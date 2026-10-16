# CAHIER DES CHARGES — APPLICATION « MA BOUTIQUE »

**Version :** 1.0 (complète)
**Date :** 18 août 2026
**Rédigé à partir de :** discussion client (discussion.md), analyse technique (ANALYSE_COMPLETE.md)
**Statut :** À valider par le client

---

## SOMMAIRE

1. Présentation du projet
2. Contexte et objectifs
3. Public cible et rôles
4. Spécifications fonctionnelles détaillées
5. Matrice des permissions
6. Règles de gestion
7. Notifications
8. Statistiques et export de données
9. Exigences techniques
10. Modèle de données
11. Sécurité
12. Exigences non fonctionnelles
13. Plan de développement
14. Estimation budgétaire
15. Gestion des risques
16. Validation du cahier des charges
17. Annexes

---

## 1. PRÉSENTATION DU PROJET

### 1.1 Intitulé
Développement d'une application mobile de gestion de boutique nommée **« Ma Boutique »**, destinée à une petite équipe commerciale (Patron, Manager, Caissière).

### 1.2 Objectifs
- Centraliser les données de la boutique (stocks, ventes, dépenses, caisse) dans une base **partagée et synchronisée** entre tous les téléphones de l'équipe.
- Permettre à chaque membre de l'équipe d'utiliser l'application **selon son rôle** avec des droits strictement définis.
- Fournir au patron une **vue globale en temps réel** : solde de caisse, statistiques de ventes, bénéfices, activité de l'équipe.
- Fonctionner **hors-ligne** avec synchronisation automatique dès le retour du réseau (connexion instable en zone rurale).
- Garantir la **sécurité** : comptes avec mots de passe, code PIN à 4 chiffres, biométrie, contrôle des appareils.

### 1.3 Plateformes cibles
| Plateforme | Priorité | Note |
|---|---|---|
| Android | **Prioritaire** | APK installable directement, Android 6.0 minimum |
| iOS | Secondaire | Nécessite un Mac et un compte Apple Developer (99 €/an) — à confirmer |
| Windows | Optionnel | Via Flutter Desktop — en bonus si demandé |

### 1.4 Monnaie
Franc CFA par défaut. Choix possible à la création de la boutique : Franc CFA, Euro, Dollar US (liste extensible). Le symbole et le formatage s'adaptent partout dans l'application.

---

## 2. CONTEXTE ET OBJECTIFS

### 2.1 Contexte
Le client est propriétaire d'une boutique et souhaite gérer son activité avec son équipe :
- Le **patron** achète la marchandise et approvisionne le stock ;
- le **manager** et la **caissière** vendent en boutique et signalent les anomalies ;
- tous doivent disposer des **mêmes informations en temps réel** (stock, prix de vente, solde de caisse) depuis leur propre téléphone.

### 2.2 Objectifs métier
- Savoir à tout moment **combien il reste d'articles** et **combien d'argent est en caisse**.
- Savoir **qui a vendu quoi, quand, et à quel prix**.
- Suivre les **dépenses** (loyer, factures) et les **sorties de caisse justifiées**.
- Suivre les **produits défectueux** et les **retours** (remboursement ou échange).
- Suivre l'**activité de l'équipe** : pointage d'arrivée/départ, journal d'actions.
- Générer et **partager des rapports de ventes** (hebdomadaires, mensuels).

### 2.3 Critère de succès
> « Le patron ajoute un produit sur son téléphone ; le manager et la caissière le voient immédiatement (ou dès reconnexion) sur le leur. »

---

## 3. PUBLIC CIBLE ET RÔLES

| Rôle | Description |
|---|---|
| **Patron** | Propriétaire de la boutique. Compte créé en même temps que la boutique. Accès complet. |
| **Manager** | Responsable des opérations quotidiennes. Compte créé par le patron. |
| **Caissière** | Personnel en charge de la caisse. Compte créé par le patron. Droits limités. |

**Nombre d'utilisateurs visé :** 1 patron, 1-2 managers, 1-2 caissières (3 à 5 appareils).

---

## 4. SPÉCIFICATIONS FONCTIONNELLES DÉTAILLÉES

### 4.1 Écran d'accueil (première page de l'application)

Deux boutons principaux :

