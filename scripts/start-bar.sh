#!/usr/bin/env bash
# Para usar no login (no lugar de "waybar"): abre a barra e os widgets escolhidos no Uix.
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
