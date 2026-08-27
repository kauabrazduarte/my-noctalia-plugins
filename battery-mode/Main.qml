import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
    id: root

    // Injected by the host
    property var pluginApi: null

    // Cached values, updated by each FileView's onLoaded/onInternalTextChanged.
    // These are regular properties (not readonly) so they can be reassigned.
    property string conservationRaw: ""
    property string capacityRaw: ""
    property string statusRaw: ""
    property string cycleRaw: ""

    // Computed state (read by BarWidget, ControlCenterWidget, Panel)
    readonly property string mode: conservationRaw === "1" ? "Long_Life" : "Standard"
    readonly property int capacity: parseInt(capacityRaw, 10) || 0
    readonly property string status: statusRaw || "Unknown"
    readonly property bool charging: status === "Charging" || status === "Full"
    readonly property int cycleCount: parseInt(cycleRaw, 10) || 0

    // --- One FileView per sysfs file ---
    // `preload: true` makes text() return the current file content synchronously.
    // The onInternalTextChanged signal fires when the file is reloaded; we re-read
    // and cache the result in our plain `string` properties so other bindings work.
    FileView {
        id: conservationView
        path: "/sys/devices/pci0000:00/0000:00:14.3/PNP0C09:00/VPC2004:00/conservation_mode"
        printErrors: false
        watchChanges: true
        onFileChanged: root.conservationRaw = text()
        onInternalTextChanged: root.conservationRaw = text()
        Component.onCompleted: root.conservationRaw = text()
    }
    FileView {
        id: capacityView
        path: "/sys/class/power_supply/BAT0/capacity"
        printErrors: false
        watchChanges: true
        onFileChanged: root.capacityRaw = text()
        onInternalTextChanged: root.capacityRaw = text()
        Component.onCompleted: root.capacityRaw = text()
    }
    FileView {
        id: statusView
        path: "/sys/class/power_supply/BAT0/status"
        printErrors: false
        watchChanges: true
        onFileChanged: root.statusRaw = text()
        onInternalTextChanged: root.statusRaw = text()
        Component.onCompleted: root.statusRaw = text()
    }
    FileView {
        id: cycleView
        path: "/sys/class/power_supply/BAT0/cycle_count"
        printErrors: false
        watchChanges: true
        onFileChanged: root.cycleRaw = text()
        onInternalTextChanged: root.cycleRaw = text()
        Component.onCompleted: root.cycleRaw = text()
    }

    // Periodic refresh: manually trigger reload of each FileView
    Timer {
        id: refreshTimer
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            conservationView.reload();
            capacityView.reload();
            statusView.reload();
            cycleView.reload();
        }
    }

    // --- Action: toggle charge mode via TLP ---
    function toggleChargeMode() {
        // Read the current state RIGHT NOW (not the cached value) to decide
        // which way to toggle. This avoids the stale-mode problem when the
        // user clicks twice quickly and the FileView hasn't reloaded yet.
        var currentCons = conservationView.text();
        var currentMode = (currentCons === "1") ? "Long_Life" : "Standard";
        var target = (currentMode === "Standard") ? "poupar" : "cheia";
        var cmd = "bat-" + target + " 2>/dev/null || pkexec /usr/bin/tlp " +
                  ((target === "cheia") ? "fullcharge" : "start");
        Logger.i("BatteryMode", "toggleChargeMode: current=", currentMode,
                 "target=", target, "cmd=", cmd);
        Quickshell.execDetached(["fish", "-c", cmd]);
        // The FileView watcher will pick up the new conservation_mode and
        // update conservationRaw automatically, which will re-evaluate the
        // mode binding and refresh the icon/text.
    }
}
