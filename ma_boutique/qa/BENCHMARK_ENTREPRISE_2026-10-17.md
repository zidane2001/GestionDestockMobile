# Benchmark et audit entreprise — 17 octobre 2026

Branche : `enterprise-apple-redesign`. Ce document consolide cinq audits indépendants et des sources publiques. Les comparaisons sont des pistes, pas une preuve que les fonctionnalités sont implémentées. Les analyses de code sont statiques sauf mention contraire. Avant toute mise en production, vérifier la configuration Supabase réellement déployée.

## Comparaisons

| N° | Référence | Comparaison avec l'application et implication à étudier |
|---|---|---|
| 1 | [Square : gestion des stocks](https://squareup.com/help/us/en/article/6110-manage-inventory-with-the-retail-pos-app) | Distingue réception, ajustement et comptage ; ici la quantité est principalement un état, sans registre complet de mouvements. |
| 2 | [Shopify : remboursement](https://help.shopify.com/en/manual/sell-in-person/shopify-pos/order-management/complete-refund-orders) | Relie les remboursements aux commandes et permet de choisir la remise en stock ; le retour actuel ne référence pas de vente d'origine. |
| 3 | [Odoo : sessions de caisse](https://www.odoo.com/documentation/19.0/applications/sales/point_of_sale/use.html) | Prévoit ouverture, comptage et clôture ; ces étapes ne sont pas établies dans le parcours actuel. |
| 4 | [Lightspeed : inventaires](https://retail-support.lightspeedhq.com/hc/en-us/articles/229129948-Performing-inventory-counts-in-Retail-POS) | Propose comptage et rapprochement d'écarts ; un parcours équivalent reste à concevoir. |
| 5 | [Loyverse : historique de stock](https://help.loyverse.com/help/inventory-history-and-valuation) | Associe mouvements, motifs et documents ; la traçabilité des mouvements doit être renforcée. |
| 6 | [Shopify : fonctions hors ligne](https://help.shopify.com/en/manual/sell-in-person/shopify-pos/selling-offline/offline-features) | Affiche les limites du hors-ligne et reprend la synchronisation ; la file actuelle ne résout pas les conflits métiers. |
| 7 | [Square : multi-boutique](https://squareup.com/us/en/point-of-sale/features/multi-store) | Associe droits et sites ; les permissions actuelles ne sont pas démontrées côté serveur. |
| 8 | [Lightspeed : commandes fournisseurs](https://x-series-support.lightspeedhq.com/hc/en-us/articles/25533748112923-Creating-a-purchase-order) | Suit fournisseurs et commandes de réapprovisionnement ; ce flux dépasse la simple modification de quantité. |
| 9 | [Android : architecture hors ligne](https://developer.android.com/topic/architecture/data-layer/offline-first) | Décrit source locale, files et conflits ; l'application utilise une file, mais écrase des valeurs absolues sans contrôle de version. |
| 10 | [SQLite : transaction atomique](https://www.sqlite.org/atomiccommit.html) | Une transaction regroupe les changements ; la vente et sa mise en file sont actuellement enregistrées séparément. |
| 11 | [PostgreSQL : isolation](https://www.postgresql.org/docs/current/transaction-iso.html) | La concurrence demande une stratégie transactionnelle et parfois des reprises ; les ventes sur plusieurs appareils peuvent perdre des variations. |
| 12 | [CouchDB : conflits de réplication](https://docs.couchdb.org/en/stable/replication/conflicts.html) | Rend explicites les révisions divergentes ; les modifications concurrentes actuelles peuvent être écrasées silencieusement. |
| 13 | [Supabase : événements Postgres](https://supabase.com/docs/guides/realtime/postgres-changes) | Les suppressions et leurs anciennes valeurs ont des limites ; une synchronisation durable doit gérer les appareils absents. |
| 14 | [Supabase : sélection et pagination](https://supabase.com/docs/reference/dart/select) | La limite de réponse par défaut nécessite une pagination ; les lectures actuelles ne sont pas paginées. |
| 15 | [Supabase : sécurité par ligne](https://supabase.com/docs/guides/database/postgres/row-level-security) | Le serveur doit imposer l'isolation ; les filtres dans le client ne prouvent pas les droits effectifs. |
| 16 | [OWASP : authentification](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html) | Les identités doivent reposer sur des secrets solides ; les identifiants techniques actuels sont dérivés d'un identifiant de boutique. |
| 17 | [OWASP : stockage des mots de passe](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html) | Les vérificateurs doivent être protégés ; mots de passe et PIN employés apparaissent en clair dans le modèle inspecté. |
| 18 | [OWASP : sécurité multi-locataire](https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Security_Cheat_Sheet.html) | L'appartenance doit être établie par une autorité fiable ; la politique et la fonction de rattachement du schéma local exigent un audit critique. |
| 19 | [Apple : onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding) | Privilégie une aide brève, contextuelle et facultative ; le premier ajout de produit mérite un accompagnement. |
| 20 | [Android : onboarding et permissions](https://developer.android.com/design/ui/mobile/guides/patterns/onboarding) | Demander une permission dans son contexte ; l'application les demande au démarrage avant explication. |
| 21 | [Apple : boutons](https://developer.apple.com/design/human-interface-guidelines/buttons) | Préconise des cibles tactiles suffisantes ; plusieurs commandes personnalisées sont inférieures à 44 points. |
| 22 | [Flutter : accessibilité](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling) | Tester libellés, cibles et agrandissement ; plusieurs icônes, formulaires et grilles exigent une vérification. |
| 23 | [Apple : barres d'onglets](https://developer.apple.com/design/human-interface-guidelines/tab-bars) | La navigation doit rester prévisible ; la sélection des onglets personnalisés doit être exposée aux lecteurs d'écran. |
| 24 | [W3C : contraste](https://www.w3.org/WAI/WCAG21/Techniques/general/G18) | Vise 4,5:1 pour du texte normal ; certaines paires du thème calculées statiquement sont sous ce seuil. |
| 25 | [Apple : icônes d'app](https://developer.apple.com/design/human-interface-guidelines/app-icons) | Une identité simple et cohérente doit rester lisible à petite taille ; les noms Smart Stock et Ma Boutique coexistent actuellement. |

## Bloqueurs observés

- **Sécurité** : le schéma du dépôt permet potentiellement un rattachement arbitraire à une boutique ; confirmer les politiques et droits déployés avant tout test ou modification du serveur. Les identités techniques sont prévisibles et les permissions employé ne sont pas démontrées côté serveur.
- **Secrets** : des scripts historiques contiennent des secrets privilégiés. Leur rotation et la revue de l'historique nécessitent l'administrateur ; ne pas réutiliser ces clés.
- **Intégrité métier** : des ventes concurrentes peuvent perdre des variations de stock ou de caisse. Une vente peut être persistée et synchronisée partiellement.
- **Retours** : le traitement applique des effets avant validation, tandis qu'un refus ne les compense pas ; absence constatée de lien à la vente d'origine.
- **Synchronisation** : conflits silencieux, suppressions potentiellement manquées, pagination absente et réconciliation de compte pouvant masquer une modification locale en attente.
- **Déploiement** : l'import initial sur appareil vierge n'est pas fonctionnel sans solution serveur sécurisée ; ne jamais réintroduire de clé privilégiée dans l'application.

## Ordre de travail et validation

1. Auditer les droits effectivement déployés et remplacer l'identité partagée par une authentification et des permissions serveur par personne ; tester lectures et écritures interdites avec deux boutiques.
2. Définir les règles métier des retours et des conflits hors ligne ; implémenter les ventes, mouvements de stock et caisse de manière atomique et idempotente, avec des tests de concurrence et de reprise.
3. Rendre explicites les états en attente, erreurs et limites hors ligne ; tester deux appareils, pertes réseau et redémarrages.
4. Ensuite seulement, faire évoluer par petites étapes l'identité, l'accessibilité et la prise en main ; pour chaque évolution, revue critique, tests automatisés et contrôle visuel sur appareils.

Le [rapport UAT](evidence/2026-10-16/RAPPORT_UAT.md) précise les parcours exécutés et les réserves. Ce benchmark ne constitue pas une certification ni une décision de déploiement.
