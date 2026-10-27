import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config
import qs.bar
import qs.widgets

// O que fica na area de trabalho: a barra do Uix e os widgets.
// Roda separado da janela de configuracoes, entao continua com o Uix fechado.
// Le ~/.config/uix/config.json e muda sozinho quando o preset, o estilo ou o layout mudam.
//   qs -p <pasta do Uix>/desktop.qml
ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Bar {}
    }

    DesktopWidgets {}

    // Desfoque atras da barra e dos widgets (efeito vidro). E uma regra do Hyprland criada em
    // tempo de execucao (nao mexe no hyprland.lua); some quando o Hyprland recarrega, entao e
    // aplicada de novo ao iniciar e a cada "configreloaded".
    function applyBlurRule() {
        if (Hyprland.usingLua)
            Quickshell.execDetached(["hyprctl", "eval", 'hl.layer_rule({ name = "uix-glass", match = { namespace = "^uix-(bar|widget)$" }, blur = true, ignore_alpha = 0.02 })']);
    }

    Component.onCompleted: applyBlurRule()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                applyBlurRule();
        }
    }

    // qs -p <pasta>/desktop.qml ipc call uixdesktop quit
    IpcHandler {
        target: "uixdesktop"

        function quit(): void {
            Qt.quit();
        }
    }
}
