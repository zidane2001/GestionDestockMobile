# Synchronisation temps réel & recherche instantanée

## 1. Ce qui a été mis en place

### 1.1 Temps réel (une modification sur un appareil = visible partout, tout de suite)

| Élément | Fichier | Rôle |
| --- | --- | --- |
| Abonnement Realtime | `lib/services/sync_service.dart` | Écoute `postgres_changes` sur les 10 tables de la boutique (INSERT / UPDATE / DELETE, filtré par `boutique_id`, plus un filet de sécurité pour les suppressions). |
| Écriture locale immédiate | `lib/services/sync_service.dart` | Chaque événement reçu est converti (`versLocal`) puis écrit dans SQLite, et l'interface se recharge (rafraîchissement regroupé sur 120 ms). |
| Anti-écho | `JournalEcritures` | Une ligne écrite par cet appareil n'est pas réappliquée quand le serveur la renvoie. L'horodatage reçu du serveur (`.select('id, maj_ts')`) sert de référence. |
| File d'attente prioritaire | `synchroniser()` | Une ligne ayant une opération locale en attente n'est jamais écrasée par une version distante. |
| Réconciliation de secours | `demarrerSurveillance()` | Si le temps réel n'est pas disponible : rapatriement silencieux toutes les 15 s (ou 45 s si le temps réel est actif), pour ne rien perdre en cas de réseau filtré. |
| Suppressions | `interpreterChangement()` | Un `DELETE` distant supprime la ligne locale, en restant borné au locataire. |
| Indicateur | `lib/widgets/app_header.dart` | « Synchronisation en direct », « N en attente de synchro », « Hors ligne · N en attente » + bouton de synchronisation manuelle. |

Hors ligne, rien n'est perdu : les opérations sont empilées dans `sync_queue` (SQLite) et renvoyées au retour du réseau. La reprise du réseau rouvre aussi l'écoute temps réel.

### 1.2 Recherche : suggestions immédiates

`rechercheProduits()` (`lib/core/stats.dart`) et le sélecteur (`lib/widgets/produit_picker.dart`) :

- suggestions recalculées **à chaque frappe** (aucune validation à presser) ;
- classement : nom exact → préfixe du nom → début de mot → tous les mots → sous-chaîne → catégorie → tolérance aux fautes (Levenshtein) ;
- accents et ponctuation ignorés (`Café` trouve `cafe`, `vêtement` trouve `vetement`) ;
- à pertinence égale, les produits **en stock** passent avant les ruptures ;
- compteur affiché (`N suggestions · M en stock`), prix, catégorie, quantité, bouton d'effacement.

Corrections associées (bugs réels constatés sur appareil) :

- `lib/widgets/product_image.dart` : l'aperçu ignorait la taille demandée pour un produit sans photo (`48×48`), ce qui produisait des contraintes infinies dans les listes.
- `lib/widgets/produit_picker.dart` : la liste des suggestions utilisait `Flexible` alors que la feuille modale défile (`SingleChildScrollView`), ce qui donnait **une feuille de vente vide** sur l'appareil (`RenderFlex … unbounded`). Les suggestions sont désormais empilées dans la feuille, qui assure le défilement.

Ces deux défauts sont couverts par `test/produit_picker_test.dart` (rendu dans un contexte défilant non borné, comme la feuille réelle).

## 1.3 Amorçage d'un serveur vide

Si le serveur ne contient encore aucune donnée métier pour la boutique (première
installation, projet restauré ou recréé), la file de synchronisation ne contient que
les modifications récentes : le catalogue déjà présent sur l'appareil ne partirait
jamais. `synchroniser()` détecte ce cas et pousse une fois tout le catalogue local
(`_amorcerServeur`), puis les appareils convergent normalement.

## 2. Mise en service du serveur (état vérifié)

Projet `kxgluwdhlgzmgdcszeln` : de nouveau **actif** (il était en pause).

- Tables métier et données présentes : 16 boutiques, 21 employés, 8 produits, 87 ventes ;
- authentification e-mail opérationnelle sans confirmation obligatoire (`mailer_autoconfirm = true`) ;
- la fonction `initier_boutique` et les tables RLS existent.

Deux manques subsistent et bloquent la synchronisation :

1. colonnes `produits.images`, `produits.categorie`, `produits.date_ajout`,
   `produits.qr_code_data` **absentes** → tout envoi de produit est refusé (erreur 42703)
   et reste indéfiniment en file d'attente ;
2. aucune table dans la publication `supabase_realtime` → mesure faite avec une sonde
   WebSocket : abonnement accepté, mais **aucune diffusion** reçue 20 s après une
   modification confirmée d'une ligne `produits`.

⇒ Exécuter `supabase/migration_temps_reel.sql` (idempotent, ~60 lignes) dans
**SQL Editor**, puis relancer l'application.

Pour un projet neuf :

1. Créer un projet sur <https://supabase.com> (offre gratuite suffisante).
2. Ouvrir **SQL Editor** et exécuter **tout** `supabase/schema.sql`
   (il est idempotent : tables, RLS, RPC, colonnes manquantes, trigger `maj_ts`,
   `replica identity full` et publication `supabase_realtime`).
   Sur une base déjà existante, `supabase/migration_temps_reel.sql` suffit.
3. Vérifier la publication :
   ```sql
   select tablename from pg_publication_tables where pubname = 'supabase_realtime';
   -- doit lister les 10 tables
   ```
4. Renseigner l'URL et la clé « anon public » (Settings → API), soit dans
   `lib/core/supabase_config.dart`, soit au lancement :
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://<projet>.supabase.co \
               --dart-define=SUPABASE_ANON_KEY=<anon-key>
   ```

## 3. Vérifier que « c'est bien synchronisé »

1. Installer l'application sur **deux appareils** et ouvrir **la même boutique**
   (même nom de boutique, connexion locale sur chaque appareil).
2. Sur l'appareil A : enregistrer une vente.
3. Attendu : l'appareil B affiche le stock mis à jour **sans aucune action** —
   bandeau « Synchronisation en direct » dans l'en-tête, message
   « Nouvelle vente enregistrée sur un autre appareil ».
4. Contrôler côté base : `select id, quantite, maj_ts from produits where boutique_id = '<id>' order by maj_ts desc limit 5;`

Sonde serveur (sans passer par l'application) : `python realtime_probe.py` réécrit une
ligne `produits` à l'identique et indique si la diffusion Realtime revient, et en
combien de temps. Un échec signifie que la publication `supabase_realtime` est
incomplète.

## 4. Dépannage

| Symptôme | Cause probable | Action |
| --- | --- | --- |
| « N en attente de synchro » qui ne descend pas | URL/clé invalide, ou schéma incomplet (colonne absente) | Relancer `schema.sql`, contrôler les identifiants |
| Aucune réception instantanée, mais les données finissent par arriver | Table absente de la publication Realtime | Section 4 de `schema.sql`, puis Realtime → Tables dans le dashboard |
| Rien ne part | Boutique créée hors ligne | Éteindre/rallumer le réseau dans l'app pour déclencher l'envoi de la file |
