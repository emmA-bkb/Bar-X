import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

// Top bar: Floating, Islands (pills), Minimal or Tonal.
BarWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: BarStyle.thickness + BarStyle.gap * 2
    margins.top: preview ? 52 : 0

    // Full background (Floating and Minimal)
    Rectangle {
        visible: !BarStyle.island
        x: BarStyle.sideMargin
        y: BarStyle.gap
        width: bar.width - BarStyle.sideMargin * 2
        height: BarStyle.thickness
        radius: BarStyle.minimal ? 0 : height / 2
        color: BarStyle.background
        border.width: BarStyle.minimal ? 0 : 1
        border.color: BarStyle.border

        Rectangle {
            visible: BarStyle.minimal
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: BarStyle.border
        }
    }

    BarSection {
        pill: BarStyle.island
        padding: 6
        x: BarStyle.sideMargin + (BarStyle.island ? 0 : 6)
        y: BarStyle.gap

        BarButton {
            visible: Config.launcherCommand() !== ""
            icon: Icons.menu
            onClicked: Quickshell.execDetached(["bash", "-c", Config.launcherCommand()])
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
        padding: 18
        anchors.horizontalCenter: parent.horizontalCenter
        y: BarStyle.gap

        Clock {}
    }

    BarSection {
        id: right
        pill: BarStyle.island
        padding: 8
        x: bar.width - width - BarStyle.sideMargin - (BarStyle.island ? 0 : 6)
        y: BarStyle.gap

        Tray {
            window: bar
        }
        Stats {}
        BarButton {
            icon: Icons.tune
            onClicked: Quickshell.execDetached([Quickshell.shellPath("uix")])
        }
    }
}
