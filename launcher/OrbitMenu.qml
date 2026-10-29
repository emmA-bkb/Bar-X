import QtQuick
import qs.config
import qs.components
import qs.services
import qs.bar

// "Orbit" menu: the pinned apps bloom out of the menu button one after the other and sit on an
// arc around it (down-right from a top or side bar, upwards from the dock, a full circle in the
// middle of the screen without a bar). Keys: arrows move, Enter opens, 1-9 open, Esc closes.
Item {
    id: root

    property string place: "top"
    property int barSpace: 0
    property bool shown: false

    // Pinned apps + the "all apps" button (null)
    readonly property var items: Launcher.pinned.concat([null])
    readonly property int n: items.length
    property int sel: -1

    // Where the arc starts: the menu button (first item of the bar), or the middle of the screen
    readonly property point origin: place === "top" ? Qt.point(Math.max(8, BarStyle.sideMargin) + 22, BarStyle.gap + BarStyle.thickness / 2) : place === "side" ? Qt.point(BarStyle.gap + BarStyle.thickness / 2, BarStyle.gap + 30) : place === "bottom" ? Qt.point(width / 2, height - BarStyle.gap - BarStyle.thickness / 2) : Qt.point(width / 2, height / 2)
    // Arc angles in degrees (0 = right, 90 = down) and radius: big enough to keep ~72 px between bubbles
    readonly property real a0: place === "bottom" ? 195 : place === "center" ? -90 : 8
    readonly property real a1: place === "bottom" ? 345 : place === "center" ? 270 - 360 / n : 82
    readonly property real span: Math.abs(a1 - a0) * Math.PI / 180
    readonly property real orbit: Math.max(place === "center" ? 130 : 150, 72 * Math.max(1, n - 1) / Math.max(0.5, span))

    function opened() {
        sel = -1;
        keys.forceActiveFocus();
    }

    function activate(i) {
        const e = items[i];
        if (e)
            Launcher.launch(e);
        else if (i === n - 1)
            Launcher.showAllApps();
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            const k = event.key;
            if (k === Qt.Key_Escape)
                Launcher.close();
            else if (k === Qt.Key_Right || k === Qt.Key_Down || k === Qt.Key_Tab)
                root.sel = (root.sel + 1) % root.n;
            else if (k === Qt.Key_Left || k === Qt.Key_Up || k === Qt.Key_Backtab)
                root.sel = (root.sel - 1 + root.n) % root.n;
            else if ((k === Qt.Key_Return || k === Qt.Key_Enter) && root.sel >= 0)
                root.activate(root.sel);
            else if (k >= Qt.Key_1 && k <= Qt.Key_9)
                root.activate(k - Qt.Key_1);
            else
                return;
            event.accepted = true;
        }
    }

    // Faint ring the bubbles sit on
    Rectangle {
        x: root.origin.x - width / 2
        y: root.origin.y - height / 2
        width: root.orbit * 2 * ringScale
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.35)
        opacity: root.shown ? 1 : 0

        property real ringScale: root.shown ? 1 : 0.2

        Behavior on ringScale {
            NumberAnimation {
                duration: 420
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }
    }

    // Center button when it opens in the middle of the screen: closes the menu
    Rectangle {
        visible: root.place === "center"
        x: root.origin.x - width / 2
        y: root.origin.y - height / 2
        width: 54
        height: 54
        radius: 27
        color: "#e6181c1f"
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.6)
        scale: root.shown ? 1 : 0

        Behavior on scale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutBack
            }
        }

        Icon {
            anchors.centerIn: parent
            path: Icons.close
            size: 22
            color: Theme.textDim
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Launcher.close()
        }
    }

    Repeater {
        model: root.items
        delegate: OrbitItem {
            required property var modelData
            required property int index
            entry: modelData
            shown: root.shown
            origin: root.origin
            angle: root.a0 + (root.a1 - root.a0) * (root.n > 1 ? index / (root.n - 1) : 0.5)
            radius: root.orbit
            delay: index * 40
            selected: root.sel === index
            onHovered: root.sel = index
        }
    }
}
