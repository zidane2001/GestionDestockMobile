# Runbook UAT — Ma Boutique mobile

## 1. Objectif

- **Story :** synchroniser l'ensemble des données de la boutique et afficher des suggestions de stock instantanées.
- **Critères couverts :**
  - création et connexion d'une boutique ;
  - recherche instantanée, accentuée, fautive et produits en rupture ;
  - produit, vente, caisse, dépense, retour, défectueux, pointage, notifications et journal ;
  - droits Patron / Manager / Caissière ;
  - synchronisation immédiate entre deux appareils ;
  - mise en file hors ligne et reprise ;
  - sécurité de l'isolation d'une boutique.
- **Périmètre exclu :** biométrie matérielle, envoi e-mail, partage vers une application tierce et notification push système (ces flux nécessitent des services externes ou des permissions non déterministes).

## 2. Préconditions

- **Environnement :** branche `main` du dépôt GitHub, APK debug sur émulateur Android API 36.
- **Base :** projet Supabase configuré ; tables `boutiques`, `employes`, `produits`, `ventes`, `depenses`, `retours`, `pointages`, `activites`, `appareils`, `notifications` joignables.
- **Schéma requis :** `supabase/schema.sql` ou `supabase/migration_temps_reel.sql` appliqué, avec les dix tables dans `supabase_realtime` et `replica identity full`.
- **Fixtures réversibles :** boutique `UAT Sync 20261016`, patron `uat.patron@example.invalid`, manager `Manager UAT`, caissière `Caisse UAT`, produits `Café UAT`, `Chemise UAT`, `Rupture UAT`.
- **Deuxième appareil :** un second émulateur ou téléphone propre est nécessaire pour les étapes de réception temps réel. Aucun compte réel ni donnée métier existante ne doit être modifié.
- **Sécurité :** aucune clé `service_role`, mot de passe ni jeton ne doit apparaître dans les preuves.

## 3. Script d'exécution

