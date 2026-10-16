"""Compare les configurations d'abonnement Realtime de Supabase.

La publication SQL est confirmée ; on teste donc, un par un, les paramètres
d'abonnement pour savoir lequel diffuse réellement les changements — et donc
si le code Dart doit utiliser des canaux privés ou publics.
"""

import asyncio
import json
import ssl
import time
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
REST = f"https://{PROJET}.supabase.co/rest/v1"


def rest(methode, chemin, corps=None, cle=SERVICE):
    data = json.dumps(corps).encode() if corps is not None else None
    requete = urllib.request.Request(
        f"{REST}/{chemin}",
        data=data,
        method=methode,
        headers={
            "apikey": cle,
            "Authorization": f"Bearer {cle}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        },
    )
    with urllib.request.urlopen(requete, timeout=20) as reponse:
        return json.loads(reponse.read().decode() or "[]")


async def tester(cible, prive, cle_apikey, cle_acces, delai=15):
    """Retourne le délai de diffusion, ou None si rien n'est reçu."""
    topic = f"realtime:essai-{int(time.time() * 1000) % 100000}"
    url = (
        f"wss://{PROJET}.supabase.co/realtime/v1/websocket"
        f"?apikey={cle_apikey}&vsn=1.0.0"
    )
    evenements = []
    ctx = ssl.create_default_context()

    try:
        async with websockets.connect(url, ssl=ctx, max_size=10**7) as ws:
            await ws.send(json.dumps({
                "topic": topic,
                "event": "phx_join",
                "payload": {
                    "config": {
                        "broadcast": {"self": False},
                        "presence": {"key": ""},
                        "postgres_changes": [
                            {"event": "*", "schema": "public", "table": "produits"}
                        ],
                        "private": prive,
                    },
                    "access_token": cle_acces,
                },
                "ref": "1",
            }))
            reponse = json.loads(await asyncio.wait_for(ws.recv(), timeout=15))
            statut = reponse.get("payload", {}).get("status")
            if statut != "ok":
                return ("refuse", None, json.dumps(reponse.get("payload"))[:160])

            t0 = time.monotonic()
            rest("PATCH", f"produits?id=eq.{cible['id']}", {"nom": cible["nom"]})

            async def guetter():
                while True:
                    trame = json.loads(await ws.recv())
                    if trame.get("event") == "postgres_changes":
                        evenements.append(time.monotonic() - t0)

            tache = asyncio.create_task(guetter())
            try:
                await asyncio.sleep(delai)
            finally:
                tache.cancel()
                await asyncio.gather(tache, return_exceptions=True)
    except Exception as erreur:  # noqa: BLE001
        return ("erreur", None, type(erreur).__name__)

    if evenements:
        return ("ok", evenements[0], "")
    return ("aucun", None, "")


async def main():
    lignes = rest("GET", "produits?select=id,nom&limit=1")
    if not lignes:
        print("Aucun produit sur le serveur.")
        return 2
    cible = lignes[0]
    print(f"cible : {cible['id']} / {cible['nom']!r}\n")

    essais = [
        ("prive + service_role", True, ANON, SERVICE),
        ("public + service_role", False, ANON, SERVICE),
        ("prive + anon", True, ANON, ANON),
    ]
    gagnant = None
    for nom, prive, apikey, acces in essais:
        statut, delai, detail = await tester(cible, prive, apikey, acces)
        if statut == "ok":
            print(f"  {nom:<24} -> DIFFUSE en {delai:.2f} s")
            gagnant = nom
        else:
            print(f"  {nom:<24} -> {statut} {detail}")
        await asyncio.sleep(2)

    print()
    if gagnant:
        print(f"CONFIGURATION GAGNANTE : {gagnant}")
        return 0
    print("AUCUNE configuration ne diffuse.")
    return 1


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
