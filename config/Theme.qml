pragma Singleton
import QtQuick
import Quickshell

// Colors, fonts and sizes used across the whole interface.
Singleton {
    readonly property string font: "Adwaita Sans"

    readonly property color window: "#f2151819"
    readonly property color sidebar: "#1b1f22"
    readonly property color surface: "#22272b"
    readonly property color surfaceHover: "#2a3035"
    readonly property color surfaceHigh: "#333a40"
    readonly property color border: "#16ffffff"

    readonly property color text: "#e6e9ec"
    readonly property color textDim: "#a3abb3"
    readonly property color textMuted: "#6c757d"

    readonly property color accent: Config.options.accent
    readonly property color accentText: "#10201d"

    readonly property int radius: 22
    readonly property int radiusMedium: 16
    readonly property int radiusSmall: 12

    readonly property int animFast: Config.options.animations ? 140 : 0
    readonly property int animNormal: Config.options.animations ? 260 : 0

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
