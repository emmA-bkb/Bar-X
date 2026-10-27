import QtQuick
import Quickshell.Hyprland
import qs.config
import qs.components

// Workspaces of the bar's monitor. Click switches workspace, mouse wheel navigates.
// In the Tonal style the active workspace becomes a flower.
BarGroup {
    id: root

    property var monitor: null

    readonly property var workspaces: Hyprland.workspaces.values.filter(w => w.id > 0 && (!monitor || w.monitor === monitor)).sort((a, b) => a.id - b.id)

    function go(target) {
        // Hyprland with a Lua config uses a different dispatch syntax
        Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.focus({ workspace = " + target + " })" : "workspace " + target);
    }

    spacing: BarStyle.minimal ? 6 : 4

    Repeater {
        model: root.workspaces

        delegate: Item {
            id: ws

            required property var modelData
            readonly property bool active: modelData.active
            readonly property real size: BarStyle.minimal ? 8 : BarStyle.itemHeight
            // The active one is wider (except on Tonal, where it becomes a flower)
            readonly property real length: active && !BarStyle.tonal ? (BarStyle.minimal ? 20 : 40) : size

            width: BarStyle.vertical ? size : length
            height: BarStyle.vertical ? length : size

            Behavior on width {
                NumberAnimation {
                    duration: Theme.animNormal
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: Theme.animNormal
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: !(BarStyle.tonal && ws.active)
                radius: Math.min(width, height) / 2
                color: ws.active ? BarStyle.active : mouse.containsMouse ? BarStyle.hover : BarStyle.minimal ? "#55ffffff" : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animFast
                    }
                }
            }

            Cookie {
                visible: BarStyle.tonal && ws.active
                anchors.centerIn: parent
                size: ws.size + 4
                lobes: 8
                depth: 0.14
                color: BarStyle.active
            }

            StyledText {
                visible: !BarStyle.minimal
                anchors.centerIn: parent
                text: ws.modelData.name
                color: ws.active ? BarStyle.onActive : ws.modelData.urgent ? "#ff7b7b" : BarStyle.textDim
                font.weight: ws.active ? Font.Bold : Font.Normal
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.go(ws.modelData.id)
            }
        }
    }

    // Mouse wheel over the workspaces switches to the previous/next one
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const list = root.workspaces;
            const i = list.findIndex(w => w.active);
            if (i < 0)
                return;
            const next = list[i + (event.angleDelta.y < 0 ? 1 : -1)];
            if (next)
                root.go(next.id);
        }
    }
}
