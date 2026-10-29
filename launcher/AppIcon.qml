import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components

// Icon of an app. Apps whose icon isn't in the icon theme show their initial instead of the
// "missing image" checkerboard.
Item {
    id: root

    property var entry
    readonly property string icon: entry ? entry.icon : ""
    // Icon=/full/path.png in the .desktop file, or a name looked up in the icon theme ("" = not found)
    readonly property string source: icon.startsWith("/") ? "file://" + icon : icon !== "" ? Quickshell.iconPath(icon, true) : ""

    IconImage {
        id: image
        anchors.fill: parent
        visible: root.source !== "" && status !== Image.Error
        source: root.source
        // Render SVG icons at the size shown, not at their (sometimes huge) natural size
        implicitSize: Math.max(root.width, root.height)
        mipmap: true
    }

    Rectangle {
        anchors.fill: parent
        visible: !image.visible
        radius: width * 0.28
        color: Theme.alpha(Theme.accent, 0.22)

        StyledText {
            anchors.centerIn: parent
            text: root.entry ? root.entry.name.charAt(0).toUpperCase() : "?"
            color: Theme.accent
            font.pixelSize: Math.round(parent.height * 0.48)
            font.weight: Font.Bold
        }
    }
}
