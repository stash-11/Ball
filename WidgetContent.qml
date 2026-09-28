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
    signal nextPlayer()
    signal downloadRequested(string url, bool audioOnly, string quality)
    signal audioModeRequested(bool audioOnly)
    signal closeRequested()
    function startDownload() { root.downloadRequested(urlInput.text, root.audioOnly, quality.currentText) }
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
                onClicked: root.activeWidget = modelData.key
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
        y: 86; width: parent.width; height: 256
        visible: root.activeWidget === "music"
        Rectangle {
            width: 84; height: 84; radius: 16; color: "#26382d"; clip: true
            UiIcon { anchors.centerIn: parent; width: 32; height: 32; tint: "#9ed6b4" }
            Image { anchors.fill: parent; source: root.player ? root.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop }
        }
        Column {
            x: 100; y: 4; width: parent.width - 100; spacing: 9
            Text { text: root.player && root.player.isPlaying ? "NOW PLAYING" : "MUSIC"; color: "#9ed6b4"; font.pixelSize: 10; font.letterSpacing: 1.3 }
            Text { width: parent.width; text: root.player && root.player.trackTitle ? root.player.trackTitle : "Nothing playing"; color: "#edf0ed"; font.pixelSize: 18; font.weight: Font.DemiBold; elide: Text.ElideRight }
            Text { width: parent.width; text: root.player ? (root.player.trackArtist || root.player.identity) : "Start a song in your music app"; color: "#96a69c"; font.pixelSize: 12; elide: Text.ElideRight }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; y: 112; spacing: 18
            ActionButton { y: 6; width: 44; height: 44; iconName: "previous"; Accessible.name: "Previous track"; enabled: !!root.player && root.player.canGoPrevious; onClicked: root.player.previous() }
            ActionButton { width: 64; height: 56; accent: true; iconName: root.player && root.player.isPlaying ? "pause" : "play"; Accessible.name: root.player && root.player.isPlaying ? "Pause" : "Play"; enabled: !!root.player && root.player.canTogglePlaying; onClicked: root.player.togglePlaying() }
            ActionButton { y: 6; width: 44; height: 44; iconName: "next"; Accessible.name: "Next track"; enabled: !!root.player && root.player.canGoNext; onClicked: root.player.next() }
        }
        Rectangle { y: 192; width: parent.width; height: 1; color: "#2a342d" }
        Text { x: 2; y: 219; text: "Playing from"; color: "#96a69c"; font.pixelSize: 12 }
        ActionButton { anchors.right: parent.right; y: 206; width: 210; text: root.player ? root.player.identity : "No player connected"; enabled: root.playerCount > 1; onClicked: root.nextPlayer() }
    }

    Item {
        y: 86; width: parent.width; height: 256
        visible: root.activeWidget === "youtube"
        Text { text: "Video link"; color: "#96a69c"; font.pixelSize: 12 }
        Controls.TextField {
            id: urlInput
            y: 22; width: parent.width; height: 44; enabled: !root.downloading
            placeholderText: "Paste a YouTube URL"; placeholderTextColor: "#7e9185"; color: "#edf0ed"
            selectByMouse: true; font.pixelSize: 13; leftPadding: 14; rightPadding: 14
            background: Rectangle { color: "#252c28"; radius: 12 }
            onAccepted: root.startDownload()
        }
        Text { y: 84; text: "Save as"; color: "#96a69c"; font.pixelSize: 12 }
        Row {
            y: 104; spacing: 6
            ActionButton { width: 88; height: 36; text: "Video"; accent: !root.audioOnly; enabled: !root.downloading; onClicked: root.audioModeRequested(false) }
            ActionButton { width: 88; height: 36; text: "Audio"; accent: root.audioOnly; enabled: !root.downloading; onClicked: root.audioModeRequested(true) }
        }
        Text { x: 204; y: 84; text: root.audioOnly ? "Format" : "Quality"; color: "#96a69c"; font.pixelSize: 12 }
        Controls.ComboBox {
            id: quality
            x: 204; y: 104; width: parent.width - 204; height: 36
            model: ["480", "720", "1080"]; currentIndex: 1
            enabled: !root.audioOnly && !root.downloading
            background: Rectangle { radius: 10; color: "#252c28" }
            contentItem: Text { leftPadding: 12; text: root.audioOnly ? "MP3" : quality.currentText + "p"; color: "#edf0ed"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
            indicator: UiIcon { x: quality.width - 28; y: 8; width: 20; height: 20; name: "chevron"; tint: "#96a69c" }
        }
        ActionButton { y: 162; width: parent.width - 56; height: 44; iconName: "download"; text: root.downloading ? "Downloading…" : "Download"; accent: true; enabled: !root.downloading; onClicked: root.startDownload() }
        ActionButton { anchors.right: parent.right; y: 162; width: 44; height: 44; iconName: "folder"; Accessible.name: "Open Downloads"; onClicked: Quickshell.execDetached(["xdg-open", root.downloadDirectory]) }
        Text { y: 220; width: parent.width; height: 34; text: root.status; color: "#96a69c"; font.pixelSize: 11; wrapMode: Text.WrapAnywhere; maximumLineCount: 2; elide: Text.ElideRight }
    }
}
