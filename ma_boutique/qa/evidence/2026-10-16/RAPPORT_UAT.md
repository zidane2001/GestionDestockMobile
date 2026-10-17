# Rapport d'exécution UAT — 16 octobre 2026

## Verdict

**PARTIEL — réserves importantes.** Plusieurs parcours ont été exécutés sur Android et des anomalies corrigées, mais tous les cas ne sont pas validés de bout en bout. Ce rapport ne constitue pas une validation de production.

## Résultats par parcours

| Étape | Statut | Observation |
|---|---|---|
| 01 Analyse | PASS | `flutter analyze --no-pub` : aucune erreur. |
| 02 Tests | PASS | 362 tests réussis. |
| 03 APK | PASS | Build debug, installation et lancement sur Android API 36. |
| 04 Boutique | PASS | Création et session Patron validées. |
| 05 Stock | PASS | Café, Chemise et Rupture créés ; stock zéro signalé. |
| 06 Recherche | PASS | Suggestion `Caf` immédiate en UI ; accents et faute `chemisse` couverts par les tests dédiés. |
| 07 Vente | PASS | Stock, caisse, activité et notification cohérents. |
| 08 Gardes vente | PARTIEL | Survente refusée sans mutation ; le garde de prix zéro reste à rejouer en interface. |
| 09 Défectueux / retour | PARTIEL | Description obligatoire, retrait de stock et remboursement validés ; parcours d'échange à rejouer. |
| 10 Caisse | PASS | Dépense et sortie valides ; solde négatif refusé. |
| 11 Rôles | PASS | Patron, Manager et Caissière connectés ; actions masquées selon permissions. |
| 12 Pointage | PASS | Arrivée et départ Manager visibles dans la vue Patron. |
| 13 Administration | PASS | Modification puis suppression logique d'un produit ; journal, notifications, appareils et rapports consultés. |
| 14 Hors-ligne | PASS après correction | File créée hors ligne puis vidée automatiquement au retour du réseau. |
| 15 Temps réel stock | PASS | Un second client authentifié modifie le stock ; l'application reçoit la quantité sans action manuelle. |
| 16 Temps réel compte | PASS après correction | Nom du compte distant reçu puis restauré en quelques secondes. |
| 17 Isolation | PARTIEL | Lecture vérifiée et filtrage des événements couvert par tests unitaires ; les refus d'écriture inter-boutiques par RLS ne sont pas validés en bout en bout. |
| 18 Nettoyage | PASS avec résidu Auth | Boutique et lignes métier supprimées ; données locales effacées. Seule l'identité technique Auth exige un administrateur serveur. |

## Bugs détectés et corrigés

1. Le retour réseau réel n'était pas observé : ajout du suivi natif `connectivity_plus` et reprise automatique différée.
2. Les changements distants de la boutique étaient écrits localement mais l'objet Boutique n'était pas rechargé dans le provider.
3. Les projets Supabase historiques sans publication Realtime de `boutiques` n'actualisaient pas le compte : ajout d'une réconciliation légère toutes les quatre secondes.
4. Une synchronisation silencieuse vidait la file sans rafraîchir son badge.
5. Les événements DELETE sans tenant pouvaient être ambigus : ils sont maintenant ignorés s'ils ne prouvent pas leur portée.

## Limites observées

- L'import initial d'une boutique sur un téléphone totalement neuf doit être remplacé par une API/RPC serveur sécurisée ; la clé `service_role` n'est volontairement plus embarquée dans l'application mobile.
- Le dernier correctif du badge de synchronisation a passé les tests automatisés, mais n'a pas encore été rejoué sur un nouvel APK en interface.
- La synchronisation sur deux appareils vierges, les conflits de modifications et les refus d'écriture inter-boutiques restent à tester avec un environnement de test adapté.
- Des secrets privilégiés historiques figurent dans des scripts du dépôt : leur révocation et rotation par l'administrateur sont nécessaires ; supprimer seulement les valeurs locales ne suffit pas.
- L'identité Supabase Auth technique d'une boutique supprimée doit être nettoyée par une fonction serveur privilégiée.
- Les plugins `mobile_scanner` et `share_plus` émettent un avertissement de migration Kotlin lors du build, sans échec de compilation.
