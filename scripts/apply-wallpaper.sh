#!/usr/bin/env bash
# Aplica um wallpaper de verdade.
# Uso: apply-wallpaper.sh <we|video|image> <caminho> <pasta-assets|-> <monitor> [monitor...]
#   we          -> linux-wallpaperengine (mesmos argumentos que o linux-wallpaper-engine-ux usa)
#   video/image -> mpvpaper
kind="$1"
path="$2"
assets="$3"
shift 3
screens=("$@")

# Para o que estiver rodando nesses monitores
for s in "${screens[@]}"; do
    pkill -9 -f "linux-wallpaperengine.*--screen-root.*$s"
done
pkill -x mpvpaper
sleep 0.2

case "$kind" in
    we)
        args=()
        for s in "${screens[@]}"; do
            args+=(--screen-root "$s")
        done
        # Camada "background": fica sempre embaixo dos widgets do Uix (que usam a "bottom").
        # Sem isso o motor usa a "bottom" e, ao trocar de wallpaper, cobre os widgets.
        args+=(--layer background --bg "$path" --scaling fill)
        [[ "$assets" != "-" && -d "$assets" ]] && args+=(--assets-dir "$assets")
        setsid -f linux-wallpaperengine "${args[@]}" >/dev/null 2>&1
        ;;
    video | image)
        for s in "${screens[@]}"; do
            setsid -f mpvpaper -l background -o "no-audio loop-file=inf image-display-duration=inf" "$s" "$path" >/dev/null 2>&1
        done
        ;;
    *)
        echo "tipo desconhecido: $kind" >&2
        exit 1
        ;;
esac
