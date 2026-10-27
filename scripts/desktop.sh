#!/usr/bin/env bash
# Puts the bar and widgets in the chosen state.
# Usage: desktop.sh <uix|waybar> <widgets: 0|1>
#   uix    -> closes Waybar; the Uix bar shows up
#   waybar -> opens Waybar; the Uix bar hides
# The Uix process (desktop.qml) keeps running if the Uix bar or the widgets are on.
dir="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
provider="$1"
widgets="$2"

case "$provider" in
    uix) pkill -x waybar ;;
    waybar) pgrep -x waybar >/dev/null || setsid -f waybar >/dev/null 2>&1 ;;
    *)
        echo "usage: $0 <uix|waybar> <0|1>" >&2
        exit 1
        ;;
esac

if [[ "$provider" == "uix" || "$widgets" == "1" ]]; then
    # -n: don't start another one if it's already running
    qs -p "$dir/desktop.qml" -n -d >/dev/null 2>&1
else
    qs -p "$dir/desktop.qml" kill >/dev/null 2>&1
fi
