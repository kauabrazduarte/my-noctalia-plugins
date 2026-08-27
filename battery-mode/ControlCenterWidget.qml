import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null

    readonly property string mode: pluginApi?.mainInstance?.mode ?? "Long_Life"
    readonly property int capacity: pluginApi?.mainInstance?.capacity ?? 0
    readonly property bool charging: pluginApi?.mainInstance?.charging ?? false

    implicitWidth: 200 * Style.uiScaleRatio
    implicitHeight: 64 * Style.uiScaleRatio

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Style.radiusL
        color: mouseArea.containsMouse ? Color.mHover : Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Style.borderS

        Behavior on color {
            ColorAnimation { duration: Style.animationFast }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2

            NIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: root.mode === "Standard" ? "bolt" : "leaf"
                color: Color.mOnSurface
                pointSize: Style.fontSizeL
            }

            NText {
                Layout.alignment: Qt.AlignHCenter
                text: root.mode === "Standard" ? "100%" : "60%"
                color: Color.mOnSurface
                pointSize: Style.fontSizeM
                font.weight: Font.Bold
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: {
                if (pluginApi?.mainInstance) {
                    pluginApi.mainInstance.toggleChargeMode();
                }
            }
        }
    }
}
