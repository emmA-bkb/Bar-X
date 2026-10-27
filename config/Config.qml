pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Configuracao persistente em ~/.config/uix/config.json
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: home + "/.config/uix"
    readonly property string path: dir + "/config.json"
    property alias options: adapter

    function expand(p) {
        return p.startsWith("~") ? home + p.slice(1) : p;
    }

    function preset(id) {
        return options.presets.find(p => p.id === id) ?? null;
    }

    function addPreset(p) {
        options.presets = options.presets.concat([p]);
    }

    function removePreset(id) {
        options.presets = options.presets.filter(p => p.id !== id);
        if (options.activePreset === id)
            options.activePreset = "";
    }

    function updatePreset(id, patch) {
        options.presets = options.presets.map(p => p.id === id ? Object.assign({}, p, patch) : p);
    }

    // ---------- Layouts de widgets ----------

    function layout(id) {
        return options.widgetLayouts.find(l => l.id === id) ?? null;
    }

    // Layout mostrado para um preset (sem layout proprio, usa o ativo)
    function layoutFor(p) {
        return (p && p.widgets ? layout(p.widgets) : null) ?? layout(options.activeLayout);
    }

    function setActiveLayout(id) {
        options.activeLayout = id;
        if (preset(options.activePreset))
            updatePreset(options.activePreset, {
                "widgets": id
            });
    }

    function addLayout(name, widgets) {
        const id = "layout-" + Date.now();
        options.widgetLayouts = options.widgetLayouts.concat([
            {
                "id": id,
                "name": name,
                "widgets": widgets
            }
        ]);
        setActiveLayout(id);
    }

    function removeLayout(id) {
        if (options.widgetLayouts.length <= 1)
            return;
        options.widgetLayouts = options.widgetLayouts.filter(l => l.id !== id);
        if (options.activeLayout === id)
            setActiveLayout(options.widgetLayouts[0].id);
    }

    function updateLayout(id, patch) {
        options.widgetLayouts = options.widgetLayouts.map(l => l.id === id ? Object.assign({}, l, patch) : l);
    }

    function editWidgets(layoutId, fn) {
        const l = layout(layoutId);
        if (l)
            updateLayout(layoutId, {
                "widgets": fn(l.widgets)
            });
    }

    function addWidget(layoutId, type, x, y) {
        const uid = "w" + Date.now().toString(36);
        editWidgets(layoutId, ws => ws.concat([
            {
                "uid": uid,
                "type": type,
                "x": x,
                "y": y
            }
        ]));
        return uid;
    }

    function moveWidget(layoutId, uid, x, y) {
        updateWidget(layoutId, uid, {
            "x": x,
            "y": y
        });
    }

    // patch: qualquer campo do widget (x, y, scale, bgOpacity...)
    function updateWidget(layoutId, uid, patch) {
        editWidgets(layoutId, ws => ws.map(w => w.uid === uid ? Object.assign({}, w, patch) : w));
    }

    // Copia um widget (mesmo tamanho e fundo) na posicao indicada
    function duplicateWidget(layoutId, uid, x, y) {
        const l = layout(layoutId);
        const w = l ? l.widgets.find(i => i.uid === uid) : null;
        if (!w)
            return "";
        const copy = Object.assign({}, w, {
            "uid": "w" + Date.now().toString(36),
            "x": x,
            "y": y
        });
        editWidgets(layoutId, ws => ws.concat([copy]));
        return copy.uid;
    }

    function removeWidget(layoutId, uid) {
        editWidgets(layoutId, ws => ws.filter(w => w.uid !== uid));
    }

    // Transparencia (efeito vidro) da barra e dos widgets: a do preset ativo, ou a geral
    function transparencyFor(p) {
        return p && p.transparency !== undefined ? p.transparency : options.transparency;
    }

    function currentTransparency() {
        return transparencyFor(preset(options.activePreset));
    }

    function setTransparency(v) {
        if (preset(options.activePreset))
            updatePreset(options.activePreset, {
                "transparency": v
            });
        else
            options.transparency = v;
    }

    // Estilo de barra em uso: o do preset ativo, ou o padrao
    function currentBarStyle() {
        const p = preset(options.activePreset);
        return p && p.bar ? p.bar : options.barStyle;
    }

    // Atualiza o estado salvo. A barra do Uix acompanha sozinha (ela le este arquivo);
    // o wallpaper e aplicado por quem chama (ver PresetCard).
    function applyPreset(id) {
        const p = preset(id);
        if (!p)
            return;
        options.activePreset = id;
        options.accent = p.accent;
        if (p.wallpaper)
            options.wallpaper = p.wallpaper;
        if (p.widgets && layout(p.widgets))
            options.activeLayout = p.widgets;
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", dir])

    FileView {
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter

            property string wallpaperDir: "~/Videos/Wallpapers"
            property string wallpaper: ""
            property string accent: "#7fd1c4"
            property string activePreset: "aurora"
            property bool animations: true
            property bool applyOnLogin: true
            property bool restoreBar: true

            // Barra de tarefas: "waybar" (a sua atual) ou "uix" (barras do Uix)
            property string barProvider: "waybar"
            property string barStyle: "floating" // usado quando nenhum preset esta ativo
            property string launcherCommand: "sh $HOME/.config/waybar/launcher.sh"

            // Apps na barra: ordenados pela area de trabalho, com o numero dela no icone
            property bool taskbarSortByWorkspace: true
            property bool taskbarWorkspaceBadge: true

            // Widgets na area de trabalho (layout ativo)
            property bool widgetsEnabled: false
            property string weatherCity: "" // vazio = detectar pela internet

            // Cores dos widgets: "manual" (abaixo) ou "wallpaper" (tiradas do wallpaper)
            property string widgetColorMode: "manual"
            property string widgetAccent: "" // vazio = cor de destaque do preset
            property string widgetBackground: "#131618"
            property bool dynamicBarColors: false // a barra tambem usa as cores dos widgets
            property string barActiveColor: "" // cor da florzinha / area ativa; vazio = automatico
            property real transparency: 0 // barra e widgets transparentes (0..1), quando nenhum preset esta ativo
            property string activeLayout: "padrao"

            // Posicoes x/y sao fracoes da tela (0..1), canto superior esquerdo do widget
            property var widgetLayouts: [
                {
                    "id": "padrao",
                    "name": "Padrão",
                    "widgets": [
                        { "uid": "clock1", "type": "clock", "x": 0.78, "y": 0.09 },
                        { "uid": "cal1", "type": "calendar", "x": 0.0125, "y": 0.09 },
                        { "uid": "weather1", "type": "weather", "x": 0.0125, "y": 0.42 },
                        { "uid": "media1", "type": "media", "x": 0.75, "y": 0.8 }
                    ]
                },
                {
                    "id": "minimal",
                    "name": "Minimal",
                    "widgets": [
                        { "uid": "clock2", "type": "clock", "x": 0.4125, "y": 0.4 }
                    ]
                },
                {
                    "id": "trabalho",
                    "name": "Trabalho",
                    "widgets": [
                        { "uid": "sys3", "type": "system", "x": 0.7725, "y": 0.09 },
                        { "uid": "cal3", "type": "calendar", "x": 0.815, "y": 0.24 },
                        { "uid": "media3", "type": "media", "x": 0.0125, "y": 0.8 }
                    ]
                }
            ]

            // bar: "floating" | "island" | "minimal"
            property var presets: [
                {
                    "id": "aurora",
                    "name": "Aurora",
                    "bar": "floating",
                    "widgets": "padrao",
                    "accent": "#7fd1c4",
                    "wallpaper": ""
                },
                {
                    "id": "sakura",
                    "name": "Sakura",
                    "bar": "island",
                    "widgets": "trabalho",
                    "accent": "#f4a7c0",
                    "wallpaper": ""
                },
                {
                    "id": "meia-noite",
                    "name": "Meia-noite",
                    "bar": "minimal",
                    "widgets": "minimal",
                    "accent": "#a7b0ff",
                    "wallpaper": ""
                }
            ]
        }
    }
}
