import QtQuick
import Quickshell
import qs.config
import qs.components
import qs.services

// Search result: icon, name and what the app is. Click opens it, right click pins/unpins it.
// Without an entry it shows a calculator result (click copies it).
Rectangle {
    id: root

    property var entry: null
    property string result: "" // calculator result
    property bool selected: false

    signal hovered

    height: 58
    radius: Theme.radiusSmall
    color: selected ? Theme.alpha(Theme.accent, 0.16) : "transparent"
    border.width: selected ? 1 : 0
    border.color: Theme.alpha(Theme.accent, 0.4)

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }

    Item {
        id: iconBox
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 36

        AppIcon {
            visible: root.entry !== null
            anchors.fill: parent
            entry: root.entry
        }

        Rectangle {
            visible: root.entry === null
            anchors.fill: parent
            radius: 18
            color: Theme.alpha(Theme.accent, 0.2)

            Icon {
                anchors.centerIn: parent
                path: Icons.calculator
                size: 19
                color: Theme.accent
            }
        }
    }

    Column {
        anchors.left: iconBox.right
        anchors.leftMargin: 14
        anchors.right: hint.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        StyledText {
            width: parent.width
            text: root.entry ? root.entry.name : "= " + root.result
            font.pixelSize: root.entry ? 14 : 17
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        StyledText {
            width: parent.width
            visible: text !== ""
            text: root.entry ? (root.entry.genericName || root.entry.comment || "") : "Press Enter to copy"
            color: Theme.textMuted
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }

    // What Enter does, on the selected row
    StyledText {
        id: hint
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        visible: root.selected
        text: root.entry ? (Launcher.isPinned(root.entry) ? "Pinned  ·  Enter ↵" : "Enter ↵") : "Copy ↵"
        color: Theme.textMuted
        font.pixelSize: 11
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered()
        onClicked: event => {
            if (!root.entry)
                Launcher.copy(root.result);
            else if (event.button === Qt.RightButton)
                Launcher.togglePin(root.entry);
            else
                Launcher.launch(root.entry);
        }
    }
}