| Bouton | Comportement |
|---|---|
| **Créer une boutique** | Ouvre le formulaire de création (4.2) |
| **Se connecter à ma boutique** | Ouvre l'écran de connexion (4.3) |

### 4.2 Formulaire de création d'une boutique

| Champ | Obligatoire | Règles |
|---|---|---|
| Nom de la boutique | Oui | **Identifiant de connexion** ; unique (vérification de doublon) ; 3 à 40 caractères |
| Style de commerce | Non | Vêtements, Électronique, Alimentation… (liste ou texte libre) |
| Type de monnaie | Oui | Franc CFA (défaut), Euro, Dollar US… |
| Email du patron | Oui | Format email valide ; utilisé pour la récupération de compte |
| Mot de passe | Oui | Minimum 6 caractères |
| Confirmation du mot de passe | Oui | Doit correspondre au mot de passe |

À la validation : la boutique et le **compte patron** sont créés, la session est ouverte directement.

### 4.3 Écran de connexion

- Champ : **nom de la boutique**.
- Sélection du **rôle** : Patron / Manager / Caissière.
- Champ : **mot de passe**.
- Règles :
  - « Nom de boutique inconnu » si la boutique n'existe pas ;
  - « Mot de passe incorrect » si le mot de passe ne correspond pas au rôle choisi ;
  - « Compte suspendu. Contactez le patron. » si le compte employé est suspendu.

### 4.4 Déverrouillage de l'application (PIN)

- Si un **code PIN à 4 chiffres** est activé sur le compte, l'application demande le PIN à chaque ouverture.
- Bouton **biométrie** (empreinte/visage) si activée par l'utilisateur.
- Bouton **« PIN oublié ? »** : réinitialisation **uniquement via l'email du patron** (le patron reçoit un code de vérification ; l'employé le saisit puis définit un nouveau PIN).
- En cas de 5 saisies erronées : temporisation (ex. 30 secondes) pour éviter le brute force.

### 4.5 Interface principale (commune aux 3 rôles)

- **Barre du haut** : nom + logo de la boutique, icône cloche des notifications (badge du nombre de non-lues).
- **Navigation** : 2 pages glissables (doigt vers la gauche/droite) + 2 onglets en bas :
  - Onglet 1 : **Tableau de bord** ;
  - Onglet 2 : **Actions & Stock**.
- Le **solde de la caisse est affiché en permanence** sur la page Tableau de bord pour les trois rôles.

### 4.6 Page 1 — Tableau de bord

| Élément | Patron | Manager | Caissière |
|---|---|---|---|
| Nom + logo de la boutique | ✅ | ✅ | ✅ |
| Solde de la caisse (gros format) | ✅ | ✅ | ✅ |
| Courbe d'évolution des ventes (7 j / 30 j) | ✅ | ✅ | — |
| Courbe des bénéfices + marge bénéficiaire | ✅ | ❌ | ❌ |
| Total des bénéfices sur produits vendus | ✅ | ❌ | ❌ |
| Statistiques basées sur les prix de vente (tendance, rythme, top produits) | ✅ | ✅ | — |
| Historique des ventes (produit, quantité, prix, vendeur) | ✅ | ✅ | Ses ventes uniquement |
| Bouton « Exporter les données » | ✅ | ✅ (rapport hebdo) | ❌ |
| Accès au journal d'activité | ✅ | ❌ | ❌ |
| Consultation des pointages des employés | ✅ | ❌ | ❌ |

### 4.7 Page 2 — Actions & Stock

#### 4.7.1 Boutons d'action (selon rôle)

| Bouton | Patron | Manager | Caissière |
|---|---|---|---|
| Enregistrer une vente | ✅ | ✅ | ✅ |
| Article vendu | ✅ | ✅ | ✅ |
| Article défectueux (avec champ description) | ✅ | ✅ | ✅ |
| Signaler un retour produit (remboursement/échange) | ✅ | ✅ | ✅ |
| Signaler une dépense (loyer, factures…) | ✅ | ✅ | ❌ |
| Justifier une diminution de caisse | ✅ | ✅ | ✅ |
| Ajouter / modifier / supprimer un produit | ✅ | ❌ | ❌ |
| Exporter un rapport | ✅ | ✅ | ❌ |
| Pointer arrivée / départ | — | ✅ | ✅ |

