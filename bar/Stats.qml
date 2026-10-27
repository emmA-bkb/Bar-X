import QtQuick
import Quickshell
import qs.config
import qs.components
import qs.services

// CPU, RAM and SSD. Clicking RAM runs UIX_SYSTEM_MONITOR from .env (e.g. a terminal with btop).
// On the side bar it is compact: small label above the number.
BarGroup {
    spacing: BarStyle.vertical ? 8 : BarStyle.minimal ? 10 : 12

    Repeater {
        model: [
            {
                "label": "CPU",
                "value": SysStats.cpu,
                "command": []
            },
            {
                "label": "RAM",
                "value": SysStats.ram,
                "command": Env.get("UIX_SYSTEM_MONITOR", "") ? ["bash", "-c", Env.get("UIX_SYSTEM_MONITOR", "")] : []
            },
            {
                "label": "SSD",
                "value": SysStats.disk,
                "command": []
            }
        ]

        delegate: Item {
            id: stat

            required property var modelData

            implicitWidth: BarStyle.vertical ? statColumn.implicitWidth : statRow.implicitWidth
            implicitHeight: BarStyle.vertical ? statColumn.implicitHeight : statRow.implicitHeight

            Row {
                id: statRow
                visible: !BarStyle.vertical
                spacing: 5

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: stat.modelData.label
                    color: BarStyle.accent
                    font.weight: Font.DemiBold
                    font.pixelSize: BarStyle.minimal ? 11 : 12
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(stat.modelData.value * 100) + "%"
                    color: BarStyle.text
                    font.pixelSize: BarStyle.minimal ? 11 : 13
                }
            }

            Column {
                id: statColumn
                visible: BarStyle.vertical

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: stat.modelData.label
                    color: BarStyle.accent
                    font.weight: Font.DemiBold
                    font.pixelSize: 9
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(stat.modelData.value * 100)
                    color: BarStyle.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: stat.modelData.command.length > 0
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(stat.modelData.command)
            }
        }
    }
}
