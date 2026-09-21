import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland

Scope {
    id: root

    required property var store
    property bool open: false
    property bool innerShown: false
    property var expandedGroups: ({})
    property int expansionRevision: 0
    readonly property alias window: panelWindow

    SystemClock {
        id: sectionClock
        precision: SystemClock.Minutes
    }

    function focusedScreen(): var {
        for (const candidate of Quickshell.screens) {
            const monitor = Hyprland.monitorFor(candidate);
            if (monitor && monitor.focused)
                return candidate;
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function show(markRead: bool): void {
        closeTimer.stop();
        root.open = true;
        panelWindow.visible = true;
        for (const key of root.store.popupKeys.slice())
            root.store.removePopup(key);
        if (markRead)
            root.store.markAllRead();
        Qt.callLater(function() {
            root.innerShown = true;
        });
    }

    function hide(): void {
        root.open = false;
        root.innerShown = false;
        closeTimer.restart();
    }

    function toggle(markRead: bool): void {
        if (root.open)
            root.hide();
        else
            root.show(markRead);
    }

    function sectionFor(dateValue: var): string {
        const date = new Date(dateValue);
        const now = new Date();
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const yesterday = new Date(today.getTime() - 86400000);
        if (date >= today)
            return "RECENT";
        if (date >= yesterday)
            return "YESTERDAY";
        return "OLDER";
    }

    function groupedRecords(): var {
        root.store.revision;
        sectionClock.date;
        const order = ["RECENT", "YESTERDAY", "OLDER"];
        const buckets = ({ "RECENT": {}, "YESTERDAY": {}, "OLDER": {} });
        for (const record of root.store.records) {
            if (record.transient)
                continue;
            const section = root.sectionFor(record.createdAt);
            const app = record.appName || "Unknown application";
            if (!buckets[section][app])
                buckets[section][app] = [];
            buckets[section][app].push(record);
        }
        const result = [];
        for (const section of order) {
            const names = Object.keys(buckets[section]);
            names.sort(function(a, b) {
                return new Date(buckets[section][b][0].createdAt) - new Date(buckets[section][a][0].createdAt);
            });
            for (const appName of names) {
                result.push({
                    key: section + ":" + appName,
                    section: section,
                    appName: appName,
                    records: buckets[section][appName]
                });
            }
        }
        return result;
    }

    function isExpanded(key: string): bool {
        root.expansionRevision;
        return root.expandedGroups[key] === true;
    }

    function savedCount(): int {
        root.store.revision;
        let count = 0;
        for (const record of root.store.records) {
            if (!record.transient)
                count++;
        }
        return count;
    }

    function toggleExpanded(key: string): void {
        const next = Object.assign({}, root.expandedGroups);
        next[key] = !root.isExpanded(key);
        root.expandedGroups = next;
        root.expansionRevision++;
    }

    Timer {
        id: closeTimer
        interval: Theme.motionMs
        onTriggered: panelWindow.visible = false
    }

    PanelWindow {
        id: panelWindow
        visible: false
        screen: root.focusedScreen()
        anchors.top: true
        anchors.right: true
        margins.top: 38
        margins.right: 10
        implicitWidth: 390
        implicitHeight: Math.min(700, centerContent.implicitHeight + 28)
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        color: "transparent"

        PanelSurface {
            id: surface
            anchors.fill: parent
            anchors.rightMargin: root.innerShown ? 0 : -22
            opacity: root.innerShown ? 1 : 0
            surfaceOpacity: 0.94

            Behavior on anchors.rightMargin {
                NumberAnimation { duration: Theme.motionMs; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: Theme.motionMs; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                id: centerContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                height: implicitHeight
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    spacing: 6

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: "Notifications"
                            color: Theme.text
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: root.savedCount() + " saved · " + root.store.unreadCount + " unread"
                            color: Theme.muted
                            font.pixelSize: 10
                        }
                    }

                    PanelButton {
                        text: "Clear"
                        implicitHeight: 32
                        enabled: root.store.records.length > 0
                        onClicked: root.store.clearAll()
                    }
                    PanelButton {
                        text: "×"
                        implicitWidth: 32
                        implicitHeight: 32
                        onClicked: root.hide()
                    }
                }

                ScrollView {
                    id: notificationScroll
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(groupColumn.implicitHeight, 640)
                    contentWidth: availableWidth
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    Column {
                        id: groupColumn
                        width: notificationScroll.availableWidth
                        spacing: 8

                        Repeater {
                            model: root.groupedRecords()

                            Column {
                                id: groupDelegate
                                required property var modelData
                                required property int index
                                width: groupColumn.width
                                spacing: 6
                                property bool firstInSection: index === 0 || root.groupedRecords()[index - 1].section !== modelData.section

                                Text {
                                    visible: groupDelegate.firstInSection
                                    text: groupDelegate.modelData.section
                                    color: Theme.muted
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    leftPadding: 8
                                    topPadding: 3
                                }

                                NotificationCard {
                                    width: parent.width
                                    record: groupDelegate.modelData.records[0]
                                    prominent: true
                                    compact: true
                                    groupCount: groupDelegate.modelData.records.length
                                    groupExpanded: root.isExpanded(groupDelegate.modelData.key)
                                    onGroupToggleRequested: root.toggleExpanded(groupDelegate.modelData.key)
                                    onDismissRequested: root.store.dismiss(record.key)
                                    onActionRequested: action => root.store.invoke(record.key, action)
                                }

                                Repeater {
                                    model: root.isExpanded(groupDelegate.modelData.key) ? groupDelegate.modelData.records.slice(1) : []
                                    NotificationCard {
                                        required property var modelData
                                        width: groupDelegate.width
                                        record: modelData
                                        compact: true
                                        onDismissRequested: root.store.dismiss(record.key)
                                        onActionRequested: action => root.store.invoke(record.key, action)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: root.store.records.length === 0
                            width: parent.width
                            height: 54
                            radius: 16
                            color: Qt.rgba(0.12, 0.12, 0.15, 0.72)
                            border.color: Qt.rgba(1, 1, 1, 0.14)
                            Text {
                                anchors.centerIn: parent
                                text: "No notifications"
                                color: Theme.muted
                                font.pixelSize: 13
                            }
                        }
                    }
                }
            }
        }

        Shortcut {
            sequence: "Escape"
            enabled: root.open
            onActivated: root.hide()
        }
    }
}
