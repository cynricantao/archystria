import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: root

    property bool open: false
    property bool innerShown: false
    property var data: ({})
    property var runAction: null
    property var cpuHistory: []
    property var ramHistory: []
    property var gpuHistory: []
    property var downloadHistory: []
    property var uploadHistory: []
    property bool btopAvailable: false
    readonly property alias window: panelWindow

    readonly property var systemData: root.data.system || ({})
    readonly property var cpuData: root.systemData.cpu || root.data.cpu || ({})
    readonly property var memoryData: root.systemData.memory || root.data.memory || ({})
    readonly property var gpuData: root.data.gpu || ((root.data.gpus && root.data.gpus.length) ? root.data.gpus[0] : ({}))
    readonly property var networkData: root.data.network || ({})
    readonly property var throughputData: root.networkData.throughput || ({})
    readonly property var speedData: root.data.speedtest || ({})
    readonly property var speedResult: root.speedData.result || ({})

    function metric(object, names, fallback) {
        if (!object)
            return fallback;
        for (const name of names) {
            if (object[name] !== undefined && object[name] !== null)
                return Number(object[name]);
        }
        return fallback;
    }

    function append(history, value, maximum) {
        const next = (history || []).slice();
        next.push(Math.max(0, Number(value) || 0));
        while (next.length > maximum)
            next.shift();
        return next;
    }

    function updateHistory() {
        root.cpuHistory = root.append(root.cpuHistory, root.metric(root.cpuData, ["percent", "usage", "usage_percent"], 0), 60);
        root.ramHistory = root.append(root.ramHistory, root.metric(root.memoryData, ["percent", "usage", "usage_percent"], 0), 60);
        root.gpuHistory = root.append(root.gpuHistory, root.metric(root.gpuData, ["utilization", "percent", "usage", "usage_percent"], 0), 60);
        root.downloadHistory = root.append(root.downloadHistory, root.metric(root.throughputData, ["rx_bytes_per_second"], 0) * 8 / 1000000, 60);
        root.uploadHistory = root.append(root.uploadHistory, root.metric(root.throughputData, ["tx_bytes_per_second"], 0) * 8 / 1000000, 60);
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

    function toggle() {
        root.open ? root.hide() : root.show();
    }

    onDataChanged: root.updateHistory()

    Timer {
        id: closeTimer
        interval: Theme.motionMs
        onTriggered: panelWindow.visible = false
    }

    Process {
        running: true
        command: ["/usr/bin/test", "-x", "/usr/bin/btop"]
        onExited: exitCode => root.btopAvailable = exitCode === 0
    }

    PanelWindow {
        id: panelWindow
        visible: false
        screen: root.focusedScreen()
        anchors.top: true
        anchors.right: true
        margins.top: 38
        margins.right: 10
        implicitWidth: 440
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
                spacing: 12

                PanelHeader {
                    Layout.fillWidth: true
                    title: "Performance & Network"
                    subtitle: (root.networkData.connection || "No active connection") + " · " + (root.networkData.interface || "—")
                    onCloseRequested: root.hide()
                }

                ScrollView {
                    id: perfScroll
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(metrics.implicitHeight, 730)
                    contentWidth: availableWidth
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        id: metrics
                        width: perfScroll.availableWidth
                        spacing: 10

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 8
                            rowSpacing: 8

                            MetricCard {
                                Layout.fillWidth: true
                                title: "CPU"
                                value: Math.round(root.metric(root.cpuData, ["percent", "usage", "usage_percent"], 0)) + "%"
                                detail: (root.cpuData.temperature_c !== undefined ? Math.round(root.cpuData.temperature_c) + "°C · " : "")
                                    + (root.cpuData.frequency_mhz ? Math.round(root.cpuData.frequency_mhz) + " MHz" : "Live usage")
                                history: root.cpuHistory
                                accent: Theme.primary
                            }
                            MetricCard {
                                Layout.fillWidth: true
                                title: "Memory"
                                value: Math.round(root.metric(root.memoryData, ["percent", "usage", "usage_percent"], 0)) + "%"
                                detail: root.memoryData.used_bytes !== undefined
                                    ? Number(root.memoryData.used_bytes / 1073741824).toFixed(1) + " / " + Number((root.memoryData.total_bytes || 0) / 1073741824).toFixed(1) + " GiB"
                                    : "Live usage"
                                history: root.ramHistory
                                accent: Theme.secondary
                            }
                            MetricCard {
                                Layout.fillWidth: true
                                visible: root.gpuData.available !== false && Object.keys(root.gpuData).length > 0
                                title: root.gpuData.name || "GPU"
                                value: Math.round(root.metric(root.gpuData, ["utilization", "percent", "usage", "usage_percent"], 0)) + "%"
                                detail: (root.gpuData.temperature_c !== undefined ? Math.round(root.gpuData.temperature_c) + "°C" : "")
                                    + (root.gpuData.memory_percent !== undefined ? " · VRAM " + Math.round(root.gpuData.memory_percent) + "%" : "")
                                history: root.gpuHistory
                                accent: Theme.tertiary
                            }
                            MetricCard {
                                Layout.fillWidth: true
                                Layout.columnSpan: (root.gpuData.available !== false && Object.keys(root.gpuData).length > 0) ? 1 : 2
                                title: "Load"
                                value: root.cpuData.load_average && root.cpuData.load_average.length ? Number(root.cpuData.load_average[0]).toFixed(2) : "—"
                                detail: root.cpuData.cores ? root.cpuData.cores + " logical CPUs" : "1 minute average"
                                history: root.cpuHistory
                                accent: Theme.outline
                            }
                        }

                        SectionLabel { text: "LIVE NETWORK" }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 104
                            radius: Theme.cardRadius
                            color: Theme.surfaceLow

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 7
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "↓"; color: Theme.primary; font.pixelSize: 18 }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text { text: "Download"; color: Theme.foregroundVariant; font.pixelSize: 10 }
                                        Text { text: (root.metric(root.throughputData, ["rx_bytes_per_second"], 0) * 8 / 1000000).toFixed(2) + " Mbps"; color: Theme.foreground; font.pixelSize: 16; font.weight: Font.DemiBold }
                                    }
                                    Text { text: "↑"; color: Theme.tertiary; font.pixelSize: 18 }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text { text: "Upload"; color: Theme.foregroundVariant; font.pixelSize: 10 }
                                        Text { text: (root.metric(root.throughputData, ["tx_bytes_per_second"], 0) * 8 / 1000000).toFixed(2) + " Mbps"; color: Theme.foreground; font.pixelSize: 16; font.weight: Font.DemiBold }
                                    }
                                }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 34
                                    Sparkline { anchors.fill: parent; values: root.downloadHistory; strokeColor: Theme.primary; maximum: Math.max(1, ...root.downloadHistory) }
                                    Sparkline { anchors.fill: parent; values: root.uploadHistory; strokeColor: Theme.tertiary; fillColor: "transparent"; maximum: Math.max(1, ...root.uploadHistory) }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: details.implicitHeight + 24
                            radius: Theme.cardRadius
                            color: Theme.surfaceLow
                            Text {
                                id: details
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 12
                                text: "Connection  " + (root.networkData.connection || "None")
                                    + "\nInterface      " + (root.networkData.interface || "—")
                                    + "\nIPv4             " + (root.networkData.ipv4 || "—")
                                    + (root.networkData.gateway ? "\nGateway       " + root.networkData.gateway : "")
                                    + (root.networkData.dns && root.networkData.dns.length ? "\nDNS              " + root.networkData.dns.join(", ") : "")
                                    + (root.networkData.link_speed_mbps ? "\nLink speed   " + root.networkData.link_speed_mbps + " Mbps" : "")
                                    + (root.networkData.connectivity ? "\nInternet       " + root.networkData.connectivity : "")
                                color: Theme.foreground
                                font.pixelSize: 11
                                lineHeight: 1.35
                                wrapMode: Text.WrapAnywhere
                            }
                        }

                        SectionLabel { text: "INTERNET SPEED TEST" }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 78
                            radius: Theme.cardRadius
                            color: Theme.surfaceLow
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: root.speedData.state === "running" ? "Testing connection…"
                                            : root.speedData.error ? root.speedData.error
                                            : root.speedResult.download_mbps !== undefined
                                                ? "↓ " + Number(root.speedResult.download_mbps).toFixed(1) + "  ↑ " + Number(root.speedResult.upload_mbps || 0).toFixed(1) + " Mbps · " + Number(root.speedResult.ping_ms || 0).toFixed(1) + " ms"
                                                : "Manual only · never scheduled"
                                        color: root.speedData.error ? Theme.error : Theme.foreground
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        text: root.speedResult.timestamp ? "Last tested " + root.speedResult.timestamp : "Uses speedtest-cli when requested"
                                        color: Theme.foregroundVariant
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                                BusyIndicator { running: root.speedData.state === "running"; visible: running; implicitWidth: 28; implicitHeight: 28 }
                                PanelButton {
                                    text: root.speedData.state === "running" ? "Running" : "Start Test"
                                    enabled: root.speedData.state !== "running" && !!root.runAction
                                    onClicked: root.runAction(["speedtest", "start"])
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            PanelButton {
                                visible: root.btopAvailable
                                text: "More Details"
                                onClicked: Quickshell.execDetached(["/usr/bin/ghostty", "-e", "/usr/bin/btop"])
                            }
                            Item { Layout.fillWidth: true }
                            Text { text: "60-second local history"; color: Theme.foregroundVariant; font.pixelSize: 9 }
                        }
                    }
                }
            }
        }

        Shortcut { sequence: "Escape"; enabled: root.open; onActivated: root.hide() }
    }
}
