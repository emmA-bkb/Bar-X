#!/usr/bin/env python3
"""Pauses the wallpaper of monitors where it can't be seen, so it stops using the GPU
(e.g. while playing a game), and resumes it when it shows again.

Usage: wallpaper-pause.py <never|fullscreen|windows>
  never      -> every wallpaper runs (resumes the paused ones)
  fullscreen -> pause on monitors showing a fullscreen or maximized window
  windows    -> pause on monitors showing any tiled window

Pausing is SIGSTOP on that monitor's linux-wallpaperengine / mpvpaper process (Hyprland keeps
showing its last frame) and SIGCONT to resume. It is stateless: run it again whenever windows or
workspaces change (services/WallpaperPause.qml does that).
"""
import json
import os
import signal
import subprocess
import sys


def hyprctl(what):
    try:
        out = subprocess.run(["hyprctl", what, "-j"], capture_output=True, text=True, timeout=3).stdout
        return json.loads(out)
    except (OSError, ValueError, subprocess.TimeoutExpired):
        return None


def covered_monitors(mode):
    if mode not in ("fullscreen", "windows"):
        return set()
    monitors, clients = hyprctl("monitors"), hyprctl("clients")
    if monitors is None or clients is None:
        return None  # Hyprland not answering: leave everything as it is
    covered = set()
    for m in monitors:
        shown = {m["activeWorkspace"]["id"], m["specialWorkspace"]["id"]} - {0}
        for c in clients:
            if c["workspace"]["id"] not in shown or not c.get("mapped", True) or c.get("hidden"):
                continue
            if c.get("fullscreen") or (mode == "windows" and not c.get("floating")):
                covered.add(m["name"])
                break
    return covered


def wallpaper_processes():
    """[(pid, [monitors], stopped)] for the engine and mpvpaper processes of this user."""
    found = []
    uid = os.getuid()
    for pid in filter(str.isdigit, os.listdir("/proc")):
        try:
            if os.stat("/proc/" + pid).st_uid != uid:
                continue
            with open("/proc/%s/cmdline" % pid, "rb") as f:
                argv = f.read().decode(errors="replace").split("\0")[:-1]
            with open("/proc/%s/stat" % pid) as f:
                state = f.read().rsplit(")", 1)[1].split()[0]
        except OSError:
            continue
        if not argv:
            continue
        name = os.path.basename(argv[0])
        if name == "linux-wallpaperengine" and "--screen-root" in argv:
            screens = [argv[i + 1] for i, a in enumerate(argv[:-1]) if a == "--screen-root"]
        elif name == "mpvpaper" and len(argv) >= 3:
            screens = [argv[-2]]  # mpvpaper [options] <monitor> <path>
        else:
            continue
        found.append((int(pid), screens, state == "T"))
    return found


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "fullscreen"
    covered = covered_monitors(mode)
    if covered is None:
        return
    for pid, screens, stopped in wallpaper_processes():
        pause = all(s in covered for s in screens)
        if pause != stopped:
            try:
                os.kill(pid, signal.SIGSTOP if pause else signal.SIGCONT)
            except OSError:
                pass


if __name__ == "__main__":
    main()
