import QtQuick
import Quickshell

// Barra de tarefas do Uix para um monitor. Cria a janela certa para o estilo do preset:
// em cima, doca embaixo ou lateral. Ao trocar de estilo, a janela antiga e trocada pela nova.
Scope {
    id: root

    required property var modelData

    LazyLoader {
        active: BarStyle.kind === "top"

        TopBar {
            screen: root.modelData
        }
    }

    LazyLoader {
        active: BarStyle.kind === "bottom"

        BottomBar {
            screen: root.modelData
        }
    }

    LazyLoader {
        active: BarStyle.kind === "side"

        SideBar {
            screen: root.modelData
        }
    }
}
