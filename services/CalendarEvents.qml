import QtQuick
import Quickshell.Io
import "../lib/Scripts.js" as Scripts

// Takvim verisi: scripts/calendar-sync.py ile okunur, eklenir ve silinir
// (~/.config/archisland/calendar-events.json). Takvim görünümü ve "sıradaki
// etkinlik" hapı aynı veriyi kullanır. Modül kapalıyken hiçbir şey çalışmaz.
Item {
  id: calendar
  required property bool enabled
  required property string pluginDir
  // Island'ın dakikalık saati; sıradaki etkinlik bununla yeniden hesaplanır.
  required property var now

  property var events: []
  property int eventsCount: 0

  // Önümüzdeki bir saat içinde başlayacak ilk saatli etkinlik (yoksa null).
  readonly property var nextEvent: {
    if (!enabled) return null
    var t = now ? now.getTime() : Date.now()
    var best = null
    for (var i = 0; i < events.length; i++) {
      var start = startOf(events[i])
      if (!start) continue
      var diff = start.getTime() - t
      if (diff < 0 || diff > 3600000) continue
      if (!best || start < best.start) best = { start: start, summary: String(events[i].summary || "Etkinlik"), minutes: Math.ceil(diff / 60000) }
    }
    return best
  }

  // "YYYY-AA-GG" + "SS:DD" → Date; tüm gün etkinliklerinde null.
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
    var time = String(timeStr || "").trim() || "Tüm gün"
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

  // Ekleme/silme bitince liste yeniden okunur.
  Process {
    id: writeProc
    onExited: calendar.sync()
  }

  // Beş dakikada bir (uzak iCal adresi varsa) eşitle.
  Timer {
    interval: 300000
    running: calendar.enabled
    repeat: true
    triggeredOnStart: true
    onTriggered: calendar.sync()
  }
  onEnabledChanged: if (!enabled) { events = []; eventsCount = 0 }
}
