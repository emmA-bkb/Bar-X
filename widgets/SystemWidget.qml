import QtQuick
import qs.config
import qs.services

WidgetCard {
    id: root

    Row {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 18

        Repeater {
            model: [
                {
                    "label": "CPU",
                    "value": SysStats.cpu
                },
                {
                    "label": "RAM",
                    "value": SysStats.ram
                },
                {
                    "label": "Disk",
                    "value": SysStats.disk
                }
            ]

            delegate: Column {
                id: stat

                required property var modelData

                width: (parent.width - 36) / 3
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                WText {
                    text: stat.modelData.label
                    color: root.fgMuted
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                WText {
                    text: Math.round(stat.modelData.value * 100) + "%"
                    font.pixelSize: 34
                    font.weight: Font.Bold
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: "#26ffffff"

                    Rectangle {
                        width: parent.width * stat.modelData.value
                        height: parent.height
                        radius: 3
                        color: root.accent

                        Behavior on width {
                            NumberAnimation {
                                duration: 600
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }
    }
}
