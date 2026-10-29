import QtQuick
import qs.config
import qs.components
import qs.services

// App in the "curtain" menu: an icon that grows and floats up and down while hovered or selected.
// Without an entry it's the "all apps" button.
Item {
    id: root

    property var entry: null
    property bool selected: false
    property bool shown: false

    signal hovered

    width: 52
    height: 48

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: root.selected ? "#26ffffff" : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }
    }

    Item {
        id: floater

        property real lift: 0

        width: 36
        height: 36
        anchors.centerIn: parent
        scale: root.selected ? 1.14 : 1
        transform: Translate {
            y: floater.lift
        }

        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        AppIcon {
            visible: root.entry !== null
            anchors.fill: parent
            entry: root.entry
        }

        Icon {
            visible: root.entry === null
            anchors.centerIn: parent
            path: Icons.apps
            size: 26
            color: "#e6ffffff"
        }

        // Floats gently while selected
        SequentialAnimation on lift {
            running: root.selected && root.shown
            loops: Animation.Infinite
            onRunningChanged: if (!running) floater.lift = 0

            NumberAnimation {
                from: 0
                to: -4
                duration: 1000
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                from: -4
                to: 0
                duration: 1000
                easing.type: Easing.InOutSine
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered()
        onClicked: event => {
            if (!root.entry)
                Launcher.showAllApps();
            else if (event.button === Qt.RightButton)
                Launcher.togglePin(root.entry);
            else
                Launcher.launch(root.entry);
        }
    }
}
