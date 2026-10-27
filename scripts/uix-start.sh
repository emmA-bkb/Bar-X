#!/usr/bin/env bash
# Starts Uix on login: bar + widgets, saved monitor layout and the wallpaper of each monitor.
# No hyprland.lua, no lugar da waybar e do linux-wallpaper-engine-ux:
#   hl.exec_cmd("/caminho/para/o/projeto/scripts/uix-start.sh")
#
# Teste sem mudar nada:  DRY=1 scripts/uix-start.sh   (so mostra o que faria)
dir="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
mkdir -p "$HOME/.config/uix"

run() {
    if [[ -n "$DRY" ]]; then
        echo "+ $*"
    else
        "$@"
    fi
}

# Le a config do Uix: barra, widgets e o wallpaper a aplicar
mapfile -t cfg < <(python3 -I - "$HOME/.config/uix/config.json" <<'EOF'
import json, sys
try:
    c = json.load(open(sys.argv[1]))
except Exception:
    c = {}
preset = next((p for p in c.get("presets", []) if p.get("id") == c.get("activePreset")), None)
wallpaper = (preset or {}).get("wallpaper") or c.get("wallpaper", "")
print(c.get("barProvider", "waybar"))
print(1 if c.get("widgetsEnabled") else 0)
print(1 if c.get("applyOnLogin", True) else 0)
print(wallpaper)
EOF
)
provider="${cfg[0]:-waybar}"
widgets="${cfg[1]:-0}"
apply_on_login="${cfg[2]:-1}"
wallpaper="${cfg[3]}"

# 1) Bar (Uix or Waybar) and widgets
run "$dir/scripts/desktop.sh" "$provider" "$widgets"

# 2) Saved monitor positions + focus on the primary monitor
run python3 -I "$dir/scripts/monitors.py" apply

# 3) Wallpapers: each monitor gets its own, or the active preset's one
if [[ "$apply_on_login" == "1" ]]; then
    # Wallpaper Engine assets folder (the same one Uix uses)
    assets="$(python3 -I "$dir/scripts/scan-wallpaper-engine.py" | awk -F'	' '$1 == "assets" { print $2; exit }')"
    mapfile -t pairs < <(python3 -I "$dir/scripts/monitors.py" wallpapers)

    if ((${#pairs[@]} > 0)); then
        run "$dir/scripts/apply-wallpaper.sh" "${assets:--}" "${pairs[@]}"
    fi
fi
