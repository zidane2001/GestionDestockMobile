# Site Ma Boutique

Site public de l'application **Ma Boutique** : vitrine, journal des versions,
page d'installation et **souscription en ligne**. Il embarque un **back-office
protégé** pour publier les mises à jour et suivre les demandes.

## Contenu

| Page | Rôle |
|---|---|
| `/` | Vitrine : promesse, fonctionnalités, captures, formules, formulaire de souscription, FAQ |
| `/fonctionnalites` | Détail fonctionnel de l'application |
| `/mises-a-jour` | Journal des versions publiées depuis le back-office |
| `/installer` | Procédure d'installation de l'APK sur Android |
| `/admin` | Connexion administrateur (mot de passe unique) |
| `/admin/tableau-de-bord` | Publier/supprimer une version, suivre les abonnements |
| `/admin/abonnes.csv` | Export CSV des demandes (protégé) |
| `/telechargement/ma-boutique.apk` | Téléchargement **direct** de l'APK (aucune redirection) |
| `/telechargement/ma-boutique-<version>.apk` | Téléchargement d'une version précise |
| `/health` | Sonde de disponibilité pour Render |

## Démarrage local

```bash
cd site
npm install
cp .env.example .env          # puis renseigner les valeurs
ADMIN_PASSWORD="motdepasse-local" SESSION_SECRET="secret-de-dev-16-caracteres" npm start
```

Sans `DATABASE_URL`, le site démarre sur **PGlite** (Postgres en WebAssembly,
données dans `site/.pglite/`) : tout est testable sans installer de serveur.
En production, `DATABASE_URL` est **obligatoire** (le démarrage échoue sinon,
pour ne jamais perdre les abonnements au redéploiement).

## Tests

```bash
npm test        # 14 tests de bout en bout : pages, souscription, auth, CSV
npm run captures # recopie les captures de l'app dans public/assets
```

Les tests démarrent le vrai serveur Express sur un port libre, avec une base
PGlite temporaire, et exercent les parcours réels (formulaire, doublon d'email,
mot de passe erroné, session falsifiée, publication, export CSV).

## Variables d'environnement

| Variable | Obligatoire | Rôle |
|---|---|---|
| `DATABASE_URL` | en production | Postgres (Neon, Render…). `sslmode=require` recommandé |
| `ADMIN_PASSWORD` | oui | Mot de passe du back-office (8 caractères minimum) |
| `SESSION_SECRET` | oui | Signature des cookies de session (16 caractères minimum) |
| `LIEN_APK` | non | URL **source** de l'APK : le site la récupère une fois puis sert le fichier lui-même |
| `APK_PATH` | non | Fichier APK déjà présent sur le disque, servi tel quel |
| `APK_CACHE_DIR` | non | Dossier de cache de l'APK (défaut `site/.apk`, ignoré par Git) |
| `PORT` | non | Fourni par Render |

Générer un secret : `node -e "console.log(require('crypto').randomBytes(32).toString('base64url'))"`.

## Sécurité

- Mot de passe comparé à temps constant, 6 tentatives par quart d'heure et par IP.
- Cookie de session `HttpOnly`, `SameSite=Strict`, `Secure` en production, signé HMAC.
- En-têtes `CSP`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`.
- Champs piège anti-robots et limite de 8 souscriptions par heure et par IP.
- Aucune donnée sensible dans les pages ; seul l'email saisi est conservé.

## Déploiement Render

1. Créer la base Postgres chez Neon et récupérer la chaîne de connexion.
2. `render.yaml` décrit le service web (`rootDir: site`, `npm ci --omit=dev`, `npm start`).
3. Renseigner dans Render : `DATABASE_URL`, `ADMIN_PASSWORD` ; `SESSION_SECRET` est généré.
4. Après déploiement, vérifier `/health`, puis `/admin` et une publication de test.

## Téléchargement : aucun détour par un hébergeur

Les boutons pointent vers `/telechargement/ma-boutique.apk`, servi par le site
avec `Content-Disposition: attachment` : le navigateur enregistre le fichier
sans changer de page ni afficher d'adresse externe.

Ordre de résolution du fichier :

1. `APK_PATH` (fichier déjà sur le disque) ;
2. cache local `APK_CACHE_DIR` — alimenté au build par `npm run prepare-apk`
   ou à la première demande ;
3. URL source de la version (ou `LIEN_APK`) : le serveur la récupère, la met en
   cache et l'envoie en flux au visiteur (un seul passage réseau, pas de
   200 Mo en mémoire).

## Publier une mise à jour de l'application

1. Construire l'APK et le déposer où il est accessible par URL (Release GitHub,
   stockage objet…), puis mettre à jour `LIEN_APK` sur Render.
2. Se connecter à `/admin`.
3. Renseigner : numéro de version, titre, date, URL **source** de l'APK, notes
   (une ligne par point).
4. Publier : la page `/mises-a-jour` et le bouton de téléchargement de l'accueil
   servent immédiatement cette version, toujours depuis le domaine du site.
