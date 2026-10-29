import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services

// Side bar (left), top to bottom. Variants:
//   side         -> one full rounded bar
//   side-island  -> three separate pills (top, middle, bottom)
//   side-tonal   -> pills tinted with the theme color
//   side-minimal -> thin, against the edge, only the essentials
BarWindow {
    id: bar

    anchors {
        left: true
        top: true
        bottom: true
    }

    implicitWidth: BarStyle.thickness + BarStyle.gap * 2

    // Bar area (the full background only shows on Full and Minimal)
    Rectangle {
        id: background
        x: BarStyle.gap
        y: BarStyle.gap
        width: BarStyle.thickness
        height: bar.height - BarStyle.gap * 2
        radius: BarStyle.minimal ? 0 : width / 2
        color: BarStyle.island ? "transparent" : BarStyle.background
        border.width: BarStyle.island || BarStyle.minimal ? 0 : 1
        border.color: BarStyle.border

        // Minimal: just a line on the right edge
        Rectangle {
            visible: BarStyle.minimal
            anchors.right: parent.right
            width: 1
            height: parent.height
            color: BarStyle.border
        }
    }

    BarSection {
        pill: BarStyle.island
        padding: 8
        anchors.horizontalCenter: background.horizontalCenter
        anchors.top: background.top
        anchors.topMargin: BarStyle.island ? 0 : 8

        BarButton {
            icon: Icons.menu
            // The Bar X menu, or the command set in UIX_LAUNCHER (.env)
            onClicked: Config.launcherCommand() !== "" ? Quickshell.execDetached(["bash", "-c", Config.launcherCommand()]) : Launcher.toggle(bar.screenName)
        }
        Workspaces {
            monitor: Hyprland.monitorFor(bar.screen)
        }
        BarDivider {
            visible: !BarStyle.minimal
        }
        Taskbar {
            visible: !BarStyle.minimal
        }
    }

    BarSection {
        pill: BarStyle.island
        padding: 10
        anchors.centerIn: background

        Clock {}
    }

    BarSection {
        pill: BarStyle.island
        padding: 8
        anchors.horizontalCenter: background.horizontalCenter
        anchors.bottom: background.bottom
        anchors.bottomMargin: BarStyle.island ? 0 : 8

        Tray {
            window: bar
        }
        Stats {
            visible: !BarStyle.minimal
        }
        BarButton {
            icon: Icons.tune
            onClicked: Quickshell.execDetached([Quickshell.shellPath("uix")])
        }
    }
}
