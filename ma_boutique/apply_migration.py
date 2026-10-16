"""Applique la migration « temps réel » directement sur Postgres.

Usage :
    python apply_migration.py            # applique puis vérifie
    python apply_migration.py --check    # vérifie seulement

Le secret est lu dans `.pg_conn.txt` (fichier local ignoré par git) ou dans la
variable d'environnement `PG_CONN`. Il n'est jamais imprimé : les éventuelles
erreurs sont masquées. Deux formats sont acceptés :

1. Chaîne Postgres (Dashboard → Settings → Database → Connection string → URI) :
       postgresql://postgres.<ref>:<motdepasse>@db.<ref>.supabase.co:5432/postgres
2. Jeton de l'API Management (Dashboard → Account → API tokens, scope "Postgres"
   ou "Debug queries"), utile si le port 5432 est bloqué par le réseau :
       sbp_xxxxxxxxxxxxxxxxxxxxxxxx
"""

import json
import os
import re
import sys
import urllib.request
from pathlib import Path

CHEMIN_CONN = Path(__file__).with_name(".pg_conn.txt")
CHEMIN_SQL = Path(__file__).parent / "supabase" / "migration_temps_reel.sql"
REF_PROJET = "kxgluwdhlgzmgdcszeln"


def lire_secret():
    valeur = os.environ.get("PG_CONN", "").strip()
    if not valeur and CHEMIN_CONN.exists():
        # On ignore les lignes vides et les commentaires (# ...).
        lignes = [
            ligne.strip()
            for ligne in CHEMIN_CONN.read_text(encoding="utf-8").splitlines()
            if ligne.strip() and not ligne.strip().startswith("#")
        ]
        valeur = lignes[0] if lignes else ""
    if not valeur:
        print(f"ERREUR: aucun secret dans {CHEMIN_CONN.name} ni dans PG_CONN.")
        return None
    if re.search(r"\[[^\]]*\]", valeur) or "YOUR-PASSWORD" in valeur:
        print("ERREUR: le mot de passe n'a pas encore été renseigné dans "
              f"{CHEMIN_CONN.name}.")
        print("       Remplace la partie entre crochets par le vrai mot de passe, "
              "ou copie l'URI complète depuis le dashboard (bouton Reveal puis Copy).")
        return None
    if valeur.startswith("sbp_"):
        return ("management", valeur)
    if valeur.startswith("postgres://"):
        valeur = valeur.replace("postgres://", "postgresql://", 1)
    if "sslmode=" not in valeur:
        valeur += ("&" if "?" in valeur else "?") + "sslmode=require"
    return ("postgres", valeur)


class BacAMgmt:
    """Exécute les instructions via l'API Management de Supabase."""

    def __init__(self, jeton):
        self.jeton = jeton

    def executer(self, instruction):
        requete = urllib.request.Request(
            f"https://api.supabase.com/v1/projects/{REF_PROJET}/database/query",
            data=json.dumps({"query": instruction}).encode(),
            method="POST",
            headers={
                "Authorization": f"Bearer {self.jeton}",
                "Content-Type": "application/json",
            },
        )
        with urllib.request.urlopen(requete, timeout=30) as reponse:
            self.derniere = json.loads(reponse.read().decode() or "[]")

    def requete(self, instruction, params=None):
        self.executer(instruction)
        lignes = self.derniere
        if not lignes:
            return []
        cles = list(lignes[0].keys())
        return [tuple(ligne.get(cle) for cle in cles) for ligne in lignes]

    def fermer(self):
        return None


def _ipv4_disponible(chaine):
    """Vrai si l'hôte de la base est joignable en IPv4.

    Certains projets Supabase n'ont qu'un enregistrement AAAA (IPv6) pour
    `db.<ref>.supabase.co` ; sans connectivité IPv6 publique, la connexion
    échouerait de façon obscure. On prévient plutôt que d'attendre un timeout.
    """
    import socket

    hote = re.search(r"@([^/:]+)", chaine)
    if hote is None:
        return True
    try:
        adresses = socket.getaddrinfo(hote.group(1), 5432, socket.AF_INET, socket.SOCK_STREAM)
    except socket.gaierror:
        return False
    return bool(adresses)


def masquer(texte):
    """Ne jamais laisser passer le mot de passe ou l'identifiant."""
    texte = re.sub(r"(://[^:/@\s]+):[^@\s]+@", r"\1:***@", str(texte))
    return texte


def decouper(sql):
    """Découpe un script SQL en instructions en respectant les guillemets et
    le dollar-quoting ($$ ... $$) des fonctions procédurales."""
    declarations = []
    courant = []
    i = 0
    n = len(sql)
    while i < n:
        caractere = sql[i]
        if caractere == "'":
            j = i + 1
            while j < n:
                if sql[j] == "'":
                    if j + 1 < n and sql[j + 1] == "'":
                        j += 2
                        continue
                    break
                j += 1
            courant.append(sql[i : j + 1])
            i = j + 1
            continue
        if caractere == '"':
            j = i + 1
            while j < n and sql[j] != '"':
                j += 1
            courant.append(sql[i : j + 1])
            i = j + 1
            continue
        if caractere == "$":
            fin_tag = sql.find("$", i + 1)
            if fin_tag != -1 and re.fullmatch(r"[A-Za-z0-9_]*", sql[i + 1 : fin_tag]):
                etiquette = sql[i : fin_tag + 1]
                cloture = sql.find(etiquette, fin_tag + 1)
                if cloture != -1:
                    courant.append(sql[i : cloture + len(etiquette)])
                    i = cloture + len(etiquette)
                    continue
        if caractere == "-" and i + 1 < n and sql[i + 1] == "-":
            j = sql.find("\n", i)
            i = n if j == -1 else j + 1
            continue
        if caractere == ";":
            instruction = "".join(courant).strip()
            if instruction:
                declarations.append(instruction)
            courant = []
            i += 1
            continue
        courant.append(caractere)
        i += 1
    reste = "".join(courant).strip()
    if reste:
        declarations.append(reste)
    return declarations


