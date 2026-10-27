pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Current weather via wttr.in (no API key). Empty city = detected from the connection.
Singleton {
    id: root

    property bool ready: false
    property string temperature: "--"
    property string condition: "Loading weather"
    property string city: ""
    property string humidity: "--"
    property string wind: "--"
    property string icon: Icons.cloud

    readonly property string query: encodeURIComponent(Config.options.weatherCity.trim())

    function refresh() {
        if (!proc.running)
            proc.running = true;
    }

    // wttr.in codes -> icon
    function iconFor(code) {
        const c = Number(code);
        if (c === 113)
            return Icons.sun;
        if ([200, 386, 389, 392, 395].includes(c))
            return Icons.storm;
        if (c >= 176 && c !== 248 && c !== 260)
            return Icons.drop;
        return Icons.cloud;
    }

    onQueryChanged: refresh()

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: proc

        command: ["curl", "-s", "-m", "15", "https://wttr.in/" + root.query + "?format=j1"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    const c = data.current_condition[0];
                    const desc = c.weatherDesc[0].value;
                    root.temperature = c.temp_C + "°C";
                    root.condition = desc.charAt(0).toUpperCase() + desc.slice(1);
                    root.humidity = c.humidity + "%";
                    root.wind = c.windspeedKmph + " km/h";
                    root.icon = root.iconFor(c.weatherCode);
                    root.city = Config.options.weatherCity.trim() || data.nearest_area[0].areaName[0].value;
                    root.ready = true;
                } catch (e) {
                    if (!root.ready)
                        root.condition = "Weather unavailable";
                }
            }
        }
    }
}
