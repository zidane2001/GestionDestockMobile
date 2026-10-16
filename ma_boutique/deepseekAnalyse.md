 CAHIER DES CHARGES - APPLICATION "MA BOUTIQUE"
Version : 1.0
Date : Août 2026
Auteur : [Nom du client]
Statut : À valider

1. PRÉSENTATION GÉNÉRALE
1.1 Contexte du Projet
Le client souhaite développer une application mobile de gestion de boutique en ligne. L'objectif est de permettre à une équipe (Patron, Manager, Caissière) de gérer les stocks, les ventes, les dépenses et les statistiques de manière collaborative et en temps réel.

1.2 Objectifs Principaux
Centraliser les données de la boutique dans une base de données cloud.

Permettre une synchronisation en temps réel entre tous les utilisateurs.

Offrir une interface simple et intuitive adaptée à chaque rôle.

Assurer la sécurité des données (authentification, codes PIN).

1.3 Public Cible
Patron : Gestionnaire principal, propriétaire de la boutique.

Manager : Responsable des opérations quotidiennes.

Caissière : Personnel en charge des ventes en caisse.

2. SPÉCIFICATIONS FONCTIONNELLES
2.1 Écran d'Accueil (Connexion/Création)
Objectif : Permettre à l'utilisateur de se connecter ou de créer une nouvelle boutique.

Fonctionnalités :

Élément	Description	Statut
Bouton "Créer une boutique"	Redirige vers un formulaire de création	Obligatoire
Bouton "Se connecter à ma boutique"	Redirige vers la sélection des rôles	Obligatoire
Nom de la boutique	Champ texte pour saisir le nom de la boutique	Obligatoire
Logo de la boutique	Optionnel pour l'instant, à prévoir	Optionnel
Formulaire de création d'une boutique :

Champ	Description	Obligatoire
Nom de la boutique	Identifiant unique pour la boutique	Oui
Style de commerce	Ex: Vêtements, Électronique, Alimentation	Optionnel
Type de monnaie	Franc CFA, Euro, Dollar, etc.	Oui
Adresse email du patron	Pour la récupération de compte	Oui
Mot de passe	Pour le compte patron (minimum 6 caractères)	Oui
Confirmation du mot de passe	Validation du mot de passe	Oui
2.2 Gestion des Comptes et Rôles
2.2.1 Rôles définis :

Rôle	Droits
Patron	Accès complet à toutes les fonctionnalités
Manager	Peut enregistrer des ventes, dépenses, voir le stock, exporter des rapports
Caissière	Peut enregistrer des ventes, signaler les produits défectueux, justifier les diminutions de caisse
2.2.2 Création de comptes employés (Patron uniquement) :

Élément	Description
Option "Ajouter un manager"	Formulaire avec : nom, rôle, mot de passe
Option "Ajouter une caissière"	Formulaire avec : nom, rôle, mot de passe
Génération automatique	Le nom de la boutique devient l'identifiant de connexion
Réinitialisation	Possibilité de réinitialiser le mot de passe d'un employé
Suppression/Suspension	Possibilité de suspendre un compte employé
2.2.3 Appareils connectés :

Le patron peut voir la liste des appareils connectés à la boutique.

Alerte si un appareil non autorisé tente de se connecter.

2.3 Compte Patron (Fonctionnalités Complètes)
2.3.1 Tableau de Bord (Page 1 - Swipe à droite) :

Élément	Description
Solde de la caisse	Affiché en gros, mis à jour en temps réel
Graphique des ventes	Évolution des ventes sur 7 jours (ou 30 jours)
Graphique des bénéfices	Basé sur prix d'achat vs prix de vente
Marge bénéficiaire	Calculée automatiquement par produit
Notifications	Alertes en temps réel sur les ventes, dépenses, stocks
Export des données	Bouton pour exporter un rapport (PDF ou Excel)
2.3.2 Gestion des Produits (Page 2 - Swipe à gauche) :

Action	Description	Exclusif Patron
Ajouter un produit	Nom, prix d'achat, prix de vente, quantité	Oui
Modifier un produit	Modifier les informations d'un produit existant	Oui
Supprimer un produit	Retirer un produit du catalogue	Oui
Rechercher un produit	Barre de recherche pour trouver rapidement un produit	Non
Voir le stock	Liste complète avec quantités et alertes (rouge si stock = 0)	Non
Vendre un produit	Recherche, sélection, quantité, prix de vente	Non (disponible pour tous)
Historique des ventes	Liste des ventes avec détails (produit, quantité, prix, vendeur)	Non
2.3.3 Gestion des Employés :

