import QtQuick
import qs.config
import qs.components
import qs.services

// Power action in the menu footer. With confirm, the first click asks "Sure?" and only a second
// click within 3 seconds runs it (restart, shut down, log out).
Rectangle {
    id: root

    property string icon
    property string label
    property string action
    property bool confirm: false
    property bool armed: false

    readonly property color danger: "#ff8a80"

    implicitWidth: row.implicitWidth + 24
    implicitHeight: 38
    radius: 19
    color: armed ? Theme.alpha(danger, 0.2) : mouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceHover
    border.width: armed ? 1 : 0
    border.color: Theme.alpha(danger, 0.6)

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            path: root.icon
            size: 16
            color: root.armed ? root.danger : Theme.textDim
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.armed ? "Sure?" : root.label
            color: root.armed ? root.danger : Theme.textDim
            font.pixelSize: 12
            font.weight: root.armed ? Font.DemiBold : Font.Normal
        }
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = false
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.confirm && !root.armed) {
                root.armed = true;
                disarm.restart();
                return;
            }
            root.armed = false;
            Launcher.power(root.action);
        }
    }
}
