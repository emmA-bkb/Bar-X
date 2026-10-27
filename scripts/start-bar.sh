#!/usr/bin/env bash
# For use on login (instead of "waybar"): opens the bar and widgets chosen in Uix.
dir="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
config="$HOME/.config/uix/config.json"

read -r provider widgets < <(python3 -I -c '
import json, sys
try:
    c = json.load(open(sys.argv[1]))
except Exception:
    c = {}
print(c.get("barProvider", "waybar"), 1 if c.get("widgetsEnabled") else 0)
' "$config")

exec "$dir/scripts/desktop.sh" "${provider:-waybar}" "${widgets:-0}"
