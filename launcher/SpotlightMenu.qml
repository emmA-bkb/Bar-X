import QtQuick
import qs.bar
import qs.components
import qs.config
import qs.services

// "Spotlight" menu: a big search bar in the middle of the screen. Results show up below as you
// type; with nothing typed it shows the pinned apps. Keys: arrows move, Enter opens, Esc closes.
Item {
    id: root

    property string place: "center"
    property int barSpace: 0
    property bool shown: false
    property string query: ""
    property int sel: 0
    readonly property bool searching: query.trim() !== ""
    readonly property string calcResult: Launcher.calc(query)
    readonly property var rows: (calcResult !== "" ? [{
        "entry": null
    }] : []).concat((searching ? Launcher.search(query) : []).slice(0, 8).map((e) => {
        return ({
            "entry": e
        });
    }))
    readonly property int count: searching ? rows.length : Launcher.pinned.length

    function opened() {
        field.clear();
        sel = 0;
        field.focusInput();
    }

    function activate(i) {
        if (searching) {
            const row = rows[i];
            if (row)
                row.entry ? Launcher.launch(row.entry) : Launcher.copy(calcResult);

        } else if (Launcher.pinned[i]) {
            Launcher.launch(Launcher.pinned[i]);
        }
    }

    function move(delta) {
        if (count > 0)
            sel = Math.max(0, Math.min(count - 1, sel + delta));

    }

    Item {
        id: box

        property real drop: root.shown ? 0 : -24

        width: Math.min(parent.width - 40, 660)
        height: column.height
        x: (parent.width - width) / 2
        y: parent.height * 0.2 + drop
        opacity: root.shown ? 1 : 0

        // Swallow clicks so they don't close the menu
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: column

            width: parent.width
            spacing: 10

            SearchField {
                id: field

                width: parent.width
                height: 62
                fontSize: 19
                color: Qt.rgba(0.075, 0.086, 0.094, 0.95)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.45)
                onEdited: (value) => {
                    root.query = value;
                    root.sel = 0;
                }
                onKey: (event) => {
                    const k = event.key;
                    if (k === Qt.Key_Escape)
                        field.text !== "" ? field.clear() : Launcher.close();
                    else if (k === Qt.Key_Down || k === Qt.Key_Tab || (!root.searching && k === Qt.Key_Right))
                        root.move(1);
                    else if (k === Qt.Key_Up || k === Qt.Key_Backtab || (!root.searching && k === Qt.Key_Left))
                        root.move(-1);
                    else if (k === Qt.Key_Return || k === Qt.Key_Enter)
                        root.activate(root.sel);
                    else
                        return ;
                    event.accepted = true;
                }
            }

            // Results / pinned apps
            Rectangle {
                width: parent.width
                height: root.searching ? Math.max(resultList.contentHeight, 54) + 16 : pinnedRow.height + 16
                visible: root.searching || Launcher.pinned.length > 0
                radius: Theme.radius
                color: Qt.rgba(0.075, 0.086, 0.094, 0.94)
                border.width: 1
                border.color: Theme.border
                clip: true

                ListView {
                    id: resultList

                    visible: root.searching
                    anchors.fill: parent
                    anchors.margins: 8
                    interactive: false
                    spacing: 2
                    model: root.rows

                    delegate: AppRow {
                        required property var modelData
                        required property int index

                        width: resultList.width
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

                Grid {
                    id: pinnedRow

                    visible: !root.searching
                    columns: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 8

                    Repeater {
                        model: Launcher.pinned

                        delegate: AppTile {
                            required property var modelData
                            required property int index

                            width: 100
                            height: 100
                            entry: modelData
                            selected: root.sel === index
                            onHovered: root.sel = index
                        }

                    }

                }

                Behavior on height {
                    NumberAnimation {
                        duration: Theme.animFast
                        easing.type: Easing.OutCubic
                    }

                }

            }

        }

        Behavior on drop {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutBack
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animNormal
            }

        }

    }

}
