import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.components
import qs.pages
import qs.services

ShellRoot {
    id: root

    property bool open: false
    property bool alive: false

    readonly property var pages: [
        {
            "title": "Presets",
            "icon": Icons.presets,
            "component": presetsPage
        },
        {
            "title": "Wallpaper",
            "icon": Icons.wallpaper,
            "component": wallpaperPage
        },
        {
            "title": "Barra",
            "icon": Icons.bar,
            "component": barPage
        },
        {
            "title": "Widgets",
            "icon": Icons.widgets,
            "component": widgetsPage
        },
        {
            "title": "Aparência",
            "icon": Icons.palette,
            "component": appearancePage
        },
        {
            "title": "Sobre",
            "icon": Icons.info,
            "component": aboutPage
        }
    ]

    function show() {
        hideTimer.stop();
        alive = true;
        revealTimer.restart();
    }

    function hide() {
        revealTimer.stop();
        open = false;
        hideTimer.restart();
    }

    Component.onCompleted: show()

    // qs -p <pasta> ipc call uix toggle
    IpcHandler {
        target: "uix"

        function toggle(): void {
            root.open ? root.hide() : root.show();
        }
        function show(): void {
            root.show();
        }
        function hide(): void {
            root.hide();
        }
        function page(index: int): void {
            Ui.page = Math.max(0, Math.min(index, root.pages.length - 1));
            root.show();
        }
    }

    Timer {
        id: revealTimer
        interval: 30
        onTriggered: root.open = true
    }

    Timer {
        id: hideTimer
        interval: Theme.animNormal + 40
        onTriggered: root.alive = false
    }

    Component {
        id: presetsPage
        PresetsPage {}
    }
    Component {
        id: wallpaperPage
        WallpaperPage {}
    }
    Component {
        id: barPage
        BarPage {}
    }
    Component {
        id: widgetsPage
        WidgetsPage {}
    }
    Component {
        id: appearancePage
        AppearancePage {}
    }
    Component {
        id: aboutPage
        AboutPage {}
    }

    PanelWindow {
        id: window

        visible: root.alive
        color: "transparent"
        implicitWidth: 1280
        implicitHeight: 800
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "uix"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Rectangle {
            id: frame

            anchors.fill: parent
            anchors.margins: 10
            radius: Theme.radius
            color: Theme.window
            border.width: 1
            border.color: Theme.border

            opacity: root.open ? 1 : 0
            scale: root.open ? 1 : 0.96

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

            focus: true
            Keys.onEscapePressed: root.hide()

            // ---------- Barra lateral ----------
            Rectangle {
                id: sidebar

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 12
                width: 232
                radius: Theme.radius - 6
                color: Theme.sidebar

                // Perfil
                Row {
                    id: profile
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.leftMargin: 18
                    anchors.topMargin: 22
                    spacing: 12

                    ClippingRectangle {
                        width: 46
                        height: 46
                        radius: 23
                        color: Theme.alpha(Theme.accent, 0.2)

                        Icon {
                            anchors.centerIn: parent
                            visible: face.status !== Image.Ready
                            path: Icons.person
                            size: 24
                            color: Theme.accent
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
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        StyledText {
                            text: System.user
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                        StyledText {
                            text: System.distro
                            color: Theme.textMuted
                            font.pixelSize: 12
                        }
                    }
                }

                Rectangle {
                    id: divider
                    anchors.top: profile.bottom
                    anchors.topMargin: 18
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    height: 1
                    color: Theme.border
                }

                StyledButton {
                    id: configButton
                    anchors.top: divider.bottom
                    anchors.topMargin: 16
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    implicitHeight: 48
                    icon: Icons.edit
                    text: "Arquivo de config"
                    onClicked: Quickshell.execDetached(["xdg-open", Config.path])
                }

                Column {
                    anchors.top: configButton.bottom
                    anchors.topMargin: 24
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 6

                    Repeater {
                        model: root.pages

                        delegate: NavItem {
                            required property var modelData
                            required property int index

                            width: parent.width
                            icon: modelData.icon
                            label: modelData.title
                            active: Ui.page === index
                            onClicked: Ui.page = index
                        }
                    }
                }
            }

            // ---------- Conteudo ----------
            Item {
                id: contentArea

                anchors.left: sidebar.right
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: 28
                anchors.rightMargin: 26
                anchors.topMargin: 22
                anchors.bottomMargin: 22

                // Cabecalho da pagina
                Item {
                    id: header
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 40

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: Theme.surfaceHover

                            Icon {
                                anchors.centerIn: parent
                                path: root.pages[Ui.page].icon
                                size: 17
                                color: Theme.textDim
                            }
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.pages[Ui.page].title
                            font.pixelSize: 19
                            font.weight: Font.DemiBold
                        }
                    }

                    IconButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        icon: Icons.close
                        iconColor: Theme.textDim
                        baseColor: "transparent"
                        onClicked: root.hide()
                    }
                }

                Loader {
                    id: pageLoader

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: header.bottom
                    anchors.topMargin: 20
                    height: parent.height - header.height - 20
                    sourceComponent: root.pages[Ui.page].component

                    onLoaded: pageIn.restart()

                    ParallelAnimation {
                        id: pageIn
                        NumberAnimation {
                            target: pageLoader
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: Theme.animNormal
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: pageLoader
                            property: "anchors.topMargin"
                            from: 32
                            to: 20
                            duration: Theme.animNormal
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // ---------- Seletor de cor (por cima de tudo) ----------
            Rectangle {
                id: pickerLayer
                anchors.fill: parent
                radius: Theme.radius
                color: "#99000000"
                z: 50
                visible: opacity > 0
                opacity: Ui.colorRequest ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.animFast
                    }
                }

                // Clique fora fecha
                MouseArea {
                    anchors.fill: parent
                    onClicked: Ui.colorRequest = null
                }

                ColorPicker {
                    id: colorPicker
                    anchors.centerIn: parent
                    scale: Ui.colorRequest ? 1 : 0.95

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animFast
                            easing.type: Easing.OutCubic
                        }
                    }

                    onAccepted: hex => {
                        const req = Ui.colorRequest;
                        Ui.colorRequest = null;
                        if (req && req.callback)
                            req.callback(hex);
                    }
                    onCanceled: Ui.colorRequest = null
                }

                Connections {
                    target: Ui
                    function onColorRequestChanged() {
                        if (Ui.colorRequest)
                            colorPicker.open(Ui.colorRequest.title, Ui.colorRequest.color);
                    }
                }
            }

            // ---------- Aviso (toast) ----------
            Rectangle {
                id: toast

                property string message

                anchors.horizontalCenter: contentArea.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: shown ? 24 : 6
                width: toastText.implicitWidth + 44
                height: 40
                radius: 20
                color: Theme.surfaceHigh
                border.width: 1
                border.color: Theme.border
                opacity: shown ? 1 : 0

                property bool shown: false

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.animNormal
                    }
                }
                Behavior on anchors.bottomMargin {
                    NumberAnimation {
                        duration: Theme.animNormal
                        easing.type: Easing.OutCubic
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        path: Icons.check
                        size: 16
                        color: Theme.accent
                    }
                    StyledText {
                        id: toastText
                        anchors.verticalCenter: parent.verticalCenter
                        text: toast.message
                    }
                }

                Timer {
                    id: toastTimer
                    interval: 2200
                    onTriggered: toast.shown = false
                }

                Connections {
                    target: Ui
                    function onToast(message) {
                        toast.message = message;
                        toast.shown = true;
                        toastTimer.restart();
                    }
                }
            }
        }
    }
}
