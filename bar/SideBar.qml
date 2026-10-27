import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

// Barra lateral (esquerda), de cima a baixo. Variacoes:
//   side         -> uma barra inteira arredondada
//   side-island  -> tres pilulas separadas (em cima, meio, embaixo)
//   side-tonal   -> pilulas tingidas com a cor do tema
//   side-minimal -> fina, colada na borda, so o essencial
BarWindow {
    id: bar

    anchors {
        left: true
        top: true
        bottom: true
    }

    implicitWidth: BarStyle.thickness + BarStyle.gap * 2

    // Area da barra (o fundo inteiro aparece so na Inteira e na Minimalista)
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

        // Minimalista: so uma linha na borda direita
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
            onClicked: Quickshell.execDetached(["bash", "-c", Config.options.launcherCommand])
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
