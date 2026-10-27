import QtQuick
import qs.config

// Botao com icone e texto. primary = preenchido com a cor de destaque.
Rectangle {
    id: root

    property string icon
    property string text
    property bool primary: false

    signal clicked

    implicitWidth: content.implicitWidth + 32
    implicitHeight: 40
    radius: Theme.radiusSmall
    color: primary ? (mouse.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent) : (mouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceHover)
    scale: mouse.pressed ? 0.97 : 1

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animFast
        }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 8

        Icon {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            path: root.icon
            size: 17
            color: root.primary ? Theme.accentText : Theme.text
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.primary ? Theme.accentText : Theme.text
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
