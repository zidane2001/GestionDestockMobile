-- ============================================================
-- Connexion depuis un appareil neuf — migration idempotente.
-- À exécuter sur une base existante via le SQL Editor du dashboard
-- (ou tout client Postgres disposant des droits).
-- ============================================================

-- Résout une boutique à partir de son nom et des identifiants d'un
-- employé actif. S'exécute en SECURITY DEFINER pour lire malgré la RLS :
-- un appareil neuf n'a encore ni session ni tenant. La fonction ne
-- renvoie que l'identifiant et le nom de la boutique, jamais les
-- employés ni leurs mots de passe ; les données sont ensuite lues avec
-- la session du tenant, sous RLS.
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
-- Isolation multi-tenant : un compte ne peut se rattacher qu'à la
-- boutique dont il est le compte technique. Sans ce garde-fou, un
-- utilisateur authentifié pouvait appeler initier_boutique avec
-- l'identifiant d'une autre boutique et lire ses données malgré la RLS.
-- ============================================================
create or replace function initier_boutique(p_id text, p_nom text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
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
