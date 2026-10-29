import QtQuick
import qs.config

// Lock / suspend / log out / restart / shut down (the last three ask for a second click).
Row {
    spacing: 6

    PowerButton {
        icon: Icons.lock
        label: "Lock"
        action: "lock"
    }
    PowerButton {
        icon: Icons.moon
        label: "Suspend"
        action: "suspend"
    }
    PowerButton {
        icon: Icons.logout
        label: "Log out"
        action: "logout"
        confirm: true
    }
    PowerButton {
        icon: Icons.refresh
        label: "Restart"
        action: "reboot"
        confirm: true
    }
    PowerButton {
        icon: Icons.power
        label: "Shut down"
        action: "poweroff"
        confirm: true
    }
}
