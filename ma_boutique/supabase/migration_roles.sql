-- ============================================================
-- Rôles appliqués côté serveur — migration idempotente (v2).
--
-- Principe : chaque appareil possède son propre compte Supabase.
-- `employes_appareils` relie ce compte à la fiche de l'employé
-- après vérification du mot de passe. La RLS peut alors distinguer
-- le patron, le manager et la caissière, au lieu de faire confiance
-- à un compte « boutique » partagé.
--
-- Ce qui est désormais impossible côté serveur :
--   * lire les données d'une autre boutique ;
--   * lire le prix d'achat sans le droit « voirPrixAchat » ;
--   * voir les ventes d'un collègue sans « historiqueComplet » ;
--   * créer ou modifier un employé sans « gererComptes » ;
--   * toucher au stock, à la caisse ou au prix d'une vente.
-- ============================================================

-- ---------- 1. Liaison appareil ↔ employé ----------

-- Un employé peut se connecter depuis plusieurs appareils (téléphone
-- + tablette) : le lien est donc porté par une table, pas par une
-- colonne sur `employes`.
create table if not exists employes_appareils (
  auth_id uuid not null references auth.users (id) on delete cascade,
  employe_id text not null references employes (id) on delete cascade,
  boutique_id text not null,
  lie_at timestamptz not null default now(),
  primary key (auth_id, employe_id)
);

create index if not exists employes_appareils_auth_idx
  on employes_appareils (auth_id);
create index if not exists employes_appareils_employe_idx
  on employes_appareils (employe_id);

-- L'ancienne colonne (un seul compte par employé) est abandonnée :
-- elle empêchait le même employé de se connecter depuis deux appareils.
-- Elle n'est supprimée qu'après la redéfinition des fonctions qui la
-- référencent (une fonction SQL y tient une dépendance explicite).

-- ---------- 2. Identité de l'appelant ----------

create or replace function mon_employe_id()
returns text
language sql stable security definer set search_path = public
as $$
  select ea.employe_id
  from employes_appareils ea
  where ea.auth_id = auth.uid()
  limit 1
$$;

create or replace function ma_boutique_id()
returns text
language sql stable security definer set search_path = public
as $$
  select ea.boutique_id
  from employes_appareils ea
  where ea.auth_id = auth.uid()
  limit 1
$$;

create or replace function mon_role_app()
returns text
language sql stable security definer set search_path = public
as $$
  select e.role
  from employes e
  join employes_appareils ea on ea.employe_id = e.id
  where ea.auth_id = auth.uid()
  limit 1
$$;

-- La boutique courante : l'appareil lié à un employé d'abord, le
-- tenant historique (un compte par boutique) ensuite. Les anciennes
-- installations restent ainsi utilisables.
create or replace function boutique_actuelle()
returns text
language sql stable security definer set search_path = public
as $$
  select coalesce(
    (select ea.boutique_id from employes_appareils ea
      where ea.auth_id = auth.uid() limit 1),
    (select bt.boutique_id from boutique_tenants bt
      where bt.user_id = auth.uid() limit 1)
  )
$$;

-- Les droits par défaut sont dupliqués depuis lib/core/permissions.dart :
-- ils servent quand la colonne `permissions` est vide (anciennes fiches).
create or replace function a_permission(p_droit text)
returns boolean
language sql stable security definer set search_path = public
as $$
  select coalesce((
    select case
      when coalesce(e.permissions, '') <> '' then
        p_droit = any(string_to_array(replace(e.permissions, ' ', ''), ','))
      else
        p_droit = any(case e.role
          when 'patron' then array[
            'vendre','defectueux','retour','depense','sortieCaisse',
            'gererProduits','voirPrixAchat','voirBenefices',
            'voirCourbeVentes','historiqueComplet','exporter','journal',
            'pointages','gererComptes','appareils','traiterRetours']
          when 'manager' then array[
            'vendre','defectueux','retour','depense','sortieCaisse',
            'voirCourbeVentes','historiqueComplet','exporter','pointer']
          else array[
            'vendre','defectueux','retour','sortieCaisse','pointer']
        end)
    end
    from employes e
    join employes_appareils ea on ea.employe_id = e.id
    where ea.auth_id = auth.uid()
    limit 1
  ), false)
$$;

-- ---------- 3. Rattachement d'un appareil à un employé ----------

