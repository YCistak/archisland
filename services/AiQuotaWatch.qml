import QtQuick
import Quickshell
import Quickshell.Io
import "../lib/Scripts.js" as Scripts

// AI quota alert (aiQuota module): Claude, Antigravity and Codex quota is
// polled in the background every 5 minutes (scripts/corner-stats.sh, "ai" only).
// When the remaining share of any window (5-hour/weekly) drops below the
// aiQuotaWarnPercent threshold in island.json, `alert` is set. The alert is
// ONE-SHOT: it appears on the main island and closes on click (dismiss) or
// when its time (aiQuotaAlertSeconds) runs out, and never shows again for that
// agent. If the quota rises above the threshold (resets), the agent's "shown"
// record is removed, and the alert shows again when it drops below once more.
// The record is kept in ~/.local/state/archisland/ai-quota-shown.json so it
// survives shell restarts. Fresh data arriving while the developer view is
// open is passed in through `ingest` too.
Item {
  id: quota
  property bool enabled: false
  property string pluginDir: ""
  property int threshold: 20

  // Used percentages (0–100); missing data counts as 0 and raises no alert.
  property var usage: null

  // Agents below the threshold: { agent: { agent, name, left } } — the window
  // with the least left for each agent.
  readonly property var below: {
    var r = {}
    if (!enabled || !usage) return r
    function add(agent, name, used) {
      used = Number(used || 0)
      if (used <= 0) return
      var left = Math.max(0, 100 - Math.round(used))
      if (left < threshold && (!r[agent] || left < r[agent].left)) r[agent] = { agent: agent, name: name, left: left }
    }
    var c = usage.claude || {}, a = usage.antigravity || {}, x = usage.codex || {}
    add("claude", "Claude", c.session); add("claude", "Claude", c.weekly)
    add("agy", "Antigravity", a.session); add("agy", "Antigravity", a.weekly)
    add("codex", "Codex", x.session)
    return r
  }

  // The one-shot alert to show right now: { agent, name, left } or null.
  property var alert: null
  // Agents whose alert has already been shown: { agent: true }.
  property var shown: ({})
  readonly property string label: alert ? alert.name + " " + alert.left + "% left" : ""

  readonly property string shownPath: Quickshell.env("HOME") + "/.local/state/archisland/ai-quota-shown.json"
  FileView {
    id: statsCache
    path: "/tmp/archisland-corner-stats.json"
    blockLoading: true
    printErrors: false
    onLoaded: {
      try {
        var d = JSON.parse(text())
        if (d && (d.claude || d.antigravity || d.codex)) {
          quota.usage = d
          quota.evaluate()
        }
      } catch (e) {}
    }
  }

  FileView {
    id: shownFile
    path: quota.shownPath
    blockLoading: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        var g = JSON.parse(text())
        if (g && typeof g === "object") quota.shown = g
      } catch (e) {}
      quota.evaluate()
    }
  }
  function saveShown() {
    shownFile.setText(JSON.stringify(shown) + "\n")
  }

  // Remove the record of agents back above the threshold and pick the next
  // alert if needed.
  function evaluate() {
    // While there is no data yet (at startup, before the first poll) do not
    // treat everything as "above the threshold" and wipe the record;
    // otherwise the alert shows again after every restart and locks the main
    // island (bubble clicks stop working).
    if (!enabled || !usage) return
    var g = Object.assign({}, shown), changed = false
    for (var k in g) if (!below[k]) { delete g[k]; changed = true }
    if (changed) { shown = g; saveShown() }
    if (alert && !below[alert.agent]) alert = null
    if (alert) return
    for (var agent in below) if (!shown[agent]) { alert = below[agent]; return }
  }
  onBelowChanged: evaluate()

  // Close the alert (click or timeout): it never shows again for this agent.
  function dismiss() {
    if (!alert) return
    var g = Object.assign({}, shown)
    g[alert.agent] = true
    shown = g
    saveShown()
    alert = null
    evaluate()
  }

  // An agent's usage percentages (for the agent done card):
  // { session, weekly } — weekly is -1 when missing; null without data/module.
  function limits(agent) {
    if (!enabled || !usage) return null
    var d = agent === "claude" ? usage.claude
      : agent === "agy" || agent === "gemini" ? usage.antigravity
      : agent === "codex" ? usage.codex : null
    if (!d) return null
    var s = Number(d.session || 0), w = d.weekly === undefined ? -1 : Number(d.weekly || 0)
    if (s <= 0 && w <= 0) return null
    return { session: Math.round(s), weekly: w < 0 ? -1 : Math.round(w) }
  }

  function ingest(data) {
    if (data && (data.claude || data.antigravity || data.codex)) usage = data
  }
  function poll() {
    if (enabled && !proc.running) proc.running = true
  }

  onEnabledChanged: if (!enabled) usage = null

  Process {
    id: proc
    command: Scripts.command(quota.pluginDir, "corner-stats.sh", [])
    environment: ({ ARCHISLAND_MODULES: "ai" })
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try { quota.ingest(JSON.parse(text)) } catch (e) {}
      }
    }
  }
  Timer {
    interval: 5 * 60 * 1000
    repeat: true
    running: quota.enabled
    triggeredOnStart: true
    onTriggered: quota.poll()
  }
}
