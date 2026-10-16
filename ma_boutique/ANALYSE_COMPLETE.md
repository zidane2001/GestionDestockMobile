# ANALYSE COMPLÈTE & DIRECTIVES DE RÉALISATION
## Application « Ma Boutique » — Gestion de boutique collaborative

**Version :** 2.0 (révisée)
**Date :** 18 août 2026
**Sources analysées :** discussion Gemini complète (discussion.md), cahier des charges DeepSeek (deepseekAnalyse.md), prototype Gemini (code.txt), code actuel du projet Flutter (lib/main.dart, lib/database.dart)

---

## TABLE DES MATIÈRES

1. Synthèse de la demande
2. État des lieux critique (ce qui existe, ce qui manque)
3. Corrections apportées aux analyses précédentes
4. Spécifications fonctionnelles détaillées
   - 4.1 Parcours utilisateur
   - 4.2 Rôles et matrice des permissions
   - 4.3 Compte Patron
   - 4.4 Compte Manager
   - 4.5 Compte Caissière
   - 4.6 Notifications
   - 4.7 Pointage & Journal d'activité
   - 4.8 Sécurité d'accès (PIN, biométrie, récupération)
   - 4.9 Statistiques & export
   - 4.10 Règles de gestion transverses (caisse, stock, retours)
5. Décisions techniques (directives)
6. Modèle de données complet
7. Directives écran par écran
8. Règles de sécurité cloud
9. Plan de réalisation en 6 phases
10. Plan de tests
11. Risques et mitigations
12. Estimation révisée
13. Checklist de livraison

---

## 1. SYNTHÈSE DE LA DEMANDE

Le client (non-développeur) veut une application **« Ma Boutique »** pour gérer sa boutique avec son équipe, sur **Android, iOS et Windows**, en **Flutter**. Les besoins exprimés dans la discussion se résument ainsi :

- **3 rôles** : Patron, Manager, Caissière.
- **1ère interface** : « Créer une boutique » (nom, style de commerce facultatif, monnaie, email du patron, mot de passe) ou « Se connecter à ma boutique » (nom de la boutique = identifiant, + rôle + mot de passe).
- **Patron** : contrôle total — tableau de bord (solde caisse en gros, courbes de ventes, marge bénéficiaire), gestion produits (ajouter/supprimer **seul**), recherche et vente, dépenses, retours, notifications, journal d'activité, export des statistiques, paramètres (comptes manager/caissière, suspension/réinitialisation, mot de passe, PIN 4 chiffres, biométrie, thème clair/sombre, appareils connectés, déconnexion).
- **Manager** : statistiques de vente **sans prix d'achat**, stock avec zéro en rouge en rupture, recherche, vente, boutons « Article vendu » / « Article défectueux » (avec champ texte), dépenses, historique des ventes, export hebdomadaire (7 jours), pointage, notifications, solde caisse.
- **Caissière** : version simplifiée — vente, recherche, produits vendus/défectueux, **justification des diminutions de caisse**, pointage, notifications, solde caisse.
- **Transverse** : interface à 2 pages glissables (page 1 = tableau de bord visuel ; page 2 = actions & stock), notifications pour tout le monde, solde caisse affiché en permanence, code PIN à 4 chiffres + biométrie pour tous, réinitialisation du PIN **uniquement via l'email du patron**, sessions persistantes, déconnexion dans les paramètres, **synchronisation entre les téléphones de l'équipe** (point central de la demande).

---

## 2. ÉTAT DES LIEUX CRITIQUE

### 2.1 Le prototype Gemini (code.txt / lib/main.dart)

**Ce qu'il fait bien :**
- Structure de base propre : modèles, ShopProvider (ChangeNotifier), 3 rôles, PageView 2 pages, notifications in-app, formulaires vente/dépense/produit, rupture de stock en rouge.
- Persistance locale avec sqflite (database.dart) correctement écrite.

**Ce qui ne répond PAS aux besoins :**
| Problème | Conséquence |
|---|---|
| Pas de création de boutique ni de vrais comptes — le bouton « Connexion Patron » ne demande aucun mot de passe | N'importe qui peut se connecter en patron |
| Données uniquement locales au téléphone (sqflite) | **Le manager ne verra JAMAIS les produits ajoutés par le patron** — c'est LA question centrale du client, le prototype y répond « non » |
| Pas de PIN, pas de biométrie, pas de thème, pas de déconnexion | Sécurité et confort absents |
| Pas de recherche produit, pas de boutons « Article vendu/défectueux », pas de retours, pas de pointage, pas de journal | 60 % des fonctions demandées manquent |
| Pas de dépenses par la caissière (justification de caisse) | Règle métier manquante |
| Pas de statistiques réelles (graphique placeholder) ni d'export | Fonction clé absente |
| `_cashBalance = 150000` codé en dur au premier lancement | Faux départ pour la gestion réelle |
| Un seul fichier main.dart de 862 lignes (code.txt) | Non maintenable à mesure que l'app grandit |

**Conclusion :** le prototype est un bon point de départ UI, mais il doit être **restructuré en architecture propre** et **étendu**, pas recopié tel quel.

### 2.2 Le cahier des charges DeepSeek (deepseekAnalyse.md)

Bon document de cadrage (structure, planning, budget), mais plusieurs incohérences et omissions — voir section 3.

