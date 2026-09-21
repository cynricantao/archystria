import QtQuick

Rectangle {
    id: root

    property real surfaceOpacity: 0.94
    property bool elevated: true

    radius: Theme.radius
    color: Qt.rgba(
        Theme.surfaceContainer.r,
        Theme.surfaceContainer.g,
        Theme.surfaceContainer.b,
        root.surfaceOpacity
    )
    border.width: 1
    border.color: Qt.rgba(
        Theme.outlineVariant.r,
        Theme.outlineVariant.g,
        Theme.outlineVariant.b,
        0.58
    )
    clip: true
}
