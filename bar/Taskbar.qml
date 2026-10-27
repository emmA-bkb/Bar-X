import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.config
import qs.components

// Open windows. Click focuses, middle click closes.
// With "taskbarSortByWorkspace" they are ordered by workspace (1, 2, 3...) and,
// within the same workspace, in the order they were opened, without jumping around.
// With "taskbarWorkspaceBadge" each icon shows its workspace number.
BarGroup {
    id: root

    spacing: 2

    // Installed apps; icons are recomputed when the list finishes loading
    readonly property var apps: DesktopEntries.applications.values

    // Order in which each window appeared (address -> number), so the order doesn't change by itself
    property var seen: ({
            "next": 0
        })

    function wsId(t) {
        return t.workspace ? t.workspace.id : 9999;
    }

    readonly property var windows: {
        const list = Hyprland.toplevels.values.filter(t => t.wayland !== null);
        for (const t of list) {
            if (seen[t.address] === undefined)
                seen[t.address] = seen.next++;
        }
        const byOpening = (a, b) => seen[a.address] - seen[b.address];
        if (Config.options.taskbarSortByWorkspace) {
            // Special workspaces (negative ids, e.g. scratchpad) go to the end
            const key = t => wsId(t) > 0 ? wsId(t) : 10000 - wsId(t);
            return list.sort((a, b) => key(a) - key(b) || byOpening(a, b));
        }
        return list.sort(byOpening);
    }

    function iconFor(appId) {
        const id = (appId ?? "").toLowerCase();
        const entry = apps.find(e => e.id.toLowerCase() === id || (e.startupClass ?? "").toLowerCase() === id) ?? DesktopEntries.heuristicLookup(appId);
        for (const name of [entry ? entry.icon : "", appId, id]) {
            const path = name ? Quickshell.iconPath(name, true) : "";
            if (path)
                return path;
        }
        return Quickshell.iconPath("application-x-executable");
    }

    Repeater {
        model: root.windows

        delegate: Item {
            id: app

            required property var modelData
            required property int index

            readonly property var workspace: modelData.workspace
            readonly property string wsLabel: !workspace ? "" : workspace.id > 0 ? workspace.name : "S"
            // The first app of a new workspace gets some space on its left
            readonly property bool groupStart: Config.options.taskbarSortByWorkspace && index > 0 && root.wsId(root.windows[index - 1]) !== root.wsId(modelData)

            width: BarStyle.itemHeight + (groupStart && !BarStyle.vertical ? 6 : 0)
            height: BarStyle.itemHeight + (groupStart && BarStyle.vertical ? 6 : 0)

            Rectangle {
                id: button
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: BarStyle.itemHeight
                height: BarStyle.itemHeight
                radius: height / 2
                color: app.modelData.activated ? Qt.rgba(BarStyle.accent.r, BarStyle.accent.g, BarStyle.accent.b, 0.22) : mouse.containsMouse ? BarStyle.hover : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animFast
                    }
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: BarStyle.kind === "bottom" ? 22 : 18
                    source: root.iconFor(app.modelData.wayland ? app.modelData.wayland.appId : "")
                }

                // Workspace number
                Rectangle {
                    visible: Config.options.taskbarWorkspaceBadge && app.wsLabel !== ""
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: -1
                    anchors.topMargin: -1
                    width: Math.max(11, badgeText.implicitWidth + 4)
                    height: 11
                    radius: 5.5
                    color: app.modelData.activated ? BarStyle.accent : Theme.surfaceHigh
                    border.width: 1
                    border.color: BarStyle.background

                    StyledText {
                        id: badgeText
                        anchors.centerIn: parent
                        text: app.wsLabel
                        color: app.modelData.activated ? BarStyle.onAccent : Theme.text
                        font.pixelSize: 8
                        font.weight: Font.Bold
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        const w = app.modelData.wayland;
                        if (!w)
                            return;
                        if (mouse.button === Qt.MiddleButton)
                            w.close();
                        else
                            w.activate();
                    }
                }
            }
        }
    }
}
