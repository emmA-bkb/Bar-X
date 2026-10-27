# Bar X

Presets de wallpaper + barra de tarefas + widgets para o **Hyprland**, feitos com [Quickshell](https://quickshell.org).

Cada preset junta um wallpaper (Wallpaper Engine, vídeo ou imagem), um estilo de barra e um layout de widgets.

## O que tem

- **Barra de tarefas** própria (substitui a Waybar): em cima (Flutuante, Ilhas, Minimalista, Tonal), doca embaixo ou lateral. Apps organizados por área de trabalho, bandeja, CPU/RAM/SSD.
- **Widgets** na área de trabalho: relógio, calendário, música (MPRIS/Spotify), clima, sistema, perfil e versões "flor" no estilo Material 3. Arrasta, redimensiona e alinha num editor.
- **Wallpapers**: biblioteca do Wallpaper Engine (Steam), pasta local e a Comunidade (Steam Workshop), com teste de compatibilidade no Linux.
- **Cores**: destaque por preset, cores tiradas do wallpaper, seletor RGB e efeito vidro (transparência com desfoque).

## Requisitos

- Hyprland e Quickshell (`qs`)
- `linux-wallpaperengine` (wallpapers do Wallpaper Engine) e `mpvpaper` (vídeos e imagens)
- `ffmpeg`, `python3`, `curl`
- Opcional: `hyprlock` (botão Bloquear), Steam com Wallpaper Engine

## Como usar

```bash
./uix                       # abre/fecha a janela de configurações
scripts/uix-start.sh        # inicia a barra, os widgets e o wallpaper do preset ativo
```

Para iniciar no login, no `~/.config/hypr/hyprland.lua` troque as linhas da Waybar e do linux-wallpaper-engine-ux por:

```lua
hl.exec_cmd("/caminho/para/o/projeto/scripts/uix-start.sh")
```

As configurações ficam em `~/.config/uix/config.json`.
