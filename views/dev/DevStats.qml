import QtQuick
import Quickshell.Io
import "../../lib/Scripts.js" as Scripts

// Geliştirici görünümünün verisi: scripts/corner-stats.sh yalnız görünüm
// açıkken ve yalnız açık modüller için (ARCHISLAND_MODULES) çalışır.
QtObject {
  id: stats
  required property var host
  property bool active: false

  readonly property bool showAi: !!host.settings.aiQuota
  readonly property bool showDocker: !!host.settings.docker
  readonly property bool showPorts: !!host.settings.devPorts
  readonly property bool showPr: !!host.settings.githubPrs
  readonly property bool any: showAi || showDocker || showPorts || showPr

  property var claude: ({ session: 0, weekly: 0, opus: 0, sonnet: 0 })
  property var antigravity: ({ session: 0, weekly: 0, burn: "", session3p: 0, weekly3p: 0, burn3p: "" })
  property int codexSession: 0
  property var containers: []
  property var ports: []
  property bool loaded: false

  function apply(data) {
    if (!data) return
    if (data.claude) claude = data.claude
    host.aiQuota.guncelle(data)
    if (data.antigravity) antigravity = data.antigravity
    if (data.codex) codexSession = data.codex.session || 0
    if (data.docker) containers = data.docker.containers || []
    if (data.ports) ports = data.ports.list || []
    loaded = true
  }
  // PR listesi PrSection'da ayrıca çekilir; burada yalnız kota/docker/port.
  readonly property bool needsStats: showAi || showDocker || showPorts
  function refresh() {
    if (needsStats && !statsProc.running) statsProc.running = true
  }
  // Docker/port eylemleri: ayrık çalışır, az sonra veri tazelenir.
  function run(command) {
    actionProc.command = command
    actionProc.startDetached()
    refreshSoon.restart()
  }
  function script(name, args) { return Scripts.command(host.setup.pluginDir, name, args) }

  onActiveChanged: if (active) refresh()

  property Process statsProc: Process {
    command: stats.script("corner-stats.sh", [])
    environment: ({
      ARCHISLAND_MODULES: [stats.showAi ? "ai" : "", stats.showDocker ? "docker" : "",
        stats.showPorts ? "ports" : ""].filter(function(x) { return x }).join(",")
    })
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try { stats.apply(JSON.parse(text)) } catch (e) {}
      }
    }
  }
  property Process actionProc: Process {}
  property Timer refreshSoon: Timer { interval: 800; onTriggered: stats.refresh() }
  // Açıkken 15 saniyede bir tazele.
  property Timer poll: Timer {
    interval: 15000
    running: stats.active && stats.needsStats
    repeat: true
    onTriggered: stats.refresh()
  }
}