Action	Description
Créer un manager	Formulaire de création
Créer une caissière	Formulaire de création
Suspendre un compte	Désactiver temporairement un compte
Réinitialiser le mot de passe	Générer un nouveau mot de passe pour un employé
Supprimer un compte	Supprimer définitivement un compte
Voir les appareils connectés	Liste des appareils actifs
2.3.4 Gestion des Dépenses et Retours :

Action	Description	Effectué par
Enregistrer une dépense	Motif, montant, date	Patron et Manager
Signaler un produit défectueux	Produit, description du problème	Manager et Caissière
Signaler un retour produit	Produit, motif (remboursement/échange)	Manager et Caissière
Justifier une diminution de caisse	Explication de la sortie d'argent	Caissière (et Manager)
2.3.5 Paramètres (Compte Patron) :

Option	Description
Modifier le mot de passe	Changement avec ancien mot de passe ou via email
Code PIN à 4 chiffres	Sécurisation de l'accès à l'application
Reconnaissance biométrique	Activation de l'empreinte digitale ou reconnaissance faciale
Changer le thème	Mode clair / Mode sombre
Appareils connectés	Voir et gérer les appareils connectés
Déconnexion	Revenir à l'écran d'accueil
2.4 Compte Manager (Fonctionnalités)
2.4.1 Tableau de Bord :

