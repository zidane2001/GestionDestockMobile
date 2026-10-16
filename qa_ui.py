#!/usr/bin/env python3
"""Pilote UI pour la campagne QA (emulateur Android headless/windowed).

Usage:
  python qa_ui.py dump                 -> liste les elements (texte, centre, clickable)
  python qa_ui.py tap "Créer ma boutique"  -> tape au centre de l'element
  python qa_ui.py text "Boutique QA"   -> tape du texte dans le champ focus
  python qa_ui.py sc read <fichier>    -> verifie un texte present a l'ecran
"""
import re
import subprocess
import sys
import time

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

ADB = ["adb", "shell"]


def run(*args, binary=False):
    return subprocess.run(list(args), capture_output=True, text=binary)


def dump(tries=5, pause=2.5):
    """Dump de l'arbre d'accessibilite.

    Flutter n'expose la semantique qu'a la demande : juste apres l'ouverture
    d'une feuille modale, le premier dump peut revenir vide. On retente.
    """
    txt = ""
    for _ in range(tries):
        subprocess.run(ADB + ["uiautomator", "dump", "/sdcard/qa.xml"], capture_output=True)
        xml = subprocess.run(["adb", "exec-out", "cat", "/sdcard/qa.xml"], capture_output=True).stdout
        txt = xml.decode("utf-8", errors="replace")
        if len(txt) > 2500:
            return txt
        time.sleep(pause)
    return txt


def nodes(xml):
    out = []
    for m in re.finditer(r"<node[^>]*>", xml):
        n = m.group(0)
        desc = re.search(r'content-desc="([^"]*)"', n)
        text = re.search(r'text="([^"]*)"', n)
        bounds = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', n)
        cls = re.search(r'class="([^"]*)"', n)
        clickable = 'clickable="true"' in n
        if not bounds:
            continue
        x1, y1, x2, y2 = map(int, bounds.groups())
        label = (desc.group(1) if desc else "") or (text.group(1) if text else "")
        out.append({
            "label": label.replace("&#10;", " ").replace("&amp;", "&"),
            "cls": (cls.group(1) if cls else "").split(".")[-1],
            "x": (x1 + x2) // 2,
            "y": (y1 + y2) // 2,
            "clickable": clickable,
        })
    return out


def fields(xml=None):
    """Champs de saisie, dans l'ordre de l'ecran (haut -> bas)."""
    items = [n for n in nodes(xml or dump()) if n["cls"] == "EditText"]
    items.sort(key=lambda n: n["y"])
    return items


def show():
    all_nodes = nodes(dump())
    items = [n for n in all_nodes if n["label"]]
    items.sort(key=lambda n: n["y"])
    for n in items:
        flag = "CLICK" if n["clickable"] else "     "
        print(f"{flag} y={n['y']:>5} x={n['x']:>5} {n['cls']:<12} {n['label'][:70]}")
    champs = fields_dump(all_nodes)
    if champs:
        print("--- champs de saisie (tap @n) ---")
        for i, n in enumerate(champs):
            print(f"      @{i} y={n['y']:>5} x={n['x']:>5} editText")


def fields_dump(all_nodes):
    items = [n for n in all_nodes if n["cls"] == "EditText"]
    items.sort(key=lambda n: n["y"])
    return items


def values():
    """Contenu actuel de chaque champ de saisie."""
    for i, n in enumerate(fields()):
        print(f"@{i} y={n['y']:<5} {n['label']!r}")


def find(query):
    q = query.lower()
    if query.startswith("@"):
        try:
            return fields()[int(query[1:])]
        except (ValueError, IndexError):
            return None
    items = [n for n in nodes(dump()) if n["label"]]
    exact = [n for n in items if n["label"].lower() == q]
    partial = [n for n in items if q in n["label"].lower()]
    for candidate in (exact, partial):
        clickables = [n for n in candidate if n["clickable"]]
        if clickables:
            return clickables[0]
        if candidate:
            return candidate[0]
    return None


def tap(query):
    n = find(query)
    if not n:
        print(f"INTROUVABLE: {query}")
        return 1
    subprocess.run(ADB + ["input", "tap", str(n["x"]), str(n["y"])])
    print(f"tap {n['label'][:50]!r} @ ({n['x']},{n['y']})")
    return 0


def type_text(text, chunk=3, pause=1.6):
    """Tape du texte par petits blocs : l'emulateur perd des caracteres si
    l'injection est trop rapide."""
    for i in range(0, len(text), chunk):
        part = text[i:i + chunk]
        escaped = part.replace(" ", "%s").replace("&", r"\&").replace("'", r"\'")
        subprocess.run(ADB + ["input", "text", escaped])
        time.sleep(pause)
    print(f"text {text!r} ({len(text)} caracteres, blocs de {chunk})")
    return 0


def clear_field(times=40):
    """Vide le champ focus : curseur en fin de ligne puis effacements."""
    subprocess.run(ADB + ["input", "keyevent", "123"])
    time.sleep(0.5)
    for _ in range(times):
        subprocess.run(ADB + ["input", "keyevent", "67"])
        time.sleep(0.08)
    print("champ vide")
    return 0


def has_text(text, xml=None):
    xml = xml or dump()
    present = text.lower() in xml.lower()
    print(f"{'OUI' if present else 'NON '} :: {text}")
    return 0 if present else 1


def scroll(direction="down", times=1):
    """Fait defiler l'ecran (down = vers le bas du contenu)."""
    for _ in range(times):
        if direction == "down":
            subprocess.run(ADB + ["input", "swipe", "540", "1900", "540", "700", "400"])
        else:
            subprocess.run(ADB + ["input", "swipe", "540", "700", "540", "1900", "400"])
        time.sleep(1.2)
    print(f"scroll {direction} x{times}")
    return 0


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "dump"
    if cmd == "dump":
        show()
    elif cmd == "tap":
        return tap(" ".join(sys.argv[2:]))
    elif cmd == "text":
        return type_text(" ".join(sys.argv[2:]))
    elif cmd == "clear":
        return clear_field()
    elif cmd == "values":
        values()
    elif cmd == "has":
        return has_text(" ".join(sys.argv[2:]))
    elif cmd == "scroll":
        return scroll(sys.argv[2] if len(sys.argv) > 2 else "down",
                      int(sys.argv[3]) if len(sys.argv) > 3 else 1)
    elif cmd == "key":
        subprocess.run(ADB + ["input", "keyevent", sys.argv[2]])
        return 0
    elif cmd == "sleep":
        time.sleep(float(sys.argv[2]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
