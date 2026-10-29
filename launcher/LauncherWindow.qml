import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.bar

// Window of the Bar X menu (state in services/Launcher.qml). Covers the monitor so a click
// outside the menu closes it, and shows the menu in the chosen style (Launcher.style):
// PanelMenu, SpotlightMenu, CurtainMenu or OrbitMenu. Each one gets:
//   place    -> "top" | "bottom" | "side" (where the Bar X taskbar is) or "center" (no bar there)
//   barSpace -> distance from that screen edge to just past the bar
//   shown    -> false -> true right after it appears (so it can animate in), back to false on close
PanelWindow {
    id: root

    readonly property var targetScreen: Quickshell.screens.find(s => s.name === Launcher.screenName) ?? Ui.screen
    readonly property bool barHere: Config.options.barProvider === "uix" && targetScreen !== null && Config.monitorBar(targetScreen.name)
    readonly property string place: barHere ? BarStyle.kind : "center"
    readonly property bool dims: Launcher.style === "panel" || Launcher.style === "spotlight"

    property bool alive: false
    property bool shown: false

    screen: targetScreen
    visible: alive
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    WlrLayershell.namespace: "uix-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Launcher.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Connections {
        target: Launcher
        function onOpenChanged() {
            if (Launcher.open) {
                hideTimer.stop();
                root.alive = true;
                showTimer.restart();
            } else {
                root.shown = false;
                hideTimer.restart();
            }
        }
        // "All apps" from the curtain / orbit: the panel takes their place
        function onStyleChanged() {
            if (Launcher.open)
                showTimer.restart();
        }
    }

    // One frame after the window appears, so the menu animates from its closed state
    Timer {
        id: showTimer
        interval: 16
        onTriggered: {
            root.shown = true;
            if (loader.item)
                loader.item.opened();
        }
    }

    // Keeps the window until the closing animation ends
    Timer {
        id: hideTimer
        interval: 450
        onTriggered: root.alive = false
    }

    // Slightly darker screen behind the panel and spotlight; a click outside closes the menu
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.shown && root.dims ? 0.25 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animNormal
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Launcher.close()
    }

    Loader {
        id: loader
        anchors.fill: parent
        active: root.alive
        sourceComponent: Launcher.style === "spotlight" ? spotlight : Launcher.style === "curtain" ? curtain : Launcher.style === "orbit" ? orbit : panel
    }

    Component {
        id: panel
        PanelMenu {
            place: root.place
            barSpace: BarStyle.gap + BarStyle.thickness + 10
            shown: root.shown
        }
    }
    Component {
        id: spotlight
        SpotlightMenu {
            place: root.place
            shown: root.shown
        }
    }
    Component {
        id: curtain
        CurtainMenu {
            place: root.place
            barSpace: BarStyle.gap + BarStyle.thickness + 10
            shown: root.shown
        }
    }
    Component {
        id: orbit
        OrbitMenu {
            place: root.place
            shown: root.shown
        }
    }
}
