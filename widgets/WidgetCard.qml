import QtQuick
import qs.config

// Fundo padrao de todos os widgets. As cores vem da paleta (manual ou do wallpaper).
Rectangle {
    readonly property bool isWidgetCard: true

    property color accent: Theme.accent
    property color bgColor: "#131618"
    property color fg: Theme.text
    property color fgDim: Theme.textDim
    property color fgMuted: Theme.textMuted
    property color onAccent: Theme.accentText
    // 0 = sem fundo, 1 = fundo solido
    property real backgroundOpacity: 0.89
    // plain: o cartao nao desenha fundo (o widget desenha os proprios blocos)
    property bool plain: false

    radius: 30
    color: plain ? "transparent" : Qt.rgba(bgColor.r, bgColor.g, bgColor.b, backgroundOpacity)
    border.width: plain ? 0 : 1
    border.color: Qt.rgba(1, 1, 1, 0.13 * Math.min(1, backgroundOpacity * 1.5))
}