create or replace function rattacher_employe(
  p_boutique text,
  p_role text,
  p_mot_de_passe text
)
returns table (employe_id text, boutique_id text, role text, permissions text)
language plpgsql security definer set search_path = public
as $$
declare v employes%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Session requise' using errcode = '42501';
  end if;
  select * into v
    from employes e
   where e.boutique_id = p_boutique
     and e.role = p_role
     and e.mot_de_passe = p_mot_de_passe
     and e.statut = 'actif'
   order by e.date_creation
   limit 1;
  if not found then
    raise exception 'Identifiants incorrects' using errcode = '42501';
  end if;
  -- Un appareil ne sert qu'un employé à la fois : changer d'employé
  -- détache l'ancien. Les autres appareils de ce même employé, eux,
  -- conservent leur accès.
  -- Les colonnes sont qualifiées : `employe_id` et `boutique_id` sont
  -- aussi des paramètres de sortie, sans quoi Postgres les confond.
  delete from employes_appareils ea
   where ea.auth_id = auth.uid() and ea.employe_id <> v.id;
  insert into employes_appareils (auth_id, employe_id, boutique_id)
  values (auth.uid(), v.id, v.boutique_id)
  on conflict on constraint employes_appareils_pkey
  do update set boutique_id = excluded.boutique_id, lie_at = now();
  return query select v.id, v.boutique_id, v.role, v.permissions;
end $$;

revoke all on function rattacher_employe(text, text, text) from public;
grant execute on function rattacher_employe(text, text, text) to authenticated;

-- Déconnexion : l'appareil n'est plus rattaché à cet employé.
create or replace function detacher_employe()
returns void
language sql security definer set search_path = public
as $$
  delete from employes_appareils where auth_id = auth.uid()
$$;

revoke all on function detacher_employe() from public;
grant execute on function detacher_employe() to authenticated;

-- Résolution d'une boutique depuis un appareil neuf : elle ne renvoie
-- que l'identifiant et le nom, jamais les employés ni leurs mots de passe.
create or replace function rejoindre_boutique(
  p_nom text,
  p_role text,
  p_mot_de_passe text
)
returns table (boutique_id text, nom text)
language sql
stable
security definer
set search_path = public
as $$
  select b.id, b.nom
  from boutiques b
  join employes e on e.boutique_id = b.id
  where lower(btrim(b.nom)) = lower(btrim(p_nom))
    and e.role = p_role
    and e.mot_de_passe = p_mot_de_passe
    and e.statut = 'actif'
  order by b.id
  limit 1
$$;

revoke all on function rejoindre_boutique(text, text, text) from public;
grant execute on function rejoindre_boutique(text, text, text) to anon, authenticated;

-- Première synchronisation d'une boutique créée hors ligne : le patron
-- n'existe pas encore côté serveur. La fonction crée la fiche et la lie
-- à l'appareil, sans jamais réattribuer une fiche existante.
create or replace function demarrer_boutique(
  p_boutique text,
  p_nom text,
  p_employe text,
  p_nom_employe text,
  p_mot_de_passe text
)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Session requise' using errcode = '42501';
  end if;
  -- N'ouvre une boutique que si elle n'existe pas encore : sinon un
  -- compte pourrait se fabriquer une fiche patron dans une autre boutique.
  if exists (select 1 from boutiques where id = p_boutique) then
    raise exception 'Boutique déjà initialisée' using errcode = '23505';
  end if;
  -- Un identifiant d'employé déjà pris (même dans une autre boutique)
  -- ne peut pas être réattribué.
  if exists (select 1 from employes where id = p_employe) then
    raise exception 'Identifiant employé déjà utilisé' using errcode = '23505';
  end if;
  insert into boutiques (id, nom, monnaie) values (p_boutique, p_nom, 'FCFA')
    on conflict (id) do nothing;
  insert into employes (
    id, boutique_id, nom, role, permissions, mot_de_passe, statut,
    pin_actif, pin, biometrie, date_creation
  ) values (
    p_employe, p_boutique, p_nom_employe, 'patron',
    'vendre,defectueux,retour,depense,sortieCaisse,gererProduits,voirPrixAchat,voirBenefices,voirCourbeVentes,historiqueComplet,exporter,journal,pointages,gererComptes,appareils,traiterRetours',
    p_mot_de_passe, 'actif', false, '', false, now()::text
  );
  insert into employes_appareils (auth_id, employe_id, boutique_id)
  values (auth.uid(), p_employe, p_boutique)
  on conflict (auth_id, employe_id)
  do update set boutique_id = excluded.boutique_id, lie_at = now();
