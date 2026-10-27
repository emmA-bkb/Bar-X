import QtQuick
import qs.config
import qs.components

// Chip de filtro (ordem / tipo) da Comunidade.
Rectangle {
    id: chip
    property string label
    property bool active: false
    signal clicked
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    width: chipText.implicitWidth + 26
    height: 32
    radius: 16
    color: active ? Theme.alpha(Theme.accent, 0.18) : chipMouse.containsMouse ? Theme.surfaceHover : Theme.surface
    border.width: 1
    border.color: active ? Theme.alpha(Theme.accent, 0.5) : "transparent"

    StyledText {
        id: chipText
        anchors.centerIn: parent
        text: chip.label
        color: chip.active ? Theme.text : Theme.textDim
        font.pixelSize: 12
        font.weight: chip.active ? Font.DemiBold : Font.Normal
    }

    MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
