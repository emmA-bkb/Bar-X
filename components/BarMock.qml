import QtQuick
import qs.config

// Miniature taskbar drawn over the wallpaper preview.
Item {
    id: root

    property string barStyle: "floating"
    property color accent: Theme.accent
    property real unit: 1 // scale: 1 = small card

    property real glass: 0
    readonly property color barColor: Qt.rgba(0.063, 0.071, 0.078, 0.82 * (1 - glass * 0.8))
    readonly property color tonalTint: Qt.tint("#101214", Qt.rgba(accent.r, accent.g, accent.b, 0.3))
    readonly property color tonalColor: Qt.rgba(tonalTint.r, tonalTint.g, tonalTint.b, 0.85 * (1 - glass * 0.8))
    readonly property real h: 12 * unit

    component Dot: Rectangle {
        property bool on: false
        width: 5 * root.unit
        height: width
        radius: width / 2
        color: on ? root.accent : "#80ffffff"
    }

    component Pill: Rectangle {
        width: 14 * root.unit
        height: 4 * root.unit
        radius: height / 2
        color: "#b0ffffff"
    }

    // Floating
    Rectangle {
        visible: root.barStyle === "floating"
        x: 6 * root.unit
        y: 6 * root.unit
        width: root.width - 12 * root.unit
        height: root.h
        radius: height / 2
        color: root.barColor

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 5 * root.unit
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3 * root.unit
            Dot { on: true }
            Dot {}
            Dot {}
        }
        Pill {
            anchors.centerIn: parent
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 5 * root.unit
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3 * root.unit
            Dot {}
            Dot { on: true }
        }
    }

    // Islands (and Tonal, with tinted pills)
    Item {
        visible: root.barStyle === "island" || root.barStyle === "tonal"
        x: 6 * root.unit
        y: 6 * root.unit
        width: root.width - 12 * root.unit
        height: root.h

        Rectangle {
            width: 30 * root.unit
            height: parent.height
            radius: height / 2
            color: root.barStyle === "tonal" ? root.tonalColor : root.barColor
            Row {
                anchors.centerIn: parent
                spacing: 3 * root.unit
                Dot { on: true }
                Dot {}
                Dot {}
            }
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 26 * root.unit
            height: parent.height
            radius: height / 2
            color: root.barStyle === "tonal" ? root.tonalColor : root.barColor
            Pill {
                anchors.centerIn: parent
            }
        }
        Rectangle {
            anchors.right: parent.right
            width: 22 * root.unit
            height: parent.height
            radius: height / 2
            color: root.barStyle === "tonal" ? root.tonalColor : root.barColor
            Row {
                anchors.centerIn: parent
                spacing: 3 * root.unit
                Dot {}
                Dot { on: true }
            }
        }
    }

    // Minimal
    Rectangle {
        visible: root.barStyle === "minimal"
        width: root.width
        height: 9 * root.unit
        color: root.barColor

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 6 * root.unit
            anchors.verticalCenter: parent.verticalCenter
            width: 10 * root.unit
            height: 3 * root.unit
            radius: height / 2
            color: root.accent
        }
        Pill {
            anchors.centerIn: parent
            height: 3 * root.unit
        }
    }

    readonly property bool sideStyle: barStyle.startsWith("side")
    readonly property bool sideIslands: barStyle === "side-island" || barStyle === "side-tonal"

    // Bottom dock (small and centered)
    Rectangle {
        visible: root.barStyle.startsWith("bottom")
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5 * root.unit
        width: dockRow.width + 12 * root.unit
        height: 13 * root.unit
        radius: height / 2
        color: root.barStyle === "bottom-tonal" ? root.tonalColor : root.barColor

        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: 3 * root.unit
            Dot { on: true }
            Dot {}
            Dot {}
            Rectangle {
                width: 1
                height: 6 * root.unit
                color: "#40ffffff"
            }
            Repeater {
                model: 4
                Rectangle {
                    width: 6 * root.unit
                    height: width
                    radius: 2 * root.unit
                    color: "#90ffffff"
                }
            }
            Pill {}
        }
    }

    // Side bar, full or minimal
    Rectangle {
        visible: root.barStyle === "side" || root.barStyle === "side-minimal"
        readonly property bool thin: root.barStyle === "side-minimal"
        x: thin ? 0 : 4 * root.unit
        y: thin ? 0 : 4 * root.unit
        width: (thin ? 9 : 11) * root.unit
        height: root.height - (thin ? 0 : 8 * root.unit)
        radius: thin ? 0 : width / 2
        color: root.barColor

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 4 * root.unit
            spacing: 3 * root.unit
            Dot { on: true }
            Dot {}
            Dot {}
        }
        Rectangle {
            anchors.centerIn: parent
            width: 4 * root.unit
            height: 9 * root.unit
            radius: 2 * root.unit
            color: "#b0ffffff"
        }
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4 * root.unit
            spacing: 3 * root.unit
            Dot {}
            Dot { on: true }
        }
    }

    // Side bar in islands (and tonal): three separate pills
    Item {
        visible: root.sideIslands
        x: 4 * root.unit
        y: 4 * root.unit
        width: 11 * root.unit
        height: root.height - 8 * root.unit

        readonly property color pillColor: root.barStyle === "side-tonal" ? root.tonalColor : root.barColor

        Rectangle {
            width: parent.width
            height: topDots.height + 8 * root.unit
            radius: width / 2
            color: parent.pillColor
            Column {
                id: topDots
                anchors.centerIn: parent
                spacing: 3 * root.unit
                Dot { on: true }
                Dot {}
                Dot {}
            }
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 15 * root.unit
            radius: width / 2
            color: parent.pillColor
            Rectangle {
                anchors.centerIn: parent
                width: 4 * root.unit
                height: 8 * root.unit
                radius: 2 * root.unit
                color: "#b0ffffff"
            }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: bottomDots.height + 8 * root.unit
            radius: width / 2
            color: parent.pillColor
            Column {
                id: bottomDots
                anchors.centerIn: parent
                spacing: 3 * root.unit
                Dot {}
                Dot { on: true }
            }
        }
    }
}
