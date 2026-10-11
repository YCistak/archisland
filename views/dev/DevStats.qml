import QtQuick
import Quickshell.Io
import "../../lib/Scripts.js" as Scripts

// Developer view data: scripts/corner-stats.sh runs only while the view is
// open and only for enabled modules (ARCHISLAND_MODULES).
// Thanks to the disk and memory cache the latest data shows with 0 ms delay on open.
Item {
  id: stats
  visible: false
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

  FileView {
    id: statsCacheFile
    path: "/tmp/archisland-corner-stats.json"
    blockLoading: true
    printErrors: false
    onLoaded: {
      try {
        var d = JSON.parse(text())
        if (d) stats.apply(d)
      } catch (e) {}
    }
  }

  function apply(data) {
    if (!data) return
    if (data.claude) claude = data.claude
    if (host.aiQuota) host.aiQuota.ingest(data)
    if (data.antigravity) antigravity = data.antigravity
    if (data.codex) codexSession = data.codex.session || 0
    if (data.docker) containers = data.docker.containers || []
    if (data.ports) ports = data.ports.list || []
    loaded = true
  }

  Component.onCompleted: {
    if (host && host.aiQuota && host.aiQuota.usage) {
      apply(host.aiQuota.usage)
    }
    try {
      if (statsCacheFile.text()) {
        var d = JSON.parse(statsCacheFile.text())
        if (d) apply(d)
      }
    } catch (e) {}
  }

  // The PR list is fetched separately in PrSection; here only quota/docker/ports.
  readonly property bool needsStats: showAi || showDocker || showPorts
  function refresh() {
    if (needsStats && !statsProc.running) statsProc.running = true
  }
  // Docker/port actions: run detached, the data refreshes shortly after.
  function run(command) {
    actionProc.command = command
    actionProc.startDetached()
    refreshSoon.restart()
  }
  function script(name, args) { return Scripts.command(host.setup.pluginDir, name, args) }

  onActiveChanged: {
    if (active) {
      // First apply the latest data from memory or disk immediately (0 ms delay):
      if (host && host.aiQuota && host.aiQuota.usage) {
        apply(host.aiQuota.usage)
      }
      try {
        if (statsCacheFile.text()) {
          var d = JSON.parse(statsCacheFile.text())
          if (d) apply(d)
        }
      } catch (e) {}
      // Fetch fresh data in the background
      refresh()
    }
  }

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
  // Refresh every 15 seconds while open.
  property Timer poll: Timer {
    interval: 15000
    running: stats.active && stats.needsStats
    repeat: true
    onTriggered: stats.refresh()
  }
}
