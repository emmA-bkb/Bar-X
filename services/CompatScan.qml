pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Testa se os wallpapers do Wallpaper Engine funcionam no Linux (scripts/scan-compat.py).
Singleton {
    id: root

    property bool running: false
    property int total: 0
    property int done: 0
    property string current: ""
    property var counts: ({
            "perfect": 0,
            "minor": 0,
            "broken": 0
        })

    readonly property int untested: Wallpapers.engineItems.filter(i => !i.compat).length

    // mode: "new" (so os que ainda nao foram testados) ou "all" (todos de novo)
    function start(mode) {
        if (running)
            return;
        total = 0;
        done = 0;
        current = "";
        counts = {
            "perfect": 0,
            "minor": 0,
            "broken": 0
        };
        proc.command = ["python3", "-I", Quickshell.shellPath("scripts/scan-compat.py"), mode];
        running = true;
        proc.running = true;
    }

    function cancel() {
        if (proc.running)
            proc.signal(15);
    }

    function handle(line) {
        const f = line.split("\t");
        switch (f[0]) {
        case "total":
            total = Number(f[1]);
            if (total === 0)
                Ui.notify("Todos os wallpapers já foram testados");
            break;
        case "start":
            current = f[1];
            break;
        case "result":
            done++;
            const c = Object.assign({}, counts);
            c[f[2]] = (c[f[2]] ?? 0) + 1;
            counts = c;
            break;
        case "error":
            Ui.notify(f[1]);
            break;
        }
    }

    Process {
        id: proc

        stdout: SplitParser {
            onRead: line => root.handle(line)
        }

        onExited: {
            const finished = root.done > 0;
            root.running = false;
            root.current = "";
            Wallpapers.rescan(); // atualiza os selos
            if (finished)
                Ui.notify(root.counts.perfect + " funcionam · " + root.counts.minor + " com problemas · " + root.counts.broken + " não funcionam");
        }
    }
}