end $$;

revoke all on function demarrer_boutique(text, text, text, text, text) from public;
grant execute on function demarrer_boutique(text, text, text, text, text) to authenticated;

-- L'ancienne colonne devient inutile : plus aucun dépendant ne la
-- référence après la redéfinition des fonctions ci-dessus.
alter table employes drop column if exists auth_id;
drop index if exists employes_auth_id_key;

-- ---------- 4. Reprise des installations existantes ----------

-- Les anciennes installations utilisent un compte « boutique-<id>@… »
-- relié par `boutique_tenants`. On le rattache au patron de la
-- boutique pour que les appareils déjà en circulation continuent de
-- fonctionner. En cas de plusieurs patrons, le plus ancien est retenu.
insert into employes_appareils (auth_id, employe_id, boutique_id)
select t.user_id, t.employe_id, t.boutique_id
  from (
    select distinct on (bt.user_id)
           bt.user_id as user_id, e.id as employe_id, e.boutique_id as boutique_id
      from boutique_tenants bt
      join employes e on e.boutique_id = bt.boutique_id and e.role = 'patron'
     order by bt.user_id, e.date_creation
  ) t
 where not exists (
   select 1 from employes_appareils ea where ea.auth_id = t.user_id
 )
on conflict (auth_id, employe_id) do nothing;

-- ---------- 5. Coûts sensibles dans des tables dédiées ----------

-- Le prix d'achat sort des tables publiées : il ne peut plus fuiter
-- ni par REST, ni par le canal temps réel. Seuls les rôles ayant le
-- droit « voirPrixAchat » le lisent.
create table if not exists produits_couts (
  produit_id text primary key references produits (id) on delete cascade,
  boutique_id text not null,
  prix_achat double precision not null default 0
);

create table if not exists ventes_couts (
  vente_id text primary key references ventes (id) on delete cascade,
  boutique_id text not null,
  prix_achat_unitaire double precision
);

-- Report des coûts existants (la lecture se fait en JSON pour rester
-- exécutable même si la colonne a déjà été supprimée).
insert into produits_couts (produit_id, boutique_id, prix_achat)
select p.id, p.boutique_id,
       coalesce((to_jsonb(p) ->> 'prix_achat')::double precision, 0)
  from produits p
on conflict (produit_id) do update
  set prix_achat = excluded.prix_achat, boutique_id = excluded.boutique_id
  where excluded.prix_achat <> 0;

insert into ventes_couts (vente_id, boutique_id, prix_achat_unitaire)
select v.id, v.boutique_id,
       (to_jsonb(v) ->> 'prix_achat_unitaire')::double precision
  from ventes v
on conflict (vente_id) do update
  set prix_achat_unitaire = excluded.prix_achat_unitaire,
      boutique_id = excluded.boutique_id
  where excluded.prix_achat_unitaire is not null;

-- ---------- 6. Écritures métier via RPC ----------

-- Le prix d'achat n'est plus lisible directement : l'upsert PostgREST
-- ne peut plus servir, la passe par des RPC qui vérifient les droits.
create or replace function enregistrer_produit(p_data jsonb)
returns void
language plpgsql security definer set search_path = public
as $$
declare v_produit text := p_data ->> 'id';
begin
  if not a_permission('gererProduits') then
    raise exception 'Accès refusé' using errcode = '42501';
  end if;
  if v_produit is null or v_produit = '' then
    raise exception 'Produit sans identifiant' using errcode = '22023';
  end if;
  insert into produits (
    id, boutique_id, nom, prix_vente, quantite, actif,
    images, categorie, date_ajout, qr_code_data, maj_ts
  ) values (
    v_produit, ma_boutique_id(), coalesce(p_data ->> 'nom', ''),
    coalesce((p_data ->> 'prix_vente')::double precision, 0),
    coalesce((p_data ->> 'quantite')::double precision, 0),
    coalesce((p_data ->> 'actif')::boolean, true),
    coalesce(p_data ->> 'images', ''),
    coalesce(p_data ->> 'categorie', 'autre'),
    nullif(p_data ->> 'date_ajout', '')::timestamptz,
    p_data ->> 'qr_code_data',
    coalesce(nullif(p_data ->> 'maj_ts', '')::timestamptz, now())
  )
  on conflict (id) do update set
    nom = excluded.nom,
    prix_vente = excluded.prix_vente,
    quantite = excluded.quantite,
    actif = excluded.actif,
    images = excluded.images,
    categorie = excluded.categorie,
    date_ajout = excluded.date_ajout,
    qr_code_data = excluded.qr_code_data,
    maj_ts = excluded.maj_ts
  where produits.boutique_id = ma_boutique_id();

  -- Le prix d'achat n'est écrit que si le produit appartient bien à la
  -- boutique de l'appelant.
  if exists (
    select 1 from produits
     where id = v_produit and boutique_id = ma_boutique_id()
  ) then
    insert into produits_couts (produit_id, boutique_id, prix_achat)
    values (
      v_produit, ma_boutique_id(),
      coalesce((p_data ->> 'prix_achat')::double precision, 0)
    )
    on conflict (produit_id) do update
      set prix_achat = excluded.prix_achat, boutique_id = excluded.boutique_id;
  end if;
