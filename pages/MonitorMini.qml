import QtQuick
import qs.config
import qs.components

// Tiny screen of a secondary monitor on a preset card: its wallpaper, a hint of the bar
// and the monitor number. The ring takes the card color, so it looks cut out of the preview.
Item {
    id: root

    property string source // thumbnail path
    property color accent: Theme.accent
    property color ring: Theme.surface
    property bool bar: true
    property string label: "2"

    // Soft shadow
    Rectangle {
        anchors.fill: frame
        anchors.topMargin: 3
        anchors.bottomMargin: -4
        radius: frame.radius + 2
        color: "#000000"
        opacity: 0.35
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: 9
        color: root.ring

        WallpaperPreview {
            anchors.fill: parent
            anchors.margins: 2.5
            radius: 7
            source: root.source
            accent: root.accent

            // Bar hint, when the bar is on for this monitor
            Rectangle {
                visible: root.bar
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 3
                width: parent.width - 8
                height: 4
                radius: 2
                color: Qt.rgba(0, 0, 0, 0.5)

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 1
                    width: 6
                    height: 2
                    radius: 1
                    color: root.accent
                }
            }

            // Monitor number
            Rectangle {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 4
                width: 15
                height: 15
                radius: 8
                color: Qt.rgba(0, 0, 0, 0.55)

                StyledText {
                    anchors.centerIn: parent
                    text: root.label
                    color: "#ffffff"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }
            }
        }
    }
}
