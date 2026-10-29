import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config

// Dims one monitor after a while without use (Monitors page -> "Dim after inactivity").
//   dimAfter: minutes without input (0 = off); idle inhibitors (videos, games) keep it bright
//   dimLevel: how dark it gets (0..1)
//   dimAway:  also dims while you use the other monitors (time since the mouse left this one)
// It's a black layer over the monitor that lets clicks through. The window only exists while
// dimming, so it never sits on top of a fullscreen game when it isn't needed.
PanelWindow {
    id: root

    required property var modelData
    // Level shown for a moment while it's being adjusted in Uix (-1 = no preview)
    property real previewLevel: -1

    readonly property var settings: Config.monitorSettings(modelData.name)
    readonly property int dimAfter: settings.dimAfter ?? 0
    readonly property real level: settings.dimLevel ?? 0.6
    readonly property bool away: settings.dimAway === true
    readonly property bool focused: Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === modelData.name

    property bool awayExpired: false
    readonly property bool dimmed: dimAfter > 0 && (idle.isIdle || (away && awayExpired && !focused))
    readonly property real target: previewLevel >= 0 ? previewLevel : dimmed ? level : 0

    screen: modelData
    visible: target > 0 || shade.opacity > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    // Empty input region: clicks and the mouse go to whatever is below
    mask: Region {}

    WlrLayershell.namespace: "uix-dim"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    IdleMonitor {
        id: idle
        enabled: root.dimAfter > 0
        timeout: Math.max(1, root.dimAfter) * 60
        respectInhibitors: true
    }

    // Time since the mouse left this monitor
    Timer {
        id: awayTimer
        interval: Math.max(1, root.dimAfter) * 60 * 1000
        running: root.away && root.dimAfter > 0 && !root.focused
        onRunningChanged: if (running) root.awayExpired = false
        onTriggered: root.awayExpired = true
    }

    onFocusedChanged: if (focused) awayExpired = false

    Rectangle {
        id: shade
        anchors.fill: parent
        color: "#000000"
        opacity: root.target

        // Slow fade when dimming, quick when coming back
        Behavior on opacity {
            NumberAnimation {
                duration: shade.opacity < root.target && root.previewLevel < 0 ? 2000 : 300
                easing.type: Easing.InOutQuad
            }
        }
    }
}
