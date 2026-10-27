import QtQuick
import qs.config

// Bolinha de cor clicavel (com check quando selecionada).
Rectangle {
    id: root

    property bool selected: false
    property string label: "" // texto dentro (ex.: "Auto")
    signal clicked

    width: 34
    height: 34
    radius: 17
    scale: mouse.containsMouse ? 1.1 : 1
    border.width: selected ? 3 : 1
    border.color: selected ? Theme.text : Theme.border

    Behavior on scale {
        NumberAnimation {
            duration: Theme.animFast
        }
    }

    StyledText {
        anchors.centerIn: parent
        visible: root.label !== ""
        text: root.label
        color: Theme.textDim
        font.pixelSize: 10
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
