import QtQuick
import qs.config
import qs.components
import qs.services
import qs.launcher

// Popup listing every app with a search: clicking one pins or unpins it in the menu.
Rectangle {
    id: root

    property string query: ""
    readonly property var filtered: {
        const q = query.trim().toLowerCase();
        return q === "" ? Launcher.apps : Launcher.apps.filter(e => e.name.toLowerCase().includes(q) || (e.genericName ?? "").toLowerCase().includes(q));
    }

    signal closed

    color: "#b0000000"
    radius: Theme.radius

    onVisibleChanged: if (visible) {
        search.text = "";
        search.forceActiveFocus();
    }

    // Click outside the panel closes it
    MouseArea {
        anchors.fill: parent
        onClicked: root.closed()
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(parent.width - 60, 560)
        height: Math.min(parent.height - 60, 560)
        radius: Theme.radius
        color: Theme.sidebar
        border.width: 1
        border.color: Theme.border

        // Swallow clicks so they don't close the popup
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 18
            height: 40

            StyledText {
                id: titleText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Pin apps"
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            Rectangle {
                anchors.left: titleText.right
                anchors.leftMargin: 16
                anchors.right: closeButton.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                height: 36
                radius: 18
                color: search.activeFocus ? Theme.surfaceHigh : Theme.surfaceHover

                TextInput {
                    id: search
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 13
                    clip: true
                    onTextChanged: root.query = text
                    Keys.onEscapePressed: root.closed()

                    StyledText {
                        visible: search.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search apps"
                        color: Theme.textMuted
                    }
                }
            }

            IconButton {
                id: closeButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.close
                iconColor: Theme.textDim
                baseColor: "transparent"
                onClicked: root.closed()
            }
        }

        ListView {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 12
            anchors.topMargin: 8
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: root.filtered

            delegate: Rectangle {
                id: row

                required property var modelData
                readonly property bool pinned: Launcher.isPinned(modelData)

                width: ListView.view.width
                height: 50
                radius: Theme.radiusSmall
                color: rowMouse.containsMouse ? Theme.surfaceHover : "transparent"

                AppIcon {
                    id: icon
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32
                    entry: row.modelData
                }

                StyledText {
                    anchors.left: icon.right
                    anchors.leftMargin: 12
                    anchors.right: pinMark.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.name
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: pinMark
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    radius: 14
                    color: row.pinned ? Theme.accent : "transparent"
                    border.width: row.pinned ? 0 : 1
                    border.color: Theme.surfaceHigh

                    Icon {
                        anchors.centerIn: parent
                        path: row.pinned ? Icons.pin : Icons.add
                        size: 15
                        color: row.pinned ? Theme.accentText : Theme.textDim
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Launcher.togglePin(row.modelData)
                }
            }
        }
    }
}
