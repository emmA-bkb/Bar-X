import QtQuick
import Quickshell
import qs.config
import qs.components
import qs.services
import qs.launcher

// The bar's menu (☰): its style, the pinned apps and a few options. The menu itself runs in the
// desktop process (launcher/LauncherWindow.qml) and follows these settings right away.
Item {
    id: root

    property bool pickerOpen: false
    readonly property string toggleCommand: "qs -p " + Quickshell.shellPath("desktop.qml") + " ipc call launcher toggle"
    readonly property var styles: [
        {
            "id": "panel",
            "name": "Panel",
            "description": "Search, pinned apps, every app and power buttons"
        },
        {
            "id": "spotlight",
            "name": "Spotlight",
            "description": "A big search bar in the middle of the screen"
        },
        {
            "id": "curtain",
            "name": "Curtain",
            "description": "Pinned apps unroll from the button and float on hover"
        },
        {
            "id": "orbit",
            "name": "Orbit",
            "description": "Pinned apps bloom around the button in an arc"
        }
    ]

    Flickable {
        anchors.fill: parent
        contentHeight: column.height + 20
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: column
            width: parent.width
            spacing: 14

            // ---------- Style ----------
            Item {
                width: parent.width
                height: 48

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    StyledText {
                        text: "Menu style"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }
                    StyledText {
                        text: "How the menu of the ☰ button on the bar looks. It changes right away."
                        color: Theme.textMuted
                        font.pixelSize: 12
                    }
                }

                StyledButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Icons.play
                    text: "Try it"
                    primary: true
                    onClicked: Quickshell.execDetached(["bash", "-c", root.toggleCommand])
                }
            }

            Row {
                id: cards
                width: parent.width
                spacing: 12

                Repeater {
                    model: root.styles

                    delegate: Rectangle {
                        id: card

                        required property var modelData
                        readonly property bool active: Config.options.launcherStyle === modelData.id

                        width: (cards.width - 3 * cards.spacing) / 4
                        height: preview.height + 74
                        radius: Theme.radiusMedium
                        color: cardMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                        border.width: 2
                        border.color: active ? Theme.accent : "transparent"

                        Behavior on border.color {
                            ColorAnimation {
                                duration: Theme.animNormal
                            }
                        }

                        MenuStylePreview {
                            id: preview
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            height: width * 0.62
                            style: card.modelData.id
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: preview.bottom
                            anchors.margins: 12
                            anchors.topMargin: 10
                            spacing: 3

                            StyledText {
                                text: card.modelData.name
                                font.weight: Font.DemiBold
                            }
                            StyledText {
                                width: parent.width
                                text: card.modelData.description
                                color: Theme.textMuted
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.options.launcherStyle = card.modelData.id
                        }
                    }
                }
            }

            // ---------- Pinned apps ----------
            Rectangle {
                width: parent.width
                height: pinnedColumn.height + 28
                radius: Theme.radiusMedium
                color: Theme.surface

                Column {
                    id: pinnedColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    spacing: 6

                    Item {
                        width: parent.width
                        height: 40

                        Column {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                text: "Pinned apps  ·  " + Launcher.pinned.length
                                font.weight: Font.DemiBold
                            }
                            StyledText {
                                text: Config.options.launcherStyle === "curtain" || Config.options.launcherStyle === "orbit" ? "This style shows only these, plus a button that opens every app" : "Shown first in the menu. Right-click an app in the menu to pin it too"
                                color: Theme.textMuted
                                font.pixelSize: 12
                            }
                        }

                        StyledButton {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            icon: Icons.add
                            text: "Add apps"
                            onClicked: root.pickerOpen = true
                        }
                    }

                    StyledText {
                        visible: Launcher.pinned.length === 0
                        topPadding: 6
                        bottomPadding: 6
                        text: "No pinned apps yet."
                        color: Theme.textMuted
                    }

                    Repeater {
                        model: Launcher.pinned

                        delegate: Rectangle {
                            id: pinRow

                            required property var modelData
                            required property int index

                            width: pinnedColumn.width
                            height: 48
                            radius: Theme.radiusSmall
                            color: pinMouse.containsMouse ? Theme.surfaceHover : "transparent"

                            MouseArea {
                                id: pinMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }

                            StyledText {
                                id: number
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                text: pinRow.index < 9 ? String(pinRow.index + 1) : ""
                                color: Theme.textMuted
                                font.pixelSize: 12
                            }

                            AppIcon {
                                id: pinIcon
                                anchors.left: number.right
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                height: 30
                                entry: pinRow.modelData
                            }

                            StyledText {
                                anchors.left: pinIcon.right
                                anchors.leftMargin: 12
                                anchors.right: pinActions.left
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: pinRow.modelData.name
                                elide: Text.ElideRight
                            }

                            Row {
                                id: pinActions
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                IconButton {
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    icon: Icons.chevronDown
                                    iconSize: 18
                                    iconColor: Theme.textDim
                                    baseColor: "transparent"
                                    rotation: 180
                                    opacity: pinRow.index > 0 ? 1 : 0.3
                                    onClicked: Launcher.movePinned(pinRow.modelData.id, -1)
                                }
                                IconButton {
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    icon: Icons.chevronDown
                                    iconSize: 18
                                    iconColor: Theme.textDim
                                    baseColor: "transparent"
                                    opacity: pinRow.index < Launcher.pinned.length - 1 ? 1 : 0.3
                                    onClicked: Launcher.movePinned(pinRow.modelData.id, 1)
                                }
                                IconButton {
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    icon: Icons.close
                                    iconSize: 16
                                    iconColor: Theme.textDim
                                    baseColor: "transparent"
                                    onClicked: Launcher.togglePin(pinRow.modelData)
                                }
                            }
                        }
                    }
                }
            }

            // ---------- Panel options ----------
            SettingRow {
                width: parent.width
                icon: Icons.power
                title: "Power buttons"
                subtitle: "Lock, suspend, log out, restart and shut down at the bottom of the Panel menu"
                Toggle {
                    checked: Config.options.launcherPower
                    onToggled: c => Config.options.launcherPower = c
                }
            }

            SettingRow {
                width: parent.width
                icon: Icons.apps
                title: "All apps in the Panel"
                subtitle: "Every installed app below the pinned ones (searching always finds all of them)"
                Toggle {
                    checked: Config.options.launcherAllApps
                    onToggled: c => Config.options.launcherAllApps = c
                }
            }

            // ---------- Shortcut ----------
            Rectangle {
                width: parent.width
                height: shortcutColumn.height + 28
                radius: Theme.radiusMedium
                color: Theme.surface

                Column {
                    id: shortcutColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    spacing: 8

                    StyledText {
                        text: "Open it with a keyboard shortcut"
                        font.weight: Font.DemiBold
                    }
                    StyledText {
                        width: parent.width
                        text: "In ~/.config/hypr/hyprland.lua, bind a key to this command (e.g. hl.bind(\"SUPER + R\", hl.dsp.exec_cmd(\"…\"))):"
                        color: Theme.textMuted
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: Theme.radiusSmall
                        color: Theme.surfaceHover

                        StyledText {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: copyButton.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.toggleCommand
                            font.family: "Adwaita Mono"
                            font.pixelSize: 12
                            elide: Text.ElideMiddle
                        }

                        IconButton {
                            id: copyButton
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 32
                            implicitHeight: 32
                            icon: Icons.copy
                            iconSize: 16
                            iconColor: Theme.textDim
                            baseColor: "transparent"
                            onClicked: {
                                Quickshell.execDetached(["wl-copy", root.toggleCommand]);
                                Ui.notify("Command copied");
                            }
                        }
                    }
                }
            }
        }
    }

    AppPickerPopup {
        anchors.fill: parent
        visible: root.pickerOpen
        z: 20
        onClosed: root.pickerOpen = false
    }
}
