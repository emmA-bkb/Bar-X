import QtQuick
import Quickshell.Widgets
import qs.config

// Rounded wallpaper preview. Without an image it shows an accent color gradient.
ClippingRectangle {
    id: root

    property string source // thumbnail path
    property color accent: Theme.accent

    radius: Theme.radiusSmall
    color: Theme.surfaceHover

    Rectangle {
        anchors.fill: parent
        visible: img.status !== Image.Ready
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.alpha(root.accent, 0.55)
            }
            GradientStop {
                position: 1
                color: Theme.alpha(root.accent, 0.08)
            }
        }
    }

    Image {
        id: img
        anchors.fill: parent
        // Local path or URL (Workshop previews)
        source: !root.source ? "" : root.source.startsWith("http") ? root.source : "file://" + root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 480
        opacity: status === Image.Ready ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animNormal
            }
        }
    }
}
