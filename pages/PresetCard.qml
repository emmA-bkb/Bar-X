import QtQuick
import qs.config
import qs.services
import qs.components
import qs.widgets

// Preset card: desktop preview (wallpaper + bar + widgets), name and actions.
Rectangle {
    id: root

    property var preset
    readonly property bool active: Config.options.activePreset === preset.id

    // Other connected monitors, drawn as tiny screens in the corner that matches where they
    // sit next to the primary one (e.g. a monitor above and to the right -> top right corner)
    readonly property var mainMonitor: Monitors.list.find(m => m.name === Monitors.primary) ?? null
    readonly property var otherMonitors: Monitors.list.filter(m => m.name !== Monitors.primary)
    readonly property bool othersAbove: {
        if (!mainMonitor || otherMonitors.length === 0)
            return true;
        const cy = otherMonitors.reduce((sum, m) => sum + m.y + m.h / 2, 0) / otherMonitors.length;
        return cy < mainMonitor.y + mainMonitor.h / 2;
    }
    readonly property bool othersRight: {
        if (!mainMonitor || otherMonitors.length === 0)
            return true;
        const cx = otherMonitors.reduce((sum, m) => sum + m.x + m.w / 2, 0) / otherMonitors.length;
        return cx >= mainMonitor.x + mainMonitor.w / 2;
    }

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
            // The Uix bar follows the config on its own; the wallpaper has to be applied
            // (every monitor: the preset's main wallpaper and the other monitors' own ones)
            if (!root.preset.wallpaper || !Wallpapers.apply(root.preset.wallpaper))
                Wallpapers.applyAll();
            Ui.notify("Preset \"" + root.preset.name + "\" applied");
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

        Row {
            id: minis
            x: root.othersRight ? preview.width - width - 8 : 8
            y: root.othersAbove ? 8 : preview.height - height - 8
            spacing: 6
            layoutDirection: root.othersRight ? Qt.RightToLeft : Qt.LeftToRight
            transformOrigin: root.othersAbove ? (root.othersRight ? Item.TopRight : Item.TopLeft) : (root.othersRight ? Item.BottomRight : Item.BottomLeft)
            scale: hover.hovered ? 1.08 : 1

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.animNormal
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model: root.otherMonitors

                delegate: MonitorMini {
                    required property var modelData
                    required property int index

                    height: Math.round(preview.height * 0.36)
                    width: Math.round(height * modelData.w / Math.max(1, modelData.h))
                    source: Wallpapers.thumbFor(Config.presetMonitorWallpaper(root.preset, modelData.name))
                    accent: root.preset.accent
                    ring: root.color
                    bar: Config.monitorBar(modelData.name)
                    label: String(index + 2)
                }
            }
        }

        // Active preset badge (moves left when the tiny screens take the bottom right corner)
        Rectangle {
            x: !root.othersAbove && root.othersRight && root.otherMonitors.length > 0 ? 8 : preview.width - width - 8
            y: preview.height - height - 8
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
                    text: "Bar: " + Ui.barName(root.preset.bar)
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
                    Ui.notify("Preset \"" + root.preset.name + "\" removed");
                }
            }
        }
    }
}
