# Runbook UAT complet — rôles et parcours métier

## Objectif et périmètre

Valider sur la branche `enterprise-apple-redesign` les parcours Patron, Manager et Caissière, les contrôles négatifs, le hors-ligne et, si l'amorçage sécurisé le permet, le temps réel sur deux appareils.

Sont exclus : biométrie réelle, envoi d'e-mail, partage vers une application tierce, paiement bancaire et notifications push externes.

## Préconditions

- APK debug construit depuis la branche courante et installé sur `emulator-5554`.
- Second AVD `mb_test2` démarré et APK installé pour les étapes 15–16.
- Fixture exclusivement réversible : boutique `UAT Roles 20261017`, patron `uat.roles@example.invalid`, manager `Manager UAT`, caissière `Caisse UAT`.
- Produits : `Café UAT` stock 8, `Chemise UAT` stock 3, `Rupture UAT` stock 0.
- Aucun secret, jeton ou donnée d'une boutique existante dans les preuves.

## Exécution

| Étape | Sécurité | Action exacte | Résultat attendu | Preuve | Stop si |
|---|---|---|---|---|---|
| 01 | lecture seule | Analyse, 366 tests et build APK. | Aucun échec. | sorties de commande | échec |
| 02 | fixture | Créer la boutique UAT et le compte Patron. | Tableau de bord Patron ouvert. | 02-patron-creation.png | création refusée |
| 03 | fixture | Ajouter les trois produits UAT. | Stocks 8, 3 et 0 visibles. | 03-stock.png | valeur fausse |
| 04 | lecture seule | Rechercher `caf`, `café`, `chemisse`, puis effacer. | Suggestions immédiates et tolérantes. | 04-recherche.png | suggestion absente |
| 05 | fixture | Vendre 2 Café UAT. | Stock 6, vente et caisse mises à jour. | 05-vente.png | dérivé incohérent |
| 06 | garde | Tenter survente et prix nul. | Refus sans mutation. | 06-garde-vente.png | vente acceptée |
| 07 | fixture | Déclarer un produit défectueux avec description ; tenter sans description. | Cas valide enregistré, cas vide refusé. | 07-defectueux.png | garde absente |
| 08 | fixture | Enregistrer un retour échange puis un remboursement valide. | Retours visibles, caisse cohérente. | 08-retours.png | incohérence |
| 09 | fixture | Dépense et sortie valides, puis sortie supérieure au solde. | Valides enregistrées, négatif refusé. | 09-caisse.png | caisse négative |
| 10 | fixture | Créer Manager UAT et Caisse UAT. | Comptes actifs visibles. | 10-comptes.png | création refusée |
| 11 | rôle | Connexion Manager, vérifier écrans autorisés/interdits, arrivée et départ. | Permissions et pointage corrects. | 11-manager.png | action interdite accessible |
| 12 | rôle | Connexion Caissière, vérifier écrans autorisés/interdits, vente et pointage. | Permissions minimales respectées. | 12-caissiere.png | administration accessible |
| 13 | rôle | Retour Patron : journal, notifications, appareils, rapports, modification et désactivation produit. | Vues accessibles, historique conservé. | 13-patron-admin.png | perte ou visibilité fausse |
| 14 | hors-ligne | Couper le réseau, créer une opération, rétablir le réseau. | File augmente puis revient à zéro. | 14-hors-ligne.png | perte ou file bloquée |
| 15 | multiappareil | Installer sur `mb_test2` et importer la boutique par le flux public. | Session ouverte sans clé privilégiée mobile. | 15-import-b.png | import sécurisé indisponible |
| 16 | multiappareil | Modifier le stock sur A et observer B. | B reçoit la valeur automatiquement. | 16-realtime-b.png | absence de propagation |
| 17 | nettoyage | Supprimer uniquement la fixture UAT et effacer les données locales des deux émulateurs. | Aucune ligne métier UAT locale ; aucune donnée préexistante touchée. | 17-nettoyage.txt | cible ambiguë |

## Conditions d'arrêt et nettoyage

Un écart arrête le parcours concerné ; les parcours indépendants suivants peuvent continuer. L'échec d'import sécurisé classe 15–16 `BLOCKED` sans réintroduire de clé privilégiée. Nettoyage limité aux identifiants créés pendant ce run ; toute identité Auth orpheline est signalée pour suppression administrative.

## Résultat

- Statut global : EN COURS
- Résultat par étape :
  - 01 PASS — analyse et suite automatisée lancées sur la branche.
  - 02 PASS — boutique UAT et session Patron créées.
  - 03 PASS — stocks CafeUAT 8, ChemiseUAT 3 et RuptureUAT 0 affichés.
  - 04 FAIL — `caf` suggère CafeUAT, mais `chemisse` retourne 0 suggestion pour ChemiseUAT.
- Nettoyage : à exécuter en étape 17.
