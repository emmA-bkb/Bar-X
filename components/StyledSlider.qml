import QtQuick
import qs.config

// Slider. Emits moved() while dragging and committed() on release,
// so the config isn't saved on every pixel.
Item {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0
    property real stepSize: 0

    property real dragValue: value
    readonly property real shownValue: mouse.pressed ? dragValue : value
    readonly property real ratio: to > from ? (shownValue - from) / (to - from) : 0

    signal moved(real value)
    signal committed(real value)

    implicitWidth: 160
    implicitHeight: 24

    function valueAt(x) {
        let v = from + (to - from) * Math.max(0, Math.min(1, (x - 8) / (width - 16)));
        if (stepSize > 0)
            v = Math.round(v / stepSize) * stepSize;
        return Math.max(from, Math.min(to, v));
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        x: 8
        width: parent.width - 16
        height: 4
        radius: 2
        color: Theme.surfaceHigh

        Rectangle {
            width: parent.width * root.ratio
            height: parent.height
            radius: 2
            color: Theme.accent
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: track.x + track.width * root.ratio - width / 2
        width: mouse.pressed ? 18 : 16
        height: width
        radius: width / 2
        color: Theme.accent
        border.width: 3
        border.color: Theme.surface

        Behavior on width {
            NumberAnimation {
                duration: Theme.animFast
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => {
            root.dragValue = root.valueAt(mouse.x);
            root.moved(root.dragValue);
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            root.dragValue = root.valueAt(mouse.x);
            root.moved(root.dragValue);
        }
        onReleased: root.committed(root.dragValue)
    }
}
