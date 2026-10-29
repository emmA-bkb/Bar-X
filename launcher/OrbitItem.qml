import QtQuick
import qs.config
import qs.components
import qs.services

// App bubble of the "orbit" menu. progress goes 0 -> 1 when the menu opens (one bubble after the
// other, see delay) and moves it from the origin out to its spot on the arc.
// Without an entry it's the "all apps" button.
Item {
    id: root

    property var entry: null
    property bool selected: false
    property bool shown: false
    property point origin
    property real angle: 0 // degrees, 0 = right, 90 = down
    property real radius: 160
    property int delay: 0
    property real progress: 0

    signal hovered

    readonly property real rad: angle * Math.PI / 180

    width: 62
    height: 62
    x: origin.x + Math.cos(rad) * radius * progress - width / 2
    y: origin.y + Math.sin(rad) * radius * progress - height / 2
    opacity: Math.min(1, progress * 1.4)
    scale: (0.4 + 0.6 * Math.min(1, progress)) * (selected ? 1.15 : 1)
    rotation: (1 - progress) * -120

    onShownChanged: shown ? openAnim.restart() : closeAnim.restart()
    Component.onCompleted: if (shown) openAnim.restart()

    SequentialAnimation {
        id: openAnim
        PauseAnimation {
            duration: root.delay
        }
        NumberAnimation {
            target: root
            property: "progress"
            to: 1
            duration: 460
            easing.type: Easing.OutBack
            easing.overshoot: 1.6
        }
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation {
            target: root
            property: "progress"
            to: 0
            duration: 220
            easing.type: Easing.InCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.selected ? Qt.tint("#e6181c1f", Theme.alpha(Theme.accent, 0.25)) : "#e6181c1f"
        border.width: 1
        border.color: root.selected ? Theme.alpha(Theme.accent, 0.7) : "#40ffffff"

        Behavior on color {
            ColorAnimation {
                duration: Theme.animFast
            }
        }
    }

    AppIcon {
        visible: root.entry !== null
        anchors.centerIn: parent
        width: 36
        height: 36
        entry: root.entry
    }

    Icon {
        visible: root.entry === null
        anchors.centerIn: parent
        path: Icons.apps
        size: 26
        color: Theme.text
    }

    // Name under the bubble while selected
    Rectangle {
        visible: root.selected && root.progress > 0.9
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 6
        width: label.implicitWidth + 20
        height: 26
        radius: 13
        color: "#d9000000"
        rotation: -root.rotation

        StyledText {
            id: label
            anchors.centerIn: parent
            text: root.entry ? root.entry.name : "All apps"
            color: "#ffffff"
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered()
        onClicked: event => {
            if (!root.entry)
                Launcher.showAllApps();
            else if (event.button === Qt.RightButton)
                Launcher.togglePin(root.entry);
            else
                Launcher.launch(root.entry);
        }
    }
}
