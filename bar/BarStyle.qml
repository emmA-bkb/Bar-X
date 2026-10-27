pragma Singleton
import QtQuick
import Quickshell
import qs.config
import qs.services

// Bar sizes and colors, based on the active preset's style.
//   floating / island / minimal / tonal -> top
//   bottom -> small dock centered at the bottom
//   side   -> vertical on the left side
Singleton {
    // UIX_BAR_STYLE forces a style (for testing)
    readonly property string style: Quickshell.env("UIX_BAR_STYLE") || Config.currentBarStyle()
    // Position: "bottom..." = bottom, "side..." = side, anything else = top
    readonly property string kind: style.startsWith("bottom") ? "bottom" : style.startsWith("side") ? "side" : "top"
    readonly property bool vertical: kind === "side"
    readonly property bool minimal: style === "minimal" || style === "side-minimal"
    readonly property bool tonal: style === "tonal" || style.endsWith("-tonal")
    // Islands = groups in separate pills (the dock is always a single pill)
    readonly property bool island: style === "island" || style === "side-island" || (tonal && kind !== "bottom")

    // Bar thickness (height; width on the side bar)
    readonly property int thickness: minimal ? (vertical ? 36 : 30) : kind === "bottom" ? 50 : kind === "side" ? 46 : 40
    readonly property int height: thickness
    readonly property int gap: minimal ? 0 : kind === "bottom" ? 8 : 6 // distance from the screen edge
    readonly property int sideMargin: minimal ? 0 : 10
    readonly property int itemHeight: minimal ? 20 : kind === "bottom" ? 36 : 28

    // Colors: the app's, or the widgets' (manual/wallpaper) if "dynamicBarColors" is on
    readonly property var colors: Config.options.dynamicBarColors ? Colors.current : null
    // Glass effect (active preset's transparency) and dark text on a light wallpaper
    readonly property real glass: Config.currentTransparency()
    readonly property bool darkText: Colors.glassText(glass, Wallpapers.thumbFor(Config.options.wallpaper))

    readonly property color accent: colors ? colors.accent : Theme.accent
    readonly property color onAccent: colors ? colors.onAccent : Theme.accentText
    readonly property color text: darkText ? Colors.darkText.fg : colors ? colors.fg : Theme.text
    readonly property color textDim: darkText ? Colors.darkText.fgDim : colors ? colors.fgDim : Theme.textDim
    readonly property color hover: Qt.rgba(text.r, text.g, text.b, 0.12)
    readonly property color base: colors ? colors.bg : "#131618"

    readonly property color background: {
        const c = tonal ? Qt.tint(base, Qt.rgba(accent.r, accent.g, accent.b, 0.22)) : base;
        return Qt.rgba(c.r, c.g, c.b, (minimal ? 0.95 : 0.9) * (1 - glass * 0.85));
    }
    // On glass the border is a bit lighter, like a reflection
    readonly property color border: tonal ? Qt.rgba(accent.r, accent.g, accent.b, 0.25) : glass > 0 ? Qt.rgba(1, 1, 1, 0.22) : "#1fffffff"

    function luminance(c) {
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
    }

    // Color of the flower (Tonal) and the active workspace. Automatic: the accent color, but if it
    // disappears against the bar background (e.g. black on dark) it turns white (or black on a light background).
    readonly property color active: {
        if (Config.options.barActiveColor)
            return Config.options.barActiveColor;
        const bgLum = luminance(background);
        if (Math.abs(luminance(accent) - bgLum) >= 0.25)
            return accent;
        return bgLum < 0.5 ? "#ffffff" : "#000000";
    }
    // Text on top of the flower
    readonly property color onActive: luminance(active) > 0.55 ? "#14201e" : "#f4f6f7"
}
