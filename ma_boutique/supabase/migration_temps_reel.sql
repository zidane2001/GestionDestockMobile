-- ============================================================
-- Ma Boutique — Migration « temps réel »
-- À coller dans : Supabase Dashboard → SQL Editor → Run
-- Idempotente : peut être relancée sans risque.
--
-- Sans cette migration :
--   • les envois de produits échouent (colonnes images/categorie/
--     date_ajout/qr_code_data absentes) et restent en file d'attente ;
--   • aucune modification n'est diffusée aux autres appareils,
--     car les tables ne sont pas dans la publication Realtime.
-- ============================================================

-- 1) Colonnes utilisées par l'application mobile.
alter table produits add column if not exists images text not null default '';
alter table produits add column if not exists categorie text not null default 'autre';
alter table produits add column if not exists date_ajout timestamptz;
alter table produits add column if not exists qr_code_data text;

-- 2) `maj_ts` devient l'horloge autoritaire du serveur : elle arbitre les
--    conflits entre appareils (la modification la plus récente gagne).
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

-- 4) Publication Realtime : sans elle, aucune modification n'est diffusée
--    instantanément vers les autres appareils.
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

-- 5) Contrôle : doit lister les 10 tables.
select tablename
from pg_publication_tables
where pubname = 'supabase_realtime'
order by tablename;
