import QtQuick
import Quickshell
import qs.config
import qs.components
import qs.services
import qs.bar

// Qual barra usar (Waybar ou a do Uix) e o estilo da barra do preset ativo.
Flickable {
    id: root

    readonly property var activePreset: Config.preset(Config.options.activePreset)
    readonly property string currentStyle: Config.currentBarStyle()
    readonly property var currentInfo: Ui.barStyle(currentStyle)
    // Posicao cujas variacoes aparecem embaixo (comeca na posicao em uso)
    property string shownPosition: currentInfo ? currentInfo.position : "top"
    readonly property string wallpaperThumb: Wallpapers.thumbFor(activePreset && activePreset.wallpaper ? activePreset.wallpaper : Config.options.wallpaper)
    readonly property string loginLine: "hl.exec_cmd(\"" + System.startBarScript + "\")"

    function setStyle(id) {
        if (activePreset)
            Config.updatePreset(activePreset.id, {
                "bar": id
            });
        else
            Config.options.barStyle = id;
    }

    contentHeight: content.height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Component.onCompleted: System.checkBars()

    Column {
        id: content
        width: root.width
        spacing: 12

        StyledText {
            text: "Barra em uso"
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        Row {
            width: parent.width
            spacing: 12

            Repeater {
                model: [
                    {
                        "id": "uix",
                        "title": "Barra do Uix",
                        "description": "Muda de estilo e cor junto com o preset",
                        "icon": Icons.sparkle,
                        "running": System.uixBarRunning && Config.options.barProvider === "uix"
                    },
                    {
                        "id": "waybar",
                        "title": "Waybar",
                        "description": "A sua barra de antes (~/.config/waybar)",
                        "icon": Icons.bar,
                        "running": System.waybarRunning
                    }
                ]

                delegate: Rectangle {
                    id: providerCard

                    required property var modelData
                    readonly property bool selected: Config.options.barProvider === modelData.id

                    width: (content.width - 12) / 2
                    height: 84
                    radius: Theme.radiusMedium
                    color: providerMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                    border.width: 2
                    border.color: selected ? Theme.accent : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animFast
                        }
                    }

                    Rectangle {
                        id: providerIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44
                        height: 44
                        radius: 22
                        color: providerCard.selected ? Theme.accent : Theme.surfaceHigh

                        Icon {
                            anchors.centerIn: parent
                            path: providerCard.modelData.icon
                            size: 20
                            color: providerCard.selected ? Theme.accentText : Theme.textDim
                        }
                    }

                    Column {
                        anchors.left: providerIcon.right
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        StyledText {
                            text: providerCard.modelData.title
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                        StyledText {
                            width: parent.width
                            text: providerCard.modelData.description
                            color: Theme.textMuted
                            font.pixelSize: 12
                        }
                        Row {
                            spacing: 6

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 7
                                height: 7
                                radius: 4
                                color: providerCard.modelData.running ? "#8be28b" : Theme.textMuted
                            }
                            StyledText {
                                text: providerCard.modelData.running ? "Rodando" : "Parada"
                                color: Theme.textDim
                                font.pixelSize: 12
                            }
                        }
                    }

                    MouseArea {
                        id: providerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            System.applyBar(providerCard.modelData.id);
                            Ui.notify(providerCard.modelData.id === "uix" ? "Barra do Uix ativada" : "Voltando para a Waybar");
                        }
                    }
                }
            }
        }

        StyledText {
            topPadding: 10
            text: root.activePreset ? "Posição da barra em \"" + root.activePreset.name + "\"" : "Posição da barra"
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        // ---------- Posicao: clique para ver as variacoes ----------
        Row {
            width: parent.width
            spacing: 12

            Repeater {
                model: Ui.barPositions

                delegate: Rectangle {
                    id: posCard

                    required property var modelData
                    readonly property bool shown: root.shownPosition === modelData.id
                    readonly property bool inUse: root.currentInfo !== null && root.currentInfo.position === modelData.id

                    width: (content.width - 24) / 3
                    height: posPreview.height + 66
                    radius: Theme.radiusMedium
                    color: posMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                    border.width: 2
                    border.color: shown ? Theme.accent : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animFast
                        }
                    }

                    WallpaperPreview {
                        id: posPreview
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        height: width * 9 / 16
                        source: root.wallpaperThumb

                        BarMock {
                            anchors.fill: parent
                            // Mostra o estilo em uso, se for desta posicao
                            barStyle: posCard.inUse ? root.currentStyle : posCard.modelData.preview
                            unit: posPreview.width / 200
                        }
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.top: posPreview.bottom
                        anchors.topMargin: 8
                        spacing: 2

                        Row {
                            spacing: 8
                            StyledText {
                                text: posCard.modelData.name
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                            Rectangle {
                                visible: posCard.inUse
                                anchors.verticalCenter: parent.verticalCenter
                                width: inUseText.implicitWidth + 14
                                height: 18
                                radius: 9
                                color: Theme.accent
                                StyledText {
                                    id: inUseText
                                    anchors.centerIn: parent
                                    text: "em uso"
                                    color: Theme.accentText
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                }
                            }
                        }
                        StyledText {
                            width: parent.width
                            text: posCard.modelData.description
                            color: Theme.textMuted
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: posMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shownPosition = posCard.modelData.id
                    }
                }
            }
        }

        StyledText {
            topPadding: 6
            text: "Estilos " + (root.shownPosition === "top" ? "da barra em cima" : root.shownPosition === "bottom" ? "da doca embaixo" : "da barra lateral") + " — clique para usar"
            color: Theme.textDim
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        Repeater {
            model: Ui.barStyles.filter(b => b.position === root.shownPosition)

            delegate: Rectangle {
                id: styleCard

                required property var modelData
                readonly property bool selected: root.currentStyle === modelData.id

                width: content.width
                height: 96
                radius: Theme.radiusMedium
                color: mouse.containsMouse ? Theme.surfaceHover : Theme.surface
                border.width: 2
                border.color: selected ? Theme.accent : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animFast
                    }
                }

                WallpaperPreview {
                    id: mock
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 10
                    width: height * 16 / 9
                    source: root.wallpaperThumb

                    BarMock {
                        anchors.fill: parent
                        barStyle: styleCard.modelData.id
                        unit: mock.width / 200
                    }
                }

                Column {
                    anchors.left: mock.right
                    anchors.leftMargin: 18
                    anchors.right: badge.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    StyledText {
                        text: styleCard.modelData.name
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    StyledText {
                        width: parent.width
                        text: styleCard.modelData.description
                        color: Theme.textMuted
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    id: badge
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 26
                    radius: 13
                    color: styleCard.selected ? Theme.accent : "transparent"
                    border.width: styleCard.selected ? 0 : 2
                    border.color: Theme.surfaceHigh

                    Icon {
                        anchors.centerIn: parent
                        visible: styleCard.selected
                        path: Icons.check
                        size: 16
                        color: Theme.accentText
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setStyle(styleCard.modelData.id)
                }
            }
        }

        StyledText {
            width: parent.width
            topPadding: 2
            text: Config.options.barProvider === "uix" ? "A barra do Uix muda na hora quando você troca o estilo ou o preset." : "O estilo vale para a barra do Uix. Ative-a acima para ver na tela."
            color: Theme.textMuted
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        // ---------- Cor da florzinha / area ativa ----------
        Rectangle {
            width: parent.width
            height: flowerColumn.height + 32
            radius: Theme.radiusMedium
            color: Theme.surface

            Column {
                id: flowerColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 12

                Row {
                    spacing: 14

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30
                        height: 30

                        Cookie {
                            anchors.fill: parent
                            size: 30
                            lobes: 8
                            depth: 0.14
                            color: BarStyle.active // a mesma cor que aparece na barra
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        StyledText {
                            text: "Cor da florzinha"
                        }
                        StyledText {
                            text: Config.options.barActiveColor ? "Cor escolhida por você" : "Auto: a cor de destaque; se sumir no fundo (ex.: preto), fica branca"
                            color: Theme.textMuted
                            font.pixelSize: 12
                        }
                    }
                }

                Row {
                    spacing: 8

                    Swatch {
                        color: Theme.surfaceHigh
                        label: "Auto"
                        selected: Config.options.barActiveColor === ""
                        onClicked: Config.options.barActiveColor = ""
                    }

                    Repeater {
                        model: ["#ffffff", "#000000"].concat(Ui.accents)

                        delegate: Swatch {
                            required property string modelData
                            color: modelData
                            selected: Config.options.barActiveColor === modelData
                            onClicked: Config.options.barActiveColor = modelData
                        }
                    }

                    CustomColorButton {
                        current: Config.options.barActiveColor
                        presets: ["#ffffff", "#000000"].concat(Ui.accents)
                        onClicked: Ui.pickColor("Cor da florzinha", Config.options.barActiveColor || Theme.accent.toString(), hex => Config.options.barActiveColor = hex)
                    }
                }

                StyledText {
                    width: parent.width
                    text: "Vale para a florzinha dos estilos Tonal e para o marcador da área ativa nos outros estilos."
                    color: Theme.textMuted
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }
        }

        StyledText {
            topPadding: 10
            text: "Apps na barra"
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        SettingRow {
            width: parent.width
            icon: Icons.presets
            title: "Organizar por área de trabalho"
            subtitle: "Apps da área 1 primeiro, depois 2, 3... sempre na mesma ordem"

            Toggle {
                checked: Config.options.taskbarSortByWorkspace
                onToggled: c => Config.options.taskbarSortByWorkspace = c
            }
        }

        SettingRow {
            width: parent.width
            icon: Icons.info
            title: "Número da área nos ícones"
            subtitle: "Um numerozinho em cima de cada app dizendo em qual área ele está"

            Toggle {
                checked: Config.options.taskbarWorkspaceBadge
                onToggled: c => Config.options.taskbarWorkspaceBadge = c
            }
        }

        // Instrucao para abrir a barra escolhida no login
        Rectangle {
            width: parent.width
            height: loginColumn.height + 32
            radius: Theme.radiusMedium
            color: Theme.surface

            Column {
                id: loginColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 10

                StyledText {
                    text: "Abrir o Uix ao iniciar a sessão"
                    font.weight: Font.DemiBold
                }
                StyledText {
                    width: parent.width
                    text: "No ~/.config/hypr/hyprland.lua, troque as linhas hl.exec_cmd(\"waybar\") e hl.exec_cmd(\"linux-wallpaper-engine-ux\") por esta (abre a barra, os widgets e o wallpaper do preset ativo):"
                    color: Theme.textMuted
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    width: parent.width
                    height: 40
                    radius: Theme.radiusSmall
                    color: Theme.sidebar

                    StyledText {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: copyButton.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.loginLine
                        font.family: "Adwaita Mono"
                        font.pixelSize: 12
                        color: Theme.textDim
                    }

                    IconButton {
                        id: copyButton
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 32
                        implicitHeight: 32
                        icon: Icons.code
                        iconSize: 16
                        iconColor: Theme.textDim
                        baseColor: "transparent"
                        onClicked: {
                            Quickshell.execDetached(["wl-copy", root.loginLine]);
                            Ui.notify("Linha copiada");
                        }
                    }
                }
            }
        }
    }
}
