#!/usr/bin/env python3
"""Monitor settings saved by Uix (~/.config/uix/config.json -> "monitors", "primaryMonitor").

Usage:
  monitors.py apply        Applies the saved monitor positions (keeping each monitor's current
                           mode, scale and rotation), keeps workspaces 1-10 on the primary
                           monitor and focuses it.
  monitors.py wallpapers   Prints one "<monitor>=<kind>:<path>" per connected monitor, for
                           apply-wallpaper.sh. A monitor without its own wallpaper uses the
                           primary one (the active preset's wallpaper).

Positions are applied at runtime with `hyprctl eval 'hl.monitor({...})'`, so hyprland.lua is
never edited; Uix applies them again on every login (scripts/uix-start.sh).
"""
import json
import os
import subprocess
import sys

CONFIG = os.path.expanduser("~/.config/uix/config.json")
VIDEO = (".mp4", ".webm", ".mkv", ".mov")


def load_config():
    try:
        with open(CONFIG) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def hypr_monitors():
    out = subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True).stdout
    try:
        return json.loads(out)
    except ValueError:
        return []


def primary_name(cfg, monitors):
    names = [m["name"] for m in monitors]
    p = cfg.get("primaryMonitor", "")
    return p if p in names else (names[0] if names else "")


def lua_str(s):
    return json.dumps(s, ensure_ascii=False)


def apply_layout():
    cfg = load_config()
    saved = cfg.get("monitors", {})
    monitors = hypr_monitors()
    for m in monitors:
        s = saved.get(m["name"], {})
        if "x" not in s and "mode" not in s:
            continue
        # Saved resolution (chosen in Uix), or the one in use now
        mode = s.get("mode") or "%dx%d@%.2f" % (m["width"], m["height"], m["refreshRate"])
        x, y = int(s.get("x", m["x"])), int(s.get("y", m["y"]))
        lua = "hl.monitor({ output = %s, mode = %s, position = %s, scale = %s, transform = %d })" % (
            lua_str(m["name"]), lua_str(mode), lua_str("%dx%d" % (x, y)),
            lua_str(str(m["scale"])), m["transform"])
        subprocess.run(["hyprctl", "eval", lua], capture_output=True)

    primary = primary_name(cfg, monitors)
    if primary:
        # Workspaces 1-10 (Super+1..0) always live on the primary monitor; every other monitor
        # gets its own workspace (11, 12...), which only receives windows that are dragged there.
        for i in range(1, 11):
            subprocess.run(["hyprctl", "eval", "hl.workspace_rule({ workspace = %s, monitor = %s, default = %s })" % (
                lua_str(str(i)), lua_str(primary), "true" if i == 1 else "false")], capture_output=True)
        others = [m["name"] for m in monitors if m["name"] != primary]
        for n, name in enumerate(others):
            subprocess.run(["hyprctl", "eval", "hl.workspace_rule({ workspace = %s, monitor = %s, default = true })" % (
                lua_str(str(11 + n)), lua_str(name))], capture_output=True)
        subprocess.run(["hyprctl", "dispatch", "hl.dsp.focus({ monitor = %s })" % lua_str(primary)], capture_output=True)


def kind_of(path):
    if os.path.isfile(os.path.join(path, "project.json")):
        return "we"
    return "video" if path.lower().endswith(VIDEO) else "image"


def wallpapers():
    cfg = load_config()
    preset = next((p for p in cfg.get("presets", []) if p.get("id") == cfg.get("activePreset")), None)
    base = (preset or {}).get("wallpaper") or cfg.get("wallpaper", "")
    saved = cfg.get("monitors", {})
    for m in hypr_monitors():
        path = saved.get(m["name"], {}).get("wallpaper") or base
        if path and os.path.exists(path):
            print("%s=%s:%s" % (m["name"], kind_of(path), path))


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "apply":
        apply_layout()
    elif cmd == "wallpapers":
        wallpapers()
    else:
        print(__doc__)
        sys.exit(1)
