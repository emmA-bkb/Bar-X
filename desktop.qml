import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config
import qs.bar
import qs.launcher
import qs.services
import qs.widgets

// What lives on the desktop: the Uix bar, the widgets and the menu (launcher).
// Runs separately from the settings window, so it keeps running with Uix closed.
// Reads ~/.config/uix/config.json and updates itself when the preset, style or layout changes.
//   qs -p <Uix folder>/desktop.qml
ShellRoot {
    id: shell

    // Dim preview asked by the Monitors page: monitor name and level, for a few seconds
    property string previewMonitor: ""
    property real previewLevel: 0

    Variants {
        model: Quickshell.screens

        delegate: Bar {}
    }

    DesktopWidgets {}

    Variants {
        model: Quickshell.screens

        delegate: ScreenDim {
            previewLevel: shell.previewMonitor === modelData.name ? shell.previewLevel : -1
        }
    }

    LauncherWindow {}

    // qs -p <folder>/desktop.qml ipc call launcher toggle   (e.g. on a keyboard shortcut)
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            Launcher.toggle("");
        }
        // ("show" would clash with the "qs ipc show" command)
        function open(): void {
            Launcher.show("");
        }
        function hide(): void {
            Launcher.close();
        }
    }

    Timer {
        id: previewTimer
        interval: 2500
        onTriggered: shell.previewMonitor = ""
    }

    // Blur behind the bar and widgets (glass effect). It's a Hyprland rule created at
    // runtime (it doesn't touch hyprland.lua); it's gone when Hyprland reloads, so it is
    // applied again on startup and on every "configreloaded".
    function applyBlurRule() {
        if (Hyprland.usingLua)
            Quickshell.execDetached(["hyprctl", "eval", 'hl.layer_rule({ name = "uix-glass", match = { namespace = "^uix-(bar|widget|launcher)$" }, blur = true, ignore_alpha = 0.02 })']);
    }

    Component.onCompleted: applyBlurRule()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") {
                applyBlurRule();
                // A reload resets monitors to hyprland.lua: put back the layout saved in Uix
                Quickshell.execDetached(["python3", "-I", Quickshell.shellPath("scripts/monitors.py"), "apply"]);
            }
            if (["fullscreen", "workspace", "workspacev2", "focusedmon", "focusedmonv2", "activespecial", "activespecialv2", "openwindow", "closewindow", "movewindow", "movewindowv2", "changefloatingmode"].includes(event.name))
                pauseDelay.restart();
        }
    }

    // Pauses the wallpaper of monitors covered by a fullscreen window (or any window, per the
    // setting) so it stops using the GPU, see scripts/wallpaper-pause.py. Runs on window and
    // workspace changes, and every few seconds to catch wallpapers that were just started.
    Timer {
        id: pauseDelay
        interval: 150
        onTriggered: {
            if (!pauseProc.running)
                pauseProc.running = true;
        }
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: pauseDelay.restart()
    }

    Process {
        id: pauseProc
        command: ["python3", "-I", Quickshell.shellPath("scripts/wallpaper-pause.py"), Config.options.wallpaperPause]
        onCommandChanged: pauseDelay.restart()
    }

    // qs -p <folder>/desktop.qml ipc call uixdesktop quit
    IpcHandler {
        target: "uixdesktop"

        function quit(): void {
            Qt.quit();
        }

        // Shows how dark a monitor gets, for a moment (Monitors page)
        function dimPreview(monitor: string, level: real): void {
            shell.previewMonitor = monitor;
            shell.previewLevel = level;
            previewTimer.restart();
        }
    }
}