#### 4.7.2 Stock et recherche

- **Barre de recherche** : recherche instantanée par nom de produit, tolérante aux fautes d'orthographe (suggestions si le nom saisi ne correspond pas exactement).
- **Liste du stock** : chaque produit affiche nom, prix de vente, quantité.
- **Rupture de stock** : quantité affichée **« 0 » en rouge** ; le produit reste listé avec son nom et son prix.
- Le prix **d'achat n'apparaît jamais** pour les rôles manager/caissière.

### 4.8 Flux de vente

1. Recherche ou sélection du produit.
2. Saisie de la **quantité** (par défaut 1, max = stock disponible).
3. Saisie du **prix de vente réel** (pré-rempli avec le prix catalogue, modifiable pour les remises).
4. Bouton **« Signaler Vendu »**.
5. Effets automatiques :
   - stock diminué ;
   - caisse augmentée du total ;
   - notification envoyée à toute l'équipe **avec le nom du vendeur** ;
   - enregistrement dans l'historique des ventes et le journal d'activité.
6. Ventes bloquées si : quantité > stock, quantité = 0, prix ≤ 0.

### 4.9 Produits défectueux et retours

#### Produit défectueux (manager et caissière)
- Sélection du produit + **champ texte obligatoire** décrivant le problème.
- Effets : stock diminué de 1, notification au patron et au manager, visible dans les statistiques.

#### Retour d'un produit vendu (manager et caissière)
- Motif : **Remboursement** ou **Échange** + description.
- Effets :
  - Remboursement : caisse diminuée du prix, stock augmenté de 1 ;
  - Échange : stock augmenté de 1.
- Notification au patron.

#### Suivi des retours (patron uniquement)
- Liste des retours : produit, motif, description, auteur, date, statut.
- Le patron peut traiter le retour : statut **en attente / traité / refusé**.

### 4.10 Dépenses et sorties de caisse

#### Dépense (patron et manager)
- Champs : motif (loyer, électricité, impôts…), montant.
- Effets : caisse diminuée, notification à toute l'équipe, journal.

#### Justification de diminution de caisse (caissière, manager, patron)
- Champs : motif obligatoire, montant.
- Effets : caisse diminuée, notification au patron et au manager, journal.

