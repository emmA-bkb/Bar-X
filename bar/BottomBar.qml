import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

// Doca: pequena, centralizada na parte de baixo da tela.
BarWindow {
    id: bar

    // So a borda de baixo: o compositor centraliza na horizontal
    anchors.bottom: true

    implicitWidth: dock.implicitWidth
    implicitHeight: BarStyle.thickness + BarStyle.gap
    margins.bottom: 0

    BarSection {
        id: dock
        pill: true
        padding: 8
        y: 0

        BarButton {
            visible: Config.launcherCommand() !== ""
            icon: Icons.menu
            onClicked: Quickshell.execDetached(["bash", "-c", Config.launcherCommand()])
        }
        Workspaces {
            monitor: Hyprland.monitorFor(bar.screen)
        }
        BarDivider {}
        Taskbar {}
        BarDivider {}
        Clock {}
        Tray {
            window: bar
        }
        BarButton {
            icon: Icons.tune
            onClicked: Quickshell.execDetached([Quickshell.shellPath("uix")])
        }
    }
}
