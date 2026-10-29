import QtQuick
import qs.config
import qs.components

// Preset list (wallpaper + bar + color). Clicking a card applies the preset.
Item {
    id: root

    function newPreset() {
        const n = Config.options.presets.length + 1;
        const id = "preset-" + Date.now();
        // Copies the current look: wallpaper on screen, bar style, color, widgets and glass
        Config.addPreset({
            "id": id,
            "name": "Preset " + n,
            "bar": Config.currentBarStyle(),
            "accent": Config.options.accent,
            "wallpaper": Config.options.wallpaper,
            "monitorWallpapers": Config.currentMonitorWallpapers(),
            "widgets": Config.options.activeLayout,
            "widgetList": Config.copyWidgets(Config.currentLayout() ? Config.currentLayout().widgets : []),
            "transparency": Config.currentTransparency()
        });
        Config.options.activePreset = id;
        Ui.notify("Preset created with the current wallpaper and color");
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        height: 48

        Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            StyledText {
                text: "Choose a look"
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
            StyledText {
                text: "Each preset combines a wallpaper, a bar style and an accent color."
                color: Theme.textMuted
                font.pixelSize: 12
            }
        }

        StyledButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.add
            text: "New preset"
            primary: true
            onClicked: root.newPreset()
        }
    }

    GridView {
        id: grid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.topMargin: 16
        anchors.bottom: parent.bottom
        anchors.leftMargin: -6
        anchors.rightMargin: -6
        clip: true

        cellWidth: width / 3
        cellHeight: (cellWidth - 28) * 9 / 16 + 76
        model: Config.options.presets
        boundsBehavior: Flickable.StopAtBounds

        delegate: Item {
            required property var modelData
            width: grid.cellWidth
            height: grid.cellHeight

            PresetCard {
                anchors.fill: parent
                anchors.margins: 6
                preset: parent.modelData
            }
        }
    }
}
