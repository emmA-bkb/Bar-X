pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Informacoes do sistema mostradas no perfil + controle da barra de tarefas.
Singleton {
    id: root

    readonly property string user: Quickshell.env("USER")
    readonly property string face: Quickshell.env("HOME") + "/.face"
    property string distro: "Linux"
    property bool waybarRunning: false
    property bool uixBarRunning: false // processo desktop.qml (barra + widgets)

    readonly property string startBarScript: Quickshell.shellPath("scripts/uix-start.sh")

    function checkBars() {
        waybarCheck.running = true;
        uixBarCheck.running = true;
    }

    function reloadWaybar() {
        Quickshell.execDetached(["pkill", "-SIGUSR2", "-x", "waybar"]);
    }

    // Troca entre a Waybar e a barra do Uix
    function applyBar(provider) {
        Config.options.barProvider = provider;
        syncDesktop();
    }

    // Liga/desliga os widgets na area de trabalho
    function setWidgetsEnabled(enabled) {
        Config.options.widgetsEnabled = enabled;
        syncDesktop();
    }

    function syncDesktop() {
        Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/desktop.sh"), Config.options.barProvider, Config.options.widgetsEnabled ? "1" : "0"]);
        recheck.restart();
    }

    Timer {
        id: recheck
        interval: 1500
        onTriggered: root.checkBars()
    }

    FileView {
        path: "/etc/os-release"
        onLoaded: {
            const m = text().match(/^NAME="?([^"\n]+)"?/m);
            if (m)
                root.distro = m[1];
        }
    }

    Process {
        id: waybarCheck
        command: ["pgrep", "-x", "waybar"]
        onExited: code => root.waybarRunning = code === 0
    }

    Process {
        id: uixBarCheck
        command: ["pgrep", "-f", "qs -p " + Quickshell.shellPath("desktop.qml")]
        onExited: code => root.uixBarRunning = code === 0
    }

    Component.onCompleted: checkBars()
}
