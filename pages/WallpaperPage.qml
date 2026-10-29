import QtQuick
import qs.config
import qs.components
import qs.services

// Wallpaper gallery: Wallpaper Engine (Steam Workshop) and local folder.
Item {
    id: root

    property string tab: Wallpapers.engineItems.length > 0 ? "we" : "local"
    property string query: ""
    property bool scanMenuOpen: false
    property bool settingsOpen: false
    // Wallpaper selected in the gallery (starts on the one on screen). Selecting does not apply it.
    property string selectedPath: Config.options.wallpaper

    readonly property bool community: tab === "community"
    readonly property var source: tab === "we" ? Wallpapers.engineItems : tab === "local" ? Wallpapers.items : Workshop.items
    // On the Community tab the search runs on the Workshop itself
    readonly property var filtered: {
        const q = query.trim().toLowerCase();
        return q === "" || community ? source : source.filter(i => i.name.toLowerCase().includes(q));
    }
    readonly property var selectedItem: community ? (Workshop.items.find(i => i.id === communityId) ?? null) : selectedPath ? Wallpapers.find(selectedPath) : null

    // Community: chosen item and whether it's already installed (downloaded by Steam)
    property string communityId: ""
    readonly property var installedIds: Wallpapers.engineItems.map(i => i.path.split("/").pop())

    function installedPath(id) {
        const item = Wallpapers.engineItems.find(i => i.path.endsWith("/" + id));
        return item ? item.path : "";
    }

    // The Community search is kept in the service (which stays alive across pages),
    // but the search box comes back empty. When the tab opens, Community follows what's in the box.
    onTabChanged: {
        // Check `tab` directly: the `community` binding may not be updated yet inside this handler
        if (tab !== "community")
            return;
        const q = query.trim();
        if (!Workshop.loaded && !Workshop.loading) {
            Workshop.query = q;
            Workshop.reload();
        } else {
            Workshop.search(q);
        }
    }

    Timer {
        id: searchDelay
        interval: 600
        onTriggered: Workshop.search(root.query.trim())
    }

    readonly property var compatInfo: ({
            "perfect": {
                "color": "#8be28b",
                "label": "Works perfectly"
            },
            "minor": {
                "color": "#f6d58b",
                "label": "Minor issues"
            },
            "broken": {
                "color": "#ff7b7b",
                "label": "Doesn't work on Linux"
            }
        })

    function typeIcon(item) {
        if (item.type === "video")
            return Icons.video;
        if (item.type === "web")
            return Icons.code;
        if (item.source === "we" || item.source === "workshop")
            return Icons.sparkle;
        return "";
    }

    function typeLabel(item) {
        return ({
                "scene": "Scene",
                "video": "Video",
                "web": "Web",
                "application": "App",
                "image": "Image"
            })[item.type] ?? item.type;
    }

    // ---------- Tabs + search ----------
    Item {
        id: top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40

        Rectangle {
            id: tabs
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: tabRow.width + 8
            height: 40
            radius: 20
            color: Theme.surface

            Row {
                id: tabRow
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: [
                        {
                            "id": "we",
                            "label": "Wallpaper Engine",
                            "count": Wallpapers.engineItems.length
                        },
                        {
                            "id": "local",
                            "label": "Local folder",
                            "count": Wallpapers.items.length
                        },
                        {
                            "id": "community",
                            "label": "Community",
                            "count": -1
                        }
                    ]

                    delegate: Rectangle {
                        id: tabButton

                        required property var modelData
                        readonly property bool active: root.tab === modelData.id

                        width: tabLabel.implicitWidth + (countBadge.visible ? countBadge.width + 8 : 0) + 30
                        height: 32
                        radius: 16
                        color: active ? Theme.alpha(Theme.accent, 0.18) : tabMouse.containsMouse ? Theme.surfaceHover : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animFast
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            StyledText {
                                id: tabLabel
                                anchors.verticalCenter: parent.verticalCenter
                                text: tabButton.modelData.label
                                color: tabButton.active ? Theme.text : Theme.textDim
                                font.weight: tabButton.active ? Font.DemiBold : Font.Normal
                            }

                            Rectangle {
                                id: countBadge
                                visible: tabButton.modelData.count >= 0
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.max(22, countText.implicitWidth + 12)
                                height: 20
                                radius: 10
                                color: tabButton.active ? Theme.accent : Theme.surfaceHigh

                                StyledText {
                                    id: countText
                                    anchors.centerIn: parent
                                    text: tabButton.modelData.count
                                    color: tabButton.active ? Theme.accentText : Theme.textDim
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tab = tabButton.modelData.id
                        }
                    }
                }
            }
        }

        // Search
        Rectangle {
            anchors.left: tabs.right
            anchors.leftMargin: 12
            anchors.right: scanButton.visible ? scanButton.left : refresh.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            height: 40
            radius: 20
            color: search.activeFocus ? Theme.surfaceHigh : Theme.surface
            border.width: 1
            border.color: search.activeFocus ? Theme.alpha(Theme.accent, 0.6) : "transparent"

            Icon {
                id: searchIcon
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                path: Icons.search
                size: 17
                color: Theme.textMuted
            }

            TextInput {
                id: search
                anchors.left: searchIcon.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                selectionColor: Theme.alpha(Theme.accent, 0.4)
                font.family: Theme.font
                font.pixelSize: 13
                clip: true
                selectByMouse: true
                onTextChanged: {
                    root.query = text;
                    if (root.community)
                        searchDelay.restart();
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text === ""
                    text: root.community ? "Search the Wallpaper Engine Workshop" : "Search wallpapers"
                    color: Theme.textMuted
                }
            }
        }

        // Test whether the wallpapers work on Linux
        StyledButton {
            id: scanButton
            visible: root.tab === "we"
            anchors.right: refresh.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.check
            text: CompatScan.running ? "Testing…" : "Test"
            onClicked: root.scanMenuOpen = !root.scanMenuOpen
        }

        IconButton {
            id: refresh
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.refresh
            onClicked: {
                if (root.community)
                    Workshop.reload();
                Wallpapers.rescan();
            }

            RotationAnimation on rotation {
                running: Wallpapers.loading || Wallpapers.engineLoading || Workshop.loading
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 900
            }
        }
    }

    // ---------- Folder (local tab only) ----------
    Rectangle {
        id: pathBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: top.bottom
        anchors.topMargin: root.tab === "local" ? 12 : 0
        height: root.tab === "local" ? 52 : 0
        visible: root.tab === "local"
        radius: Theme.radiusMedium
        color: Theme.surface

        Row {
            id: pathLabel
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                path: Icons.folder
                size: 18
                color: Theme.textDim
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Folder"
                color: Theme.textDim
            }
        }

        Rectangle {
            anchors.left: pathLabel.right
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            height: 34
            radius: Theme.radiusSmall
            color: input.activeFocus ? Theme.surfaceHigh : Theme.surfaceHover
            border.width: 1
            border.color: input.activeFocus ? Theme.alpha(Theme.accent, 0.6) : "transparent"

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                text: Config.options.wallpaperDir
                color: Theme.text
                selectionColor: Theme.alpha(Theme.accent, 0.4)
                font.family: Theme.font
                font.pixelSize: 13
                clip: true
                selectByMouse: true
                onEditingFinished: {
                    if (text !== Config.options.wallpaperDir)
                        Config.options.wallpaperDir = text;
                }
            }
        }
    }

    // ---------- Filters (Community only) ----------
    Item {
        id: communityBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: pathBar.bottom
        anchors.topMargin: root.community ? 12 : 0
        height: root.community ? 34 : 0
        visible: root.community

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Repeater {
                model: Workshop.sorts
                delegate: FilterChip {
                    required property var modelData
                    label: modelData.label
                    active: Workshop.sort === modelData.id
                    onClicked: Workshop.setSort(modelData.id)
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Repeater {
                model: Workshop.types
                delegate: FilterChip {
                    required property var modelData
                    label: modelData.label
                    active: Workshop.type === modelData.id
                    onClicked: Workshop.setType(modelData.id)
                }
            }
        }
    }

    // ---------- Gallery ----------
    GridView {
        id: grid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: communityBar.bottom
        anchors.topMargin: 14
        anchors.bottom: footer.top
        anchors.bottomMargin: 10
        anchors.leftMargin: -5
        anchors.rightMargin: -5
        clip: true

        cellWidth: width / 4
        cellHeight: (cellWidth - 10) * 9 / 16 + 10
        model: root.filtered
        boundsBehavior: Flickable.StopAtBounds

        // Community: loads the next page on reaching the end
        onAtYEndChanged: {
            if (atYEnd && root.community && contentHeight > height)
                Workshop.loadMore();
        }

        // A new page replaces the whole list, and a GridView jumps back to the top when its
        // model is replaced. Save the scroll position before the page arrives and restore it after.
        property real keepY: 0
        property bool restorePending: false

        function restoreScroll() {
            contentY = Math.min(keepY, Math.max(0, contentHeight - height));
            restorePending = false;
        }

        onCountChanged: {
            if (restorePending)
                Qt.callLater(restoreScroll);
        }

        Connections {
            target: Workshop
            function onBeforeAppend() {
                if (root.tab !== "community")
                    return;
                grid.keepY = grid.contentY;
                grid.restorePending = true;
            }
        }

        delegate: Item {
            id: cell

            required property var modelData
            readonly property bool isWorkshop: modelData.source === "workshop"
            readonly property bool installed: isWorkshop && root.installedIds.includes(modelData.id)
            readonly property bool selected: isWorkshop ? root.communityId === modelData.id : root.selectedPath === modelData.path
            // Workshop previews may be GIFs without an extension in the link: try to animate all of them on hover
            readonly property bool isGif: isWorkshop || modelData.thumb.toLowerCase().endsWith(".gif")
            readonly property var compat: root.compatInfo[modelData.compat] ?? null

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
                        duration: Theme.animNormal
                        easing.type: Easing.OutCubic
                    }
                }

                // .gif previews animate on hover
                Loader {
                    anchors.fill: parent
                    active: cell.isGif && mouse.containsMouse
                    sourceComponent: AnimatedImage {
                        source: cell.isWorkshop ? cell.modelData.thumb : "file://" + cell.modelData.thumb
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        playing: true
                    }
                }

                // Type badge
                Rectangle {
                    visible: root.typeIcon(cell.modelData) !== ""
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 7
                    width: typeRow.implicitWidth + 14
                    height: 22
                    radius: 11
                    color: "#b0101214"

                    Row {
                        id: typeRow
                        anchors.centerIn: parent
                        spacing: 4

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            path: root.typeIcon(cell.modelData)
                            size: 12
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.typeLabel(cell.modelData)
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }
                }

                // Title + compatibility
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 34
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: "#00101214"
                        }
                        GradientStop {
                            position: 0.6
                            color: "#d0101214"
                        }
                    }

                    StyledText {
                        id: subsText
                        visible: cell.isWorkshop
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        text: cell.isWorkshop ? "↓ " + Workshop.formatCount(cell.modelData.subscriptions) : ""
                        color: Theme.textDim
                        font.pixelSize: 11
                    }

                    Rectangle {
                        id: compatDot
                        visible: cell.compat !== null
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 11
                        width: 7
                        height: 7
                        radius: 4
                        color: cell.compat ? cell.compat.color : "transparent"
                    }

                    StyledText {
                        anchors.left: parent.left
                        anchors.right: cell.isWorkshop ? subsText.left : compatDot.left
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        text: cell.modelData.name
                        font.pixelSize: 12
                    }
                }
            }

            // "Installed" badge (Community)
            Rectangle {
                visible: cell.installed
                anchors.right: thumb.right
                anchors.top: thumb.top
                anchors.margins: 7
                anchors.rightMargin: cell.selected ? 36 : 7
                width: installedRow.implicitWidth + 14
                height: 22
                radius: 11
                color: "#d02f6b3a"

                Row {
                    id: installedRow
                    anchors.centerIn: parent
                    spacing: 4
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        path: Icons.check
                        size: 12
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Installed"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }
            }

            // Border and badge of the selected one
            Rectangle {
                anchors.fill: thumb
                anchors.margins: -3
                scale: thumb.scale
                radius: Theme.radiusSmall + 3
                color: "transparent"
                border.width: 2
                border.color: cell.selected ? Theme.accent : "transparent"
            }

            Rectangle {
                anchors.right: thumb.right
                anchors.top: thumb.top
                anchors.margins: 7
                width: 24
                height: 24
                radius: 12
                color: Theme.accent
                scale: cell.selected ? 1 : 0

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.animNormal
                        easing.type: Easing.OutBack
                    }
                }

                Icon {
                    anchors.centerIn: parent
                    path: Icons.check
                    size: 15
                    color: Theme.accentText
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (cell.isWorkshop)
                        root.communityId = cell.modelData.id;
                    else
                        root.selectedPath = cell.modelData.path;
                }
                onDoubleClicked: {
                    if (cell.isWorkshop) {
                        root.communityId = cell.modelData.id;
                        root.applyCommunity(cell.modelData);
                        return;
                    }
                    root.selectedPath = cell.modelData.path;
                    if (Wallpapers.apply(cell.modelData.path))
                        Ui.notify("Applying \"" + cell.modelData.name + "\"");
                }
            }
        }
    }

    // Empty state
    Column {
        anchors.centerIn: grid
        spacing: 10
        visible: root.filtered.length === 0 && !(root.tab === "we" ? Wallpapers.engineLoading : root.community ? Workshop.loading : Wallpapers.loading)

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            path: Icons.wallpaper
            size: 42
            color: Theme.textMuted
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.community && Workshop.error !== "" ? "Couldn't open the Workshop. Check your connection and click refresh" : root.query !== "" ? "Nothing found for \"" + root.query + "\"" : root.tab === "we" ? "No Wallpaper Engine wallpapers found in Steam" : "No images or videos in this folder"
            color: Theme.textMuted
        }
    }

    // ---------- Compatibility test ----------
    // Progress
    Rectangle {
        visible: CompatScan.running
        anchors.left: grid.left
        anchors.right: grid.right
        anchors.bottom: grid.bottom
        anchors.margins: 10
        height: 58
        radius: Theme.radiusMedium
        color: Theme.surfaceHigh
        border.width: 1
        border.color: Theme.border
        z: 5

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.right: stopButton.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7

            StyledText {
                width: parent.width
                text: CompatScan.total > 0 ? "Testing " + Math.min(CompatScan.done + 1, CompatScan.total) + " of " + CompatScan.total + (CompatScan.current ? "  ·  " + CompatScan.current : "") : "Preparing the test…"
                font.weight: Font.DemiBold
            }

            Rectangle {
                width: parent.width
                height: 5
                radius: 3
                color: Theme.surface

                Rectangle {
                    width: CompatScan.total > 0 ? parent.width * CompatScan.done / CompatScan.total : 0
                    height: parent.height
                    radius: 3
                    color: Theme.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.animNormal
                        }
                    }
                }
            }
        }

        StyledButton {
            id: stopButton
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.close
            text: "Stop"
            onClicked: CompatScan.cancel()
        }
    }

    // "Test" button menu
    MouseArea {
        anchors.fill: parent
        visible: root.scanMenuOpen
        z: 9
        onClicked: root.scanMenuOpen = false
    }

    Rectangle {
        visible: root.scanMenuOpen
        anchors.right: top.right
        anchors.rightMargin: 48
        anchors.top: top.bottom
        anchors.topMargin: 8
        width: 360
        height: scanColumn.height + 16
        radius: Theme.radiusMedium
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        z: 10

        Column {
            id: scanColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8

            Repeater {
                model: [
                    {
                        "mode": "new",
                        "title": "Test the untested ones (" + CompatScan.untested + ")",
                        "description": "Only the ones without a compatibility dot yet"
                    },
                    {
                        "mode": "all",
                        "title": "Test all of them again (" + Wallpapers.engineItems.length + ")",
                        "description": "Runs the test again on every wallpaper"
                    }
                ]

                delegate: Rectangle {
                    id: scanOption

                    required property var modelData

                    width: scanColumn.width
                    height: 54
                    radius: Theme.radiusSmall
                    color: scanMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    opacity: CompatScan.running ? 0.4 : 1

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        StyledText {
                            text: scanOption.modelData.title
                            font.weight: Font.DemiBold
                        }
                        StyledText {
                            width: parent.width
                            text: scanOption.modelData.description
                            color: Theme.textMuted
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !CompatScan.running
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.scanMenuOpen = false;
                            CompatScan.start(scanOption.modelData.mode);
                        }
                    }
                }
            }

            StyledText {
                width: parent.width
                leftPadding: 12
                rightPadding: 12
                topPadding: 6
                bottomPadding: 4
                text: "Each wallpaper runs hidden for 5 seconds (3 at a time). Nothing shows up on your screen."
                color: Theme.textMuted
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }
        }
    }

    // Loading the Community
    Rectangle {
        visible: root.community && Workshop.loading
        anchors.horizontalCenter: grid.horizontalCenter
        anchors.bottom: grid.bottom
        anchors.bottomMargin: 10
        width: loadingText.implicitWidth + 32
        height: 34
        radius: 17
        color: Theme.surfaceHigh

        StyledText {
            id: loadingText
            anchors.centerIn: parent
            text: "Loading the Workshop…"
            color: Theme.textDim
        }
    }

    // Applies a Community item: if it's already installed applies it, otherwise opens it in Steam to subscribe
    function applyCommunity(item) {
        const path = installedPath(item.id);
        if (path) {
            Wallpapers.apply(path);
            Ui.notify("Applying \"" + item.name + "\"");
        } else {
            Workshop.openInSteam(item.id);
            Ui.notify("Click \"Subscribe\" in Steam. Once it downloads, it shows up as installed");
        }
    }

    // ---------- Footer ----------
    Item {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 44

        Column {
            anchors.left: parent.left
            anchors.right: footerActions.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            StyledText {
                width: parent.width
                text: root.selectedItem ? root.selectedItem.name : "No wallpaper selected"
                color: root.selectedItem ? Theme.text : Theme.textMuted
                font.weight: Font.DemiBold
            }
            StyledText {
                width: parent.width
                visible: root.selectedItem !== null
                text: {
                    const item = root.selectedItem;
                    if (!item)
                        return "";
                    if (item.source === "workshop") {
                        const status = root.installedIds.includes(item.id) ? "Installed" : Workshop.watching === item.id ? "Waiting for Steam to download…" : "Not installed";
                        return root.typeLabel(item) + " · " + Workshop.formatCount(item.subscriptions) + " subscribers · " + Workshop.formatSize(item.size) + " · " + status;
                    }
                    const origin = item.source === "we" ? "Wallpaper Engine" : "Local folder";
                    const compat = root.compatInfo[item.compat];
                    return origin + " · " + root.typeLabel(item) + (compat ? " · " + compat.label : "");
                }
                color: Theme.textMuted
                font.pixelSize: 12
            }
        }

        Row {
            id: footerActions
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Community
            StyledButton {
                visible: root.community && root.selectedItem !== null
                text: "View in browser"
                icon: Icons.code
                onClicked: Workshop.openInBrowser(root.selectedItem.id)
            }

            StyledButton {
                visible: root.community && root.selectedItem !== null
                readonly property bool installed: root.selectedItem !== null && root.installedIds.includes(root.selectedItem.id)
                text: installed ? "Apply now" : "Download with Steam"
                icon: installed ? Icons.check : Icons.add
                primary: true
                onClicked: root.applyCommunity(root.selectedItem)
            }

            // Sound, FPS, scaling and the wallpaper's own options (+ pausing for all wallpapers)
            StyledButton {
                visible: !root.community
                text: "Settings"
                icon: Icons.tune
                onClicked: root.settingsOpen = true
            }

            StyledButton {
                visible: !root.community
                text: "Use in active preset"
                icon: Icons.presets
                opacity: enabled ? 1 : 0.4
                enabled: root.selectedPath !== "" && Config.preset(Config.options.activePreset) !== null
                onClicked: {
                    // Saves to the active preset and puts it on screen, so both stay in sync
                    Config.updatePreset(Config.options.activePreset, {
                        "wallpaper": root.selectedPath
                    });
                    Wallpapers.apply(root.selectedPath);
                    Ui.notify("Wallpaper saved to the preset \"" + Config.preset(Config.options.activePreset).name + "\"");
                }
            }

            StyledButton {
                visible: !root.community
                text: "Apply now"
                icon: Icons.check
                primary: true
                opacity: enabled ? 1 : 0.4
                enabled: root.selectedItem !== null
                onClicked: {
                    if (Wallpapers.apply(root.selectedItem.path))
                        Ui.notify("Applying \"" + root.selectedItem.name + "\"");
                }
            }
        }
    }

    // ---------- Wallpaper settings ----------
    WallpaperSettingsPopup {
        anchors.fill: parent
        visible: root.settingsOpen
        z: 20
        item: root.selectedItem && root.selectedItem.source !== "workshop" ? root.selectedItem : null
        onClosed: root.settingsOpen = false
    }
}