end $$;

revoke all on function enregistrer_produit(jsonb) from public;
grant execute on function enregistrer_produit(jsonb) to authenticated;

create or replace function enregistrer_vente(p_data jsonb)
returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_employe text := mon_employe_id();
  v_nom text;
  v_role text;
  v_produit text := p_data ->> 'produit_id';
  v_prix_catalogue double precision;
  v_prix double precision;
  v_quantite double precision := coalesce((p_data ->> 'quantite')::double precision, 0);
  v_total double precision;
  v_id text := p_data ->> 'id';
begin
  if not a_permission('vendre') then
    raise exception 'Accès refusé' using errcode = '42501';
  end if;
  if v_employe is null then
    raise exception 'Accès refusé' using errcode = '42501';
  end if;
  if v_id is null or v_id = '' then
    raise exception 'Vente sans identifiant' using errcode = '22023';
  end if;
  if v_quantite <= 0 then
    raise exception 'Quantité invalide' using errcode = '22023';
  end if;
  select nom, role into v_nom, v_role from employes where id = v_employe;

  -- Le produit doit exister : sans lui, le stock ne pourrait pas être
  -- dédécrementé côté serveur.
  select prix_vente into v_prix_catalogue
    from produits
   where id = v_produit and boutique_id = ma_boutique_id();
  if v_prix_catalogue is null then
    raise exception 'Produit introuvable' using errcode = '22023';
  end if;

  -- Le prix appliqué ne peut qu'être une remise du prix catalogue, et
  -- le total est recalculé par le serveur : un client ne peut pas
  -- enregistrer une vente à 0,01 €.
  v_prix := coalesce((p_data ->> 'prix_unitaire_reel')::double precision, v_prix_catalogue);
  if v_prix <= 0 or v_prix > v_prix_catalogue then
    v_prix := v_prix_catalogue;
  end if;
  v_total := v_prix * v_quantite;

  insert into ventes (
    id, boutique_id, produit_id, produit_nom, quantite,
    prix_unitaire_reel, total,
    vendeur_id, vendeur_nom, vendeur_role, date, maj_ts
  ) values (
    v_id, ma_boutique_id(), v_produit,
    coalesce((select p.nom from produits p where p.id = v_produit), ''),
    v_quantite, v_prix, v_total,
    v_employe, v_nom, v_role,
    coalesce(p_data ->> 'date', now()::text), now()
  )
  on conflict (id) do nothing;
end $$;

revoke all on function enregistrer_vente(jsonb) from public;
grant execute on function enregistrer_vente(jsonb) to authenticated;

