import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services

// Dock: small, centered at the bottom of the screen.
BarWindow {
    id: bar

    // Only the bottom edge: the compositor centers it horizontally
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
            icon: Icons.menu
            // The Bar X menu, or the command set in UIX_LAUNCHER (.env)
            onClicked: Config.launcherCommand() !== "" ? Quickshell.execDetached(["bash", "-c", Config.launcherCommand()]) : Launcher.toggle(bar.screenName)
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
