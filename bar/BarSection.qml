import QtQuick
import qs.config

// Grupo de modulos da barra. Com pill = true vira uma pilula (estilos Ilhas, Tonal e doca).
Rectangle {
    id: root

    property bool pill: false
    property int padding: 12
    default property alias content: group.data

    implicitWidth: BarStyle.vertical ? BarStyle.thickness : group.implicitWidth + (pill ? padding * 2 : 0)
    implicitHeight: BarStyle.vertical ? group.implicitHeight + (pill ? padding * 2 : 0) : BarStyle.thickness
    radius: Math.min(width, height) / 2
    color: pill ? BarStyle.background : "transparent"
    border.width: pill ? 1 : 0
    border.color: BarStyle.border

    BarGroup {
        id: group
        anchors.centerIn: parent
        spacing: 8
    }
}
