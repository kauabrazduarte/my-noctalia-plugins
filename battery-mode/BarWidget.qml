import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    // Injected by the host
    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property string screenName: screen?.name ?? ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool barIsVertical: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)

    property bool enabled: true
    property bool allowClickWhenDisabled: false
    property bool hovering: false

    property color colorBg: Color.mSurfaceVariant
    property color colorFg: Color.mPrimary
    property color colorBgHover: Color.mHover
    property color colorFgHover: Color.mOnHover
    property color colorBorder: Color.mOutline
    property real customRadius: Style.radiusL

    // Live state from Main.qml
    readonly property string mode: pluginApi?.mainInstance?.mode ?? "Long_Life"
    readonly property int capacity: pluginApi?.mainInstance?.capacity ?? 0
    readonly property bool charging: pluginApi?.mainInstance?.charging ?? false
    readonly property bool showLabel: pluginApi?.pluginSettings?.showLabel ?? true
    readonly property bool clickToToggle: pluginApi?.pluginSettings?.clickToToggle ?? true

    readonly property string currentGlyph: mode === "Standard" ? "bolt" : "leaf"
    readonly property string tooltipText: {
        if (!pluginApi) return "";
        var modeLabel = (mode === "Standard")
            ? (pluginApi.tr("tooltip.standard") || "Standard (100%)")
            : (pluginApi.tr("tooltip.longlife") || "Long_Life (60%)");
        var statusLabel = charging
            ? (pluginApi.tr("tooltip.charging") || "Charging")
            : (pluginApi.tr("tooltip.discharging") || "On battery");
        return (pluginApi.tr("title") || "Battery") + " — " +
               capacity + "% • " + statusLabel + " • " + modeLabel;
    }

    property string tooltipDirection: BarService.getTooltipDirection()

    signal entered
    signal exited
    signal clicked
    signal rightClicked
    signal middleClicked
    signal wheel(int angleDelta)

    readonly property real contentWidth: barIsVertical ? capsuleHeight : Math.round(capsuleHeight + Style.marginXS * 2)
    readonly property real contentHeight: capsuleHeight

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    function openPanel() {
        if (pluginApi) {
            var result = pluginApi.openPanel(root.screen);
            Logger.i("BatteryMode", "OpenPanel result:", result);
        } else {
            Logger.e("BatteryMode", "PluginAPI is null");
        }
    }

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        opacity: root.enabled ? Style.opacityFull : Style.opacityMedium
        color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
        radius: Math.min((customRadius >= 0 ? customRadius : Style.iRadiusL), width / 2)
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        Behavior on color {
            ColorAnimation {
                duration: Style.animationNormal
                easing.type: Easing.InOutQuad
            }
        }

        // Glyph (icon) - on the left
        NIcon {
            id: glyph
            anchors.left: parent.left
            anchors.leftMargin: Style.marginS
            anchors.verticalCenter: parent.verticalCenter
            visible: showLabel
            icon: root.currentGlyph
            color: mouseArea.containsMouse ? Color.mOnHover : (root.mode === "Standard" ? Color.mPrimary : Color.mSecondary)
            pointSize: Style.fontSizeS
        }

        // Text (capacity %)
        NText {
            id: label
            anchors.left: glyph.visible ? glyph.right : parent.left
            anchors.leftMargin: glyph.visible ? Style.marginXS : Style.marginS
            anchors.right: parent.right
            anchors.rightMargin: Style.marginS
            anchors.verticalCenter: parent.verticalCenter
            visible: showLabel
            text: root.capacity + "%"
            color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
            pointSize: Style.fontSizeS
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        onEntered: {
            root.hovering = true;
            if (root.tooltipText) {
                TooltipService.show(root, root.tooltipText, root.tooltipDirection);
            }
            root.entered();
        }
        onExited: {
            root.hovering = false;
            if (root.tooltipText) {
                TooltipService.hide();
            }
            root.exited();
        }
        onClicked: function (mouse) {
            if (root.tooltipText) {
                TooltipService.hide();
            }

            if (!root.enabled && !root.allowClickWhenDisabled) {
                return;
            }

            if (mouse.button === Qt.LeftButton) {
                if (root.clickToToggle && pluginApi?.mainInstance) {
                    pluginApi.mainInstance.toggleChargeMode();
                } else {
                    root.openPanel();
                }
                root.clicked();
            } else if (mouse.button === Qt.RightButton) {
                root.openPanel();
                root.rightClicked();
            } else if (mouse.button === Qt.MiddleButton) {
                root.openPanel();
                root.middleClicked();
            }
        }
        onWheel: wheel => root.wheel(wheel.angleDelta.y)
    }
}
