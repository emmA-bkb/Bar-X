import QtQuick
import QtQuick.Shapes
import qs.config

// Desenha um caminho SVG 24x24 (ver config/Icons.qml) em qualquer tamanho e cor.
Item {
    id: root

    property string path
    property color color: Theme.text
    property real size: 20

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            xScale: root.size / 24
            yScale: root.size / 24
        }

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            strokeWidth: 0

            PathSvg {
                path: root.path
            }
        }
    }
}
