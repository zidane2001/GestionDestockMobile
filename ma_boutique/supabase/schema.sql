-- ============================================================
-- Ma Boutique — Schéma multi-tenant Supabase
-- À exécuter une fois dans : Supabase Dashboard -> SQL Editor
-- ============================================================

-- Tenant = boutique. Un compte Supabase (auth) est créé par boutique ;
-- la table boutique_tenants fait le lien user -> boutique pour la RLS.
create table if not exists boutique_tenants (
  user_id uuid primary key references auth.users (id) on delete cascade,
  boutique_id text not null
);

-- Administrateurs (propriétaires de boutiques). Distincts des employés.
create table if not exists admins (
  id uuid primary key references auth.users (id) on delete cascade,
  nom text not null,
  email text not null unique,
  telephone text not null default '',
  date_creation timestamptz not null default now()
);

-- Toutes les tables métier portent une colonne boutique_id.
create table if not exists boutiques (
  id text primary key,
  nom text not null,
  style_commerce text not null default '',
  monnaie text not null default 'FCFA',
  email_patron text not null default '',
  logo_url text,
  solde_caisse double precision not null default 0,
  admin_id uuid references admins (id) on delete set null,
  statut text not null default 'active',
  abonnement_mode text not null default 'achat_direct',
  abonnement_debut timestamptz,
  abonnement_fin timestamptz,
  notification_abonnement boolean not null default false,
  methode_paiement text not null default '',
  maj_ts timestamptz not null default now()
);

create table if not exists employes (
  id text primary key,
  boutique_id text not null references boutiques (id) on delete cascade,
  nom text not null,
  role text not null,
  permissions text not null default '',
  mot_de_passe text not null,
  statut text not null default 'actif',
  pin_actif boolean not null default false,
  pin text not null default '',
  biometrie boolean not null default false,
  date_creation text not null,
  maj_ts timestamptz not null default now()
);

create table if not exists produits (
  id text primary key,
  boutique_id text not null references boutiques (id) on delete cascade,
  nom text not null,
  prix_achat double precision not null,
  prix_vente double precision not null,
  quantite double precision not null default 0,
  actif boolean not null default true,
  images text not null default '',
  categorie text not null default 'autre',
  date_ajout timestamptz,
  qr_code_data text,
  maj_ts timestamptz not null default now()
);

create table if not exists ventes (
  id text primary key,
  boutique_id text not null references boutiques (id) on delete cascade,
  produit_id text not null,
  produit_nom text not null,
  quantite double precision not null,
  prix_unitaire_reel double precision not null,
  prix_achat_unitaire double precision not null,
  total double precision not null,
  vendeur_id text not null,
  vendeur_nom text not null,
  vendeur_role text not null,
  date text not null,
  maj_ts timestamptz not null default now()
);

create table if not exists depenses (
  id text primary key,
  boutique_id text not null references boutiques (id) on delete cascade,
  description text not null,
  montant double precision not null,
  auteur_nom text not null,
  auteur_role text not null,
  type text not null,
  date text not null,
  maj_ts timestamptz not null default now()
);

create table if not exists retours (
  id text primary key,
  boutique_id text not null references boutiques (id) on delete cascade,
  produit_id text not null,
  produit_nom text not null,
  motif text not null,
  description text not null,
  montant double precision not null default 0,
  auteur_nom text not null,
  statut text not null default 'en_attente',
  date text not null,
  maj_ts timestamptz not null default now()
);

create table if not exists pointages (
  id text primary key,
  boutique_id text not null references boutiques (id) on delete cascade,
  employe_id text not null,
  employe_nom text not null,
  role text not null,
  date text not null,
  heure_arrivee text not null,
  heure_depart text,
  maj_ts timestamptz not null default now()
);

create table if not exists activites (
  id text primary key,
  boutique_id text not null references boutiques (id) on delete cascade,
  employe_nom text not null,
  employe_role text not null,
  type text not null,
  description text not null,
  date text not null,
  maj_ts timestamptz not null default now()
);

create table if not exists appareils (
  id text primary key,
  boutique_id text not null references boutiques (id) on delete cascade,
  employe_nom text not null,
  role text not null,
  nom_appareil text not null,
  derniere_connexion text not null,
  actif boolean not null default true,
  maj_ts timestamptz not null default now()
);

create table if not exists notifications (
  id text primary key,
  boutique_id text not null references boutiques (id) on delete cascade,
  destinataires text not null,
  titre text not null,
  message text not null,
  type text not null,
  est_lu boolean not null default false,
  date text not null,
  maj_ts timestamptz not null default now()
);

