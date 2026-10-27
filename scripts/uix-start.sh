#!/usr/bin/env bash
# Inicia o Uix no login: barra + widgets e o wallpaper do preset ativo.
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

# 1) Barra (Uix ou Waybar) e widgets
run "$dir/scripts/desktop.sh" "$provider" "$widgets"

# 2) Wallpaper do preset ativo
if [[ "$apply_on_login" == "1" && -n "$wallpaper" && -e "$wallpaper" ]]; then
    if [[ -f "$wallpaper/project.json" ]]; then
        kind="we"
    else
        case "${wallpaper,,}" in
            *.mp4 | *.webm | *.mkv | *.mov) kind="video" ;;
            *) kind="image" ;;
        esac
    fi

    # Pasta de assets do Wallpaper Engine (a mesma que o Uix usa)
    assets="$(python3 -I "$dir/scripts/scan-wallpaper-engine.py" | awk -F'\t' '$1 == "assets" { print $2; exit }')"

    # Monitores conectados
    mapfile -t screens < <(hyprctl monitors -j 2>/dev/null | python3 -I -c 'import json, sys; [print(m["name"]) for m in json.load(sys.stdin)]')

    if ((${#screens[@]} > 0)); then
        run "$dir/scripts/apply-wallpaper.sh" "$kind" "$wallpaper" "${assets:--}" "${screens[@]}"
    fi
fi
