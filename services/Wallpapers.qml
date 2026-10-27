pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Wallpapers from the local folder (images and videos) and from Wallpaper Engine (Steam Workshop).
Singleton {
    id: root

    // { source: "local" | "we", type: "image" | "video" | "scene" | "web" | ...,
    //   path, thumb, name, compat: "" | "perfect" | "minor" | "broken" }
    property var items: []
    property var engineItems: []
    property string engineAssets: ""

    property bool loading: false
    property bool engineLoading: false
    property bool pending: false

    readonly property string dir: Config.expand(Config.options.wallpaperDir)
    readonly property string cacheDir: Config.home + "/.cache/uix/thumbs"

    function find(path) {
        return items.find(i => i.path === path) ?? engineItems.find(i => i.path === path) ?? null;
    }

    function thumbFor(path) {
        const item = find(path);
        return item ? item.thumb : "";
    }

    function nameFor(path) {
        const item = find(path);
        return item ? item.name : path.split("/").pop();
    }

    function rescan() {
        if (proc.running) {
            pending = true;
        } else {
            loading = true;
            proc.running = true;
        }
        if (!engineProc.running) {
            engineLoading = true;
            engineProc.running = true;
        }
    }

    // Puts a wallpaper on screen as the main wallpaper (primary monitor, and every monitor
    // without its own wallpaper). Config.options.wallpaper always means "the main wallpaper on screen now".
    function apply(path) {
        if (!find(path))
            return false;
        Config.options.wallpaper = path;
        applyAll();
        return true;
    }

    // Gives one monitor its own wallpaper ("" = back to the main wallpaper)
    function setMonitorWallpaper(name, path) {
        Config.setMonitor(name, {
            "wallpaper": path
        });
        Config.saveWallpapersToPreset();
        applyAll();
    }

    // Redraws the wallpaper of every monitor (each one: its own, or the main one)
    function applyAll() {
        const pairs = [];
        for (const s of Quickshell.screens) {
            const path = Config.monitorWallpaper(s.name);
            const item = find(path);
            if (item)
                pairs.push(s.name + "=" + (item.source === "we" ? "we" : item.type) + ":" + path);
        }
        if (pairs.length > 0)
            Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/apply-wallpaper.sh"), engineAssets || "-"].concat(pairs));
    }

    // Reads which wallpaper is really running (also catches ones set outside Uix, e.g. by
    // linux-wallpaper-engine-ux) and stores it as the current wallpaper.
    function detectCurrent() {
        if (Config.ready && !detect.running)
            detect.running = true;
    }

    Connections {
        target: Config
        function onReadyChanged() {
            root.detectCurrent();
        }
    }

    Process {
        id: detect

        command: ["ps", "-eo", "args"]

        stdout: StdioCollector {
            onStreamFinished: {
                // monitor -> wallpaper path, read from the running processes
                const running = {};
                for (const line of text.split("\n")) {
                    if (/linux-wallpaperengine .*--screen-root/.test(line)) {
                        // "--screen-root A [--screen-root B] --bg X": X goes to every screen since the last --bg
                        const tokens = line.split(/\s+/);
                        let screens = [];
                        for (let i = 0; i < tokens.length - 1; i++) {
                            if (tokens[i] === "--screen-root") {
                                screens.push(tokens[i + 1]);
                            } else if (tokens[i] === "--bg") {
                                for (const s of screens)
                                    running[s] = tokens[i + 1];
                                screens = [];
                            }
                        }
                    } else if (/(^|\/)mpvpaper /.test(line) && line.indexOf(" /") >= 0) {
                        // mpvpaper ... <monitor> <path>: the path is the first argument starting with "/"
                        const before = line.slice(0, line.indexOf(" /")).trim().split(/\s+/);
                        running[before[before.length - 1]] = line.slice(line.indexOf(" /") + 1).trim();
                    }
                }
                const primary = Ui.screen ? Ui.screen.name : "";
                const found = running[primary] ?? Object.values(running)[0] ?? "";
                if (found && found !== Config.options.wallpaper)
                    Config.options.wallpaper = found;
            }
        }
    }

    onDirChanged: rescan()
    Component.onCompleted: {
        rescan();
        detectCurrent();
    }

    Process {
        id: proc

        // The chosen folder + the wallpapers that ship with Uix (assets/wallpapers)
        command: ["bash", Quickshell.shellPath("scripts/scan-wallpapers.sh"), root.cacheDir, root.dir, Quickshell.shellPath("assets/wallpapers")]

        stdout: StdioCollector {
            onStreamFinished: {
                root.items = text.split("\n").filter(l => l.length > 0).map(l => {
                    const [type, path, thumb] = l.split("\t");
                    return {
                        "source": "local",
                        "type": type,
                        "path": path,
                        "thumb": thumb,
                        "name": path.split("/").pop(),
                        "compat": ""
                    };
                });
            }
        }

        onExited: {
            root.loading = false;
            if (root.pending) {
                root.pending = false;
                root.rescan();
            }
        }
    }

    Process {
        id: engineProc

        command: ["python3", "-I", Quickshell.shellPath("scripts/scan-wallpaper-engine.py")]

        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of text.split("\n")) {
                    const f = line.split("\t");
                    if (f[0] === "assets") {
                        root.engineAssets = f[1];
                    } else if (f[0] === "we") {
                        list.push({
                            "source": "we",
                            "path": f[1],
                            "thumb": f[2],
                            "name": f[3],
                            "type": f[4],
                            "compat": f[5] ?? ""
                        });
                    }
                }
                root.engineItems = list.sort((a, b) => a.name.localeCompare(b.name));
            }
        }

        onExited: root.engineLoading = false
    }
}
