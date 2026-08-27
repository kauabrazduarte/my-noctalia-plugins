import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null

    // SmartPanel properties
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    property real contentPreferredWidth: 360 * Style.uiScaleRatio
    property real contentPreferredHeight: 360 * Style.uiScaleRatio

    readonly property string mode: pluginApi?.mainInstance?.mode ?? "Long_Life"
    readonly property int capacity: pluginApi?.mainInstance?.capacity ?? 0
    readonly property string status: pluginApi?.mainInstance?.status ?? "?"
    readonly property bool charging: pluginApi?.mainInstance?.charging ?? false
    readonly property int cycleCount: pluginApi?.mainInstance?.cycleCount ?? 0

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            anchors.margins: Style.marginL
            color: Color.mSurface
            radius: Style.radiusL
            border.color: Color.mOutline
            border.width: Style.borderS

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.marginL
                spacing: Style.marginM

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginM

                    NIcon {
                        icon: root.mode === "Standard" ? "bolt" : "leaf"
                        color: Color.mOnSurface
                        pointSize: Style.fontSizeXL
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        NText {
                            text: root.mode === "Standard"
                                ? (pluginApi?.tr("mode.standard") || "Standard (100%)")
                                : (pluginApi?.tr("mode.longlife") || "Long_Life (60%)")
                            color: Color.mOnSurface
                            pointSize: Style.fontSizeL
                            font.weight: Font.Bold
                        }

                        NText {
                            text: root.capacity + "% • " + root.status
                            color: Color.mOnSurfaceVariant
                            pointSize: Style.fontSizeS
                        }
                    }
                }

                // Description
                NText {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: root.mode === "Standard"
                        ? (pluginApi?.tr("description.standard") ||
                           "Carga livre até 100%. Use quando precisar de autonomia máxima, por exemplo antes de uma viagem.")
                        : (pluginApi?.tr("description.longlife") ||
                           "A carga fica travada em ~60% para preservar a saúde da bateria enquanto você usa o notebook na tomada. Recomendado para uso diário conectado.")
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeS
                }

                Item { Layout.fillHeight: true }

                // Cycles
                NText {
                    text: "Ciclos: " + root.cycleCount
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeXS
                }

                // Action button
                NButton {
                    Layout.fillWidth: true
                    text: root.mode === "Standard"
                        ? (pluginApi?.tr("action.enableLongLife") || "Ativar modo Long_Life (60%)")
                        : (pluginApi?.tr("action.enableStandard") || "Liberar carga até 100%")
                    onClicked: {
                        if (pluginApi?.mainInstance) {
                            pluginApi.mainInstance.toggleChargeMode();
                        }
                    }
                }
            }
        }
    }
}
