import QtQuick
import qs.config
import qs.components
import qs.services

// Popup to choose a wallpaper (Wallpaper Engine + local folder). Emits chosen(path).
Rectangle {
    id: root

    property string title: ""
    property string query: ""

    readonly property var all: Wallpapers.engineItems.concat(Wallpapers.items)
    readonly property var filtered: {
        const q = query.trim().toLowerCase();
        return q === "" ? all : all.filter(i => i.name.toLowerCase().includes(q));
    }

    signal chosen(string path)
    signal closed

    color: "#b0000000"
    radius: Theme.radius

    // Click outside the panel closes it
    MouseArea {
        anchors.fill: parent
        onClicked: root.closed()
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(parent.width - 60, 860)
        height: Math.min(parent.height - 60, 560)
        radius: Theme.radius
        color: Theme.surface
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
                text: root.title
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
                    selectByMouse: true
                    onTextChanged: root.query = text

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text === ""
                        text: "Search wallpapers"
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

        GridView {
            id: grid
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 14
            anchors.topMargin: 10
            clip: true
            cellWidth: width / 4
            cellHeight: (cellWidth - 10) * 9 / 16 + 10
            model: root.filtered
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: cell

                required property var modelData

                width: grid.cellWidth
                height: grid.cellHeight

                WallpaperPreview {
                    id: thumb
                    anchors.fill: parent
                    anchors.margins: 5
                    source: cell.modelData.thumb
                    scale: mouse.containsMouse ? 1.03 : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animFast
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 26
                        color: "#c0101214"

                        StyledText {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            text: cell.modelData.name
                            font.pixelSize: 11
                        }
                    }

                    // Marked as not working on Linux
                    Rectangle {
                        visible: cell.modelData.compat === "broken"
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 6
                        width: 8
                        height: 8
                        radius: 4
                        color: "#ff7b7b"
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.chosen(cell.modelData.path)
                }
            }
        }
    }
}