Élément	Description
Solde de la caisse	Affiché en temps réel
Statistiques des ventes	Basées sur les prix de vente (sans prix d'achat)
Produits les plus vendus	Classement des produits par popularité
Historique des ventes	Liste des ventes avec détails
2.4.2 Gestion des Ventes et Actions :

Action	Description
Enregistrer une vente	Recherche du produit, quantité, prix de vente
Signaler un produit vendu	Marquer un produit comme vendu
Signaler un produit défectueux	Produit, description du problème
Enregistrer une dépense	Motif, montant (ex: loyer, électricité)
Exporter un rapport	Rapport hebdomadaire (7 jours) avec statistiques de vente
2.4.3 Paramètres (Manager) :

Option	Description
Modifier le code PIN	Changer le code à 4 chiffres
Reconnaissance biométrique	Activation de l'empreinte digitale
Changer le thème	Mode clair / Mode sombre
Déconnexion	Revenir à l'écran d'accueil
2.5 Compte Caissière (Fonctionnalités)
2.5.1 Tableau de Bord :

Élément	Description
Solde de la caisse	Affiché en temps réel
Historique des ventes (simplifié)	Liste des dernières ventes effectuées
2.5.2 Gestion des Ventes :

Action	Description
Enregistrer une vente	Recherche du produit, quantité, prix de vente
Signaler un produit vendu	Marquer un produit comme vendu
Signaler un produit défectueux	Produit, description du problème
Justifier une diminution de caisse	Explication de la sortie d'argent
2.5.3 Paramètres (Caissière) :

Option	Description
Modifier le code PIN	Changer le code à 4 chiffres
Reconnaissance biométrique	Activation de l'empreinte digitale
Changer le thème	Mode clair / Mode sombre
Déconnexion	Revenir à l'écran d'accueil
2.6 Gestion des Notifications
Notifications en temps réel pour :

Événement	Patron	Manager	Caissière
Nouvelle vente enregistrée	✅	✅	✅
Produit en rupture de stock	✅	✅	❌
Nouveau produit ajouté	✅	✅	✅
Dépense enregistrée	✅	✅	❌
Produit défectueux signalé	✅	✅	❌
Diminution de caisse justifiée	✅	✅	❌
Retour produit signalé	✅	✅	❌
Compte créé/suspendu	✅	❌	❌
Types de notifications :

Push notifications (alertes sur l'écran du téléphone, même lorsque l'app est fermée).

In-app notifications (alertes visibles uniquement dans l'application).

3. SPÉCIFICATIONS TECHNIQUES
3.1 Technologies Recommandées
Catégorie	Technologie	Justification
Framework mobile	Flutter	Compatible Android, iOS, Windows
Gestion d'état	Provider ou Riverpod	Léger, efficace pour cette application
Base de données	Firebase Firestore ou Supabase	Synchronisation en temps réel, authentification intégrée, facile à configurer
Authentification	Firebase Auth ou Supabase Auth	Gestion des comptes, récupération de mot de passe
Notifications push	Firebase Cloud Messaging	Notifications en temps réel
Stockage de fichiers	Firebase Storage ou Supabase Storage	Pour les exports de données (PDF, Excel)
Hébergement	Firebase Hosting ou Vercel	Pour la documentation ou une version web (optionnel)
3.2 Architecture de la Base de Données
Collections / Tables (Firestore / PostgreSQL) :

text
boutiques/
  └── {boutiqueId}/
      ├── nom: string
      ├── style: string
      ├── monnaie: string
      ├── email_patron: string
      ├── caisse_solde: number
      ├── date_creation: timestamp
      ├── date_modification: timestamp
      ├── employes/
      │   └── {employeId}/
      │       ├── nom: string
      │       ├── role: string (patron|manager|caissiere)
      │       ├── email: string
      │       ├── mot_de_passe_hash: string
      │       ├── pin_code: string (optionnel)
      │       ├── biometrie_actif: boolean
      │       ├── status: string (actif|suspendu)
      │       ├── date_creation: timestamp
      │       └── appareils/
      │           └── {appareilId}/
      │               ├── nom_appareil: string
      │               ├── date_connexion: timestamp
      │               └── actif: boolean
      ├── produits/
      │   └── {produitId}/
      │       ├── nom: string
      │       ├── prix_achat: number (visible uniquement patron)
      │       ├── prix_vente: number
      │       ├── quantite: number
      │       ├── quantite_critique: number (seuil d'alerte)
      │       ├── date_ajout: timestamp
      │       ├── date_modification: timestamp
      │       └── est_defectueux: boolean
      ├── ventes/
      │   └── {venteId}/
      │       ├── produit_id: string (référence)
      │       ├── produit_nom: string
      │       ├── quantite: number
      │       ├── prix_unitaire: number
      │       ├── total_vente: number
      │       ├── vendeur_id: string (référence employé)
      │       ├── vendeur_nom: string
      │       ├── date_vente: timestamp
      │       └── est_retourne: boolean
      ├── depenses/
      │   └── {depenseId}/
      │       ├── description: string
      │       ├── montant: number
      │       ├── auteur_id: string (référence employé)
      │       ├── auteur_role: string
      │       ├── date_depense: timestamp
      │       └── justificatif: string (optionnel)
      ├── retours/
      │   └── {retourId}/
      │       ├── vente_id: string (référence)
      │       ├── produit_id: string (référence)
      │       ├── motif: string (remboursement|echange|defectueux)
      │       ├── description: string
      │       ├── auteur_id: string (référence employé)
      │       ├── date_retour: timestamp
      │       └── statut: string (en_attente|traite|refuse)
      ├── notifications/
      │   └── {notificationId}/
      │       ├── titre: string
      │       ├── message: string
      │       ├── type: string (vente|depense|stock|produit|retour)
      │       ├── destinataire_role: string (patron|manager|caissiere)
      │       ├── date_envoi: timestamp
      │       └── est_lu: boolean
      └── statistiques/
          └── {statistiqueId}/
              ├── semaine: number
              ├── annee: number
              ├── total_ventes: number
              ├── total_depenses: number
              ├── benefice_brut: number
              └── benefice_net: number
3.3 Règles de Sécurité
Authentification :

Connexion avec nom de boutique + mot de passe (ou email + mot de passe).

Session persistante (reste connecté jusqu'à déconnexion manuelle).

2FA (facultatif) : Code PIN à 4 chiffres ou biométrie.

Autorisations :

Action	Patron	Manager	Caissière
Ajouter/Modifier/Supprimer un produit	✅	❌	❌
Voir le prix d'achat d'un produit	✅	❌	❌
Voir le prix de vente d'un produit	✅	✅	✅
Créer un compte employé	✅	❌	❌
Suspendre un compte employé	✅	❌	❌
Enregistrer une vente	✅	✅	✅
Enregistrer une dépense	✅	✅	❌
Signaler un produit défectueux	✅	✅	✅
Exporter les statistiques	✅	✅	❌
Voir les bénéfices	✅	❌	❌
Modifier son code PIN	✅	✅	✅
3.4 Performances Attendues
Critère	Objectif
Temps de synchronisation	< 2 secondes
Temps de chargement de l'app	< 3 secondes
Temps d'affichage du stock	< 1 seconde
Temps d'enregistrement d'une vente	< 1 seconde
Notifications push	< 5 secondes après action
3.5 Compatibilité
Plateforme	Version minimale
Android	Android 6.0 (API 23)
iOS	iOS 13.0
Windows	Windows 10 (via Flutter Desktop)
Taille de l'application	< 50 MB (Android) / < 100 MB (iOS)
4. CONTRAINTES ET EXIGENCES NON FONCTIONNELLES
4.1 Sécurité
Les mots de passe doivent être hashés.

Les données sensibles (prix d'achat) doivent être protégées.

Les sessions doivent expirer après une période d'inactivité (30 min).

Les appareils non autorisés doivent être bloqués.

4.2 Ergonomie
Interface simple et intuitive.

Navigation par glissement (swipe) entre les pages.

Design responsive adapté aux mobiles.

Mode clair et mode sombre disponibles.

4.3 Fiabilité
L'application doit fonctionner hors ligne (mode dégradé) avec synchronisation automatique dès que la connexion est rétablie.

Les données doivent être sauvegardées régulièrement (backup automatique).

4.4 Maintenabilité
Code bien documenté.

Utilisation de clean architecture (faciliter les mises à jour).

Tests unitaires pour les fonctions critiques.

5. PLAN DE DÉVELOPPEMENT
Phase 1 : Conception et Design (1-2 semaines)
Définition : Valider le cahier des charges avec le client.

Design : Créer des maquettes (Figma) pour chaque écran.

Validation : Faire valider les maquettes par le client.

Phase 2 : Développement Backend (2-3 semaines)
Base de données : Configuration de Firebase Firestore (ou Supabase).

Authentification : Mise en place de Firebase Auth (ou Supabase Auth).

API : Développement des endpoints pour les requêtes principales.

Phase 3 : Développement Frontend (3-4 semaines)
Structure : Mise en place du projet Flutter avec Provider/Riverpod.

Écrans : Développement de tous les écrans et composants UI.

Logique métier : Implémentation des fonctionnalités (ventes, stocks, etc.).

Phase 4 : Synchronisation et Notifications (1-2 semaines)
Synchronisation : Mise en place de la synchronisation en temps réel.

Notifications : Configuration des notifications push (Firebase Cloud Messaging).

Phase 5 : Tests et Déploiement (2 semaines)
Tests : Tests fonctionnels, tests de sécurité, tests de performance.

Déploiement : Génération des fichiers APK (Android), IPA (iOS) et installer Windows.

Documentation : Guide d'utilisation pour le client.

Phase 6 : Formation et Livraison (1 semaine)
Formation : Former le client et son équipe à l'utilisation de l'application.

Livraison : Remettre les fichiers d'installation et la documentation.

Durée totale estimée : 10-14 semaines

6. ESTIMATION DES COÛTS (Indicatif)
6.1 Développement (Forfait)
Rubrique	Coût estimé (€)
Conception UI/UX	300 - 500 €
Développement Backend	500 - 1 000 €
Développement Frontend	1 000 - 2 000 €
Tests et Déploiement	300 - 500 €
Formation et Documentation	200 - 300 €
Total	2 300 - 4 300 €
Ces coûts sont indicatifs et dépendent du développeur/freelance choisi. Pour une version plus simple, le coût peut être réduit à environ 1 500 - 2 000 €.

6.2 Frais Récurrents (Mensuels/Annules)
Rubrique	Coût (€)
Hébergement Firebase/Supabase (Plan gratuit ou payant)	0 - 25 €/mois
Compte Google Play Store (licence unique)	25 € (une seule fois)
Compte Apple App Store (licence annuelle)	99 €/an
Noms de domaine (optionnel)	10 - 15 €/an
Total	25 - 140 €/mois (selon le trafic)
7. GESTION DES RISQUES
Risque	Probabilité	Impact	Solution
Base de données trop lente	Moyenne	Élevé	Optimiser les requêtes, utiliser des index
Sécurité des données	Faible	Élevé	Hash des mots de passe, chiffrement des données sensibles
Utilisateur perd le code PIN	Moyenne	Moyen	Procédure de récupération via email
Problème de synchronisation	Faible	Élevé	Mise en place d'un système de reprise sur échec
Dépassement de budget	Moyenne	Élevé	Découpage en phases avec validation client à chaque étape
Abandon du projet par le client	Faible	Élevé	Périmètre et planning clairs dès le début
8. GLOSSAIRE
Terme	Définition
Backend	Partie de l'application qui gère les données, les serveurs et la logique métier.
Base de données cloud	Base de données hébergée sur Internet (ex: Firebase).
Flutter	Framework open-source de Google pour créer des applications mobiles et web.
Provider	Librairie de gestion d'état pour Flutter.
Firebase	Plateforme de développement d'applications mobiles de Google.
Supabase	Alternative open-source à Firebase avec PostgreSQL.
APK	Fichier d'installation pour Android.
IPA	Fichier d'installation pour iOS.
Push notification	Notification envoyée à l'utilisateur même si l'application est fermée.
Synchronisation	Processus qui assure que les données sont identiques sur tous les appareils.
9. ANNEXES
Annexe A : Maquettes (Textuelles)
Les maquettes ont déjà été fournies par Gemini dans l'historique. Elles seront converties en maquettes visuelles (Figma) lors de la phase de conception.

Annexe B : Code Source (Déjà Généré)
Le code Flutter partiel généré par Gemini est disponible et servira de base de départ (à adapter avec la base de données cloud et la synchronisation).

✅ VALIDATION DU CAHIER DES CHARGES
Client : [Nom du client]
Date : [Date de validation]

Signature du client : ________________________

Observations ou modifications souhaitées :

Ce cahier des charges est maintenant complet, détaillé et prêt à être envoyé à un développeur. Ton ami peut l'utiliser pour :