import QtQuick
import qs.config

// Tiny drawing of a menu style on a fake desktop with a top bar (Menu page cards).
Rectangle {
    id: root

    property string style: "panel"
    readonly property color accent: Theme.accent
    readonly property color glass: "#cc15191c"

    radius: Theme.radiusSmall
    clip: true
    gradient: Gradient {
        GradientStop {
            position: 0
            color: Qt.darker(Theme.alpha(root.accent, 1), 3.2)
        }
        GradientStop {
            position: 1
            color: "#101315"
        }
    }

    // Top bar with the menu button
    Rectangle {
        x: 6
        y: 5
        width: parent.width - 12
        height: 9
        radius: 4
        color: root.glass

        Rectangle {
            x: 3
            anchors.verticalCenter: parent.verticalCenter
            width: 5
            height: 5
            radius: 2.5
            color: root.accent
        }
    }

    // Panel: a big card under the button with search, a grid and power buttons
    Item {
        visible: root.style === "panel"
        anchors.fill: parent

        Rectangle {
            x: 6
            y: 18
            width: parent.width * 0.55
            height: parent.height - 24
            radius: 6
            color: root.glass
            border.color: "#26ffffff"

            Rectangle {
                x: 5
                y: 5
                width: parent.width - 10
                height: 7
                radius: 3.5
                color: "#33ffffff"
            }

            Grid {
                x: 6
                y: 17
                columns: 4
                spacing: 5
                Repeater {
                    model: 8
                    Rectangle {
                        width: 9
                        height: 9
                        radius: 3
                        color: index < 4 ? root.accent : "#4dffffff"
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 5
                spacing: 3
                Repeater {
                    model: 3
                    Rectangle {
                        width: 10
                        height: 5
                        radius: 2.5
                        color: "#40ffffff"
                    }
                }
            }
        }
    }

    // Spotlight: a search bar in the middle and results below
    Item {
        visible: root.style === "spotlight"
        anchors.fill: parent

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.26
            width: parent.width * 0.62
            height: 12
            radius: 6
            color: root.glass
            border.color: Theme.alpha(root.accent, 0.7)
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.26 + 16
            width: parent.width * 0.62
            height: 30
            radius: 6
            color: root.glass

            Column {
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Repeater {
                    model: 3
                    Rectangle {
                        width: index === 0 ? 50 : 36
                        height: 4
                        radius: 2
                        color: index === 0 ? root.accent : "#40ffffff"
                    }
                }
            }
        }
    }

    // Curtain: a strip of icons hanging from the button
    Rectangle {
        visible: root.style === "curtain"
        x: 5
        y: 17
        width: 14
        height: parent.height - 28
        radius: 5
        color: "#8c000000"
        border.color: "#40ffffff"

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 4
            spacing: 4
            Repeater {
                model: 6
                Rectangle {
                    width: 8
                    height: 8
                    radius: 3
                    color: index === 1 ? root.accent : "#80ffffff"
                    // the hovered one floats a little
                    x: 0
                    transform: Translate {
                        y: index === 1 ? -1.5 : 0
                    }
                }
            }
        }
    }

    // Orbit: bubbles on an arc around the button
    Item {
        visible: root.style === "orbit"
        anchors.fill: parent

        Rectangle {
            x: 8 - width / 2
            y: 9 - height / 2
            width: 120
            height: 120
            radius: 60
            color: "transparent"
            border.color: Theme.alpha(root.accent, 0.4)
        }

        Repeater {
            model: 5
            Rectangle {
                readonly property real a: (8 + index * 18.5) * Math.PI / 180
                width: 14
                height: 14
                radius: 7
                x: 8 + Math.cos(a) * 60 - 7
                y: 9 + Math.sin(a) * 60 - 7
                color: root.glass
                border.color: index === 2 ? root.accent : "#40ffffff"

                Rectangle {
                    anchors.centerIn: parent
                    width: 6
                    height: 6
                    radius: 2
                    color: index === 2 ? root.accent : "#99ffffff"
                }
            }
        }
    }
}
