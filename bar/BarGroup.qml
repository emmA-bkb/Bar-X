import QtQuick

// Lays items out horizontally or, on the side bar, vertically.
// (-1 = let the Grid decide: 1 column when vertical, 1 row when horizontal)
Grid {
    property bool vertical: BarStyle.vertical

    columns: vertical ? 1 : -1
    rows: vertical ? -1 : 1
    spacing: 4
    verticalItemAlignment: Grid.AlignVCenter
    horizontalItemAlignment: Grid.AlignHCenter
}
