import QtQuick
import Quickshell
import qs.config

// Big clock: hour on top, minutes below and the date. No background by default.
WidgetCard {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        anchors.centerIn: parent
        spacing: -34

        WText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH")
            color: root.accent
            font.pixelSize: 140
            font.weight: Font.Black
        }
        WText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "mm")
            color: root.fg
            font.pixelSize: 140
            font.weight: Font.Black
        }
        WText {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 34
            text: {
                const day = Qt.locale("en_US").toString(clock.date, "ddd").replace(".", "");
                return day.charAt(0).toUpperCase() + day.slice(1) + ", " + Qt.formatDateTime(clock.date, "dd/MM");
            }
            color: root.fgDim
            font.pixelSize: 22
            font.weight: Font.DemiBold
        }
    }
}
