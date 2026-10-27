import QtQuick

// Enfileira itens na horizontal ou, na barra lateral, na vertical.
// (-1 = deixa o Grid calcular: 1 coluna na vertical, 1 linha na horizontal)
Grid {
    property bool vertical: BarStyle.vertical

    columns: vertical ? 1 : -1
    rows: vertical ? -1 : 1
    spacing: 4
    verticalItemAlignment: Grid.AlignVCenter
    horizontalItemAlignment: Grid.AlignHCenter
}
