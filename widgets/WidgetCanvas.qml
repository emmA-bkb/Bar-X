import QtQuick
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// Desktop miniature: wallpaper, bar and widgets at the real screen's scale.
// With editable = true widgets can be dragged, resized from the corner,
// aligned and adjusted with the keyboard:
//   arrows = move on the grid (Shift = 1px)   + / - = size   Ctrl+D = duplicate   Delete = remove
ClippingRectangle {
    id: root

    property var layout // { id, name, widgets: [{ uid, type, x, y, scale?, bgOpacity? }] }
    property bool editable: false
    property string wallpaper // thumbnail path
    property string barStyle: "floating"
    property color accent: Theme.accent
    // Glass effect (the active preset's by default; preset cards pass their own)
    property real glass: Config.currentTransparency()
    readonly property bool darkText: Colors.glassText(glass, wallpaper)

    property string selected: ""
    property bool dragging: false

    // Change not saved yet (while dragging a control): { uid, patch }
    property var preview: null

    readonly property real s: width / Ui.screenWidth
    readonly property real gridPx: 24 // grid in real screen pixels
    readonly property real grid: gridPx * s
    readonly property real marginPx: 24 // distance from the edges when aligning
    readonly property real topMarginPx: 72 // leaves room for the bar

    readonly property real minScale: 0.4
    readonly property real maxScale: 1.6

    // Widget colors: from this preview's wallpaper, or the manual ones
    // (in manual mode without its own color, uses the shown preset's accent)
    readonly property var colors: {
        if (Colors.dynamic)
            return Colors.forThumb(wallpaper);
        if (Config.options.widgetAccent)
            return Colors.manual;
        return Object.assign({}, Colors.manual, {
            "accent": accent.toString(),
            "onAccent": Colors.onColor(accent)
        });
    }

    readonly property var selectedWidget: {
        if (!layout || selected === "")
            return null;
        const w = layout.widgets.find(i => i.uid === selected);
        return w ? effective(w) : null;
    }

    // ---------- Geometry (all in screen fractions) ----------

    function effective(w) {
        const merged = Object.assign({
            "scale": 1,
            "bgOpacity": Ui.defaultBg(w.type)
        }, w);
        return preview && preview.uid === w.uid ? Object.assign(merged, preview.patch) : merged;
    }

    function sizeOf(w) {
        const info = Ui.widgetType(w.type);
        const sc = w.scale ?? 1;
        return {
            "w": info ? info.w * sc / Ui.screenWidth : 0,
            "h": info ? info.h * sc / Ui.screenHeight : 0
        };
    }

    // Keeps the widget inside the screen
    function clamped(w) {
        const size = sizeOf(w);
        return Object.assign({}, w, {
            "x": Math.max(0, Math.min(w.x, 1 - size.w)),
            "y": Math.max(0, Math.min(w.y, 1 - size.h))
        });
    }

    function setPreview(patch) {
        if (selected !== "")
            preview = {
                "uid": selected,
                "patch": patch
            };
    }

    // Saves a change to the selected widget (moving it if it grows past the screen)
    function commit(patch) {
        preview = null;
        const base = layout ? layout.widgets.find(i => i.uid === selected) : null;
        if (!base)
            return;
        const next = clamped(Object.assign(effective(base), patch));
        const changes = {};
        for (const k in next) {
            if (k !== "uid" && k !== "type" && next[k] !== base[k])
                changes[k] = next[k];
        }
        if (Object.keys(changes).length > 0)
            Config.updateWidget(layout.id, selected, changes);
    }

    function nudge(dxPx, dyPx) {
        const w = selectedWidget;
        if (w)
            commit({
                "x": w.x + dxPx / Ui.screenWidth,
                "y": w.y + dyPx / Ui.screenHeight
            });
    }

    function resizeBy(delta) {
        const w = selectedWidget;
        if (w)
            commit({
                "scale": Math.round(Math.max(minScale, Math.min(maxScale, w.scale + delta)) * 100) / 100
            });
    }

    // h: "left" | "center" | "right" | "", v: "top" | "middle" | "bottom" | ""
    function align(h, v) {
        const w = selectedWidget;
        if (!w)
            return;
        const size = sizeOf(w);
        const mx = marginPx / Ui.screenWidth;
        const patch = {};
        if (h === "left")
            patch.x = mx;
        else if (h === "center")
            patch.x = (1 - size.w) / 2;
        else if (h === "right")
            patch.x = 1 - size.w - mx;
        if (v === "top")
            patch.y = topMarginPx / Ui.screenHeight;
        else if (v === "middle")
            patch.y = (1 - size.h) / 2;
        else if (v === "bottom")
            patch.y = 1 - size.h - marginPx / Ui.screenHeight;
        commit(patch);
    }

    function duplicate() {
        const w = selectedWidget;
        if (!w || !layout)
            return;
        const pos = clamped(Object.assign({}, w, {
            "x": w.x + gridPx * 2 / Ui.screenWidth,
            "y": w.y + gridPx * 2 / Ui.screenHeight
        }));
        selected = Config.duplicateWidget(layout.id, selected, pos.x, pos.y);
    }

    function removeSelected() {
        if (!editable || selected === "" || !layout)
            return;
        Config.removeWidget(layout.id, selected);
        selected = "";
    }

    radius: Theme.radiusSmall
    color: Theme.surfaceHover
    implicitHeight: width * Ui.screenHeight / Ui.screenWidth

    Keys.enabled: editable
    Keys.onPressed: event => {
        if (selected === "")
            return;
        const step = (event.modifiers & Qt.ShiftModifier) ? 1 : gridPx;
        switch (event.key) {
        case Qt.Key_Left:
            nudge(-step, 0);
            break;
        case Qt.Key_Right:
            nudge(step, 0);
            break;
        case Qt.Key_Up:
            nudge(0, -step);
            break;
        case Qt.Key_Down:
            nudge(0, step);
            break;
        case Qt.Key_Plus:
        case Qt.Key_Equal:
            resizeBy(0.05);
            break;
        case Qt.Key_Minus:
            resizeBy(-0.05);
            break;
        case Qt.Key_Delete:
        case Qt.Key_Backspace:
            removeSelected();
            break;
        case Qt.Key_D:
            if (!(event.modifiers & Qt.ControlModifier))
                return;
            duplicate();
            break;
        case Qt.Key_Escape:
            selected = "";
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    WallpaperPreview {
        anchors.fill: parent
        radius: root.radius
        source: root.wallpaper
        accent: root.accent
    }

    BarMock {
        anchors.fill: parent
        glass: root.glass
        barStyle: root.barStyle
        accent: root.accent
        unit: root.width / 320
    }

    // Grid dots while dragging
    Canvas {
        id: dots
        anchors.fill: parent
        opacity: root.dragging ? 0.5 : 0
        visible: opacity > 0
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = "#ffffff";
            const step = root.grid * 2;
            if (step < 4)
                return;
            for (let x = step; x < width; x += step)
                for (let y = step; y < height; y += step)
                    ctx.fillRect(x - 1, y - 1, 2, 2);
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
            }
        }
    }

    // Clicking the background clears the selection
    MouseArea {
        anchors.fill: parent
        enabled: root.editable
        onPressed: {
            root.selected = "";
            root.forceActiveFocus();
        }
    }

    Repeater {
        model: root.layout ? root.layout.widgets : []

        delegate: Item {
            id: w

            required property var modelData
            readonly property var wd: root.effective(modelData)
            readonly property var info: Ui.widgetType(modelData.type)
            readonly property bool isSelected: root.selected === modelData.uid

            x: wd.x * root.width
            y: wd.y * root.height
            width: (info ? info.w : 0) * wd.scale * root.s
            height: (info ? info.h : 0) * wd.scale * root.s
            z: isSelected ? 2 : 1

            WidgetView {
                // In the preview the widgets' buttons don't respond (clicks are for dragging/selecting)
                enabled: false
                type: w.modelData.type
                colors: root.colors
                glass: root.glass
                darkText: root.darkText
                backgroundOpacity: w.wd.bgOpacity
                width: implicitWidth
                height: implicitHeight
                transformOrigin: Item.TopLeft
                scale: root.s * w.wd.scale
            }

            // Selection / hover outline
            Rectangle {
                visible: root.editable && (w.isSelected || mouse.containsMouse)
                anchors.fill: parent
                anchors.margins: -3
                radius: 30 * root.s * w.wd.scale + 3
                color: "transparent"
                border.width: 2
                border.color: w.isSelected ? root.accent : "#70ffffff"
            }

            MouseArea {
                id: mouse

                property bool moved: false

                anchors.fill: parent
                enabled: root.editable
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                drag.target: w
                drag.threshold: 2
                drag.minimumX: 0
                drag.minimumY: 0
                drag.maximumX: root.width - w.width
                drag.maximumY: root.height - w.height

                onPressed: {
                    moved = false;
                    root.selected = w.modelData.uid;
                    root.forceActiveFocus();
                }
                onPositionChanged: {
                    if (drag.active) {
                        moved = true;
                        root.dragging = true;
                    }
                }
                onReleased: mouse => {
                    root.dragging = false;
                    if (!moved)
                        return;
                    // Snaps to the grid (hold Shift to drop freely)
                    const free = mouse.modifiers & Qt.ShiftModifier;
                    const snap = v => free ? v : Math.round(v / root.grid) * root.grid;
                    root.commit({
                        "x": snap(w.x) / root.width,
                        "y": snap(w.y) / root.height
                    });
                }
            }

            // Resize handle (bottom-right corner)
            Rectangle {
                visible: root.editable && w.isSelected && !root.dragging
                x: parent.width - width / 2 - 1
                y: parent.height - height / 2 - 1
                width: 14
                height: 14
                radius: 7
                color: root.accent
                border.width: 3
                border.color: Theme.surface

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    preventStealing: true
                    cursorShape: Qt.SizeFDiagCursor

                    function scaleAt(mouse) {
                        const p = mapToItem(w, mouse.x, mouse.y);
                        const base = w.info;
                        const byW = p.x / (base.w * root.s);
                        const byH = p.y / (base.h * root.s);
                        const sc = Math.max(root.minScale, Math.min(root.maxScale, Math.max(byW, byH)));
                        return Math.round(sc * 20) / 20; // 5% steps
                    }

                    onPositionChanged: mouse => {
                        if (pressed)
                            root.setPreview({
                                "scale": scaleAt(mouse)
                            });
                    }
                    onReleased: mouse => root.commit({
                            "scale": scaleAt(mouse)
                        })
                }
            }

            // Label with name and size
            Rectangle {
                visible: root.editable && w.isSelected && !root.dragging
                anchors.horizontalCenter: parent.horizontalCenter
                y: w.y > height + 12 ? -height - 8 : parent.height + 10
                width: tagText.implicitWidth + 20
                height: 24
                radius: 12
                color: Theme.surfaceHigh
                border.width: 1
                border.color: Theme.border

                StyledText {
                    id: tagText
                    anchors.centerIn: parent
                    text: (w.info ? w.info.name : "") + "  ·  " + Math.round(w.wd.scale * 100) + "%"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
