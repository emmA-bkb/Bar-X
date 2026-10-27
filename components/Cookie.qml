import QtQuick
import QtQuick.Shapes

// Forma de "florzinha" (como os botoes do Material 3 Expressive).
// lobes = quantidade de petalas, depth = quanto as petalas entram (0..0.3).
Item {
    id: root

    property real size: 48
    property int lobes: 8
    property real depth: 0.12
    property color color: "white"
    property bool spinning: false // gira devagar (ex.: enquanto a musica toca)

    implicitWidth: size
    implicitHeight: size

    readonly property string svg: {
        const n = lobes * 24;
        const R = size / 2;
        let d = "";
        for (let i = 0; i <= n; i++) {
            const t = i / n * 2 * Math.PI;
            const r = R * (1 - depth) + R * depth * (1 + Math.cos(lobes * t)) / 2;
            const x = (R + r * Math.cos(t)).toFixed(2);
            const y = (R + r * Math.sin(t)).toFixed(2);
            d += (i === 0 ? "M" : "L") + x + " " + y + " ";
        }
        return d + "Z";
    }

    Shape {
        id: shape
        width: root.size
        height: root.size
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            strokeWidth: 0

            PathSvg {
                path: root.svg
            }
        }

        RotationAnimation on rotation {
            running: root.spinning
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 12000
        }
    }
}
