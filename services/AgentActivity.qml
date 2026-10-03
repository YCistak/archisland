import QtQuick

// Kodlama ajanlarının (Claude Code, Antigravity/Gemini, Codex) anlık durumu.
// Durumu ajanların kancaları (hooks/) island IPC'si üzerinden bildirir:
//   archisland-shell guilhermerisu.island agent <ajan> <working|waiting|done|idle> <oturum>
// Her oturum ayrı tutulur; aynı ajanın birden çok oturumu olabilir.
// "working" bildirimi 5 dakika tazelenmezse oturum bayat sayılıp düşürülür.
Item {
  id: agents
  property bool enabled: false

  // Ajan kimliği → görünen ad ve renk.
  readonly property var adlar: ({ claude: "Claude", agy: "Antigravity", gemini: "Gemini", codex: "Codex" })
  readonly property var renkler: ({ claude: "#d97757", agy: "#60a5fa", gemini: "#60a5fa", codex: "#9ca3af" })
  function ad(ajan) { return adlar[ajan] || ajan }
  function renk(ajan) { return renkler[ajan] || "#e2e6de" }

  // "ajan/oturum" → { ajan, durum: "working"|"waiting", zaman }
  property var oturumlar: ({})
  readonly property int bayatSure: 5 * 60 * 1000

  readonly property var liste: {
    var out = []
    for (var k in oturumlar) out.push(oturumlar[k])
    return out
  }
  readonly property int sayi: liste.length
  readonly property bool bekleyenVar: liste.some(function(o) { return o.durum === "waiting" })
  // Tek ajan türü varsa onun adı, karışıksa boş.
  readonly property string tekAjan: {
    var a = ""
    for (var i = 0; i < liste.length; i++) {
      if (a !== "" && a !== liste[i].ajan) return ""
      a = liste[i].ajan
    }
    return a
  }
  readonly property string ozet: {
    if (sayi === 0) return ""
    if (bekleyenVar) {
      var b = liste.filter(function(o) { return o.durum === "waiting" })[0]
      return ad(b.ajan) + " onay bekliyor"
    }
    if (sayi === 1) return ad(liste[0].ajan) + " çalışıyor"
    return sayi + " ajan çalışıyor"
  }
  readonly property color ozetRenk: tekAjan !== "" ? renk(tekAjan) : "#e2e6de"

  // Son biten ajan: "bitti" banner'ı bunu gösterir.
  property string sonBiten: ""
  signal bitti(string ajan)

  function oturumListesi() {
    var out = []
    for (var k in oturumlar) {
      var o = oturumlar[k]
      var sn = Math.round((Date.now() - o.zaman) / 1000)
      out.push(k + " (" + o.durum + ", " + sn + "s once)")
    }
    return out.length ? out.join(", ") : "aktif ajan yok"
  }

  function bildir(ajan, durum, oturum) {
    ajan = String(ajan || "").toLowerCase()
    durum = String(durum || "").toLowerCase()
    oturum = String(oturum || "varsayilan")
    if (!enabled) return "kapali"
    if (durum === "list" || durum === "status" || ajan === "list") {
      return oturumListesi()
    }
    if (ajan === "clear" || durum === "clear" || durum === "reset") {
      oturumlar = ({})
      return "temizlendi"
    }
    if (!ajan) return "hata: ajan adı yok"
    var anahtar = ajan + "/" + oturum
    var kopya = Object.assign({}, oturumlar)
    if (durum === "working" || durum === "waiting") {
      kopya[anahtar] = { ajan: ajan, durum: durum, zaman: Date.now() }
    } else if (durum === "done") {
      var vardi = !!kopya[anahtar]
      delete kopya[anahtar]
      oturumlar = kopya
      sonBiten = ajan
      bitti(ajan)
      return vardi ? "bitti" : "bitti (oturum bilinmiyordu)"
    } else if (durum === "idle") {
      if (oturum === "all" || oturum === "*" || oturum === "varsayilan") {
        for (var k in kopya) {
          if (kopya[k].ajan === ajan) delete kopya[k]
        }
      } else {
        delete kopya[anahtar]
      }
    } else {
      return "hata: durum working|waiting|done|idle|clear|reset olmalı"
    }
    oturumlar = kopya
    return durum
  }

  onEnabledChanged: if (!enabled) oturumlar = ({})

  // Bayat oturumları düşür.
  Timer {
    interval: 15000
    repeat: true
    running: agents.enabled && agents.sayi > 0
    onTriggered: {
      var simdi = Date.now(), kopya = {}, degisti = false
      for (var k in agents.oturumlar) {
        if (simdi - agents.oturumlar[k].zaman > agents.bayatSure) degisti = true
        else kopya[k] = agents.oturumlar[k]
      }
      if (degisti) agents.oturumlar = kopya
    }
  }
}
