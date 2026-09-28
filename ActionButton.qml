import QtQuick
import QtQuick.Controls.Basic
Button {
    id: root
    property bool accent: false
    property string iconName: ""
    implicitHeight: 40
    implicitWidth: Math.max(44, label.implicitWidth + (iconName ? 30 : 0) + 28)
    opacity: enabled ? 1 : 0.35
    contentItem: Item {
        Row {
            anchors.centerIn: parent; spacing: 8
            UiIcon { visible: root.iconName !== ""; name: root.iconName; width: 20; height: 20; tint: root.accent ? "#17201c" : "#edf0ed" }
            Text { id: label; visible: text !== ""; text: root.text; color: root.accent ? "#17201c" : "#edf0ed"; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
    }
    background: Rectangle { radius: height / 3; color: root.accent ? (root.down ? "#82bb99" : "#9ed6b4") : (root.hovered ? "#343e38" : "#252c28") }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
