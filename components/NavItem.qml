import QtQuick
import qs.config

// Sidebar item.
Rectangle {
    id: root

    property string icon
    property string label
    property bool active: false

    signal clicked

    implicitHeight: 44
    radius: Theme.radiusSmall
    color: active ? Theme.alpha(Theme.accent, 0.16) : mouse.containsMouse ? Theme.surfaceHover : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }

    // Side indicator of the active item
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: root.active ? 18 : 0
        radius: 2
        color: Theme.accent

        Behavior on height {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            path: root.icon
            size: 19
            color: root.active ? Theme.accent : Theme.textDim
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.active ? Theme.text : Theme.textDim
            font.weight: root.active ? Font.DemiBold : Font.Normal
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
