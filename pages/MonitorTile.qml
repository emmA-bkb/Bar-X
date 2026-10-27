import QtQuick
import qs.config
import qs.components
import qs.services

// One monitor on the layout drawing: its wallpaper, name, resolution and badges.
// Dragging it moves the monitor (the page decides where it snaps).
Rectangle {
    id: root

    required property var monitor
    property bool selected: false
    property bool primary: false

    signal pressed
    signal dragged(real dx, real dy) // in drawing pixels, since the press
    signal released

    radius: 10
    color: Theme.surfaceHigh
    border.width: selected ? 3 : 1
    border.color: selected ? Theme.accent : Theme.border

    WallpaperPreview {
        anchors.fill: parent
        anchors.margins: 3
        radius: 8
        source: Wallpapers.thumbFor(Config.monitorWallpaper(root.monitor.name))
    }

    // Dark strip with the name so it stays readable over any wallpaper
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 3
        height: info.height + 12
        radius: 8
        color: "#c0101214"

        Column {
            id: info
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: root.monitor.name
                font.weight: Font.DemiBold
            }
            StyledText {
                text: root.monitor.w + "×" + root.monitor.h + " · " + root.monitor.refresh + " Hz"
                color: Theme.textDim
                font.pixelSize: 11
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 4

        // Bar turned off on this monitor
        Rectangle {
            visible: !Config.monitorBar(root.monitor.name)
            width: 24
            height: 24
            radius: 12
            color: "#c0101214"

            Icon {
                anchors.centerIn: parent
                path: Icons.bar
                size: 13
                color: "#ff7b7b"
            }
        }

        // Primary monitor
        Rectangle {
            visible: root.primary
            width: 24
            height: 24
            radius: 12
            color: Theme.accent

            Icon {
                anchors.centerIn: parent
                path: Icons.star
                size: 14
                color: Theme.accentText
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        property real startX: 0
        property real startY: 0

        onPressed: mouse => {
            const p = mapToItem(null, mouse.x, mouse.y);
            startX = p.x;
            startY = p.y;
            root.pressed();
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            const p = mapToItem(null, mouse.x, mouse.y);
            root.dragged(p.x - startX, p.y - startY);
        }
        onReleased: root.released()
    }
}
