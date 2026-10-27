import QtQuick
import Quickshell

// Uix taskbar for one monitor. Creates the right window for the preset's style:
// top, bottom dock or side. When the style changes, the old window is replaced by the new one.
Scope {
    id: root

    required property var modelData

    LazyLoader {
        active: BarStyle.kind === "top"

        TopBar {
            screen: root.modelData
            screenName: root.modelData.name
        }
    }

    LazyLoader {
        active: BarStyle.kind === "bottom"

        BottomBar {
            screen: root.modelData
            screenName: root.modelData.name
        }
    }

    LazyLoader {
        active: BarStyle.kind === "side"

        SideBar {
            screen: root.modelData
            screenName: root.modelData.name
        }
    }
}
