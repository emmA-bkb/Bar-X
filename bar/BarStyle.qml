pragma Singleton
import QtQuick
import Quickshell
import qs.config
import qs.services

// Medidas e cores da barra, conforme o estilo do preset ativo.
//   floating / island / minimal / tonal -> em cima
//   bottom -> doca pequena centralizada embaixo
//   side   -> vertical no lado esquerdo
Singleton {
    // UIX_BAR_STYLE forca um estilo (para testes)
    readonly property string style: Quickshell.env("UIX_BAR_STYLE") || Config.currentBarStyle()
    // Posicao: "bottom..." = embaixo, "side..." = lateral, o resto = em cima
    readonly property string kind: style.startsWith("bottom") ? "bottom" : style.startsWith("side") ? "side" : "top"
    readonly property bool vertical: kind === "side"
    readonly property bool minimal: style === "minimal" || style === "side-minimal"
    readonly property bool tonal: style === "tonal" || style.endsWith("-tonal")
    // Ilhas = grupos em pilulas separadas (na doca e sempre uma pilula so)
    readonly property bool island: style === "island" || style === "side-island" || (tonal && kind !== "bottom")

    // Espessura da barra (altura; largura na lateral)
    readonly property int thickness: minimal ? (vertical ? 36 : 30) : kind === "bottom" ? 50 : kind === "side" ? 46 : 40
    readonly property int height: thickness
    readonly property int gap: minimal ? 0 : kind === "bottom" ? 8 : 6 // distancia da borda da tela
    readonly property int sideMargin: minimal ? 0 : 10
    readonly property int itemHeight: minimal ? 20 : kind === "bottom" ? 36 : 28

    // Cores: as do app, ou as dos widgets (manual/wallpaper) se "dynamicBarColors" estiver ligado
    readonly property var colors: Config.options.dynamicBarColors ? Colors.current : null
    // Efeito vidro (transparencia do preset ativo) e texto escuro em wallpaper claro
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
    // No vidro a borda fica um pouco mais clara, como um reflexo
    readonly property color border: tonal ? Qt.rgba(accent.r, accent.g, accent.b, 0.25) : glass > 0 ? Qt.rgba(1, 1, 1, 0.22) : "#1fffffff"

    function luminance(c) {
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
    }

    // Cor da florzinha (Tonal) e da area ativa. Automatico: a cor de destaque, mas se ela
    // sumir no fundo da barra (ex.: preto no escuro) vira branca (ou preta num fundo claro).
    readonly property color active: {
        if (Config.options.barActiveColor)
            return Config.options.barActiveColor;
        const bgLum = luminance(background);
        if (Math.abs(luminance(accent) - bgLum) >= 0.25)
            return accent;
        return bgLum < 0.5 ? "#ffffff" : "#000000";
    }
    // Texto em cima da florzinha
    readonly property color onActive: luminance(active) > 0.55 ? "#14201e" : "#f4f6f7"
}
