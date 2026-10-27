import QtQuick
import qs.config

// Settings row: icon + title/description on the left, control on the right.
Rectangle {
    id: root

    property string icon
    property string title
    property string subtitle
    default property alias trailing: trailingArea.data

    implicitHeight: 64
    radius: Theme.radiusMedium
    color: Theme.surface

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.right: trailingArea.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            path: root.icon
            size: 19
            color: Theme.textDim
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 33
            spacing: 2

            StyledText {
                width: parent.width
                text: root.title
            }

            StyledText {
                visible: root.subtitle !== ""
                width: parent.width
                text: root.subtitle
                color: Theme.textMuted
                font.pixelSize: 12
            }
        }
    }

    Item {
        id: trailingArea
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
