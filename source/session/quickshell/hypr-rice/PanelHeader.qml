import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property alias trailing: trailingText.text
    signal closeRequested
    signal backRequested
    property bool showBack: false

    spacing: 10

    PanelButton {
        visible: root.showBack
        text: "‹"
        implicitWidth: 34
        fontPixelSize: 20
        onClicked: root.backRequested()
    }

    Text {
        visible: root.icon.length > 0
        text: root.icon
        color: Theme.primary
        font.family: "JetBrainsMono Nerd Font Propo"
        font.pixelSize: 18
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Text {
            Layout.fillWidth: true
            text: root.title
            color: Theme.foreground
            font.pixelSize: 18
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Text {
            visible: text.length > 0
            Layout.fillWidth: true
            text: root.subtitle
            color: Theme.foregroundVariant
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }

    Text {
        id: trailingText
        color: Theme.foregroundVariant
        font.pixelSize: 11
    }

    PanelButton {
        text: "×"
        implicitWidth: 38
        implicitHeight: 38
        fontPixelSize: 19
        onClicked: root.closeRequested()
    }
}
