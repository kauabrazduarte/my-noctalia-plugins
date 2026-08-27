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
        onInternalTextChanged: root.conservationRaw = text().trim()
        Component.onCompleted: root.conservationRaw = text().trim()
    }
    FileView {
        id: capacityView
        path: "/sys/class/power_supply/BAT0/capacity"
        printErrors: false
        onInternalTextChanged: root.capacityRaw = text().trim()
        Component.onCompleted: root.capacityRaw = text().trim()
    }
    FileView {
        id: statusView
        path: "/sys/class/power_supply/BAT0/status"
        printErrors: false
        onInternalTextChanged: root.statusRaw = text().trim()
        Component.onCompleted: root.statusRaw = text().trim()
    }
    FileView {
        id: cycleView
        path: "/sys/class/power_supply/BAT0/cycle_count"
        printErrors: false
        onInternalTextChanged: root.cycleRaw = text().trim()
        Component.onCompleted: root.cycleRaw = text().trim()
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
    // Logic:
    //   currentMode=Long_Life  -> user wants Standard  -> tlp fullcharge (rejected without AC)
    //   currentMode=Standard   -> user wants Long_Life -> tlp start (always works)
    // tlp start applies the configured STOP_CHARGE_THRESH_BAT0 (1 = Long_Life)
    // from /etc/tlp.conf and sets conservation_mode accordingly. It does not
    // require AC.
    function toggleChargeMode() {
        var currentCons = conservationView.text().trim();
        var currentMode = (currentCons === "1") ? "Long_Life" : "Standard";
        var tlpCmd = (currentMode === "Long_Life") ? "fullcharge" : "start";

        Logger.i("BatteryMode", "toggleChargeMode: currentCons=[", currentCons,
                 "] currentMode=", currentMode, "target=", tlpCmd);

        // tlp fullcharge refuses if AC is not connected ("fullcharge is
        // possible on AC power only"). Read ADP0/online via cat and
        // show a desktop toast if the charger is unplugged. Use the
        // Process callback (onStreamFinished) so we never block the
        // QML event loop. _spawnTlp / _notifyNoAc live as Item-level
        // methods so the inline closures can reach them.
        if (tlpCmd === "fullcharge") {
            var proc = Qt.createQmlObject('
                import Quickshell.Io
                Process {
                    stdout: StdioCollector {}
                    onExited: function (code) { destroy() }
                }
            ', root, "acCheck_" + Date.now());
            proc.command = ["cat", "/sys/class/power_supply/ADP0/online"];
            proc.running = true;
            proc.stdout.onStreamFinished.connect(function () {
                var v = proc.stdout.text.trim();
                proc.destroy();
                Logger.i("BatteryMode", "AC check (delayed): v=[", v, "]");
                if (v === "1") {
                    root._spawnTlp(tlpCmd);
                } else {
                    root._notifyNoAc();
                }
            });
            return;
        }

        // tlp start (Long_Life) works without AC, no check needed.
        root._spawnTlp(tlpCmd);
    }

    function _spawnTlp(tlpCmd) {
        // Use setsid to fully detach pkexec from this QML scene.
        var cmd = "setsid -f pkexec /usr/bin/tlp " + tlpCmd;
        Logger.i("BatteryMode", "spawning tlp:", cmd);
        Quickshell.execDetached(["sh", "-c", cmd]);
        forceRefreshTimer.restart();
    }

    function _notifyNoAc() {
        if (typeof ToastService !== "undefined" && ToastService.showError) {
            ToastService.showError(
                "Carregador não conectado",
                "Conecte o carregador antes de mudar para Standard (100%).");
        } else {
            Quickshell.execDetached(["notify-send",
                "-a", "Battery Charge Mode",
                "-u", "critical",
                "Carregador não conectado",
                "Conecte o carregador antes de mudar para Standard (100%)."]);
        }
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
