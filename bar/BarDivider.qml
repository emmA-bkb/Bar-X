import QtQuick

// Separador fininho entre grupos (horizontal ou vertical).
Rectangle {
    width: BarStyle.vertical ? 16 : 1
    height: BarStyle.vertical ? 1 : 16
    color: BarStyle.border
}
