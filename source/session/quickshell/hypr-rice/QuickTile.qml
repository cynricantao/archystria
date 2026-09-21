import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string state: ""
    property bool active: false
    property bool detailsAvailable: false
    property bool enabled: true
    signal clicked
    signal detailsClicked

    implicitHeight: 76
    radius: Theme.cardRadius
    color: root.active
        ? Qt.rgba(Theme.primaryContainer.r, Theme.primaryContainer.g, Theme.primaryContainer.b, 0.94)
        : (bodyArea.containsMouse && root.enabled ? Theme.surfaceHigh : Theme.surfaceLow)
    opacity: root.enabled ? 1 : 0.46

    Behavior on color {
        ColorAnimation { duration: Theme.fastMotionMs }
    }

    RowLayout {
        z: 1
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 38
            Layout.preferredHeight: 38
            radius: 12
            color: root.active
                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
                : Theme.surfaceContainer

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.active ? Theme.primaryContainerForeground : Theme.foregroundVariant
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 18
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.title
                color: root.active ? Theme.primaryContainerForeground : Theme.foreground
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.state
                color: root.active
                    ? Qt.rgba(Theme.primaryContainerForeground.r, Theme.primaryContainerForeground.g, Theme.primaryContainerForeground.b, 0.74)
                    : Theme.foregroundVariant
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        Text {
            visible: root.detailsAvailable
            text: "›"
            color: root.active ? Theme.primaryContainerForeground : Theme.foregroundVariant
            font.pixelSize: 20
        }
    }

    MouseArea {
        id: detailsArea
        z: 2
        visible: root.detailsAvailable
        enabled: root.enabled && root.detailsAvailable
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 48
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            mouse.accepted = true;
            root.detailsClicked();
        }
    }

    MouseArea {
        id: bodyArea
        z: 0
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
