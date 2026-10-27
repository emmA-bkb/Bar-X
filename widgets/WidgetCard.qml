import QtQuick
import qs.config

// Default background of every widget. Colors come from the palette (manual or wallpaper).
Rectangle {
    readonly property bool isWidgetCard: true

    property color accent: Theme.accent
    property color bgColor: "#131618"
    property color fg: Theme.text
    property color fgDim: Theme.textDim
    property color fgMuted: Theme.textMuted
    property color onAccent: Theme.accentText
    // 0 = no background, 1 = solid background
    property real backgroundOpacity: 0.89
    // plain: the card draws no background (the widget draws its own tiles)
    property bool plain: false

    radius: 30
    color: plain ? "transparent" : Qt.rgba(bgColor.r, bgColor.g, bgColor.b, backgroundOpacity)
    border.width: plain ? 0 : 1
    border.color: Qt.rgba(1, 1, 1, 0.13 * Math.min(1, backgroundOpacity * 1.5))
}
