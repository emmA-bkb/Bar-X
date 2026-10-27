import QtQuick
import qs.config
import qs.services
import qs.components
import qs.widgets

// Card de um preset: previa da area de trabalho (wallpaper + barra + widgets), nome e acoes.
Rectangle {
    id: root

    property var preset
    readonly property bool active: Config.options.activePreset === preset.id

    radius: Theme.radiusMedium
    color: hover.hovered ? Theme.surfaceHover : Theme.surface
    border.width: 2
    border.color: active ? Theme.accent : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }
    Behavior on border.color {
        ColorAnimation {
            duration: Theme.animNormal
        }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Config.applyPreset(root.preset.id);
            // A barra do Uix acompanha o config sozinha; o wallpaper precisa ser aplicado
            if (root.preset.wallpaper)
                Wallpapers.apply(root.preset.wallpaper);
            Ui.notify("Preset \"" + root.preset.name + "\" aplicado");
        }
    }

    WidgetCanvas {
        id: preview
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        height: width * 9 / 16
        layout: Config.layoutFor(root.preset)
        wallpaper: Wallpapers.thumbFor(root.preset.wallpaper)
        barStyle: root.preset.bar
        accent: root.preset.accent
        glass: Config.transparencyFor(root.preset)

        // Selo do preset ativo
        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            width: 26
            height: 26
            radius: 13
            color: Theme.accent
            scale: root.active ? 1 : 0

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.animNormal
                    easing.type: Easing.OutBack
                }
            }

            Icon {
                anchors.centerIn: parent
                path: Icons.check
                size: 16
                color: Theme.accentText
            }
        }
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: preview.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: 14
        anchors.rightMargin: 10

        Column {
            anchors.left: parent.left
            anchors.right: actions.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            StyledText {
                width: parent.width
                text: root.preset.name
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            Row {
                spacing: 6

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 9
                    height: 9
                    radius: 5
                    color: root.preset.accent
                }

                StyledText {
                    text: "Barra " + Ui.barName(root.preset.bar).toLowerCase()
                    color: Theme.textMuted
                    font.pixelSize: 12
                }
            }
        }

        Row {
            id: actions
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            opacity: hover.hovered ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animFast
                }
            }

            IconButton {
                implicitWidth: 32
                implicitHeight: 32
                icon: Icons.trash
                iconSize: 16
                iconColor: Theme.textDim
                baseColor: "transparent"
                onClicked: {
                    Config.removePreset(root.preset.id);
                    Ui.notify("Preset \"" + root.preset.name + "\" removido");
                }
            }
        }
    }
}
