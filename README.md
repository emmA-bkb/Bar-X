# Bar X

Wallpaper + taskbar + widget presets for **Hyprland**, built with [Quickshell](https://quickshell.org).

Each preset combines a wallpaper (Wallpaper Engine, video or image), a bar style and a widget layout.

## Features

- **Taskbar** of its own (replaces Waybar): top (Floating, Islands, Minimal, Tonal), bottom dock or side bar. Apps grouped by workspace, system tray, CPU/RAM/SSD.
- **Menu** (the ☰ button) in four styles: Panel (search, pinned and every app, power buttons), Spotlight (a search bar in the middle), Curtain (pinned apps unroll from the button) and Orbit (pinned apps bloom in an arc). The apps you open most come first in searches, and it has a quick calculator.
- **Desktop widgets**: clock, calendar, music (MPRIS/Spotify), weather, system, profile and Material 3 style "flower" versions. Drag, resize and align them in an editor.
- **Wallpapers**: Wallpaper Engine library (Steam), a local folder and the Community tab (Steam Workshop), with a Linux compatibility test.
- **Wallpaper settings**: sound and volume, FPS limit, scaling, particles/mouse/parallax and the wallpaper's own options (e.g. its soundtrack). Wallpapers pause on monitors covered by a fullscreen app (or any window) to free the GPU for games.
- **Colors**: accent per preset, colors taken from the wallpaper, an RGB color picker and a glass effect (transparency with blur).
- **Monitors**: a wallpaper per monitor (saved in each preset), bar on/off per monitor, primary monitor, monitor arrangement and resolution and refresh rate, and dimming a monitor after a while without use.

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

To open the menu with a shortcut, e.g. Super + R:

```lua
hl.bind("SUPER + R", hl.dsp.exec_cmd("qs -p /path/to/the/project/desktop.qml ipc call launcher toggle"))
```

Settings (presets, widgets, monitors, colors) are stored in `~/.config/uix/config.json`, outside the project.

### Machine-specific settings (`.env`)

Commands that depend on your system go in a `.env` file in the project folder, which git ignores:

```bash
cp .env.example .env   # then edit the values
```

| Variable | What it does |
|---|---|
| `UIX_LAUNCHER` | Command of the menu button (☰) on the bar, instead of the Bar X menu. Empty = the Bar X menu. |
| `UIX_TERMINAL` | Terminal for terminal apps opened from the menu (default `kitty`). |
| `UIX_SYSTEM_MONITOR` | Command run when you click RAM on the bar (e.g. `kitty -e btop`). |
