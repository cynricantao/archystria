import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    required property var record
    property bool prominent: false
    property bool popup: false
    property bool compact: false
    property int groupCount: 1
    property bool groupExpanded: false
    signal dismissRequested
    signal actionRequested(var action)
    signal popupExpired
    signal centerRequested
    signal groupToggleRequested

    implicitHeight: content.implicitHeight + (compact ? 16 : 24)
    radius: compact ? 16 : 12
    color: compact ? Qt.rgba(0.12, 0.12, 0.15, 0.76) : (prominent ? Theme.panelHigh : Theme.panel)
    border.color: record.urgency === 2
        ? Theme.error
        : (record.unread ? Theme.accent : (compact ? Qt.rgba(1, 1, 1, 0.16) : Theme.border))
    border.width: prominent || record.unread ? 1 : 0

    MouseArea {
        anchors.fill: parent
        acceptedButtons: root.popup ? Qt.LeftButton : Qt.NoButton
        onClicked: root.centerRequested()
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: root.compact ? 8 : 12
        spacing: root.compact ? 8 : 10

        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: root.compact ? 32 : 38
            Layout.preferredHeight: root.compact ? 32 : 38
            radius: root.compact ? 9 : 10
            color: root.compact ? Qt.rgba(0.04, 0.04, 0.06, 0.55) : Theme.bg

            Image {
                anchors.fill: parent
                anchors.margins: root.compact ? 6 : 7
                source: root.record.appIcon.indexOf("/") >= 0 ? root.record.appIcon : Quickshell.iconPath(root.record.appIcon, "dialog-information")
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: root.compact ? 2 : 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: root.record.appName
                    color: Theme.muted
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    text: root.record.active ? timeText(root.record.createdAt) : "closed"
                    color: Theme.muted
                    font.pixelSize: 10
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.record.summary
                color: Theme.text
                font.pixelSize: root.compact ? 14 : (root.prominent ? 15 : 14)
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.record.body
                color: Theme.muted
                font.pixelSize: 12
                wrapMode: Text.Wrap
                maximumLineCount: root.compact ? 2 : (root.prominent ? 4 : 2)
                elide: Text.ElideRight
            }

            Flow {
                Layout.fillWidth: true
                visible: actionRepeater.count > 0
                spacing: 6

                Repeater {
                    id: actionRepeater
                    model: root.activeActions()

                    PanelButton {
                        required property var modelData
                        text: modelData.text
                        implicitHeight: root.compact ? 28 : 30
                        onClicked: root.actionRequested(modelData)
                    }
                }
            }
        }

        PanelButton {
            visible: root.groupCount > 1
            Layout.alignment: Qt.AlignTop
            text: root.groupCount + (root.groupExpanded ? "  ▴" : "  ▾")
            implicitHeight: 28
            foreground: Theme.muted
            onClicked: root.groupToggleRequested()
        }

        PanelButton {
            Layout.alignment: Qt.AlignTop
            text: "×"
            implicitWidth: root.compact ? 28 : 30
            implicitHeight: root.compact ? 28 : 30
            foreground: Theme.muted
            onClicked: root.dismissRequested()
        }
    }

    Timer {
        running: root.popup
        interval: root.record.urgency === 2 ? 10000 : 6000
        onTriggered: root.popupExpired()
    }

    function activeActions(): var {
        try {
            return root.record.active && root.record.notification ? root.record.notification.actions : [];
        } catch (error) {
            return [];
        }
    }

    function timeText(date: var): string {
        const value = new Date(date);
        const now = new Date();
        const deltaMinutes = Math.floor((now.getTime() - value.getTime()) / 60000);
        if (deltaMinutes < 1)
            return "now";
        if (deltaMinutes < 60)
            return deltaMinutes + "m";
        return Qt.formatTime(value, "HH:mm");
    }
}
