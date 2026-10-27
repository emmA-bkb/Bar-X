#!/usr/bin/env bash
# Deixa a barra e os widgets no estado escolhido.
# Uso: desktop.sh <uix|waybar> <widgets: 0|1>
#   uix    -> fecha a Waybar; a barra do Uix aparece
#   waybar -> abre a Waybar; a barra do Uix some
# O processo do Uix (desktop.qml) fica rodando se a barra do Uix ou os widgets estiverem ligados.
dir="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
provider="$1"
widgets="$2"

case "$provider" in
    uix) pkill -x waybar ;;
    waybar) pgrep -x waybar >/dev/null || setsid -f waybar >/dev/null 2>&1 ;;
    *)
        echo "uso: $0 <uix|waybar> <0|1>" >&2
        exit 1
        ;;
esac

if [[ "$provider" == "uix" || "$widgets" == "1" ]]; then
    # -n: nao abre outro se ja estiver rodando
    qs -p "$dir/desktop.qml" -n -d >/dev/null 2>&1
else
    qs -p "$dir/desktop.qml" kill >/dev/null 2>&1
fi
