import QtQuick
import qs.config

// Free color picker: saturation/brightness square, hue bar,
// R/G/B controls and hex code. Open it with open(title, color).
Rectangle {
    id: root

    property string title: "Choose color"
    // Current color in HSV (the hue is kept even on gray)
    property real hue: 0
    property real sat: 1
    property real val: 1
    readonly property color current: Qt.hsva(hue, sat, val, 1)

    signal accepted(string hex)
    signal canceled

    function toHex(c) {
        return "#" + [c.r, c.g, c.b].map(x => Math.round(x * 255).toString(16).padStart(2, "0")).join("");
    }

    function setColor(c) {
        const col = Qt.color(c);
        if (col.hsvHue >= 0)
            hue = col.hsvHue;
        sat = col.hsvSaturation;
        val = col.hsvValue;
    }

    function open(newTitle, c) {
        title = newTitle;
        setColor(c);
        hexInput.text = toHex(current);
    }

    function setRgb(r, g, b) {
        setColor(Qt.rgba(r / 255, g / 255, b / 255, 1));
        hexInput.text = toHex(current);
    }

    width: 380
    height: column.height + 40
    radius: Theme.radius
    color: Theme.surface
    border.width: 1
    border.color: Theme.border

    // Swallow clicks so clicking inside doesn't close it
    MouseArea {
        anchors.fill: parent
    }

    Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        spacing: 14

        StyledText {
            text: root.title
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        // Saturation (left -> right) and brightness (top -> bottom)
        Rectangle {
            id: svBox
            width: parent.width
            height: 180
            radius: Theme.radiusSmall
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: "white"
                }
                GradientStop {
                    position: 1
                    color: Qt.hsva(root.hue, 1, 1, 1)
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "transparent"
                    }
                    GradientStop {
                        position: 1
                        color: "black"
                    }
                }
            }

            Rectangle {
                x: root.sat * svBox.width - width / 2
                y: (1 - root.val) * svBox.height - height / 2
                width: 18
                height: 18
                radius: 9
                color: root.current
                border.width: 3
                border.color: "white"
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true
                cursorShape: Qt.CrossCursor
                function pick(mouse) {
                    root.sat = Math.max(0, Math.min(1, mouse.x / width));
                    root.val = Math.max(0, Math.min(1, 1 - mouse.y / height));
                    hexInput.text = root.toHex(root.current);
                }
                onPressed: mouse => pick(mouse)
                onPositionChanged: mouse => pick(mouse)
            }
        }

        // Hue
        Rectangle {
            id: hueBar
            width: parent.width
            height: 16
            radius: 8
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: "#ff0000"
                }
                GradientStop {
                    position: 0.167
                    color: "#ffff00"
                }
                GradientStop {
                    position: 0.333
                    color: "#00ff00"
                }
                GradientStop {
                    position: 0.5
                    color: "#00ffff"
                }
                GradientStop {
                    position: 0.667
                    color: "#0000ff"
                }
                GradientStop {
                    position: 0.833
                    color: "#ff00ff"
                }
                GradientStop {
                    position: 1
                    color: "#ff0000"
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: root.hue * hueBar.width - width / 2
                width: 20
                height: 20
                radius: 10
                color: Qt.hsva(root.hue, 1, 1, 1)
                border.width: 3
                border.color: "white"
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                preventStealing: true
                cursorShape: Qt.PointingHandCursor
                function pick(mouse) {
                    root.hue = Math.max(0, Math.min(0.9999, (mouse.x - 6) / hueBar.width));
                    hexInput.text = root.toHex(root.current);
                }
                onPressed: mouse => pick(mouse)
                onPositionChanged: mouse => pick(mouse)
            }
        }

        // R, G, B
        Repeater {
            model: [
                {
                    "label": "R",
                    "tint": "#ff6b6b"
                },
                {
                    "label": "G",
                    "tint": "#7be08b"
                },
                {
                    "label": "B",
                    "tint": "#6ba8ff"
                }
            ]

            delegate: Row {
                id: channel

                required property var modelData
                required property int index
                readonly property real value: Math.round([root.current.r, root.current.g, root.current.b][index] * 255)

                spacing: 10

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    text: channel.modelData.label
                    color: channel.modelData.tint
                    font.weight: Font.Bold
                }

                StyledSlider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: column.width - 80
                    from: 0
                    to: 255
                    stepSize: 1
                    value: channel.value
                    onMoved: v => {
                        const rgb = [root.current.r, root.current.g, root.current.b].map(x => Math.round(x * 255));
                        rgb[channel.index] = v;
                        root.setRgb(rgb[0], rgb[1], rgb[2]);
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    horizontalAlignment: Text.AlignRight
                    text: channel.value
                    color: Theme.textDim
                    font.pixelSize: 12
                }
            }
        }

        // Preview + hex + buttons
        Row {
            width: parent.width
            spacing: 10

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40
                radius: 20
                color: root.current
                border.width: 1
                border.color: Theme.border
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 110
                height: 40
                radius: Theme.radiusSmall
                color: hexInput.activeFocus ? Theme.surfaceHigh : Theme.surfaceHover
                border.width: 1
                border.color: hexInput.activeFocus ? Theme.alpha(Theme.accent, 0.6) : "transparent"

                TextInput {
                    id: hexInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    selectionColor: Theme.alpha(Theme.accent, 0.4)
                    font.family: "Adwaita Mono"
                    font.pixelSize: 13
                    maximumLength: 7
                    selectByMouse: true
                    onTextEdited: {
                        const t = text.trim();
                        if (/^#?[0-9a-fA-F]{6}$/.test(t))
                            root.setColor(t.startsWith("#") ? t : "#" + t);
                    }
                }
            }

            Item {
                width: parent.width - 40 - 110 - cancel.width - ok.width - 40
                height: 1
            }

            StyledButton {
                id: cancel
                anchors.verticalCenter: parent.verticalCenter
                text: "Cancel"
                onClicked: root.canceled()
            }

            StyledButton {
                id: ok
                anchors.verticalCenter: parent.verticalCenter
                text: "Use"
                primary: true
                onClicked: root.accepted(root.toHex(root.current))
            }
        }
    }
}
