# Rapport QA — Smart Stock (`ma_boutique`)

**Date** : 15 octobre 2026
**Cible** : émulateur Pixel 36 (Android 16), build debug `com.example.ma_boutique`
**Comptes créés pour la campagne** :

| Boutique | id | Monnaie | Patron | Mot de passe |
|---|---|---|---|---|
| Boutique QA 15oct | `8b4xylob` | EUR | qa.15oct@example.com | `QaTest2026` |
| Boutique QA 2 | `c8joq5hi` | FCFA | qa2.15oct@example.com | `Qa2Test2026` |

Méthode : exécution des parcours réels dans l'app (taps/typage via `adb`), puis contrôle
systématique de l'état persisté dans SQLite (`run-as com.example.ma_boutique sqlite3
databases/ma_boutique.db`) et dans l'arbre d'accessibilité.

**Passe de correction (même jour, après la campagne)** : F3, F4 et l'aperçu QR de la fiche
édition ont été corrigés dans le code, recompilés (`flutter build apk --debug`) et revalidés
en E2E sur ce même compte — voir « Retest des corrections » en §3. `flutter test` passe :
**318 tests** (dont 5 nouveaux dédiés au QR).

---

## 1. Blocage majeur à connaître

### F1 — Le backend Supabase n'existe plus (BLOQUANT pour tout le volet serveur)

```
nslookup kxgluwdhlgzmgdcszeln.supabase.co
*** DESKTOP-9MACGNN ne parvient pas à trouver kxgluwdhlgzmgdcszeln.supabase.co : Non-existent domain
curl https://kxgluwdhlgzmgdcszeln.supabase.co/rest/v1/  →  HTTP 000 (0,16 s)
```

Conséquences et vérifications :

- Tout le volet réseau est **intestable** : synchronisation multi-appareils, import d'une
  boutique depuis le serveur (`_importerDepuisSupabase`), récupération de compte par email,
  console superadmin.
- Comportement hors ligne **conforme** : les opérations restent en file, la caisse/les ventes
  continuent de fonctionner, aucun crash. État vérifié en fin de campagne : **36 opérations
  en attente**, correctement réparties par boutique (`boutique_id`) — 25 pour `8b4xylob`
  (`activites 6 · appareils 1 · boutiques 5 · depenses 2 · employes 1 · notifications 5 ·
  produits 3 · ventes 2`) et 11 pour `c8joq5hi` (`activites 2 · appareils 1 · boutiques 2 ·
  employes 1 · notifications 2 · produits 2 · ventes 1`) — et une seule clé `serveur_mdp`
  provisionnée.
- État revérifié **après la passe de correction** : **48 opérations en attente**, soit 37 pour
  `8b4xylob` et 11 pour `c8joq5hi` — la file de la boutique 2 n'a pas bougé d'un seul cran
  pendant toute la passe de correction, preuve supplémentaire d'isolation. La file n'a fait
  que croître à chaque action, toujours sans le moindre signal visible.
- L'app **ne signale pas** cet échec : la synchro échoue en silence (`catch (_)`), l'en-tête
  n'affiche rien tant que `enLigne` reste vrai. Un utilisateur ne peut pas savoir que ses
  données ne sont pas sauvegardées (36 opérations en fin de campagne, 48 ensuite, sans aucun
  signal visible).

---

## 2. Défauts trouvés

### F2 — Sécurité : secrets et mots de passe en clair (ÉLEVÉ)

- `lib/core/supabase_config.dart` contient en dur la clé **`service_role`** (contourne la RLS)
  et le mot de passe superadmin `NashShop@1234`. Un APK décompilé donne un accès total à la
  base.
- Les mots de passe employés sont stockés en clair dans SQLite :

```
select nom,boutique_id,motDePasse from employes;
Patron|8b4xylob|QaTest2026
Patron|c8joq5hi|Qa2Test2026
```

### F3 — Le QR code produit contient un mauvais identifiant (ÉLEVÉ)

`ajouterProduit()` appelle `_uid()` deux fois : une fois pour `Produit.id`, une fois pour le
payload du QR. Les deux ids divergent donc **systématiquement**.

```
select id, qrCodeData from produits;
4ghagfs7 | {type: produit, id: fpa0klgo, nom: T-shirt QA, prix: 1200.0, cat: autre, v: 1}
lbvz5hya | {type: produit, id: 5d37ghcf, nom: Produit B2, prix: 500.0, cat: autre, v: 1}
```

Impact : l'écran produit annonce « Scannez pour identifier le produit (ID: …) » ; le scan
(paquet `mobile_scanner`) ne pourra pas retrouver le produit. À noter aussi :
`data.toString()` produit une carte Dart (`{type: produit, …}`), **pas du JSON** malgré le
commentaire du code.

**CORRIGÉ** — trois points, tous revérifiés en E2E sur ce compte :

- `ajouterProduit()` génère **un seul** `_uid()`, réutilisé pour l'id du produit et pour le
  payload du QR (les deux appels distincts n'existent plus) ;
- `modifierProduit()` **régénère** le QR à chaque modification, ce qui répare aussi les
  produits créés avant correction ;
- `genererDataProduit()` émet du vrai `jsonEncode`, et `parserQrProduit()` lit désormais le
  JSON **et** l'ancien format `toString()` réellement stocké (le repli précédent attendait
  des guillemets que les données réelles n'ont jamais eus).

```
-- produit créé après correction --------------------------------------------
id=t9kntsf5  qr={"type":"produit","id":"t9kntsf5","nom":"QA F3 test","prix":950.0,"cat":"autre","v":1}

