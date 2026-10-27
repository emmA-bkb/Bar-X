import QtQuick
import qs.config
import qs.components

// Round icon button used on the bar.
Rectangle {
    id: root

    property string icon
    signal clicked

    width: BarStyle.itemHeight
    height: BarStyle.itemHeight
    radius: height / 2
    color: mouse.containsMouse ? BarStyle.hover : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }

    Icon {
        anchors.centerIn: parent
        path: root.icon
        size: BarStyle.minimal ? 15 : 18
        color: mouse.containsMouse ? BarStyle.accent : BarStyle.text
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
