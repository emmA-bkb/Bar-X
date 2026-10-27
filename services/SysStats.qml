pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Uso de CPU, RAM e disco, atualizado a cada 2 segundos.
Singleton {
    id: root

    property real cpu: 0
    property real ram: 0
    property real disk: 0

    property var lastCpu: null

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            if (!df.running)
                df.running = true;
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4];
            const total = f.reduce((a, b) => a + b, 0);
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total;
                if (dt > 0)
                    root.cpu = 1 - (idle - root.lastCpu.idle) / dt;
            }
            root.lastCpu = {
                "idle": idle,
                "total": total
            };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const total = Number(t.match(/MemTotal:\s+(\d+)/)[1]);
            const avail = Number(t.match(/MemAvailable:\s+(\d+)/)[1]);
            root.ram = 1 - avail / total;
        }
    }

    Process {
        id: df
        command: ["df", "--output=pcent", "/home"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/(\d+)%/);
                if (m)
                    root.disk = Number(m[1]) / 100;
            }
        }
    }
}
