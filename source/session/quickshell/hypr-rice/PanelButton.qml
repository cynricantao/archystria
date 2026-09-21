import QtQuick

Rectangle {
    id: root

    property alias text: label.text
    property bool enabled: true
    property bool selected: false
    property color foreground: Theme.text
    property int fontPixelSize: 12
    signal clicked

    implicitWidth: Math.max(34, label.implicitWidth + 20)
    implicitHeight: 34
    radius: 10
    color: root.selected
        ? Theme.primaryContainer
        : (mouse.containsMouse && root.enabled ? Theme.surfaceHigh : "transparent")
    border.width: root.selected ? 1 : 0
    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.42)
    opacity: root.enabled ? 1 : 0.42

    Behavior on color {
        ColorAnimation { duration: Theme.fastMotionMs }
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: root.selected ? Theme.primaryContainerForeground : root.foreground
        font.pixelSize: root.fontPixelSize
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
