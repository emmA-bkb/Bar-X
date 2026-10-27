import QtQuick
import Quickshell
import qs.config
import qs.components

Item {
    Column {
        anchors.centerIn: parent
        spacing: 14

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 84
            height: 84
            radius: 26
            color: Theme.alpha(Theme.accent, 0.16)

            StyledText {
                anchors.centerIn: parent
                text: "Uix"
                color: Theme.accent
                font.pixelSize: 28
                font.weight: Font.Bold
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Uix 0.1.0"
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Presets de wallpaper + barra de tarefas para Hyprland"
            color: Theme.textDim
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Config.path
            color: Theme.textMuted
            font.pixelSize: 12
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 6
            spacing: 8

            StyledButton {
                icon: Icons.folder
                text: "Abrir pasta"
                onClicked: Quickshell.execDetached(["xdg-open", Config.dir])
            }
            StyledButton {
                icon: Icons.code
                text: "Editar config"
                onClicked: Quickshell.execDetached(["xdg-open", Config.path])
            }
        }
    }
}
