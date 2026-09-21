import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Rectangle {
    id: root

    property var item: null
    property var parentWindow: null
    property bool dimmed: false

    function friendlyName() {
        if (!root.item)
            return "";
        return root.item.tooltipTitle || root.item.title || root.item.id || "Tray application";
    }

    implicitHeight: 48
    radius: 11
    color: mouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceLow
    opacity: root.dimmed ? 0.68 : 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: 9
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            radius: 9
            color: Theme.surfaceContainer
            IconImage {
                anchors.centerIn: parent
                implicitSize: 20
                width: 20
                height: 20
                source: root.item ? root.item.icon : ""
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                Layout.fillWidth: true
                text: root.friendlyName()
                color: Theme.foreground
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.item
                    ? ((root.item.title && root.item.title !== root.friendlyName()) ? root.item.title : root.item.id)
                    : ""
                color: Theme.foregroundVariant
                font.pixelSize: 9
                elide: Text.ElideRight
            }
        }

        Text {
            text: root.item && root.item.hasMenu ? "⋮" : "›"
            color: Theme.foregroundVariant
            font.pixelSize: 17
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: pointer => {
            if (!root.item)
                return;
            if (pointer.button === Qt.MiddleButton) {
                root.item.secondaryActivate();
            } else if (pointer.button === Qt.RightButton || root.item.onlyMenu) {
                const point = root.mapToItem(null, pointer.x, pointer.y);
                root.item.display(root.parentWindow, Math.round(point.x), Math.round(point.y));
            } else {
                root.item.activate();
            }
        }
    }
}
