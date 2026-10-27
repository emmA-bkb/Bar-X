import QtQuick
import Quickshell
import qs.config

// Relogio grande: hora em cima, minuto embaixo e a data. Por padrao sem fundo.
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
                const day = Qt.locale("pt_BR").toString(clock.date, "ddd").replace(".", "");
                return day.charAt(0).toUpperCase() + day.slice(1) + ", " + Qt.formatDateTime(clock.date, "dd/MM");
            }
            color: root.fgDim
            font.pixelSize: 22
            font.weight: Font.DemiBold
        }
    }
}
