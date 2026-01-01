#!/usr/bin/env python3

import shutil
import sys
import os
import json
import subprocess
import time
from pathlib import Path
from configparser import ConfigParser

try:
    from rapidfuzz import fuzz
except ImportError:
    fuzz = None

CACHE_DIR = Path.home() / ".cache/rofi-launcher"
APPS_CACHE = CACHE_DIR / "apps.json"

DESKTOP_DIRS = [
    Path("/usr/share/applications"),
    Path.home() / ".local/share/applications",
    Path("/var/lib/snapd/desktop/applications"),
    Path("/var/lib/flatpak/exports/share/applications"),
    Path.home() / ".local/share/flatpak/exports/share/applications",
]

CACHE_TTL = 3600  # seconds

def index_apps():
    apps = []

    for base in DESKTOP_DIRS:
        if not base.exists():
            continue

        for path in base.glob("*.desktop"):
            cp = ConfigParser(interpolation=None)
            try:
                cp.read(path)
                entry = cp["Desktop Entry"]
            except Exception:
                continue

            if entry.get("Type") != "Application":
                continue
            if entry.get("NoDisplay", "false").lower() == "true":
                continue
            if entry.get("Hidden", "false").lower() == "true":
                continue

            name = entry.get("Name")
            exec_cmd = entry.get("Exec")

            if not name or not exec_cmd:
                continue

            apps.append({
                "name": name,
                "desktop_id": path.stem,
            })

    return apps

def load_apps():
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    if APPS_CACHE.exists():
        age = time.time() - APPS_CACHE.stat().st_mtime
        if age < CACHE_TTL:
            return json.loads(APPS_CACHE.read_text())

    apps = index_apps()
    APPS_CACHE.write_text(json.dumps(apps))
    return apps

def build_candidates():
    items = []

    # commands
    items += [
        ",tt          toggle todo",
        ",t",
        ",tr          remove todo",
        ",p",
        ",n",
        ",til",
        ",why",
        ",hmm",
        ",w <q>    search the web gh, yt, lb, wiki"
    ]

    items.append("---")

    # apps
    for app in load_apps():
        items.append(app["name"])

    return items

def score(query, candidate):
    query = query.lower()
    candidate_lower = candidate.lower()

    if query == candidate_lower:
        return 100
    elif all(word in candidate_lower for word in query.split()):
        return 90
    elif candidate_lower.startswith(query):
        return 80
    elif fuzz:
        return fuzz.partial_ratio(query, candidate)
    else:
        return 0

def filter_and_rank(query, items):
    scored = [(score(query, i), i) for i in items]
    return [i for s, i in sorted(scored, reverse=True) if s > 0]

def output_menu():
    items = build_candidates()
    for item in items:
        print(item)

def dispatch(raw):
    if not raw:
        return

    raw = raw.strip()

    # COMMAND MODE
    if raw.startswith(","):
        query = raw[1:]

        # split first space
        if " " in query:
            cmd, rest = query.split(" ", 1)
        else:
            cmd, rest = query, ""

        # split comma subcommands
        parts = cmd.split(",")
        base = parts[0]
        sub = parts[1] if len(parts) > 1 else None

        handle_command(base, sub, rest)
        return

    # APP MODE
    if not raw.startswith(","):
        apps_cache = load_apps()
        APP_MAP = {a["name"]: a["desktop_id"] for a in apps_cache}
        desktop_id = APP_MAP.get(raw)
        if desktop_id:
            subprocess.run(["gtk-launch", desktop_id])
        else:
            # fallback: try to exec as command
            if shutil.which(raw):
                subprocess.Popen([raw])
            else:
                subprocess.run(["notify-send", "Cannot launch app", raw])
        return

def handle_command(base, sub, rest):
    home = Path.home()

    if base in ["t", "tt", "tr", "ta"]:
        if rest:
            subprocess.run([home / "scripts/scripts/rofi/rofi-todo-add.sh", base, rest])
        else:
            subprocess.run([home / "scripts/scripts/rofi/rofi-todo-add.sh", base])

    elif base == "p":
        if not rest:
            subprocess.run([home / "scripts/scripts/rofi/rofi-projects.sh"])
        else:
            for d in ["github", "github/work", "github/side-hustle"]:
                path = home / d / rest
                if path.exists():
                    subprocess.run(["code", str(path)])
                    return
            subprocess.run([home / "scripts/scripts/rofi/rofi-projects.sh"])

    elif base in ["n", "til", "why", "hmm"]:
        if rest:
            subprocess.run([home / "scripts/scripts/rofi/rofi-obsidian.sh", base, rest])
        else:
            subprocess.run([home / "scripts/scripts/rofi/rofi-obsidian.sh", base])



    elif base == "w":
        q = rest.replace(" ", "+")
        if sub == "gh":
            url = f"https://github.com/search?q={q}"
        elif sub == "yt":
            url = f"https://youtube.com/results?search_query={q}"
        elif sub == "lb":
            url = f"https://libgen.li/index.php?req={q}"
        elif sub == "wiki":
            url = f"https://en.wikipedia.org/w/index.php?search={q}"
        else:
            url = f"https://google.com/search?q={q}"

        subprocess.run(["firefox-dev", url])

    else:
        subprocess.run(["notify-send", "Unknown command", f",{base}"])



def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--dispatch":
        dispatch(sys.stdin.read().strip())
    else:
        output_menu()

if __name__ == "__main__":
    main()
