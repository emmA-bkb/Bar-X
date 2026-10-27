import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.config
import qs.components

// Music player. Prefers Spotify; otherwise uses the first open MPRIS player.
// The buttons work on the desktop; in the Uix editor dragging takes over.
WidgetCard {
    id: root

    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => (p.identity ?? "").toLowerCase().includes("spotify")) ?? ps[0] ?? null;
    }
    readonly property bool hasTrack: player !== null && (player.trackTitle ?? "") !== ""
    readonly property real progress: player && player.length > 0 ? Math.min(1, player.position / player.length) : 0

    // The MPRIS position doesn't update by itself
    Timer {
        interval: 1000
        repeat: true
        running: root.player !== null && root.player.isPlaying
        onTriggered: root.player.positionChanged()
    }

    ClippingRectangle {
        id: cover
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 20
        width: 120
        height: 120
        radius: 20
        color: Theme.alpha(root.accent, 0.18)

        Icon {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            path: Icons.music
            size: 48
            color: root.accent
        }

        Image {
            id: art
            anchors.fill: parent
            source: root.hasTrack ? (root.player.trackArtUrl ?? "") : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 240
        }
    }

    Column {
        anchors.left: cover.right
        anchors.leftMargin: 20
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        WText {
            width: parent.width
            text: root.hasTrack ? root.player.trackTitle : "Nothing playing"
            font.pixelSize: 22
            font.weight: Font.DemiBold
        }

        WText {
            width: parent.width
            text: root.hasTrack ? (root.player.trackArtist || root.player.identity) : "Open Spotify to see your music here"
            color: root.fgDim
            font.pixelSize: 16
        }

        Item {
            width: 1
            height: 4
        }

        Rectangle {
            width: parent.width
            height: 6
            radius: 3
            color: "#26ffffff"

            Rectangle {
                width: parent.width * root.progress
                height: parent.height
                radius: 3
                color: root.accent
            }
        }

        Row {
            anchors.right: parent.right
            spacing: 14

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                path: Icons.skipPrev
                size: 26
                color: prevMouse.containsMouse ? root.fg : root.fgDim

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    enabled: root.player !== null && root.player.canGoPrevious
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player.previous()
                }
            }

            Rectangle {
                width: 42
                height: 42
                radius: 21
                color: root.accent

                Icon {
                    anchors.centerIn: parent
                    path: root.player && root.player.isPlaying ? Icons.pause : Icons.play
                    size: 24
                    color: root.onAccent
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.player !== null && root.player.canTogglePlaying
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player.togglePlaying()
                }
            }

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                path: Icons.skipNext
                size: 26
                color: nextMouse.containsMouse ? root.fg : root.fgDim

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    enabled: root.player !== null && root.player.canGoNext
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player.next()
                }
            }
        }
    }
}