---

## 3. CORRECTIONS APPORTÉES PAR RAPPORT AUX ANALYSES PRÉCÉDENTES

| # | Erreur / imprécision | Correction directive |
|---|---|---|
| 1 | Matrice notifications DeepSeek : caissière ❌ pour « Rupture de stock » et « Dépense » | **Tous les rôles reçoivent les notifications** (le client l'a dit explicitement : « à chaque fois qu'il y aura une dépense enregistrée tout le monde sera prévenu ») |
| 2 | DeepSeek confond « Signaler une dépense » et « Justifier une diminution de caisse » | Ce sont **2 fonctions distinctes** : dépense = patron/manager (loyer, factures) ; justification de baisse de caisse = caissière (et manager) avec motif. Les deux décrémentent la caisse mais la 2e est une explication d'une sortie, pas un enregistrement de dépense |
| 3 | DeepSeek : « Signaler un produit défectueux : patron ✅ » | Le patron **voit** et **gère** les signalements, mais c'est le manager et la caissière qui signalent |
| 4 | Modèle de données incomplet (DeepSeek) | Ajouter les tables **pointages**, **journal_activites**, **appareils**, **retours (avec statut)**, et le champ **monnaie** au niveau boutique |
| 5 | « Prix d'achat visible patron uniquement » : simple mention | Doit être **appliqué au niveau des règles de sécurité du cloud** (Firestore rules / RLS), pas seulement masqué dans l'UI — sinon les données fuient |
| 6 | « Export PDF ou Excel » flou | Décision : **CSV/Excel** (facile à générer sans dépendance lourde) partagé via le système natif (WhatsApp/email) — package `share_plus`. PDF optionnel en v2 |
| 7 | Récupération du PIN : vague chez DeepSeek | **Toute réinitialisation de PIN passe exclusivement par l'email du PATRON** (vérification + génération d'un code temporaire). Après réinitialisation, l'employé définit un nouveau PIN à la prochaine ouverture |
| 8 | Statistiques hebdomadaires | **Archivage automatique** chaque semaine (lundi 00:00) + génération manuelle à la demande. Le rapport manager/caissière est **sans prix d'achat**, celui du patron est complet (marge, bénéfice) |
| 9 | Windows | Cible principale = **Android** ; iOS nécessite un Mac et un compte Apple (99 €/an) ; Windows en bonus via Flutter Desktop. À confirmer avec le client |
| 10 | Vente : prix saisi par le vendeur | Le vendeur **saisit le prix réel de vente** (peut différer du prix catalogue — remise). Le prix catalogue est proposé par défaut |

---

## 4. SPÉCIFICATIONS FONCTIONNELLES DÉTAILLÉES

### 4.1 Parcours utilisateur

```
Démarrage de l'app
│
├── Écran d'accueil
│   ├── [Créer une boutique]  → formulaire : nom*, style (facultatif), monnaie* (FCFA/Euro/Dollar/…),
│   │                           email patron*, mot de passe*, confirmation → création du compte patron
│   └── [Se connecter à ma boutique] → nom boutique* + choix du rôle (Patron/Manager/Caissière) + mot de passe*
│
├── (Si déjà connecté + PIN actif) → écran de déverrouillage PIN 4 chiffres (ou biométrie)
│
└── Interface principale : PageView 2 pages (glissement gauche/droite + onglets en bas)
    ├── Page 1 : Tableau de bord (nom/logo boutique, solde caisse en gros, statistiques)
    └── Page 2 : Actions & Stock (boutons d'action selon le rôle + liste des produits + recherche)
```

