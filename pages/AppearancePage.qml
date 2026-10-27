import QtQuick
import qs.config
import qs.components
import qs.services

// Cor de destaque e opcoes gerais.
Flickable {
    id: root

    contentHeight: content.height

    readonly property var backgrounds: ["#131618", "#000000", "#1b2030", "#1d2a26", "#2a1d26", "#2b231a", "#2a1b1b", "#241f33", "#e8e6e3"]

    // Cor de destaque do app (e do preset ativo)
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
                        text: "Cor de destaque"
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

                    // Cor livre (RGB)
                    CustomColorButton {
                        size: 36
                        current: Config.options.accent
                        presets: Ui.accents
                        onClicked: Ui.pickColor("Cor de destaque", Config.options.accent, hex => root.setAccent(hex))
                    }
                }
            }
        }

        // ---------- Transparencia (efeito vidro) ----------
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
                                text: "Barra e widgets transparentes (vidro)"
                            }
                            StyledText {
                                text: glassCard.activePreset ? "Vale para o preset \"" + glassCard.activePreset.name + "\"" : "Vale quando nenhum preset está ativo"
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
                        text: "Intensidade  " + Math.round(glassSlider.shownValue) + "%"
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
                    text: "O fundo atrás fica desfocado. Em wallpapers claros o texto fica escuro sozinho para dar para ler."
                    color: Theme.textMuted
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }
        }

        // ---------- Cores dos widgets ----------
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
                                text: "Cores dos widgets combinando com o wallpaper"
                            }
                            StyledText {
                                text: Config.options.widgetColorMode === "wallpaper" ? "Mudam sozinhas quando o wallpaper muda" : "Desligado: escolha as cores abaixo"
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

                // Automatico: mostra as cores tiradas do wallpaper atual
                Row {
                    visible: Config.options.widgetColorMode === "wallpaper"
                    spacing: 10

                    Repeater {
                        model: [
                            {
                                "key": "accent",
                                "label": "Destaque"
                            },
                            {
                                "key": "bg",
                                "label": "Fundo"
                            },
                            {
                                "key": "fg",
                                "label": "Texto"
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

                // Manual: destaque e fundo
                Column {
                    visible: Config.options.widgetColorMode !== "wallpaper"
                    spacing: 10

                    StyledText {
                        text: "Destaque"
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
                            onClicked: Ui.pickColor("Destaque dos widgets", Config.options.widgetAccent || Config.options.accent, hex => Config.options.widgetAccent = hex)
                        }
                    }

                    StyledText {
                        topPadding: 4
                        text: "Fundo"
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
                            onClicked: Ui.pickColor("Fundo dos widgets", Config.options.widgetBackground, hex => Config.options.widgetBackground = hex)
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 34

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Usar as mesmas cores na barra do Uix"
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
            title: "Cidade do clima"
            subtitle: "Usada no widget de clima. Vazio = detectar automaticamente"

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
                        text: "Automático"
                        color: Theme.textMuted
                    }
                }
            }
        }

        SettingRow {
            width: parent.width
            icon: Icons.sparkle
            title: "Animações"
            subtitle: "Transições suaves na interface"

            Toggle {
                checked: Config.options.animations
                onToggled: c => Config.options.animations = c
            }
        }

        SettingRow {
            width: parent.width
            icon: Icons.presets
            title: "Aplicar preset ao iniciar a sessão"
            subtitle: "Restaura wallpaper e barra do preset ativo no login"

            Toggle {
                checked: Config.options.applyOnLogin
                onToggled: c => Config.options.applyOnLogin = c
            }
        }
    }
}
