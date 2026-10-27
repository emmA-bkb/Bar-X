#!/usr/bin/env bash
# Bloqueia a tela (botao "Bloquear" do widget Perfil).
#   - Ja bloqueada: nao faz nada
#   - Tem ~/.config/hypr/hyprlock.conf: usa o hyprlock com a sua config
#   - Senao: usa o hyprlock com o tema do Uix (config/hyprlock.conf), na cor de destaque do Uix
#   - Sem hyprlock instalado: tenta o bloqueio padrao do sistema
dir="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"

pidof hyprlock >/dev/null && exit 0

if ! command -v hyprlock >/dev/null; then
    exec loginctl lock-session
fi

if [[ -f "$HOME/.config/hypr/hyprlock.conf" ]]; then
    exec hyprlock
fi

# Cor de destaque do Uix (#rrggbb -> "r, g, b")
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
