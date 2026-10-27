pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Community wallpapers (Wallpaper Engine's Steam Workshop).
// Install = subscribe through Steam; Steam downloads it to the Workshop folder and Uix detects it.
Singleton {
    id: root

    // Same format as the Wallpapers items, plus the Workshop data:
    // { source: "workshop", id, path, thumb, name, type, compat, subscriptions, size, tags }
    property var items: []
    property bool loading: false
    property bool loaded: false
    property bool hasMore: false
    property string error: ""
    property int page: 1

    // Emitted right before a new page is appended to `items`, so the grid can keep its scroll position
    signal beforeAppend

    property string sort: "trend" // trend | mostrecent | toprated | subscribed
    property string type: "" // "" | Scene | Video | Web
    property string query: ""

    property var request: null
    property bool pending: false

    // Id being downloaded by Steam (to notify when it finishes)
    property string watching: ""
    property int watchTries: 0

    readonly property var sorts: [
        {
            "id": "trend",
            "label": "Trending"
        },
        {
            "id": "mostrecent",
            "label": "Recent"
        },
        {
            "id": "toprated",
            "label": "Top rated"
        },
        {
            "id": "subscribed",
            "label": "Most subscribed"
        }
    ]

    readonly property var types: [
        {
            "id": "",
            "label": "All"
        },
        {
            "id": "Scene",
            "label": "Scene"
        },
        {
            "id": "Video",
            "label": "Video"
        },
        {
            "id": "Web",
            "label": "Web"
        }
    ]

    function setSort(s) {
        if (sort !== s) {
            sort = s;
            reload();
        }
    }

    function setType(t) {
        if (type !== t) {
            type = t;
            reload();
        }
    }

    function search(q) {
        if (query !== q) {
            query = q;
            reload();
        }
    }

    function reload() {
        run(1, false);
    }

    function loadMore() {
        if (!loading && hasMore)
            run(page + 1, true);
    }

    function run(p, append) {
        request = {
            "page": p,
            "append": append,
            "sort": sort,
            "type": type,
            "query": query
        };
        if (proc.running) {
            pending = true;
            return;
        }
        start();
    }

    function start() {
        proc.command = ["python3", "-I", Quickshell.shellPath("scripts/workshop.py"), request.sort, String(request.page), request.type, request.query];
        loading = true;
        error = "";
        proc.running = true;
    }

    function pageUrl(id) {
        return "https://steamcommunity.com/sharedfiles/filedetails/?id=" + id;
    }

    // Opens the item in the Steam app (it has the "Subscribe" button, which downloads the wallpaper)
    function openInSteam(id) {
        Quickshell.execDetached(["xdg-open", "steam://url/CommunityFilePage/" + id]);
        watching = id;
        watchTries = 0;
        watchTimer.restart();
    }

    function openInBrowser(id) {
        Quickshell.execDetached(["xdg-open", pageUrl(id)]);
    }

    function formatCount(n) {
        if (n >= 1000000)
            return (n / 1000000).toFixed(1) + "M";
        if (n >= 1000)
            return (n / 1000).toFixed(1) + "K";
        return String(n);
    }

    function formatSize(bytes) {
        if (bytes >= 1073741824)
            return (bytes / 1073741824).toFixed(1) + " GB";
        return Math.max(1, Math.round(bytes / 1048576)) + " MB";
    }

    // While Steam downloads, look for the wallpaper in the folder every 8s (for up to ~3 min)
    Timer {
        id: watchTimer
        interval: 8000
        repeat: true
        onTriggered: {
            if (root.watching === "" || Wallpapers.engineItems.some(i => i.path.endsWith("/" + root.watching)) || ++root.watchTries > 22) {
                stop();
                root.watching = "";
                return;
            }
            Wallpapers.rescan();
        }
    }

    Process {
        id: proc

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.pending)
                    return; // stale response; the new one is about to run
                let data;
                try {
                    data = JSON.parse(text);
                } catch (e) {
                    data = {
                        "error": "invalid response"
                    };
                }
                if (data.error) {
                    root.error = data.error;
                    return;
                }
                const mapped = data.items.map(i => ({
                            "source": "workshop",
                            "id": i.id,
                            "path": i.id,
                            "thumb": i.preview,
                            "name": i.title,
                            "type": i.type,
                            "compat": "",
                            "subscriptions": i.subscriptions,
                            "size": i.size,
                            "tags": i.tags
                        }));
                if (root.request.append) {
                    root.beforeAppend();
                    const seen = new Set(root.items.map(i => i.id));
                    root.items = root.items.concat(mapped.filter(i => !seen.has(i.id)));
                } else {
                    root.items = mapped;
                }
                root.page = data.page;
                root.hasMore = data.hasMore;
                root.loaded = true;
            }
        }

        onExited: {
            if (root.pending) {
                root.pending = false;
                root.start();
            } else {
                root.loading = false;
            }
        }
    }
}
