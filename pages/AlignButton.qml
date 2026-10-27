import QtQuick
import qs.config
import qs.components

// Small widget align button (h: left/center/right, v: top/middle/bottom).
IconButton {
    property string h: ""
    property string v: ""

    implicitWidth: 28
    implicitHeight: 26
    radius: 8
    iconSize: 15
    iconColor: Theme.textDim
    baseColor: Theme.surfaceHover
}
