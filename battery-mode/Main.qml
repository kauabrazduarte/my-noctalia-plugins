import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Injected by the host
    property var pluginApi: null

    // Read-only state (consumed by BarWidget / ControlCenterWidget / Panel)
    readonly property string conservationPath: "/sys/devices/pci0000:00/0000:00:14.3/PNP0C09:00/VPC2004:00/conservation_mode"
    readonly property string capacityPath: "/sys/class/power_supply/BAT0/capacity"
    readonly property string statusPath: "/sys/class/power_supply/BAT0/status"
    readonly property string chargeTypesPath: "/sys/class/power_supply/BAT0/charge_types"
    readonly property string cyclePath: "/sys/class/power_supply/BAT0/cycle_count"

    property string mode: "Long_Life"          // "Long_Life" or "Standard"
    property int capacity: 0
    property string status: "Unknown"          // "Charging", "Discharging", "Not charging", "Full", "Unknown"
    property bool charging: false
    property int cycleCount: 0

    Timer {
        id: pollTimer
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // 1) charge mode (the real source of truth is conservation_mode)
            root.readFile(root.conservationPath, function(cons) {
                root.mode = (cons === "1") ? "Long_Life" : "Standard";
            });
            // 2) capacity (0-100)
            root.readFile(root.capacityPath, function(cap) {
                var n = parseInt(cap, 10);
                if (!isNaN(n)) root.capacity = n;
            });
            // 3) status
            root.readFile(root.statusPath, function(st) {
                root.status = st;
                root.charging = (st === "Charging" || st === "Full");
            });
            // 4) cycle count
            root.readFile(root.cyclePath, function(cyc) {
                var n = parseInt(cyc, 10);
                if (!isNaN(n)) root.cycleCount = n;
            });
        }
    }

    // Async file read using Quickshell.Io.FileView
    function readFile(path, callback) {
        var view = Qt.createQmlObject('import Quickshell.Io; FileView { property var callback: null; path: ""; onLoaded: { callback(text); destroy(); } onLoadFailed: { callback(""); destroy(); } }', root, "read_" + Date.now());
        view.callback = callback;
        view.path = path;
    }

    // Action: toggle charge mode via TLP (uses pkexec for graphical auth in niri)
    function toggleChargeMode() {
        var target = (root.mode === "Standard") ? "poupar" : "cheia";
        var cmd = "bat-" + target + " 2>/dev/null || pkexec /usr/bin/tlp " +
                  ((target === "cheia") ? "fullcharge" : "start");
        Quickshell.execDetached(["fish", "-c", cmd]);
        // Optimistic UI update: flip immediately, the next 2s tick will reconcile.
        root.mode = (target === "cheia") ? "Standard" : "Long_Life";
    }

    Component.onCompleted: {
        Logger.i("BatteryMode", "Service initialized");
    }
}
