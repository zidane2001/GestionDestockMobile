"""Reproduit la configuration exacte de l'application mobile.

L'app se connecte avec un compte boutique (clé anon + RLS du tenant) et
s'abonne avec un canal PUBLIC via `canal.onPostgresChanges(...)`. Ce script
refait exactement cela pour vérifier que la diffusion arrive bien, et mesure
le délai — c'est le chemin que l'appareil utilisera réellement.
"""

import asyncio
import json
import ssl
import time
import urllib.parse
import urllib.request

import websockets

PROJET = "kxgluwdhlgzmgdcszeln"
ANON = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4Z2x1"
    "d2RobGd6bWdkY3N6ZWxuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcxMjkwNTMsImV4cCI6MjEw"
    "MjcwNTA1M30.Y99XBlEdPZ5SV3vnlFHYY6JdE2KxT_258UHbS5kkYng"
)
SERVICE = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4Z2x1"
    "d2RobGd6bWdkY3N6ZWxuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NzEyOTA1Mywi"
    "ZXhwIjoyMTAyNzA1MDUzfQ.K3368bW_8MBcELoxXmCj1cP79i03Riqii-3Qd44vYXQ"
)
BASE = f"https://{PROJET}.supabase.co"


def requete(url, methode="GET", corps=None, cle=None):
    data = json.dumps(corps).encode() if corps is not None else None
    entetes = {"Content-Type": "application/json"}
    if cle:
        entetes["apikey"] = cle
        entetes["Authorization"] = f"Bearer {cle}"
    rq = urllib.request.Request(url, data=data, method=methode, headers=entetes)
    with urllib.request.urlopen(rq, timeout=20) as reponse:
        brut = reponse.read().decode()
        return json.loads(brut) if brut else {}


def identifiants(boutique_id):
    """Reproduit exactement la dérivation de `SyncService._client`."""
    propre = "".join(c for c in boutique_id.lower() if c.isalnum())
    return f"boutique-{propre}@ma-boutique.app", f"mb-{propre}"


def connexion_boutique(boutique_id):
    email, mdp = identifiants(boutique_id)
    try:
        retour = requete(
            f"{BASE}/auth/v1/token?grant_type=password",
            "POST",
            {"email": email, "password": mdp},
            cle=ANON,
        )
        return retour.get("access_token"), email
    except Exception as erreur:  # noqa: BLE001
        return None, f"{email} -> {type(erreur).__name__}"


async def main():
    # Une boutique qui possède au moins un produit et un compte tenant.
    tenants = requete(f"{BASE}/rest/v1/boutique_tenants?select=boutique_id&limit=50", cle=SERVICE)
    candidats = sorted({t["boutique_id"] for t in tenants})

    cible = None
    jeton = None
    email = None
    for boutique_id in candidats:
        produits = requete(
            f"{BASE}/rest/v1/produits?select=id,nom,quantite&boutique_id=eq.{urllib.parse.quote(boutique_id)}&limit=1",
            cle=SERVICE,
        )
        if not produits:
            continue
        jeton, info = connexion_boutique(boutique_id)
        if jeton:
            cible = (boutique_id, produits[0])
            email = info
            break
        print(f"  compte introuvable : {info}")
        await asyncio.sleep(1)

    if not jeton:
        print("ECHEC: aucun compte boutique existant n'a pu être ouvert.")
        return 2

    boutique_id, produit = cible
    print(f"boutique   : {boutique_id}")
    print(f"compte     : {email}")
    print(f"produit    : {produit['id']} / {produit['nom']!r}")

    topic = f"realtime:app-{int(time.time()) % 100000}"
    url = f"wss://{PROJET}.supabase.co/realtime/v1/websocket?apikey={ANON}&vsn=1.0.0"
    ctx = ssl.create_default_context()
    evenements = []

    async with websockets.connect(url, ssl=ctx, max_size=10**7) as ws:
        # Canal PUBLIC filtré sur la boutique, comme `demarrerTempsReel`.
        await ws.send(json.dumps({
            "topic": topic,
            "event": "phx_join",
            "payload": {
                "config": {
                    "broadcast": {"self": False},
                    "presence": {"key": ""},
                    "postgres_changes": [
                        {
                            "event": "*",
                            "schema": "public",
                            "table": "produits",
                            "filter": f"boutique_id=eq.{boutique_id}",
                        }
                    ],
                    "private": False,
                },
                "access_token": jeton,
            },
            "ref": "1",
        }))
        reponse = json.loads(await asyncio.wait_for(ws.recv(), timeout=15))
        statut = reponse.get("payload", {}).get("status")
        print(f"abonnement : {statut}")
        if statut != "ok":
            print("  ->", json.dumps(reponse.get("payload"))[:200])
            return 1

        t0 = time.monotonic()
        requete(
            f"{BASE}/rest/v1/produits?id=eq.{produit['id']}",
            "PATCH",
            {"quantite": produit.get("quantite", 1)},
            cle=SERVICE,
        )
        print("modification envoyée par un « autre appareil », attente…")

        async def guetter():
            while True:
                trame = json.loads(await ws.recv())
                if trame.get("event") == "postgres_changes":
                    evenements.append((time.monotonic() - t0, trame.get("payload", {})))

        tache = asyncio.create_task(guetter())
        try:
            await asyncio.sleep(20)
        finally:
            tache.cancel()
            await asyncio.gather(tache, return_exceptions=True)

    if evenements:
        delai, charge = evenements[0]
        donnees = charge.get("data", {})
        print(f"OK: diffusion reçue en {delai:.2f} s -> type={donnees.get('type')} "
              f"table={donnees.get('table')}")
        return 0
    print("ECHEC: aucune diffusion reçue en 20 s avec le compte boutique.")
    return 1


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
