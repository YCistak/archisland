import QtQuick
import Quickshell
import Quickshell.Io
import "../lib/Scripts.js" as Scripts

// AI kota uyarısı (aiQuota modülü): Claude, Antigravity ve Codex kotası
// arka planda 5 dakikada bir yoklanır (scripts/corner-stats.sh, yalnız "ai").
// Herhangi bir pencerede (5 saatlik/haftalık) kalan oran island.json'daki
// aiQuotaWarnPercent eşiğinin altına düşünce `alarm` dolar. Uyarı TEK
// SEFERLİKTİR: ana island'da görünür, tıklanınca (kapat) ya da süresi
// (aiQuotaAlertSeconds) dolunca kapanır ve o ajan için bir daha çıkmaz.
// Kota eşiğin üstüne çıkarsa (yenilenirse) ajanın "gösterildi" kaydı silinir,
// tekrar altına düşünce uyarı yeniden çıkar. Kayıt shell yeniden başlasa da
// kalsın diye ~/.local/state/archisland/ai-quota-shown.json dosyasında tutulur.
// Geliştirici görünümü açıkken gelen taze veri de `guncelle` ile aktarılır.
Item {
  id: quota
  property bool enabled: false
  property string pluginDir: ""
  property int esik: 20

  // Kullanılan yüzdeler (0–100); veri yoksa 0 sayılır, uyarı çıkmaz.
  property var veri: null

  // Eşiğin altındaki ajanlar: { ajan: { ajan, ad, kalan } } — her ajan için
  // en az kalan pencere.
  readonly property var altinda: {
    var r = {}
    if (!enabled || !veri) return r
    function ekle(ajan, ad, kullanilan) {
      kullanilan = Number(kullanilan || 0)
      if (kullanilan <= 0) return
      var kalan = Math.max(0, 100 - Math.round(kullanilan))
      if (kalan < esik && (!r[ajan] || kalan < r[ajan].kalan)) r[ajan] = { ajan: ajan, ad: ad, kalan: kalan }
    }
    var c = veri.claude || {}, a = veri.antigravity || {}, x = veri.codex || {}
    ekle("claude", "Claude", c.session); ekle("claude", "Claude", c.weekly)
    ekle("agy", "Antigravity", a.session); ekle("agy", "Antigravity", a.weekly)
    ekle("codex", "Codex", x.session)
    return r
  }

  // Şu an gösterilecek tek seferlik uyarı: { ajan, ad, kalan } ya da null.
  property var alarm: null
  // Uyarısı zaten gösterilmiş ajanlar: { ajan: true }.
  property var gosterilen: ({})
  readonly property string metin: alarm ? alarm.ad + " %" + alarm.kalan + " kaldı" : ""

  readonly property string kayitYolu: Quickshell.env("HOME") + "/.local/state/archisland/ai-quota-shown.json"
  FileView {
    id: kayit
    path: quota.kayitYolu
    blockLoading: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        var g = JSON.parse(text())
        if (g && typeof g === "object") quota.gosterilen = g
      } catch (e) {}
      quota.degerlendir()
    }
  }
  function kaydet() {
    kayit.setText(JSON.stringify(gosterilen) + "\n")
  }

  // Eşiği aşan ajanların kaydını sil, gerekirse sıradaki uyarıyı seç.
  function degerlendir() {
    var g = Object.assign({}, gosterilen), degisti = false
    for (var k in g) if (!altinda[k]) { delete g[k]; degisti = true }
    if (degisti) { gosterilen = g; kaydet() }
    if (alarm && !altinda[alarm.ajan]) alarm = null
    if (alarm) return
    for (var ajan in altinda) if (!gosterilen[ajan]) { alarm = altinda[ajan]; return }
  }
  onAltindaChanged: degerlendir()

  // Uyarıyı kapat (tıklama ya da süre dolması): bu ajan için bir daha çıkmaz.
  function kapat() {
    if (!alarm) return
    var g = Object.assign({}, gosterilen)
    g[alarm.ajan] = true
    gosterilen = g
    kaydet()
    alarm = null
    degerlendir()
  }

  // Bir ajanın kullanım yüzdeleri (ajan bitti kartı için):
  // { oturum, haftalik } — haftalik yoksa -1; veri/modül yoksa null.
  function limitler(ajan) {
    if (!enabled || !veri) return null
    var d = ajan === "claude" ? veri.claude
      : ajan === "agy" || ajan === "gemini" ? veri.antigravity
      : ajan === "codex" ? veri.codex : null
    if (!d) return null
    var o = Number(d.session || 0), hf = d.weekly === undefined ? -1 : Number(d.weekly || 0)
    if (o <= 0 && hf <= 0) return null
    return { oturum: Math.round(o), haftalik: hf < 0 ? -1 : Math.round(hf) }
  }

  function guncelle(data) {
    if (data && (data.claude || data.antigravity || data.codex)) veri = data
  }
  function yokla() {
    if (enabled && !proc.running) proc.running = true
  }

  onEnabledChanged: if (!enabled) veri = null

  Process {
    id: proc
    command: Scripts.command(quota.pluginDir, "corner-stats.sh", [])
    environment: ({ ARCHISLAND_MODULES: "ai" })
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try { quota.guncelle(JSON.parse(text)) } catch (e) {}
      }
    }
  }
  Timer {
    interval: 5 * 60 * 1000
    repeat: true
    running: quota.enabled
    triggeredOnStart: true
    onTriggered: quota.yokla()
  }
}
