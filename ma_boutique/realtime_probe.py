"""Sonde de vérification du temps réel Supabase.

1. lit une ligne de `produits`,
2. s'abonne à postgres_changes sur `produits`,
3. réécrit la même valeur (aucun changement de données) pour déclencher un UPDATE,
4. mesure si l'événement revient et en combien de temps.
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
WS = f"wss://{PROJET}.supabase.co/realtime/v1/websocket?apikey={ANON}&vsn=1.0.0"


def rest(methode, chemin, corps=None):
    data = json.dumps(corps).encode() if corps is not None else None
    requete = urllib.request.Request(
        f"{REST}/{chemin}",
        data=data,
        method=methode,
        headers={
            "apikey": SERVICE,
            "Authorization": f"Bearer {SERVICE}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        },
    )
    with urllib.request.urlopen(requete, timeout=20) as reponse:
        return json.loads(reponse.read().decode() or "[]")


async def main():
    lignes = rest("GET", "produits?select=id,nom,quantite,boutique_id&limit=1")
    if not lignes:
        print("ECHEC: aucun produit sur le serveur, test impossible")
        return 2
    cible = lignes[0]
    print(f"ligne cible: {cible['id']} / {cible['nom']!r} / qté {cible['quantite']}")

    evenements = []
    ctx = ssl.create_default_context()

    async with websockets.connect(WS, ssl=ctx, max_size=10**7) as ws:
        join = {
            "topic": "realtime:sonde-produits",
            "event": "phx_join",
            "payload": {
                "config": {
                    "broadcast": {"self": False},
                    "presence": {"key": ""},
                    "postgres_changes": [
                        {"event": "*", "schema": "public", "table": "produits"}
                    ],
                    "private": False,
                },
                "access_token": SERVICE,
            },
            "ref": "1",
        }
        await ws.send(json.dumps(join))
        reponse = json.loads(await asyncio.wait_for(ws.recv(), timeout=15))
        print("phx_join ->", reponse.get("event"), json.dumps(reponse.get("payload"))[:300])

        t0 = time.monotonic()
        touchees = rest("PATCH", f"produits?id=eq.{cible['id']}", {"nom": cible["nom"]})
        print(f"PATCH -> {len(touchees)} ligne(s) modifiée(s), attente de la diffusion…")

        async def guetter():
            while True:
                brut = await ws.recv()
                trame = json.loads(brut)
                if trame.get("event") == "postgres_changes":
                    evenements.append((time.monotonic() - t0, trame))

        async def battement():
            while True:
                await asyncio.sleep(15)
                await ws.send(json.dumps({"topic": "realtime:sonde-produits",
                                          "event": "heartbeat",
                                          "payload": {},
                                          "ref": "hb"}))

        taches = [asyncio.create_task(guetter()), asyncio.create_task(battement())]
        try:
            await asyncio.sleep(20)
        finally:
            for t in taches:
                t.cancel()
            await asyncio.gather(*taches, return_exceptions=True)

    if evenements:
        delai, trame = evenements[0]
        charge = trame.get("payload", {}).get("data", {})
        print(f"OK: événement reçu en {delai:.2f} s -> {json.dumps(charge)[:200]}")
        return 0
    print("ECHEC: aucune diffusion reçue en 20 s (publication supabase_realtime ?)")
    return 1


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
