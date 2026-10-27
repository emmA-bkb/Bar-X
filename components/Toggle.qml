import QtQuick
import qs.config

// Interruptor liga/desliga.
Rectangle {
    id: root

    property bool checked: false

    signal toggled(bool checked)

    implicitWidth: 46
    implicitHeight: 26
    radius: height / 2
    color: checked ? Theme.accent : Theme.surfaceHigh

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }

    Rectangle {
        width: 20
        height: 20
        radius: 10
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 3 : 3
        color: root.checked ? Theme.accentText : Theme.textDim

        Behavior on x {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
