import QtQuick
import QtQuick.Controls
import qs.config

// Box showing the chosen option; clicking it opens a scrollable list with every option.
// options: [{ value, label }]. Emits chosen(value).
Rectangle {
    id: root

    property var options: []
    property var current
    property string placeholder: ""
    readonly property int currentIndex: options.findIndex(o => o.value === current)

    signal chosen(var value)

    function open() {
        popup.open();
    }

    implicitWidth: 220
    implicitHeight: 42
    radius: Theme.radiusSmall
    color: mouse.containsMouse || popup.visible ? Theme.surfaceHigh : Theme.surface
    border.width: 1
    border.color: popup.visible ? Theme.alpha(Theme.accent, 0.6) : Theme.border

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }

    StyledText {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.right: chevron.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.currentIndex >= 0 ? root.options[root.currentIndex].label : root.placeholder
        color: root.currentIndex >= 0 ? Theme.text : Theme.textMuted
        elide: Text.ElideRight
    }

    Icon {
        id: chevron
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        path: Icons.chevronDown
        size: 20
        color: Theme.textDim
        rotation: popup.visible ? 180 : 0

        Behavior on rotation {
            NumberAnimation {
                duration: Theme.animFast
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: root.options.length > 0
        onClicked: popup.visible ? popup.close() : popup.open()
    }

    Popup {
        id: popup
        y: root.height + 6
        width: root.width
        height: Math.min(list.contentHeight + 12, 300)
        padding: 6
        margins: 10

        onOpened: list.positionViewAtIndex(Math.max(0, root.currentIndex), ListView.Center)

        background: Rectangle {
            radius: Theme.radiusSmall
            color: Theme.sidebar
            border.width: 1
            border.color: Theme.border
        }

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Theme.animFast
            }
        }
        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Theme.animFast
            }
        }

        contentItem: ListView {
            id: list
            clip: true
            spacing: 2
            model: root.options
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: list.contentHeight > list.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: Theme.surfaceHigh
                }
            }

            delegate: Rectangle {
                id: row

                required property var modelData
                required property int index
                readonly property bool isCurrent: index === root.currentIndex

                width: list.width - 8
                height: 36
                radius: 8
                color: isCurrent ? Theme.alpha(Theme.accent, 0.18) : rowMouse.containsMouse ? Theme.surfaceHover : "transparent"

                StyledText {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.label
                    color: row.isCurrent ? Theme.text : Theme.textDim
                    font.weight: row.isCurrent ? Font.DemiBold : Font.Normal
                }

                Icon {
                    visible: row.isCurrent
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    path: Icons.check
                    size: 16
                    color: Theme.accent
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        popup.close();
                        root.chosen(row.modelData.value);
                    }
                }
            }
        }
    }
}
