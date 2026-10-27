import QtQuick
import qs.config
import qs.components
import qs.services
import qs.widgets

// Editor de layouts de widgets: arraste os widgets na previa da area de trabalho.
// Por enquanto e so previa, nada e colocado na tela de verdade.
Item {
    id: root

    readonly property var layout: Config.layout(Config.options.activeLayout)
    readonly property var activePreset: Config.preset(Config.options.activePreset)
    property bool pickerOpen: false

    function newLayout() {
        const n = Config.options.widgetLayouts.length + 1;
        // Comeca como copia do layout atual
        const widgets = layout ? JSON.parse(JSON.stringify(layout.widgets)) : [];
        Config.addLayout("Meu layout " + n, widgets);
        Ui.notify("Layout criado. Clique duas vezes no nome para renomear");
    }

    function addWidget(type) {
        const t = Ui.widgetType(type);
        if (!layout || !t)
            return;
        const x = (1 - t.w / Ui.screenWidth) / 2;
        const y = (1 - t.h / Ui.screenHeight) / 2;
        canvas.selected = Config.addWidget(layout.id, type, x, y);
        canvas.forceActiveFocus();
        pickerOpen = false;
    }

    // ---------- Layouts + adicionar ----------
    Item {
        id: top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40

        Flickable {
            anchors.left: parent.left
            anchors.right: desktopToggle.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            height: 36
            contentWidth: chips.width
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: chips
                spacing: 8

                Repeater {
                    model: Config.options.widgetLayouts

                    delegate: LayoutChip {
                        required property var modelData
                        layout: modelData
                    }
                }

                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: newMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    border.width: 1
                    border.color: Theme.surfaceHigh

                    Icon {
                        anchors.centerIn: parent
                        path: Icons.add
                        size: 18
                        color: Theme.textDim
                    }

                    MouseArea {
                        id: newMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.newLayout()
                    }
                }
            }
        }

        // Liga/desliga os widgets na area de trabalho de verdade
        Row {
            id: desktopToggle
            anchors.right: addButton.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Mostrar na área de trabalho"
                color: Theme.textDim
            }

            Toggle {
                anchors.verticalCenter: parent.verticalCenter
                checked: Config.options.widgetsEnabled
                onToggled: c => {
                    System.setWidgetsEnabled(c);
                    Ui.notify(c ? "Widgets na área de trabalho" : "Widgets escondidos");
                }
            }
        }

        StyledButton {
            id: addButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.add
            text: "Adicionar widget"
            primary: true
            onClicked: root.pickerOpen = !root.pickerOpen
        }
    }

    // ---------- Previa ----------
    WidgetCanvas {
        id: canvas
        anchors.top: top.bottom
        anchors.topMargin: 14
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width, (parent.height - top.height - 14 - hint.height - 12) * Ui.screenWidth / Ui.screenHeight)
        height: width * Ui.screenHeight / Ui.screenWidth
        radius: Theme.radiusMedium
        editable: true
        layout: root.layout
        wallpaper: Wallpapers.thumbFor(root.activePreset && root.activePreset.wallpaper ? root.activePreset.wallpaper : Config.options.wallpaper)
        barStyle: root.activePreset ? root.activePreset.bar : "floating"
    }

    // ---------- Controles do widget selecionado ----------
    Rectangle {
        id: hint

        readonly property var sel: canvas.selectedWidget
        readonly property var selInfo: sel ? Ui.widgetType(sel.type) : null

        function alignSelected(h, v) {
            canvas.align(h, v);
            canvas.forceActiveFocus();
        }

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 66
        radius: Theme.radiusMedium
        color: Theme.surface

        StyledText {
            visible: hint.sel === null
            anchors.centerIn: parent
            width: parent.width - 40
            horizontalAlignment: Text.AlignHCenter
            text: "Clique num widget para ajustar  ·  Arraste o canto para redimensionar  ·  Setas movem (Shift = 1px)  ·  + / − tamanho  ·  Ctrl+D duplica  ·  Delete remove"
            color: Theme.textMuted
            font.pixelSize: 12
        }

        Row {
            visible: hint.sel !== null
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16

            // Nome e posicao
            Row {
                anchors.verticalCenter: parent.verticalCenter
                width: 168
                spacing: 10

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 18
                    color: Theme.alpha(Theme.accent, 0.16)

                    Icon {
                        anchors.centerIn: parent
                        path: hint.selInfo ? hint.selInfo.icon : ""
                        size: 18
                        color: Theme.accent
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    StyledText {
                        text: hint.selInfo ? hint.selInfo.name : ""
                        font.weight: Font.DemiBold
                    }
                    StyledText {
                        text: hint.sel ? "X " + Math.round(hint.sel.x * Ui.screenWidth) + "  ·  Y " + Math.round(hint.sel.y * Ui.screenHeight) + " px" : ""
                        color: Theme.textMuted
                        font.pixelSize: 11
                    }
                }
            }

            Divider {}

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                StyledText {
                    leftPadding: 8
                    text: "Tamanho  " + Math.round(sizeSlider.shownValue) + "%"
                    color: Theme.textDim
                    font.pixelSize: 12
                }
                StyledSlider {
                    id: sizeSlider
                    width: 140
                    from: canvas.minScale * 100
                    to: canvas.maxScale * 100
                    stepSize: 5
                    value: hint.sel ? hint.sel.scale * 100 : 100
                    onMoved: v => canvas.setPreview({
                            "scale": v / 100
                        })
                    onCommitted: v => {
                        canvas.commit({
                            "scale": v / 100
                        });
                        canvas.forceActiveFocus();
                    }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                StyledText {
                    leftPadding: 8
                    text: "Fundo  " + Math.round(bgSlider.shownValue) + "%"
                    color: Theme.textDim
                    font.pixelSize: 12
                }
                StyledSlider {
                    id: bgSlider
                    width: 120
                    from: 0
                    to: 100
                    stepSize: 5
                    value: hint.sel ? hint.sel.bgOpacity * 100 : 89
                    onMoved: v => canvas.setPreview({
                            "bgOpacity": v / 100
                        })
                    onCommitted: v => {
                        canvas.commit({
                            "bgOpacity": v / 100
                        });
                        canvas.forceActiveFocus();
                    }
                }
            }

            Divider {}

            // Alinhar: linha de cima = horizontal, linha de baixo = vertical
            Grid {
                anchors.verticalCenter: parent.verticalCenter
                columns: 3
                spacing: 3

                AlignButton {
                    icon: Icons.alignLeft
                    h: "left"
                    onClicked: hint.alignSelected(h, v)
                }
                AlignButton {
                    icon: Icons.alignCenterH
                    h: "center"
                    onClicked: hint.alignSelected(h, v)
                }
                AlignButton {
                    icon: Icons.alignRight
                    h: "right"
                    onClicked: hint.alignSelected(h, v)
                }
                AlignButton {
                    icon: Icons.alignTop
                    v: "top"
                    onClicked: hint.alignSelected(h, v)
                }
                AlignButton {
                    icon: Icons.alignCenterV
                    v: "middle"
                    onClicked: hint.alignSelected(h, v)
                }
                AlignButton {
                    icon: Icons.alignBottom
                    v: "bottom"
                    onClicked: hint.alignSelected(h, v)
                }
            }

            Divider {}

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                IconButton {
                    icon: Icons.restore
                    iconSize: 17
                    iconColor: Theme.textDim
                    onClicked: {
                        canvas.commit({
                            "scale": 1,
                            "bgOpacity": Ui.defaultBg(hint.sel.type)
                        });
                        canvas.forceActiveFocus();
                    }
                }
                IconButton {
                    icon: Icons.copy
                    iconSize: 17
                    iconColor: Theme.textDim
                    onClicked: {
                        canvas.duplicate();
                        canvas.forceActiveFocus();
                    }
                }
                IconButton {
                    icon: Icons.trash
                    iconSize: 17
                    iconColor: Theme.textDim
                    onClicked: canvas.removeSelected()
                }
            }
        }
    }

    // ---------- Menu de widgets ----------
    MouseArea {
        anchors.fill: parent
        visible: root.pickerOpen
        onClicked: root.pickerOpen = false
    }

    Rectangle {
        id: picker
        anchors.right: parent.right
        anchors.top: top.bottom
        anchors.topMargin: 8
        width: 580
        height: pickerColumn.height + 16
        radius: Theme.radiusMedium
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        opacity: root.pickerOpen ? 1 : 0
        scale: root.pickerOpen ? 1 : 0.95
        transformOrigin: Item.TopRight
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutCubic
            }
        }

        Grid {
            id: pickerColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            columns: 2
            columnSpacing: 4
            rowSpacing: 2

            Repeater {
                model: Ui.widgetTypes

                delegate: Rectangle {
                    id: option

                    required property var modelData

                    width: (pickerColumn.width - 4) / 2
                    height: 56
                    radius: Theme.radiusSmall
                    color: optionMouse.containsMouse ? Theme.surfaceHover : "transparent"

                    Rectangle {
                        id: optionIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        height: 36
                        radius: 18
                        color: Theme.alpha(Theme.accent, 0.16)

                        Icon {
                            anchors.centerIn: parent
                            path: option.modelData.icon
                            size: 18
                            color: Theme.accent
                        }
                    }

                    Column {
                        anchors.left: optionIcon.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        StyledText {
                            width: parent.width
                            text: option.modelData.name
                            font.weight: Font.DemiBold
                        }
                        StyledText {
                            width: parent.width
                            text: option.modelData.description
                            color: Theme.textMuted
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: optionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.addWidget(option.modelData.id)
                    }
                }
            }
        }
    }
}