-- produit créé AVANT correction, réparé par une simple modification ---------
4ghagfs7     qr={"type":"produit","id":"4ghagfs7","nom":"T-shirt QA","prix":1200.0,"cat":"autre","v":1}

-- contrôle SQL --------------------------------------------------------------
select case when id=json_extract(qrCodeData,'$.id') and prixVente=json_extract(qrCodeData,'$.prix')
            then 'QR_COHERENT_ID_ET_PRIX' ...  →  QR_COHERENT_ID_ET_PRIX
```

### F4 — Vendre 0 pièce enregistre 1 vente (MOYEN)

Dans la feuille de vente :

```dart
onChanged: (v) {
  final n = int.tryParse(v.replaceAll(RegExp(r'\D'), '')) ?? 1;
  setState(() => _quantite = n < 1 ? 1 : n);
},
```

Reproduit : champ « Quantité » = `0`, total affiché « €0.00 », puis « Signaler vendu » →
la vente enregistrée est **1 × 1 200 €** (stock 9, caisse 1 200 €). Le clamp est silencieux :
aucun message, et le champ continue d'afficher `0` alors que l'état interne vaut `1`
(contrôleur non resynchronisé). Le garde-fou `quantite <= 0` du provider est donc
inatteignable depuis l'UI.

**CORRIGÉ** — le champ et l'état sont maintenant strictement synchronisés (`_quantite` suit la
saisie, zéro compris, sans clamp silencieux) et le message du provider s'affiche enfin dans la
feuille. Rejoué sur le build corrigé : champ `0`, total `€0.00`, message « La quantité doit
être supérieure à 0. », feuille laissée ouverte, et en base `ventes=3` **inchangé** avec le
stock toujours à 6.

### F5 — Nom de boutique dupliqué non bloqué (MOYEN, risque multi-tenant)

`creer_boutique_screen.dart` contrôle l'unicité avec
`provider.boutique != null && provider.boutique!.nom == nom`. Depuis l'écran d'inscription,
`provider.boutique` est **toujours nul** (l'utilisateur est déconnecté) : le contrôle
`« Ce nom de boutique existe déjà. »` ne peut jamais se déclencher, alors que l'aide affichée
promet un nom « unique ».

Or `connexion()` résout la boutique **par son nom** et prend la première correspondance
(`toutes('boutiques')` puis premier match, insensible à la casse). Deux boutiques homonymes
rendent donc la connexion ambiguë (risque d'ouvrir la mauvaise boutique).
*Non reproduit en E2E (cela aurait créé une 3ᵉ boutique) : constat d'analyse de code.*

### F6 — Le mot de passe de synchronisation est global, pas par boutique (MOYEN)

`SyncService._client()` lit `getSetting('serveur_mdp')` sans distinction de boutique. Après
déconnexion, la valeur reste :

```
select key,value from settings;
session_id|            (vidé par la déconnexion — correct)
serveur_mdp|mb-8b4xylob   (reste celui de la boutique 1)
```

Avec deux boutiques, la synchro de la boutique 2 tente donc d'abord le mot de passe de la
boutique 1 (`essaie(mdp)`), puis se corrige sur `mdpDerive`. Risque : échecs de synchro
inutiles, voire écriture dans la mauvaise session si les identifiants coïncident.

### F7 — Identifiants courts, non cryptographiques, sans portée tenant (FAIBLE)

`_uid()` = 8 caractères base36 tirés de `Random()` (non cryptographique) et utilisés comme clé
de conflit d'upsert Supabase (`onConflict: 'id'`). Les ids ne sont pas préfixés par boutique :
une collision écraserait la ligne d'un autre tenant. Le mot de passe serveur est
`mb-<id>` — dérivable si l'id est connu.

### F8 — Avertissement d'analyse du code (FAIBLE)

`flutter analyze` signale `use_build_context_synchronously` dans `connexion_screen.dart` : le
`context` est utilisé après un `await`. Sur cet écran, une navigation pendant la requête peut
provoquer une erreur.

### F9 — Message d'erreur hors ligne jamais affiché (FAIBLE)

La synchro échoue en silence (voir F1). L'en-tête n'affiche « N en attente de synchro » que
lorsque l'app est passée manuellement hors ligne (`basculerReseau`), pas en cas d'échec réel.

### F10 — « Scannez pour identifier le produit » : aucun scan n'existe dans l'app (MOYEN)

L'écran détail et la fiche édition affichent « Scannez pour identifier le produit (ID: …) »,
mais rien n'est en mesure de lire ce QR :

- `mobile_scanner: ^5.1.1` est déclaré dans `pubspec.yaml` et **jamais importé** dans `lib/`
  (0 occurrence hors pubspec/lock) ;
- `QrCodeService.parserQrProduit()`, seul code capable de décoder un QR produit, **n'est
  appelé nulle part** dans l'application.

Le QR est donc purement décoratif : il s'affiche, personne ne le lit. Constat de code — il n'y
a pas de scénario utilisateur à exécuter puisque la fonction n'existe pas. À corriger en
priorité après F3/F4 : soit câbler le scan, soit retirer l'invitation à scanner.

---

## 3. Résultats des tests exécutés

| # | Test | Attendu | Résultat |
|---|---|---|---|
| 1 | Inscription : formulaire vide | 3 erreurs, aucune boutique créée | **PASS** (0 boutique en base) |
| 2 | Inscription : email `vous@exemple` (sans TLD) | « Adresse email invalide. » | **PASS** |
| 3 | Inscription : mot de passe 3 caractères | « Minimum 6 caractères. » | **PASS** |
| 4 | Inscription : mot de passe court sans TLD, nom vide | aucun enregistrement | **PASS** |
| 5 | Inscription valide | boutique + patron + appareil + 3 opérations en file | **PASS** |
| 6 | Monnaie choisie (EUR) | respectée à l'affichage et en base | **PASS** |
| 7 | Ajout produit (500 / 1200 / 10) | enregistré, marge €700 calculée en direct | **PASS** |
| 8 | Produit rattaché à sa boutique | `boutique_id` = id de la boutique | **PASS** |
| 9 | Vente 3 × 1200 | stock 10→6, caisse +3 600, notification + journal | **PASS** |
| 10 | Vente 15 unités (stock 10) | « Stock insuffisant : 10 en stock. », aucune vente | **PASS** |
| 11 | Vente quantité 0 | refus | **FAIL** → F4 (1 vente enregistrée) — *corrigé, voir R4* |
| 12 | Dépense 99 999 > caisse 4 800 | refus, caisse intacte | **PASS** |
| 13 | Dépense 800 | caisse 4 800→4 000, type `depense` | **PASS** |
| 14 | Sortie de caisse 500 | caisse 4 000→3 500, type `sortieJustifiee` | **PASS** |
| 15 | Tableau de bord | caisse, ventes du jour, pièces vendues, marge 58 % | **PASS** |
| 16 | Notifications | 5 entrées, bonnes catégories, badge d'en-tête | **PASS** |
| 17 | Journal d'activité | 5 entrées correspondant aux actions | **PASS** |
| 18 | Déconnexion | `session_id` vidée, retour à l'accueil | **PASS** |
| 19 | Connexion : boutique inconnue | « Nom de boutique inconnu. » | **PASS** |
| 20 | Connexion : mauvais mot de passe | « Mot de passe incorrect. » | **PASS** |
| 21 | Connexion : identifiants valides | tableau de bord de la bonne boutique | **PASS** |
| 22 | Persistance : relance de l'app | session restaurée, caisse €4 800, 4 pièces | **PASS** |
| 23 | Persistance : reboot complet de l'Android | base intacte (`integrity_check = ok`, schema v9) | **PASS** |
| 24 | Isolation : 2ᵉ boutique vierge | 0 €, 0 vente, aucun produit de la 1ʳᵉ | **PASS** |
| 25 | Isolation : vente dans la 2ᵉ boutique | stock/caisse/monnaie propres (1 000 FCFA) | **PASS** |
| 26 | Isolation : retour sur la 1ʳᵉ boutique | caisse €3 500, seul « T-shirt QA » listé | **PASS** |

### Retest des corrections (même compte, build corrigé)

| # | Test | Attendu | Résultat |
|---|---|---|---|
| R1 | QR d'un produit créé après correction | JSON valide et `id` = `produits.id` | **PASS** (`t9kntsf5` → `QR_ID_CONCORDANT`) |
| R2 | QR d'un produit créé *avant* correction | régénéré par simple modification | **PASS** (`4ghagfs7` concordant) |
| R3 | Modification du prix 900 → 950 | QR et prix produits alignés | **PASS** (`QR_COHERENT_ID_ET_PRIX`) |
| R4 | Vente de 0 pièce (build corrigé) | refus visible, aucune vente | **PASS** (`ventes=3` inchangé, stock 6) |
| R5 | Réinstallations successives de l'apk (3×) | aucune perte de données | **PASS** (session, caisse €3 500, 4 pièces) |
| R6 | `flutter test` (+5 tests QR) | tous verts | **PASS** (318/318, exit 0) |
| R7 | `flutter analyze` après corrections | aucune nouvelle anomalie | **PASS** (26 issues = baseline inchangée) |

**Aucun crash, aucune exception Flutter, aucun ANR** pendant toute la campagne (logcat filtré).

---

## 4. Non couvert (et pourquoi)

- **Défectueux / Retour produit** : les feuilles contenant le sélecteur de produit
  (`ProduitPicker`) n'exposent pas leur arbre d'accessibilité sur cet émulateur — la feuille
  s'ouvre mais reste illisible pour l'automatisation. Aucune autre entrée ne permet de
  pré-sélectionner un produit (la fiche produit n'expose que « Vendre »). Ces deux flux
  restent **non vérifiés**.
- **Équipe** (création d'employé, permissions, suspension, pointage) et **sécurité** (code PIN,
  biométrie, changement de mot de passe, thème sombre) : scrutation de l'interface confirmée
  (l'écran Paramètres expose bien ces entrées), parcours non exécutés faute de temps.
- **Tout ce qui dépend du serveur** : voir F1.
- **Limites de validation du formulaire d'inscription** : la règle « nom entre 3 et 40
  caractères » n'a été exercée qu'avec un champ vide (qui déclenche le même message) ; les
  bornes 2 et 41 caractères, ainsi que « les mots de passe ne correspondent pas », n'ont pas
  été isolées.

## 5. Note d'outillage (utile pour automatiser la suite)

- L'injection de texte `adb shell input text` **ne fonctionne que si le clavier virtuel est
  désactivé** (`adb shell ime disable com.google.android.inputmethod.latin/…`) : avec Gboard
  actif, les événements sont avalés (champ focalisé, curseur visible, aucun caractère inséré).
- Même clavier désactivé, la saisie reste *lossy* si on injecte d'un coup : injecter par blocs
  de 3 caractères avec ~1,5 s de pause donne 100 % de fidélité.
- Vider un champ : `input keyevent 123` (fin de ligne) puis `DEL` répété (fonctionne seulement
  clavier désactivé).
- Les feuilles modales mettent ~10 s à exposer leur arbre ; les relire en boucle.
- Le script `qa_ui.py` (racine du dépôt) implémente ces règles : `dump`, `tap`, `text`,
  `clear`, `values`, `scroll`, `has`.

Captures : `qa_compte_cree.png` (compte créé), `qa_isolation_boutique1.png` (retour boutique 1).

---

## 6. Priorisation suggérée

1. ~~**F3** (QR) et **F4** (quantité 0)~~ : **corrigés et revalidés** (R1–R4, R6).
   Restent à traiter les points suivants.
2. **F2** : sortir la clé `service_role` de l'app, hacher les mots de passe (ou ne pas les
   stocker), externaliser le mot de passe superadmin.
3. **F1** : remettre un projet Supabase en service, puis rejouer le volet serveur + F5/F6/F7.
4. **F9** : afficher un état « synchro impossible » plutôt qu'un échec silencieux.