-- Nombre de lignes métier de la boutique : sert à savoir si le serveur
-- doit être amorcé (et non filtré par le rôle de l'appelant).
create or replace function compte_metier(p_boutique text)
returns bigint
language plpgsql stable security definer set search_path = public
as $$
declare n bigint;
begin
  if auth.uid() is null then
    return 0;
  end if;
  if p_boutique is distinct from ma_boutique_id() then
    return 0;
  end if;
  select (select count(*) from employes where boutique_id = p_boutique)
       + (select count(*) from produits where boutique_id = p_boutique)
       + (select count(*) from ventes where boutique_id = p_boutique)
    into n;
  return n;
end $$;

revoke all on function compte_metier(text) from public;
grant execute on function compte_metier(text) to authenticated;

-- ---------- 7. Triggers de protection ----------

-- Le coût réel d'une vente est figé par le serveur, au moment de la
-- vente : une caissière ne peut ni le lire ni le falsifier.
create or replace function ventes_cout_reel()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare v_prix double precision;
begin
  select pc.prix_achat into v_prix
    from produits_couts pc
   where pc.produit_id = new.produit_id
     and pc.boutique_id = new.boutique_id;
  insert into ventes_couts (vente_id, boutique_id, prix_achat_unitaire)
  values (new.id, new.boutique_id, v_prix)
  on conflict (vente_id) do update
    set prix_achat_unitaire = excluded.prix_achat_unitaire,
        boutique_id = excluded.boutique_id;
  return new;
end $$;

drop trigger if exists ventes_cout_reel on ventes;
create trigger ventes_cout_reel after insert on ventes
  for each row execute function ventes_cout_reel();

-- La caisse est tenue par le serveur : une vente l'augmente, une dépense
-- la diminue. Le client ne peut plus écrire `solde_caisse`.
create or replace function ventes_caisse()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  update boutiques set solde_caisse = solde_caisse + new.total
   where id = new.boutique_id;
  return new;
end $$;

drop trigger if exists ventes_caisse on ventes;
create trigger ventes_caisse after insert on ventes
  for each row execute function ventes_caisse();

create or replace function depenses_caisse()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  update boutiques set solde_caisse = solde_caisse - new.montant
   where id = new.boutique_id;
  return new;
end $$;

drop trigger if exists depenses_caisse on depenses;
create trigger depenses_caisse after insert on depenses
  for each row execute function depenses_caisse();

-- Le stock est tenu par le serveur : une vente le diminue, un retour
-- signalé l'ajuste. Un employé n'a donc plus besoin d'écrire la table.
create or replace function ventes_stock()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  update produits set quantite = greatest(0, quantite - new.quantite)
   where id = new.produit_id and boutique_id = new.boutique_id;
  return new;
end $$;

drop trigger if exists ventes_stock on ventes;
create trigger ventes_stock after insert on ventes
  for each row execute function ventes_stock();

create or replace function retours_stock()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if new.motif = 'defectueux' then
    update produits set quantite = greatest(0, quantite - 1)
     where id = new.produit_id and boutique_id = new.boutique_id;
  else
    update produits set quantite = quantite + 1
     where id = new.produit_id and boutique_id = new.boutique_id;
  end if;
  if new.motif = 'remboursement' then
    update boutiques set solde_caisse = solde_caisse - new.montant
     where id = new.boutique_id;
  end if;
  return new;
end $$;

drop trigger if exists retours_stock on retours;
create trigger retours_stock after insert on retours
  for each row execute function retours_stock();

-- ---------- 8. Colonnes sensibles protégées en écriture ----------

-- Un employé sans « gererProduits » ne peut modifier ni le catalogue
-- ni le stock : les écritures internes (triggers) restent autorisées,
-- elles passent par un niveau de trigger supérieur à 1.
create or replace function proteger_produit()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if pg_trigger_depth() > 1 then
    return new;
  end if;
  if not a_permission('gererProduits') then
    new.id := old.id;
    new.boutique_id := old.boutique_id;
    new.nom := old.nom;
    new.prix_vente := old.prix_vente;
    new.quantite := old.quantite;
    new.images := old.images;
    new.categorie := old.categorie;
    new.date_ajout := old.date_ajout;
    new.qr_code_data := old.qr_code_data;
    new.actif := old.actif;
  end if;
  return new;
end $$;

drop trigger if exists proteger_produit on produits;
create trigger proteger_produit before update on produits
  for each row execute function proteger_produit();

-- La caisse n'est modifiable que par les triggers serveur.
create or replace function proteger_boutique()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if pg_trigger_depth() > 1 then
    return new;
  end if;
  new.solde_caisse := old.solde_caisse;
  return new;
end $$;

drop trigger if exists proteger_boutique on boutiques;
create trigger proteger_boutique before update on boutiques
  for each row execute function proteger_boutique();

-- ---------- 9. Retrait des colonnes sensibles ----------

-- Les vues de lecture masquent déjà ces colonnes, mais le canal temps
-- réel diffuse toutes les colonnes d'une table : le prix d'achat doit
-- disparaître de la table pour ne jamais fuiter.
drop view if exists produits_employe;
drop view if exists ventes_employe;

alter table produits drop column if exists prix_achat;
alter table ventes drop column if exists prix_achat_unitaire;

-- ---------- 10. Lectures masquées pour les rôles non privilégiés ----------

create or replace view produits_employe as
select
  p.id, p.boutique_id, p.nom,
  case when a_permission('voirPrixAchat')
       then coalesce(pc.prix_achat, 0) else 0 end as prix_achat,
  p.prix_vente, p.quantite, p.actif, p.images, p.categorie, p.date_ajout,
  p.qr_code_data, p.maj_ts
from produits p
left join produits_couts pc on pc.produit_id = p.id
where p.boutique_id = ma_boutique_id();

create or replace view ventes_employe as
select
  v.id, v.boutique_id, v.produit_id, v.produit_nom, v.quantite, v.prix_unitaire_reel,
  case when a_permission('voirPrixAchat')
       then coalesce(vc.prix_achat_unitaire, pc.prix_achat, 0) else 0 end
    as prix_achat_unitaire,
  v.total, v.vendeur_id, v.vendeur_nom, v.vendeur_role, v.date, v.maj_ts
from ventes v
left join ventes_couts vc on vc.vente_id = v.id
left join produits_couts pc on pc.produit_id = v.produit_id
where v.boutique_id = ma_boutique_id()
  and (v.vendeur_id = mon_employe_id() or a_permission('historiqueComplet'));

grant select on produits_employe, ventes_employe to authenticated;
grant select on produits_couts, ventes_couts to authenticated;
revoke select on produits_couts, ventes_couts from anon;

-- La lecture directe des tables reste possible (le temps réel en a
-- besoin) : les colonnes sensibles n'y sont plus.
grant select on produits, ventes to authenticated;
revoke select on produits, ventes from anon;

-- ---------- 11. Politiques par table ----------

alter table boutiques enable row level security;
drop policy if exists boutique_isolee on boutiques;
drop policy if exists boutiques_lecture on boutiques;
drop policy if exists boutiques_ecriture on boutiques;
drop policy if exists boutiques_maj on boutiques;
create policy boutiques_lecture on boutiques
  for select using (id = ma_boutique_id());
create policy boutiques_ecriture on boutiques
  for insert with check (id = ma_boutique_id() and a_permission('gererComptes'));
create policy boutiques_maj on boutiques
  for update using (id = ma_boutique_id() and a_permission('gererComptes'))
  with check (id = ma_boutique_id() and a_permission('gererComptes'));

alter table employes enable row level security;
drop policy if exists boutique_isolee on employes;
drop policy if exists employes_lecture on employes;
drop policy if exists employes_ecriture on employes;
drop policy if exists employes_maj on employes;
drop policy if exists employes_suppr on employes;
create policy employes_lecture on employes
  for select using (
    boutique_id = ma_boutique_id()
    and (id = mon_employe_id() or a_permission('gererComptes'))
  );
create policy employes_ecriture on employes
  for insert with check (boutique_id = ma_boutique_id() and a_permission('gererComptes'));
create policy employes_maj on employes
  for update using (boutique_id = ma_boutique_id() and a_permission('gererComptes'))
  with check (boutique_id = ma_boutique_id() and a_permission('gererComptes'));
create policy employes_suppr on employes
  for delete using (boutique_id = ma_boutique_id() and a_permission('gererComptes'));

alter table produits enable row level security;
drop policy if exists boutique_isolee on produits;
drop policy if exists produits_lecture on produits;
drop policy if exists produits_ecriture on produits;
drop policy if exists produits_maj on produits;
drop policy if exists produits_suppr on produits;
create policy produits_lecture on produits
  for select using (boutique_id = ma_boutique_id());
create policy produits_ecriture on produits
  for insert with check (boutique_id = ma_boutique_id() and a_permission('gererProduits'));
-- La mise à jour reste ouverte pour que la vente décrémente le stock ;
-- le trigger proteger_produit() reverrouille tous les autres champs.
create policy produits_maj on produits
  for update using (boutique_id = ma_boutique_id())
  with check (boutique_id = ma_boutique_id());
create policy produits_suppr on produits
  for delete using (boutique_id = ma_boutique_id() and a_permission('gererProduits'));

alter table produits_couts enable row level security;
drop policy if exists produits_couts_lecture on produits_couts;
create policy produits_couts_lecture on produits_couts
  for select using (
    boutique_id = ma_boutique_id() and a_permission('voirPrixAchat')
  );

alter table ventes enable row level security;
drop policy if exists boutique_isolee on ventes;
drop policy if exists ventes_lecture on ventes;
drop policy if exists ventes_ecriture on ventes;
drop policy if exists ventes_maj on ventes;
create policy ventes_lecture on ventes
  for select using (
    boutique_id = ma_boutique_id()
    and (vendeur_id = mon_employe_id() or a_permission('historiqueComplet'))
  );
-- Aucune politique d'écriture : `enregistrer_vente` (SECURITY DEFINER)
-- est le seul chemin. Une écriture PostgREST directe serait refusée, donc
-- un client ne peut ni forcer le total ni vendre sous une autre identité.
drop policy if exists ventes_ecriture on ventes;
-- Aucune mise à jour n'est autorisée : le total, la quantité et le prix
-- d'une vente sont figés par `enregistrer_vente`. Sans politique de mise
-- à jour, une caissière ne peut pas réécrire le montant de sa propre vente.
drop policy if exists ventes_maj on ventes;

alter table ventes_couts enable row level security;
drop policy if exists ventes_couts_lecture on ventes_couts;
create policy ventes_couts_lecture on ventes_couts
  for select using (
    boutique_id = ma_boutique_id() and a_permission('voirPrixAchat')
  );

alter table depenses enable row level security;
drop policy if exists boutique_isolee on depenses;
drop policy if exists depenses_lecture on depenses;
drop policy if exists depenses_ecriture on depenses;
drop policy if exists depenses_maj on depenses;
create policy depenses_lecture on depenses
  for select using (boutique_id = ma_boutique_id() and a_permission('depense'));
create policy depenses_ecriture on depenses
  for insert with check (
    boutique_id = ma_boutique_id()
    and a_permission(case
      when type in ('sortieJustifiee', 'sortie_justifiee') then 'sortieCaisse'
      else 'depense' end)
  );
create policy depenses_maj on depenses
  for update using (
    boutique_id = ma_boutique_id()
    and a_permission(case
      when type in ('sortieJustifiee', 'sortie_justifiee') then 'sortieCaisse'
      else 'depense' end)
  )
  with check (boutique_id = ma_boutique_id());

alter table retours enable row level security;
drop policy if exists boutique_isolee on retours;
drop policy if exists retours_lecture on retours;
drop policy if exists retours_ecriture on retours;
drop policy if exists retours_maj on retours;
create policy retours_lecture on retours
  for select using (
    boutique_id = ma_boutique_id()
    and (
      a_permission('historiqueComplet')
      or a_permission('traiterRetours')
      or auteur_nom = (select e.nom from employes e where e.id = mon_employe_id())
    )
  );
create policy retours_ecriture on retours
  for insert with check (
    boutique_id = ma_boutique_id()
    and (a_permission('retour') or a_permission('defectueux'))
  );
create policy retours_maj on retours
  for update using (boutique_id = ma_boutique_id() and a_permission('traiterRetours'))
  with check (boutique_id = ma_boutique_id() and a_permission('traiterRetours'));

alter table pointages enable row level security;
drop policy if exists boutique_isolee on pointages;
drop policy if exists pointages_lecture on pointages;
drop policy if exists pointages_ecriture on pointages;
drop policy if exists pointages_maj on pointages;
create policy pointages_lecture on pointages
  for select using (
    boutique_id = ma_boutique_id()
    and (
      employe_id = mon_employe_id()
      or a_permission('pointages')
      or a_permission('historiqueComplet')
    )
  );
create policy pointages_ecriture on pointages
  for insert with check (
    boutique_id = ma_boutique_id()
    and employe_id = mon_employe_id()
    and a_permission('pointer')
  );
create policy pointages_maj on pointages
  for update using (boutique_id = ma_boutique_id() and (employe_id = mon_employe_id() or a_permission('pointages')))
  with check (boutique_id = ma_boutique_id() and (employe_id = mon_employe_id() or a_permission('pointages')));

alter table activites enable row level security;
drop policy if exists boutique_isolee on activites;
drop policy if exists activites_lecture on activites;
drop policy if exists activites_ecriture on activites;
create policy activites_lecture on activites
  for select using (boutique_id = ma_boutique_id() and a_permission('journal'));
create policy activites_ecriture on activites
  for insert with check (boutique_id = ma_boutique_id());

alter table appareils enable row level security;
drop policy if exists boutique_isolee on appareils;
drop policy if exists appareils_lecture on appareils;
drop policy if exists appareils_ecriture on appareils;
drop policy if exists appareils_maj on appareils;
create policy appareils_lecture on appareils
  for select using (boutique_id = ma_boutique_id() and a_permission('appareils'));
create policy appareils_ecriture on appareils
  for insert with check (boutique_id = ma_boutique_id());
create policy appareils_maj on appareils
  for update using (boutique_id = ma_boutique_id() and a_permission('appareils'))
  with check (boutique_id = ma_boutique_id() and a_permission('appareils'));

alter table notifications enable row level security;
drop policy if exists boutique_isolee on notifications;
drop policy if exists notifications_lecture on notifications;
drop policy if exists notifications_ecriture on notifications;
drop policy if exists notifications_maj on notifications;
create policy notifications_lecture on notifications
  for select using (
    boutique_id = ma_boutique_id()
    and (
      mon_role_app() = 'patron'
      or position(',' || mon_role_app() || ',' in ',' || destinataires || ',') > 0
    )
  );
create policy notifications_ecriture on notifications
  for insert with check (boutique_id = ma_boutique_id());
create policy notifications_maj on notifications
  for update using (boutique_id = ma_boutique_id())
  with check (boutique_id = ma_boutique_id());

-- La table de liaison n'est lisible que par son propriétaire.
alter table employes_appareils enable row level security;
drop policy if exists employes_appareils_moi on employes_appareils;
create policy employes_appareils_moi on employes_appareils
  for all using (auth_id = auth.uid()) with check (auth_id = auth.uid());

-- ---------- 12. Superadmin : contrôle d'accès corrigé ----------

create or replace function stats_boutique(p_boutique_id text)
returns table (employes bigint, produits bigint, ventes bigint)
language plpgsql security definer set search_path = public
as $$
declare
  v_employes bigint;
  v_produits bigint;
  v_ventes bigint;
begin
  if auth.role() <> 'service_role'
     and boutique_actuelle() is distinct from p_boutique_id
     and not exists (
       select 1 from admins a
       where a.id = auth.uid()
         and a.id = (select b.admin_id from boutiques b where b.id = p_boutique_id)
     )
  then
    raise exception 'Accès refusé' using errcode = '42501';
  end if;
  select count(*) into v_employes from employes where boutique_id = p_boutique_id;
  select count(*) into v_produits from produits where boutique_id = p_boutique_id;
  select count(*) into v_ventes from ventes where boutique_id = p_boutique_id;
  return query select v_employes, v_produits, v_ventes;
end $$;

revoke all on function stats_boutique(text) from public;
grant execute on function stats_boutique(text) to authenticated, service_role;

-- ---------- 13. Images produits partagées entre appareils ----------

-- Sans ce bucket, la colonne `images` ne transportait que des chemins
-- absolus d'un appareil : le collègue voyait un chemin /data/user/0/... qui
-- n'existe pas chez lui, donc une image cassée. Les fichiers vivent
-- désormais dans Storage, sous « <boutique>/<produit>/<fichier> ».
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'produits', 'produits', false, 5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Lecture : tout membre de la boutique (le premier segment du chemin est
-- l'identifiant de la boutique).
drop policy if exists produits_images_lecture on storage.objects;
create policy produits_images_lecture on storage.objects
  for select to authenticated
  using (
    bucket_id = 'produits'
    and (storage.foldername(name))[1] = public.ma_boutique_id()
  );

-- Écriture : seuls ceux qui gèrent le catalogue.
drop policy if exists produits_images_ecriture on storage.objects;
create policy produits_images_ecriture on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'produits'
    and (storage.foldername(name))[1] = public.ma_boutique_id()
    and public.a_permission('gererProduits')
  );

drop policy if exists produits_images_maj on storage.objects;
create policy produits_images_maj on storage.objects
  for update to authenticated
  using (
    bucket_id = 'produits'
    and (storage.foldername(name))[1] = public.ma_boutique_id()
    and public.a_permission('gererProduits')
  )
  with check (
    bucket_id = 'produits'
    and (storage.foldername(name))[1] = public.ma_boutique_id()
    and public.a_permission('gererProduits')
  );

drop policy if exists produits_images_suppr on storage.objects;
create policy produits_images_suppr on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'produits'
    and (storage.foldername(name))[1] = public.ma_boutique_id()
    and public.a_permission('gererProduits')
  );
