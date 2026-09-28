pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Controls
import Quickshell

Item {
    id: root
    property string activeWidget: "music"
    property var player: null
    property int playerCount: 0
    property bool audioOnly: false
    property bool downloading: false
    property string status: "Paste a YouTube link to get started."
    property string downloadDirectory: ""
    property string droppedUrl: ""
    property int dropSerial: 0
    signal widgetSelected(string widget)
    signal nextPlayer()
    signal downloadRequested(string url, bool audioOnly, string quality, string format)
    signal audioModeRequested(bool audioOnly)
    signal closeRequested()
    signal expressionRequested(string mood)
    function react(mood) { root.expressionRequested(mood) }
    function startDownload() {
        root.downloadRequested(urlInput.text, root.audioOnly,
                               root.audioOnly ? "720p" : quality.currentText,
                               root.audioOnly ? musicFormat.currentText : videoFormat.currentText)
    }
    function formatTime(value) {
        var seconds = Math.max(0, Math.floor(Number(value) || 0));
        var minutes = Math.floor(seconds / 60);
        return minutes + ":" + (seconds % 60 < 10 ? "0" : "") + (seconds % 60);
    }
    onDropSerialChanged: if (dropSerial > 0) urlInput.text = droppedUrl

    Rectangle {
        width: 268; height: 64; radius: 16; color: "#202622"
        Rectangle {
            x: root.activeWidget === "music" ? 4 : 136
            y: 4; width: 128; height: 56; radius: 12; color: "#9ed6b4"
            Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        }
        Repeater {
            model: [{key: "music", label: "Music"}, {key: "youtube", label: "YouTube"}]
            Controls.Button {
                id: tab
                required property var modelData
                required property int index
                readonly property color tint: root.activeWidget === modelData.key ? "#17201c" : "#aebbb2"
                x: 4 + index * 132; y: 4; width: 128; height: 56
                onClicked: { root.widgetSelected(modelData.key); root.react("happy") }
                Accessible.name: modelData.label
                background: Item {}
                contentItem: Column {
                    spacing: 4
                    UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: tab.modelData.key; width: 22; height: 22; tint: tab.tint }
                    Text { width: parent.width; text: tab.modelData.label; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 12; font.weight: Font.DemiBold; color: tab.tint }
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }
    }

    Item {
        id: musicView
        x: 0; y: 78; width: parent.width; height: parent.height - y
        visible: root.activeWidget === "music"
        Rectangle {
            x: 0; y: 0; width: 112; height: 112; radius: 18; color: "#26382d"; clip: true
            UiIcon { anchors.centerIn: parent; width: 38; height: 38; tint: "#9ed6b4" }
            Image { anchors.fill: parent; source: root.player ? root.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop }
        }
        Column {
            x: 128; y: 8; width: parent.width - x; spacing: 7
            Text { text: root.player && root.player.isPlaying ? "NOW PLAYING" : "MUSIC PLAYER"; color: "#9ed6b4"; font.pixelSize: 10; font.letterSpacing: 1.3 }
            Text { width: parent.width; text: root.player && root.player.trackTitle ? root.player.trackTitle : "Nothing playing"; color: "#edf0ed"; font.pixelSize: 18; font.weight: Font.DemiBold; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap }
            Text { width: parent.width; text: root.player ? (root.player.trackArtist || root.player.identity) : "Start a song in your music app"; color: "#96a69c"; font.pixelSize: 12; elide: Text.ElideRight }
        }
        Controls.Slider {
            id: seekBar
            x: 0; y: 120; width: parent.width; height: 24
            from: 0; to: root.player && root.player.length > 0 ? root.player.length : 1
            value: root.player ? Math.min(to, root.player.position) : 0
            enabled: !!root.player && root.player.canSeek && root.player.length > 0
            onMoved: if (root.player) root.player.position = value
            background: Rectangle {
                x: seekBar.leftPadding; y: seekBar.topPadding + seekBar.availableHeight / 2 - 2
                width: seekBar.availableWidth; height: 4; radius: 2; color: "#35413a"
                Rectangle { width: seekBar.visualPosition * parent.width; height: parent.height; radius: 2; color: "#9ed6b4" }
            }
            handle: Rectangle { x: seekBar.leftPadding + seekBar.visualPosition * (seekBar.availableWidth - width); y: seekBar.topPadding + seekBar.availableHeight / 2 - height / 2; width: 12; height: 12; radius: 6; color: "#d9f2e3" }
        }
        Text { x: 0; y: 143; text: root.player ? root.formatTime(root.player.position) : "0:00"; color: "#96a69c"; font.pixelSize: 10 }
        Text { anchors.right: parent.right; y: 143; text: root.player ? root.formatTime(root.player.length) : "0:00"; color: "#96a69c"; font.pixelSize: 10 }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; y: 160; spacing: 18
            ActionButton { y: 6; width: 44; height: 44; iconName: "previous"; Accessible.name: "Previous track"; enabled: !!root.player && root.player.canGoPrevious; onClicked: { root.react("wink"); root.player.previous() } }
            ActionButton { width: 64; height: 56; accent: true; iconName: root.player && root.player.isPlaying ? "pause" : "play"; Accessible.name: root.player && root.player.isPlaying ? "Pause" : "Play"; enabled: !!root.player && root.player.canTogglePlaying; onClicked: { root.react("laugh"); root.player.togglePlaying() } }
            ActionButton { y: 6; width: 44; height: 44; iconName: "next"; Accessible.name: "Next track"; enabled: !!root.player && root.player.canGoNext; onClicked: { root.react("wink"); root.player.next() } }
        }
        Rectangle { x: 0; y: 222; width: parent.width; height: 1; color: "#2a342d" }
        Text { x: 2; y: 232; text: "PLAYING FROM"; color: "#96a69c"; font.pixelSize: 10; font.letterSpacing: 1 }
        ActionButton { anchors.right: parent.right; y: 228; width: 232; height: 34; text: root.player ? root.player.identity : "No player connected"; enabled: root.playerCount > 1; onClicked: { root.react("curious"); root.nextPlayer() } }
    }

    Item {
        id: youtubeView
        x: 0; y: 78; width: parent.width; height: parent.height - y
        visible: root.activeWidget === "youtube"
        Row {
            y: 0; spacing: 10
            UiIcon { y: 1; name: "youtube"; width: 20; height: 20; tint: "#9ed6b4" }
            Text { text: "YOUTUBE DOWNLOADER"; color: "#edf0ed"; font.pixelSize: 12; font.weight: Font.DemiBold; font.letterSpacing: 0.7 }
        }
        Controls.TextField {
            id: urlInput
            y: 28; width: parent.width; height: 44; enabled: !root.downloading
            placeholderText: "Paste a YouTube URL"; placeholderTextColor: "#7e9185"; color: "#edf0ed"
            selectByMouse: true; font.pixelSize: 13; leftPadding: 14; rightPadding: 14
            background: Rectangle { color: "#252c28"; radius: 12 }
            onAccepted: root.startDownload()
        }
        Row {
            y: 80; width: parent.width; height: 42; spacing: 8
            ActionButton { width: (parent.width - 8) / 2; height: 42; text: "Video"; accent: !root.audioOnly; enabled: !root.downloading; onClicked: { root.react("curious"); root.audioModeRequested(false) } }
            ActionButton { width: (parent.width - 8) / 2; height: 42; text: "Music"; accent: root.audioOnly; enabled: !root.downloading; onClicked: { root.react("happy"); root.audioModeRequested(true) } }
        }
        Row {
            y: 132; width: parent.width; height: 16; spacing: 8
            Text { width: root.audioOnly ? parent.width : (parent.width - 8) / 2; text: root.audioOnly ? "AUDIO FORMAT" : "VIDEO QUALITY"; color: "#96a69c"; font.pixelSize: 10; font.letterSpacing: 0.8 }
            Text { visible: !root.audioOnly; width: (parent.width - 8) / 2; text: "CONTAINER"; color: "#96a69c"; font.pixelSize: 10; font.letterSpacing: 0.8 }
        }
        Controls.ComboBox {
            id: quality
            x: 0; y: 152; width: (parent.width - 8) / 2; height: 38
            model: ["360p", "480p", "720p", "1080p", "1440p", "2160p"]; currentIndex: 2
            enabled: !root.audioOnly && !root.downloading; visible: !root.audioOnly
            background: Rectangle { radius: 10; color: "#252c28" }
            contentItem: Text { leftPadding: 12; text: quality.currentText; color: "#edf0ed"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
            indicator: UiIcon { x: quality.width - 28; y: 9; width: 20; height: 20; name: "chevron"; tint: "#96a69c" }
        }
        Controls.ComboBox {
            id: videoFormat
            x: (parent.width + 8) / 2; y: 152; width: (parent.width - 8) / 2; height: 38
            model: ["MP4", "MKV", "WebM"]; currentIndex: 0
            enabled: !root.audioOnly && !root.downloading; visible: !root.audioOnly
            background: Rectangle { radius: 10; color: "#252c28" }
            contentItem: Text { leftPadding: 12; text: videoFormat.currentText; color: "#edf0ed"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
            indicator: UiIcon { x: videoFormat.width - 28; y: 9; width: 20; height: 20; name: "chevron"; tint: "#96a69c" }
        }
        Controls.ComboBox {
            id: musicFormat
            x: 0; y: 152; width: parent.width; height: 38
            model: ["MP3", "M4A", "OPUS", "FLAC", "WAV"]; currentIndex: 0
            enabled: root.audioOnly && !root.downloading; visible: root.audioOnly
            background: Rectangle { radius: 10; color: "#252c28" }
            contentItem: Text { leftPadding: 12; text: musicFormat.currentText; color: "#edf0ed"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
            indicator: UiIcon { x: musicFormat.width - 28; y: 9; width: 20; height: 20; name: "chevron"; tint: "#96a69c" }
        }
        ActionButton { x: 0; y: 200; width: parent.width - 52; height: 42; iconName: "download"; text: root.downloading ? "Downloading…" : "Download"; accent: true; enabled: !root.downloading; onClicked: { root.react("excited"); root.startDownload() } }
        ActionButton { anchors.right: parent.right; y: 200; width: 44; height: 42; iconName: "folder"; Accessible.name: "Open Downloads"; onClicked: { root.react("happy"); Quickshell.execDetached(["xdg-open", root.downloadDirectory]) } }
        Text { x: 2; y: 248; width: parent.width - 4; height: 16; text: root.status; color: "#96a69c"; font.pixelSize: 10; elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter }
    }
}
