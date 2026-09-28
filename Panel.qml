import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "Download.js" as Download

Item {
    id: root
    property var shell: null
    property var service: null
    property var manifest: null
    property bool opened: false
    property string activeWidget: "music"
    readonly property real ballSize: 40
    readonly property real ballRadius: ballSize / 2
    property string dockEdge: "right"
    property real dockPosition: 48
    property bool dragging: false
    property real dragX: 0
    property real dragY: 0
    property real dragStartX: 0
    property real dragStartY: 0
    function clamp(value, low, high) { return Math.max(low, Math.min(high, value)) }
    readonly property real restX: dockEdge === "left" ? -ballRadius : dockEdge === "right" ? window.width - ballRadius : clamp(dockPosition, 48, window.width - 48) - ballRadius
    readonly property real restY: dockEdge === "top" ? -ballRadius : dockEdge === "bottom" ? window.height - ballRadius : clamp(dockPosition, 48, window.height - 48) - ballRadius
    readonly property real panelX: dockEdge === "left" ? 16 : dockEdge === "right" ? window.width - 426 : clamp(dockPosition - 205, 16, window.width - 426)
    readonly property real panelY: dockEdge === "bottom" ? window.height - 386 : clamp(restY, 24, window.height - 386)
    function beginDrag() {
        dragStartX = bubble.x;
        dragStartY = bubble.y;
        dragX = bubble.x;
        dragY = bubble.y;
        dragging = true;
    }
    function moveDrag(dx, dy) {
        var peek = ballRadius * 0.4;
        dragX = clamp(dragStartX + dx, -peek, window.width - ballSize + peek);
        dragY = clamp(dragStartY + dy, -peek, window.height - ballSize + peek);
    }
    function finishDrag() {
        var cx = dragX + ballRadius;
        var cy = dragY + ballRadius;
        var distances = [cx, window.width - cx, cy, window.height - cy];
        var nearest = distances.indexOf(Math.min.apply(null, distances));
        dockEdge = ["left", "right", "top", "bottom"][nearest];
        dockPosition = nearest === 0 || nearest === 1 ? cy : cx;
        dragging = false;
    }
    // Hover peeks out ten pixels; expansion starts at that exact position.
    property real expansionOrigin: 10 / 36
    property bool growing: false
    property real undock: opened || Math.abs(travel) > 0.001 ? expansionOrigin
                         : hoverPocket.containsMouse || bubble.hovered || bubble.held ? 10 / 36 : 0
    Behavior on undock {
        NumberAnimation { id: revealMotion; duration: 220; easing.type: Easing.OutCubic }
    }
    property real travel: growing ? 1 : 0
    Behavior on travel {
        NumberAnimation {
            id: shapeMotion
            duration: root.growing ? 580 : 460
            easing.type: Easing.OutBack; easing.overshoot: 0.55
        }
    }
    readonly property real emergedX: restX + (dockEdge === "left" ? ballRadius + 16 : dockEdge === "right" ? -ballRadius - 16 : 0) * undock
    readonly property real emergedY: restY + (dockEdge === "top" ? ballRadius + 16 : dockEdge === "bottom" ? -ballRadius - 16 : 0) * undock
    onOpenedChanged: {
        if (opened) expansionOrigin = undock;
        growing = opened;
        bubble.react(opened ? "surprised" : "happy");
    }
    function open(payloadJson) {
        var payload = {}
        try { payload = JSON.parse(payloadJson || "{}") || {} } catch (e) {}
        var requestedWidget = String(payload.widget || payload.tab || "")
        if (requestedWidget === "music" || requestedWidget === "youtube")
            root.activeWidget = requestedWidget
        root.opened = true
    }
    function close() { opened = false }
    function toggleWidgets() {
        if (shell) shell.toggle("io.github.stash-11.utilities", "{}")
        else opened = !opened
    }
    function dismiss() {
        if (shell) shell.hide("io.github.stash-11.utilities")
        else close()
    }
    readonly property var players: Mpris.players.values
    property string selectedPlayer: ""
    readonly property var player: {
        for (var i = 0; i < players.length; i++)
            if (selectedPlayer && players[i].identity === selectedPlayer) return players[i];
        for (var j = 0; j < players.length; j++)
            if (players[j].isPlaying) return players[j];
        return players.length ? players[0] : null;
    }
    function nextPlayer() {
        if (!players.length) return;
        var index = players.indexOf(player);
        bubble.react("wink");
        selectedPlayer = players[(index + 1) % players.length].identity;
    }
    property string downloadDirectory: (Quickshell.env("HOME") || "") + "/Downloads"
    property string status: "Paste a YouTube link to get started."
    property string lastError: ""
    property bool audioOnly: false
    property string droppedYoutubeUrl: ""
    property int youtubeDropSerial: 0
    function startDownload(url, audio, quality, format) {
        if (download.running) return;
        bubble.react("excited");
        var args = Download.command(url, audio, quality, downloadDirectory, format);
        if (!args.length) { status = "Enter a valid https:// YouTube video link."; return; }
        lastError = "";
        status = "Starting download…";
        download.command = args;
        download.running = true;
    }
    Process {
        command: ["xdg-user-dir", "DOWNLOAD"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var path = String(text).trim();
                if (path.charAt(0) === "/") root.downloadDirectory = path;
            }
        }
    }
    Process {
        id: download
        stdout: SplitParser {
            onRead: function(line) {
                if (String(line).trim()) root.status = String(line).trim();
            }
        }
        stderr: SplitParser {
            onRead: function(line) {
                if (String(line).trim()) root.lastError = String(line).trim();
            }
        }
        onExited: function(code) {
            root.status = code === 0 ? "Done · Saved to Downloads" : (root.lastError || "Download failed. Check the link and connection.");
            bubble.react(code === 0 ? "laugh" : "angry");
        }
    }

    PanelWindow {
        id: window
        visible: true
        // A stable surface lets a grabbed bubble cross the screen without
        // moving a Wayland window. Only the bubble's mask accepts input.
        anchors { top: true; right: true; bottom: true; left: true }
        margins { top: 0; right: 0 }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "my-utilities"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        mask: Region {
            Region { item: bubble; radius: bubble.corner }
            Region { item: hoverPocket }
        }

        // Keep hover while the ball moves away from the edge under the pointer.
        MouseArea {
            id: hoverPocket
            x: Math.min(root.restX, root.emergedX)
            y: Math.min(root.restY, root.emergedY)
            width: !root.opened && Math.abs(root.travel) < 0.001 ? root.ballSize + Math.abs(root.restX - root.emergedX) : 0
            height: width > 0 ? root.ballSize + Math.abs(root.restY - root.emergedY) : 0
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleWidgets()
        }

        Bubble {
            id: bubble
            x: root.dragging ? root.dragX : root.emergedX * (1 - phase) + root.panelX * phase
            y: root.dragging ? root.dragY : root.emergedY * (1 - phase) + root.panelY * phase
            scale: 1
            transformOrigin: Item.Center
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
            Behavior on x { enabled: !root.dragging && !revealMotion.running && !shapeMotion.running && root.travel === 0; NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            Behavior on y { enabled: !root.dragging && !revealMotion.running && !shapeMotion.running && root.travel === 0; NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            width: root.ballSize + (410 - root.ballSize) * root.travel
            height: root.ballSize + (370 - root.ballSize) * Math.max(0, root.travel * (0.82 + 0.18 * root.travel))
            progress: root.travel
            expanded: root.opened
            angry: hoverPocket.containsMouse || bubble.hovered || bubble.held
            dockEdge: root.dragging ? "" : root.dockEdge
            tucked: 1 - root.undock
            busy: download.running
            enjoying: !!root.player && root.player.isPlaying
            onClicked: root.toggleWidgets()
            onDragStarted: { bubble.react("curious"); root.beginDrag() }
            onDragMoved: function(dx, dy) { root.moveDrag(dx, dy) }
            onDragFinished: { root.finishDrag(); bubble.react("wink") }
            onYoutubeUrlDropped: function(url) {
                bubble.react("surprised");
                if (!Download.validUrl(url)) {
                    root.status = "Drop a valid YouTube video URL."
                    root.activeWidget = "youtube"
                    if (!root.opened) root.toggleWidgets()
                    return
                }
                root.droppedYoutubeUrl = url
                root.youtubeDropSerial += 1
                root.activeWidget = "youtube"
                bubble.react("excited")
                if (!root.opened) root.toggleWidgets()
            }

            content: WidgetContent {
                width: 382
                height: 342
                x: bubble.cardLeft + 14
                y: bubble.cardTop + 14 + 10 * (1 - bubble.reveal)
                scale: Math.min(1, Math.max(0, (bubble.cardWidth - 28) / width))
                transformOrigin: Item.TopRight
                visible: bubble.reveal > 0
                opacity: bubble.reveal
                enabled: root.opened && bubble.reveal > 0.95
                focus: enabled
                activeWidget: root.activeWidget
                onWidgetSelected: function(widget) { root.activeWidget = widget }
                onCloseRequested: root.dismiss()
                onExpressionRequested: function(mood) { bubble.react(mood) }
                onAudioModeRequested: function(value) { root.audioOnly = value }
                Keys.onEscapePressed: root.dismiss()
                player: root.player
                playerCount: root.players.length
                audioOnly: root.audioOnly
                downloading: download.running
                status: root.status
                downloadDirectory: root.downloadDirectory
                droppedUrl: root.droppedYoutubeUrl
                dropSerial: root.youtubeDropSerial
                onNextPlayer: root.nextPlayer()
                onDownloadRequested: function(url, audio, quality, format) { root.startDownload(url, audio, quality, format) }
            }
        }

        Rectangle {
            id: dropHint
            width: 92; height: 34; radius: 12
            x: root.dockEdge === "right" ? bubble.x - width - 10
             : root.dockEdge === "left" ? bubble.x + bubble.width + 10
             : root.clamp(bubble.x + bubble.width / 2 - width / 2, 10, window.width - width - 10)
            y: root.dockEdge === "bottom" ? bubble.y - height - 10
             : root.clamp(bubble.y + bubble.height / 2 - height / 2, 10, window.height - height - 10)
            color: "#202622"
            opacity: bubble.dropHover ? 1 : 0
            visible: bubble.dropHover || opacity > 0.01
            z: 10
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Text {
                anchors.centerIn: parent
                text: "Drop here"
                color: "#edf0ed"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
        }
    }
}
