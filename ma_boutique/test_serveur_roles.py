"""Tests bout-en-bout des rôles **côté serveur** (PostgREST + RPC).

Chaque test ouvre de vrais comptes Supabase, un par appareil, exactement
comme l'application : l'appareil s'inscrit, puis la RPC `rattacher_employe`
le relie à sa fiche employé. On vérifie ensuite que la RLS applique les
droits par rôle, que le serveur tient le stock et la caisse, que les coûts
ne fuient pas et que deux boutiques restent étanches.

Pré-requis : la migration `supabase/migration_roles.sql` appliquée sur le
projet (voir `apply_migration.py`).

Usage :
    python test_serveur_roles.py              # toute la suite
    python test_serveur_roles.py -k caisse    # seulement les tests citant « caisse »
    python test_serveur_roles.py --garder     # conserve les données de test
"""

import base64
import json
import re
import secrets
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

RACINE = Path(__file__).parent
PREFIXE_TEST = "test-serveur-"

# PNG 1×1 valide : sert à vérifier le transport des images entre appareils.
PNG_1X1 = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhK"
    "mMIQAAAABJRU5ErkJggg=="
)


# ---------------------------------------------------------------- transport


class ApiError(Exception):
    """Réponse d'erreur de Supabase (PostgREST ou Auth)."""

    def __init__(self, statut, charge):
        self.statut = statut
        self.charge = charge if isinstance(charge, dict) else {"message": str(charge)}
        self.code = str(self.charge.get("code") or "")
        self.message = str(self.charge.get("message") or self.charge)
        super().__init__(f"HTTP {self.statut} [{self.code}] {self.message}")

    @property
    def refus(self):
        """Vrai quand le serveur a refusé pour une raison de droits.

        PostgREST répond 403/42501, mais Storage renvoie 400 avec
        `AccessDenied` (RLS), `NoSuchKey` (objet invisible hors boutique) ou
        `NoSuchBucket` (bucket privé vu par un visiteur non connecté).
        """
        return self.statut in (401, 403) or self.code in (
            "42501", "PGRST301", "AccessDenied", "NoSuchKey", "NoSuchBucket"
        )


def envoyer_octets(methode, url, octets=None, entetes=None):
    """Comme `envoyer`, mais pour un corps binaire (Storage)."""
    requete = urllib.request.Request(url, data=octets, method=methode, headers=dict(entetes or {}))
    try:
        with urllib.request.urlopen(requete, timeout=60) as reponse:
            return reponse.read()
    except urllib.error.HTTPError as erreur:
        texte = erreur.read().decode(errors="replace")
        try:
            charge = json.loads(texte)
        except ValueError:
            charge = {"message": texte[:300]}
        raise ApiError(erreur.code, charge) from None


def envoyer(methode, url, corps=None, entetes=None):
    donnees = None if corps is None else json.dumps(corps).encode()
    entetes = dict(entetes or {})
    if donnees is not None:
        entetes["Content-Type"] = "application/json"
    requete = urllib.request.Request(url, data=donnees, method=methode, headers=entetes)
    try:
        with urllib.request.urlopen(requete, timeout=60) as reponse:
            texte = reponse.read().decode() or "null"
            return json.loads(texte)
    except urllib.error.HTTPError as erreur:
        texte = erreur.read().decode(errors="replace")
        try:
            charge = json.loads(texte)
        except ValueError:
            charge = {"message": texte[:500]}
        raise ApiError(erreur.code, charge) from None


def lire_cle_anon():
    """Clé « anon public » : la valeur par défaut de la configuration Dart."""
    source = (RACINE / "lib" / "core" / "supabase_config.dart").read_text(encoding="utf-8")
    url = re.search(r"supabaseUrl\s*=.*?defaultValue:\s*'([^']+)'", source, re.S)
    cle = re.search(r"supabaseAnonKey\s*=.*?defaultValue:\s*\n?\s*'([^']+)'", source, re.S)
    if not url or not cle:
        raise SystemExit("Impossible de lire l'URL/la clé Supabase dans lib/core/supabase_config.dart")
    return url.group(1).rstrip("/"), cle.group(1)


def maintenant():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def scalaire(valeur):
    """PostgREST renvoie un scalaire pour une RPC `returns bigint`."""
    if isinstance(valeur, list):
        return valeur[0] if valeur else None
    return valeur


