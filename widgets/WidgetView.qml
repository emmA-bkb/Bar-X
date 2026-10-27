import QtQuick
import qs.config
import qs.services

// Loads the right widget by type, at real size (screen pixels),
// and passes down the colors (manual palette or wallpaper).
Item {
    id: root

    property string type
    // { accent, bg, fg, fgDim, fgMuted, onAccent }
    property var colors: Colors.current
    property real backgroundOpacity: Ui.defaultBg(type)
    // Glass effect: 0 = normal, 1 = fully transparent background
    property real glass: 0
    // Dark text (glass over a light wallpaper)
    property bool darkText: false

    readonly property var info: Ui.widgetType(type)

    implicitWidth: info ? info.w : 0
    implicitHeight: info ? info.h : 0

    readonly property var components: ({
            "clock": clock,
            "calendar": calendar,
            "media": media,
            "weather": weather,
            "system": system,
            "mediaFlower": mediaFlower,
            "clockStacked": clockStacked,
            "statTiles": statTiles,
            "weekStrip": weekStrip,
            "profile": profile,
            "weatherFlower": weatherFlower
        })

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: root.components[root.type] ?? null
    }

    Binding {
        when: loader.item !== null
        target: loader.item
        property: "accent"
        value: root.colors ? root.colors.accent : "#7fd1c4"
    }
    Binding {
        when: loader.item !== null
        target: loader.item
        property: "bgColor"
        value: root.colors ? root.colors.bg : "#131618"
    }
    Binding {
        when: loader.item !== null
        target: loader.item
        property: "fg"
        value: root.darkText ? Colors.darkText.fg : root.colors ? root.colors.fg : "#e6e9ec"
    }
    Binding {
        when: loader.item !== null
        target: loader.item
        property: "fgDim"
        value: root.darkText ? Colors.darkText.fgDim : root.colors ? root.colors.fgDim : "#a3abb3"
    }
    Binding {
        when: loader.item !== null
        target: loader.item
        property: "fgMuted"
        value: root.darkText ? Colors.darkText.fgMuted : root.colors ? root.colors.fgMuted : "#6c757d"
    }
    Binding {
        when: loader.item !== null
        target: loader.item
        property: "onAccent"
        value: root.colors ? root.colors.onAccent : "#10201d"
    }
    Binding {
        when: loader.item !== null
        target: loader.item
        property: "backgroundOpacity"
        value: root.backgroundOpacity * (1 - root.glass * 0.85)
    }

    Component {
        id: clock
        ClockWidget {}
    }
    Component {
        id: calendar
        CalendarWidget {}
    }
    Component {
        id: media
        MediaWidget {}
    }
    Component {
        id: weather
        WeatherWidget {}
    }
    Component {
        id: system
        SystemWidget {}
    }
    Component {
        id: mediaFlower
        MediaFlowerWidget {}
    }
    Component {
        id: clockStacked
        ClockStackedWidget {}
    }
    Component {
        id: statTiles
        StatTilesWidget {}
    }
    Component {
        id: weekStrip
        WeekStripWidget {}
    }
    Component {
        id: profile
        ProfileWidget {}
    }
    Component {
        id: weatherFlower
        WeatherFlowerWidget {}
    }
}