def verifier(executer_requete):
    """Contrôle post-migration : colonnes produits, publication, réplication, trigger."""
    colonnes = [r[0] for r in executer_requete(
        "select column_name from information_schema.columns "
        "where table_schema='public' and table_name='produits' "
        "and column_name in ('images','categorie','date_ajout','qr_code_data') "
        "order by column_name"
    )]

    publiees = [r[0] for r in executer_requete(
        "select tablename from pg_publication_tables "
        "where pubname='supabase_realtime' order by tablename"
    )]

    attendues = [
        "activites", "appareils", "boutiques", "depenses", "employes",
        "notifications", "pointages", "produits", "retours", "ventes",
    ]

    replique = {r[0]: r[1] for r in executer_requete(
        "select relname, relreplident from pg_class "
        "where relname in ('" + "','".join(attendues) + "') order by relname"
    )}

    triggers = sorted(r[0] for r in executer_requete(
        "select distinct tgrelid::regclass::text from pg_trigger "
        "where tgname = 'maj_ts_auto' and not tgisinternal"
    ))

    print("--- VÉRIFICATIONS ---")
    manquantes = [c for c in ("images", "categorie", "date_ajout", "qr_code_data") if c not in colonnes]
    print(f"colonnes produits : {'OK (4/4)' if not manquantes else 'MANQUANTES ' + str(manquantes)}")

    absentes = [t for t in attendues if t not in publiees]
    print(f"publication realtime : {'OK (10/10)' if not absentes else 'ABSENTES ' + str(absentes)}")

    nonfull = [t for t in attendues if replique.get(t) != "f"]
    print(f"replica identity full : {'OK (10/10)' if not nonfull else 'DEFAUT pour ' + str(nonfull)}")

    print(f"trigger maj_ts_auto  : {'OK (' + str(len(triggers)) + ' tables)' if len(triggers) == 10 else 'MANQUANT sur ' + str(sorted(set(attendues) - set(triggers)))}")

    return not (manquantes or absentes or nonfull or len(triggers) < 10)


def main():
    verif_seule = "--check" in sys.argv
    secret = lire_secret()
    if secret is None:
        return 2
    type_secret, valeur = secret

    connexion = None
    if type_secret == "management":
        bac = BacAMgmt(valeur)
        executer = bac.executer
        requete = bac.requete
        cible = "API Management Supabase"
    else:
        try:
            import psycopg
        except ImportError:
            print("ERREUR: psycopg absent — pip install psycopg[binary]")
            return 2
        if not _ipv4_disponible(valeur):
            print("IMPOSSIBLE: ce projet Supabase n'existe qu'en IPv6 (db.<ref>.supabase.co)")
            print("            et cette machine n'a pas de connectivité IPv6 publique.")
            print("            => Utilise un jeton API Management (sbp_…) à la place,")
            print("               ou exécute le SQL dans le dashboard Supabase.")
            return 4
        try:
            connexion = psycopg.connect(valeur, connect_timeout=20, autocommit=True)
            curseur = connexion.cursor()
        except Exception as erreur:  # noqa: BLE001
            print(f"ERREUR de connexion: {masquer(erreur)}")
            return 3
        executer = curseur.execute
        requete = lambda sql, params=None: (curseur.execute(sql, params or []), curseur.fetchall())[1]
        cible = "Postgres (port 5432)"

    try:
        if verif_seule:
            return 0 if verifier(requete) else 1

        script = CHEMIN_SQL.read_text(encoding="utf-8")
        instructions = decouper(script)
        print(f"connecté via {cible} — {len(instructions)} instructions à exécuter")
        echecs = []
        for index, instruction in enumerate(instructions, start=1):
            debut = instruction.split("\n")[0][:70]
            try:
                executer(instruction)
                print(f"  {index:>2}. OK   {debut}")
            except Exception as erreur:  # noqa: BLE001 - on affiche puis on poursuit
                echecs.append((debut, masquer(erreur)))
                print(f"  {index:>2.} ECHEC {debut} -> {masquer(erreur)}")
        if echecs:
            print("--- ECHECS ---")
            for debut, erreur in echecs:
                print(f" {debut}: {erreur}")
            return 1
        return 0 if verifier(requete) else 1
    except Exception as erreur:  # noqa: BLE001
        print(f"ERREUR de connexion/exécution: {masquer(erreur)}")
        return 3
    finally:
        if connexion is not None:
            connexion.close()


if __name__ == "__main__":
    raise SystemExit(main())
