import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Scope {
    id: root

    readonly property string unreadPath: Quickshell.env("HYPR_RICE_UNREAD_PATH") || (Quickshell.env("XDG_RUNTIME_DIR") + "/hypr-rice-notifications.json")
    property var records: []
    property var popupKeys: []
    property int revision: 0
    property bool dnd: false
    readonly property int unreadCount: {
        root.revision;
        let count = 0;
        for (const record of root.records) {
            if (record.unread)
                count++;
        }
        return count;
    }

    signal centerRequested
    signal dndChangeRequested(bool enabled)

    function setDnd(enabled: bool): void {
        root.dndChangeRequested(enabled);
    }

    function plainText(value: string): string {
        return (value || "").replace(/<[^>]*>/g, "").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">");
    }

    function findIndex(key: string): int {
        for (let i = 0; i < root.records.length; i++) {
            if (root.records[i].key === key)
                return i;
        }
        return -1;
    }

    function recordFor(key: string): var {
        const index = root.findIndex(key);
        return index >= 0 ? root.records[index] : null;
    }

    function popupRecords(): var {
        root.revision;
        const result = [];
        for (const key of root.popupKeys) {
            const record = root.recordFor(key);
            if (record)
                result.push(record);
        }
        return result;
    }

    function commit(nextRecords: var): void {
        root.records = nextRecords;
        root.revision++;
        root.writeUnreadState();
    }

    function writeUnreadState(): void {
        let count = 0;
        for (const record of root.records) {
            if (record.unread)
                count++;
        }
        const payload = {
            unread: count,
            hasUnread: count > 0,
            updatedAt: new Date().toISOString()
        };
        unreadFile.setText(JSON.stringify(payload) + "\n");
    }

    function add(notification: var): void {
        notification.tracked = true;
        const now = new Date();
        const key = String(notification.id) + ":" + String(now.getTime()) + ":" + String(root.revision);
        const record = {
            key: key,
            id: notification.id,
            notification: notification,
            active: true,
            appName: notification.appName || "Unknown application",
            appIcon: notification.appIcon || notification.desktopEntry || "dialog-information",
            summary: root.plainText(notification.summary || "Notification"),
            body: root.plainText(notification.body || ""),
            urgency: notification.urgency,
            transient: notification.transient,
            createdAt: now,
            unread: !notification.transient
        };
        notification.closed.connect(function(reason) {
            root.markInactive(key);
        });
        const next = root.records.slice();
        next.unshift(record);
        if (!root.dnd)
            root.popupKeys = [key].concat(root.popupKeys).slice(0, 4);
        root.commit(next);
    }

    function notificationAlive(notification: var): bool {
        try {
            return notification && notification.id !== undefined;
        } catch (error) {
            return false;
        }
    }

    function markInactive(key: string): void {
        const index = root.findIndex(key);
        if (index < 0 || !root.records[index].active)
            return;
        const next = root.records.slice();
        const updated = Object.assign({}, next[index]);
        updated.active = false;
        updated.notification = null;
        next[index] = updated;
        root.popupKeys = root.popupKeys.filter(existing => existing !== key);
        root.commit(next);
    }

    function removePopup(key: string): void {
        root.popupKeys = root.popupKeys.filter(existing => existing !== key);
        root.revision++;
    }

    function markAllRead(): void {
        let changed = false;
        const next = root.records.map(function(record) {
            if (!record.unread)
                return record;
            changed = true;
            return Object.assign({}, record, { unread: false });
        });
        if (changed)
            root.commit(next);
        else
            root.writeUnreadState();
    }

    function dismiss(key: string): void {
        const index = root.findIndex(key);
        if (index < 0)
            return;
        const record = root.records[index];
        const liveNotification = record.notification;
        const shouldDismiss = record.active && root.notificationAlive(liveNotification);
        const next = root.records.slice();
        next.splice(index, 1);
        root.popupKeys = root.popupKeys.filter(existing => existing !== key);
        root.commit(next);
        if (shouldDismiss) {
            try {
                liveNotification.dismiss();
            } catch (error) {
                console.warn("dismiss on destroyed notification ignored");
            }
        }
    }

    function clearAll(): void {
        const current = root.records.slice();
        root.records = [];
        root.popupKeys = [];
        root.revision++;
        root.writeUnreadState();
        for (const record of current) {
            if (record.active && root.notificationAlive(record.notification)) {
                try {
                    record.notification.dismiss();
                } catch (error) {
                    console.warn("dismiss on destroyed notification ignored");
                }
            }
        }
    }

    function invoke(key: string, action: var): void {
        const record = root.recordFor(key);
        if (!record || !record.active || !root.notificationAlive(record.notification))
            return;
        try {
            action.invoke();
        } catch (error) {
            console.warn("action invoke failed: " + error);
        }
        root.removePopup(key);
    }

    FileView {
        id: unreadFile
        path: root.unreadPath
        atomicWrites: true
        blockWrites: false
        printErrors: false
    }

    NotificationServer {
        id: server
        keepOnReload: false
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: true
        inlineReplySupported: false
        onNotification: notification => root.add(notification)
    }

    onDndChanged: {
        if (root.dnd) {
            root.popupKeys = [];
            root.revision++;
        }
    }

    Component.onCompleted: root.writeUnreadState()
}
