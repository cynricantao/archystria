import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Scope {
    id: root

    property bool open: false
    property bool innerShown: false
    property var settings: ({})
    property string statusMessage: "Changes apply atomically"
    readonly property var menu: root.settings.menuBar || ({})
    readonly property var modules: root.menu.modules || ({})
    readonly property var trayItems: SystemTray.items.values
    readonly property alias window: panelWindow

    readonly property var moduleRegistry: [
        { id: "media", label: "Media", icon: "󰎆", locked: false },
        { id: "tray", label: "Managed Tray", icon: "󰅀", locked: false },
        { id: "caffeinate", label: "Caffeinate", icon: "󰅶", locked: false },
        { id: "network", label: "Network", icon: "󰈀", locked: false },
        { id: "controlCenter", label: "Control Center", icon: "󰒓", locked: true },
        { id: "clock", label: "Clock", icon: "󰥔", locked: true },
        { id: "weather", label: "Weather", icon: "󰖐", locked: false },
        { id: "microphone", label: "Microphone", icon: "󰍬", locked: false },
        { id: "power", label: "Power", icon: "󰐥", locked: false }
    ]
    readonly property var orderedModules: {
        const configured = root.menu.rightOrder || [];
        const byId = {};
        for (const entry of root.moduleRegistry)
            byId[entry.id] = entry;
        const result = [];
        for (const id of configured) {
            if (byId[id])
                result.push(byId[id]);
        }
        for (const entry of root.moduleRegistry) {
            if (configured.indexOf(entry.id) < 0)
                result.push(entry);
        }
        return result;
    }

    function focusedScreen() {
        for (const candidate of Quickshell.screens) {
            const monitor = Hyprland.monitorFor(candidate);
            if (monitor && monitor.focused)
                return candidate;
        }
        return Quickshell.screens.length ? Quickshell.screens[0] : null;
    }
    function show() {
        closeTimer.stop();
        root.open = true;
        panelWindow.visible = true;
        Qt.callLater(function() { root.innerShown = true; });
    }
    function hide() {
        root.open = false;
        root.innerShown = false;
        closeTimer.restart();
    }
    function toggle() { root.open ? root.hide() : root.show(); }
    function command(arguments) {
        if (managerProcess.running)
            return;
        root.statusMessage = "Applying…";
        managerProcess.exec(["/home/cynric/.local/bin/hypr-rice-waybar-manager"].concat(arguments));
    }
    function trayHidden(id) {
        return (root.menu.trayHidden || []).indexOf(id) >= 0;
    }

    Timer { id: closeTimer; interval: Theme.motionMs; onTriggered: panelWindow.visible = false }

    Process {
        id: managerProcess
        stdout: SplitParser { onRead: data => {} }
        stderr: SplitParser { onRead: data => root.statusMessage = data.trim() }
        onExited: exitCode => root.statusMessage = exitCode === 0 ? "Applied · validated · Waybar restarted" : "Change rolled back"
    }

    PanelWindow {
        id: panelWindow
        visible: false
        screen: root.focusedScreen()
        anchors.top: true
        anchors.right: true
        margins.top: 38
        margins.right: 10
        implicitWidth: 410
        implicitHeight: Math.min(820, content.implicitHeight + 32)
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        color: "transparent"

        PanelSurface {
            anchors.fill: parent
            anchors.rightMargin: root.innerShown ? 0 : -22
            opacity: root.innerShown ? 1 : 0

            Behavior on anchors.rightMargin { NumberAnimation { duration: Theme.motionMs; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: Theme.motionMs; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: content
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                PanelHeader {
                    Layout.fillWidth: true
                    title: "Menu Bar Manager"
                    subtitle: "Visible modules, order, density, and tray policy"
                    onCloseRequested: root.hide()
                }

                ScrollView {
                    id: managerScroll
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(managerColumn.implicitHeight, 700)
                    contentWidth: availableWidth
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        id: managerColumn
                        width: managerScroll.availableWidth
                        spacing: 10

                        SectionLabel { text: "DENSITY" }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Repeater {
                                model: ["compact", "normal", "relaxed"]
                                PanelButton {
                                    required property string modelData
                                    Layout.fillWidth: true
                                    text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                    selected: root.menu.density === modelData
                                    enabled: !managerProcess.running
                                    onClicked: root.command(["density", modelData])
                                }
                            }
                        }

                        SectionLabel { text: "LEFT-SIDE MODULES" }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 50
                            radius: 11
                            color: Theme.surfaceLow
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8
                                Text { text: "󰖲"; color: Theme.foregroundVariant; font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 15 }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Text { text: "Active application"; color: Theme.foreground; font.pixelSize: 11; font.weight: Font.DemiBold }
                                    Text { text: "Launcher and workspaces stay pinned"; color: Theme.foregroundVariant; font.pixelSize: 8 }
                                }
                                Switch {
                                    checked: !!root.modules.activeApp
                                    enabled: !managerProcess.running
                                    onToggled: root.command(["module", "activeApp", checked ? "on" : "off"])
                                }
                            }
                        }

                        SectionLabel { text: "RIGHT-SIDE MODULES" }

                        Repeater {
                            model: root.orderedModules
                            Rectangle {
                                id: moduleRow
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                implicitHeight: 50
                                radius: 11
                                color: Theme.surfaceLow

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 7
                                    Text {
                                        text: moduleRow.modelData.icon
                                        color: Theme.foregroundVariant
                                        font.family: "JetBrainsMono Nerd Font Propo"
                                        font.pixelSize: 15
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: moduleRow.modelData.label + (moduleRow.modelData.locked ? " · required" : "")
                                        color: Theme.foreground
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                    PanelButton {
                                        text: "↑"
                                        implicitWidth: 30
                                        enabled: !managerProcess.running && moduleRow.index > 0
                                        onClicked: root.command(["move", moduleRow.modelData.id, "up"])
                                    }
                                    PanelButton {
                                        text: "↓"
                                        implicitWidth: 30
                                        enabled: !managerProcess.running && moduleRow.index < root.orderedModules.length - 1
                                        onClicked: root.command(["move", moduleRow.modelData.id, "down"])
                                    }
                                    Switch {
                                        checked: moduleRow.modelData.locked || !!root.modules[moduleRow.modelData.id]
                                        enabled: !moduleRow.modelData.locked && !managerProcess.running
                                        onToggled: root.command(["module", moduleRow.modelData.id, checked ? "on" : "off"])
                                    }
                                }
                            }
                        }

                        SectionLabel { text: "TRAY APPLICATIONS" }

                        Text {
                            visible: root.trayItems.length === 0
                            Layout.fillWidth: true
                            text: "No StatusNotifier applications are registered."
                            color: Theme.foregroundVariant
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                        }

                        Repeater {
                            model: root.trayItems
                            Rectangle {
                                id: trayRow
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 48
                                radius: 11
                                color: Theme.surfaceLow
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 9
                                    spacing: 9
                                    IconImage {
                                        implicitSize: 20
                                        width: 20
                                        height: 20
                                        source: trayRow.modelData.icon
                                        asynchronous: true
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Text {
                                            Layout.fillWidth: true
                                            text: trayRow.modelData.tooltipTitle || trayRow.modelData.title || trayRow.modelData.id
                                            color: Theme.foreground
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: trayRow.modelData.id
                                            color: Theme.foregroundVariant
                                            font.pixelSize: 8
                                            elide: Text.ElideMiddle
                                        }
                                    }
                                    PanelButton {
                                        text: root.trayHidden(trayRow.modelData.id) ? "Show" : "Hide"
                                        enabled: !managerProcess.running
                                        onClicked: root.command(["tray", trayRow.modelData.id, root.trayHidden(trayRow.modelData.id) ? "show" : "hide"])
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.statusMessage
                    color: root.statusMessage.indexOf("rolled back") >= 0 ? Theme.error : Theme.foregroundVariant
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }
            }
        }

        Shortcut { sequence: "Escape"; enabled: root.open; onActivated: root.hide() }
    }
}
