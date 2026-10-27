import QtQuick
import qs.config
import qs.components
import qs.services

// Clima com o icone dentro de uma florzinha.
WidgetCard {
    id: root

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 26
        anchors.right: badge.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        WText {
            text: Weather.temperature
            color: root.accent
            font.pixelSize: 44
            font.weight: Font.Bold
        }
        WText {
            width: parent.width
            text: Weather.city || Weather.condition
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }
        WText {
            width: parent.width
            text: Weather.city ? Weather.condition + " · " + Weather.humidity + " · " + Weather.wind : ""
            color: root.fgMuted
            font.pixelSize: 13
        }
    }

    Item {
        id: badge
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        width: 80
        height: 80

        Cookie {
            anchors.fill: parent
            size: 80
            lobes: 12
            depth: 0.08
            color: root.accent
        }

        Icon {
            anchors.centerIn: parent
            path: Weather.icon
            size: 38
            color: root.onAccent
        }
    }
}
