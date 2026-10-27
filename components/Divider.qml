import QtQuick
import qs.config

// Vertical line to separate groups of controls.
Rectangle {
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    width: 1
    height: 38
    color: Theme.border
}
