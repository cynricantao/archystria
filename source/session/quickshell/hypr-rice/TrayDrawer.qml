import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Scope {
    id: root

    property bool open: false
    property bool innerShown: false
    property bool revealHidden: false
    property var hiddenIds: []
    readonly property var items: SystemTray.items.values
    readonly property alias window: panelWindow
    signal manageRequested

    function isHidden(item) {
        return root.hiddenIds.indexOf(item.id) >= 0;
    }

    function filtered(hidden) {
        const result = [];
        for (const item of root.items) {
            if (item.status === Status.Passive)
                continue;
            if (root.isHidden(item) === hidden)
                result.push(item);
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

    Timer { id: closeTimer; interval: Theme.motionMs; onTriggered: panelWindow.visible = false }

    PanelWindow {
        id: panelWindow
        visible: false
        screen: root.focusedScreen()
        anchors.top: true
        anchors.right: true
        margins.top: 38
        margins.right: 10
        implicitWidth: 330
        implicitHeight: Math.min(620, content.implicitHeight + 32)
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        color: "transparent"

        PanelSurface {
            id: surface
            anchors.fill: parent
            anchors.rightMargin: root.innerShown ? 0 : -20
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
                    title: "Tray"
                    subtitle: root.filtered(false).length + " visible · " + root.filtered(true).length + " hidden"
                    onCloseRequested: root.hide()
                }

                ScrollView {
                    id: trayScroll
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(trayColumn.implicitHeight, 500)
                    contentWidth: availableWidth
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        id: trayColumn
                        width: trayScroll.availableWidth
                        spacing: 6

                        Repeater {
                            model: root.filtered(false)
                            TrayItemRow {
                                required property var modelData
                                Layout.fillWidth: true
                                item: modelData
                                parentWindow: panelWindow
                            }
                        }

                        Text {
                            visible: root.filtered(false).length === 0
                            Layout.fillWidth: true
                            text: root.items.length === 0 ? "No tray applications are registered" : "All tray applications are hidden"
                            color: Theme.foregroundVariant
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            Layout.topMargin: 14
                            Layout.bottomMargin: 14
                        }

                        PanelButton {
                            visible: root.filtered(true).length > 0
                            Layout.fillWidth: true
                            text: root.revealHidden ? "Hide hidden items" : "Show " + root.filtered(true).length + " hidden"
                            onClicked: root.revealHidden = !root.revealHidden
                        }

                        Repeater {
                            model: root.revealHidden ? root.filtered(true) : []
                            TrayItemRow {
                                required property var modelData
                                Layout.fillWidth: true
                                item: modelData
                                parentWindow: panelWindow
                                dimmed: true
                            }
                        }
                    }
                }

                PanelButton {
                    Layout.fillWidth: true
                    text: "Manage Tray Applications"
                    onClicked: root.manageRequested()
                }
            }
        }

        Shortcut { sequence: "Escape"; enabled: root.open; onActivated: root.hide() }
    }
}
