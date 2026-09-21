import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string title: ""
    property string value: ""
    property string detail: ""
    property var history: []
    property color accent: Theme.primary

    implicitHeight: 116
    radius: Theme.cardRadius
    color: Theme.surfaceLow
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: root.title
                color: Theme.foregroundVariant
                font.pixelSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                text: root.value
                color: Theme.foreground
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.detail
            color: Theme.foregroundVariant
            font.pixelSize: 9
            elide: Text.ElideRight
        }

        Sparkline {
            Layout.fillWidth: true
            Layout.fillHeight: true
            values: root.history
            strokeColor: root.accent
            fillColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10)
            maximum: 100
        }
    }
}
