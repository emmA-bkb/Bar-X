pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persistent settings in ~/.config/uix/config.json
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: home + "/.config/uix"
    readonly property string path: dir + "/config.json"
    property alias options: adapter
    // True once config.json has been read (writing options before that would overwrite the file)
    property bool ready: false

    function expand(p) {
        return p.startsWith("~") ? home + p.slice(1) : p;
    }

    function preset(id) {
        return options.presets.find(p => p.id === id) ?? null;
    }

    function addPreset(p) {
        options.presets = options.presets.concat([p]);
    }

    function removePreset(id) {
        options.presets = options.presets.filter(p => p.id !== id);
        if (options.activePreset === id)
            options.activePreset = "";
    }

    function updatePreset(id, patch) {
        options.presets = options.presets.map(p => p.id === id ? Object.assign({}, p, patch) : p);
    }

    // ---------- Widget layouts ----------
    // Each preset keeps its own widgets (preset.widgetList). The layouts in options.widgetLayouts
    // are templates: choosing one copies its widgets into the active preset (preset.widgets =
    // the template they came from). Without an active preset, the active template is used.
    // A preset's widgets look like a layout with the id "preset:<preset id>".

    function layout(id) {
        return options.widgetLayouts.find(l => l.id === id) ?? null;
    }

    function copyWidgets(widgets) {
        return JSON.parse(JSON.stringify(widgets ?? []));
    }

    // Widgets of a preset, as a layout { id, name, widgets }. Presets saved before they kept
    // their own widgets show their template.
    function layoutFor(p) {
        if (!p)
            return layout(options.activeLayout);
        const base = p.widgetList ? null : ((p.widgets ? layout(p.widgets) : null) ?? layout(options.activeLayout));
        return {
            "id": "preset:" + p.id,
            "name": p.name,
            "widgets": p.widgetList ?? (base ? base.widgets : [])
        };
    }

    // Widgets on the desktop now: the active preset's, or the active template
    function currentLayout() {
        return layoutFor(preset(options.activePreset));
    }

    // A template or a preset's widgets, by id
    function findLayout(id) {
        return id.startsWith("preset:") ? layoutFor(preset(id.slice(7))) : layout(id);
    }

    // Chooses a template; with an active preset, its widgets are replaced by a copy of the template's
    function setActiveLayout(id) {
        options.activeLayout = id;
        const l = layout(id);
        if (preset(options.activePreset) && l)
            updatePreset(options.activePreset, {
                "widgets": id,
                "widgetList": copyWidgets(l.widgets)
            });
    }

    function addLayout(name, widgets) {
        const id = "layout-" + Date.now();
        options.widgetLayouts = options.widgetLayouts.concat([
            {
                "id": id,
                "name": name,
                "widgets": widgets
            }
        ]);
        setActiveLayout(id);
    }

    function removeLayout(id) {
        if (options.widgetLayouts.length <= 1)
            return;
        options.widgetLayouts = options.widgetLayouts.filter(l => l.id !== id);
        if (options.activeLayout === id)
            setActiveLayout(options.widgetLayouts[0].id);
    }

    function updateLayout(id, patch) {
        options.widgetLayouts = options.widgetLayouts.map(l => l.id === id ? Object.assign({}, l, patch) : l);
    }

    function editWidgets(layoutId, fn) {
        const l = findLayout(layoutId);
        if (!l)
            return;
        if (layoutId.startsWith("preset:"))
            updatePreset(layoutId.slice(7), {
                "widgetList": fn(l.widgets)
            });
        else
            updateLayout(layoutId, {
                "widgets": fn(l.widgets)
            });
    }

    function addWidget(layoutId, type, x, y) {
        const uid = "w" + Date.now().toString(36);
        editWidgets(layoutId, ws => ws.concat([
            {
                "uid": uid,
                "type": type,
                "x": x,
                "y": y
            }
        ]));
        return uid;
    }

    function moveWidget(layoutId, uid, x, y) {
        updateWidget(layoutId, uid, {
            "x": x,
            "y": y
        });
    }

    // patch: any widget field (x, y, scale, bgOpacity...)
    function updateWidget(layoutId, uid, patch) {
        editWidgets(layoutId, ws => ws.map(w => w.uid === uid ? Object.assign({}, w, patch) : w));
    }

    // Copies a widget (same size and background) to the given position
    function duplicateWidget(layoutId, uid, x, y) {
        const l = findLayout(layoutId);
        const w = l ? l.widgets.find(i => i.uid === uid) : null;
        if (!w)
            return "";
        const copy = Object.assign({}, w, {
            "uid": "w" + Date.now().toString(36),
            "x": x,
            "y": y
        });
        editWidgets(layoutId, ws => ws.concat([copy]));
        return copy.uid;
    }

    function removeWidget(layoutId, uid) {
        editWidgets(layoutId, ws => ws.filter(w => w.uid !== uid));
    }

    // Command of the menu button on the bar: the saved one, or UIX_LAUNCHER from .env
    function launcherCommand() {
        return options.launcherCommand || Env.get("UIX_LAUNCHER", "");
    }

    // ---------- Monitors ----------
    // options.monitors = { "<output>": { bar: bool, wallpaper: "<path>" | "", x, y } }

    function monitorSettings(name) {
        return options.monitors[name] ?? {};
    }

    function setMonitor(name, patch) {
        const all = Object.assign({}, options.monitors);
        all[name] = Object.assign({}, monitorSettings(name), patch);
        options.monitors = all;
    }

    // Bar on this monitor? (on by default)
    function monitorBar(name) {
        return monitorSettings(name).bar !== false;
    }

    // Wallpaper of a monitor: its own, or the current (primary / preset) one
    function monitorWallpaper(name) {
        return monitorSettings(name).wallpaper || options.wallpaper;
    }

    // Primary monitor name: the saved one, or the first connected monitor (same rule as Ui.screen)
    function primaryName() {
        return options.primaryMonitor || (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
    }

    // Own wallpapers of the other monitors right now: { "<output>": "<path>" | "" }, "" = the main one
    function currentMonitorWallpapers() {
        const out = {};
        for (const s of Quickshell.screens)
            if (s.name !== primaryName())
                out[s.name] = monitorSettings(s.name).wallpaper || "";
        return out;
    }

    // Wallpaper a preset puts on a non-primary monitor: the one saved in that preset, or the
    // preset's main wallpaper (never what is on screen now, so presets don't change each other)
    function presetMonitorWallpaper(p, name) {
        const saved = p && p.monitorWallpapers ? p.monitorWallpapers[name] : "";
        return saved || (p && p.wallpaper) || options.wallpaper;
    }

    // Saves the other monitors' wallpapers (and, with withMain, the main one) to the active preset
    function saveWallpapersToPreset(withMain) {
        if (!preset(options.activePreset))
            return;
        const patch = {
            "monitorWallpapers": currentMonitorWallpapers()
        };
        if (withMain)
            patch.wallpaper = options.wallpaper;
        updatePreset(options.activePreset, patch);
    }

    // Presets made before they kept their own widgets and other monitors' wallpapers get a copy
    // of their template's widgets and of what the other monitors show now, so each preset
    // keeps its own from then on
    function migratePresets() {
        const current = Quickshell.screens.length >= 2 ? currentMonitorWallpapers() : null;
        let changed = false;
        const list = options.presets.map(p => {
            const patch = {};
            if (current && p.monitorWallpapers === undefined)
                patch.monitorWallpapers = current;
            if (p.widgetList === undefined)
                patch.widgetList = copyWidgets(layoutFor(p).widgets);
            if (Object.keys(patch).length === 0)
                return p;
            changed = true;
            return Object.assign({}, p, patch);
        });
        if (changed)
            options.presets = list;
    }

    // ---------- Wallpaper Engine settings ----------
    // options.wallpaperSettings = { "<path>": { sound, volume, autoMute, fps, scaling, particles,
    //   mouse, parallax, properties: { "<name>": value } } }. fps 0 = options.wallpaperFps.
    // scripts/wallpaper-settings.py turns them into linux-wallpaperengine arguments.
    readonly property var wallpaperDefaults: ({
            "sound": true,
            "volume": 15,
            "autoMute": true,
            "fps": 0,
            "scaling": "fill",
            "particles": true,
            "mouse": true,
            "parallax": true,
            "properties": {}
        })

    function wallpaperSetting(path) {
        return Object.assign({}, wallpaperDefaults, options.wallpaperSettings[path] ?? {});
    }

    function setWallpaperSetting(path, patch) {
        const all = Object.assign({}, options.wallpaperSettings);
        all[path] = Object.assign({}, all[path] ?? {}, patch);
        options.wallpaperSettings = all;
    }

    function setWallpaperProperty(path, name, value) {
        const props = Object.assign({}, wallpaperSetting(path).properties);
        props[name] = value;
        setWallpaperSetting(path, {
            "properties": props
        });
    }

    function resetWallpaperSettings(path) {
        const all = Object.assign({}, options.wallpaperSettings);
        delete all[path];
        options.wallpaperSettings = all;
    }

    // Transparency (glass effect) of the bar and widgets: the active preset's, or the global one
    function transparencyFor(p) {
        return p && p.transparency !== undefined ? p.transparency : options.transparency;
    }

    function currentTransparency() {
        return transparencyFor(preset(options.activePreset));
    }

    function setTransparency(v) {
        if (preset(options.activePreset))
            updatePreset(options.activePreset, {
                "transparency": v
            });
        else
            options.transparency = v;
    }

    // Bar style in use: the active preset's, or the default
    function currentBarStyle() {
        const p = preset(options.activePreset);
        return p && p.bar ? p.bar : options.barStyle;
    }

    // Updates the saved state. The Uix bar follows on its own (it reads this file);
    // the wallpaper is applied by the caller (see PresetCard).
    function applyPreset(id) {
        const p = preset(id);
        if (!p)
            return;
        options.activePreset = id;
        options.accent = p.accent;
        if (p.wallpaper)
            options.wallpaper = p.wallpaper;
        // Each other monitor gets the preset's saved wallpaper ("" or none = the main one)
        const all = Object.assign({}, options.monitors);
        for (const s of Quickshell.screens)
            if (s.name !== primaryName())
                all[s.name] = Object.assign({}, all[s.name] ?? {}, {
                    "wallpaper": (p.monitorWallpapers ?? {})[s.name] ?? ""
                });
        options.monitors = all;
        if (p.widgets && layout(p.widgets))
            options.activeLayout = p.widgets;
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", dir])

    FileView {
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: {
            root.ready = true;
            root.migratePresets();
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
            root.ready = true;
            root.migratePresets();
        }

        JsonAdapter {
            id: adapter

            property string wallpaperDir: "~/Videos/Wallpapers"
            property string wallpaper: ""
            property string accent: "#7fd1c4"
            property string activePreset: "aurora"
            property bool animations: true
            property bool applyOnLogin: true
            property bool restoreBar: true

            // Taskbar: "waybar" (your current one) or "uix" (Uix bars)
            property string barProvider: "waybar"
            property string barStyle: "floating" // used when no preset is active
            property string launcherCommand: "" // empty = UIX_LAUNCHER from .env

            // Apps on the bar: ordered by workspace, with its number on the icon
            property bool taskbarSortByWorkspace: true
            property bool taskbarWorkspaceBadge: true

            // Widgets on the desktop (active layout)
            property bool widgetsEnabled: false
            property string weatherCity: "" // empty = detect from the internet

            // Widget colors: "manual" (below) or "wallpaper" (taken from the wallpaper)
            property string widgetColorMode: "manual"
            property string widgetAccent: "" // empty = the preset's accent color
            property string widgetBackground: "#131618"
            property bool dynamicBarColors: false // the bar uses the widget colors too
            property string barActiveColor: "" // flower / active workspace color; empty = automatic
            property var monitors: ({}) // per-monitor settings, see monitorSettings()
            property string primaryMonitor: "" // empty = the first connected monitor
            property real transparency: 0 // transparent bar and widgets (0..1), when no preset is active
            property var wallpaperSettings: ({}) // per Wallpaper Engine wallpaper, see wallpaperSetting()
            property int wallpaperFps: 30 // default FPS limit of Wallpaper Engine wallpapers
            property string wallpaperPause: "fullscreen" // "never" | "fullscreen" | "windows", see scripts/wallpaper-pause.py
            property var launcherPinned: [] // desktop entry ids pinned at the top of the menu
            property var launcherUsage: ({}) // desktop entry id -> times opened from the menu
            property string launcherStyle: "panel" // "panel" | "spotlight" | "curtain" | "orbit", see services/Launcher.qml
            property bool launcherPower: true // power buttons in the panel menu
            property bool launcherAllApps: true // every app below the pinned ones in the panel menu
            property string activeLayout: "padrao"

            // x/y positions are fractions of the screen (0..1), top-left corner of the widget
            property var widgetLayouts: [
                {
                    "id": "padrao",
                    "name": "Default",
                    "widgets": [
                        { "uid": "clock1", "type": "clock", "x": 0.78, "y": 0.09 },
                        { "uid": "cal1", "type": "calendar", "x": 0.0125, "y": 0.09 },
                        { "uid": "weather1", "type": "weather", "x": 0.0125, "y": 0.42 },
                        { "uid": "media1", "type": "media", "x": 0.75, "y": 0.8 }
                    ]
                },
                {
                    "id": "minimal",
                    "name": "Minimal",
                    "widgets": [
                        { "uid": "clock2", "type": "clock", "x": 0.4125, "y": 0.4 }
                    ]
                },
                {
                    "id": "trabalho",
                    "name": "Work",
                    "widgets": [
                        { "uid": "sys3", "type": "system", "x": 0.7725, "y": 0.09 },
                        { "uid": "cal3", "type": "calendar", "x": 0.815, "y": 0.24 },
                        { "uid": "media3", "type": "media", "x": 0.0125, "y": 0.8 }
                    ]
                }
            ]

            // bar: "floating" | "island" | "minimal"
            property var presets: [
                {
                    "id": "aurora",
                    "name": "Aurora",
                    "bar": "floating",
                    "widgets": "padrao",
                    "accent": "#7fd1c4",
                    "wallpaper": ""
                },
                {
                    "id": "sakura",
                    "name": "Sakura",
                    "bar": "island",
                    "widgets": "trabalho",
                    "accent": "#f4a7c0",
                    "wallpaper": ""
                },
                {
                    "id": "meia-noite",
                    "name": "Midnight",
                    "bar": "minimal",
                    "widgets": "minimal",
                    "accent": "#a7b0ff",
                    "wallpaper": ""
                }
            ]
        }
    }
}
