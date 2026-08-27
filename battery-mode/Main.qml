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

        // tlp fullcharge refuses if AC is not connected ("fullcharge is
        // possible on AC power only"). Use Quickshell.execDetached to spawn
        // a synchronous cat that we can read in-process; this avoids
        // FileView's async-load race (text() returns "" before onLoaded
        // fires, which would falsely show the AC-down warning).
        if (tlpCmd === "fullcharge") {
            var ac = "/sys/class/power_supply/ADP0/online";
            var acOnline = Qt.createQmlObject('
                import Quickshell.Io
                Process {
                    stdout: StdioCollector {}
                }
            ', root, "acCheck_" + Date.now());
            acOnline.command = ["sh", "-c", "cat '" + ac + "' 2>/dev/null || echo 0"];
            acOnline.running = true;
            // Polling: small spin while the cat finishes. The file is
            // single-character and the read should complete in <10ms.
            var tries = 0;
            while (!acOnline.stdout.available && tries < 50) {
                acOnline.stdout.waitForReadyRead(10);
                tries++;
            }
            var v = acOnline.stdout.text().trim();
            acOnline.destroy();
            Logger.i("BatteryMode", "AC check: path=", ac, "v=[", v, "]");
            if (v !== "1") {
                // Use noctalia's ToastService so the message appears
                // inside the shell (it doesn't depend on a freedesktop
                // notification daemon being installed).
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
                return;
            }
        }

        // Use setsid to fully detach pkexec from this QML scene (otherwise
        // the broken polkit-agent dialog can deadlock Quickshell.Io.Process).
        var cmd = "setsid -f pkexec /usr/bin/tlp " + tlpCmd;
        Logger.i("BatteryMode", "toggleChargeMode: currentCons=[", currentCons,
                 "] currentMode=", currentMode, "target=", tlpCmd,
                 "cmd=", cmd);
        Quickshell.execDetached(["sh", "-c", cmd]);
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
