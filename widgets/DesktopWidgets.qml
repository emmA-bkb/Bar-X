import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Coloca os widgets do layout ativo na area de trabalho de verdade.
// Ficam na camada "bottom": acima do wallpaper e abaixo das janelas.
Scope {
    id: root

    readonly property var layout: Config.layout(Config.options.activeLayout)
    // Widgets live on the primary monitor
    readonly property var screen: Ui.screen
    readonly property real glass: Config.currentTransparency()
    readonly property bool darkText: Colors.glassText(glass, Wallpapers.thumbFor(Config.options.wallpaper))

    Variants {
        model: Config.options.widgetsEnabled && root.layout && root.screen ? root.layout.widgets : []

        delegate: PanelWindow {
            id: window

            required property var modelData
            readonly property var info: Ui.widgetType(modelData.type)
            readonly property real widgetScale: modelData.scale ?? 1

            screen: root.screen
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                left: true
            }

            // Posicao salva como fracao da tela
            margins {
                left: Math.round(modelData.x * root.screen.width)
                top: Math.round(modelData.y * root.screen.height)
            }

            implicitWidth: info ? Math.round(info.w * widgetScale) : 1
            implicitHeight: info ? Math.round(info.h * widgetScale) : 1

            WlrLayershell.namespace: "uix-widget"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // Desenhado no tamanho original e reduzido/ampliado pelo "scale" do widget
            WidgetView {
                type: window.modelData.type
                glass: root.glass
                darkText: root.darkText
                backgroundOpacity: window.modelData.bgOpacity ?? Ui.defaultBg(window.modelData.type)
                width: implicitWidth
                height: implicitHeight
                transformOrigin: Item.TopLeft
                scale: window.widgetScale
            }
        }
    }
}
