import QtQuick
import Quickshell
import qs.config

WidgetCard {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        anchors.centerIn: parent
        spacing: 2

        Row {
            anchors.horizontalCenter: parent.horizontalCenter

            WText {
                text: Qt.formatDateTime(clock.date, "HH")
                font.pixelSize: 92
                font.weight: Font.Bold
            }
            WText {
                text: ":"
                color: root.fgMuted
                font.pixelSize: 92
                font.weight: Font.Bold
            }
            WText {
                text: Qt.formatDateTime(clock.date, "mm")
                color: root.accent
                font.pixelSize: 92
                font.weight: Font.Bold
            }
        }

        WText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.locale("en_US").toString(clock.date, "dddd, MMMM d")
            color: root.fgDim
            font.pixelSize: 20
        }
    }
}
