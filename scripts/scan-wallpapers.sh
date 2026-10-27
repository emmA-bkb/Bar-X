#!/usr/bin/env bash
# Lista imagens e videos de uma ou mais pastas e gera miniaturas dos videos.
# Uso: scan-wallpapers.sh <pasta-de-cache> <pasta> [pasta...]
# Saida: uma linha por arquivo -> tipo<TAB>caminho<TAB>miniatura
cache="$1"
shift
mkdir -p "$cache"
shopt -s nullglob nocaseglob

for dir in "$@"; do
    for f in "$dir"/*.{png,jpg,jpeg,webp,gif,bmp,avif,mp4,webm,mkv,mov}; do
        case "${f,,}" in
            *.mp4 | *.webm | *.mkv | *.mov)
                thumb="$cache/$(printf '%s' "$f" | md5sum | cut -c1-16).jpg"
                if [[ ! -f "$thumb" ]]; then
                    ffmpeg -loglevel error -y -ss 1 -i "$f" -frames:v 1 -vf scale=480:-1 "$thumb" </dev/null
                fi
                printf 'video\t%s\t%s\n' "$f" "$thumb"
                ;;
            *)
                printf 'image\t%s\t%s\n' "$f" "$f"
                ;;
        esac
    done
done