#### Règle générale
- La caisse **ne peut jamais devenir négative** (message d'erreur sinon).

### 4.11 Gestion des produits (patron uniquement)

- **Ajouter** : nom, prix d'achat, prix de vente, quantité initiale.
- **Modifier** : toutes les informations d'un produit.
- **Supprimer** : le produit disparaît du stock actif mais **les ventes passées restent dans l'historique** (suppression logique, avec confirmation).

### 4.12 Gestion des comptes employés (patron uniquement, dans les paramètres)

| Action | Description |
|---|---|
| Créer un compte manager | Mot de passe choisi par le patron (min. 6 caractères) |
| Créer un compte caissière | Idem |
| Réinitialiser le mot de passe | Le patron attribue un nouveau mot de passe |
| Suspendre / activer un compte | Le compte suspendu ne peut plus se connecter ni utiliser l'app |
| Supprimer un compte | Définitif, avec confirmation |

### 4.13 Appareils connectés (patron uniquement)

- Liste des appareils utilisés dans la boutique : rôle, modèle de téléphone, dernière connexion, statut (autorisé / révoqué).
- Le patron peut **révoquer** un appareil : l'appareil est déconnecté et ne peut plus se reconnecter.
- Objectif : détecter l'utilisation d'un compte sur un téléphone non autorisé.

### 4.14 Journal d'activité (patron uniquement)

- Chronologie de toutes les actions : ventes, dépenses, produits ajoutés/supprimés, produits défectueux, retours, connexions, suspensions de comptes, pointages.
- Filtres : par type d'action, par employé, par période.

### 4.15 Pointage des employés (manager et caissière)

- Boutons « **Pointer arrivée** » et « **Pointer départ** » (un pointage par jour et par employé).
- Le patron consulte les pointages (qui est arrivé à quelle heure, parti à quelle heure).

### 4.16 Paramètres

| Option | Patron | Manager | Caissière |
|---|---|---|---|
| Activer / modifier le code PIN 4 chiffres | ✅ | ✅ | ✅ |
| Activer la biométrie (suggestion lors de l'activation du PIN) | ✅ | ✅ | ✅ |
| Changer le thème (clair / sombre) | ✅ | ✅ | ✅ |
| Gestion des comptes employés | ✅ | ❌ | ❌ |
| Appareils connectés | ✅ | ❌ | ❌ |
| Modifier le mot de passe (avec ancien mot de passe, ou réinitialisation via email en cas d'oubli) | ✅ | ❌ | ❌ |
| **Déconnexion** | ✅ | ✅ | ✅ |

La déconnexion ramène à l'écran d'accueil (créer / se connecter).

### 4.17 Notifications

- **In-app** (cloche, liste chronologique, badge non-lues) + **push** (notification téléphone même app fermée).
- Événements notifiés :

| Événement | Patron | Manager | Caissière |
|---|---|---|---|
| Nouvelle vente (avec nom du vendeur) | ✅ | ✅ | ✅ |
| Produit en rupture de stock | ✅ | ✅ | ✅ |
| Nouveau produit ajouté | ✅ | ✅ | ✅ |
| Dépense enregistrée | ✅ | ✅ | ✅ |
| Produit défectueux signalé | ✅ | ✅ | ✅ |
| Retour produit signalé | ✅ | ✅ | ✅ |
| Diminution de caisse justifiée | ✅ | ✅ | ✅ |
| Compte créé / suspendu | ✅ | ❌ | ❌ |
| Pointage d'un employé | ✅ | ❌ | ❌ |

### 4.18 Statistiques et export

#### Patron (rapport complet)
- Ventes par jour / semaine / mois (courbes).
- **Marge bénéficiaire** par produit (prix de vente − prix d'achat).
- **Solde total des bénéfices** (produits vendus).
- Produits les plus vendus, périodes de forte vente.
- Export **CSV/Excel** complet (prix d'achat et marges inclus) partageable (WhatsApp, email, fichiers).
- **Archivage automatique hebdomadaire** (rapport généré chaque lundi) consultable.

#### Manager (rapport hebdomadaire, 7 derniers jours)
- Nombre de pièces vendues, tendances, rythme de vente par produit, produits les plus rentables, chronologie des ventes.
- Export **CSV/Excel** partageable, **sans aucune donnée de prix d'achat**.

#### Caissière
- Pas d'export.

---

## 5. MATRICE DES PERMISSIONS (SYNTHÈSE)

| Fonction | Patron | Manager | Caissière |
|---|---|---|---|
| Créer une boutique | ✅ | ❌ | ❌ |
| Ajouter / modifier / supprimer un produit | ✅ | ❌ | ❌ |
| Voir le prix d'achat | ✅ | ❌ | ❌ |
| Voir le prix de vente | ✅ | ✅ | ✅ |
| Rechercher un produit | ✅ | ✅ | ✅ |
| Enregistrer une vente | ✅ | ✅ | ✅ |
| Article vendu / défectueux | ✅ | ✅ | ✅ |
| Retour produit | ✅ | ✅ | ✅ |
| Dépense | ✅ | ✅ | ❌ |
| Justification sortie de caisse | ✅ | ✅ | ✅ |
| Solde de la caisse | ✅ | ✅ | ✅ |
| Statistiques de ventes | ✅ | ✅ | ✅ (simplifié) |
| Bénéfices / marges | ✅ | ❌ | ❌ |
| Historique des ventes | ✅ | ✅ | Ses ventes |
| Gestion comptes employés | ✅ | ❌ | ❌ |
| Appareils connectés | ✅ | ❌ | ❌ |
| Journal d'activité | ✅ | ❌ | ❌ |
| Pointage | — | ✅ | ✅ |
| Export | ✅ (complet) | ✅ (hebdo sans coût d'achat) | ❌ |
| PIN / biométrie / thème / déconnexion | ✅ | ✅ | ✅ |

---

## 6. RÈGLES DE GESTION

| Règle | Comportement |
|---|---|
| Vente | Stock − quantité ; caisse + total ; notification à tous ; journal ; historique |
| Vente impossible | Si quantité demandée > stock → blocage avec message |
| Article défectueux | Stock − 1 ; description obligatoire ; notification patron + manager ; visible dans les stats |
| Retour remboursement | Caisse − prix ; stock + 1 ; notification patron |
| Retour échange | Stock + 1 ; notification patron |
| Dépense | Caisse − montant ; notification à tous ; journal |
| Sortie de caisse justifiée | Caisse − montant ; motif obligatoire ; notification patron + manager |
| Rupture de stock | « 0 » en rouge partout ; produit conservé avec nom et prix |
| Prix d'achat | Visible patron uniquement (UI **et** règles de sécurité cloud) |
| Caisse négative | Interdite (blocage avec message) |
| Suppression de produit | Logique : l'historique des ventes est conservé |
| Session | Persistante jusqu'à déconnexion manuelle ; contrôle du statut du compte à chaque ouverture |
| Compte suspendu | Connexion refusée ; déconnexion forcée sur les appareils déjà connectés |
| PIN | 4 chiffres ; 5 erreurs → temporisation ; réinitialisation via email du patron uniquement |
| Identifiant de connexion | Nom de la boutique (unique) + mot de passe par rôle |

---

## 7. NOTIFICATIONS

### 7.1 Types
- **In-app** : liste chronologique consultable dans l'application (icône cloche), badge des non-lues.
- **Push** : notification système même lorsque l'application est fermée.

### 7.2 Règles
- Une notification est créée pour chaque événement du tableau 4.17, selon le rôle destinataire.
- Conservation de l'historique des notifications (pas de limite stricte, purge au-delà de 90 jours conseillée).
- Marquer comme lues / tout marquer comme lu.

---

## 8. STATISTIQUES ET EXPORT DE DONNÉES

### 8.1 Indicateurs calculés
| Indicateur | Formule |
|---|---|
| Total d'une vente | prix réel de vente × quantité |
| Marge d'un produit | prix de vente − prix d'achat |
| Marge d'une vente | (prix de vente − prix d'achat) × quantité |
| Bénéfice total | Σ marges des produits vendus − Σ dépenses |
| Solde de la caisse | Solde initial + Σ ventes − Σ dépenses − Σ remboursements − Σ sorties justifiées |
| Rapport hebdomadaire | Données des 7 derniers jours glissants |

### 8.2 Formats d'export
- **CSV** (ouvrable dans Excel) : encodage UTF-8 avec BOM (compatibilité Excel Windows), colonnes séparées par `;`.
- Partage via le menu natif du téléphone (WhatsApp, email, fichiers…).
- Un rapport = un fichier daté dans le nom (ex. `rapport_ventes_2026-08-18.csv`).

### 8.3 Archivage
- Génération automatique chaque lundi 00:00 (rapport de la semaine écoulée).
- Rapports archivés consultables par le patron.

---

## 9. EXIGENCES TECHNIQUES

### 9.1 Stack
| Composant | Choix | Justification |
|---|---|---|
| Framework | Flutter (Dart) | Android + iOS + Windows en un seul code |
| Gestion d'état | Provider | Léger et éprouvé |
| Base locale (hors-ligne) | sqflite | L'application doit fonctionner sans réseau |
| Cloud & synchronisation | **Firebase** (Firestore, Auth, Cloud Messaging) | Hors-ligne natif de Firestore, auth intégrée, gratuit pour ce volume |
| Alternative cloud | Supabase (PostgreSQL) | À n'envisager que si le dev préfère SQL ; le hors-ligne devra être développé |
| Biométrie | local_auth | Empreinte / visage natif |
| Graphiques | fl_chart | Courbes ventes / bénéfices |
| Export CSV | Package csv | Simple et léger |
| Partage de fichiers | share_plus | Menu natif WhatsApp/email |
| Formatage monnaie | intl | FCFA / € / $ |
| Détection réseau | connectivity_plus | Déclencher la synchronisation |
| Informations appareil | device_info_plus | Affichage « appareils connectés » |

### 9.2 Architecture
- Architecture en couches : **UI → Providers → Repositories → (Base locale + Cloud)**.
- **Offline-first** : toute écriture passe d'abord par sqflite (file « outbox »), puis est synchronisée vers le cloud à la reconnexion.
- Identifiants : **UUID générés côté client** (indispensable au mode hors-ligne).
- Conflits : horodatage serveur, dernière écriture gagne, vérification du stock à la synchronisation.
- Le **prix d'achat n'est jamais envoyé** aux appareils manager/caissière (filtrage cloud + règles de sécurité).

### 9.3 Structure des fichiers (cible)
```
lib/
├── main.dart
├── core/          # constantes, utilitaires, services (auth, sync, notifications)
├── data/          # database.dart, repositories, service cloud
├── models/        # boutique, employe, produit, vente, depense, retour,
│                  # notification, pointage, activite, appareil
├── providers/     # session, boutique, stock, vente, notifications
├── screens/       # 1 fichier par écran (voir §4)
└── widgets/       # composants réutilisables
```

### 9.4 Migration du prototype existant
Le prototype actuel (lib/main.dart + lib/database.dart) est conservé comme base :
1. Découper le fichier main.dart unique en couches (modèles, providers, écrans).
2. Étendre la base sqflite avec les nouvelles tables (§10).
3. Remplacer la sélection de rôle par le vrai flux d'authentification (création boutique / connexion).
4. Ajouter la notion de boutique et d'employés.

---

## 10. MODÈLE DE DONNÉES

### 10.1 Table `boutiques`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| nom | TEXT | Unique — identifiant de connexion |
| style_commerce | TEXT | Facultatif |
| monnaie | TEXT | FCFA (défaut), EUR, USD… |
| email_patron | TEXT | Récupération de compte |
| logo_url | TEXT | Facultatif |
| solde_caisse | REAL | Mis à jour à chaque opération |
| date_creation | TIMESTAMP | |
| date_modification | TIMESTAMP | |

### 10.2 Table `employes`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| boutique_id | TEXT FK | |
| role | TEXT | patron \| manager \| caissiere |
| mot_de_passe_hash | TEXT | Hashé (bcrypt/argon2) |
| pin_hash | TEXT | Nullable, hashé |
| biometrie_active | INTEGER | 0/1 |
| theme | TEXT | clair \| sombre |
| statut | TEXT | actif \| suspendu |
| date_creation | TIMESTAMP | |

### 10.3 Table `produits`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| boutique_id | TEXT FK | |
| nom | TEXT | |
| prix_achat | REAL | Patron uniquement |
| prix_vente | REAL | Visible par tous |
| quantite | INTEGER | |
| est_defectueux | INTEGER | 0/1 |
| actif | INTEGER | 0 = supprimé (logique) |
| date_ajout / date_modification | TIMESTAMP | |

### 10.4 Table `ventes`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| boutique_id | TEXT FK | |
| produit_id | TEXT FK | |
| produit_nom | TEXT | Copie pour l'historique |
| quantite | INTEGER | |
| prix_unitaire_reel | REAL | Prix réellement pratiqué |
| total | REAL | |
| vendeur_id | TEXT FK | |
| vendeur_role | TEXT | |
| date_vente | TIMESTAMP | |

### 10.5 Table `depenses`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| boutique_id | TEXT FK | |
| description | TEXT | |
| montant | REAL | |
| auteur_id | TEXT FK | |
| auteur_role | TEXT | |
| type | TEXT | depense \| sortie_justifiee |
| motif_justification | TEXT | Si sortie justifiée |
| date_depense | TIMESTAMP | |

### 10.6 Table `retours`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| boutique_id | TEXT FK | |
| vente_id | TEXT FK | Facultatif |
| produit_id | TEXT FK | |
| motif | TEXT | remboursement \| echange \| defectueux |
| description | TEXT | Obligatoire si défectueux |
| auteur_id | TEXT FK | |
| statut | TEXT | en_attente \| traite \| refuse |
| date_retour | TIMESTAMP | |

### 10.7 Table `notifications`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| boutique_id | TEXT FK | |
| destinataire_role | TEXT | patron \| manager \| caissiere \| tous |
| titre / message | TEXT | |
| type | TEXT | vente \| depense \| stock \| produit \| retour \| compte \| pointage |
| est_lu | INTEGER | 0/1 |
| date_envoi | TIMESTAMP | |

### 10.8 Table `pointages`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| employe_id | TEXT FK | |
| boutique_id | TEXT FK | |
| date | TEXT (AAAA-MM-JJ) | Un pointage par jour/employé |
| heure_arrivee | TEXT (HH:MM) | |
| heure_depart | TEXT (HH:MM) | Nullable |

### 10.9 Table `journal_activites`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| boutique_id | TEXT FK | |
| employe_id | TEXT FK | |
| employe_role | TEXT | |
| type | TEXT | vente \| depense \| produit \| retour \| connexion \| compte \| pointage |
| description | TEXT | Texte descriptif |
| date | TIMESTAMP | |

### 10.10 Table `appareils`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| boutique_id | TEXT FK | |
| employe_id | TEXT FK | |
| identifiant_appareil | TEXT | UUID stocké sur le téléphone |
| nom_appareil | TEXT | Modèle du téléphone |
| fcm_token | TEXT | Notifications push |
| actif | INTEGER | 1 = autorisé, 0 = révoqué |
| derniere_connexion | TIMESTAMP | |

### 10.11 Table `settings` (locale uniquement)
| Champ | Type | Notes |
|---|---|---|
| key / value | TEXT | Boutique courante, employé courant, thème, PIN actif… |

---

## 11. SÉCURITÉ

### 11.1 Authentification
- Comptes : boutique + rôle + mot de passe (minimum 6 caractères).
- Mots de passe **hashés** (bcrypt ou argon2) — jamais en clair, jamais dans les logs.
- Sessions persistantes jusqu'à déconnexion manuelle.

### 11.2 Code PIN et biométrie
- PIN 4 chiffres, stocké hashé, vérifié localement.
- 5 erreurs → temporisation 30 secondes.
- Réinitialisation uniquement via **l'email du patron** (code de vérification envoyé à l'email du patron).
- Biométrie optionnelle (local_auth), activable seulement après activation du PIN.

### 11.3 Protection des données sensibles
- Le **prix d'achat** est protégé par les **règles de sécurité du cloud** (lecture réservée au rôle patron) ET n'est jamais transmis aux appareils des autres rôles.
- Règles cloud : écritures limitées par rôle (produits → patron ; ventes/dépenses/retours → rôles habilités).

### 11.4 Contrôle des appareils
- Chaque téléphone a un identifiant unique enregistré au premier lancement.
- Le patron voit et peut **révoquer** les appareils connectés.
- Un appareil révoqué est déconnecté et refuse toute reconnexion.

### 11.5 Sauvegarde
- Export manuel des données (CSV) disponible pour le patron.
- Données du cloud sauvegardées par l'infrastructure (Firestore multi-région).

---

## 12. EXIGENCES NON FONCTIONNELLES

### 12.1 Performances
| Critère | Objectif |
|---|---|
| Ouverture de l'application | < 3 s |
| Affichage du stock | < 1 s |
| Enregistrement d'une vente | < 1 s |
| Synchronisation après reconnexion | < 2 s après détection du réseau |
| Notification push | < 5 s après l'action |

### 12.2 Compatibilité
| Plateforme | Minimum |
|---|---|
| Android | Android 6.0 (API 23) |
| iOS | iOS 13 (si retenu) |
| Windows | Windows 10 (si retenu) |
| Taille APK | < 50 Mo |

### 12.3 Ergonomie
- Interface simple, gros boutons, adaptée à une utilisation debout en boutique.
- Navigation par glissement + onglets.
- Mode clair / sombre.
- Textes et montants lisibles ; formatage monétaire cohérent.
- Messages d'erreur clairs en français.

### 12.4 Fiabilité
- Fonctionnement hors-ligne complet (saisie possible sans réseau).
- Synchronisation automatique dès reconnexion.
- Aucune perte de donnée en cas de coupure pendant une saisie (écriture locale immédiate).

### 12.5 Maintenabilité
- Architecture en couches, fichiers découpés par domaine.
- Code commenté en français (sections clés).
- Tests unitaires sur la logique métier et tests widget sur les écrans.

---

## 13. PLAN DE DÉVELOPPEMENT

| Phase | Contenu | Durée | Livrable | Validation client |
|---|---|---|---|---|
| 0. Cadrage | Maquettes de tous les écrans, validation du parcours | 1 sem. | Maquettes approuvées | ✅ après chaque écran |
| 1. Socle | Architecture, base locale, écrans accueil/création/connexion, comptes avec mots de passe hashés | 2 sem. | Démo : créer une boutique + se connecter en 3 rôles | Test sur 1 téléphone |
| 2. Cœur métier | Ventes, stock, recherche, défectueux, retours, dépenses, justification caisse, tableaux de bord, notifications in-app | 3 sem. | App complète hors-ligne | Test complet en boutique |
| 3. Cloud & sync | Firebase (Auth, Firestore, règles), synchronisation multi-appareils, appareils connectés | 3 sem. | 2-3 téléphones synchronisés | Test réel : produit ajouté → visible par l'équipe |
| 4. Sécurité & confort | PIN, biométrie, récupération via email patron, thème, gestion comptes employés, journal, pointage | 2 sem. | Paramètres complets | Tests des scénarios de sécurité |
| 5. Stats & exports | Courbes, marges/bénéfices, exports CSV, rapport hebdo, archivage | 1-2 sem. | Rapports partageables | Vérification des chiffres |
| 6. Qualité & livraison | Tests, push FCM, packaging APK/Windows/iOS, documentation, formation | 2 sem. | APK + doc + formation | Recette finale |

**Durée totale estimée : 12 à 15 semaines.**

---

## 14. ESTIMATION BUDGÉTAIRE

### 14.1 Développement (forfait)
| Rubrique | Fourchette |
|---|---|
| Cadrage et maquettes (phase 0) | 200 - 400 € |
| Développement (phases 1 à 5) | 2 000 - 3 500 € |
| Tests, packaging, formation (phase 6) | 400 - 700 € |
| **Total** | **2 600 - 4 600 €** |

> Variante « 1 téléphone sans cloud » : 1 200 - 1 800 € — mais ne permet PAS à l'équipe de partager les données.

### 14.2 Frais récurrents et ponctuels
| Rubrique | Coût |
|---|---|
| Firebase (Auth + Firestore + FCM) | 0 € (plan gratuit suffisant pour 1 boutique) |
| Compte Google Play Store | 25 $ (une seule fois) |
| Compte Apple Developer | 99 €/an (si iOS retenu) |
| Noms de domaine (optionnel) | 10 - 15 €/an |

---

## 15. GESTION DES RISQUES

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Connexion instable | Élevée | Élevé | Hors-ligne complet dès la phase 2 ; message clair « en attente de synchronisation » |
| Fuite des prix d'achat | Moyenne | Très élevé | Règles de sécurité cloud + non-transmission aux appareils employés + test dédié |
| Conflits de synchronisation | Moyenne | Moyen | Dernière écriture gagne + contrôle de stock à la synchro |
| Perte / vol du téléphone du patron | Faible | Élevé | Réinitialisation par email, révocation d'appareils, sauvegardes CSV |
| Demandes supplémentaires en cours de route | Élevée | Moyen | Points de validation par phase ; évolutions notées pour une v2 |
| Non-adoption par l'équipe | Moyenne | Moyen | Formation, interface simple, pointage et notifications valorisants |
| Dépassement de budget | Moyenne | Élevé | Phases courtes avec validation ; aucun travail sans validation |

---

## 16. VALIDATION DU CAHIER DES CHARGES

**Client :** ______________________________
**Date :** ______________________________

☐ J'ai lu et compris l'ensemble du cahier des charges.
☐ Je valide les fonctionnalités décrites aux sections 4, 5, 6, 7 et 8.
☐ Je valide les choix techniques de la section 9.
☐ Je valide le planning (section 13) et le budget (section 14).

**Signature du client :** ______________________________

**Observations / modifications souhaitées :**

1. ___________________________________________________
2. ___________________________________________________
3. ___________________________________________________

---

## 17. ANNEXES

### Annexe A — Points à trancher par le client
1. iOS est-il nécessaire ? (nécessite Mac + 99 €/an)
2. Windows est-il nécessaire ?
3. Export : CSV suffit-il, ou faut-il du PDF ? (PDF = +0,5 semaine)
4. Logo de la boutique : le client fournira-t-il une image ?
5. Nombre d'employés maximum prévu ?

### Annexe B — Documents sources
- discussion.md : conversation complète avec Gemini (besoins détaillés).
- ANALYSE_COMPLETE.md : analyse technique, corrections et directives de réalisation.
- code.txt / lib/ : prototype Flutter existant (base de départ).