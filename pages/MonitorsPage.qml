import QtQuick
import qs.config
import qs.components
import qs.services

// Monitors: layout (drag to arrange, so the mouse goes from one to the other), primary
// monitor, taskbar on/off and a wallpaper for each monitor.
Item {
    id: root

    readonly property var monitors: Monitors.list
    property string selected: ""
    readonly property var sel: monitors.find(m => m.name === selected) ?? monitors.find(m => m.name === Monitors.primary) ?? monitors[0] ?? null

    // Positions being edited and not applied yet: { name: { x, y } }
    property var draft: ({})
    readonly property bool dirty: Object.keys(draft).length > 0
    property bool pickerOpen: false

    function posOf(m) {
        return draft[m.name] ?? {
            "x": m.x,
            "y": m.y
        };
    }

    function setDraft(name, pos) {
        const d = Object.assign({}, draft);
        d[name] = pos;
        draft = d;
    }

    // Puts the moved monitor right against another one (side by side or stacked), so the
    // edges touch and the mouse can cross. Picks the spot closest to where it was dropped.
    function snap(name, p) {
        const me = monitors.find(m => m.name === name);
        const others = monitors.filter(m => m.name !== name).map(m => Object.assign({}, m, posOf(m)));
        if (!me || others.length === 0)
            return p;
        const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));
        const overlaps = c => others.some(o => c.x < o.x + o.w && c.x + me.w > o.x && c.y < o.y + o.h && c.y + me.h > o.y);
        const candidates = [];
        for (const o of others) {
            // Side by side: keep at least 100px of shared edge
            const ys = [o.y, o.y + o.h - me.h, clamp(p.y, o.y - me.h + 100, o.y + o.h - 100)];
            for (const y of ys) {
                candidates.push({ "x": o.x + o.w, "y": y });
                candidates.push({ "x": o.x - me.w, "y": y });
            }
            // Stacked
            const xs = [o.x, o.x + o.w - me.w, clamp(p.x, o.x - me.w + 100, o.x + o.w - 100)];
            for (const x of xs) {
                candidates.push({ "x": x, "y": o.y + o.h });
                candidates.push({ "x": x, "y": o.y - me.h });
            }
        }
        let best = p;
        let bestDist = Infinity;
        for (const c of candidates) {
            if (overlaps(c))
                continue;
            const d = Math.hypot(c.x - p.x, c.y - p.y);
            if (d < bestDist) {
                bestDist = d;
                best = c;
            }
        }
        return {
            "x": Math.round(best.x),
            "y": Math.round(best.y)
        };
    }

    // Applies the edited layout, shifted so the top-left monitor starts at 0x0
    function applyDraft() {
        const all = monitors.map(m => Object.assign({ "name": m.name }, posOf(m)));
        const minX = Math.min(...all.map(m => m.x));
        const minY = Math.min(...all.map(m => m.y));
        const positions = {};
        for (const m of all)
            positions[m.name] = {
                "x": m.x - minX,
                "y": m.y - minY
            };
        Monitors.applyLayout(positions);
        draft = {};
        Ui.notify("Monitor layout applied");
    }

    Component.onCompleted: Monitors.refresh()

    // ---------- Layout drawing ----------
    Rectangle {
        id: stage

        // Bounding box of every monitor; frozen while dragging so the drawing doesn't rescale
        property var frozen: null
        readonly property var bounds: {
            if (frozen)
                return frozen;
            if (root.monitors.length === 0)
                return { "minX": 0, "minY": 0, "w": 1920, "h": 1080 };
            const ps = root.monitors.map(m => Object.assign({}, m, root.posOf(m)));
            const minX = Math.min(...ps.map(m => m.x));
            const minY = Math.min(...ps.map(m => m.y));
            const maxX = Math.max(...ps.map(m => m.x + m.w));
            const maxY = Math.max(...ps.map(m => m.y + m.h));
            return { "minX": minX, "minY": minY, "w": maxX - minX, "h": maxY - minY };
        }
        readonly property real k: Math.min((width - 120) / bounds.w, (height - 80) / bounds.h)
        readonly property real ox: (width - bounds.w * k) / 2 - bounds.minX * k
        readonly property real oy: (height - bounds.h * k) / 2 - bounds.minY * k

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Math.min(300, parent.height * 0.45)
        radius: Theme.radiusMedium
        color: Theme.surface

        Repeater {
            model: root.monitors

            delegate: MonitorTile {
                id: tile

                required property var modelData
                readonly property var pos: root.posOf(modelData)
                property var startPos: null

                monitor: modelData
                selected: root.sel !== null && root.sel.name === modelData.name
                primary: modelData.name === Monitors.primary
                x: stage.ox + pos.x * stage.k
                y: stage.oy + pos.y * stage.k
                width: modelData.w * stage.k
                height: modelData.h * stage.k
                z: selected ? 2 : 1

                onPressed: {
                    root.selected = modelData.name;
                    startPos = root.posOf(modelData);
                    stage.frozen = stage.bounds;
                }
                onDragged: (dx, dy) => root.setDraft(modelData.name, {
                        "x": startPos.x + dx / stage.k,
                        "y": startPos.y + dy / stage.k
                    })
                onReleased: {
                    if (root.draft[modelData.name])
                        root.setDraft(modelData.name, root.snap(modelData.name, root.draft[modelData.name]));
                    stage.frozen = null;
                }
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            text: root.monitors.length > 1 ? "Drag to change the position. They snap edge to edge, so the mouse can move from one to the other." : "Only one monitor connected"
            color: Theme.textMuted
            font.pixelSize: 11
        }
    }

    // Apply / undo the new layout
    Row {
        id: layoutButtons
        anchors.right: parent.right
        anchors.top: stage.bottom
        anchors.topMargin: 10
        height: root.dirty ? implicitHeight : 0
        visible: root.dirty
        spacing: 8

        StyledButton {
            text: "Undo"
            icon: Icons.restore
            onClicked: root.draft = {}
        }
        StyledButton {
            text: "Apply layout"
            icon: Icons.check
            primary: true
            onClicked: root.applyDraft()
        }
    }

    // ---------- Selected monitor ----------
    Flickable {
        id: detailsScroll
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: layoutButtons.bottom
        anchors.topMargin: 12
        anchors.bottom: parent.bottom
        contentHeight: details.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

    Rectangle {
        id: details
        visible: root.sel !== null
        width: detailsScroll.width
        height: detailsColumn.height + 32
        radius: Theme.radiusMedium
        color: Theme.surface

        readonly property string name: root.sel ? root.sel.name : ""
        readonly property bool isPrimary: name === Monitors.primary
        readonly property string ownWallpaper: Config.monitorSettings(name).wallpaper ?? ""
        readonly property string shownWallpaper: Config.monitorWallpaper(name)

        Column {
            id: detailsColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 12

            // Name and mode
            Row {
                spacing: 12

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 40
                    radius: 20
                    color: Theme.alpha(Theme.accent, 0.16)

                    Icon {
                        anchors.centerIn: parent
                        path: Icons.monitor
                        size: 20
                        color: Theme.accent
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    StyledText {
                        text: details.name + (root.sel ? "  ·  " + root.sel.w + "×" + root.sel.h + " · " + root.sel.refresh + " Hz" : "")
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    StyledText {
                        text: root.sel ? root.sel.description : ""
                        color: Theme.textMuted
                        font.pixelSize: 12
                    }
                }
            }

            // Primary monitor
            SettingRow {
                width: parent.width
                icon: Icons.star
                title: "Primary monitor"
                subtitle: details.isPrimary ? "The widgets and the preset's wallpaper live here. It gets the focus on login." : "Click to make this the primary monitor"

                Row {
                StyledButton {
                    visible: !details.isPrimary
                    text: "Make primary"
                    icon: Icons.star
                    onClicked: {
                        Monitors.setPrimary(details.name);
                        Ui.notify("Primary monitor: " + details.name);
                    }
                }
                Rectangle {
                    visible: details.isPrimary
                    width: primaryText.implicitWidth + 24
                    height: 30
                    radius: 15
                    color: Theme.accent

                    StyledText {
                        id: primaryText
                        anchors.centerIn: parent
                        text: "Primary"
                        color: Theme.accentText
                        font.weight: Font.Bold
                    }
                }
                }
            }

            // Resolution
            Rectangle {
                width: parent.width
                height: resColumn.height + 28
                radius: Theme.radiusMedium
                color: Theme.surfaceHover

                Column {
                    id: resColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    spacing: 10

                    StyledText {
                        width: parent.width
                        text: "Resolution  ·  if a black stripe shows up, try another one (or press \"Auto\" on the monitor)"
                        color: Theme.textDim
                        font.pixelSize: 12
                    }

                    Flow {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: root.sel ? root.sel.modes : []

                            delegate: FilterChip {
                                required property var modelData
                                anchors.verticalCenter: undefined // positioned by the Flow
                                label: modelData.w + "×" + modelData.h + " · " + modelData.refresh + " Hz"
                                active: root.sel !== null && root.sel.mode === modelData.mode
                                onClicked: {
                                    Monitors.setMode(details.name, modelData.mode);
                                    Ui.notify(details.name + ": " + modelData.w + "×" + modelData.h);
                                }
                            }
                        }
                    }
                }
            }

            // Taskbar on this monitor
            SettingRow {
                width: parent.width
                icon: Icons.bar
                title: "Taskbar on this monitor"
                subtitle: Config.options.barProvider === "uix" ? "Turns the Bar X taskbar on or off on this monitor only" : "Applies to the Bar X taskbar (turn it on in the Bar page)"

                Toggle {
                    checked: Config.monitorBar(details.name)
                    onToggled: c => Config.setMonitor(details.name, {
                            "bar": c
                        })
                }
            }

            // Wallpaper of this monitor
            Rectangle {
                width: parent.width
                height: 76
                radius: Theme.radiusMedium
                color: Theme.surfaceHover

                WallpaperPreview {
                    id: wpThumb
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 100
                    height: 56
                    radius: 8
                    source: Wallpapers.thumbFor(details.shownWallpaper)
                }

                Column {
                    anchors.left: wpThumb.right
                    anchors.leftMargin: 14
                    anchors.right: wpButtons.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    StyledText {
                        width: parent.width
                        text: details.shownWallpaper ? Wallpapers.nameFor(details.shownWallpaper) : "No wallpaper"
                        font.weight: Font.DemiBold
                    }
                    StyledText {
                        width: parent.width
                        text: details.isPrimary ? "Main wallpaper (the preset's)" : details.ownWallpaper ? "Wallpaper for this monitor only" : "Same as the primary monitor"
                        color: Theme.textMuted
                        font.pixelSize: 12
                    }
                }

                Row {
                    id: wpButtons
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    StyledButton {
                        visible: !details.isPrimary && details.ownWallpaper !== ""
                        text: "Use the main one"
                        onClicked: Wallpapers.setMonitorWallpaper(details.name, "")
                    }
                    StyledButton {
                        text: "Choose wallpaper"
                        icon: Icons.wallpaper
                        primary: true
                        onClicked: root.pickerOpen = true
                    }
                }
            }
        }
    }

    }

    // ---------- Wallpaper picker ----------
    WallpaperPickerPopup {
        anchors.fill: parent
        visible: root.pickerOpen
        z: 20
        title: "Wallpaper for " + details.name
        onClosed: root.pickerOpen = false
        onChosen: path => {
            root.pickerOpen = false;
            if (details.isPrimary) {
                // The primary monitor shows the main wallpaper
                Config.setMonitor(details.name, {
                    "wallpaper": ""
                });
                Wallpapers.apply(path);
                Config.saveWallpapersToPreset();
            } else {
                Wallpapers.setMonitorWallpaper(details.name, path);
            }
            Ui.notify("Applying \"" + Wallpapers.nameFor(path) + "\" on " + details.name);
        }
    }
}
