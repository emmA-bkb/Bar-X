import QtQuick
import qs.config
import qs.components
import qs.services
import qs.bar

// "Curtain" menu: a strip of pinned apps that unrolls from the menu button (down from a top bar,
// up from the dock, sideways from the side bar), with the app name next to the hovered icon.
// Keys: arrows move, Enter opens, 1-9 open the first nine apps, Esc closes.
Item {
    id: root

    property string place: "top"
    property int barSpace: 0
    property bool shown: false

    readonly property bool horizontal: place === "side"
    // Pinned apps + the "all apps" button (null)
    readonly property var items: Launcher.pinned.concat([null])
    // Space each icon takes in the strip (52x48 icons, 5 px apart)
    readonly property int step: horizontal ? 57 : 53
    property int sel: -1

    function opened() {
        sel = -1;
        keys.forceActiveFocus();
    }

    function activate(i) {
        const e = items[i];
        if (e)
            Launcher.launch(e);
        else if (i === items.length - 1)
            Launcher.showAllApps();
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            const k = event.key;
            const next = root.horizontal ? Qt.Key_Right : Qt.Key_Down;
            const prev = root.horizontal ? Qt.Key_Left : Qt.Key_Up;
            if (k === Qt.Key_Escape)
                Launcher.close();
            else if (k === next || k === Qt.Key_Tab)
                root.sel = Math.min(root.items.length - 1, root.sel + 1);
            else if (k === prev || k === Qt.Key_Backtab)
                root.sel = Math.max(0, root.sel - 1);
            else if ((k === Qt.Key_Return || k === Qt.Key_Enter) && root.sel >= 0)
                root.activate(root.sel);
            else if (k >= Qt.Key_1 && k <= Qt.Key_9)
                root.activate(k - Qt.Key_1);
            else
                return;
            event.accepted = true;
        }
    }

    // The curtain: grows from the button side and shows more of the strip as it grows
    Item {
        id: reveal

        readonly property real full: root.horizontal ? strip.width : strip.height

        width: root.horizontal ? (root.shown ? strip.width : 0) : strip.width
        height: root.horizontal ? strip.height : (root.shown ? strip.height : 0)
        x: root.place === "side" ? root.barSpace - 4 : root.place === "top" ? Math.max(8, BarStyle.sideMargin) : (parent.width - width) / 2
        y: root.place === "top" ? root.barSpace - 4 : root.place === "bottom" ? parent.height - root.barSpace + 4 - height : root.place === "side" ? 12 : (parent.height - strip.height) / 2
        clip: true

        Behavior on width {
            NumberAnimation {
                duration: 380
                easing.type: Easing.OutCubic
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: 380
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: strip

            width: root.horizontal ? root.items.length * root.step + 9 : 62
            height: root.horizontal ? 62 : root.items.length * root.step + 13
            // From the dock it unrolls upwards, so the strip stays glued to the bottom
            y: root.place === "bottom" ? reveal.height - height : 0
            radius: 17
            color: "#8c000000"
            border.color: "#40ffffff"
            border.width: 1
            opacity: root.shown ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 380
                    easing.type: Easing.OutCubic
                }
            }

            // Swallow clicks so they don't close the menu
            MouseArea {
                anchors.fill: parent
            }

            Grid {
                anchors.centerIn: parent
                columns: root.horizontal ? root.items.length : 1
                spacing: 5

                Repeater {
                    model: root.items
                    delegate: CurtainItem {
                        required property var modelData
                        required property int index
                        entry: modelData
                        shown: root.shown
                        selected: root.sel === index
                        onHovered: root.sel = index
                    }
                }
            }
        }
    }

    // Name of the selected app, next to it
    Rectangle {
        readonly property var entry: root.sel >= 0 ? root.items[root.sel] : undefined
        // Center of the selected icon along the strip
        readonly property real offset: (root.horizontal ? 7 + 26 : 9 + 24) + root.sel * root.step

        visible: root.shown && root.sel >= 0 && reveal.width > 0 && reveal.height > 0
        width: nameText.implicitWidth + 24
        height: 30
        radius: 15
        color: "#d9000000"
        border.color: "#40ffffff"
        border.width: 1
        x: root.horizontal ? reveal.x + offset - width / 2 : reveal.x + reveal.width + 8
        y: root.horizontal ? reveal.y + reveal.height + 8 : (root.place === "bottom" ? reveal.y + reveal.height - strip.height : reveal.y) + offset - height / 2

        StyledText {
            id: nameText
            anchors.centerIn: parent
            text: parent.entry === null ? "All apps" : parent.entry ? parent.entry.name : ""
            color: "#ffffff"
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }
}
