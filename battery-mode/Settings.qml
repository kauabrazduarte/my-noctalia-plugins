import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM

    property var pluginApi: null

    property bool valueShowLabel: pluginApi?.pluginSettings?.showLabel ?? true
    property bool valueClickToToggle: pluginApi?.pluginSettings?.clickToToggle ?? true

    Component.onCompleted: {
        Logger.i("BatteryMode", "Settings UI loaded");
    }

    NLabel {
        label: pluginApi?.tr("settings.showLabel.label") || "Show percentage"
        description: pluginApi?.tr("settings.showLabel.description") || "Show the charge percentage next to the icon"
    }

    NToggle {
        checked: root.valueShowLabel
        onToggled: function (checked) {
            root.valueShowLabel = checked;
            pluginApi?.savePluginSettings({ "showLabel": checked, "clickToToggle": root.valueClickToToggle });
        }
    }

    NLabel {
        label: pluginApi?.tr("settings.clickToToggle.label") || "Click to toggle"
        description: pluginApi?.tr("settings.clickToToggle.description") || "Allow toggling the charge mode by clicking the bar widget"
    }

    NToggle {
        checked: root.valueClickToToggle
        onToggled: function (checked) {
            root.valueClickToToggle = checked;
            pluginApi?.savePluginSettings({ "showLabel": root.valueShowLabel, "clickToToggle": checked });
        }
    }
}
