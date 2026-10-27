import QtQuick
import Quickshell
import qs.config
import qs.components

// Clock. Horizontal: "HH:mm • dd/MM"; on the side bar the hour above the minutes.
Item {
    implicitWidth: BarStyle.vertical ? BarStyle.itemHeight : row.implicitWidth
    implicitHeight: BarStyle.vertical ? column.implicitHeight : BarStyle.itemHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        id: row
        visible: !BarStyle.vertical
        anchors.centerIn: parent
        spacing: 8

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: BarStyle.text
            font.weight: Font.DemiBold
            font.pixelSize: BarStyle.minimal ? 12 : 14
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: "•"
            color: BarStyle.accent
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "dd/MM")
            color: BarStyle.textDim
            font.pixelSize: BarStyle.minimal ? 12 : 14
        }
    }

    Column {
        id: column
        visible: BarStyle.vertical
        anchors.centerIn: parent
        spacing: -2

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH")
            color: BarStyle.accent
            font.weight: Font.Bold
            font.pixelSize: 15
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "mm")
            color: BarStyle.text
            font.weight: Font.Bold
            font.pixelSize: 15
        }
    }
}
