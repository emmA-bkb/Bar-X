import QtQuick
import qs.config

// Widget text. QtRendering so it stays sharp when the widget is resized.
// The default color comes from the widget card (manual palette or wallpaper).
Text {
    readonly property Item card: {
        let p = parent;
        while (p) {
            if (p.isWidgetCard)
                return p;
            p = p.parent;
        }
        return null;
    }

    color: card ? card.fg : Theme.text
    font.family: Theme.font
    font.pixelSize: 16
    renderType: Text.QtRendering
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
