import QtQuick
import Quickshell
import qs.config
import qs.components
import qs.services
import qs.bar

// Which bar to use (Waybar or the Uix one) and the active preset's bar style.
Flickable {
    id: root

    readonly property var activePreset: Config.preset(Config.options.activePreset)
    readonly property string currentStyle: Config.currentBarStyle()
    readonly property var currentInfo: Ui.barStyle(currentStyle)
    // Position whose variants are shown below (starts on the position in use)
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
            text: "Bar in use"
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
                        "title": "Bar X taskbar",
                        "description": "Changes style and color along with the preset",
                        "icon": Icons.sparkle,
                        "running": System.uixBarRunning && Config.options.barProvider === "uix"
                    },
                    {
                        "id": "waybar",
                        "title": "Waybar",
                        "description": "Your previous bar (~/.config/waybar)",
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
                                text: providerCard.modelData.running ? "Running" : "Stopped"
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
                            Ui.notify(providerCard.modelData.id === "uix" ? "Bar X taskbar enabled" : "Switching back to Waybar");
                        }
                    }
                }
            }
        }

        StyledText {
            topPadding: 10
            text: root.activePreset ? "Bar position in \"" + root.activePreset.name + "\"" : "Bar position"
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        // ---------- Position: click to see the variants ----------
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
                            // Shows the style in use, if it belongs to this position
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
                                    text: "in use"
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
            text: (root.shownPosition === "top" ? "Top bar styles" : root.shownPosition === "bottom" ? "Bottom dock styles" : "Side bar styles") + " — click to use"
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
            text: Config.options.barProvider === "uix" ? "The Bar X taskbar changes right away when you switch the style or the preset." : "The style applies to the Bar X taskbar. Turn it on above to see it on screen."
            color: Theme.textMuted
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        // ---------- Flower / active workspace color ----------
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
                            color: BarStyle.active // the same color shown on the bar
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        StyledText {
                            text: "Flower color"
                        }
                        StyledText {
                            text: Config.options.barActiveColor ? "Color chosen by you" : "Auto: the accent color; if it disappears on the background (e.g. black), it turns white"
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
                        onClicked: Ui.pickColor("Flower color", Config.options.barActiveColor || Theme.accent.toString(), hex => Config.options.barActiveColor = hex)
                    }
                }

                StyledText {
                    width: parent.width
                    text: "Applies to the flower in the Tonal styles and to the active workspace marker in the other styles."
                    color: Theme.textMuted
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }
        }

        StyledText {
            topPadding: 10
            text: "Apps on the bar"
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        SettingRow {
            width: parent.width
            icon: Icons.presets
            title: "Sort by workspace"
            subtitle: "Apps on workspace 1 first, then 2, 3... always in the same order"

            Toggle {
                checked: Config.options.taskbarSortByWorkspace
                onToggled: c => Config.options.taskbarSortByWorkspace = c
            }
        }

        SettingRow {
            width: parent.width
            icon: Icons.info
            title: "Workspace number on the icons"
            subtitle: "A tiny number on each app showing which workspace it is on"

            Toggle {
                checked: Config.options.taskbarWorkspaceBadge
                onToggled: c => Config.options.taskbarWorkspaceBadge = c
            }
        }

        // How to start the chosen bar on login
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
                    text: "Start Bar X on login"
                    font.weight: Font.DemiBold
                }
                StyledText {
                    width: parent.width
                    text: "In ~/.config/hypr/hyprland.lua, replace the hl.exec_cmd(\"waybar\") and hl.exec_cmd(\"linux-wallpaper-engine-ux\") lines with this one (starts the bar, the widgets and the active preset's wallpaper):"
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
                            Ui.notify("Line copied");
                        }
                    }
                }
            }
        }
    }
}
