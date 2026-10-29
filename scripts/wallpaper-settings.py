#!/usr/bin/env python3
"""linux-wallpaperengine arguments for one wallpaper, from its settings in Uix
(~/.config/uix/config.json -> "wallpaperSettings", "wallpaperFps").

Usage: wallpaper-settings.py args <path> [silent]
Output: one argument per line. The first line is the scaling mode for the monitor
(it goes right after that monitor's --bg); the rest are options for the whole process.
"silent" mutes it no matter the settings (the same wallpaper already plays on another monitor).
"""
import json
import os
import sys

CONFIG = os.path.join(os.path.expanduser("~"), ".config", "uix", "config.json")
SCALING = ("fill", "fit", "stretch", "default")


def load():
    try:
        with open(CONFIG, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def prop_value(value):
    if isinstance(value, bool):
        return "1" if value else "0"
    # Colors are "r g b" with 0..1 floats; the engine reads whole numbers as 0..255,
    # so every component keeps its decimal point
    if isinstance(value, list):
        return " ".join("%.4f" % float(c) for c in value)
    return str(value)


def engine_args(cfg, path, silent=False):
    s = (cfg.get("wallpaperSettings") or {}).get(path) or {}
    scaling = s.get("scaling") if s.get("scaling") in SCALING else "fill"
    out = [scaling]

    fps = int(s.get("fps") or cfg.get("wallpaperFps") or 30)
    out += ["--fps", str(max(1, fps))]

    # --volume and --silent can't be used together
    if silent or s.get("sound") is False:
        out.append("--silent")
    else:
        out += ["--volume", str(int(s.get("volume", 15)))]
        if s.get("autoMute") is False:
            out.append("--noautomute")

    if s.get("particles") is False:
        out.append("--disable-particles")
    if s.get("mouse") is False:
        out.append("--disable-mouse")
    if s.get("parallax") is False:
        out.append("--disable-parallax")

    for name, value in (s.get("properties") or {}).items():
        out += ["--set-property", "%s=%s" % (name, prop_value(value))]
    return out


def main():
    if len(sys.argv) < 3 or sys.argv[1] != "args":
        print(__doc__, file=sys.stderr)
        sys.exit(1)
    silent = len(sys.argv) > 3 and sys.argv[3] == "silent"
    print("\n".join(engine_args(load(), sys.argv[2], silent)))


if __name__ == "__main__":
    main()
