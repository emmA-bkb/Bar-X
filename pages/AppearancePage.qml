import QtQuick
import qs.config
import qs.components
import qs.services

// Accent color and general options.
Flickable {
    id: root

    contentHeight: content.height

    readonly property var backgrounds: ["#131618", "#000000", "#1b2030", "#1d2a26", "#2a1d26", "#2b231a", "#2a1b1b", "#241f33", "#e8e6e3"]

    // App accent color (and the active preset's)
    function setAccent(hex) {
        Config.options.accent = hex;
        if (Config.preset(Config.options.activePreset))
            Config.updatePreset(Config.options.activePreset, {
                "accent": hex
            });
    }
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: content
        width: root.width
        spacing: 12

        Rectangle {
            width: parent.width
            height: 112
            radius: Theme.radiusMedium
            color: Theme.surface

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Row {
                    spacing: 14

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        path: Icons.palette
                        size: 19
                        color: Theme.textDim
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Accent color"
                    }
                }

                Row {
                    spacing: 10

                    Repeater {
                        model: Ui.accents

                        delegate: Rectangle {
                            id: swatch

                            required property string modelData
                            readonly property bool selected: Config.options.accent === modelData

                            width: 36
                            height: 36
                            radius: 18
                            color: modelData
                            scale: swatchMouse.containsMouse ? 1.1 : 1
                            border.width: selected ? 3 : 0
                            border.color: Theme.text

                            Behavior on scale {
                                NumberAnimation {
                                    duration: Theme.animFast
                                }
                            }

                            Icon {
                                anchors.centerIn: parent
                                visible: swatch.selected
                                path: Icons.check
                                size: 18
                                color: Theme.accentText
                            }

                            MouseArea {
                                id: swatchMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setAccent(swatch.modelData)
                            }
                        }
                    }

                    // Free color (RGB)
                    CustomColorButton {
                        size: 36
                        current: Config.options.accent
                        presets: Ui.accents
                        onClicked: Ui.pickColor("Accent color", Config.options.accent, hex => root.setAccent(hex))
                    }
                }
            }
        }

        // ---------- Transparency (glass effect) ----------
        Rectangle {
            readonly property real amount: Config.currentTransparency()
            readonly property var activePreset: Config.preset(Config.options.activePreset)

            id: glassCard
            width: parent.width
            height: glassColumn.height + 36
            radius: Theme.radiusMedium
            color: Theme.surface

            Column {
                id: glassColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                spacing: 14

                Item {
                    width: parent.width
                    height: 40

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            path: Icons.sparkle
                            size: 19
                            color: Theme.textDim
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            StyledText {
                                text: "Transparent bar and widgets (glass)"
                            }
                            StyledText {
                                text: glassCard.activePreset ? "Applies to the preset \"" + glassCard.activePreset.name + "\"" : "Applies when no preset is active"
                                color: Theme.textMuted
                                font.pixelSize: 12
                            }
                        }
                    }

                    Toggle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: glassCard.amount > 0
                        onToggled: c => Config.setTransparency(c ? 0.6 : 0)
                    }
                }

                Item {
                    visible: glassCard.amount > 0
                    width: parent.width
                    height: 30

                    StyledText {
                        id: glassLabel
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 130
                        text: "Intensity  " + Math.round(glassSlider.shownValue) + "%"
                        color: Theme.textDim
                        font.pixelSize: 12
                    }

                    StyledSlider {
                        id: glassSlider
                        anchors.left: glassLabel.right
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        from: 10
                        to: 100
                        stepSize: 5
                        value: glassCard.amount * 100
                        onCommitted: v => Config.setTransparency(v / 100)
                    }
                }

                StyledText {
                    visible: glassCard.amount > 0
                    width: parent.width
                    text: "The background behind is blurred. On light wallpapers the text turns dark by itself so it stays readable."
                    color: Theme.textMuted
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }
        }

        // ---------- Widget colors ----------
        Rectangle {
            width: parent.width
            height: colorsColumn.height + 36
            radius: Theme.radiusMedium
            color: Theme.surface

            Column {
                id: colorsColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                spacing: 14

                Item {
                    width: parent.width
                    height: 40

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            path: Icons.widgets
                            size: 19
                            color: Theme.textDim
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            StyledText {
                                text: "Widget colors matching the wallpaper"
                            }
                            StyledText {
                                text: Config.options.widgetColorMode === "wallpaper" ? "They change by themselves when the wallpaper changes" : "Off: choose the colors below"
                                color: Theme.textMuted
                                font.pixelSize: 12
                            }
                        }
                    }

                    Toggle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: Config.options.widgetColorMode === "wallpaper"
                        onToggled: c => Config.options.widgetColorMode = c ? "wallpaper" : "manual"
                    }
                }

                // Automatic: shows the colors taken from the current wallpaper
                Row {
                    visible: Config.options.widgetColorMode === "wallpaper"
                    spacing: 10

                    Repeater {
                        model: [
                            {
                                "key": "accent",
                                "label": "Accent"
                            },
                            {
                                "key": "bg",
                                "label": "Background"
                            },
                            {
                                "key": "fg",
                                "label": "Text"
                            }
                        ]

                        delegate: Row {
                            required property var modelData
                            spacing: 8

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28
                                height: 28
                                radius: 14
                                color: Colors.current ? Colors.current[parent.modelData.key] : "transparent"
                                border.width: 1
                                border.color: Theme.border
                            }
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                rightPadding: 10
                                text: parent.modelData.label
                                color: Theme.textDim
                                font.pixelSize: 12
                            }
                        }
                    }
                }

                // Manual: accent and background
                Column {
                    visible: Config.options.widgetColorMode !== "wallpaper"
                    spacing: 10

                    StyledText {
                        text: "Accent"
                        color: Theme.textDim
                        font.pixelSize: 12
                    }
                    Row {
                        spacing: 8

                        Swatch {
                            color: Theme.surfaceHigh
                            label: "Auto"
                            selected: Config.options.widgetAccent === ""
                            onClicked: Config.options.widgetAccent = ""
                        }
                        Repeater {
                            model: Ui.accents
                            delegate: Swatch {
                                required property string modelData
                                color: modelData
                                selected: Config.options.widgetAccent === modelData
                                onClicked: Config.options.widgetAccent = modelData
                            }
                        }
                        CustomColorButton {
                            current: Config.options.widgetAccent
                            presets: Ui.accents
                            onClicked: Ui.pickColor("Widget accent", Config.options.widgetAccent || Config.options.accent, hex => Config.options.widgetAccent = hex)
                        }
                    }

                    StyledText {
                        topPadding: 4
                        text: "Background"
                        color: Theme.textDim
                        font.pixelSize: 12
                    }
                    Row {
                        spacing: 8

                        Repeater {
                            model: root.backgrounds
                            delegate: Swatch {
                                required property string modelData
                                color: modelData
                                selected: Config.options.widgetBackground === modelData
                                onClicked: Config.options.widgetBackground = modelData
                            }
                        }
                        CustomColorButton {
                            current: Config.options.widgetBackground
                            presets: root.backgrounds
                            onClicked: Ui.pickColor("Widget background", Config.options.widgetBackground, hex => Config.options.widgetBackground = hex)
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 34

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Use the same colors on the Bar X taskbar"
                    }
                    Toggle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: Config.options.dynamicBarColors
                        onToggled: c => Config.options.dynamicBarColors = c
                    }
                }
            }
        }

        SettingRow {
            width: parent.width
            icon: Icons.cloud
            title: "Weather city"
            subtitle: "Used by the weather widget. Empty = detect automatically"

            Rectangle {
                width: 220
                height: 34
                radius: Theme.radiusSmall
                color: cityInput.activeFocus ? Theme.surfaceHigh : Theme.surfaceHover
                border.width: 1
                border.color: cityInput.activeFocus ? Theme.alpha(Theme.accent, 0.6) : "transparent"

                TextInput {
                    id: cityInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    text: Config.options.weatherCity
                    color: Theme.text
                    selectionColor: Theme.alpha(Theme.accent, 0.4)
                    font.family: Theme.font
                    font.pixelSize: 13
                    clip: true
                    selectByMouse: true
                    onEditingFinished: {
                        if (text.trim() !== Config.options.weatherCity)
                            Config.options.weatherCity = text.trim();
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: cityInput.text === "" && !cityInput.activeFocus
                        text: "Automatic"
                        color: Theme.textMuted
                    }
                }
            }
        }

        SettingRow {
            width: parent.width
            icon: Icons.sparkle
            title: "Animations"
            subtitle: "Smooth transitions in the interface"

            Toggle {
                checked: Config.options.animations
                onToggled: c => Config.options.animations = c
            }
        }

        SettingRow {
            width: parent.width
            icon: Icons.presets
            title: "Apply preset on login"
            subtitle: "Restores the active preset's wallpaper and bar on login"

            Toggle {
                checked: Config.options.applyOnLogin
                onToggled: c => Config.options.applyOnLogin = c
            }
        }
    }
}
