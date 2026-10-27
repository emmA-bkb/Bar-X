import QtQuick
import Quickshell
import qs.config

WidgetCard {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    readonly property date today: clock.date
    readonly property int month: today.getMonth()
    readonly property int year: today.getFullYear()

    // 42 days (6 weeks) starting on the Sunday before the 1st
    readonly property var days: {
        const start = new Date(year, month, 1).getDay();
        const list = [];
        for (let i = 0; i < 42; i++)
            list.push(new Date(year, month, 1 - start + i));
        return list;
    }

    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 10

        Row {
            width: parent.width

            WText {
                width: parent.width - yearText.width
                text: {
                    const m = Qt.locale("en_US").standaloneMonthName(root.month);
                    return m.charAt(0).toUpperCase() + m.slice(1);
                }
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }
            WText {
                id: yearText
                text: root.year
                color: root.accent
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }
        }

        Grid {
            columns: 7
            columnSpacing: 0
            rowSpacing: 0

            Repeater {
                model: ["S", "M", "T", "W", "T", "F", "S"]

                delegate: WText {
                    required property string modelData
                    width: 40
                    height: 28
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: root.fgMuted
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
            }

            Repeater {
                model: root.days

                delegate: Item {
                    id: day

                    required property var modelData
                    readonly property bool inMonth: modelData.getMonth() === root.month
                    readonly property bool isToday: inMonth && modelData.getDate() === root.today.getDate()

                    width: 40
                    height: 37

                    Rectangle {
                        anchors.centerIn: parent
                        width: 34
                        height: 34
                        radius: 17
                        color: root.accent
                        visible: day.isToday
                    }

                    WText {
                        anchors.centerIn: parent
                        text: day.modelData.getDate()
                        font.pixelSize: 15
                        font.weight: day.isToday ? Font.Bold : Font.Normal
                        color: day.isToday ? root.onAccent : day.inMonth ? root.fg : "#40ffffff"
                    }
                }
            }
        }
    }
}
