import QtQuick
import qs.config
import qs.components

// Search box of the menu. Emits edited(value) as the text changes and key(event) for every key,
// so the menu can handle arrows, Enter and Esc (set event.accepted to keep the key).
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: "Search apps, or type a calculation…"
    property int fontSize: 15

    signal edited(string value)
    signal key(var event)

    function clear() {
        input.text = "";
    }

    function focusInput() {
        input.forceActiveFocus();
    }

    height: 48
    radius: height / 2
    color: Theme.surfaceHover
    border.width: 1
    border.color: input.activeFocus ? Theme.alpha(Theme.accent, 0.55) : "transparent"

    Icon {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: root.height * 0.36
        anchors.verticalCenter: parent.verticalCenter
        path: Icons.search
        size: Math.round(root.height * 0.4)
        color: Theme.textDim
    }

    TextInput {
        id: input
        anchors.left: icon.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: root.fontSize
        selectionColor: Theme.alpha(Theme.accent, 0.4)
        clip: true

        onTextChanged: root.edited(text)
        Keys.onPressed: event => root.key(event)

        StyledText {
            visible: input.text === ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: Theme.textMuted
            font.pixelSize: root.fontSize
        }
    }
}
