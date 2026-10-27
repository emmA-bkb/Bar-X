# Bar X

Wallpaper + taskbar + widget presets for **Hyprland**, built with [Quickshell](https://quickshell.org).

Each preset combines a wallpaper (Wallpaper Engine, video or image), a bar style and a widget layout.

## Features

- **Taskbar** of its own (replaces Waybar): top (Floating, Islands, Minimal, Tonal), bottom dock or side bar. Apps grouped by workspace, system tray, CPU/RAM/SSD.
- **Desktop widgets**: clock, calendar, music (MPRIS/Spotify), weather, system, profile and Material 3 style "flower" versions. Drag, resize and align them in an editor.
- **Wallpapers**: Wallpaper Engine library (Steam), a local folder and the Community tab (Steam Workshop), with a Linux compatibility test.
- **Colors**: accent per preset, colors taken from the wallpaper, an RGB color picker and a glass effect (transparency with blur).
- **Monitors**: a wallpaper per monitor (saved in each preset), bar on/off per monitor, primary monitor and monitor arrangement.

## Requirements

- Hyprland and Quickshell (`qs`)
- `linux-wallpaperengine` (Wallpaper Engine wallpapers) and `mpvpaper` (videos and images)
- `ffmpeg`, `python3`, `curl`
- Optional: `hyprlock` (Lock button), Steam with Wallpaper Engine

## Usage

```bash
./uix                       # opens/closes the settings window
scripts/uix-start.sh        # starts the bar, the widgets and the active preset's wallpaper
```

To start it on login, in `~/.config/hypr/hyprland.lua` replace the Waybar and linux-wallpaper-engine-ux lines with:

```lua
hl.exec_cmd("/path/to/the/project/scripts/uix-start.sh")
```

Settings (presets, widgets, monitors, colors) are stored in `~/.config/uix/config.json`, outside the project.

### Machine-specific settings (`.env`)

Commands that depend on your system go in a `.env` file in the project folder, which git ignores:

```bash
cp .env.example .env   # then edit the values
```

| Variable | What it does |
|---|---|
| `UIX_LAUNCHER` | Command of the menu button (☰) on the bar. Empty hides the button. |
| `UIX_SYSTEM_MONITOR` | Command run when you click RAM on the bar (e.g. `kitty -e btop`). |
