import QtQuick
import qs.config

// Botao redondo so com icone.
Rectangle {
    id: root

    property string icon
    property real iconSize: 18
    property color iconColor: Theme.text
    property color baseColor: Theme.surfaceHover

    signal clicked

    implicitWidth: 38
    implicitHeight: 38
    radius: height / 2
    color: mouse.containsMouse ? Theme.surfaceHigh : baseColor
    scale: mouse.pressed ? 0.92 : 1

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animFast
        }
    }

    Icon {
        anchors.centerIn: parent
        path: root.icon
        size: root.iconSize
        color: root.iconColor
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
