import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.config

// Bandeja do sistema. Clique ativa, botao direito abre o menu do app.
BarGroup {
    id: root

    property var window: null

    spacing: 2

    Repeater {
        model: SystemTray.items

        delegate: Rectangle {
            id: trayItem

            required property var modelData

            width: BarStyle.itemHeight
            height: BarStyle.itemHeight
            radius: height / 2
            color: mouse.containsMouse ? BarStyle.hover : "transparent"

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: trayItem.modelData.icon
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    const item = trayItem.modelData;
                    if (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && item.onlyMenu)) {
                        if (item.hasMenu && root.window) {
                            const p = BarStyle.vertical ? trayItem.mapToItem(null, trayItem.width + 6, 0) : BarStyle.kind === "bottom" ? trayItem.mapToItem(null, 0, -6) : trayItem.mapToItem(null, 0, trayItem.height + 6);
                            item.display(root.window, p.x, p.y);
                        }
                    } else if (mouse.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else {
                        item.activate();
                    }
                }
            }
        }
    }
}
