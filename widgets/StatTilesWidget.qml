import QtQuick
import qs.config
import qs.components
import qs.services

// CPU, RAM e disco em blocos separados, cada um com o icone numa florzinha.
WidgetCard {
    id: root

    plain: true

    Row {
        anchors.fill: parent
        spacing: 15

        Repeater {
            model: [
                {
                    "label": "CPU",
                    "value": SysStats.cpu,
                    "icon": Icons.chip
                },
                {
                    "label": "RAM",
                    "value": SysStats.ram,
                    "icon": Icons.memory
                },
                {
                    "label": "Disco",
                    "value": SysStats.disk,
                    "icon": Icons.disk
                }
            ]

            delegate: Rectangle {
                id: tile

                required property var modelData

                width: (root.width - 30) / 3
                height: root.height
                radius: 28
                color: Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, root.backgroundOpacity)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.13 * Math.min(1, root.backgroundOpacity * 1.5))

                Item {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    width: 44
                    height: 44

                    Cookie {
                        anchors.fill: parent
                        size: 44
                        lobes: 12
                        depth: 0.09
                        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.85)
                    }

                    Icon {
                        anchors.centerIn: parent
                        path: tile.modelData.icon
                        size: 20
                        color: root.onAccent
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 18
                    spacing: 0

                    WText {
                        text: Math.round(tile.modelData.value * 100) + "%"
                        font.pixelSize: 32
                        font.weight: Font.Bold
                    }
                    WText {
                        text: tile.modelData.label
                        color: root.fgDim
                        font.pixelSize: 15
                    }
                }
            }
        }
    }
}
