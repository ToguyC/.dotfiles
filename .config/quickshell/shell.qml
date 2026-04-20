//─────────────────────────────────────────────────────────────
// shell.qml — single-file btop-style bar for Hyprland
//
// Features: workspaces, clock, volume, brightness, battery,
// network, cpu/ram, system tray.
//
// Helpers needed on the system:
//   brightnessctl, nmcli (NetworkManager), nm-connection-editor
//   JetBrainsMono Nerd Font (or change theme.fontMono below)
//─────────────────────────────────────────────────────────────

//@ pragma UseQApplication

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Scope {
    id: root

    //═════════════════════════════════════════════════════════
    //  THEME — btop-inspired palette, font, geometry
    //═════════════════════════════════════════════════════════

    //═════════════════════════════════════════════════════════
    //  INLINE COMPONENTS — the `component Foo: Base { ... }`
    //  syntax defines a reusable type scoped to this file.
    //═════════════════════════════════════════════════════════
  QtObject {
    id: theme

    // Base
    readonly property color bg:        "#0f1114"
    readonly property color bgAlt:     "#1a1d23"
    readonly property color border:    "#2a2f38"
    readonly property color dim:       "#5c6370"

    // Foreground
    readonly property color fg:        "#c8ccd4"
    readonly property color fgBright:  "#eef0f4"

    // Accents (semantic)
    readonly property color accent:    "#66d9ef"   // cyan — info, network, mpris
    readonly property color active:    "#a6e22e"   // green — focus, success, vpn
    readonly property color warn:      "#f4bf75"   // orange — caution, brightness
    readonly property color alert:     "#f92672"   // magenta — errors, low battery
    readonly property color purple:    "#ae81ff"   // RAM module
    readonly property color yellow:    "#f4d03f"   // CPU module

    // Monospace font
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property int    fontSize: 12

    // Layout
    readonly property int barHeight: 26
    readonly property int padding:   8
    readonly property int gap:       10
}

    //── A single "[" or "]" bracket ───────────────────────
    component Bracket: Text {
        color: theme.dim
        font.family: theme.fontMono
        font.pixelSize: theme.fontSize
        anchors.verticalCenter: parent.verticalCenter
    }

    //── A framed text block:  [ icon text ] ───────────────
    component Module: Row {
        id: modRoot
        property string text: ""
        property color  textColor: theme.fg
        property string icon: ""
        property color  iconColor: theme.accent
        spacing: 4

        Bracket { text: "[" }

        Text {
            visible: modRoot.icon.length > 0
            text: modRoot.icon
            color: modRoot.iconColor
            font.family: theme.fontMono
            font.pixelSize: theme.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: modRoot.text
            color: modRoot.textColor
            font.family: theme.fontMono
            font.pixelSize: theme.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Bracket { text: "]" }
    }

    //── Workspaces (Hyprland) ─────────────────────────────
    component Workspaces: Row {
        id: wsRoot
        required property var screen
        // Always render at least this many slots, even if the
        // workspace doesn't exist yet in Hyprland (so 1..3 are
        // always visible on startup). The Repeater will grow
        // beyond this if you create higher-numbered workspaces.
        property int minCount: 3
        spacing: 6

        readonly property var myMon: Hyprland.monitorFor(wsRoot.screen)

        // Highest workspace id that currently exists on this monitor.
        // Used to decide how many slots to draw past minCount.
        readonly property int highestOnThisMon: {
            let max = 0
            const list = Hyprland.workspaces.values
            if (list) {
                for (let i = 0; i < list.length; ++i) {
                    const w = list[i]
                    if (!w || !w.monitor || !myMon) continue
                    if (w.monitor.id !== myMon.id) continue
                    if (w.id > max) max = w.id
                }
            }
            return max
        }

        readonly property int slotCount: Math.max(minCount, highestOnThisMon)

        // Does workspace `id` exist on this monitor right now?
        // (i.e. is it in Hyprland's list and assigned to myMon)
        function _wsExists(id) {
            const list = Hyprland.workspaces.values
            if (!list) return false
            for (let i = 0; i < list.length; ++i) {
                const w = list[i]
                if (!w || !w.monitor || !myMon) continue
                if (w.id === id && w.monitor.id === myMon.id) return true
            }
            return false
        }

        Bracket { text: "[" }

        Repeater {
            id: rep
            // model is an integer → `index` is 0..N-1 in the delegate
            model: wsRoot.slotCount

            delegate: Item {
                id: slot
                required property int index
                readonly property int wsId: index + 1
                readonly property bool exists: wsRoot._wsExists(wsId)
                readonly property bool isActive:
                    Hyprland.focusedWorkspace
                    && Hyprland.focusedWorkspace.id === wsId

                implicitWidth: label.implicitWidth + 6
                implicitHeight: label.implicitHeight
                width: implicitWidth
                height: implicitHeight
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: slot.wsId
                    font.family: theme.fontMono
                    font.pixelSize: theme.fontSize
                    font.bold: slot.isActive
                    // Active = green, existing-but-not-active = fg, empty = dim
                    color: slot.isActive ? theme.active
                         : slot.exists   ? theme.fg
                         :                 theme.dim
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + slot.wsId)
                }
            }
        }

        Bracket { text: "]" }
    }

    //── Clock ─────────────────────────────────────────────
    component Clock: Row {
        spacing: 4

        SystemClock {
            id: sysclock
            precision: SystemClock.Minutes
        }

        Bracket { text: "[" }

        Text {
            text: Qt.formatDateTime(sysclock.date, "ddd dd")
            color: theme.fg
            font.family: theme.fontMono
            font.pixelSize: theme.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: "·"
            color: theme.dim
            font.family: theme.fontMono
            font.pixelSize: theme.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: Qt.formatDateTime(sysclock.date, "hh:mm")
            color: theme.fgBright
            font.family: theme.fontMono
            font.pixelSize: theme.fontSize
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }

        Bracket { text: "]" }
    }

    //── MPRIS (now playing) ───────────────────────────────
    // Click = play/pause, scroll = prev/next, middle-click = raise.
    // Hides itself when no player is active.
    component Mpris: MouseArea {
        id: mprisRoot
        implicitWidth: mod.implicitWidth
        implicitHeight: mod.implicitHeight
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        // Pick the first player that's actually playing; otherwise
        // fall back to the first one that exists (so paused tracks
        // still show up).
        readonly property var player: {
            const list = Mpris.players.values
            if (!list || list.length === 0) return null
            for (const p of list) if (p && p.isPlaying) return p
            return list[0]
        }
        readonly property bool has: player !== null
        visible: has

        // Accumulator so trackpads don't skip 5 songs per flick
        property real _scrollAccum: 0

        Module {
            id: mod
            icon: mprisRoot.has && mprisRoot.player.isPlaying ? "󰐊" : "󰏤"
            iconColor: theme.accent
            text: {
                if (!mprisRoot.has) return ""
                const p = mprisRoot.player
                const title  = p.trackTitle  || "Unknown"
                const artist = p.trackArtist || ""
                const joined = artist ? (artist + " — " + title) : title
                // Truncate so the bar doesn't grow without bound on long titles
                return joined.length > 40 ? joined.slice(0, 39) + "…" : joined
            }
            textColor: theme.fg
        }

        onClicked: mouse => {
            if (!has) return
            if (mouse.button === Qt.LeftButton) {
                if (player.canTogglePlaying) player.togglePlaying()
            } else if (mouse.button === Qt.MiddleButton) {
                if (player.canRaise) player.raise()
            }
        }

        onWheel: wheel => {
            if (!has) return
            const dy = wheel.angleDelta.y + wheel.pixelDelta.y
            if (dy === 0) return
            _scrollAccum += dy
            const threshold = 120
            while (_scrollAccum >= threshold) {
                if (player.canGoPrevious) player.previous()
                _scrollAccum -= threshold
            }
            while (_scrollAccum <= -threshold) {
                if (player.canGoNext) player.next()
                _scrollAccum += threshold
            }
            wheel.accepted = true
        }
    }

    //── VPN indicator ─────────────────────────────────────
    // Hidden when no VPN interface is active; shows a small
    // "[ 󰦝 VPN name ]" badge when one is up. Iface names like
    // tun0, tun1, wg0, wg1, proton0, nordlynx, ppp0, ...
    component Vpn: Item {
        id: vpnRoot
        implicitWidth:  mod.implicitWidth
        implicitHeight: mod.implicitHeight

        // Name of the active VPN interface, or "" if none
        property string iface: ""
        readonly property bool active: iface.length > 0
        visible: active

        Module {
            id: mod
            icon: "󰦝"
            iconColor: theme.active   // green — on-theme for "protected"
            text: vpnRoot.iface
            textColor: theme.fg
        }

        // /proc/net/dev lists all interfaces, one per line.
        // We pick the first whose name matches a VPN-ish prefix.
        FileView {
            id: vpnDev
            path: "/proc/net/dev"
            blockLoading: false
            onTextChanged: {
                const lines = vpnDev.text().split("\n")
                const vpnRe = /^(tun|tap|wg|proton|nordlynx|ppp)\d*$/
                let found = ""
                // First two lines are headers in /proc/net/dev
                for (let i = 2; i < lines.length; ++i) {
                    const trimmed = lines[i].trim()
                    if (!trimmed) continue
                    const name = trimmed.split(":")[0].trim()
                    if (vpnRe.test(name)) { found = name; break }
                }
                vpnRoot.iface = found
            }
        }

        Timer {
            interval: 3000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: vpnDev.reload()
        }
    }

    //── Volume (Pipewire default sink) ────────────────────
    component Volume: MouseArea {
        id: volRoot
        implicitWidth: mod.implicitWidth
        implicitHeight: mod.implicitHeight
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton

        // PwObjectTracker is required — audio properties are
        // invalid on nodes that aren't tracked.
        PwObjectTracker { objects: [ Pipewire.defaultAudioSink ] }

        readonly property var sink: Pipewire.defaultAudioSink
        readonly property bool hasSink: sink !== null && sink.audio !== null
        readonly property int  percent: hasSink ? Math.round(sink.audio.volume * 100) : 0
        readonly property bool muted:   hasSink ? sink.audio.muted : true

        // Accumulated scroll distance between steps.
        // 120 = one traditional mouse-wheel notch.
        property real _scrollAccum: 0

        Module {
            id: mod
            icon:      volRoot.muted ? "󰝟" : (volRoot.percent > 50 ? "󰕾" : "󰖀")
            iconColor: volRoot.muted ? theme.dim : theme.accent
            text:      volRoot.muted ? "mute" : (volRoot.percent + "%")
            textColor: volRoot.muted ? theme.dim : theme.fg
        }

        onClicked: mouse => {
            if (hasSink && mouse.button === Qt.LeftButton)
                sink.audio.muted = !sink.audio.muted
        }

        onWheel: wheel => {
            if (!hasSink) return
            // angleDelta (wheels, 120/notch) + pixelDelta (trackpads, px).
            const dy = wheel.angleDelta.y + wheel.pixelDelta.y
            if (dy === 0) return

            _scrollAccum += dy
            const threshold = 120   // one wheel notch worth of scroll
            const step = 0.05

            while (_scrollAccum >= threshold) {
                sink.audio.volume = Math.min(1, sink.audio.volume + step)
                _scrollAccum -= threshold
            }
            while (_scrollAccum <= -threshold) {
                sink.audio.volume = Math.max(0, sink.audio.volume - step)
                _scrollAccum += threshold
            }

            wheel.accepted = true
        }
    }

    //── Brightness (brightnessctl) ────────────────────────
    component Brightness: MouseArea {
        id: brRoot
        implicitWidth: mod.implicitWidth
        implicitHeight: mod.implicitHeight
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.NoButton

        // What the UI shows (updated instantly on every scroll tick)
        property int percent: 0
        // What we last *told* brightnessctl to set
        property int pendingPercent: -1
        // True while a scroll burst is active; pauses the poll timer
        // so it doesn't clobber the live value mid-scroll.
        property bool scrolling: false
        // Accumulated scroll distance between steps (120 = one notch)
        property real _scrollAccum: 0

        Module {
            id: mod
            icon: "󰖨"
            iconColor: theme.warn
            text:  brRoot.percent + "%"
            textColor: theme.fg
        }

        // Background poll — refreshes if brightness is changed by
        // something else (Fn keys, another tool). Paused during scroll.
        Timer {
            interval: 2000
            running: !brRoot.scrolling
            repeat: true
            triggeredOnStart: true
            onTriggered: getProc.running = true
        }

        Process {
            id: getProc
            command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
            stdout: StdioCollector {
                id: brStdout
                onStreamFinished: {
                    const n = parseInt(brStdout.text.trim(), 10)
                    // Don't overwrite what the user just asked for
                    if (!isNaN(n) && !brRoot.scrolling) brRoot.percent = n
                }
            }
        }

        // Debounce: many scroll ticks → one brightnessctl call.
        // The timer restarts on every tick; once the user stops
        // for ~40ms we fire the actual write.
        Timer {
            id: writeTimer
            interval: 40
            repeat: false
            onTriggered: {
                if (brRoot.pendingPercent < 0) return
                setProc.command = ["brightnessctl", "-q",
                                   "set", brRoot.pendingPercent + "%"]
                setProc.running = true
                brRoot.pendingPercent = -1
            }
        }

        // Ends the scroll burst a bit after the last tick
        Timer {
            id: scrollEndTimer
            interval: 300
            repeat: false
            onTriggered: brRoot.scrolling = false
        }

        Process { id: setProc; command: ["true"] }

        onWheel: wheel => {
            const dy = wheel.angleDelta.y + wheel.pixelDelta.y
            if (dy === 0) return

            _scrollAccum += dy
            const threshold = 120   // one wheel notch
            let next = brRoot.percent
            let stepped = false

            while (_scrollAccum >= threshold) {
                next = Math.min(100, next + 5)
                _scrollAccum -= threshold
                stepped = true
            }
            while (_scrollAccum <= -threshold) {
                next = Math.max(1, next - 5)
                _scrollAccum += threshold
                stepped = true
            }

            if (stepped) {
                // 1. Optimistic UI update
                brRoot.percent = next
                brRoot.pendingPercent = next
                // 2. Debounce the actual brightnessctl write
                brRoot.scrolling = true
                writeTimer.restart()
                scrollEndTimer.restart()
            }

            wheel.accepted = true
        }
    }

    //── Battery (UPower) ──────────────────────────────────
    component Battery: Item {
        id: batRoot
        implicitWidth:  mod.implicitWidth
        implicitHeight: mod.implicitHeight

        readonly property var dev: UPower.displayDevice
        readonly property bool present: dev && dev.ready && dev.isLaptopBattery
        visible: present

        readonly property int  percent: present ? Math.round(dev.percentage * 100) : 0
        readonly property bool charging: UPower.onBattery === false

        readonly property color batColor:
              percent > 60 ? theme.active
            : percent > 25 ? theme.warn
            : theme.alert

        readonly property string batIcon:
              charging     ? "󰂄"
            : percent > 80 ? "󰁹"
            : percent > 60 ? "󰂂"
            : percent > 40 ? "󰂀"
            : percent > 20 ? "󰁾"
            :                "󰁺"

        Module {
            id: mod
            icon:      batRoot.batIcon
            iconColor: batRoot.batColor
            text:      batRoot.percent + "%"
            textColor: theme.fg
        }
    }

    //── Network (rx/tx speed from /sys, no click action) ──
    component Network: Item {
        id: netRoot
        implicitWidth:  mod.implicitWidth
        implicitHeight: mod.implicitHeight

        // Name of the default-route interface (empty if offline)
        property string iface: ""
        // Current rates in bytes/sec
        property real rxRate: 0
        property real txRate: 0
        // Previous byte totals for diff; -1 means "no prior sample"
        property real _prevRx: -1
        property real _prevTx: -1

        readonly property bool online: iface.length > 0
        readonly property real intervalSec: 1.0   // keep in sync with the Timer

        // ── UI ────────────────────────────────────────────
        Module {
            id: mod
            icon: netRoot.online ? "󰓅" : "󰖪"
            iconColor: netRoot.online ? theme.accent : theme.dim
            text: netRoot.online
                ? ("↓" + netRoot._fmt(netRoot.rxRate)
                   + " ↑" + netRoot._fmt(netRoot.txRate))
                : "offline"
            textColor: netRoot.online ? theme.fg : theme.dim
        }

        // Format a bytes/sec rate as a short human string.
        // Uses decimal Mb/s (megabits/second) which is what
        // people typically expect from a "network speed" readout.
        function _fmt(bytesPerSec) {
            const mbps = bytesPerSec * 8 / 1_000_000
            if (mbps >= 100) return mbps.toFixed(0) + "Mb"
            if (mbps >= 10)  return mbps.toFixed(1) + "Mb"
            if (mbps >= 1)   return mbps.toFixed(2) + "Mb"
            const kbps = bytesPerSec * 8 / 1_000
            if (kbps >= 1)   return kbps.toFixed(0) + "Kb"
            return "0"
        }

        // ── Data sources ─────────────────────────────────
        // /proc/net/route first line is a header, then tab/space
        // separated rows. Default route has Destination "00000000".
        FileView {
            id: routeFile
            path: "/proc/net/route"
            blockLoading: false
            onTextChanged: {
                const lines = routeFile.text().split("\n")
                let found = ""
                for (let i = 1; i < lines.length; ++i) {
                    const cols = lines[i].trim().split(/\s+/)
                    if (cols.length >= 2 && cols[1] === "00000000") {
                        found = cols[0]
                        break
                    }
                }
                if (found !== netRoot.iface) {
                    // Interface changed (connected, disconnected, roamed)
                    // Reset accumulators so the next sample doesn't spike.
                    netRoot.iface = found
                    netRoot._prevRx = -1
                    netRoot._prevTx = -1
                    rxFile.path = found ? "/sys/class/net/" + found + "/statistics/rx_bytes" : ""
                    txFile.path = found ? "/sys/class/net/" + found + "/statistics/tx_bytes" : ""
                }
            }
        }

        FileView {
            id: rxFile
            path: ""
            blockLoading: false
        }

        FileView {
            id: txFile
            path: ""
            blockLoading: false
        }

        // Tick once a second: re-resolve the iface (cheap) and sample rates.
        Timer {
            interval: 1000   // must match intervalSec
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                routeFile.reload()
                if (!netRoot.online) {
                    netRoot.rxRate = 0
                    netRoot.txRate = 0
                    return
                }
                rxFile.reload()
                txFile.reload()

                const rx = parseInt(rxFile.text().trim(), 10)
                const tx = parseInt(txFile.text().trim(), 10)
                if (isNaN(rx) || isNaN(tx)) return

                if (netRoot._prevRx >= 0) {
                    netRoot.rxRate = Math.max(0, (rx - netRoot._prevRx) / netRoot.intervalSec)
                    netRoot.txRate = Math.max(0, (tx - netRoot._prevTx) / netRoot.intervalSec)
                }
                netRoot._prevRx = rx
                netRoot._prevTx = tx
            }
        }
    }

    //── CPU + RAM ─────────────────────────────────────────
    //── CPU + RAM ─────────────────────────────────────────
    component CpuRam: Item {
        id: cpuRoot

        // Terminal emulator to launch btop in. Override on instantiation
        // if you don't use kitty (e.g. "alacritty", "foot", "wezterm").
        property string terminal: "kitty"

        implicitWidth:  row.implicitWidth
        implicitHeight: row.implicitHeight

        property real cpuPct: 0
        property real ramPct: 0
        property int  _prevTotal: 0
        property int  _prevIdle:  0

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            spacing: theme.gap

            Module {
                icon: "󰘚"
                iconColor: theme.yellow
                text: "CPU " + Math.round(cpuRoot.cpuPct) + "%"
                textColor:
                      cpuRoot.cpuPct > 85 ? theme.alert
                    : cpuRoot.cpuPct > 60 ? theme.warn
                    :                       theme.fg
            }

            Module {
                icon: "󰍛"
                iconColor: theme.purple
                text: "MEM " + Math.round(cpuRoot.ramPct) + "%"
                textColor:
                      cpuRoot.ramPct > 85 ? theme.alert
                    : cpuRoot.ramPct > 60 ? theme.warn
                    :                       theme.fg
            }
        }

        // Click anywhere on the CPU/MEM strip to open btop in a terminal.
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: btopProc.running = true
        }

        Process {
            id: btopProc
            command: [cpuRoot.terminal, "-e", "btop"]
        }

        FileView {
            id: statFile
            path: "/proc/stat"
            blockLoading: false
            onTextChanged: {
                const line = statFile.text().split("\n")[0]
                const cols = line.trim().split(/\s+/).slice(1).map(Number)
                if (cols.length < 4) return
                const idle  = cols[3] + (cols[4] || 0)
                const total = cols.reduce((a, b) => a + b, 0)

                if (cpuRoot._prevTotal !== 0) {
                    const dT = total - cpuRoot._prevTotal
                    const dI = idle  - cpuRoot._prevIdle
                    if (dT > 0) cpuRoot.cpuPct = 100 * (dT - dI) / dT
                }
                cpuRoot._prevTotal = total
                cpuRoot._prevIdle  = idle
            }
        }

        FileView {
            id: memFile
            path: "/proc/meminfo"
            blockLoading: false
            onTextChanged: {
                let total = 0, avail = 0
                for (const line of memFile.text().split("\n")) {
                    if (line.startsWith("MemTotal:"))
                        total = parseInt(line.split(/\s+/)[1], 10)
                    else if (line.startsWith("MemAvailable:"))
                        avail = parseInt(line.split(/\s+/)[1], 10)
                    if (total && avail) break
                }
                if (total > 0) cpuRoot.ramPct = 100 * (total - avail) / total
            }
        }

        Timer {
            interval: 2000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                statFile.reload()
                memFile.reload()
            }
        }
    }

    //── System tray ───────────────────────────────────────
    component SysTray: RowLayout {
        spacing: 6

        Bracket {
            text: "["
            visible: trayRepeater.count > 0
            anchors.verticalCenter: undefined
            Layout.alignment: Qt.AlignVCenter
        }

        Repeater {
            id: trayRepeater
            model: SystemTray.items

            delegate: MouseArea {
                id: trayItem
                required property SystemTrayItem modelData
                implicitWidth: 18
                implicitHeight: 18
                Layout.alignment: Qt.AlignVCenter
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                IconImage {
                    anchors.fill: parent
                    source: modelData.icon
                    asynchronous: true
                }

                // Quickshell-native menu popup, anchored to this icon.
                // Opens only when opener.menu is set to a real menu handle.
                QsMenuAnchor {
                    id: menuAnchor
                    menu: trayItem.modelData.hasMenu ? trayItem.modelData.menu : null
                    anchor.window: trayItem.QsWindow.window
                    // anchor.rect is interpreted in the window's content-item
                    // coordinate space, so we map from our local space into it.
                    readonly property point _winPos:
                        trayItem.mapToItem(
                            trayItem.QsWindow.window.contentItem, 0, 0)
                    anchor.rect.x: _winPos.x
                    anchor.rect.y: _winPos.y + theme.barHeight
                    anchor.rect.width: trayItem.width
                    anchor.rect.height: trayItem.height
                }

                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        // If the item only offers a menu, show it on left-click too.
                        if (trayItem.modelData.onlyMenu && trayItem.modelData.hasMenu)
                            menuAnchor.open()
                        else
                            trayItem.modelData.activate()
                    } else if (mouse.button === Qt.MiddleButton) {
                        trayItem.modelData.secondaryActivate()
                    } else if (mouse.button === Qt.RightButton
                               && trayItem.modelData.hasMenu) {
                        menuAnchor.open()
                    }
                }
            }
        }

        Bracket {
            text: "]"
            visible: trayRepeater.count > 0
            anchors.verticalCenter: undefined
            Layout.alignment: Qt.AlignVCenter
        }
    }

    //═════════════════════════════════════════════════════════
    //  THE BAR — one PanelWindow per monitor via Variants
    //═════════════════════════════════════════════════════════
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top:   true
                left:  true
                right: true
            }

            implicitHeight: theme.barHeight
            color: theme.bg

            // Thin bottom border for the terminal "frame" look
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 1
                color: theme.border
            }

            Item {
                anchors.fill: parent
                anchors.leftMargin:  theme.padding
                anchors.rightMargin: theme.padding

                // LEFT — workspaces + now-playing + VPN
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: theme.gap

                    Workspaces { screen: modelData }
                    Mpris {}
                    Vpn {}
                }

                // CENTER — clock
                Clock {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter:   parent.verticalCenter
                }

                // RIGHT — system widgets + tray
                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: theme.gap

                    Network    {}
                    CpuRam     {}
                    Volume     {}
                    Brightness {}
                    Battery    {}
                    SysTray    {}
                }
            }
        }
    }
}
