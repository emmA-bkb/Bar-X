pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Wallpapers da comunidade (Steam Workshop do Wallpaper Engine).
// Instalar = assinar pela Steam; a Steam baixa para a pasta da Workshop e o Uix detecta.
Singleton {
    id: root

    // Mesmo formato dos itens de Wallpapers, mais os dados da Workshop:
    // { source: "workshop", id, path, thumb, name, type, compat, subscriptions, size, tags }
    property var items: []
    property bool loading: false
    property bool loaded: false
    property bool hasMore: false
    property string error: ""
    property int page: 1

    property string sort: "trend" // trend | mostrecent | toprated | subscribed
    property string type: "" // "" | Scene | Video | Web
    property string query: ""

    property var request: null
    property bool pending: false

    // Id que esta sendo baixado pela Steam (para avisar quando terminar)
    property string watching: ""
    property int watchTries: 0

    readonly property var sorts: [
        {
            "id": "trend",
            "label": "Em alta"
        },
        {
            "id": "mostrecent",
            "label": "Recentes"
        },
        {
            "id": "toprated",
            "label": "Mais votados"
        },
        {
            "id": "subscribed",
            "label": "Mais baixados"
        }
    ]

    readonly property var types: [
        {
            "id": "",
            "label": "Todos"
        },
        {
            "id": "Scene",
            "label": "Cena"
        },
        {
            "id": "Video",
            "label": "Vídeo"
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

    // Abre o item no app da Steam (la tem o botao "Inscrever-se", que baixa o wallpaper)
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
            return (n / 1000000).toFixed(1).replace(".", ",") + " mi";
        if (n >= 1000)
            return (n / 1000).toFixed(1).replace(".", ",") + " mil";
        return String(n);
    }

    function formatSize(bytes) {
        if (bytes >= 1073741824)
            return (bytes / 1073741824).toFixed(1).replace(".", ",") + " GB";
        return Math.max(1, Math.round(bytes / 1048576)) + " MB";
    }

    // Enquanto a Steam baixa, procura o wallpaper na pasta a cada 8s (por ate ~3 min)
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
                    return; // resposta velha; a nova ja vai rodar
                let data;
                try {
                    data = JSON.parse(text);
                } catch (e) {
                    data = {
                        "error": "resposta inválida"
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
