import QtQuick
import Quickshell
import qs.config

// Calendario so da semana atual, com o mes numa pilula.
WidgetCard {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    readonly property date today: clock.date
    readonly property var week: {
        const start = new Date(today.getFullYear(), today.getMonth(), today.getDate() - today.getDay());
        const list = [];
        for (let i = 0; i < 7; i++)
            list.push(new Date(start.getFullYear(), start.getMonth(), start.getDate() + i));
        return list;
    }

    Rectangle {
        id: monthPill
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 20
        anchors.topMargin: 16
        width: monthText.implicitWidth + 24
        height: 28
        radius: 14
        color: root.accent

        WText {
            id: monthText
            anchors.centerIn: parent
            text: {
                const m = Qt.locale("pt_BR").standaloneMonthName(root.today.getMonth());
                return m.charAt(0).toUpperCase() + m.slice(1) + " " + root.today.getFullYear();
            }
            color: root.onAccent
            font.pixelSize: 14
            font.weight: Font.Bold
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14

        Repeater {
            model: root.week

            delegate: Column {
                id: day

                required property var modelData
                required property int index
                readonly property bool isToday: modelData.getDate() === root.today.getDate() && modelData.getMonth() === root.today.getMonth()

                width: 46
                spacing: 4

                WText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: ["D", "S", "T", "Q", "Q", "S", "S"][day.index]
                    color: root.fgMuted
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 38
                    height: 38

                    Rectangle {
                        anchors.fill: parent
                        radius: 19
                        color: root.accent
                        visible: day.isToday
                    }

                    WText {
                        anchors.centerIn: parent
                        text: day.modelData.getDate()
                        color: day.isToday ? root.onAccent : root.fg
                        font.pixelSize: 16
                        font.weight: day.isToday ? Font.Bold : Font.Normal
                    }
                }
            }
        }
    }
}
