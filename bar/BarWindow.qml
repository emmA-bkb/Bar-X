import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// Base das janelas de barra (em cima, embaixo, lateral).
PanelWindow {
    // Modo de teste: UIX_BAR_PREVIEW=1 mostra a barra sem reservar espaco, por cima de tudo
    readonly property bool preview: Quickshell.env("UIX_BAR_PREVIEW") === "1"

    visible: preview || Config.options.barProvider === "uix"
    color: "transparent"
    exclusiveZone: preview ? 0 : BarStyle.thickness + BarStyle.gap
    exclusionMode: preview ? ExclusionMode.Ignore : ExclusionMode.Normal

    WlrLayershell.namespace: "uix-bar"
    WlrLayershell.layer: preview ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
}
