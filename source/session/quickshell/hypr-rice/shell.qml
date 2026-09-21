import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

ShellRoot {
    id: shell

    NotificationStore {
        id: notifications
        dnd: controlCenter.settingsData.dnd === true
        onCenterRequested: shell.openNotifications(true)
        onDndChangeRequested: enabled => controlCenter.backendAction(["dnd", enabled ? "on" : "off"])
    }

    NotificationPopups {
        store: notifications
        onCenterRequested: shell.openNotifications(true)
    }

    NotificationCenter {
        id: notificationCenter
        store: notifications
    }

    ControlCenter {
        id: controlCenter
        onPerformanceRequested: shell.openPerformance()
        onMenuBarRequested: shell.openMenuBar()
    }

    PerformanceNetwork {
        id: performanceNetwork
        data: controlCenter.backendData
        runAction: args => controlCenter.backendAction(args)
    }

    MenuBarManager {
        id: menuBarManager
        settings: controlCenter.settingsData
    }

    TrayDrawer {
        id: trayDrawer
        hiddenIds: controlCenter.settingsData.menuBar
            ? (controlCenter.settingsData.menuBar.trayHidden || [])
            : []
        onManageRequested: shell.openMenuBar()
    }

    HyprlandFocusGrab {
        id: panelFocus
        windows: [
            notificationCenter.window,
            controlCenter.window,
            performanceNetwork.window,
            menuBarManager.window,
            trayDrawer.window
        ]
        active: notificationCenter.open || controlCenter.open || performanceNetwork.open
            || menuBarManager.open || trayDrawer.open
        onCleared: shell.closeAll()
    }

    function closeExcept(name: string): void {
        if (name !== "notifications") notificationCenter.hide();
        if (name !== "control") controlCenter.hide();
        if (name !== "performance") performanceNetwork.hide();
        if (name !== "menu") menuBarManager.hide();
        if (name !== "tray") trayDrawer.hide();
    }

    function openNotifications(markRead: bool): void {
        shell.closeExcept("notifications");
        notificationCenter.show(markRead);
    }

    function openPerformance(): void {
        shell.closeExcept("performance");
        performanceNetwork.show();
    }

    function openMenuBar(): void {
        shell.closeExcept("menu");
        menuBarManager.show();
    }

    function openTray(): void {
        shell.closeExcept("tray");
        trayDrawer.show();
    }

    function closeAll(): void {
        shell.closeExcept("");
    }

    IpcHandler {
        target: "panels"

        function toggleControl(): void {
            if (controlCenter.open)
                controlCenter.hide();
            else {
                shell.closeExcept("control");
                controlCenter.show("home");
            }
        }

        function openControl(section: string): void {
            shell.closeExcept("control");
            controlCenter.show(section);
        }

        function toggleNotifications(): void {
            if (notificationCenter.open)
                notificationCenter.hide();
            else
                shell.openNotifications(true);
        }

        function openNotifications(): void {
            shell.openNotifications(true);
        }

        function togglePerformance(): void {
            if (performanceNetwork.open)
                performanceNetwork.hide();
            else
                shell.openPerformance();
        }

        function toggleMenuBar(): void {
            if (menuBarManager.open)
                menuBarManager.hide();
            else
                shell.openMenuBar();
        }

        function toggleTray(): void {
            if (trayDrawer.open)
                trayDrawer.hide();
            else
                shell.openTray();
        }

        function closeAll(): void {
            shell.closeAll();
        }
    }
}
