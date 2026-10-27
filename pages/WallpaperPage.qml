import QtQuick
import qs.config
import qs.components
import qs.services

// Galeria de wallpapers: Wallpaper Engine (Steam Workshop) e pasta local.
Item {
    id: root

    property string tab: Wallpapers.engineItems.length > 0 ? "we" : "local"
    property string query: ""
    property bool scanMenuOpen: false
    // Wallpaper selected in the gallery (starts on the one on screen). Selecting does not apply it.
    property string selectedPath: Config.options.wallpaper

    readonly property bool community: tab === "community"
    readonly property var source: tab === "we" ? Wallpapers.engineItems : tab === "local" ? Wallpapers.items : Workshop.items
    // Na Comunidade a busca e feita na propria Workshop
    readonly property var filtered: {
        const q = query.trim().toLowerCase();
        return q === "" || community ? source : source.filter(i => i.name.toLowerCase().includes(q));
    }
    readonly property var selectedItem: community ? (Workshop.items.find(i => i.id === communityId) ?? null) : selectedPath ? Wallpapers.find(selectedPath) : null

    // Comunidade: item escolhido e o que ja esta instalado (baixado pela Steam)
    property string communityId: ""
    readonly property var installedIds: Wallpapers.engineItems.map(i => i.path.split("/").pop())

    function installedPath(id) {
        const item = Wallpapers.engineItems.find(i => i.path.endsWith("/" + id));
        return item ? item.path : "";
    }

    // A busca da Comunidade fica guardada no servico (que continua vivo ao trocar de pagina),
    // mas a caixa de busca volta vazia. Ao abrir a aba, a Comunidade segue o que esta na caixa.
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
                "label": "Funciona perfeitamente"
            },
            "minor": {
                "color": "#f6d58b",
                "label": "Pequenos problemas"
            },
            "broken": {
                "color": "#ff7b7b",
                "label": "Não funciona no Linux"
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
                "scene": "Cena",
                "video": "Vídeo",
                "web": "Web",
                "application": "App",
                "image": "Imagem"
            })[item.type] ?? item.type;
    }

    // ---------- Abas + busca ----------
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
                            "label": "Pasta local",
                            "count": Wallpapers.items.length
                        },
                        {
                            "id": "community",
                            "label": "Comunidade",
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

        // Busca
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
                    text: root.community ? "Buscar na Workshop do Wallpaper Engine" : "Buscar wallpaper"
                    color: Theme.textMuted
                }
            }
        }

        // Testar se os wallpapers funcionam no Linux
        StyledButton {
            id: scanButton
            visible: root.tab === "we"
            anchors.right: refresh.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.check
            text: CompatScan.running ? "Testando…" : "Testar"
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

    // ---------- Pasta (so na aba local) ----------
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
                text: "Pasta"
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

    // ---------- Filtros (so na Comunidade) ----------
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

    // ---------- Galeria ----------
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

        // Comunidade: carrega a proxima pagina ao chegar no fim
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
            // Previas da Workshop podem ser GIF sem extensao no link: tenta animar todas ao passar o mouse
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

                // Previas .gif animam ao passar o mouse
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

                // Selo do tipo
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

                // Titulo + compatibilidade
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

            // Selo "Instalado" (Comunidade)
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
                        text: "Instalado"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }
            }

            // Borda e selo do selecionado
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
                        Ui.notify("Aplicando \"" + cell.modelData.name + "\"");
                }
            }
        }
    }

    // Estado vazio
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
            text: root.community && Workshop.error !== "" ? "Não foi possível abrir a Workshop. Confira a internet e clique em atualizar" : root.query !== "" ? "Nada encontrado para \"" + root.query + "\"" : root.tab === "we" ? "Nenhum wallpaper do Wallpaper Engine encontrado na Steam" : "Nenhuma imagem ou vídeo nesta pasta"
            color: Theme.textMuted
        }
    }

    // ---------- Teste de compatibilidade ----------
    // Progresso
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
                text: CompatScan.total > 0 ? "Testando " + Math.min(CompatScan.done + 1, CompatScan.total) + " de " + CompatScan.total + (CompatScan.current ? "  ·  " + CompatScan.current : "") : "Preparando o teste…"
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
            text: "Parar"
            onClicked: CompatScan.cancel()
        }
    }

    // Menu do botao "Testar"
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
                        "title": "Testar os que faltam (" + CompatScan.untested + ")",
                        "description": "Só os que ainda não têm o pontinho de compatibilidade"
                    },
                    {
                        "mode": "all",
                        "title": "Testar todos de novo (" + Wallpapers.engineItems.length + ")",
                        "description": "Refaz o teste de todos os wallpapers"
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
                text: "Cada wallpaper roda 5 segundos escondido (3 por vez). Nada aparece na sua tela."
                color: Theme.textMuted
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }
        }
    }

    // Carregando a Comunidade
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
            text: "Carregando a Workshop…"
            color: Theme.textDim
        }
    }

    // Aplica um item da Comunidade: se ja estiver instalado aplica, senao abre na Steam para assinar
    function applyCommunity(item) {
        const path = installedPath(item.id);
        if (path) {
            Wallpapers.apply(path);
            Ui.notify("Aplicando \"" + item.name + "\"");
        } else {
            Workshop.openInSteam(item.id);
            Ui.notify("Clique em \"Inscrever-se\" na Steam. Quando baixar, aparece como instalado");
        }
    }

    // ---------- Rodape ----------
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
                text: root.selectedItem ? root.selectedItem.name : "Nenhum wallpaper selecionado"
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
                        const status = root.installedIds.includes(item.id) ? "Instalado" : Workshop.watching === item.id ? "Esperando a Steam baixar…" : "Não instalado";
                        return root.typeLabel(item) + " · " + Workshop.formatCount(item.subscriptions) + " inscritos · " + Workshop.formatSize(item.size) + " · " + status;
                    }
                    const origin = item.source === "we" ? "Wallpaper Engine" : "Pasta local";
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

            // Comunidade
            StyledButton {
                visible: root.community && root.selectedItem !== null
                text: "Ver no navegador"
                icon: Icons.code
                onClicked: Workshop.openInBrowser(root.selectedItem.id)
            }

            StyledButton {
                visible: root.community && root.selectedItem !== null
                readonly property bool installed: root.selectedItem !== null && root.installedIds.includes(root.selectedItem.id)
                text: installed ? "Aplicar agora" : "Baixar pela Steam"
                icon: installed ? Icons.check : Icons.add
                primary: true
                onClicked: root.applyCommunity(root.selectedItem)
            }

            StyledButton {
                visible: !root.community
                text: "Usar no preset ativo"
                icon: Icons.presets
                opacity: enabled ? 1 : 0.4
                enabled: root.selectedPath !== "" && Config.preset(Config.options.activePreset) !== null
                onClicked: {
                    // Saves to the active preset and puts it on screen, so both stay in sync
                    Config.updatePreset(Config.options.activePreset, {
                        "wallpaper": root.selectedPath
                    });
                    Wallpapers.apply(root.selectedPath);
                    Ui.notify("Wallpaper salvo no preset \"" + Config.preset(Config.options.activePreset).name + "\"");
                }
            }

            StyledButton {
                visible: !root.community
                text: "Aplicar agora"
                icon: Icons.check
                primary: true
                opacity: enabled ? 1 : 0.4
                enabled: root.selectedItem !== null
                onClicked: {
                    if (Wallpapers.apply(root.selectedItem.path))
                        Ui.notify("Aplicando \"" + root.selectedItem.name + "\"");
                }
            }
        }
    }
}
