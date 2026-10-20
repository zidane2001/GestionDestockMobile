# ma_boutique

Application Flutter de gestion de boutique (caisse, stock, employés, dépenses)
avec synchronisation Supabase et un serveur qui applique les rôles.

## Rôles côté serveur

Les droits ne sont pas seulement masqués dans l'interface : ils sont appliqués
par PostgreSQL (RLS + RPC `SECURITY DEFINER`), donc un client modifié ne peut
pas les contourner.

| Rôle | Peut | Ne peut pas |
| --- | --- | --- |
| `patron` | tout, y compris comptes, journal, prix d'achat, bénéfices | — |
| `manager` | vendre, dépenses, historique complet, courbe des ventes | gérer les comptes, lire le prix d'achat, lire le journal |
| `caissière` | vendre, pointages, retours/défectueux | toucher au catalogue ou au stock, voir la caisse, les dépenses, les ventes des collègues |

Points clés de la migration [supabase/migration_roles.sql](supabase/migration_roles.sql) :

- `employes_appareils` relie chaque compte d'appareil à une fiche employé
  (`rattacher_employe` revérifie le mot de passe côté serveur) ;
- le prix d'achat vit dans `produits_couts` / `ventes_couts`, jamais dans les
  tables publiées pour le temps réel ;
- le stock, la caisse et le total d'une vente sont écrits par des triggers :
  une vente passée par `enregistrer_vente` est la seule écriture possible ;
- les lectures de synchronisation passent par `produits_employe` et
  `ventes_employe`, qui masquent les coûts selon les droits ;
- les images produits vivent dans le bucket Storage `produits`, sous
  `<boutique>/<produit>/<fichier>` : un appareil téléverse, les autres
  téléchargent. Le bucket est privé, la lecture est réservée aux membres de
  la boutique et l'écriture à ceux qui gèrent le catalogue.

## Appliquer la migration

Le script lit la chaîne de connexion ou un jeton Management dans
`.pg_conn.txt` (ignoré par git) ou dans `PG_CONN`.

```bash
python apply_migration.py --check                                  # état du serveur
python apply_migration.py --fichier supabase/migration_roles.sql    # applique
python apply_migration.py --requete "select tablename from pg_publication_tables"
```

L'API Management limite le débit : les appels sont espacés et réessayés
automatiquement (HTTP 429). Une exécution complète prend quelques minutes.

## Tests

```bash
flutter analyze
flutter test                       # suite Flutter (373 tests)

python test_serveur_roles.py       # 73 vérifications contre le serveur réel
python test_serveur_roles.py -k image     # filtre sur le nom des tests
python test_serveur_roles.py --garder     # conserve les données de test
```

`test_serveur_roles.py` crée de vrais comptes Supabase (un par appareil),
amorce deux boutiques, puis vérifie par REST, RPC et websocket :

- chaque rôle est limité à ce qu'il doit voir ;
- le serveur recalcule le total, décrémente le stock, crédite la caisse ;
- deux boutiques restent étanches ;
- **deux appareils d'un même employé** partagent stock, ventes et caisse ;
- **une image téléversée par un appareil est téléchargeable par ses
  collègues**, mais pas par une autre boutique, et une caissière ne peut pas
  en envoyer ;
- **le temps réel** (vrai canal websocket) délivre la vente au patron, la
  cache à la caissière, et lui délivre la sienne.

Les données sont supprimées à la fin, sauf avec `--garder`.
