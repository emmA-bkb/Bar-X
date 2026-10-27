#!/usr/bin/env python3
"""Lists the installed Wallpaper Engine wallpapers (Steam Workshop + presets).

Output, one line per item, separated by TAB:
    assets  <wallpaper_engine assets folder>
    we      <folder> <preview> <title> <type> <compatibility>

The compatibility (perfect/minor/broken) comes from the linux-wallpaper-engine-ux tests
and the Uix "Test" button (scripts/scan-compat.py), when they exist.
"""
import json
import os
import re

APP_ID = "431960"
HOME = os.path.expanduser("~")


def steam_roots():
    candidates = [
        "~/.local/share/Steam",
        "~/.steam/steam",
        "~/.var/app/com.valvesoftware.Steam/.local/share/Steam",
    ]
    roots = []
    for c in candidates:
        p = os.path.realpath(os.path.expanduser(c))
        if os.path.isdir(p) and p not in roots:
            roots.append(p)
    return roots


def library_dirs():
    libs = []
    for root in steam_roots():
        for p in [root] + read_library_paths(root):
            p = os.path.realpath(p)
            if os.path.isdir(p) and p not in libs:
                libs.append(p)
    return libs


def read_library_paths(root):
    vdf = os.path.join(root, "steamapps", "libraryfolders.vdf")
    try:
        with open(vdf, encoding="utf-8", errors="replace") as f:
            return re.findall(r'"path"\s+"([^"]+)"', f.read())
    except OSError:
        return []


def load_overrides():
    """Compatibility: linux-wallpaper-engine-ux tests, overridden by the Uix ones (newer)."""
    result = {}
    path = os.path.join(HOME, ".config", "Linux Wallpaper Engine", "wallpaper-overrides.json")
    try:
        with open(path, encoding="utf-8") as f:
            result.update(json.load(f).get("overrides", {}))
    except (OSError, ValueError):
        pass
    try:
        with open(os.path.join(HOME, ".config", "uix", "compat.json"), encoding="utf-8") as f:
            for k, v in json.load(f).items():
                result[k] = {**result.get(k, {}), **v}
    except (OSError, ValueError):
        pass
    return result


def clean(text):
    return re.sub(r"[\t\r\n]+", " ", str(text or "")).strip()


def main():
    overrides = load_overrides()
    libs = library_dirs()

    for lib in libs:
        assets = os.path.join(lib, "steamapps", "common", "wallpaper_engine", "assets")
        if os.path.isdir(assets):
            print(f"assets\t{assets}")
            break

    seen = set()
    for lib in libs:
        sources = [
            os.path.join(lib, "steamapps", "workshop", "content", APP_ID),
            os.path.join(lib, "steamapps", "common", "wallpaper_engine", "projects", "myprojects"),
        ]
        for base in sources:
            if not os.path.isdir(base):
                continue
            for name in sorted(os.listdir(base)):
                folder = os.path.join(base, name)
                project_file = os.path.join(folder, "project.json")
                if folder in seen or not os.path.isfile(project_file):
                    continue
                try:
                    with open(project_file, encoding="utf-8-sig") as f:
                        project = json.load(f)
                except (OSError, ValueError):
                    continue
                seen.add(folder)

                preview = project.get("preview") or ""
                preview_path = os.path.join(folder, preview) if preview else ""
                if preview_path and not os.path.isfile(preview_path):
                    preview_path = ""

                kind = (project.get("type") or "scene").lower()
                compat = overrides.get(folder, {}).get("compatibility", "")
                title = clean(project.get("title")) or name

                print("\t".join(["we", folder, preview_path, title, kind, compat]))


if __name__ == "__main__":
    main()
