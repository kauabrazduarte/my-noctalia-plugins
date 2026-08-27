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
        // NOTE: watchChanges does NOT work on this Lenovo sysfs path
        // (inotify isn't fired for writes to virtual battery files). Use
        // the periodic Timer (below) to force reload() instead.
        onInternalTextChanged: root.conservationRaw = text()
        Component.onCompleted: root.conservationRaw = text()
    }
    FileView {
        id: capacityView
        path: "/sys/class/power_supply/BAT0/capacity"
        printErrors: false
        onInternalTextChanged: root.capacityRaw = text()
        Component.onCompleted: root.capacityRaw = text()
    }
    FileView {
        id: statusView
        path: "/sys/class/power_supply/BAT0/status"
        printErrors: false
        onInternalTextChanged: root.statusRaw = text()
        Component.onCompleted: root.statusRaw = text()
    }
    FileView {
        id: cycleView
        path: "/sys/class/power_supply/BAT0/cycle_count"
        printErrors: false
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
        var currentCons = conservationView.text();
        var currentMode = (currentCons === "1") ? "Long_Life" : "Standard";
        var target = (currentMode === "Standard") ? "poupar" : "cheia";
        var cmd = "bat-" + target + " 2>/dev/null || pkexec /usr/bin/tlp " +
                  ((target === "cheia") ? "fullcharge" : "start");
        Logger.i("BatteryMode", "toggleChargeMode: current=", currentMode,
                 "target=", target, "cmd=", cmd);
        // execDetached (fire-and-forget) because pkexec needs to be detached
        // from the QML scene — if we used Process, the polkit dialog would
        // own the QProcess and the exited signal never fires when the user
        // cancels the dialog.
        Quickshell.execDetached(["fish", "-c", cmd]);
        // Force a fast re-read of conservation_mode. The pkexec dialog
        // takes ~3s (the user types their password), then tlp runs (a few
        // hundred ms), then the firmware writes sysfs. Polling at 500ms
        // for ~5s catches the eventual change without burning CPU.
        forceRefreshTimer.restart();
    }

    Timer {
        id: forceRefreshTimer
        interval: 500
        repeat: true
        running: false
        onTriggered: {
            // Each tick: count up. After ~10 ticks (5s), stop.
            if (forceRefreshTimer.repeat && parent._ticks === undefined) {
                parent._ticks = 0;
            }
            parent._ticks = (parent._ticks || 0) + 1;
            conservationView.reload();
            capacityView.reload();
            statusView.reload();
            cycleView.reload();
            if ((parent._ticks || 0) >= 10) {
                forceRefreshTimer.stop();
                forceRefreshTimer.repeat = true;
                parent._ticks = 0;
            }
        }
    }
}
