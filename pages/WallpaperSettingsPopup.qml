import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.components
import qs.services

// Settings of a Wallpaper Engine wallpaper (sound, FPS, scaling, effects and the options the
// wallpaper itself offers, read from its project.json) plus the performance settings shared by
// every wallpaper. Changes are saved right away and the wallpaper restarts if it's on screen.
Rectangle {
    id: root

    property var item: null
    readonly property string path: item ? item.path : ""
    readonly property bool engine: item !== null && item.source === "we"
    readonly property var s: Config.wallpaperSetting(path)

    // Options from project.json: [{ name, type, label, value, min, max, step, options }]
    property var props: []

    signal closed

    color: "#b0000000"
    radius: Theme.radius

    // Restarts the wallpapers when the change shows on screen (after a short pause, so going
    // through chips doesn't restart them every time, and so config.json is written before
    // apply-wallpaper.sh reads it). everyone = a setting shared by all wallpapers.
    property bool applyAll: false

    function changed(everyone) {
        if (everyone || Quickshell.screens.some(sc => Config.monitorWallpaper(sc.name) === path))
            applyAll = true;
        applyDelay.restart();
    }

    Timer {
        id: applyDelay
        interval: 700
        onTriggered: {
            if (root.applyAll)
                Wallpapers.applyAll();
            root.applyAll = false;
        }
    }

    function set(patch) {
        Config.setWallpaperSetting(path, patch);
        changed();
    }

    function propValue(p) {
        const v = s.properties[p.name];
        return v === undefined ? p.value : v;
    }

    function setProp(p, value) {
        Config.setWallpaperProperty(path, p.name, value);
        changed();
    }

    // "0.5 0.2 1" (project.json) or [0.5, 0.2, 1] (saved) -> color
    function toColor(v) {
        const c = Array.isArray(v) ? v : String(v).split(/[\s,]+/).map(Number);
        return Qt.rgba(c[0] || 0, c[1] || 0, c[2] || 0, 1);
    }

    function label(text, loc) {
        let t = String(text ?? "");
        if (loc && loc[t])
            t = loc[t];
        if (t === "ui_browse_properties_scheme_color")
            return "Theme color";
        t = t.replace(/^ui_browse_properties_/, "").replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim();
        return t.charAt(0).toUpperCase() + t.slice(1);
    }

    function parseProject(text) {
        try {
            const general = JSON.parse(text.replace(/^﻿/, "")).general ?? {};
            const loc = general.localization ? (general.localization["en-us"] ?? {}) : {};
            const list = [];
            for (const name in general.properties ?? {}) {
                const p = general.properties[name];
                if (!["bool", "slider", "combo", "color"].includes(p.type))
                    continue;
                list.push({
                    "name": name,
                    "type": p.type,
                    "label": label(p.text, loc) || name,
                    "order": p.order ?? 0,
                    "value": p.value,
                    "min": Number(p.min ?? 0),
                    "max": Number(p.max ?? 100),
                    "step": Number(p.step ?? 0),
                    "options": (p.options ?? []).map(o => ({
                                "label": label(o.label, loc),
                                "value": o.value
                            }))
                });
            }
            root.props = list.sort((a, b) => a.order - b.order);
        } catch (e) {
            root.props = [];
        }
    }

    FileView {
        path: root.engine && root.path !== "" ? root.path + "/project.json" : ""
        onLoaded: root.parseProject(text())
        onLoadFailed: root.props = []
    }

    onPathChanged: props = []

    // Click outside the panel closes it
    MouseArea {
        anchors.fill: parent
        onClicked: root.closed()
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(parent.width - 60, 760)
        height: Math.min(parent.height - 60, 640)
        radius: Theme.radius
        color: Theme.sidebar
        border.width: 1
        border.color: Theme.border

        // Swallow clicks so they don't close the popup
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 18
            height: 44

            Column {
                anchors.left: parent.left
                anchors.right: closeButton.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                StyledText {
                    text: "Wallpaper settings"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
                StyledText {
                    width: parent.width
                    visible: root.item !== null
                    text: root.item ? root.item.name : ""
                    color: Theme.textMuted
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            IconButton {
                id: closeButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.close
                iconColor: Theme.textDim
                baseColor: "transparent"
                onClicked: root.closed()
            }
        }

        Flickable {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 18
            anchors.topMargin: 10
            contentHeight: content.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: content
                width: parent.width
                spacing: 8

                // ---------- This wallpaper ----------
                StyledText {
                    text: "This wallpaper"
                    color: Theme.textDim
                    font.weight: Font.DemiBold
                }

                StyledText {
                    visible: !root.engine
                    width: parent.width
                    text: root.item ? "Videos and images play without sound. Pausing (below) works for them too." : "Select a wallpaper in the gallery to change its settings."
                    color: Theme.textMuted
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                SettingRow {
                    visible: root.engine
                    width: parent.width
                    icon: root.s.sound ? Icons.volume : Icons.volumeOff
                    title: "Sound"
                    subtitle: "Music and effects of this wallpaper"
                    Toggle {
                        checked: root.s.sound
                        onToggled: c => root.set({
                                "sound": c
                            })
                    }
                }

                SettingRow {
                    visible: root.engine && root.s.sound
                    width: parent.width
                    icon: Icons.volume
                    title: "Volume  " + Math.round(volumeSlider.shownValue) + "%"
                    StyledSlider {
                        id: volumeSlider
                        width: 240
                        from: 0
                        to: 100
                        stepSize: 1
                        value: root.s.volume
                        onCommitted: v => root.set({
                                "volume": Math.round(v)
                            })
                    }
                }

                SettingRow {
                    visible: root.engine && root.s.sound
                    width: parent.width
                    icon: Icons.music
                    title: "Mute while other apps play sound"
                    subtitle: "E.g. while Spotify or a video is playing"
                    Toggle {
                        checked: root.s.autoMute
                        onToggled: c => root.set({
                                "autoMute": c
                            })
                    }
                }

                SettingRow {
                    visible: root.engine
                    width: parent.width
                    icon: Icons.speed
                    title: "FPS limit"
                    subtitle: "Lower = lighter on the GPU and games"
                    Row {
                        spacing: 6
                        Repeater {
                            model: [0, 15, 24, 30, 60]
                            delegate: FilterChip {
                                required property int modelData
                                label: modelData === 0 ? "Default (" + Config.options.wallpaperFps + ")" : String(modelData)
                                active: root.s.fps === modelData
                                onClicked: root.set({
                                    "fps": modelData
                                })
                            }
                        }
                    }
                }

                SettingRow {
                    visible: root.engine
                    width: parent.width
                    icon: Icons.wallpaper
                    title: "Scaling"
                    Row {
                        spacing: 6
                        Repeater {
                            model: [
                                {
                                    "id": "fill",
                                    "label": "Fill"
                                },
                                {
                                    "id": "fit",
                                    "label": "Fit"
                                },
                                {
                                    "id": "stretch",
                                    "label": "Stretch"
                                },
                                {
                                    "id": "default",
                                    "label": "Original"
                                }
                            ]
                            delegate: FilterChip {
                                required property var modelData
                                label: modelData.label
                                active: root.s.scaling === modelData.id
                                onClicked: root.set({
                                    "scaling": modelData.id
                                })
                            }
                        }
                    }
                }

                SettingRow {
                    visible: root.engine
                    width: parent.width
                    icon: Icons.sparkle
                    title: "Particles"
                    subtitle: "Turning them off helps a lot on heavy wallpapers"
                    Toggle {
                        checked: root.s.particles
                        onToggled: c => root.set({
                                "particles": c
                            })
                    }
                }

                SettingRow {
                    visible: root.engine
                    width: parent.width
                    icon: Icons.person
                    title: "Mouse interaction"
                    subtitle: "Effects that follow the mouse"
                    Toggle {
                        checked: root.s.mouse
                        onToggled: c => root.set({
                                "mouse": c
                            })
                    }
                }

                SettingRow {
                    visible: root.engine
                    width: parent.width
                    icon: Icons.restore
                    title: "Parallax"
                    subtitle: "The image moves a little with the mouse"
                    Toggle {
                        checked: root.s.parallax
                        onToggled: c => root.set({
                                "parallax": c
                            })
                    }
                }

                // ---------- Options of the wallpaper itself ----------
                StyledText {
                    visible: root.engine && root.props.length > 0
                    topPadding: 10
                    text: "Wallpaper options"
                    color: Theme.textDim
                    font.weight: Font.DemiBold
                }

                Repeater {
                    model: root.engine ? root.props : []

                    delegate: SettingRow {
                        id: propRow

                        required property var modelData
                        readonly property var value: root.propValue(modelData)

                        width: content.width
                        icon: modelData.type === "color" ? Icons.palette : modelData.type === "bool" ? Icons.check : Icons.tune
                        title: modelData.type === "slider" ? modelData.label + "  " + Number(propSlider.shownValue).toFixed(modelData.step > 0 && modelData.step < 1 ? 2 : 0) : modelData.label

                        Row {
                            spacing: 6

                            Toggle {
                                visible: propRow.modelData.type === "bool"
                                checked: propRow.value === true || propRow.value === 1 || propRow.value === "1" || propRow.value === "true"
                                onToggled: c => root.setProp(propRow.modelData, c)
                            }

                            StyledSlider {
                                id: propSlider
                                visible: propRow.modelData.type === "slider"
                                width: 240
                                from: propRow.modelData.min
                                to: propRow.modelData.max
                                stepSize: propRow.modelData.step
                                value: Number(propRow.value) || 0
                                onCommitted: v => root.setProp(propRow.modelData, v)
                            }

                            // Few options: one chip each. Many: one chip that goes to the next option.
                            Repeater {
                                model: propRow.modelData.type === "combo" && propRow.modelData.options.length <= 4 ? propRow.modelData.options : []
                                delegate: FilterChip {
                                    required property var modelData
                                    label: modelData.label
                                    active: String(propRow.value) === String(modelData.value)
                                    onClicked: root.setProp(propRow.modelData, modelData.value)
                                }
                            }

                            FilterChip {
                                readonly property var options: propRow.modelData.options
                                readonly property int current: options.findIndex(o => String(o.value) === String(propRow.value))
                                visible: propRow.modelData.type === "combo" && options.length > 4
                                label: (current >= 0 ? options[current].label : String(propRow.value)) + "  ›"
                                active: true
                                onClicked: root.setProp(propRow.modelData, options[(current + 1) % options.length].value)
                            }

                            Swatch {
                                visible: propRow.modelData.type === "color"
                                color: root.toColor(propRow.value)
                                onClicked: Ui.pickColor(propRow.modelData.label, color.toString(), hex => {
                                    const c = Qt.color(hex);
                                    root.setProp(propRow.modelData, [c.r, c.g, c.b]);
                                })
                            }
                        }
                    }
                }

                StyledButton {
                    visible: root.engine
                    icon: Icons.restore
                    text: "Reset this wallpaper"
                    onClicked: {
                        Config.resetWallpaperSettings(root.path);
                        root.changed();
                        Ui.notify("Settings reset");
                    }
                }

                // ---------- All wallpapers ----------
                StyledText {
                    topPadding: 14
                    text: "All wallpapers"
                    color: Theme.textDim
                    font.weight: Font.DemiBold
                }

                SettingRow {
                    width: parent.width
                    icon: Icons.pause
                    title: "Pause wallpapers"
                    subtitle: "Frees the GPU for games when the wallpaper is covered"
                    Row {
                        spacing: 6
                        Repeater {
                            model: [
                                {
                                    "id": "never",
                                    "label": "Never"
                                },
                                {
                                    "id": "fullscreen",
                                    "label": "Fullscreen apps"
                                },
                                {
                                    "id": "windows",
                                    "label": "Any window"
                                }
                            ]
                            delegate: FilterChip {
                                required property var modelData
                                label: modelData.label
                                active: Config.options.wallpaperPause === modelData.id
                                onClicked: Config.options.wallpaperPause = modelData.id
                            }
                        }
                    }
                }

                SettingRow {
                    width: parent.width
                    icon: Icons.speed
                    title: "Default FPS limit"
                    subtitle: "For wallpapers without their own limit"
                    Row {
                        spacing: 6
                        Repeater {
                            model: [15, 24, 30, 60]
                            delegate: FilterChip {
                                required property int modelData
                                label: String(modelData)
                                active: Config.options.wallpaperFps === modelData
                                onClicked: {
                                    Config.options.wallpaperFps = modelData;
                                    root.changed(true);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
