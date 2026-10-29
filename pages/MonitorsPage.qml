import QtQuick
import Quickshell
import qs.config
import qs.components
import qs.services

// Monitors: layout (drag to arrange, so the mouse goes from one to the other), primary
// monitor, taskbar on/off, dimming after inactivity and a wallpaper for each monitor.
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

            // Resolution and refresh rate: two dropdowns with every mode the monitor offers
            Rectangle {
                id: modeBox

                // "1920x1080" of each mode, biggest first (the modes come sorted)
                readonly property var resolutions: {
                    const out = [];
                    for (const m of root.sel ? root.sel.modes : [])
                        if (!out.some(o => o.value === m.w + "x" + m.h))
                            out.push({
                                "value": m.w + "x" + m.h,
                                "label": m.w + " × " + m.h
                            });
                    return out;
                }
                readonly property string currentRes: root.sel ? root.sel.mode.split("@")[0] : ""
                readonly property int currentHz: root.sel ? Math.round(Number(root.sel.mode.split("@")[1])) : 0
                // Refresh rates of the current resolution, fastest first
                readonly property var rates: (root.sel ? root.sel.modes : []).filter(m => m.w + "x" + m.h === currentRes).map(m => ({
                            "value": m.mode,
                            "label": m.refresh + " Hz",
                            "refresh": m.refresh
                        }))
                readonly property string currentRate: (rates.find(r => r.refresh === currentHz) ?? {
                        "value": ""
                    }).value

                width: parent.width
                height: modeColumn.height + 28
                radius: Theme.radiusMedium
                color: Theme.surfaceHover

                Column {
                    id: modeColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    spacing: 10

                    Row {
                        spacing: 12

                        Column {
                            spacing: 6

                            StyledText {
                                text: "Resolution"
                                color: Theme.textDim
                                font.pixelSize: 12
                            }
                            Dropdown {
                                width: 220
                                options: modeBox.resolutions
                                current: modeBox.currentRes
                                onChosen: res => {
                                    // Keeps the refresh rate when the new resolution has it, otherwise the fastest one
                                    const opts = root.sel.modes.filter(m => m.w + "x" + m.h === res);
                                    const pick = opts.find(m => m.refresh === modeBox.currentHz) ?? opts[0];
                                    Monitors.setMode(details.name, pick.mode);
                                    Ui.notify(details.name + ": " + pick.w + "×" + pick.h + " · " + pick.refresh + " Hz");
                                }
                            }
                        }

                        Column {
                            spacing: 6

                            StyledText {
                                text: "Refresh rate"
                                color: Theme.textDim
                                font.pixelSize: 12
                            }
                            Dropdown {
                                width: 160
                                options: modeBox.rates
                                current: modeBox.currentRate
                                onChosen: mode => {
                                    Monitors.setMode(details.name, mode);
                                    Ui.notify(details.name + ": " + Math.round(Number(mode.split("@")[1])) + " Hz");
                                }
                            }
                        }
                    }

                    StyledText {
                        width: parent.width
                        text: "If a black stripe shows up, try another resolution (or press \"Auto\" on the monitor)."
                        color: Theme.textMuted
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
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

            // Dim after inactivity (widgets/ScreenDim.qml, in the desktop process)
            SettingRow {
                width: parent.width
                icon: Icons.sun
                title: "Dim after inactivity"
                subtitle: "Darkens this monitor when the computer isn't being used"

                Row {
                    spacing: 6
                    Repeater {
                        model: [0, 5, 10, 15, 30, 60]
                        delegate: FilterChip {
                            required property int modelData
                            label: modelData === 0 ? "Off" : modelData + " min"
                            active: (Config.monitorSettings(details.name).dimAfter ?? 0) === modelData
                            onClicked: Config.setMonitor(details.name, {
                                "dimAfter": modelData
                            })
                        }
                    }
                }
            }

            SettingRow {
                visible: (Config.monitorSettings(details.name).dimAfter ?? 0) > 0
                width: parent.width
                icon: Icons.sun
                title: "How dark  " + Math.round(dimSlider.shownValue * 100) + "%"
                subtitle: "Move the slider to see it on the monitor"

                StyledSlider {
                    id: dimSlider
                    width: 240
                    from: 0.2
                    to: 0.9
                    stepSize: 0.05
                    value: Config.monitorSettings(details.name).dimLevel ?? 0.6
                    onMoved: v => {
                        dimPreview.level = v;
                        if (!dimPreview.running)
                            dimPreview.start();
                    }
                    onCommitted: v => {
                        Config.setMonitor(details.name, {
                            "dimLevel": v
                        });
                        dimPreview.level = v;
                        dimPreview.restart();
                    }
                }

                // Sends the level to the desktop process at most every 150 ms while dragging
                Timer {
                    id: dimPreview
                    property real level: 0.6
                    interval: 150
                    onTriggered: Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("desktop.qml"), "ipc", "call", "uixdesktop", "dimPreview", details.name, String(level)])
                }
            }

            SettingRow {
                visible: (Config.monitorSettings(details.name).dimAfter ?? 0) > 0 && Monitors.list.length > 1
                width: parent.width
                icon: Icons.monitor
                title: "Also while you use the other monitor"
                subtitle: "Counts the time since the mouse left this monitor"

                Toggle {
                    checked: Config.monitorSettings(details.name).dimAway === true
                    onToggled: c => Config.setMonitor(details.name, {
                            "dimAway": c
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
                Config.saveWallpapersToPreset(true);
            } else {
                Wallpapers.setMonitorWallpaper(details.name, path);
            }
            Ui.notify("Applying \"" + Wallpapers.nameFor(path) + "\" on " + details.name);
        }
    }
}
