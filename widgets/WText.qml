import QtQuick
import qs.config

// Texto dos widgets. QtRendering para continuar nitido quando o widget e redimensionado.
// A cor padrao vem do cartao do widget (paleta manual ou do wallpaper).
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