-- ============================================================
-- Row Level Security : chaque utilisateur ne voit que SA boutique.
-- Note : la table `boutiques` n'a pas de colonne boutique_id
-- (son id EST l'identifiant du tenant) — politique sur id.
-- ============================================================
create or replace function boutique_actuelle()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select boutique_id from boutique_tenants where user_id = auth.uid()
$$;

do $$
declare t text;
begin
  foreach t in array array['boutiques','employes','produits','ventes','depenses','retours','pointages','activites','appareils','notifications']
  loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists "boutique_isolee" on %I', t);
    if t = 'boutiques' then
      -- Le propriétaire (admin) voit aussi SES boutiques ; les comptes
      -- service (superadmin) contournent la RLS de toute façon.
      -- NB : admins.id est l'uid du compte auth (pas de colonne user_id).
      execute format(
        'create policy "boutique_isolee" on %I for all
         using (id = boutique_actuelle()
                or admin_id = (select a.id from admins a where a.id = auth.uid()))
         with check (id = boutique_actuelle()
                or admin_id = (select a.id from admins a where a.id = auth.uid()))', t);
    else
      execute format(
        'create policy "boutique_isolee" on %I for all
         using (boutique_id = boutique_actuelle())
         with check (boutique_id = boutique_actuelle())', t);
    end if;
  end loop;
end $$;

-- L'admin ne voit que sa propre fiche (nom, email, téléphone).
alter table admins enable row level security;
drop policy if exists "ma_fiche_admin" on admins;
create policy "ma_fiche_admin" on admins
  for all using (id = auth.uid()) with check (id = auth.uid());

-- La table de liaison n'est lisible que par son propriétaire.
alter table boutique_tenants enable row level security;
drop policy if exists "mon_tenant" on boutique_tenants;
create policy "mon_tenant" on boutique_tenants
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ============================================================
-- RPC d'initiation : crée la boutique (si absente) et associe le
-- compte Supabase courant à cette boutique. Le compte est dérivé de
-- l'id de la boutique : un seul tenant par boutique, partagé par ses
-- appareils.
-- ============================================================
create or replace function initier_boutique(p_id text, p_nom text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Seul le compte technique dérivé de CETTE boutique peut s'y rattacher.
  -- Sans ce garde-fou, n'importe quel compte authentifié pourrait déplacer
  -- son lien vers une autre boutique et lire ses données (RLS contournée).
  if lower(coalesce(auth.jwt() ->> 'email', ''))
     <> 'boutique-' || regexp_replace(lower(p_id), '[^a-z0-9]', '', 'g')
        || '@ma-boutique.app'
  then
    raise exception 'Accès refusé' using errcode = '42501';
  end if;
  insert into boutiques (id, nom, monnaie)
  values (p_id, p_nom, 'FCFA')
  on conflict (id) do nothing;
  insert into boutique_tenants (user_id, boutique_id)
  values (auth.uid(), p_id)
  on conflict (user_id) do nothing;
end $$;

-- ============================================================
-- RPC de connexion : un appareil neuf retrouve une boutique existante
-- à partir de son nom et des identifiants d'un employé actif, sans
-- embarquer de clé service_role. Ne renvoie que l'identifiant et le nom
-- de la boutique ; les données passent ensuite par la session du tenant.
-- ============================================================
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

-- ============================================================
-- RPC stats_boutique : compteurs employés/produits/ventes.
-- Accessible au compte service (superadmin), au tenant (RLS)
-- et à l'admin propriétaire de la boutique.
-- ============================================================
create or replace function stats_boutique(p_boutique_id text)
returns table (employes bigint, produits bigint, ventes bigint)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_employes bigint;
  v_produits bigint;
  v_ventes bigint;
begin
  if auth.role() <> 'service_role'
     and boutique_actuelle() <> p_boutique_id
     and not exists (
       select 1 from admins a
       where a.id = auth.uid()
         and a.id = (select b.admin_id from boutiques b where b.id = p_boutique_id))
  then
    raise exception 'Accès refusé';
  end if;
  select count(*) into v_employes from employes where boutique_id = p_boutique_id;
  select count(*) into v_produits from produits where boutique_id = p_boutique_id;
  select count(*) into v_ventes from ventes where boutique_id = p_boutique_id;
  return query select v_employes, v_produits, v_ventes;
end $$;

-- ============================================================
-- Migration « temps réel » — à exécuter aussi sur une base
-- existante. Idempotente : peut être relancée sans risque.
-- ============================================================

-- 1) Colonnes utilisées par l'application mobile (photos, catégorie,
--    date d'ajout, contenu du QR produit).
alter table produits add column if not exists images text not null default '';
alter table produits add column if not exists categorie text not null default 'autre';
alter table produits add column if not exists date_ajout timestamptz;
alter table produits add column if not exists qr_code_data text;

-- 2) `maj_ts` devient l'horloge autoritaire du serveur : c'est elle qui
--    arbitre les conflits entre appareils (la modification la plus
--    récente l'emporte).
create or replace function toucher_maj_ts()
returns trigger
language plpgsql
as $$
begin
  new.maj_ts := now();
  return new;
end $$;

do $$
declare t text;
begin
  foreach t in array array['boutiques','employes','produits','ventes','depenses','retours','pointages','activites','appareils','notifications']
  loop
    execute format('drop trigger if exists maj_ts_auto on %I', t);
    execute format('create trigger maj_ts_auto before insert or update on %I
                    for each row execute function toucher_maj_ts()', t);
  end loop;
end $$;

-- 3) Réplication complète : indispensable pour que les suppressions
--    transportent l'identifiant du locataire (filtre Realtime).
do $$
declare t text;
begin
  foreach t in array array['boutiques','employes','produits','ventes','depenses','retours','pointages','activites','appareils','notifications']
  loop
    execute format('alter table %I replica identity full', t);
  end loop;
end $$;

-- 4) Publication Realtime : sans elle, aucune modification n'est
--    diffusée instantanément vers les autres appareils.
do $$
declare t text;
begin
  foreach t in array array['boutiques','employes','produits','ventes','depenses','retours','pointages','activites','appareils','notifications']
  loop
    begin
      execute format('alter publication supabase_realtime add table %I', t);
    exception
      when duplicate_object then null;
      when undefined_object then
        raise notice 'Publication supabase_realtime absente : activer Realtime dans le dashboard Supabase.';
    end;
  end loop;
end $$;

-- 5) Contrôle : les tables réellement publiées doivent lister les 10 tables.
-- select tablename from pg_publication_tables where pubname = 'supabase_realtime';
