# Parcours Android : accueil et garde de création

Objectif : vérifier l'accès à la création et le refus d'un formulaire vide sur la branche enterprise-apple-redesign. Périmètre en lecture seule : aucune boutique ni donnée commerciale créée. La synchronisation, les permissions serveur et les autres parcours sont exclus.

Préconditions : APK debug de la branche installé sur emulator-5554 ; application ouverte sur l'accueil ; écran et outil ADB disponibles ; aucune authentification ou connexion réseau requise. Menu attendu : « Créer ma boutique ». Pas de fixture ni de secret.

| Étape | Action | Résultat attendu | Preuve | Arrêt |
|---|---|---|---|---|
| 1 | Depuis l'accueil, toucher « Créer ma boutique ». | Le formulaire « Créer ma boutique » apparaît. | creation-formulaire.png | Formulaire absent. |
| 2 | Sans saisir aucune donnée, faire défiler jusqu'à « Créer la boutique » et toucher le bouton. | Le formulaire reste ouvert ; les erreurs pour le nom, l'email et le mot de passe apparaissent. | creation-gardes.png | Navigation vers une boutique ou erreur absente. |
| 3 | Revenir à l'accueil avec Retour. | L'accueil réapparaît ; aucune boutique n'a été créée. | creation-retour.png | Accueil absent. |

Arrêt immédiat en cas d'écart. Nettoyage : revenir à l'accueil ; aucune donnée saisie ou fixture persistante. Vérification : accueil à l'écran. Résultats à noter après chaque étape ; ne pas déduire un test serveur d'une capture UI.

Résultats : étape 1 PASS — formulaire visible, capture creation-formulaire.png.
Étape 2 PASS — formulaire toujours ouvert ; les trois messages de validation sont présents dans l'arbre d'accessibilité, capture creation-gardes.png.
Étape 3 PASS — retour à l'accueil confirmé, capture creation-retour.png. Aucune donnée n'a été saisie ; aucune fixture à supprimer.

Verdict : PASS pour ce parcours limité. La création valide, le stock, les ventes et la synchronisation ne sont pas testés par ce scénario.
