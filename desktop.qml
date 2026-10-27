import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config
import qs.bar
import qs.widgets

// What lives on the desktop: the Uix bar and the widgets.
// Runs separately from the settings window, so it keeps running with Uix closed.
// Reads ~/.config/uix/config.json and updates itself when the preset, style or layout changes.
//   qs -p <Uix folder>/desktop.qml
ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Bar {}
    }

    DesktopWidgets {}

    // Blur behind the bar and widgets (glass effect). It's a Hyprland rule created at
    // runtime (it doesn't touch hyprland.lua); it's gone when Hyprland reloads, so it is
    // applied again on startup and on every "configreloaded".
    function applyBlurRule() {
        if (Hyprland.usingLua)
            Quickshell.execDetached(["hyprctl", "eval", 'hl.layer_rule({ name = "uix-glass", match = { namespace = "^uix-(bar|widget)$" }, blur = true, ignore_alpha = 0.02 })']);
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
        }
    }

    // qs -p <folder>/desktop.qml ipc call uixdesktop quit
    IpcHandler {
        target: "uixdesktop"

        function quit(): void {
            Qt.quit();
        }
    }
}
