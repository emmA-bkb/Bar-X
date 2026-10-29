import QtQuick
import Quickshell
import qs.config
import qs.components
import qs.services

// App in the menu grid: big icon and name. Click opens it, right click pins/unpins it.
Item {
    id: root

    property var entry
    property bool selected: false
    readonly property bool pinned: entry ? Launcher.isPinned(entry) : false

    signal hovered

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: Theme.radiusSmall
        color: root.selected ? Theme.alpha(Theme.accent, 0.16) : "transparent"
        border.width: root.selected ? 1 : 0
        border.color: Theme.alpha(Theme.accent, 0.4)

        Behavior on color {
            ColorAnimation {
                duration: Theme.animFast
            }
        }
    }

    AppIcon {
        id: icon
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 14
        width: 46
        height: 46
        entry: root.entry
        scale: mouse.pressed ? 0.9 : root.selected ? 1.08 : 1

        Behavior on scale {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutBack
            }
        }
    }

    // Pinned mark
    Rectangle {
        visible: root.pinned
        anchors.left: icon.right
        anchors.leftMargin: -8
        anchors.top: icon.top
        anchors.topMargin: -4
        width: 18
        height: 18
        radius: 9
        color: Theme.accent

        Icon {
            anchors.centerIn: parent
            path: Icons.pin
            size: 11
            color: Theme.accentText
        }
    }

    StyledText {
        anchors.top: icon.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 14
        horizontalAlignment: Text.AlignHCenter
        text: root.entry ? root.entry.name : ""
        color: root.selected ? Theme.text : Theme.textDim
        font.pixelSize: 12
        maximumLineCount: 2
        wrapMode: Text.Wrap
        elide: Text.ElideRight
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered()
        onClicked: event => {
            if (event.button === Qt.RightButton)
                Launcher.togglePin(root.entry);
            else
                Launcher.launch(root.entry);
        }
    }
}
