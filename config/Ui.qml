pragma Singleton
import QtQuick
import Quickshell

// Interface state shared between pages.
Singleton {
    property int page: 0

    // Bar positions; each one has its own styles (variants)
    readonly property var barPositions: [
        {
            "id": "top",
            "name": "Top",
            "description": "Bar at the top of the screen",
            "preview": "floating"
        },
        {
            "id": "bottom",
            "name": "Bottom",
            "description": "Small centered dock",
            "preview": "bottom"
        },
        {
            "id": "side",
            "name": "Side",
            "description": "Vertical bar on the left side",
            "preview": "side"
        }
    ]

    // Bar styles. id is what gets saved in the preset ("bar").
    readonly property var barStyles: [
        {
            "id": "floating",
            "position": "top",
            "name": "Floating",
            "fullName": "Floating",
            "description": "Full bar with rounded corners and a gap from the edge"
        },
        {
            "id": "island",
            "position": "top",
            "name": "Islands",
            "fullName": "Islands",
            "description": "Modules split into pills: left, center and right"
        },
        {
            "id": "minimal",
            "position": "top",
            "name": "Minimal",
            "fullName": "Minimal",
            "description": "Thin bar against the edge, just the essentials"
        },
        {
            "id": "tonal",
            "position": "top",
            "name": "Tonal",
            "fullName": "Tonal",
            "description": "Islands tinted with the theme color and a flower on the active workspace"
        },
        {
            "id": "bottom",
            "position": "bottom",
            "name": "Dock",
            "fullName": "Dock",
            "description": "Small and centered at the bottom of the screen"
        },
        {
            "id": "bottom-tonal",
            "position": "bottom",
            "name": "Tonal dock",
            "fullName": "Tonal dock",
            "description": "The dock tinted with the theme color and a flower on the active workspace"
        },
        {
            "id": "side",
            "position": "side",
            "name": "Full",
            "fullName": "Side",
            "description": "A single bar, top to bottom, with rounded corners"
        },
        {
            "id": "side-island",
            "position": "side",
            "name": "Islands",
            "fullName": "Side islands",
            "description": "Three separate pills: top, middle and bottom"
        },
        {
            "id": "side-minimal",
            "position": "side",
            "name": "Minimal",
            "fullName": "Side minimal",
            "description": "Thin and against the edge, only workspaces, clock and tray"
        },
        {
            "id": "side-tonal",
            "position": "side",
            "name": "Tonal",
            "fullName": "Side tonal",
            "description": "Islands tinted with the theme color and a flower on the active workspace"
        }
    ]

    function barStyle(id) {
        return barStyles.find(b => b.id === id) ?? null;
    }

    // Real screen size: widget positions are relative to it
    // Primary monitor (widgets live there); falls back to the first connected one
    readonly property var screen: Quickshell.screens.find(s => s.name === Config.options.primaryMonitor) ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    readonly property real screenWidth: screen ? screen.width : 1920
    readonly property real screenHeight: screen ? screen.height : 1080

    // Widget types. w/h = size in pixels on the real screen.
    readonly property var widgetTypes: [
        {
            "id": "clock",
            "name": "Clock",
            "description": "Big time and date",
            "icon": Icons.clock,
            "w": 340,
            "h": 170
        },
        {
            "id": "calendar",
            "name": "Calendar",
            "description": "Current month with today highlighted",
            "icon": Icons.calendar,
            "w": 330,
            "h": 330
        },
        {
            "id": "media",
            "name": "Music",
            "description": "Spotify and other players (MPRIS)",
            "icon": Icons.music,
            "w": 460,
            "h": 160
        },
        {
            "id": "weather",
            "name": "Weather",
            "description": "Temperature and conditions",
            "icon": Icons.cloud,
            "w": 380,
            "h": 160
        },
        {
            "id": "system",
            "name": "System",
            "description": "CPU, RAM and disk usage",
            "icon": Icons.chip,
            "w": 420,
            "h": 140
        },
        {
            "id": "mediaFlower",
            "name": "Music · Flower",
            "description": "Round cover and a flower play button",
            "icon": Icons.music,
            "w": 440,
            "h": 150
        },
        {
            "id": "clockStacked",
            "name": "Big clock",
            "description": "Stacked hour and minutes, no background",
            "icon": Icons.clock,
            "w": 250,
            "h": 300,
            "bg": 0
        },
        {
            "id": "statTiles",
            "name": "System · Tiles",
            "description": "CPU, RAM and disk in separate tiles",
            "icon": Icons.memory,
            "w": 420,
            "h": 140
        },
        {
            "id": "weekStrip",
            "name": "Week",
            "description": "Calendar of the current week only",
            "icon": Icons.calendar,
            "w": 360,
            "h": 130
        },
        {
            "id": "profile",
            "name": "Profile",
            "description": "Your photo, uptime and shortcuts",
            "icon": Icons.person2,
            "w": 330,
            "h": 190
        },
        {
            "id": "weatherFlower",
            "name": "Weather · Flower",
            "description": "Temperature with the icon in a flower",
            "icon": Icons.cloud,
            "w": 360,
            "h": 130
        }
    ]

    // Default background of a widget type (some, like the big clock, have none)
    function defaultBg(type) {
        const t = widgetType(type);
        return t && t.bg !== undefined ? t.bg : 0.89;
    }

    function widgetType(id) {
        return widgetTypes.find(t => t.id === id) ?? null;
    }

    readonly property var accents: ["#7fd1c4", "#8ec5ff", "#a7b0ff", "#c9a7ff", "#f4a7c0", "#ffb38a", "#f6d58b", "#a8e6a1"]

    signal toast(string message)

    // Open color picker request: { title, color, callback } (or null)
    property var colorRequest: null

    // Opens the free color picker; callback(hex) is called on confirm
    function pickColor(title, initial, callback) {
        colorRequest = {
            "title": title,
            "color": initial,
            "callback": callback
        };
    }

    function notify(message) {
        toast(message);
    }

    function barName(id) {
        const s = barStyle(id);
        return s ? s.fullName : id;
    }
}
