pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: bubble
    property real progress: 0
    property bool expanded: false
    property bool busy: false
    property bool dropHover: false
    property bool enjoying: false
    property real joy: enjoying && !expanded && !angry && face < 0.01 ? 1 : 0
    property real beat: 0
    Behavior on joy { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    SequentialAnimation on beat {
        running: bubble.enjoying && !bubble.expanded && !bubble.angry && bubble.face < 0.01
        loops: Animation.Infinite
        NumberAnimation { to: 1; duration: 420; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 420; easing.type: Easing.InOutSine }
        onStopped: bubble.beat = 0
    }
    property bool angry: false
    property string expression: ""
    property string pendingExpression: ""
    property real expressionAmount: 0
    readonly property bool laughing: expression === "laugh" || expression === "happy" || expression === "excited"
    readonly property real visibleExpressionAmount: expanded ? 0 : expressionAmount
    readonly property real laughAmount: laughing ? visibleExpressionAmount : 0
    readonly property real winkAmount: expression === "wink" ? visibleExpressionAmount : 0
    readonly property real curiousAmount: expression === "curious" ? visibleExpressionAmount : 0
    readonly property real surprisedAmount: expression === "surprised" ? visibleExpressionAmount : 0
    property real anger: angry && !expanded && expression === "" ? 1 : 0
    Behavior on anger { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    readonly property bool hovered: pointer.containsMouse
    readonly property bool held: pointer.pressed
    property string dockEdge: "right"
    property real tucked: 1
    property real peekX: dockEdge === "right" ? -10 : dockEdge === "left" ? 10 : 0
    property real peekY: dockEdge === "bottom" ? -10 : 0
    Behavior on peekX { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on peekY { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    property alias content: contents.data
    property real eyelid: 1
    readonly property real phase: Math.max(0, Math.min(1, progress))
    readonly property real rounding: ease((phase - 0.25) / 0.75)
    readonly property real corner: Math.min(width, height) / 2 * (1 - rounding) + 24 * rounding
    property real face: expanded ? 1 : 0
    Behavior on face { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    readonly property real faceScale: 5 / 6 + phase / 6
    readonly property real reveal: ease((phase - 0.84) / 0.16)
    readonly property bool ballOnRight: dockEdge === "right"
    readonly property real cardLeft: 0
    readonly property real cardTop: 0
    readonly property real cardWidth: width
    readonly property point ballCenter: Qt.point(width / 2 + (width / 2 - 24) * rounding,
                                               height / 2 + (24 - height / 2) * rounding)
    readonly property point faceCenter: Qt.point(ballCenter.x + peekX * tucked * (1 - phase),
                                               ballCenter.y + peekY * tucked * (1 - phase))
    signal clicked()
    signal dragStarted()
    signal dragMoved(real dx, real dy)
    signal dragFinished()
    signal youtubeUrlDropped(string url)

    function react(mood) {
        pendingExpression = mood;
        expressionIn.stop();
        expressionOut.stop();
        expressionHold.stop();
        expressionSwapOut.stop();
        if (expression !== "" && expression !== mood && expressionAmount > 0.01) {
            expressionSwapOut.start();
        } else {
            expression = mood;
            if (expressionAmount < 0.01) expressionAmount = 0;
            expressionIn.start();
        }
    }

    function ease(value) {
        var t = Math.max(0, Math.min(1, value));
        return t * t * (3 - 2 * t);
    }
    function mixColor(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t,
                       a.b + (b.b - a.b) * t, 1);
    }
    readonly property color mint: pointer.pressed ? "#8dc5a3" : dropHover ? "#c0f1d0" : pointer.containsMouse ? "#a8dfbd" : "#9ed6b4"
    readonly property color ink: "#151918"
    readonly property color restingFace: "#263d30"
    readonly property color openFace: "#9ed6b4"
    readonly property color faceColor: mixColor(restingFace, openFace, ease(phase))

    // Mask the whole bubble, including its contents, with one liquid outline.
    layer.enabled: true
    layer.smooth: true
    layer.effect: ShaderEffect {
        property size extent: Qt.size(bubble.width, bubble.height)
        property real phase: bubble.phase
        property real corner: bubble.corner
        fragmentShader: Qt.resolvedUrl("bubble-mask.frag.qsb")
    }

    Rectangle {
        anchors.fill: parent
        color: bubble.mixColor(bubble.mint, bubble.ink, bubble.ease(bubble.phase))
        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }
    Item { id: contents; anchors.fill: parent }

    // The eyes merge into one X. Their position never chases a moving target.
    Item {
        x: bubble.faceCenter.x - 24 * bubble.faceScale
        y: bubble.faceCenter.y - 24 * bubble.faceScale - 1.5 * bubble.beat * bubble.joy
        width: 48
        height: 48
        opacity: bubble.dropHover ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        scale: bubble.faceScale
        transformOrigin: Item.TopLeft
        Repeater {
            model: 2
            Rectangle {
                required property int index
                readonly property real side: index === 0 ? -1 : 1
                width: 5 - 3 * bubble.face + 5 * bubble.laughAmount
                       + (index === 0 ? 2 * bubble.winkAmount : 0) + bubble.curiousAmount
                height: (13 - 8 * bubble.anger * (1 - bubble.face) + 3 * bubble.face
                         - 9 * bubble.laughAmount - (index === 0 ? 10 * bubble.winkAmount : 0)
                         + 4 * bubble.surprisedAmount)
                        * (bubble.eyelid * (1 - bubble.face) + bubble.face)
                x: 24 + side * (6.5 - 1.5 * bubble.anger + 1.5 * bubble.surprisedAmount) * (1 - bubble.face) - width / 2
                y: 25 + bubble.anger * (1 - bubble.face) - height / 2
                radius: width / 2
                rotation: side * (45 * bubble.face - 18 * bubble.anger * (1 - bubble.face)
                                 + 12 * bubble.laughAmount + 15 * bubble.curiousAmount)
                color: bubble.faceColor
                opacity: (1 - bubble.joy) * (1 - Math.max(bubble.laughAmount,
                           index === 0 ? bubble.winkAmount : 0))
                antialiasing: true
            }
        }
        // Two smiling, closed eyes; the face gently bobs while playback runs.
        Repeater {
            model: 2
            Item {
                required property int index
                x: 24 + (index === 0 ? -6.5 : 6.5) - 5
                y: 22
                width: 10; height: 8
                opacity: bubble.joy + bubble.laughAmount
                scale: bubble.joy > 0.5 ? 1 : 0.9 + 0.1 * bubble.laughAmount
                Rectangle {
                    x: 1.5; y: 0; width: 2.5; height: 8; radius: 1.25
                    rotation: 35; color: bubble.faceColor; antialiasing: true
                }
                Rectangle {
                    x: 6; y: 0; width: 2.5; height: 8; radius: 1.25
                    rotation: -35; color: bubble.faceColor; antialiasing: true
                }
            }
        }
        Canvas {
            id: mouth
            width: 48; height: 48
            opacity: bubble.visibleExpressionAmount
            onOpacityChanged: requestPaint()
            Connections { target: bubble; function onExpressionChanged() { mouth.requestPaint() } }
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (bubble.expression === "") return;
                ctx.strokeStyle = bubble.faceColor;
                ctx.fillStyle = bubble.faceColor;
                ctx.lineWidth = 2;
                ctx.lineCap = "round";
                if (bubble.laughing) {
                    ctx.beginPath(); ctx.ellipse(24, 28, 6, 5, 0, 0, Math.PI * 2); ctx.fill();
                    ctx.fillStyle = "#9ed6b4";
                    ctx.beginPath(); ctx.ellipse(24, 31, 3, 1.5, 0, 0, Math.PI * 2); ctx.fill();
                } else if (bubble.expression === "surprised") {
                    ctx.beginPath(); ctx.ellipse(24, 28, 3, 4, 0, 0, Math.PI * 2); ctx.stroke();
                } else if (bubble.expression === "angry") {
                    ctx.beginPath(); ctx.arc(24, 34, 7, Math.PI * 1.15, Math.PI * 1.85); ctx.stroke();
                } else {
                    ctx.beginPath(); ctx.arc(24, 21, 9, Math.PI * 0.15, Math.PI * 0.85); ctx.stroke();
                }
            }
        }
    }
    UiIcon {
        x: bubble.faceCenter.x - 11
        y: bubble.faceCenter.y - 11
        width: 22; height: 22
        name: "drop"
        tint: "#17201c"
        visible: bubble.dropHover && !bubble.expanded
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }
    Rectangle {
        visible: bubble.busy
        x: bubble.width - 12; y: 36
        width: 6; height: 6; radius: 3; color: "#f2d58c"
    }
    MouseArea {
        id: pointer
        property point pressPoint
        property bool moving: false
        x: bubble.expanded ? bubble.faceCenter.x - 24 : 0
        y: bubble.expanded ? bubble.faceCenter.y - 24 : 0
        width: bubble.expanded ? 48 : bubble.width
        height: bubble.expanded ? 48 : bubble.height
        hoverEnabled: true
        preventStealing: true
        cursorShape: moving ? Qt.ClosedHandCursor : bubble.expanded ? Qt.PointingHandCursor : Qt.OpenHandCursor
        onPressed: function(mouse) {
            pressPoint = mapToItem(null, mouse.x, mouse.y);
            moving = false;
        }
        onPositionChanged: function(mouse) {
            if (!pressed || bubble.expanded || bubble.phase > 0.02) return;
            var point = mapToItem(null, mouse.x, mouse.y);
            var dx = point.x - pressPoint.x;
            var dy = point.y - pressPoint.y;
            if (!moving && Math.hypot(dx, dy) > 6) {
                moving = true;
                bubble.dragStarted();
            }
            if (moving) bubble.dragMoved(dx, dy);
        }
        onReleased: {
            if (moving) bubble.dragFinished();
            else bubble.clicked();
            moving = false;
        }
        onCanceled: {
            if (moving) bubble.dragFinished();
            moving = false;
        }
    }
    DropArea {
        anchors.fill: parent
        keys: ["text/plain", "text/uri-list"]
        onEntered: {
            bubble.dropHover = true;
            bubble.react("surprised");
        }
        onExited: bubble.dropHover = false
        onDropped: function(event) {
            bubble.dropHover = false;
            var value = String(event.text || "").trim();
            if (!value && event.urls && event.urls.length) value = String(event.urls[0]);
            if (value.indexOf("file:") === 0) value = decodeURIComponent(value.replace(/^file:\/\//, ""));
            if (value.indexOf("\n") >= 0) value = value.split(/\s+/)[0];
            event.acceptProposedAction();
            bubble.youtubeUrlDropped(value);
        }
    }
    Timer {
        interval: 5200; repeat: true; running: !bubble.expanded && !bubble.angry && !bubble.enjoying
        onTriggered: blink.restart()
    }
    NumberAnimation {
        id: expressionSwapOut
        target: bubble; property: "expressionAmount"; to: 0
        duration: 120; easing.type: Easing.InOutSine
        onFinished: {
            bubble.expression = bubble.pendingExpression;
            expressionIn.start();
        }
    }
    NumberAnimation {
        id: expressionIn
        target: bubble; property: "expressionAmount"; to: 1
        duration: 240; easing.type: Easing.OutCubic
        onFinished: expressionHold.start()
    }
    PauseAnimation { id: expressionHold; duration: 620; onFinished: expressionOut.start() }
    NumberAnimation {
        id: expressionOut
        target: bubble; property: "expressionAmount"; to: 0
        duration: 220; easing.type: Easing.InOutSine
        onFinished: bubble.expression = ""
    }
    onExpandedChanged: {
        blink.stop();
        eyelid = 1;
    }
    onAngryChanged: {
        blink.stop();
        eyelid = 1;
    }
    onEnjoyingChanged: {
        blink.stop();
        eyelid = 1;
    }
    SequentialAnimation {
        id: blink
        NumberAnimation { target: bubble; property: "eyelid"; to: 0.15; duration: 80 }
        PauseAnimation { duration: 50 }
        NumberAnimation { target: bubble; property: "eyelid"; to: 1; duration: 120 }
    }
    Accessible.role: Accessible.Button
    Accessible.name: expanded ? "Close widgets" : "Open music and downloader widgets"
    Accessible.onPressAction: bubble.clicked()
}
