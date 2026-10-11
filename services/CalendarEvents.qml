import QtQuick
import Quickshell.Io
import "../lib/Scripts.js" as Scripts

// Calendar data: read, added and removed through scripts/calendar-sync.py
// (~/.config/archisland/calendar-events.json). The calendar view and the "next
// event" pill use the same data. Nothing runs while the module is off.
Item {
  id: calendar
  required property bool enabled
  required property string pluginDir
  // The island's minute clock; the next event is recomputed with it.
  required property var now

  property var events: []
  property int eventsCount: 0

  // The first timed event starting within the next hour (null if none).
  readonly property var nextEvent: {
    if (!enabled) return null
    var t = now ? now.getTime() : Date.now()
    var best = null
    for (var i = 0; i < events.length; i++) {
      var start = startOf(events[i])
      if (!start) continue
      var diff = start.getTime() - t
      if (diff < 0 || diff > 3600000) continue
      if (!best || start < best.start) best = { start: start, summary: String(events[i].summary || "Event"), minutes: Math.ceil(diff / 60000) }
    }
    return best
  }

  // "YYYY-MM-DD" + "HH:MM" → Date; null for all-day events.
  function startOf(ev) {
    var d = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(ev.date || ""))
    var h = /^(\d{1,2}):(\d{2})$/.exec(String(ev.time || ""))
    if (!d || !h) return null
    return new Date(Number(d[1]), Number(d[2]) - 1, Number(d[3]), Number(h[1]), Number(h[2]))
  }

  function eventsOn(dateStr) {
    return events.filter(function(ev) { return ev.date === dateStr })
  }

  function sync() {
    if (enabled && !syncProc.running) syncProc.running = true
  }
  function add(dateStr, timeStr, title) {
    title = String(title || "").trim()
    if (!enabled || !title) return
    var time = String(timeStr || "").trim() || "All day"
    writeProc.command = Scripts.command(pluginDir, "calendar-sync.py", ["add", dateStr, time, title])
    writeProc.running = true
  }
  function remove(idOrSummary) {
    if (!enabled || !idOrSummary) return
    writeProc.command = Scripts.command(pluginDir, "calendar-sync.py", ["delete", String(idOrSummary)])
    writeProc.running = true
  }

  Process {
    id: syncProc
    command: Scripts.command(calendar.pluginDir, "calendar-sync.py", [])
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          calendar.events = data.events || []
          calendar.eventsCount = data.eventsCount || calendar.events.length
        } catch (e) {}
      }
    }
  }

  // The list is re-read when an add/remove finishes.
  Process {
    id: writeProc
    onExited: calendar.sync()
  }

  // Sync every five minutes (if there is a remote iCal URL).
  Timer {
    interval: 300000
    running: calendar.enabled
    repeat: true
    triggeredOnStart: true
    onTriggered: calendar.sync()
  }
  onEnabledChanged: if (!enabled) { events = []; eventsCount = 0 }
}
