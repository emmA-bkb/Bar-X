#!/usr/bin/env bash
# Locks the screen ("Lock" button of the Profile widget).
#   - Already locked: does nothing
#   - ~/.config/hypr/hyprlock.conf exists: uses hyprlock with your config
#   - Otherwise: uses hyprlock with the Uix theme (config/hyprlock.conf) in the Uix accent color
#   - hyprlock not installed: tries the system's default lock
dir="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"

pidof hyprlock >/dev/null && exit 0

if ! command -v hyprlock >/dev/null; then
    exec loginctl lock-session
fi

if [[ -f "$HOME/.config/hypr/hyprlock.conf" ]]; then
    exec hyprlock
fi

# Uix accent color (#rrggbb -> "r, g, b")
accent="$(python3 -I -c '
import json, sys
try:
    c = json.load(open(sys.argv[1])).get("accent", "#7fd1c4")
except Exception:
    c = "#7fd1c4"
c = c.lstrip("#")[-6:]
print(", ".join(str(int(c[i:i + 2], 16)) for i in (0, 2, 4)))
' "$HOME/.config/uix/config.json")"

conf="$HOME/.cache/uix/hyprlock.conf"
mkdir -p "$(dirname "$conf")"
sed "s/ACCENT_RGB/${accent:-127, 209, 196}/g" "$dir/config/hyprlock.conf" >"$conf"

exec hyprlock -c "$conf"
