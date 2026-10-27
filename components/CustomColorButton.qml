import QtQuick
import qs.config

// Bolinha arco-iris que abre o seletor de cor livre.
// Se a cor atual nao for uma das bolinhas prontas (presets), mostra a cor escolhida com um check.
Rectangle {
    id: root

    property string current: ""
    property var presets: []
    property real size: 34
    readonly property bool isCustom: current !== "" && !presets.includes(current)

    signal clicked

    width: size
    height: size
    radius: size / 2
    scale: mouse.containsMouse ? 1.1 : 1
    border.width: isCustom ? 3 : 0
    border.color: Theme.text

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
            position: 0
            color: root.isCustom ? root.current : "#ff5f6d"
        }
        GradientStop {
            position: 0.35
            color: root.isCustom ? root.current : "#ffc371"
        }
        GradientStop {
            position: 0.65
            color: root.isCustom ? root.current : "#47e891"
        }
        GradientStop {
            position: 1
            color: root.isCustom ? root.current : "#6a82fb"
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.animFast
        }
    }

    Icon {
        anchors.centerIn: parent
        path: root.isCustom ? Icons.check : Icons.add
        size: root.size * 0.5
        color: root.isCustom ? (Qt.color(root.current).hslLightness > 0.6 ? "#14201e" : "#ffffff") : "#ffffff"
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