def suffixe(n=8):
    return secrets.token_hex(n // 2)


# ---------------------------------------------------------------- appareils


class Appareil:
    """Un appareil de l'application : son propre compte Supabase."""

    def __init__(self, base, cle, etiquette):
        self.base = base
        self.cle = cle
        self.etiquette = etiquette
        self.email = f"{PREFIXE_TEST}{etiquette}-{suffixe()}@ma-boutique.app"
        self.mot_de_passe = "MotDePasse!" + suffixe(12)
        self.jeton = None
        self.utilisateur = None

    # -- session

    def _entetes(self, anonyme=False):
        return {
            "apikey": self.cle,
            "Authorization": (
                f"Bearer {self.cle}" if anonyme or not self.jeton else f"Bearer {self.jeton}"
            ),
        }

    def ouvrir(self):
        charge = envoyer(
            "POST",
            f"{self.base}/auth/v1/signup",
            {"email": self.email, "password": self.mot_de_passe},
            {"apikey": self.cle},
        )
        self.jeton = charge.get("access_token")
        self.utilisateur = (charge.get("user") or {}).get("id")
        if not self.jeton:
            raise SystemExit(f"Inscription impossible pour {self.email} : {charge}")
        return self

    # -- REST

    def rpc(self, nom, params=None, anonyme=False):
        return envoyer(
            "POST",
            f"{self.base}/rest/v1/rpc/{nom}",
            params or {},
            self._entetes(anonyme=anonyme),
        )

    def select(self, table, filtres=None, colonnes="*", ordre=None):
        url = f"{self.base}/rest/v1/{table}?select={urllib.parse.quote(colonnes, safe='*,()')}"
        for colonne, valeur in (filtres or {}).items():
            url += f"&{colonne}=eq.{urllib.parse.quote(str(valeur), safe='')}"
        if ordre:
            url += f"&order={ordre}"
        return envoyer("GET", url, None, self._entetes()) or []

    def inserer(self, table, lignes):
        corps = lignes if isinstance(lignes, list) else [lignes]
        return envoyer(
            "POST",
            f"{self.base}/rest/v1/{table}",
            corps,
            {**self._entetes(), "Prefer": "return=representation"},
        )

    # -- Storage (images produits)

    def televerser_image(self, objet, octets=None, type_mime="image/png"):
        return envoyer_octets(
            "POST",
            f"{self.base}/storage/v1/object/produits/{objet}",
            octets if octets is not None else PNG_1X1,
            {**self._entetes(), "Content-Type": type_mime},
        )

    def telecharger_image(self, objet):
        return envoyer_octets(
            "GET",
            f"{self.base}/storage/v1/object/produits/{objet}",
            None,
            self._entetes(),
        )

    def modifier(self, table, filtres, valeurs):
        morceaux = "&".join(
            f"{colonne}=eq.{urllib.parse.quote(str(valeur), safe='')}"
            for colonne, valeur in filtres.items()
        )
        return envoyer(
            "PATCH",
            f"{self.base}/rest/v1/{table}?{morceaux}",
            valeurs,
            {**self._entetes(), "Prefer": "return=representation"},
        )


# ---------------------------------------------------------------- résultats


class Resultats:
    def __init__(self):
        self.reussis = 0
        self.echecs = []
        self.filtre = None

    def _retenu(self, nom):
        return self.filtre is None or self.filtre.lower() in nom.lower()

    def verifier(self, nom, condition, detail=""):
        if not self._retenu(nom):
            return
        if condition:
            self.reussis += 1
            print(f"  OK    {nom}", flush=True)
        else:
            self.echecs.append((nom, detail))
            print(f"  ECHEC {nom}   {detail}", flush=True)

    def refus(self, nom, action):
        """L'action doit être refusée par le serveur."""
        if not self._retenu(nom):
            return
        try:
            resultat = action()
        except ApiError as erreur:
            self.verifier(nom, erreur.refus, f"reçu {erreur}")
            return
        self.verifier(nom, False, f"action acceptée : {json.dumps(resultat)[:160]}")

    def sans_effet(self, nom, action, relire, attendu):
        """L'action ne doit pas changer la valeur relue."""
        if not self._retenu(nom):
            return
        try:
            action()
        except ApiError as erreur:
            self.verifier(nom, erreur.refus, f"reçu {erreur}")
            return
        obtenu = relire()
        self.verifier(nom, obtenu == attendu, f"valeur {obtenu!r} au lieu de {attendu!r}")

    def resume(self):
        total = self.reussis + len(self.echecs)
        print(f"\n=== {self.reussis}/{total} vérifications réussies ===", flush=True)
        for nom, detail in self.echecs:
            print(f"  - {nom} : {detail}", flush=True)
        return 0 if not self.echecs else 1


# ---------------------------------------------------------------- scénario


def main():
    base, cle = lire_cle_anon()
    resultats = Resultats()
    for index, argument in enumerate(sys.argv):
        if argument == "-k" and index + 1 < len(sys.argv):
            resultats.filtre = sys.argv[index + 1]
    garder = "--garder" in sys.argv

    print(f"Serveur : {base}\n", flush=True)
    boutiques = [f"{PREFIXE_TEST}a-{suffixe()}", f"{PREFIXE_TEST}b-{suffixe()}"]

    patron_a = Appareil(base, cle, "patron-a").ouvrir()
    patron_b = Appareil(base, cle, "patron-b").ouvrir()
    caissiere = Appareil(base, cle, "caissiere-a").ouvrir()
    manager = Appareil(base, cle, "manager-a").ouvrir()
    intrus = Appareil(base, cle, "non-rattache").ouvrir()

    ids = {
        "patron_a": f"emp-{suffixe()}-patron-a",
        "patron_b": f"emp-{suffixe()}-patron-b",
        "manager": f"emp-{suffixe()}-manager-a",
        "caissiere": f"emp-{suffixe()}-caissiere-a",
        "produit": f"prod-{suffixe()}",
    }
    mdp = {"patron_a": "1234", "patron_b": "1234", "manager": "2345", "caissiere": "3456"}

    try:
        # ---------- 1. Amorçage des deux boutiques ----------
        print("1. Amorçage", flush=True)
        patron_a.rpc(
            "demarrer_boutique",
            {
                "p_boutique": boutiques[0],
                "p_nom": "Boutique test A",
                "p_employe": ids["patron_a"],
                "p_nom_employe": "Patron A",
                "p_mot_de_passe": mdp["patron_a"],
            },
        )
        patron_b.rpc(
            "demarrer_boutique",
            {
                "p_boutique": boutiques[1],
                "p_nom": "Boutique test B",
                "p_employe": ids["patron_b"],
                "p_nom_employe": "Patron B",
                "p_mot_de_passe": mdp["patron_b"],
            },
        )
        resultats.verifier(
            "demarrer_boutique crée la boutique du patron",
            len(patron_a.select("boutiques", {"id": boutiques[0]})) == 1,
        )
        try:
            patron_b.rpc(
                "demarrer_boutique",
                {
                    "p_boutique": boutiques[0],
                    "p_nom": "Usurpation",
                    "p_employe": f"emp-{suffixe()}",
                    "p_nom_employe": "Faux patron",
                    "p_mot_de_passe": "0000",
                },
            )
            resultats.verifier("demarrer_boutique ne réattribue pas une boutique existante", False, "appel accepté")
        except ApiError as erreur:
            resultats.verifier(
                "demarrer_boutique ne réattribue pas une boutique existante",
                erreur.code == "23505",
                f"reçu {erreur}",
            )

        # ---------- 2. Fiches employés créées par le patron ----------
        print("\n2. Comptes employés", flush=True)
        communs = {"boutique_id": boutiques[0], "statut": "actif", "pin_actif": False,
                   "pin": "", "biometrie": False, "date_creation": maintenant()}
        patron_a.inserer(
            "employes",
            [
                {"id": ids["manager"], "nom": "Manager A", "role": "manager",
                 "permissions": "", "mot_de_passe": mdp["manager"], **communs},
                {"id": ids["caissiere"], "nom": "Caissière A", "role": "caissiere",
                 "permissions": "", "mot_de_passe": mdp["caissiere"], **communs},
            ],
        )
        resultats.verifier(
            "le patron lit les fiches de son équipe",
            len(patron_a.select("employes", {"boutique_id": boutiques[0]})) == 3,
        )

        # ---------- 3. Connexion des appareils ----------
        print("\n3. Connexion des appareils", flush=True)
        trouve = caissiere.rpc(
            "rejoindre_boutique",
            {"p_nom": "Boutique test A", "p_role": "caissiere", "p_mot_de_passe": mdp["caissiere"]},
            anonyme=True,
        )
        resultats.verifier(
            "rejoindre_boutique retrouve la boutique avec les bons identifiants",
            isinstance(trouve, list) and trouve and trouve[0]["boutique_id"] == boutiques[0],
            f"réponse {trouve!r}",
        )
        resultats.verifier(
            "rejoindre_boutique ne répond rien avec un mauvais mot de passe",
            caissiere.rpc("rejoindre_boutique",
                          {"p_nom": "Boutique test A", "p_role": "caissiere",
                           "p_mot_de_passe": "mauvais"}, anonyme=True) in ([], None),
        )
        resultats.refus(
            "rattacher_employe refuse un mauvais mot de passe",
            lambda: caissiere.rpc("rattacher_employe",
                                  {"p_boutique": boutiques[0], "p_role": "caissiere",
                                   "p_mot_de_passe": "mauvais"}),
        )

        for appareil, role, identifiant in (
            (manager, "manager", ids["manager"]),
            (caissiere, "caissiere", ids["caissiere"]),
        ):
            lie = appareil.rpc("rattacher_employe", {
                "p_boutique": boutiques[0], "p_role": role, "p_mot_de_passe": mdp[role]})
            resultats.verifier(
                f"l'appareil {role} est relié à sa fiche",
                isinstance(lie, list) and lie and lie[0]["employe_id"] == identifiant,
                f"réponse {lie!r}",
            )

        resultats.verifier(
            "un compte non rattaché ne voit aucun produit",
            intrus.select("produits", {"boutique_id": boutiques[0]}) == [],
        )

        # ---------- 4. Catalogue et coûts ----------
        print("\n4. Catalogue", flush=True)
        produit = {
            "id": ids["produit"], "nom": "Savon test", "prix_vente": 1000,
            "quantite": 10, "actif": True, "images": "", "categorie": "autre",
            "date_ajout": maintenant(), "qr_code_data": None, "maj_ts": maintenant(),
            "prix_achat": 500,
        }
        patron_a.rpc("enregistrer_produit", {"p_data": produit})
        catalogue = patron_a.select("produits", {"boutique_id": boutiques[0]})
        resultats.verifier("le patron crée un produit", len(catalogue) == 1)
        resultats.verifier(
            "le prix d'achat n'est pas exposé dans la table produits",
            bool(catalogue) and "prix_achat" not in catalogue[0],
            f"colonnes {sorted(catalogue[0].keys()) if catalogue else []}",
        )
        couts = patron_a.select("produits_couts", {"produit_id": ids["produit"]})
        resultats.verifier(
            "le patron lit le prix d'achat dans la table dédiée",
            len(couts) == 1 and couts[0]["prix_achat"] == 500,
            f"réponse {couts!r}",
        )
        resultats.refus(
            "la caissière ne crée pas de produit (RPC)",
            lambda: caissiere.rpc("enregistrer_produit", {"p_data": {**produit, "id": f"prod-{suffixe()}"}}),
        )
        resultats.refus(
            "la caissière ne crée pas de produit (REST)",
            lambda: caissiere.inserer("produits", {
                "id": f"prod-{suffixe()}", "boutique_id": boutiques[0], "nom": "Faux",
                "prix_vente": 1, "quantite": 99, "date_ajout": maintenant()}),
        )
        resultats.sans_effet(
            "la caissière ne modifie pas le prix de vente",
            lambda: caissiere.modifier("produits", {"id": ids["produit"]}, {"prix_vente": 1}),
            lambda: patron_a.select("produits", {"id": ids["produit"]})[0]["prix_vente"],
            1000,
        )
        resultats.sans_effet(
            "la caissière ne gonfle pas le stock",
            lambda: caissiere.modifier("produits", {"id": ids["produit"]}, {"quantite": 999}),
            lambda: patron_a.select("produits", {"id": ids["produit"]})[0]["quantite"],
            10,
        )
        resultats.verifier(
            "la caissière lit le catalogue",
            len(caissiere.select("produits", {"boutique_id": boutiques[0]})) == 1,
        )
        resultats.verifier(
            "la caissière ne lit pas les prix d'achat des produits",
            caissiere.select("produits_couts", {"boutique_id": boutiques[0]}) == [],
        )
        resultats.verifier(
            "la caissière ne lit que sa propre fiche employé",
            [e["id"] for e in caissiere.select("employes", {"boutique_id": boutiques[0]})]
            == [ids["caissiere"]],
        )

        # ---------- 5. Dépenses et journal ----------
        print("\n5. Dépenses et journal", flush=True)
        resultats.refus(
            "la caissière ne crée pas de dépense",
            lambda: caissiere.inserer("depenses", {
                "id": f"dep-{suffixe()}", "boutique_id": boutiques[0],
                "description": "Fausse dépense", "montant": 1000, "auteur_nom": "Caissière A",
                "auteur_role": "caissiere", "type": "depense", "date": maintenant()}),
        )
        resultats.verifier(
            "la caissière ne lit pas les dépenses",
            caissiere.select("depenses", {"boutique_id": boutiques[0]}) == [],
        )
        resultats.verifier(
            "la caissière ne lit pas le journal d'activité",
            caissiere.select("activites", {"boutique_id": boutiques[0]}) == [],
        )

        # ---------- 6. Vente, stock et caisse ----------
        print("\n6. Vente, stock et caisse", flush=True)
        vente_id = f"vente-{suffixe()}"
        caissiere.rpc("enregistrer_vente", {"p_data": {
            "id": vente_id, "produit_id": ids["produit"], "quantite": 2,
            "prix_unitaire_reel": 1000, "total": 1, "date": maintenant()}})
        ventes = caissiere.select("ventes", {"boutique_id": boutiques[0]})
        resultats.verifier("la caissière enregistre une vente", len(ventes) == 1, f"{ventes!r}")
        resultats.verifier(
            "le serveur recalcule le total de la vente",
            bool(ventes) and ventes[0]["total"] == 2000,
            f"total {ventes[0]['total'] if ventes else None}",
        )
        resultats.verifier(
            "le serveur décrémente le stock",
            patron_a.select("produits", {"id": ids["produit"]})[0]["quantite"] == 8,
        )
        caisse = patron_a.select("boutiques", {"id": boutiques[0]})[0]["solde_caisse"]
        resultats.verifier("le serveur crédite la caisse", caisse == 2000, f"caisse {caisse}")
        resultats.sans_effet(
            "le patron ne peut pas forcer la caisse à la main",
            lambda: patron_a.modifier("boutiques", {"id": boutiques[0]}, {"solde_caisse": 999999}),
            lambda: patron_a.select("boutiques", {"id": boutiques[0]})[0]["solde_caisse"],
            2000,
        )
        couts_vente = patron_a.select("ventes_couts", {"vente_id": vente_id})
        resultats.verifier(
            "le coût de la vente est figé côté serveur",
            len(couts_vente) == 1 and couts_vente[0]["prix_achat_unitaire"] == 500,
            f"réponse {couts_vente!r}",
        )
        resultats.verifier(
            "la caissière ne lit pas le coût de sa vente",
            caissiere.select("ventes_couts", {"vente_id": vente_id}) == [],
        )
        # Sans politique de mise à jour, PostgREST répond 200 avec zéro ligne
        # modifiée : le total ne bouge pas.
        resultats.sans_effet(
            "la caissière ne réécrit pas le total de sa vente",
            lambda: caissiere.modifier("ventes", {"id": vente_id}, {"total": 1}),
            lambda: patron_a.select("ventes", {"id": vente_id})[0]["total"],
            2000,
        )
        resultats.refus(
            "la caissière n'insère pas une vente en direct",
            lambda: caissiere.inserer("ventes", {
                "id": f"vente-{suffixe()}", "boutique_id": boutiques[0],
                "produit_id": ids["produit"], "produit_nom": "Savon test", "quantite": 1,
                "prix_unitaire_reel": 1, "total": 1, "vendeur_id": ids["caissiere"],
                "vendeur_nom": "Caissière A", "vendeur_role": "caissiere", "date": maintenant()}),
        )

        # ---------- 7. Le manager ----------
        print("\n7. Manager", flush=True)
        manager.rpc("enregistrer_vente", {"p_data": {
            "id": f"vente-{suffixe()}", "produit_id": ids["produit"], "quantite": 1,
            "prix_unitaire_reel": 1000, "date": maintenant()}})
        resultats.verifier(
            "le manager vend",
            len(manager.select("ventes", {"boutique_id": boutiques[0]})) == 2,
            f"{manager.select('ventes', {'boutique_id': boutiques[0]})!r}",
        )
        resultats.verifier(
            "la caissière ne voit que ses propres ventes",
            len(caissiere.select("ventes", {"boutique_id": boutiques[0]})) == 1,
        )
        resultats.verifier(
            "le manager ne lit pas les prix d'achat",
            manager.select("produits_couts", {"boutique_id": boutiques[0]}) == [],
        )
        resultats.refus(
            "le manager ne gère pas les comptes",
            lambda: manager.inserer("employes", {
                "id": f"emp-{suffixe()}", "nom": "Intrus", "role": "patron",
                "permissions": "", "mot_de_passe": "0000", **communs}),
        )
        resultats.verifier(
            "le manager ne lit pas le journal",
            manager.select("activites", {"boutique_id": boutiques[0]}) == [],
        )

        # ---------- 8. Isolation entre boutiques ----------
        print("\n8. Isolation entre boutiques", flush=True)
        resultats.verifier(
            "la boutique B ne voit pas le catalogue de A",
            patron_b.select("produits", {"boutique_id": boutiques[0]}) == []
            and patron_b.select("produits", {"boutique_id": boutiques[1]}) == [],
        )
        resultats.verifier(
            "la boutique B ne voit pas les ventes de A",
            patron_b.select("ventes", {"boutique_id": boutiques[0]}) == [],
        )
        resultats.verifier(
            "la boutique B ne voit pas les employés de A",
            patron_b.select("employes", {"boutique_id": boutiques[0]}) == [],
        )
        resultats.verifier(
            "la boutique B ne voit pas la caisse de A",
            patron_b.select("boutiques", {"id": boutiques[0]}) == [],
        )
        try:
            patron_b.rpc("enregistrer_vente", {"p_data": {
                "id": f"vente-{suffixe()}", "produit_id": ids["produit"], "quantite": 1,
                "prix_unitaire_reel": 1000, "date": maintenant()}})
            resultats.verifier("la boutique B ne peut pas vendre un produit de A", False, "vente acceptée")
        except ApiError as erreur:
            resultats.verifier(
                "la boutique B ne peut pas vendre un produit de A",
                erreur.refus or erreur.code == "22023",
                f"reçu {erreur}",
            )
        resultats.refus(
            "stats_boutique refuse la boutique d'un autre",
            lambda: caissiere.rpc("stats_boutique", {"p_boutique_id": boutiques[1]}),
        )
        resultats.verifier(
            "compte_metier ne compte rien pour une autre boutique",
            scalaire(caissiere.rpc("compte_metier", {"p_boutique": boutiques[1]})) == 0,
        )
        resultats.verifier(
            "compte_metier compte les lignes de sa boutique",
            (scalaire(patron_a.rpc("compte_metier", {"p_boutique": boutiques[0]})) or 0) > 0,
        )

        # ---------- 9. Lectures de synchronisation (ce que le client tire) ----------
        print("\n9. Synchronisation client", flush=True)
        produits_caissiere = caissiere.select("produits_employe", {"boutique_id": boutiques[0]})
        resultats.verifier(
            "la vue produits_employe masque le coût pour la caissière",
            len(produits_caissiere) == 1 and produits_caissiere[0]["prix_achat"] == 0,
            f"{produits_caissiere!r}",
        )
        resultats.verifier(
            "la vue produits_employe donne le stock à jour (7 unités)",
            bool(produits_caissiere) and produits_caissiere[0]["quantite"] == 7,
            f"{produits_caissiere!r}",
        )
        produits_patron = patron_a.select("produits_employe", {"boutique_id": boutiques[0]})
        resultats.verifier(
            "la vue produits_employe donne le coût réel au patron",
            len(produits_patron) == 1 and produits_patron[0]["prix_achat"] == 500,
            f"{produits_patron!r}",
        )
        ventes_caissiere = caissiere.select("ventes_employe", {"boutique_id": boutiques[0]})
        resultats.verifier(
            "la vue ventes_employe masque le coût pour la caissière",
            len(ventes_caissiere) == 1 and ventes_caissiere[0]["prix_achat_unitaire"] == 0,
            f"{ventes_caissiere!r}",
        )
        ventes_patron = patron_a.select("ventes_employe", {"boutique_id": boutiques[0]})
        resultats.verifier(
            "la vue ventes_employe donne le coût réel au patron",
            len(ventes_patron) == 2
            and all(v["prix_achat_unitaire"] == 500 for v in ventes_patron),
            f"{ventes_patron!r}",
        )
        resultats.verifier(
            "la caisse cumule les ventes des deux employés",
            patron_a.select("boutiques", {"id": boutiques[0]})[0]["solde_caisse"] == 3000,
            f"caisse {patron_a.select('boutiques', {'id': boutiques[0]})[0]['solde_caisse']}",
        )
        verifier_temps_reel(resultats)

        # ---------- 10. Deux appareils du même employé ----------
        print("\n10. Deux appareils du même employé", flush=True)
        caissiere_2 = Appareil(base, cle, "caissiere-a2").ouvrir()
        lie_2 = caissiere_2.rpc("rattacher_employe", {
            "p_boutique": boutiques[0], "p_role": "caissiere",
            "p_mot_de_passe": mdp["caissiere"]})
        resultats.verifier(
            "un second appareil se rattache au même employé",
            isinstance(lie_2, list) and lie_2 and lie_2[0]["employe_id"] == ids["caissiere"],
            f"réponse {lie_2!r}",
        )
        vente_dev2 = f"vente-{suffixe()}"
        caissiere_2.rpc("enregistrer_vente", {"p_data": {
            "id": vente_dev2, "produit_id": ids["produit"], "quantite": 1,
            "prix_unitaire_reel": 1000, "date": maintenant()}})
        resultats.verifier(
            "la vente saisie sur le second appareil arrive sur le premier",
            any(v["id"] == vente_dev2
                for v in caissiere.select("ventes", {"boutique_id": boutiques[0]})),
        )
        vente_dev1 = f"vente-{suffixe()}"
        caissiere.rpc("enregistrer_vente", {"p_data": {
            "id": vente_dev1, "produit_id": ids["produit"], "quantite": 1,
            "prix_unitaire_reel": 1000, "date": maintenant()}})
        resultats.verifier(
            "les deux appareils du même employé partagent le même stock (5)",
            caissiere.select("produits_employe", {"id": ids["produit"]})[0]["quantite"] == 5
            and caissiere_2.select("produits_employe", {"id": ids["produit"]})[0]["quantite"] == 5,
            f"{caissiere.select('produits_employe', {'id': ids['produit']})!r}",
        )
        resultats.verifier(
            "la caisse cumule les ventes des deux appareils (5000)",
            patron_a.select("boutiques", {"id": boutiques[0]})[0]["solde_caisse"] == 5000,
        )
        resultats.verifier(
            "chaque appareil voit les ventes de l'autre",
            len(caissiere.select("ventes_employe", {"boutique_id": boutiques[0]})) == 3
            and len(caissiere_2.select("ventes_employe", {"boutique_id": boutiques[0]})) == 3,
            f"{len(caissiere.select('ventes_employe', {'boutique_id': boutiques[0]}))} / "
            f"{len(caissiere_2.select('ventes_employe', {'boutique_id': boutiques[0]}))}",
        )

        # ---------- 11. Images partagées entre appareils ----------
        print("\n11. Images entre appareils", flush=True)
        objet = f"{boutiques[0]}/{ids['produit']}/photo-{suffixe()}.png"
        try:
            patron_a.televerser_image(objet)
            resultats.verifier("le patron téléverse l'image du produit", True)
        except ApiError as erreur:
            resultats.verifier("le patron téléverse l'image du produit", False, f"reçu {erreur}")
        try:
            recue = manager.telecharger_image(objet)
        except ApiError as erreur:
            recue = b""
            resultats.verifier("un collègue télécharge l'image du produit", False, f"reçu {erreur}")
        else:
            resultats.verifier(
                "un collègue télécharge l'image du produit",
                recue == PNG_1X1,
                f"{len(recue)} octets reçus",
            )
        try:
            vue_caissiere = caissiere.telecharger_image(objet)
        except ApiError:
            vue_caissiere = b""
        resultats.verifier(
            "la caissière peut afficher l'image (lecture seule)",
            vue_caissiere == PNG_1X1,
        )
        resultats.refus(
            "la caissière ne téléverse pas d'image",
            lambda: caissiere.televerser_image(f"{boutiques[0]}/{ids['produit']}/intrus.png"),
        )
        resultats.refus(
            "une autre boutique ne télécharge pas l'image",
            lambda: patron_b.telecharger_image(objet),
        )
        resultats.refus(
            "un visiteur non connecté ne télécharge pas l'image (bucket privé)",
            lambda: envoyer_octets(
                "GET",
                f"{base}/storage/v1/object/produits/{objet}",
                None,
                {"apikey": cle},
            ),
        )
        resultats.refus(
            "une autre boutique ne téléverse pas dans le dossier d'autrui",
            lambda: patron_b.televerser_image(f"{boutiques[0]}/{ids['produit']}/intrus.png"),
        )
        stock_actuel = patron_a.select("produits", {"id": ids["produit"]})[0]["quantite"]
        patron_a.rpc("enregistrer_produit", {"p_data": {
            **produit, "images": objet, "quantite": stock_actuel, "maj_ts": maintenant()}})
        vu = manager.select("produits_employe", {"id": ids["produit"]})
        resultats.verifier(
            "le chemin d'image circule dans la colonne images",
            bool(vu) and vu[0]["images"] == objet,
            f"{vu!r}",
        )
        try:
            depuis_colonne = manager.telecharger_image(vu[0]["images"]) if vu else b""
        except (ApiError, KeyError):
            depuis_colonne = b""
        resultats.verifier(
            "l'image référencée par la fiche est téléchargeable (ce que fait la synchro)",
            depuis_colonne == PNG_1X1,
        )

        # ---------- 12. Temps réel ----------
        print("\n12. Temps réel", flush=True)
        verifier_canaux_temps_reel(resultats, base, cle, patron_a, caissiere,
                                   ids["produit"], boutiques[0])

        # ---------- 13. Déconnexion ----------
        print("\n13. Détachement de l'appareil", flush=True)
        caissiere.rpc("detacher_employe")
        resultats.verifier(
            "un appareil détaché ne voit plus rien",
            caissiere.select("produits", {"boutique_id": boutiques[0]}) == [],
        )
        resultats.refus(
            "un appareil détaché ne peut plus vendre",
            lambda: caissiere.rpc("enregistrer_vente", {"p_data": {
                "id": f"vente-{suffixe()}", "produit_id": ids["produit"], "quantite": 1,
                "prix_unitaire_reel": 1000, "date": maintenant()}}),
        )
    finally:
        if not garder:
            nettoyer(boutiques)

    return resultats.resume()


def _ouvrir_canal(url, appareil, nom, boutique, essais=3):
    """Joint le canal Realtime et s'abonne aux ventes de la boutique.

    La connexion websocket est parfois refusée par le réseau : trois essais
    espacés évitent de transformer un incident passager en échec de suite.
    """
    from websockets.sync.client import connect
    derniere = None
    for essai in range(essais):
        try:
            # `legacy=True` : connexion directe, utilisable hors bloc `with`.
            socket = connect(url, open_timeout=30, legacy=True)
            socket.send(json.dumps({
                "topic": f"realtime:{nom}",
                "event": "phx_join",
                "ref": "1",
                "join_ref": "1",
                "payload": {
                    "config": {"postgres_changes": [{
                        "event": "INSERT",
                        "schema": "public",
                        "table": "ventes",
                        "filter": f"boutique_id=eq.{boutique}",
                    }]},
                    "access_token": appareil.jeton,
                },
            }))
            return socket
        except OSError as erreur:  # TimeoutError en fait partie
            derniere = erreur
            print(f"       (canal {nom} indisponible : {erreur}, nouvel essai)", flush=True)
            time.sleep(2 + 2 * essai)
    raise derniere


def _attendre_abonnement(socket, delai=20):
    fin = time.time() + delai
    while time.time() < fin:
        try:
            message = json.loads(socket.recv(timeout=max(0.5, fin - time.time())))
        except Exception:  # noqa: BLE001 - timeout ou socket fermé
            return False
        if message.get("event") == "system":
            return message.get("payload", {}).get("status") == "ok"
        if message.get("event") == "phx_reply":
            if message.get("payload", {}).get("status") != "ok":
                return False
    return False


def _attendre_vente(socket, vente_id, delai):
    """Vrai si l'événement de cette vente arrive avant `delai` secondes."""
    fin = time.time() + delai
    while time.time() < fin:
        try:
            message = json.loads(socket.recv(timeout=max(0.5, fin - time.time())))
        except Exception:  # noqa: BLE001 - timeout
            return False
        if message.get("event") != "postgres_changes":
            continue
        donnees = message.get("payload", {}).get("data", {})
        if donnees.get("table") == "ventes" and \
                (donnees.get("record") or {}).get("id") == vente_id:
            return True
    return False


def verifier_canaux_temps_reel(resultats, base, cle, patron, caissiere, produit_id, boutique):
    """Deux appareils écoutent la même boutique : la RLS filtre les événements."""
    try:
        from websockets.sync.client import connect  # noqa: F401
    except ImportError:
        resultats.verifier(
            "le temps réel est testable (paquet websockets installé)",
            False,
            "pip install websockets",
        )
        return
    reference = base.split("//")[1].split(".")[0]
    url = f"wss://{reference}.supabase.co/realtime/v1/websocket?apikey={cle}&vsn=1.0.0"
    canaux = {}
    try:
        for nom, appareil in (("patron", patron), ("caissiere", caissiere)):
            canaux[nom] = _ouvrir_canal(url, appareil, f"test-{nom}", boutique)
            resultats.verifier(
                f"le canal temps réel s'ouvre pour {nom}",
                _attendre_abonnement(canaux[nom]),
            )

        vente_patron = f"vente-{suffixe()}"
        patron.rpc("enregistrer_vente", {"p_data": {
            "id": vente_patron, "produit_id": produit_id, "quantite": 1,
            "prix_unitaire_reel": 1000, "date": maintenant()}})
        resultats.verifier(
            "le patron reçoit la nouvelle vente en temps réel",
            _attendre_vente(canaux["patron"], vente_patron, 25),
        )
        resultats.verifier(
            "la caissière ne reçoit pas la vente du patron (RLS du temps réel)",
            not _attendre_vente(canaux["caissiere"], vente_patron, 8),
        )

        vente_caissiere = f"vente-{suffixe()}"
        caissiere.rpc("enregistrer_vente", {"p_data": {
            "id": vente_caissiere, "produit_id": produit_id, "quantite": 1,
            "prix_unitaire_reel": 1000, "date": maintenant()}})
        resultats.verifier(
            "la caissière reçoit sa propre vente en temps réel",
            _attendre_vente(canaux["caissiere"], vente_caissiere, 25),
        )
    except OSError as erreur:
        # Ne jamais sortir en succès sans avoir testé le temps réel.
        resultats.verifier(
            "le temps réel est joignable",
            False,
            f"connexion impossible : {erreur}",
        )
    finally:
        for socket in canaux.values():
            try:
                socket.close()
            except Exception:  # noqa: BLE001
                pass


TABLES_SYNCHRONISEES = (
    "activites", "appareils", "boutiques", "depenses", "employes",
    "notifications", "pointages", "produits", "retours", "ventes",
)


def verifier_temps_reel(resultats):
    """Publication Realtime et `replica identity`, lues hors RLS."""
    try:
        from apply_migration import BacAMgmt, lire_secret
    except ImportError:
        print("  (temps réel non vérifié : apply_migration.py introuvable)", flush=True)
        return
    secret = lire_secret()
    if not secret or secret[0] != "management":
        print("  (temps réel non vérifié : jeton Management absent)", flush=True)
        return
    bac = BacAMgmt(secret[1])
    publiees = {
        ligne[0] for ligne in bac.requete(
            "select tablename from pg_publication_tables where pubname = 'supabase_realtime'"
        )
    }
    manquantes = [t for t in TABLES_SYNCHRONISEES if t not in publiees]
    resultats.verifier(
        "toutes les tables synchronisées sont publiées pour le temps réel",
        not manquantes,
        f"manquantes {manquantes}",
    )
    repliques = {
        ligne[0] for ligne in bac.requete(
            "select relname from pg_class where relreplident = 'f' "
            "and relname in (" + ",".join(f"'{t}'" for t in TABLES_SYNCHRONISEES) + ")"
        )
    }
    sans_identite = [t for t in TABLES_SYNCHRONISEES if t not in repliques]
    resultats.verifier(
        "les tables du temps réel gardent leur identité complète (suppressions)",
        not sans_identite,
        f"manquantes {sans_identite}",
    )


def nettoyer(boutiques):
    """Supprime les données de test via l'API Management (hors RLS)."""
    try:
        from apply_migration import BacAMgmt, lire_secret
    except ImportError:
        print("\n(nettoyage impossible : apply_migration.py introuvable)", flush=True)
        return
    secret = lire_secret()
    if not secret or secret[0] != "management":
        print("\n(nettoyage ignoré : jeton Management absent)", flush=True)
        return
    try:
        bac = BacAMgmt(secret[1])
        for boutique in boutiques:
            bac.executer(f"delete from boutiques where id = '{boutique}'")
        bac.executer(f"delete from boutiques where id like '{PREFIXE_TEST}%'")
        print("\nDonnées de test supprimées.", flush=True)
    except Exception as erreur:  # noqa: BLE001 - le nettoyage ne doit pas masquer les tests
        print(f"\n(nettoyage partiel : {erreur})", flush=True)


if __name__ == "__main__":
    raise SystemExit(main())