| Étape | Sécurité | Action exacte | Résultat attendu | Preuve | Stop si |
|---|---|---|---|---|---|
| 01 | lecture seule | Lancer `flutter analyze --no-pub`. | Zéro problème d'analyse. | `01-analyse.txt` | Une erreur est relevée. |
| 02 | lecture seule | Lancer `flutter test --no-pub`. | Tous les tests passent. | `02-tests.txt` | Un test échoue. |
| 03 | lecture seule | Construire et installer l'APK debug puis ouvrir l'application. | Accueil affiché sans exception Flutter. | `03-accueil.png` | Crash, erreur ou permission bloquante. |
| 04 | fixture réversible | Créer `UAT Sync 20261016` avec le patron. | Session patron ouverte ; boutique, employé et appareil créés. | `04-creation.png` | Validation ou création échoue. |
| 05 | fixture réversible | Ajouter Café UAT (stock 8), Chemise UAT (stock 3), Rupture UAT (stock 0). | Les trois produits sont visibles, rupture signalée. | `05-stock.png` | Produit absent ou montant/stock erroné. |
| 06 | lecture seule | Dans la recherche de stock, saisir `caf`, `café`, `chemisse`, puis vider le champ. | Suggestions à chaque frappe ; accents et faute tolérés ; stock restauré après effacement. | `06-recherche.png` | Suggestion absente ou nécessite validation. |
| 07 | fixture réversible | Ouvrir la vente, rechercher Café UAT, vendre quantité 2 au prix affiché. | Stock -2, caisse +total, vente, notification et activité créées. | `07-vente.png` | Une donnée dérivée est absente ou fausse. |
| 08 | lecture seule | Tenter une vente supérieure au stock puis un prix nul. | Chaque garde affiche le message de blocage et ne modifie rien. | `08-gardes-vente.png` | Une vente invalide est acceptée. |
| 09 | fixture réversible | Signaler un Café UAT défectueux avec description, puis un retour échange. | Stock et retours évoluent selon les règles ; notifications créées. | `09-retours.png` | Description facultative ou stock/caisse incohérent. |
| 10 | fixture réversible | Enregistrer une dépense et une sortie de caisse, puis tenter une somme rendant la caisse négative. | Les opérations valides modifient la caisse ; la dernière est bloquée. | `10-caisse.png` | Caisse négative ou garde absente. |
| 11 | fixture réversible | Créer Manager UAT et Caisse UAT ; se reconnecter avec chaque rôle. | Écrans et actions respectent la matrice des permissions. | `11-roles.png` | Une action interdite est accessible. |
| 12 | fixture réversible | Pointer arrivée puis départ sous Manager/Caissière. | Un pointage journalier cohérent est visible au patron. | `12-pointage.png` | Doublon ou heure absente. |
| 13 | fixture réversible | Modifier/supprimer logiquement Chemise UAT sous Patron ; consulter journal, notifications, appareils et rapport. | Historique conservé, produit inactif, vues patron accessibles. | `13-patron.png` | Perte d'historique ou visibilité incorrecte. |
| 14 | fixture réversible | Désactiver réseau, créer une modification ; réactiver réseau. | Compteur de file augmente hors ligne puis revient à zéro après reprise. | `14-hors-ligne.png` | Perte de la modification ou file bloquée. |
| 15 | fixture réversible | Sur appareil A et B connectés à la même fixture, modifier le stock sur A. | B reçoit le changement sans action manuelle, affiche l'indicateur direct et le toast. | `15-realtime-b.png` + lecture base | B ne reçoit rien avant le délai de réconciliation. |
| 16 | fixture réversible | Modifier le compte boutique (nom/logo/statut autorisé) sur A. | B reçoit la modification et la session applique les règles. | `16-compte-b.png` + lecture base | Donnée de compte non propagée. |
| 17 | lecture seule | Vérifier qu'un événement ou un DELETE d'une autre boutique est ignoré. | Aucune donnée de la fixture n'est modifiée. | `17-isolation.txt` | Contamination inter-boutique. |
| 18 | nettoyage | Supprimer exclusivement les fixtures UAT et vérifier qu'aucune ligne UAT ne demeure. | Nettoyage confirmé par lecture. | `18-nettoyage.txt` | Toute donnée préexistante serait concernée. |

## 4. Conditions d'arrêt

- Écart entre le résultat observé et le résultat attendu : arrêt immédiat du parcours concerné et statut `FAIL`.
- Absence de second appareil, de publication Realtime ou de méthode sûre pour créer/importer la fixture : statut `BLOCKED` des étapes 15–18 ; aucune donnée réelle n'est modifiée.
- Toute action qui toucherait une boutique existante ou demanderait de révéler un secret : arrêt immédiat.

## 5. Nettoyage

- Les seuls identifiants supprimables sont ceux préfixés `UAT Sync 20261016`, `UAT`, ou créés pendant l'exécution.
- Suppression via l'interface ou une procédure tenant autorisée, puis lecture de vérification.
- Les comptes/fixtures réels et les artefacts d'autres utilisateurs sont hors périmètre.

## 6. Résultat

- **Statut global :** PARTIEL ; certains parcours et contrôles de sécurité restent à rejouer. Voir le rapport détaillé, qui prévaut sur ce résumé.
- **Preuves :** dossier `qa/evidence/2026-10-16/`.
- **Exécution :** 362 tests automatisés, analyse statique sans erreur, APK debug construit/installé, parcours UI Android exécutés.
- **Écarts corrigés pendant l'UAT :** reprise automatique après reconnexion, rechargement du compte boutique, réconciliation légère du compte, badge de file silencieuse, isolement des DELETE temps réel.
- **Critères non testés ou incomplets :** échange, garde de prix nul en interface, deux appareils vierges, écritures inter-boutiques et dernier correctif du badge en interface ; biométrie matérielle, e-mail, partage externe et push système sont exclus.
- **Nettoyage :** lignes métier de la fixture supprimées du serveur et données locales Android effacées. L'identité technique Supabase Auth créée pour la fixture nécessite une suppression administrative côté serveur, sans impact sur les tables métier.
