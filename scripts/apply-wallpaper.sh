#!/usr/bin/env bash
# Puts wallpapers on screen, one per monitor.
# Usage: apply-wallpaper.sh <assets-dir|-> <monitor>=<kind>:<path> [<monitor>=<kind>:<path>...]
#   kind we          -> linux-wallpaperengine, one process per monitor, with the wallpaper's settings
#                       from Uix (sound, FPS, scaling, properties: scripts/wallpaper-settings.py)
#   kind video/image -> mpvpaper (one process per monitor)
# One process per monitor lets each monitor have its own settings and be paused on its own
# (scripts/wallpaper-pause.py).
# Example: apply-wallpaper.sh /…/assets DP-1=we:/…/431960/123 HDMI-A-1=image:/…/wallpaper.png
dir="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
assets="$1"
shift

# Stop whatever is running now (on every monitor: they are all redrawn below).
# A paused (SIGSTOP) process only handles SIGTERM after a SIGCONT, so continue them first.
pkill -CONT -f "linux-wallpaperengine.*--screen-root"
pkill -9 -f "linux-wallpaperengine.*--screen-root"
pkill -CONT -x mpvpaper
pkill -x mpvpaper
sleep 0.2

declare -A playing # wallpapers already started on another monitor (only the first one plays sound)
for pair in "$@"; do
    monitor="${pair%%=*}"
    rest="${pair#*=}"
    kind="${rest%%:*}"
    path="${rest#*:}"
    [[ -z "$monitor" || -z "$path" ]] && continue

    case "$kind" in
        we)
            mapfile -t opts < <(python3 -I "$dir/wallpaper-settings.py" args "$path" ${playing[$path]:+silent})
            playing[$path]=1
            # "background" layer: always below the Uix widgets (which use "bottom").
            # Without it the engine uses "bottom" and covers the widgets when the wallpaper changes.
            args=(--layer background --screen-root "$monitor" --bg "$path" --scaling "${opts[0]:-fill}" "${opts[@]:1}")
            [[ "$assets" != "-" && -d "$assets" ]] && args+=(--assets-dir "$assets")
            setsid -f linux-wallpaperengine "${args[@]}" >/dev/null 2>&1
            ;;
        video | image)
            setsid -f mpvpaper -l background -o "no-audio loop-file=inf image-display-duration=inf" "$monitor" "$path" >/dev/null 2>&1
            ;;
    esac
done
