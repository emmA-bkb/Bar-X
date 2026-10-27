import QtQuick
import qs.config
import qs.components

// Widget layout chip. Click selects, double click renames.
Rectangle {
    id: root

    property var layout
    readonly property bool active: Config.options.activeLayout === layout.id
    property bool editing: false

    implicitWidth: (editing ? Math.max(90, input.contentWidth + 24) : label.implicitWidth + 32) + (removeButton.visible ? 24 : 0)
    implicitHeight: 36
    radius: 18
    color: active ? Theme.alpha(Theme.accent, 0.18) : mouse.containsMouse ? Theme.surfaceHover : Theme.surface
    border.width: 1
    border.color: active ? Theme.alpha(Theme.accent, 0.5) : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }

    function finishRename() {
        const name = input.text.trim();
        if (name !== "" && name !== layout.name)
            Config.updateLayout(layout.id, {
                "name": name
            });
        editing = false;
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Config.setActiveLayout(root.layout.id)
        onDoubleClicked: {
            input.text = root.layout.name;
            root.editing = true;
            input.forceActiveFocus();
            input.selectAll();
        }
    }

    StyledText {
        id: label
        visible: !root.editing
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: root.layout.name
        color: root.active ? Theme.text : Theme.textDim
        font.weight: root.active ? Font.DemiBold : Font.Normal
    }

    TextInput {
        id: input
        visible: root.editing
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.text
        selectionColor: Theme.alpha(Theme.accent, 0.4)
        font.family: Theme.font
        font.pixelSize: 13
        onAccepted: root.finishRename()
        onActiveFocusChanged: if (!activeFocus && root.editing)
            root.finishRename()
        Keys.onEscapePressed: root.editing = false
    }

    IconButton {
        id: removeButton
        visible: root.active && !root.editing && Config.options.widgetLayouts.length > 1
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 24
        implicitHeight: 24
        icon: Icons.close
        iconSize: 14
        iconColor: Theme.textDim
        baseColor: "transparent"
        onClicked: {
            const name = root.layout.name;
            Config.removeLayout(root.layout.id);
            Ui.notify("Layout \"" + name + "\" removed");
        }
    }
}
