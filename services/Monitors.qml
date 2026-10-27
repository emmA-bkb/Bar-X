pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config

// Connected monitors (from Hyprland) and the per-monitor settings saved by Uix.
Singleton {
    id: root

    // [{ name, description, x, y, w, h, refresh, scale, transform, focused, mode, modes }]
    // mode = current "WxH@Hz"; modes = [{ mode, w, h, refresh }] the monitor (or its adapter) offers
    // w/h are the logical size on the desktop layout (rotation and scale applied)
    property var list: []

    // Same rule as Ui.screen: the saved one, or the first monitor Quickshell lists
    readonly property string primary: Ui.screen ? Ui.screen.name : (list.length > 0 ? list[0].name : "")

    // "1600x900@60.00Hz" list -> unique modes, biggest resolution first
    function uniqueModes(available) {
        const seen = {};
        const out = [];
        for (const a of available ?? []) {
            const mode = a.replace("Hz", "");
            const [res, hz] = mode.split("@");
            // 60.00 and 59.94 Hz look the same on the button: keep only the first
            const key = res + "@" + Math.round(Number(hz));
            if (seen[key])
                continue;
            seen[key] = true;
            const [w, h] = res.split("x").map(Number);
            out.push({
                "mode": mode,
                "w": w,
                "h": h,
                "refresh": Math.round(Number(hz))
            });
        }
        return out.sort((a, b) => b.w * b.h - a.w * a.h || b.refresh - a.refresh);
    }

    // Changes a monitor's resolution, saves it and keeps it touching its neighbours
    // (e.g. a monitor above another keeps its bottom edge in place when it gets shorter).
    function setMode(name, mode) {
        const me = list.find(m => m.name === name);
        if (!me)
            return;
        const [res] = mode.split("@");
        const [mw, mh] = res.split("x").map(Number);
        const rotated = me.transform % 2 === 1;
        const nw = Math.round((rotated ? mh : mw) / me.scale);
        const nh = Math.round((rotated ? mw : mh) / me.scale);
        let x = me.x;
        let y = me.y;
        for (const o of list) {
            if (o.name === name)
                continue;
            if (o.y === me.y + me.h)
                y = me.y + me.h - nh;
            if (o.x === me.x + me.w)
                x = me.x + me.w - nw;
        }
        // Save every monitor's position too, so the script places all of them
        const all = Object.assign({}, Config.options.monitors);
        for (const m of list)
            all[m.name] = Object.assign({}, all[m.name] ?? {}, {
                "x": m.name === name ? x : m.x,
                "y": m.name === name ? y : m.y
            });
        all[name].mode = mode;
        Config.options.monitors = all;
        applyTimer.restart();
    }

    function refresh() {
        if (!proc.running)
            proc.running = true;
    }

    // positions: { name: { x, y } } in desktop pixels. Saves them and applies them now;
    // scripts/uix-start.sh applies them again on every login.
    function applyLayout(positions) {
        const all = Object.assign({}, Config.options.monitors);
        for (const name in positions)
            all[name] = Object.assign({}, all[name] ?? {}, {
                "x": Math.round(positions[name].x),
                "y": Math.round(positions[name].y)
            });
        Config.options.monitors = all;
        // Give the config file a moment to be written before the script reads it
        applyTimer.restart();
    }

    // Makes a monitor the primary one (widgets go there and it gets the main wallpaper).
    // If it had its own wallpaper, the old primary keeps the main one, so nothing changes on screen.
    function setPrimary(name) {
        const old = primary;
        if (name === old)
            return;
        const own = Config.monitorSettings(name).wallpaper;
        if (own) {
            const main = Config.options.wallpaper;
            Config.setMonitor(name, {
                "wallpaper": ""
            });
            Config.options.wallpaper = own;
            if (old)
                Config.setMonitor(old, {
                    "wallpaper": main
                });
        }
        Config.options.primaryMonitor = name;
        // Moves workspaces 1-10 to the new primary monitor and focuses it (scripts/monitors.py apply)
        applyTimer.restart();
    }

    Timer {
        id: applyTimer
        interval: 400
        onTriggered: {
            Quickshell.execDetached(["python3", "-I", Quickshell.shellPath("scripts/monitors.py"), "apply"]);
            refreshTimer.restart();
        }
    }

    Timer {
        id: refreshTimer
        interval: 1200
        onTriggered: root.refresh()
    }

    // Monitors plugged/unplugged or Hyprland config reloaded
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["monitoradded", "monitoraddedv2", "monitorremoved", "monitorremovedv2", "configreloaded"].includes(event.name))
                refreshTimer.restart();
        }
    }

    Component.onCompleted: refresh()

    Process {
        id: proc

        command: ["hyprctl", "monitors", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.list = JSON.parse(text).map(m => {
                        const rotated = m.transform % 2 === 1;
                        return {
                            "name": m.name,
                            "description": m.description,
                            "x": m.x,
                            "y": m.y,
                            "w": Math.round((rotated ? m.height : m.width) / m.scale),
                            "h": Math.round((rotated ? m.width : m.height) / m.scale),
                            "refresh": Math.round(m.refreshRate),
                            "scale": m.scale,
                            "transform": m.transform,
                            "focused": m.focused,
                            "mode": m.width + "x" + m.height + "@" + m.refreshRate.toFixed(2),
                            "modes": root.uniqueModes(m.availableModes)
                        };
                    }).sort((a, b) => a.x - b.x || a.y - b.y);
                } catch (e) {}
            }
        }
    }
}
