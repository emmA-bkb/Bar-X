import QtQuick
import qs.config
import qs.components
import qs.services

// Clima atual (wttr.in). A cidade pode ser escolhida em Aparencia; vazio = automatico.
WidgetCard {
    id: root

    Icon {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: 28
        anchors.verticalCenter: parent.verticalCenter
        path: Weather.icon
        size: 76
        color: root.accent
    }

    Column {
        anchors.left: icon.right
        anchors.leftMargin: 22
        anchors.right: details.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        WText {
            text: Weather.temperature
            font.pixelSize: 52
            font.weight: Font.Bold
        }
        WText {
            width: parent.width
            text: Weather.city ? Weather.condition + " · " + Weather.city : Weather.condition
            color: root.fgDim
            font.pixelSize: 16
        }
    }

    Column {
        id: details
        anchors.right: parent.right
        anchors.rightMargin: 26
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Row {
            anchors.right: parent.right
            spacing: 6
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                path: Icons.drop
                size: 16
                color: root.fgMuted
            }
            WText {
                text: Weather.humidity
                color: root.fgDim
                font.pixelSize: 15
            }
        }

        WText {
            anchors.right: parent.right
            text: Weather.wind
            color: root.fgDim
            font.pixelSize: 15
        }
    }
}
