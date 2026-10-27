pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Wallpapers da pasta local (imagens e videos) e do Wallpaper Engine (Steam Workshop).
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

    // Coloca o wallpaper na tela de verdade (todos os monitores)
    function apply(path) {
        const item = find(path);
        if (!item)
            return false;
        const kind = item.source === "we" ? "we" : item.type;
        const screens = Quickshell.screens.map(s => s.name);
        Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/apply-wallpaper.sh"), kind, path, engineAssets || "-"].concat(screens));
        return true;
    }

    onDirChanged: rescan()
    Component.onCompleted: rescan()

    Process {
        id: proc

        // A pasta escolhida + os wallpapers que vem com o Uix (assets/wallpapers)
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
