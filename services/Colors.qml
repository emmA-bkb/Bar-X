pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Widget colors (and, if enabled, the bar's).
//   widgetColorMode = "wallpaper" -> taken from the wallpaper (scripts/palette.py, cached)
//   widgetColorMode = "manual"    -> chosen in Appearance
Singleton {
    id: root

    readonly property bool dynamic: Config.options.widgetColorMode === "wallpaper"

    // Hand-picked palette
    readonly property var manual: {
        const accent = Config.options.widgetAccent || Config.options.accent;
        // Light background -> dark text
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

    // Palette of the wallpaper in use now
    readonly property var current: forWallpaper(Config.options.wallpaper)

    // thumbnail -> palette
    property var cache: ({})
    property var queue: []

    // Dark or light text, depending on the background color
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

    // Light wallpaper? (uses the average brightness computed by palette.py)
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

    // With a lot of transparency on a light wallpaper, white text disappears: use dark text
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
