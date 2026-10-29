import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services
import qs.bar

// "Panel" menu: greeting, search, pinned apps, every app and power buttons, next to the
// bar's menu button. Keys: type to search, arrows move, Enter opens, Esc clears / closes.
Item {
    id: root

    property string place: "top"
    property int barSpace: 0
    property bool shown: false

    property string query: ""
    property int sel: 0
    readonly property bool searching: query.trim() !== ""
    readonly property string calcResult: Launcher.calc(query)
    readonly property var results: searching ? Launcher.search(query) : []
    readonly property var rows: (calcResult !== "" ? [
            {
                "entry": null
            }
        ] : []).concat(results.map(e => ({
                "entry": e
            })))
    readonly property var allApps: Config.options.launcherAllApps ? Launcher.apps : []
    readonly property int pinnedCount: searching ? 0 : Launcher.pinned.length
    readonly property int count: searching ? rows.length : pinnedCount + allApps.length
    readonly property int columns: 6

    function opened() {
        searchBox.clear();
        sel = 0;
        grid.positionViewAtBeginning();
        searchBox.focusInput();
    }

    function activate(i) {
        if (searching) {
            const row = rows[i];
            if (row)
                row.entry ? Launcher.launch(row.entry) : Launcher.copy(calcResult);
            return;
        }
        const e = i < pinnedCount ? Launcher.pinned[i] : allApps[i - pinnedCount];
        if (e)
            Launcher.launch(e);
    }

    function move(delta) {
        if (count === 0)
            return;
        sel = Math.max(0, Math.min(count - 1, sel + delta));
        if (searching)
            list.positionViewAtIndex(sel, ListView.Contain);
        else if (sel < pinnedCount)
            grid.positionViewAtBeginning();
        else
            grid.positionViewAtIndex(sel - pinnedCount, GridView.Contain);
    }

    Rectangle {
        id: panel

        readonly property int margin: 12
        property real shift: root.shown ? 0 : 18

        width: Math.min(parent.width - 2 * margin, 720)
        height: Math.min(parent.height - 2 * margin - (root.place === "top" || root.place === "bottom" ? root.barSpace : 0), Config.options.launcherAllApps ? 640 : 420)
        x: root.place === "side" ? root.barSpace : root.place === "top" ? Math.max(margin, BarStyle.sideMargin) : (parent.width - width) / 2
        y: root.place === "top" ? root.barSpace : root.place === "bottom" ? parent.height - height - root.barSpace : root.place === "side" ? margin : (parent.height - height) / 2

        radius: Theme.radius
        // Mostly solid even with the glass effect: the menu has a lot of text to read
        color: Qt.rgba(0.075, 0.086, 0.094, BarStyle.glass > 0 ? 0.9 : 0.97)
        border.width: 1
        border.color: BarStyle.glass > 0 ? "#33ffffff" : Theme.border

        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.97
        transformOrigin: root.place === "top" ? Item.TopLeft : root.place === "bottom" ? Item.Bottom : root.place === "side" ? Item.Left : Item.Center
        transform: Translate {
            x: root.place === "side" ? -panel.shift : 0
            y: root.place === "top" ? -panel.shift : root.place === "bottom" ? panel.shift : 0
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }
        Behavior on shift {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }

        // Swallow clicks so they don't close the menu
        MouseArea {
            anchors.fill: parent
        }

        // ---------- Greeting ----------
        Item {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 18
            height: 44

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            ClippingRectangle {
                id: avatar
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                height: 42
                radius: 21
                color: Theme.alpha(Theme.accent, 0.25)

                StyledText {
                    anchors.centerIn: parent
                    visible: face.status !== Image.Ready
                    text: System.user.charAt(0).toUpperCase()
                    color: Theme.accent
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }

                Image {
                    id: face
                    anchors.fill: parent
                    source: "file://" + System.face
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 96
                    asynchronous: true
                }
            }

            Column {
                anchors.left: avatar.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                StyledText {
                    readonly property int hour: clock.date.getHours()
                    text: (hour < 5 ? "Good night" : hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening") + ", " + System.user
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
                StyledText {
                    text: Qt.locale("en_US").toString(clock.date, "dddd, MMMM d")
                    color: Theme.textMuted
                    font.pixelSize: 12
                }
            }

            StyledText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Theme.textDim
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }
        }

        // ---------- Search ----------
        SearchField {
            id: searchBox
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.margins: 18
            anchors.topMargin: 14

            onEdited: value => {
                root.query = value;
                root.sel = 0;
                list.positionViewAtBeginning();
            }
            onKey: event => {
                const k = event.key;
                if (k === Qt.Key_Escape)
                    searchBox.text !== "" ? searchBox.clear() : Launcher.close();
                else if (k === Qt.Key_Down)
                    root.move(root.searching ? 1 : root.columns);
                else if (k === Qt.Key_Up)
                    root.move(root.searching ? -1 : -root.columns);
                else if (k === Qt.Key_Tab)
                    root.move(1);
                else if (k === Qt.Key_Backtab)
                    root.move(-1);
                else if (!root.searching && k === Qt.Key_Left)
                    root.move(-1);
                else if (!root.searching && k === Qt.Key_Right)
                    root.move(1);
                else if (k === Qt.Key_Return || k === Qt.Key_Enter)
                    root.activate(root.sel);
                else
                    return;
                event.accepted = true;
            }
        }

        // ---------- Apps ----------
        Item {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: searchBox.bottom
            anchors.bottom: footer.visible ? footer.top : parent.bottom
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 10
            anchors.bottomMargin: 8

            // Pinned apps (in the header) + every app
            GridView {
                id: grid
                anchors.fill: parent
                visible: !root.searching
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                cellWidth: width / root.columns
                cellHeight: 104
                model: root.allApps

                header: Column {
                    width: grid.width

                    StyledText {
                        leftPadding: 8
                        topPadding: 4
                        bottomPadding: 2
                        text: "Pinned"
                        color: Theme.textDim
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    StyledText {
                        visible: Launcher.pinned.length === 0
                        leftPadding: 8
                        topPadding: 6
                        bottomPadding: 10
                        text: "Right-click an app to pin it here"
                        color: Theme.textMuted
                        font.pixelSize: 12
                    }

                    Grid {
                        columns: root.columns

                        Repeater {
                            model: Launcher.pinned
                            delegate: AppTile {
                                required property var modelData
                                required property int index
                                width: grid.cellWidth
                                height: grid.cellHeight
                                entry: modelData
                                selected: root.sel === index
                                onHovered: root.sel = index
                            }
                        }
                    }

                    StyledText {
                        visible: Config.options.launcherAllApps
                        leftPadding: 8
                        topPadding: 8
                        bottomPadding: 2
                        text: "All apps  ·  " + Launcher.apps.length
                        color: Theme.textDim
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                }

                delegate: AppTile {
                    required property var modelData
                    required property int index
                    width: grid.cellWidth
                    height: grid.cellHeight
                    entry: modelData
                    selected: root.sel === index + root.pinnedCount
                    onHovered: root.sel = index + root.pinnedCount
                }
            }

            // Search results
            ListView {
                id: list
                anchors.fill: parent
                visible: root.searching
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                model: root.rows

                delegate: AppRow {
                    required property var modelData
                    required property int index
                    width: list.width
                    entry: modelData.entry
                    result: root.calcResult
                    selected: root.sel === index
                    onHovered: root.sel = index
                }
            }

            StyledText {
                visible: root.searching && root.count === 0
                anchors.centerIn: parent
                text: "No apps found for \"" + root.query.trim() + "\""
                color: Theme.textMuted
            }
        }

        // ---------- Power ----------
        Item {
            id: footer
            visible: Config.options.launcherPower
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16
            height: 40

            StyledText {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.right: powerRow.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Right-click: pin  ·  ↑↓←→ Enter"
                color: Theme.textMuted
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            PowerRow {
                id: powerRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
