import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property var player: null
    property real livePosition: player ? player.position : 0

    implicitHeight: 132
    radius: Theme.cardRadius
    color: Theme.surfaceLow
    clip: true

    function formatSeconds(seconds) {
        const value = Math.max(0, Math.floor(Number(seconds) || 0));
        const minutes = Math.floor(value / 60);
        return minutes + ":" + String(value % 60).padStart(2, "0");
    }

    Timer {
        interval: 1000
        running: root.visible && root.player && root.player.isPlaying && !progress.pressed
        repeat: true
        onTriggered: root.livePosition = root.player.position
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 88
            Layout.preferredHeight: 88
            radius: 12
            color: Theme.surfaceHigh
            clip: true

            Image {
                id: artwork
                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: !artwork.visible
                text: "󰎆"
                color: Theme.foregroundVariant
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 28
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: root.player ? (root.player.trackTitle || root.player.identity || "Unknown title") : "Nothing playing"
                color: Theme.foreground
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.player ? (root.player.trackArtist || root.player.identity || "") : ""
                color: Theme.foregroundVariant
                font.pixelSize: 10
                elide: Text.ElideRight
            }

            Slider {
                id: progress
                Layout.fillWidth: true
                implicitHeight: 16
                from: 0
                to: root.player && root.player.lengthSupported ? Math.max(1, root.player.length) : 1
                value: Math.min(to, root.livePosition)
                enabled: root.player && root.player.canSeek && root.player.lengthSupported
                onMoved: root.livePosition = value
                onPressedChanged: {
                    if (!pressed && enabled) {
                        root.player.position = value;
                        root.livePosition = value;
                    }
                }
                background: Rectangle {
                    x: progress.leftPadding
                    y: progress.topPadding + progress.availableHeight / 2 - height / 2
                    width: progress.availableWidth
                    height: 3
                    radius: 2
                    color: Theme.surfaceBright
                    Rectangle {
                        width: progress.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: Theme.primary
                    }
                }
                handle: Rectangle {
                    visible: progress.enabled
                    x: progress.leftPadding + progress.visualPosition * (progress.availableWidth - width)
                    y: progress.topPadding + progress.availableHeight / 2 - height / 2
                    implicitWidth: 10
                    implicitHeight: 10
                    radius: 5
                    color: Theme.primary
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 5
                Text {
                    Layout.fillWidth: true
                    text: root.formatSeconds(root.livePosition)
                    color: Theme.foregroundVariant
                    font.pixelSize: 9
                }
                PanelButton {
                    text: "‹"
                    implicitWidth: 30
                    implicitHeight: 30
                    enabled: root.player && root.player.canGoPrevious
                    onClicked: root.player.previous()
                }
                PanelButton {
                    text: root.player && root.player.isPlaying ? "Ⅱ" : "▶"
                    implicitWidth: 34
                    implicitHeight: 30
                    enabled: root.player && root.player.canTogglePlaying
                    selected: root.player && root.player.isPlaying
                    onClicked: root.player.togglePlaying()
                }
                PanelButton {
                    text: "›"
                    implicitWidth: 30
                    implicitHeight: 30
                    enabled: root.player && root.player.canGoNext
                    onClicked: root.player.next()
                }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: root.player && root.player.lengthSupported ? root.formatSeconds(root.player.length) : ""
                    color: Theme.foregroundVariant
                    font.pixelSize: 9
                }
            }
        }
    }
}
