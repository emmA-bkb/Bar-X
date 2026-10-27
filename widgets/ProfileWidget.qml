import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// Profile: photo (~/.face), user name, uptime, weather and shortcuts.
WidgetCard {
    id: root

    property string uptime: ""

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: {
            const secs = Number(text().split(" ")[0]);
            const h = Math.floor(secs / 3600);
            const m = Math.floor(secs % 3600 / 60);
            root.uptime = h > 0 ? h + "h " + m + "min" : m + "min";
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: uptimeFile.reload()
    }

    Row {
        id: header
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 22
        spacing: 14

        ClippingRectangle {
            width: 64
            height: 64
            radius: 32
            color: root.accent

            WText {
                anchors.centerIn: parent
                visible: face.status !== Image.Ready
                text: System.user.charAt(0).toUpperCase()
                color: root.onAccent
                font.pixelSize: 28
                font.weight: Font.Bold
            }

            Image {
                id: face
                anchors.fill: parent
                source: "file://" + System.face
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 128
                asynchronous: true
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            WText {
                text: System.user
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
            WText {
                text: "Up for " + root.uptime
                color: root.fgMuted
                font.pixelSize: 13
            }
            Row {
                spacing: 6
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    path: Weather.icon
                    size: 15
                    color: root.fgDim
                }
                WText {
                    text: Weather.ready ? Weather.temperature + " · " + Weather.condition.toLowerCase() : "…"
                    color: root.fgDim
                    font.pixelSize: 13
                }
            }
        }
    }

    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 22
        spacing: 10

        // Lock: hyprlock (with your config or the Uix theme), see scripts/lock.sh
        Rectangle {
            width: lockRow.implicitWidth + 30
            height: 42
            radius: 21
            color: lockMouse.containsMouse ? Qt.lighter(root.accent, 1.1) : root.accent

            Row {
                id: lockRow
                anchors.centerIn: parent
                spacing: 8
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    path: Icons.lock
                    size: 17
                    color: root.onAccent
                }
                WText {
                    text: "Lock"
                    color: root.onAccent
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
            }

            MouseArea {
                id: lockMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/lock.sh")])
            }
        }

        // Open Uix
        Rectangle {
            width: 42
            height: 42
            radius: 21
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, uixMouse.containsMouse ? 0.2 : 0.1)

            Icon {
                anchors.centerIn: parent
                path: Icons.tune
                size: 18
                color: root.fg
            }

            MouseArea {
                id: uixMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached([Quickshell.shellPath("uix")])
            }
        }
    }
}
