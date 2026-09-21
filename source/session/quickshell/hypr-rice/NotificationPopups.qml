import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PanelWindow {
    id: window

    required property var store
    signal centerRequested

    function focusedScreen(): var {
        for (const candidate of Quickshell.screens) {
            const monitor = Hyprland.monitorFor(candidate);
            if (monitor && monitor.focused)
                return candidate;
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    visible: popupRepeater.count > 0
    screen: focusedScreen()
    anchors.top: true
    anchors.right: true
    margins.top: 38
    margins.right: 10
    implicitWidth: 400
    implicitHeight: popupColumn.implicitHeight
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    ColumnLayout {
        id: popupColumn
        anchors.fill: parent
        spacing: 8

        Repeater {
            id: popupRepeater
            model: window.store.popupRecords()

            NotificationCard {
                required property var modelData
                Layout.fillWidth: true
                record: modelData
                prominent: true
                popup: true
                onDismissRequested: window.store.dismiss(record.key)
                onActionRequested: action => window.store.invoke(record.key, action)
                onPopupExpired: {
                    window.store.removePopup(record.key);
                    if (record.transient && record.active && record.notification) {
                        try {
                            record.notification.expire();
                        } catch (error) {
                            console.warn("expire on destroyed notification ignored");
                        }
                    }
                }
                onCenterRequested: window.centerRequested()
            }
        }
    }
}
