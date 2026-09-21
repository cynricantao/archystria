import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root

    property string icon: ""
    property string label: ""
    property string detail: ""
    property real from: 0
    property real to: 1
    property real value: 0
    property bool controlEnabled: true
    property bool muted: false
    signal moved(real nextValue)
    signal committed(real nextValue)
    signal iconClicked

    spacing: 10
    opacity: root.controlEnabled ? 1 : 0.48

    Rectangle {
        Layout.preferredWidth: 34
        Layout.preferredHeight: 34
        radius: 11
        color: iconArea.containsMouse ? Theme.surfaceBright : Theme.surfaceHigh

        Text {
            anchors.centerIn: parent
            text: root.icon
            color: root.muted ? Theme.error : Theme.foreground
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 16
        }

        MouseArea {
            id: iconArea
            anchors.fill: parent
            enabled: root.controlEnabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: root.label
                color: Theme.foreground
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                text: root.detail
                color: Theme.foregroundVariant
                font.pixelSize: 10
            }
        }

        Slider {
            id: slider
            Layout.fillWidth: true
            implicitHeight: 18
            from: root.from
            to: root.to
            value: root.value
            enabled: root.controlEnabled

            onMoved: {
                root.value = value;
                root.moved(value);
            }
            onPressedChanged: {
                if (!pressed)
                    root.committed(value);
            }

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 5
                radius: 3
                color: Theme.surfaceBright

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    radius: parent.radius
                    color: Theme.primary
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                implicitWidth: 14
                implicitHeight: 14
                radius: 7
                color: slider.pressed ? Theme.primaryContainerForeground : Theme.primary
                border.width: 2
                border.color: Theme.surfaceContainer
            }
        }
    }
}
