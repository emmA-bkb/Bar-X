#!/usr/bin/env bash
# Puts wallpapers on screen, one per monitor.
# Usage: apply-wallpaper.sh <assets-dir|-> <monitor>=<kind>:<path> [<monitor>=<kind>:<path>...]
#   kind we          -> linux-wallpaperengine (a single process with one --bg per monitor)
#   kind video/image -> mpvpaper (one process per monitor)
# Example: apply-wallpaper.sh /…/assets DP-1=we:/…/431960/123 HDMI-A-1=image:/…/wallpaper.png
assets="$1"
shift

# Stop whatever is running now (on every monitor: they are all redrawn below)
pkill -9 -f "linux-wallpaperengine.*--screen-root"
pkill -x mpvpaper
sleep 0.2

engine_args=()
for pair in "$@"; do
    monitor="${pair%%=*}"
    rest="${pair#*=}"
    kind="${rest%%:*}"
    path="${rest#*:}"
    [[ -z "$monitor" || -z "$path" ]] && continue

    case "$kind" in
        we)
            # "background" layer: always below the Uix widgets (which use "bottom").
            # Without it the engine uses "bottom" and covers the widgets when the wallpaper changes.
            engine_args+=(--screen-root "$monitor" --bg "$path" --scaling fill)
            ;;
        video | image)
            setsid -f mpvpaper -l background -o "no-audio loop-file=inf image-display-duration=inf" "$monitor" "$path" >/dev/null 2>&1
            ;;
    esac
done

if ((${#engine_args[@]} > 0)); then
    args=(--layer background "${engine_args[@]}")
    [[ "$assets" != "-" && -d "$assets" ]] && args+=(--assets-dir "$assets")
    setsid -f linux-wallpaperengine "${args[@]}" >/dev/null 2>&1
fi
