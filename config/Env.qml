pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Machine-specific settings from the project's .env file (not committed; see .env.example).
// Lookup order: real environment variable > .env > the fallback given in the code.
Singleton {
    id: root

    property var values: ({})

    function get(key, fallback) {
        const fromEnv = Quickshell.env(key);
        if (fromEnv)
            return fromEnv;
        return values[key] ?? fallback;
    }

    // KEY=VALUE per line; "#" comments; optional quotes; ~ and $HOME expanded
    function parse(text) {
        const out = {};
        const home = Quickshell.env("HOME");
        for (const raw of text.split("\n")) {
            const line = raw.trim();
            if (!line || line.startsWith("#") || !line.includes("="))
                continue;
            const key = line.slice(0, line.indexOf("=")).trim().replace(/^export\s+/, "");
            let value = line.slice(line.indexOf("=") + 1).trim();
            if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'")))
                value = value.slice(1, -1);
            value = value.replace(/^~(?=\/|$)/, home).replace(/\$HOME|\$\{HOME\}/g, home);
            out[key] = value;
        }
        root.values = out;
    }

    FileView {
        path: Quickshell.shellPath(".env")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parse(text())
        onLoadFailed: root.values = {}
    }
}
