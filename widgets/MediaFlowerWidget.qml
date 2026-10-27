import QtQuick
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// Music: round cover (spins like a record while playing) and a flower play button.
WidgetCard {
    id: root

    ClippingRectangle {
        id: cover
        anchors.left: parent.left
        anchors.leftMargin: 22
        anchors.verticalCenter: parent.verticalCenter
        width: 108
        height: 108
        radius: 54
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.2)

        Icon {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            path: Icons.music
            size: 44
            color: root.accent
        }

        Image {
            id: art
            anchors.fill: parent
            source: Media.art
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 220

            RotationAnimation on rotation {
                running: Media.playing
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 20000
            }
        }
    }

    Column {
        anchors.left: cover.right
        anchors.leftMargin: 20
        anchors.right: controls.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        WText {
            width: parent.width
            text: Media.title
            font.pixelSize: 22
            font.weight: Font.Bold
        }
        WText {
            width: parent.width
            text: Media.artist
            color: root.fgDim
            font.pixelSize: 15
        }
        Rectangle {
            width: parent.width
            height: 5
            radius: 3
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.15)

            Rectangle {
                width: parent.width * Media.progress
                height: parent.height
                radius: 3
                color: root.accent
            }
        }
    }

    Row {
        id: controls
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            path: Icons.skipPrev
            size: 24
            color: prevMouse.containsMouse ? root.fg : root.fgDim

            MouseArea {
                id: prevMouse
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Media.previous()
            }
        }

        // Flower play button
        Item {
            width: 76
            height: 76

            Cookie {
                anchors.centerIn: parent
                size: playMouse.containsMouse ? 76 : 70
                lobes: 8
                depth: 0.13
                color: root.accent
                spinning: Media.playing

                Behavior on size {
                    NumberAnimation {
                        duration: 160
                    }
                }
            }

            Icon {
                anchors.centerIn: parent
                path: Media.playing ? Icons.pause : Icons.play
                size: 30
                color: root.onAccent
            }

            MouseArea {
                id: playMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Media.toggle()
            }
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            path: Icons.skipNext
            size: 24
            color: nextMouse.containsMouse ? root.fg : root.fgDim

            MouseArea {
                id: nextMouse
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Media.next()
            }
        }
    }
}
