pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Cores dos widgets (e, se ligado, da barra).
//   widgetColorMode = "wallpaper" -> tiradas do wallpaper (scripts/palette.py, com cache)
//   widgetColorMode = "manual"    -> escolhidas em Aparencia
Singleton {
    id: root

    readonly property bool dynamic: Config.options.widgetColorMode === "wallpaper"

    // Paleta escolhida a mao
    readonly property var manual: {
        const accent = Config.options.widgetAccent || Config.options.accent;
        // Fundo claro -> texto escuro
        const light = onColor(Config.options.widgetBackground) !== "#f4f6f7";
        return {
            "accent": accent,
            "bg": Config.options.widgetBackground,
            "fg": light ? "#1b1d1f" : "#e6e9ec",
            "fgDim": light ? "#4a4f55" : "#a3abb3",
            "fgMuted": light ? "#6c757d" : "#6c757d",
            "onAccent": onColor(accent)
        };
    }

    // Paleta do wallpaper em uso agora
    readonly property var current: forWallpaper(Config.options.wallpaper)

    // miniatura -> paleta
    property var cache: ({})
    property var queue: []

    // Texto escuro ou claro, conforme a cor de fundo
    function onColor(c) {
        const col = Qt.color(c);
        const lum = 0.2126 * col.r + 0.7152 * col.g + 0.0722 * col.b;
        return lum > 0.55 ? "#14201e" : "#f4f6f7";
    }

    function forWallpaper(path) {
        return forThumb(Wallpapers.thumbFor(path));
    }

    function forThumb(thumb) {
        if (!dynamic || !thumb || thumb.startsWith("http"))
            return manual;
        const c = cache[thumb];
        if (c)
            return c;
        Qt.callLater(request, thumb);
        return manual;
    }

    // Wallpaper claro? (usa o brilho medio calculado pelo palette.py)
    function isLight(thumb) {
        if (!thumb || thumb.startsWith("http"))
            return false;
        const c = cache[thumb];
        if (!c) {
            Qt.callLater(request, thumb);
            return false;
        }
        return (c.lum ?? 0) > 0.55;
    }

    // Com bastante transparencia num wallpaper claro, o texto branco some: usa texto escuro
    function glassText(transparency, thumb) {
        return transparency >= 0.4 && isLight(thumb);
    }

    readonly property var darkText: ({
            "fg": "#1c1a1e",
            "fgDim": "#3b3540",
            "fgMuted": "#5d5662"
        })

    function request(thumb) {
        if (cache[thumb] || queue.includes(thumb))
            return;
        queue = queue.concat([thumb]);
        next();
    }

    function next() {
        if (proc.running || queue.length === 0)
            return;
        proc.thumb = queue[0];
        proc.command = ["python3", "-I", Quickshell.shellPath("scripts/palette.py"), queue[0]];
        proc.running = true;
    }

    Process {
        id: proc

        property string thumb

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const p = JSON.parse(text);
                    if (!p.error) {
                        const c = Object.assign({}, root.cache);
                        c[proc.thumb] = p;
                        root.cache = c;
                    }
                } catch (e) {}
            }
        }

        onExited: {
            root.queue = root.queue.filter(t => t !== proc.thumb);
            root.next();
        }
    }
}