**Règles de connexion :**
- L'identifiant de connexion est **le nom de la boutique** (unique) + mot de passe **par rôle**.
- Le compte patron est créé avec la boutique. Le manager et la caissière sont créés **par le patron** (paramètres).
- Session **persistante** (reste connecté jusqu'à déconnexion manuelle).
- Un compte **suspendu** ne peut plus se connecter.
- Mot de passe : minimum 6 caractères, hashé (jamais en clair).

### 4.2 Rôles et matrice des permissions

| Action | Patron | Manager | Caissière |
|---|---|---|---|
| Créer une boutique | ✅ | ❌ | ❌ |
| Ajouter / modifier / supprimer un produit | ✅ | ❌ | ❌ |
| Voir le prix d'achat | ✅ | ❌ | ❌ |
| Voir le prix de vente | ✅ | ✅ | ✅ |
| Rechercher un produit dans le stock | ✅ | ✅ | ✅ |
| Enregistrer une vente (quantité + prix réel) | ✅ | ✅ | ✅ |
| Bouton « Article vendu » | ✅ | ✅ | ✅ |
| Bouton « Article défectueux » (+ description) | ✅ | ✅ | ✅ |
| Signaler un retour produit (remboursement/échange) | ✅ | ✅ | ✅ |
| Enregistrer une dépense (loyer, factures…) | ✅ | ✅ | ❌ |
| Justifier une diminution de caisse | ✅ | ✅ | ✅ |
| Voir le solde de la caisse | ✅ | ✅ | ✅ |
| Voir les statistiques de vente | ✅ | ✅ | ✅ (simplifié) |
| Voir les bénéfices / la marge | ✅ | ❌ | ❌ |
| Historique des ventes | ✅ | ✅ | ✅ (ses ventes) |
| Créer / suspendre / supprimer un compte employé | ✅ | ❌ | ❌ |
| Réinitialiser un mot de passe employé | ✅ | ❌ | ❌ |
| Voir les appareils connectés / révoquer | ✅ | ❌ | ❌ |
| Journal d'activité | ✅ | ❌ | ❌ |
| Pointage arrivée/départ | — | ✅ | ✅ |
| Exporter les statistiques | ✅ (complet) | ✅ (hebdo, sans prix d'achat) | ❌ |
| Notifications | ✅ | ✅ | ✅ |
| Paramètres : PIN, biométrie, thème, déconnexion | ✅ | ✅ | ✅ |
| Modifier le mot de passe (ancien mdp / email) | ✅ | ❌ | ❌ |

### 4.3 Compte Patron — détail

**Page 1 — Tableau de bord :**
- Nom + logo de la boutique en tête.
- **Solde de la caisse en gros** (carte mise en avant, mise à jour en temps réel).
- Courbe d'évolution des ventes (7 jours / 30 jours).
- Courbe des bénéfices + **marge bénéficiaire** (calculée à partir du prix d'achat vs prix de vente) + **solde total des bénéfices** des produits vendus.
- Bouton **« Exporter les données »** (statistiques complètes).
- Icône notifications (cloche) dans la barre du haut.

**Page 2 — Actions & Stock :**
- Boutons : Enregistrer une vente, Signaler une dépense, Ajouter un produit, (Retours).
- **Recherche produit** (barre de recherche, tolérance aux fautes d'orthographe → suggestions).
- Liste du stock : nom, prix de vente, quantité — **quantité = 0 affichée en rouge**, le produit reste listé avec son prix.
- Accès à l'**historique des ventes** (produit, quantité, prix, **vendeur**).

**Section produits (patron uniquement) :**
- Ajouter : nom, prix d'achat, prix de vente, quantité initiale.
- Modifier un produit.
- Supprimer un produit (les ventes passées restent en historique — suppression logique).

**Espace retours :**
- Liste des retours signalés (produit, motif : **remboursement** ou **échange**, description, auteur, date, statut).
- Le patron peut traiter / clôturer un retour (statut : en_attente / traité / refusé).

**Paramètres (patron) :**
- **Comptes employés** : créer un compte manager (mot de passe choisi par le patron), créer un compte caissière (idem), supprimer, suspendre, réinitialiser le mot de passe.
- Modifier le mot de passe patron (avec ancien mot de passe, ou via email en cas d'oubli).
- Code PIN 4 chiffres (activation / modification).
- Reconnaissance biométrique (activation si le téléphone le permet).
- Réinitialisation du PIN (via email patron — aussi utilisable par le patron lui-même).
- Thème clair / sombre.
- **Appareils connectés** : liste des appareils actifs (qui, quel téléphone, dernière connexion), possibilité de révoquer un appareil.
- Déconnexion (retour à l'écran d'accueil).

**Autres :**
- **Journal d'activité** : chronologie de toutes les actions (qui a fait quoi, quand) — vente, dépense, ajout/suppression produit, signalement défectueux, retour, connexion…
- **Pointage des employés** : consultation des arrivées/départs du manager et de la caissière.
- **Notifications** : ventes (avec nom du vendeur), dépenses, ruptures de stock, nouveaux produits, produits défectueux, retours.

### 4.4 Compte Manager — détail

**Page 1 — Tableau de bord :**
- Nom/logo boutique + solde de la caisse en gros (uniquement le solde, « rien d'autre »).
- Statistiques des ventes **basées sur les prix de vente** (aucun prix d'achat).
- Produits les plus vendus, tendance / rythme de vente par produit.
- Historique des ventes (y compris celles de la caissière).

**Page 2 — Actions & Stock :**
- Boutons : Enregistrer une vente, Signaler une dépense, Article vendu, Article défectueux (avec champ texte), Justifier une diminution de caisse.
- **Recherche produit** + liste du stock (zéro en rouge).
- **Exporter le rapport hebdomadaire** (7 jours) : volume de ventes, chronologie, produits les plus vendus et les plus rentables — **sans prix d'achat**. Fichier numérique partageable (WhatsApp/email).

**Paramètres (manager) :** PIN 4 chiffres, biométrie, thème, déconnexion.
**Pointage :** bouton « Pointer arrivée » / « Pointer départ ».
**Notifications :** ventes, dépenses, nouveaux produits, ruptures.

### 4.5 Compte Caissière — détail

**Page 1 — Tableau de bord :** nom/logo boutique, solde caisse en gros, historique simplifié de ses ventes.
**Page 2 — Actions :**
- Enregistrer une vente (recherche avec suggestion en cas d'orthographe, quantité, prix de vente, bouton « Signaler vendu »).
- Article vendu / Article défectueux (avec description).
- **Justifier une diminution de caisse** (motif) — le manager et le patron voient l'action et la justification.
- Stock consultable (zéro en rouge).
**Paramètres (caissière) :** PIN, biométrie, thème, déconnexion.
**Pointage** : comme le manager.
**Notifications** : ventes, dépenses, nouveaux produits, ruptures.

### 4.6 Notifications

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

- **In-app** (obligatoire, dans la cloche) + **Push** (Firebase Cloud Messaging, en phase 4).
- Notifications conservées en base (historique consultable).

### 4.7 Pointage & Journal d'activité

- **Pointage** (manager + caissière) : bouton à l'ouverture de session — « Arrivée » puis « Départ ». Le patron consulte les pointages dans son interface. Les pointages sont datés.
- **Journal d'activité** (patron uniquement) : journalisation automatique de toute action métier (vente, dépense, produit, défectueux, retour, connexion, changement de mot de passe, suspension…). Consultation chronologique avec filtres (type, employé, date).

### 4.8 Sécurité d'accès

- **PIN 4 chiffres** : activable par chaque compte dans ses paramètres. À chaque ouverture de l'app (ou reprise après verrouillage), déverrouillage requis. PIN hashé (jamais stocké en clair).
- **Biométrie** : proposition à l'utilisateur lors de l'activation du PIN (« Voulez-vous aussi utiliser votre empreinte ? ») — via `local_auth`.
- **Oubli du PIN** : bouton « PIN oublié » → vérification **sur l'email du patron uniquement** (le patron reçoit un code / lien pour réinitialiser le PIN de l'employé concerné) → l'employé définit un nouveau PIN à la prochaine ouverture.
- **Mot de passe patron oublié** : réinitialisation via l'email Gmail renseigné à la création.
- **Comptes suspendus** : bloqués à la connexion et à l'ouverture de session.

### 4.9 Statistiques & export

- **Patron** : stats complètes (ventes, bénéfices, marge par produit, produits les plus vendus, périodes de vente). Export **complet** (y compris coûts d'achat et marges). Génération manuelle + **archivage automatique hebdomadaire**.
- **Manager** : export hebdomadaire (7 derniers jours) **sans prix d'achat** : nombre de pièces vendues, tendances, rythme de vente par produit, produits les plus rentables (en prix de vente), chronologie des ventes.
- **Format** : CSV/Excel (.csv ou .xlsx), partage via le système (WhatsApp, email, fichiers).
- **Caissière** : pas d'export.

### 4.10 Règles de gestion transverses

| Règle | Comportement |
|---|---|
| Vente | Stock -= quantité ; caisse += total (prix réel saisi × quantité) ; notification à tous ; journal |
| Vente impossible | Si quantité demandée > stock → blocage avec message |
| Article vendu (bouton) | Enregistre la vente de l'article sélectionné (même flux que la vente, sans saisie) |
| Article défectueux | Stock -= 1 ; notification patron + manager ; visible dans les stats (type défectueux) |
| Retour (remboursement) | Caisse -= prix ; stock += 1 ; notification patron ; statut à traiter |
| Retour (échange) | Stock += 1 ; notification patron ; statut à traiter |
| Dépense | Caisse -= montant ; notification à tous ; journal |
| Justification baisse de caisse | Caisse -= montant (si sortie) ; motif obligatoire ; notification patron + manager ; journal |
| Rupture de stock | Quantité affichée « 0 » **en rouge** partout ; produit conservé dans la liste avec nom + prix |
| Prix d'achat | Visible uniquement par le patron (masqué en UI **et** interdit par les règles de sécurité cloud) |
| Caisse | Ne peut jamais être négative (blocage avec message) |
| Monnaie | Définie à la création de la boutique (FCFA par défaut) ; formatage adapté partout |

---

## 5. DÉCISIONS TECHNIQUES (DIRECTIVES)

### 5.1 Stack recommandée

| Composant | Choix | Justification |
|---|---|---|
| Framework | **Flutter** (déjà utilisé) | Android + iOS + Windows, un seul code |
| Gestion d'état | **Provider** (continuité) ou Riverpod | Léger, adapté à la taille du projet |
| Base locale | **sqflite** (déjà en place) | Mode hors-ligne : l'app doit fonctionner sans réseau |
| Cloud + sync | **Firebase (Firestore + Auth + FCM)** — recommandé | **Persistance hors-ligne native de Firestore** (point décisif : le client veut que le manager voie les données du patron ; en zone à connexion instable, le hors-ligne est vital). Auth gratuit et fiable. |
| Alternative | Supabase (PostgreSQL + Realtime + RLS) | Bonne alternative open-source, mais le hors-ligne n'est pas natif (à développer) |
| Biométrie | `local_auth` | Empreinte / visage natif |
| Partage de fichiers | `share_plus` | Envoi du rapport par WhatsApp/email |
| Graphiques | `fl_chart` | Courbes ventes/bénéfices |
| Génération CSV/Excel | `csv` (léger) ou `excel` | Rapports exportables |
| Formatage monnaie | `intl` | FCFA / € / $ selon la boutique |
| Chiffrement PIN | `cryptography` (bcrypt/argon2) ou hash SHA-256 salé | Jamais en clair |

### 5.2 Architecture cible

```
lib/
├── main.dart                      # Bootstrap (init DB, provider, thème)
├── core/
│   ├── constants.dart             # Couleurs, seuils, textes
│   ├── utils/                     # format_monnaie, validators
│   └── services/                  # auth_service, sync_service, notif_service
├── data/
│   ├── database.dart              # sqflite local (existante, à étendre)
│   ├── repositories/
│   │   ├── boutique_repository.dart
│   │   ├── produit_repository.dart
│   │   ├── vente_repository.dart
│   │   ├── depense_repository.dart
│   │   ├── retour_repository.dart
│   │   ├── employe_repository.dart
│   │   ├── pointage_repository.dart
│   │   ├── journal_repository.dart
│   │   └── appareil_repository.dart
│   └── cloud/                     # firestore_service, auth_service (Firebase)
├── models/                        # (découper par fichier)
│   ├── boutique.dart
│   ├── employe.dart
│   ├── produit.dart
│   ├── vente.dart
│   ├── depense.dart
│   ├── retour.dart
│   ├── notification.dart
│   ├── pointage.dart
│   ├── activite.dart
│   └── appareil.dart
├── providers/                     # state management par domaine
│   ├── session_provider.dart      # rôle courant, compte, verrouillage PIN
│   ├── boutique_provider.dart     # caisse, infos boutique, thème
│   ├── stock_provider.dart        # produits, recherche
│   ├── vente_provider.dart
│   └── notif_provider.dart
├── screens/                       # 1 fichier par écran (voir section 7)
└── widgets/                       # composants réutilisables (cartes, listes)
```

**Principes directeurs :**
1. **Offline-first** : toutes les écritures passent d'abord par sqflite (file d'attente « outbox »), puis synchronisation vers Firestore à la reconnexion.
2. **Identifiants UUID générés côté client** (nécessaire pour la synchro hors-ligne).
3. **Horodatage serveur** (`serverTimestamp`) pour résoudre les conflits — dernière écriture gagne (acceptable pour cette taille de boutique).
4. Le prix d'achat n'est **jamais** téléchargé par les comptes manager/caissière (filtrage côté cloud + règles de sécurité).
5. Un `SyncService` écoute l'état réseau (`connectivity_plus`) et déclenche la réconciliation.

### 5.3 Migration depuis le prototype actuel

1. Découper `main.dart` (862 lignes) en fichiers par couche (modèles → providers → screens).
2. Conserver `database.dart`, l'étendre avec les nouvelles tables.
3. Remplacer l'écran de sélection de rôle par le vrai flux : accueil (créer/se connecter) → authentification.
4. Ajouter la notion de boutique et d'employés (le prototype n'a que le rôle courant).

---

## 6. MODÈLE DE DONNÉES COMPLET

(Convention : `PK` clé primaire, `FK` clé étrangère, `ID` UUID généré côté client.)

### Table `boutiques`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| nom | TEXT | Unique — identifiant de connexion |
| style_commerce | TEXT | Facultatif (vêtements, électronique…) |
| monnaie | TEXT | FCFA, EUR, USD… (défaut : FCFA) |
| email_patron | TEXT | Récupération de compte |
| logo_url | TEXT | Facultatif (phase 2) |
| solde_caisse | REAL | MAJ par chaque opération |
| date_creation | TIMESTAMP | |
| date_modification | TIMESTAMP | |

### Table `employes`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| boutique_id | TEXT FK | |
| role | TEXT | patron \| manager \| caissiere |
| mot_de_passe_hash | TEXT | Hashé (bcrypt/argon2) |
| pin_hash | TEXT | Hash du PIN 4 chiffres, nullable |
| biometrie_active | INTEGER | 0/1 |
| theme | TEXT | clair \| sombre (par compte) |
| statut | TEXT | actif \| suspendu |
| date_creation | TIMESTAMP | |

### Table `produits`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| boutique_id | TEXT FK | |
| nom | TEXT | |
| prix_achat | REAL | **Visible patron uniquement** |
| prix_vente | REAL | Visible par tous |
| quantite | INTEGER | |
| est_defectueux | INTEGER | 0/1 |
| actif | INTEGER | 0 = supprimé (suppression logique) |
| date_ajout / date_modification | TIMESTAMP | |

### Table `ventes`
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

### Table `depenses`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| boutique_id | TEXT FK | |
| description | TEXT | Loyer, facture… |
| montant | REAL | |
| auteur_id | TEXT FK | |
| auteur_role | TEXT | |
| type | TEXT | depense \| sortie_caisse_justifiee |
| motif_justification | TEXT | Si type = sortie justifiée |
| date_depense | TIMESTAMP | |

### Table `retours`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| boutique_id | TEXT FK | |
| vente_id | TEXT FK | Optionnel |
| produit_id | TEXT FK | |
| motif | TEXT | remboursement \| echange \| defectueux |
| description | TEXT | Champ libre (obligatoire si defectueux) |
| auteur_id | TEXT FK | |
| statut | TEXT | en_attente \| traite \| refuse |
| date_retour | TIMESTAMP | |

### Table `notifications`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| boutique_id | TEXT FK | |
| destinataire_role | TEXT | patron \| manager \| caissiere (ou « tous ») |
| titre / message | TEXT | |
| type | TEXT | vente \| depense \| stock \| produit \| retour \| compte \| pointage |
| est_lu | INTEGER | 0/1 |
| date_envoi | TIMESTAMP | |

### Table `pointages`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| employe_id | TEXT FK | |
| boutique_id | TEXT FK | |
| date | TEXT (AAAA-MM-JJ) | Un pointage par jour et par employé |
| heure_arrivee | TEXT (HH:MM) | |
| heure_depart | TEXT (HH:MM) | Nullable |

### Table `journal_activites`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| boutique_id | TEXT FK | |
| employe_id | TEXT FK | |
| employe_role | TEXT | |
| type | TEXT | vente \| depense \| produit \| retour \| connexion \| compte \| pointage |
| description | TEXT | « Vente de 2x T-Shirt Coton (10 000 FCFA) » |
| date | TIMESTAMP | |

### Table `appareils`
| Champ | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| boutique_id | TEXT FK | |
| employe_id | TEXT FK | Qui utilise cet appareil |
| identifiant_appareil | TEXT | UUID généré et stocké sur le téléphone |
| nom_appareil | TEXT | Modèle (via `device_info_plus`) |
| fcm_token | TEXT | Pour le push |
| actif | INTEGER | 1 = autorisé, 0 = révoqué par le patron |
| derniere_connexion | TIMESTAMP | |

### Table `settings` (locale uniquement)
| Champ | Type | Notes |
|---|---|---|
| key / value | TEXT | boutique_courante, employe_courant, theme, pin_actif… |

---

## 7. DIRECTIVES ÉCRAN PAR ÉCRAN

### Écran 1 — Accueil
- Logo app + titre « Ma Boutique ».
- 2 boutons pleine largeur : « **Créer une boutique** » / « **Se connecter à ma boutique** ».

### Écran 2 — Créer une boutique
- Champs : Nom de la boutique (obligatoire, unicité vérifiée), Style de commerce (facultatif), Monnaie (liste : Franc CFA, Euro, Dollar US…), Email du patron (obligatoire, format validé), Mot de passe (min. 6), Confirmation.
- Bouton « Créer ma boutique » → crée boutique + compte patron (session ouverte).
- Erreurs claires par champ + « nom déjà utilisé » si doublon.

### Écran 3 — Connexion
- Champ : Nom de la boutique.
- Choix du rôle (3 boutons Patron/Manager/Caissière, comme le prototype mais avec champs mot de passe).
- Champ mot de passe → connexion si mot de passe correct et compte actif.
- Message « Compte suspendu. Contactez le patron » si suspendu.

### Écran 4 — Déverrouillage PIN
- Affiché à chaque ouverture si un PIN est activé.
- Pavé 4 chiffres + bouton biométrie (si activée) + « PIN oublié ? » (→ vérification via email patron).

### Écran 5 — Interface principale (commun aux 3 rôles)
- AppBar : nom/logo boutique + cloche notifications (badge si non lues).
- `PageView` 2 pages + `BottomNavigationBar` (Tableau de bord / Actions & Stock).
- Le **solde de la caisse est visible en permanence** (carte sur la page 1).

### Écran 6 — Page 1 : Tableau de bord (varie selon le rôle)
- **Patron** : solde caisse en gros, courbe ventes 7j/30j, courbe bénéfices, marge bénéficiaire, total bénéfices, bouton « Exporter », accès journal d'activité, pointages des employés.
- **Manager** : solde caisse, stats ventes (prix de vente), produits les plus vendus, historique des ventes.
- **Caissière** : solde caisse, historique de ses ventes.

### Écran 7 — Page 2 : Actions & Stock (varie selon le rôle)
- Grille de boutons d'action selon la matrice (section 4.2) : Vente, Dépense, Article vendu, Article défectueux, Retour, Ajouter produit (patron), Justifier sortie de caisse, Exporter (patron/manager), Pointer arrivée/départ (manager/caissière).
- Barre de recherche produit (filtre instantané, tolérance orthographe : `LIKE %nom%` + suggestions).
- Liste des produits : nom, prix de vente, quantité — **« 0 » en rouge** si rupture.
- **Patron** : chaque produit a des actions modifier/supprimer (long-press ou icônes) — visibles de lui seul.

### Écran 8 — Notifications (modal)
- Liste chronologique (icône par type), badge non-lues, « tout marquer comme lu ».

### Écran 9 — Enregistrer une vente
- Recherche/sélection du produit (pré-rempli si vient de la liste) → quantité → prix de vente réel (pré-rempli avec le prix catalogue, modifiable) → bouton « **Signaler Vendu** ».
- Contrôles : quantité > 0, quantité ≤ stock, prix > 0.

### Écran 10 — Article défectueux
- Sélection du produit + champ texte obligatoire « décrire le problème » → enregistre un retour de type `defectueux`, stock -1, notification.

### Écran 11 — Retour produit
- Sélection du produit (éventuellement la vente), choix du motif : **Remboursement** (caisse -prix, stock +1) / **Échange** (stock +1), description, bouton valider.

### Écran 12 — Dépense / Sortie de caisse justifiée
- **Dépense** (patron/manager) : motif + montant → caisse -montant, notification à tous.
- **Justification de sortie** (caissière/manager) : motif obligatoire + montant → caisse -montant, notification patron + manager.

### Écran 13 — Gestion des produits (patron)
- Liste complète (recherche incluse), bouton « + Ajouter », fiche produit : nom, prix achat, prix vente, quantité → modifier / supprimer (confirmation + « la vente reste dans l'historique »).

### Écran 14 — Statistiques & export
- Patron : filtres (jour / semaine / mois), courbes, marge par produit, total bénéfices, génération du rapport → export CSV partagé, archivage hebdomadaire automatique (lundi) consultable.
- Manager : rapport 7 jours → export CSV **sans prix d'achat** (champs interdits au niveau cloud).

### Écran 15 — Journal d'activité (patron)
- Liste chronologique + filtres (type, employé, période).

### Écran 16 — Pointages (patron : consultation ; manager/caissière : pointer)
- Employé : 2 boutons « Arrivée » / « Départ » (l'heure est enregistrée).
- Patron : tableau des pointages par employé/jour.

### Écran 17 — Paramètres (commun : PIN, biométrie, thème, déconnexion)
- Patron en plus : gestion comptes employés, changement mot de passe, appareils connectés.

### Écran 18 — Gestion des employés (patron)
- Liste manager/caissière avec statut (actif/suspendu).
- « + Créer un compte manager / caissière » : nom du compte + mot de passe choisi par le patron.
- Actions par compte : réinitialiser mot de passe, suspendre/activer, supprimer (confirmation).

### Écran 19 — Appareils connectés (patron)
- Liste : rôle, modèle du téléphone, dernière connexion, statut. Bouton « Révoquer » par appareil (→ l'appareil est déconnecté).

### Écran 20 — Réinitialisation PIN / mot de passe oublié
- « PIN oublié » : envoi d'un code de vérification **à l'email du patron uniquement** → l'employé (ou le patron) saisit le code, puis définit un nouveau PIN.
- « Mot de passe patron oublié » : réinitialisation via l'email renseigné à la création.

---

## 8. RÈGLES DE SÉCURITÉ CLOUD

1. **Authentification** : Firebase Auth (email + mot de passe) avec le nom de boutique comme partie de l'identifiant (ex. `boutique.nom`), ou Firestore en mode « boutique → employés » avec hash local vérifié côté serveur via Cloud Functions. **Directive simple** : utiliser Firebase Auth avec un identifiant de forme `{nom_boutique}.{role}@maboutique.app` + mot de passe — simple et gratuit.
2. **Règles Firestore** (obligatoires) :
   - `produits.prix_achat` : lisible uniquement si `request.auth.token.role == 'patron'` de la boutique.
   - Écritures limitées : seuls le patron modifie produits/comptes ; ventes/dépenses/retours autorisés aux rôles habilités.
   - Lecture des `ventes`/`journal` : patron et manager ; caissière : ses ventes + stock + solde.
3. **PIN** : hashé (SHA-256 + sel ou bcrypt) — jamais stocké en clair, jamais envoyé au cloud en clair.
4. **Appareils** : identifiant d'appareil persisté au 1er lancement ; l'employé connecté lie l'appareil à son compte ; le patron révoque via l'écran 19 (statut `actif=0` → l'app force la déconnexion au prochain appel).
5. **Sessions** : token de session persistant (jusqu'à déconnexion) ; vérification du statut du compte à chaque lancement (suspension → déconnexion immédiate).
6. **Hors-ligne** : les écritures sont mises en file (outbox) avec horodatage ; à la reconnexion, `serverTimestamp` détermine la dernière écriture. Les règles de sécurité s'appliquent aussi à la synchro.

---

## 9. PLAN DE RÉALISATION EN 6 PHASES

| Phase | Contenu | Durée | Livrable | Validation client |
|---|---|---|---|---|
| **0. Cadrage** | Maquettes Figma des 20 écrans, validation des textes et du parcours | 1 sem. | Maquettes validées | Le client approuve chaque écran |
| **1. Socle** | Architecture (section 5.2), base sqflite étendue, écrans accueil/création/connexion, comptes locaux avec hash | 2 sem. | App démo : créer une boutique + se connecter en patron/manager/caissière | Test sur 1 téléphone |
| **2. Cœur métier** | Ventes, stock, recherche, défectueux, retours, dépenses, justification caisse, tableau de bord, notifications in-app | 3 sem. | App complète hors-ligne (1 téléphone) | Test complet en boutique |
| **3. Cloud & sync** | Firebase (Auth, Firestore, règles de sécurité), SyncService, multi-appareils, appareils connectés | 3 sem. | 2-3 téléphones synchronisés | **Test réel : le patron ajoute un produit → le manager le voit** |
| **4. Sécurité & confort** | PIN + biométrie, réinitialisation via email patron, thème, comptes employés complets, journal d'activité, pointage | 2 sem. | Toutes les options de paramètres | Tests de tous les scénarios de sécurité |
| **5. Stats & exports** | Courbes (fl_chart), bénéfices/marge, exports CSV, rapport hebdo manager, archivage auto | 1-2 sem. | Rapports partageables | Le patron vérifie l'exactitude des chiffres |
| **6. Qualité & livraison** | Tests (section 10), push FCM, packaging Android APK / Windows / iOS, documentation, formation | 2 sem. | APK + exe + doc + session de formation | Recette finale + installation sur tous les téléphones |

**Durée totale : 12-15 semaines.** Points de contrôle après chaque phase (le client valide avant de continuer).

---

## 10. PLAN DE TESTS

1. **Tests unitaires** (Dart) : calculs caisse (vente/dépense/remboursement), marge/bénéfices, validation quantité/stock, formatage monnaie, règles de rôle.
2. **Tests widget** : chaque écran par rôle (boutons visibles/masqués selon la matrice), zéro rouge, recherche, formulaires.
3. **Tests d'intégration** : synchro hors-ligne → en ligne (ajout produit sur l'appareil A visible sur B), conflit d'écriture, suspension de compte à distance.
4. **Tests de sécurité** : un compte caissière ne peut pas lire `prix_achat` (requête directe au cloud), PIN hashé, compte suspendu bloqué.
5. **Recette client (UAT)** — checklist :
   - [ ] Je crée ma boutique avec mon email et mon mot de passe
   - [ ] J'ajoute un produit (prix d'achat + prix de vente + quantité)
   - [ ] Le manager voit le produit mais pas le prix d'achat
   - [ ] Le manager vend 2 articles → la caisse augmente, je reçois la notification avec son nom
   - [ ] Un produit à 0 s'affiche en rouge
   - [ ] La caissière signale un produit défectueux → le stock baisse
   - [ ] Un retour remboursement diminue la caisse
   - [ ] La caissière justifie une sortie de caisse → je suis prévenu
   - [ ] Je suspends le compte manager → il ne peut plus se connecter
   - [ ] Je vois les appareils connectés et je peux en révoquer un
   - [ ] Le manager exporte le rapport hebdomadaire sans prix d'achat
   - [ ] J'exporte mes statistiques complètes et je peux les partager
   - [ ] Le PIN à 4 chiffres fonctionne + biométrie + récupération via mon email
   - [ ] Les pointages arrivée/départ sont enregistrés
   - [ ] Le thème clair/sombre et la déconnexion fonctionnent
6. **Test multi-appareils** : au moins 3 téléphones Android + 1 émulateur.

---

## 11. RISQUES ET MITIGATIONS

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Connexion instable (zone rurale) | Élevée | Élevé | Offline-first obligatoire dès la phase 2 ; file d'outbox ; messages clairs « hors ligne, données en attente de synchronisation » |
| Prix d'achat visible par erreur aux employés | Moyenne | Très élevé | Règles de sécurité cloud testées (test 4.4), jamais envoyé au client manager/caissière |
| Conflits de synchronisation (2 téléphones vendent en même temps) | Moyenne | Moyen | Last-write-wins + vérification du stock au moment de la synchro ; rejet avec message en cas de stock insuffisant |
| Perte/vol du téléphone du patron | Faible | Élevé | Réinitialisation du mot de passe via email ; révocation d'appareils ; sauvegardes régulières (export) |
| Périmètre flou / demandes en cours de route | Élevée | Moyen | Points de validation après chaque phase ; cahier des charges signé ; liste d'évolutions « v2 » |
| Coût cloud imprévu | Faible | Faible | Plan gratuit Firebase (Firestore 1 Go, Auth 50k MAU) largement suffisant pour 1 boutique |
| L'équipe n'utilise pas l'app | Moyenne | Moyen | Formation + écrans simples ; le pointage et les notifications motivent l'usage |

---

## 12. ESTIMATION RÉVISÉE

**Développement (12-15 semaines) :**
| Rubrique | Fourchette |
|---|---|
| Cadrage + maquettes (phase 0) | 200 - 400 € |
| Développement (phases 1-5) | 2 000 - 3 500 € |
| Tests, packaging, formation (phase 6) | 400 - 700 € |
| **Total** | **2 600 - 4 600 €** |

> Note : le hors-ligne + synchronisation représente ~30 % du coût. Une version « 1 téléphone seulement » (sans cloud) coûterait ~1 200 - 1 800 € mais ne répond pas au besoin central (l'équipe partage les données).

**Coûts récurrents :** Firebase gratuit (0 €) ; Play Store 25 $ une fois ; Apple 99 €/an (si iOS) ; domaine éventuel 10-15 €/an.

---

## 13. CHECKLIST DE LIVRAISON

- [ ] APK Android signé (release) installable sur téléphones Android 6+
- [ ] Installateur Windows (si confirmé)
- [ ] Build iOS (nécessite Mac — à confirmer)
- [ ] Compte Firebase du client configuré (Auth, Firestore, FCM) — **au nom du client**
- [ ] Code source sur Git avec README de déploiement
- [ ] Document utilisateur simple (captures + explications) + vidéo de démo (2-3 min)
- [ ] Session de formation (patron, puis manager, puis caissière)
- [ ] Checklist de recette signée (section 10)
- [ ] Garantie 1 mois de correction de bugs

---

## ANNEXE — VÉRIFICATION DE CONFORMITÉ AVEC LA DISCUSSION

Chaque exigence exprimée dans la discussion (discussion.md) est couverte : création boutique (nom, style, monnaie, email, mot de passe) ✅ / connexion par rôle ✅ / produits ajoutés visibles par l'équipe (sync cloud) ✅ / prix d'achat patron uniquement ✅ / statistiques & marge patron ✅ / export patron + rapport hebdo manager sans prix d'achat ✅ / retours (remboursement/échange) ✅ / dépenses + justification caisse ✅ / PIN 4 chiffres + biométrie + récupération via email patron ✅ / comptes employés gérés par le patron (créer, supprimer, suspendre, réinitialiser) ✅ / appareils connectés ✅ / thème clair/sombre ✅ / déconnexion ✅ / journal d'activité ✅ / pointage ✅ / notifications tous rôles ✅ / 2 pages glissables avec solde caisse permanent ✅ / Android + iOS + Windows ✅ / hors-ligne avec synchro ✅.