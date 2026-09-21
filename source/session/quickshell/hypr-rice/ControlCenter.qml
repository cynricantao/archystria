import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

Scope {
    id: root

    property bool open: false
    property bool innerShown: false
    property string activeSection: "home"
    property bool backendRunning: false
    property bool pavucontrolAvailable: false
    property string backendError: "Backend unavailable"
    property var backendData: ({})
    readonly property var networkData: root.backendData.network || ({})
    readonly property var localSendData: root.backendData.localsend || ({})
    readonly property var bluetoothData: root.backendData.bluetooth || ({})
    readonly property var weatherData: root.backendData.weather || ({})
    readonly property var weatherCurrent: root.weatherData.current || ({})
    readonly property var weatherLocation: root.weatherData.location || ({})
    readonly property var brightnessData: root.backendData.brightness || ({})
    readonly property var settingsData: root.backendData.settings || ({})
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property int outputPercent: root.sink && root.sink.audio ? Math.round(root.sink.audio.volume * 100) : 0
    readonly property string networkSummary: root.networkData.connected ? (root.networkData.connection || "Ethernet") : "Offline"
    readonly property string localSendSummary: root.localSendData.ready ? "Ready" : (root.localSendData.process_running ? "Starting" : "On demand")
    readonly property var mediaPlayers: Mpris.players.values.filter(player =>
        (player.identity || "").toLowerCase() !== "playerctld"
        && player.playbackState !== MprisPlaybackState.Stopped)
    readonly property alias window: panelWindow

    signal performanceRequested
    signal menuBarRequested

    function focusedScreen(): var {
        for (const candidate of Quickshell.screens) {
            const monitor = Hyprland.monitorFor(candidate);
            if (monitor && monitor.focused)
                return candidate;
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function validSection(section: string): string {
        const normalized = (section || "").toLowerCase();
        return ["home", "volume", "network", "bluetooth", "weather", "localsend"].indexOf(normalized) >= 0 ? normalized : "home";
    }

    function show(section: string): void {
        root.activeSection = root.validSection(section);
        closeTimer.stop();
        root.open = true;
        panelWindow.visible = true;
        Qt.callLater(function() {
            root.innerShown = true;
        });
    }

    function hide(): void {
        root.open = false;
        root.innerShown = false;
        closeTimer.restart();
    }

    function toggle(): void {
        if (root.open)
            root.hide();
        else
            root.show(root.activeSection);
    }

    function consumeBackendLine(line: string): void {
        const trimmed = line.trim();
        if (!trimmed)
            return;
        try {
            const update = JSON.parse(trimmed);
            root.backendData = Object.assign({}, root.backendData, update);
            root.backendRunning = true;
            root.backendError = "";
        } catch (error) {
            root.backendError = "Backend returned invalid JSON";
        }
    }

    function backendAction(arguments: var): void {
        actionProcess.exec(["__USER_HOME__/.local/bin/hypr-rice-panel-data"].concat(arguments));
    }

    function setDefaultAudio(node: var): void {
        if (node)
            audioProcess.exec(["/usr/bin/wpctl", "set-default", String(node.id)]);
    }

    function commitAudioVolume(node: var, value: real): void {
        if (node)
            audioProcess.exec(["/usr/bin/wpctl", "set-volume", String(node.id), Math.max(0, Math.min(1.5, value)).toFixed(3)]);
    }

    function toggleAudioMute(node: var): void {
        if (node)
            audioProcess.exec(["/usr/bin/wpctl", "set-mute", String(node.id), "toggle"]);
    }


    Timer {
        id: closeTimer
        interval: Theme.motionMs
        onTriggered: panelWindow.visible = false
    }

    Process {
        id: backendStream
        running: true
        command: ["__USER_HOME__/.local/bin/hypr-rice-panel-data", "stream"]
        stdout: SplitParser {
            onRead: data => root.consumeBackendLine(data)
        }
        onStarted: {
            root.backendRunning = true;
            root.backendError = "";
        }
        onExited: (exitCode, exitStatus) => {
            root.backendRunning = false;
            root.backendError = "Backend unavailable (exit " + exitCode + ")";
        }
    }

    Process {
        id: actionProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.backendError = "Backend action failed (exit " + exitCode + ")";
        }
    }

    Process {
        id: audioProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.backendError = "Audio action failed (exit " + exitCode + ")";
        }
    }

    Process {
        running: true
        command: ["/usr/bin/test", "-x", "__USER_HOME__/.local/bin/hypr-rice-pavucontrol"]
        onExited: (exitCode, exitStatus) => root.pavucontrolAvailable = exitCode === 0
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    PanelWindow {
        id: panelWindow
        visible: false
        screen: root.focusedScreen()
        anchors.top: true
        anchors.right: true
        margins.top: 38
        margins.right: 10
        implicitWidth: 430
        implicitHeight: Math.min(820, panelContent.implicitHeight + 32)
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        color: "transparent"

        PanelSurface {
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
                id: panelContent
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                PanelHeader {
                    Layout.fillWidth: true
                    title: root.activeSection === "home" ? "Control Center"
                        : root.activeSection === "volume" ? "Sound"
                        : root.activeSection === "network" ? "Network"
                        : root.activeSection === "bluetooth" ? "Bluetooth"
                        : root.activeSection === "weather" ? "Weather"
                        : "LocalSend"
                    subtitle: root.activeSection === "home" ? "Quick settings and media" : ""
                    showBack: root.activeSection !== "home"
                    onBackRequested: root.activeSection = "home"
                    onCloseRequested: root.hide()
                }

                ScrollView {
                    id: controlScroll
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(controlContent.implicitHeight, 650)
                    contentWidth: availableWidth
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        id: controlContent
                        width: controlScroll.availableWidth
                        spacing: 12

                        ColumnLayout {
                            visible: root.activeSection === "home"
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 82
                                radius: Theme.cardRadius
                                color: Theme.surfaceLow

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 12
                                    Text {
                                        text: "󰖐"
                                        color: Theme.tertiary
                                        font.family: "JetBrainsMono Nerd Font Propo"
                                        font.pixelSize: 28
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            Layout.fillWidth: true
                                            text: root.weatherLocation.name
                                                || (root.settingsData.weather ? (root.settingsData.weather.name || root.settingsData.weather.city || root.settingsData.weather.location) : "")
                                                || "Set weather location"
                                            color: Theme.foreground
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: root.weatherCurrent.description || (root.weatherData.error ? root.weatherData.error : "Updating weather…")
                                            color: root.weatherData.error ? Theme.error : Theme.foregroundVariant
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                        }
                                    }
                                    Text {
                                        text: root.weatherCurrent.temperature_c !== undefined ? Math.round(root.weatherCurrent.temperature_c) + "°" : "…"
                                        color: Theme.foreground
                                        font.pixelSize: 28
                                        font.weight: Font.Light
                                    }
                                    Text {
                                        text: "›"
                                        color: Theme.foregroundVariant
                                        font.pixelSize: 20
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activeSection = "weather"
                                }
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                columnSpacing: 8
                                rowSpacing: 8

                                QuickTile {
                                    Layout.fillWidth: true
                                    icon: root.networkData.connected ? "󰈀" : "󰈂"
                                    title: "Network"
                                    state: root.networkSummary
                                    active: !!root.networkData.connected
                                    detailsAvailable: true
                                    onClicked: root.performanceRequested()
                                    onDetailsClicked: root.activeSection = "network"
                                }
                                QuickTile {
                                    Layout.fillWidth: true
                                    visible: root.bluetoothData.available !== false
                                    icon: "󰂯"
                                    title: "Bluetooth"
                                    state: root.bluetoothData.powered
                                        ? (root.bluetoothData.connected_count ? root.bluetoothData.connected_count + " connected" : "On")
                                        : (root.bluetoothData.available === undefined ? "Checking…" : "Off")
                                    active: !!root.bluetoothData.powered
                                    detailsAvailable: true
                                    onClicked: root.backendAction(["bluetooth", "power", root.bluetoothData.powered ? "off" : "on"])
                                    onDetailsClicked: root.activeSection = "bluetooth"
                                }
                                QuickTile {
                                    Layout.fillWidth: true
                                    icon: root.settingsData.dnd ? "󰂛" : "󰂚"
                                    title: "Do Not Disturb"
                                    state: root.settingsData.dnd ? "On · notifications saved" : "Off"
                                    active: !!root.settingsData.dnd
                                    onClicked: root.backendAction(["dnd", root.settingsData.dnd ? "off" : "on"])
                                }
                                QuickTile {
                                    Layout.fillWidth: true
                                    icon: "󰒍"
                                    title: "LocalSend"
                                    state: root.localSendSummary
                                    active: !!root.localSendData.ready
                                    detailsAvailable: true
                                    onClicked: root.backendAction(["localsend", "open"])
                                    onDetailsClicked: root.activeSection = "localsend"
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 74
                                radius: Theme.cardRadius
                                color: Theme.surfaceLow

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 4
                                    ShellSlider {
                                        Layout.fillWidth: true
                                        icon: root.sink && root.sink.audio && root.sink.audio.muted ? "󰝟" : "󰕾"
                                        label: root.sink ? (root.sink.description || root.sink.nickname || "Volume") : "No audio output"
                                        detail: root.outputPercent + "%"
                                        from: 0
                                        to: 1.0
                                        value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
                                        controlEnabled: !!(root.sink && root.sink.audio)
                                        muted: !!(root.sink && root.sink.audio && root.sink.audio.muted)
                                        onMoved: nextValue => {
                                            if (root.sink && root.sink.audio)
                                                root.sink.audio.volume = nextValue;
                                        }
                                        onCommitted: nextValue => root.commitAudioVolume(root.sink, nextValue)
                                        onIconClicked: root.toggleAudioMute(root.sink)
                                    }
                                    PanelButton {
                                        text: "›"
                                        implicitWidth: 30
                                        onClicked: root.activeSection = "volume"
                                    }
                                }
                            }

                            Rectangle {
                                visible: !!root.brightnessData.available
                                Layout.fillWidth: true
                                implicitHeight: visible ? 74 : 0
                                radius: Theme.cardRadius
                                color: Theme.surfaceLow
                                ShellSlider {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    icon: "󰃟"
                                    label: "Brightness"
                                    detail: Math.round((root.brightnessData.percent || 0)) + "%"
                                    from: 0
                                    to: 100
                                    value: root.brightnessData.percent || 0
                                    onCommitted: nextValue => root.backendAction(["brightness", "set", String(Math.round(nextValue))])
                                }
                            }

                            MediaCard {
                                Layout.fillWidth: true
                                visible: root.mediaPlayers.length > 0
                                implicitHeight: visible ? 132 : 0
                                player: root.mediaPlayers.length > 0 ? root.mediaPlayers[0] : null
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                PanelButton {
                                    text: "󰌾  Lock"
                                    Layout.fillWidth: true
                                    onClicked: Quickshell.execDetached(["__USER_HOME__/.config/hypr/scripts/session-action", "lock"])
                                }
                                PanelButton {
                                    text: "󰒓  Menu Bar"
                                    Layout.fillWidth: true
                                    onClicked: root.menuBarRequested()
                                }
                                PanelButton {
                                    text: "󰐥  Power"
                                    Layout.fillWidth: true
                                    onClicked: Quickshell.execDetached(["__USER_HOME__/.local/bin/hypr-rice-power-menu"])
                                }
                            }
                        }

                        ColumnLayout {
                            visible: root.activeSection === "volume"
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "OUTPUT"
                                color: Theme.muted
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 86
                                radius: 12
                                color: Theme.panel
                                border.color: Theme.border

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    readonly property var sink: Pipewire.defaultAudioSink
                                    Text {
                                        Layout.fillWidth: true
                                        text: parent.sink ? (parent.sink.description || parent.sink.nickname || parent.sink.name) : "No output device"
                                        color: Theme.text
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        PanelButton {
                                            text: parent.parent.sink && parent.parent.sink.audio && parent.parent.sink.audio.muted ? "Unmute" : "Mute"
                                            enabled: parent.parent.sink && parent.parent.sink.audio
                                            implicitWidth: 68
                                            onClicked: root.toggleAudioMute(parent.parent.sink)
                                        }
                                        Slider {
                                            Layout.fillWidth: true
                                            from: 0
                                            to: 1.5
                                            enabled: parent.parent.sink && parent.parent.sink.audio
                                            value: enabled ? parent.parent.sink.audio.volume : 0
                                            onMoved: parent.parent.sink.audio.volume = value
                                            onPressedChanged: {
                                                if (!pressed && enabled)
                                                    root.commitAudioVolume(parent.parent.sink, value);
                                            }
                                        }
                                        Text {
                                            text: parent.parent.sink && parent.parent.sink.audio ? Math.round(parent.parent.sink.audio.volume * 100) + "%" : "—"
                                            color: Theme.muted
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                            }

                            Text {
                                text: "OUTPUT DEVICES"
                                color: Theme.muted
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Repeater {
                                    model: Pipewire.nodes
                                    Item {
                                        id: sinkDelegate
                                        required property var modelData
                                        Layout.fillWidth: true
                                        implicitHeight: visible ? 38 : 0
                                        visible: modelData && modelData.audio && modelData.isSink && !modelData.isStream

                                        PwObjectTracker { objects: [sinkDelegate.modelData] }
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 9
                                            color: sinkMouse.containsMouse ? Theme.panelHigh : Theme.panel
                                            border.color: Pipewire.defaultAudioSink === sinkDelegate.modelData ? Theme.accent : Theme.border
                                            Text {
                                                anchors.fill: parent
                                                anchors.margins: 10
                                                verticalAlignment: Text.AlignVCenter
                                                text: sinkDelegate.modelData.description || sinkDelegate.modelData.nickname || sinkDelegate.modelData.name
                                                color: Theme.text
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                            }
                                            MouseArea {
                                                id: sinkMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.setDefaultAudio(sinkDelegate.modelData)
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                text: "INPUT DEVICES"
                                color: Theme.muted
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 86
                                radius: 12
                                color: Theme.panel
                                border.color: Theme.border

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    Text {
                                        Layout.fillWidth: true
                                        text: root.source ? (root.source.description || root.source.nickname || root.source.name) : "No input device"
                                        color: Theme.text
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        PanelButton {
                                            text: root.source && root.source.audio && root.source.audio.muted ? "Unmute" : "Mute"
                                            enabled: root.source && root.source.audio
                                            implicitWidth: 68
                                            onClicked: root.toggleAudioMute(root.source)
                                        }
                                        Slider {
                                            Layout.fillWidth: true
                                            from: 0
                                            to: 1.5
                                            enabled: root.source && root.source.audio
                                            value: enabled ? root.source.audio.volume : 0
                                            onMoved: root.source.audio.volume = value
                                            onPressedChanged: {
                                                if (!pressed && enabled)
                                                    root.commitAudioVolume(root.source, value);
                                            }
                                        }
                                        Text {
                                            text: root.source && root.source.audio ? Math.round(root.source.audio.volume * 100) + "%" : "—"
                                            color: Theme.muted
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Repeater {
                                    model: Pipewire.nodes
                                    Item {
                                        id: sourceDelegate
                                        required property var modelData
                                        Layout.fillWidth: true
                                        implicitHeight: visible ? 38 : 0
                                        visible: modelData && modelData.audio && !modelData.isSink && !modelData.isStream

                                        PwObjectTracker { objects: [sourceDelegate.modelData] }
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 9
                                            color: sourceMouse.containsMouse ? Theme.panelHigh : Theme.panel
                                            border.color: Pipewire.defaultAudioSource === sourceDelegate.modelData ? Theme.accent : Theme.border
                                            Text {
                                                anchors.fill: parent
                                                anchors.margins: 10
                                                verticalAlignment: Text.AlignVCenter
                                                text: sourceDelegate.modelData.description || sourceDelegate.modelData.nickname || sourceDelegate.modelData.name
                                                color: Theme.text
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                            }
                                            MouseArea {
                                                id: sourceMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.setDefaultAudio(sourceDelegate.modelData)
                                            }
                                        }
                                    }
                                }
                            }

                            PanelButton {
                                text: "More Options"
                                enabled: root.pavucontrolAvailable
                                onClicked: Quickshell.execDetached(["__USER_HOME__/.local/bin/hypr-rice-pavucontrol"])
                            }
                        }

                        ColumnLayout {
                            visible: root.activeSection === "network"
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "ETHERNET"
                                color: Theme.muted
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: networkDetails.implicitHeight + 24
                                radius: 12
                                color: Theme.panel
                                border.color: root.networkData.connected ? Theme.accent : Theme.border

                                Text {
                                    id: networkDetails
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 12
                                    text: root.networkData.error
                                        ? root.networkData.error
                                        : ("Connection  " + (root.networkData.connection || "None")
                                           + "\nInterface      " + (root.networkData.interface || "—")
                                           + "\nIPv4             " + (root.networkData.ipv4 || "—")
                                           + (root.networkData.ipv6 ? "\nIPv6             " + root.networkData.ipv6 : "")
                                           + (root.networkData.gateway ? "\nGateway       " + root.networkData.gateway : "")
                                           + (root.networkData.dns && root.networkData.dns.length ? "\nDNS              " + root.networkData.dns.join(", ") : ""))
                                    color: root.networkData.error ? Theme.error : Theme.text
                                    font.pixelSize: 12
                                    lineHeight: 1.35
                                    wrapMode: Text.WrapAnywhere
                                }
                            }

                            Text {
                                text: "VPN"
                                color: Theme.muted
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            Text {
                                visible: !root.networkData.vpns || root.networkData.vpns.length === 0
                                text: "No VPN connections configured"
                                color: Theme.muted
                                font.pixelSize: 12
                            }

                            Repeater {
                                model: root.networkData.vpns || []
                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 48
                                    radius: 10
                                    color: Theme.panel
                                    border.color: modelData.active ? Theme.accent : Theme.border
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 9
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text { text: modelData.name; color: Theme.text; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                                            Text { text: modelData.active ? "Connected" : "Disconnected"; color: Theme.muted; font.pixelSize: 10 }
                                        }
                                        PanelButton {
                                            text: modelData.active ? "Disconnect" : "Connect"
                                            implicitWidth: 90
                                            onClicked: root.backendAction(["vpn", modelData.active ? "down" : "up", modelData.name])
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            visible: root.activeSection === "bluetooth"
                            Layout.fillWidth: true
                            spacing: 10

                            SectionLabel { text: "ADAPTER" }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: bluetoothDetails.implicitHeight + 24
                                radius: 12
                                color: Theme.panel
                                border.color: root.bluetoothData.powered ? Theme.accent : Theme.border
                                Text {
                                    id: bluetoothDetails
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 12
                                    text: root.bluetoothData.error
                                        ? root.bluetoothData.error
                                        : ("State       " + (root.bluetoothData.powered ? "On" : "Off")
                                           + "\nAdapter   " + (root.bluetoothData.controller ? (root.bluetoothData.controller.name || root.bluetoothData.controller.address || "Available") : "Available")
                                           + "\nDevices    " + (root.bluetoothData.connected_count || 0) + " connected")
                                    color: root.bluetoothData.error ? Theme.error : Theme.text
                                    font.pixelSize: 12
                                    lineHeight: 1.35
                                    wrapMode: Text.WrapAnywhere
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                PanelButton {
                                    Layout.fillWidth: true
                                    text: root.bluetoothData.powered ? "Turn Off" : "Turn On"
                                    enabled: root.bluetoothData.available !== false && root.backendRunning
                                    onClicked: root.backendAction(["bluetooth", "power", root.bluetoothData.powered ? "off" : "on"])
                                }
                                PanelButton {
                                    Layout.fillWidth: true
                                    text: root.bluetoothData.discovering ? "Scanning…" : "Scan"
                                    enabled: !!root.bluetoothData.powered && root.backendRunning
                                    onClicked: root.backendAction(["bluetooth", "scan", "start"])
                                }
                            }

                            SectionLabel { text: "PAIRED & DISCOVERED DEVICES" }
                            Text {
                                visible: !root.bluetoothData.devices || root.bluetoothData.devices.length === 0
                                text: root.bluetoothData.powered ? "No devices found" : "Turn Bluetooth on to view devices"
                                color: Theme.muted
                                font.pixelSize: 11
                            }
                            Repeater {
                                model: root.bluetoothData.devices || []
                                Rectangle {
                                    id: bluetoothDevice
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 48
                                    radius: 10
                                    color: Theme.panel
                                    border.color: bluetoothDevice.modelData.connected ? Theme.accent : Theme.border
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 9
                                        spacing: 8
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text { Layout.fillWidth: true; text: bluetoothDevice.modelData.name || bluetoothDevice.modelData.address; color: Theme.text; font.pixelSize: 12; elide: Text.ElideRight }
                                            Text { text: bluetoothDevice.modelData.connected ? "Connected" : (bluetoothDevice.modelData.paired ? "Paired" : "Available"); color: Theme.muted; font.pixelSize: 9 }
                                        }
                                        PanelButton {
                                            visible: bluetoothDevice.modelData.paired || bluetoothDevice.modelData.connected
                                            text: bluetoothDevice.modelData.connected ? "Disconnect" : "Connect"
                                            implicitWidth: 90
                                            onClicked: root.backendAction(["bluetooth", bluetoothDevice.modelData.connected ? "disconnect" : "connect", bluetoothDevice.modelData.address])
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            visible: root.activeSection === "weather"
                            Layout.fillWidth: true
                            spacing: 10

                            SectionLabel { text: "CURRENT CONDITIONS" }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: weatherDetails.implicitHeight + 24
                                radius: 12
                                color: Theme.panel
                                border.color: root.weatherData.available ? Theme.accent : Theme.border
                                Text {
                                    id: weatherDetails
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 12
                                    text: root.weatherData.error && !root.weatherData.available
                                        ? root.weatherData.error
                                        : ((root.weatherLocation.name || root.weatherLocation.country || "Configured location")
                                           + "\n" + (root.weatherCurrent.description || "Weather unavailable")
                                           + (root.weatherCurrent.temperature_c !== undefined ? "\nTemperature   " + Math.round(root.weatherCurrent.temperature_c) + "°C" : "")
                                           + (root.weatherCurrent.feels_like_c !== undefined ? "\nFeels like       " + Math.round(root.weatherCurrent.feels_like_c) + "°C" : "")
                                           + (root.weatherCurrent.humidity_percent !== undefined ? "\nHumidity       " + root.weatherCurrent.humidity_percent + "%" : "")
                                           + (root.weatherCurrent.wind_kph !== undefined ? "\nWind              " + root.weatherCurrent.wind_kph + " km/h" : "")
                                           + (root.weatherData.stale ? "\nCached weather · refresh pending" : ""))
                                    color: root.weatherData.error && !root.weatherData.available ? Theme.error : Theme.text
                                    font.pixelSize: 12
                                    lineHeight: 1.35
                                    wrapMode: Text.WrapAnywhere
                                }
                            }

                            SectionLabel { text: "LOCATION" }
                            RowLayout {
                                Layout.fillWidth: true
                                TextField {
                                    id: weatherLocationField
                                    Layout.fillWidth: true
                                    placeholderText: "City or place"
                                    text: root.settingsData.weather
                                        ? (root.settingsData.weather.name || root.settingsData.weather.city || root.settingsData.weather.location || "")
                                        : ""
                                }
                                PanelButton {
                                    text: "Save"
                                    enabled: weatherLocationField.text.trim().length > 0 && root.backendRunning
                                    onClicked: root.backendAction(["weather", "location", weatherLocationField.text.trim()])
                                }
                            }
                        }

                        ColumnLayout {
                            visible: root.activeSection === "localsend"
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "LOCALSEND"
                                color: Theme.muted
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: localSendDetails.implicitHeight + 24
                                radius: 12
                                color: Theme.panel
                                border.color: root.localSendData.ready ? Theme.accent : Theme.border
                                Text {
                                    id: localSendDetails
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 12
                                    text: root.localSendData.error
                                        ? root.localSendData.error
                                        : ("Device    " + (root.localSendData.alias || "Not configured")
                                           + "\nAddress   " + (root.localSendData.ip || "No active route")
                                           + "\nStatus      " + (root.localSendData.ready ? "Ready to transfer" : (root.localSendData.process_running ? "Starting" : "Launches on demand")))
                                    color: root.localSendData.error ? Theme.error : Theme.text
                                    font.pixelSize: 12
                                    lineHeight: 1.35
                                    wrapMode: Text.WrapAnywhere
                                }
                            }

                            Text {
                                text: "Starts only when requested. Peer and transfer history is unavailable."
                                color: Theme.muted
                                font.pixelSize: 11
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }

                            PanelButton {
                                text: root.localSendData.process_running ? "Open LocalSend" : "Start LocalSend"
                                enabled: root.backendRunning
                                onClicked: root.backendAction(["localsend", "open"])
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 0
                            visible: false

                            ColumnLayout {
                                id: mediaColumn
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8
                                Text {
                                    text: "MEDIA"
                                    color: Theme.muted
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                                Repeater {
                                    model: root.mediaPlayers
                                    RowLayout {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.trackTitle || modelData.identity
                                                color: Theme.text
                                                font.pixelSize: 13
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.trackArtist || modelData.identity
                                                color: Theme.muted
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                            }
                                        }
                                        PanelButton {
                                            text: "‹"
                                            implicitWidth: 30
                                            enabled: modelData.canGoPrevious
                                            onClicked: modelData.previous()
                                        }
                                        PanelButton {
                                            text: modelData.isPlaying ? "Pause" : "Play"
                                            implicitWidth: 52
                                            enabled: modelData.canTogglePlaying
                                            onClicked: modelData.togglePlaying()
                                        }
                                        PanelButton {
                                            text: "›"
                                            implicitWidth: 30
                                            enabled: modelData.canGoNext
                                            onClicked: modelData.next()
                                        }
                                    }
                                }
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
