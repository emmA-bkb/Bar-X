pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

// The Bar X menu (launcher/LauncherWindow.qml): installed apps, search, pinned apps, a quick
// calculator and power actions. Lives in the desktop process; the bar's menu button and
// "qs -p <folder>/desktop.qml ipc call launcher toggle" open it.
Singleton {
    id: root

    property bool open: false
    // Monitor it opens on (the one with the button that was clicked, or the focused one)
    property string screenName: ""

    // Look of the menu (Config.options.launcherStyle):
    //   panel     -> search, pinned apps, every app and power buttons
    //   spotlight -> a search bar in the middle of the screen
    //   curtain   -> a strip of pinned apps that unrolls from the menu button
    //   orbit     -> pinned apps blooming in an arc around the menu button
    // The styles that only show pinned apps have an "all apps" button that switches to the panel.
    property string styleOverride: ""
    readonly property string style: styleOverride || Config.options.launcherStyle

    function show(screenName) {
        root.screenName = screenName || (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "");
        styleOverride = "";
        open = true;
    }

    function showAllApps() {
        styleOverride = "panel";
    }

    function close() {
        open = false;
    }

    function toggle(screenName) {
        open ? close() : show(screenName);
    }

    // ---------- Apps ----------
    readonly property var apps: DesktopEntries.applications.values.filter(e => !e.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    readonly property var pinned: Config.options.launcherPinned.map(id => apps.find(e => e.id === id)).filter(e => e !== undefined)

    function isPinned(entry) {
        return Config.options.launcherPinned.includes(entry.id);
    }

    function togglePin(entry) {
        const list = Config.options.launcherPinned;
        Config.options.launcherPinned = isPinned(entry) ? list.filter(id => id !== entry.id) : list.concat([entry.id]);
    }

    // Moves a pinned app up (-1) or down (+1) in the list
    function movePinned(id, delta) {
        const list = Config.options.launcherPinned.slice();
        const i = list.indexOf(id);
        const j = i + delta;
        if (i < 0 || j < 0 || j >= list.length)
            return;
        list.splice(j, 0, list.splice(i, 1)[0]);
        Config.options.launcherPinned = list;
    }

    function usage(entry) {
        return Config.options.launcherUsage[entry.id] ?? 0;
    }

    function launch(entry) {
        const counts = Object.assign({}, Config.options.launcherUsage);
        counts[entry.id] = (counts[entry.id] ?? 0) + 1;
        Config.options.launcherUsage = counts;
        // DesktopEntry.execute() ignores Terminal=true, so those run inside a terminal here
        if (entry.runInTerminal)
            Quickshell.execDetached([Env.get("UIX_TERMINAL", "kitty"), "-e"].concat(entry.command));
        else
            entry.execute();
        close();
    }

    // Apps matching the search, best first: name start > word start > name > other fields,
    // then the ones opened most often
    function search(query) {
        const q = query.trim().toLowerCase();
        if (q === "")
            return [];
        const scored = [];
        for (const e of apps) {
            const name = e.name.toLowerCase();
            let score = 0;
            if (name.startsWith(q))
                score = 100;
            else if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
                score = 80;
            else if (name.includes(q))
                score = 60;
            else if ([e.genericName, e.id].concat(e.keywords).some(t => (t ?? "").toLowerCase().includes(q)))
                score = 40;
            else if (e.categories.some(t => t.toLowerCase().includes(q)) || (e.comment ?? "").toLowerCase().includes(q))
                score = 20;
            if (score > 0)
                scored.push({
                    "entry": e,
                    "score": score + Math.min(usage(e), 30)
                });
        }
        return scored.sort((a, b) => b.score - a.score).slice(0, 40).map(s => s.entry);
    }

    // "12*3+4" -> "40"; "" when the text isn't a math expression
    function calc(query) {
        const q = query.trim();
        if (!/^[\d\s+\-*/().,%^]+$/.test(q) || !/\d/.test(q) || !/[+\-*/%^]/.test(q))
            return "";
        try {
            // Only digits, operators and parentheses get here
            const value = Function("return (" + q.replace(/,/g, ".").replace(/\^/g, "**") + ")")();
            return Number.isFinite(value) ? String(Math.round(value * 1e10) / 1e10) : "";
        } catch (e) {
            return "";
        }
    }

    function copy(text) {
        Quickshell.execDetached(["wl-copy", text]);
        close();
    }

    // ---------- Power ----------
    function power(action) {
        close();
        if (action === "lock")
            Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/lock.sh")]);
        else if (action === "suspend")
            Quickshell.execDetached(["systemctl", "suspend"]);
        else if (action === "reboot")
            Quickshell.execDetached(["systemctl", "reboot"]);
        else if (action === "poweroff")
            Quickshell.execDetached(["systemctl", "poweroff"]);
        else if (action === "logout")
            // hyprshutdown closes the apps nicely first, when it's installed
            Quickshell.execDetached(["bash", "-c", "command -v hyprshutdown >/dev/null 2>&1 && exec hyprshutdown; " + (Hyprland.usingLua ? "hyprctl dispatch 'hl.dsp.exit()'" : "hyprctl dispatch exit")]);
    }
}
