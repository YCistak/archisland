import QtQuick

// Canlı etkinlik yöneticisi: island dinlenme hâlindeyken (view "rest") hangi
// kalıcı etkinliğin ana hap, hangisinin yanındaki küçük kabarcık olacağını
// tek yerde seçer. Kural: aynı anda en fazla 1 ana + 2 küçük etkinlik
// (1. kabarcık island'ın sağında, 2. solunda; island dışında başka bir şey açılmaz).
//
// Kalıcı etkinlikler koşulları sürdükçe görünür; öncelik sırası aşağıdaki
// `kalicilar` dizisinin sırasıdır (üstteki kazanır):
//   1. kurulum   — companion eklentisi eksik/bozuk (uyarı metni)
//   2. indirme   — süren ya da yeni biten indirme / paket güncellemesi
//   3. ajanOnay  — bir kodlama ajanı onay bekliyor
//   4. kota      — AI kota uyarısı (tek seferlik, kabarcığı yok; ajan ve
//                  medyayı geçici olarak kabarcığa indirir)
//   5. ajan      — kodlama ajanı çalışıyor
//   6. takvim    — bir saat içinde başlayacak etkinlik
//   7. medya     — müzik/video çalıyor: her zaman en altta; başka bir
//                  etkinlik varsa o island'a geçer, medya kabarcığa iner.
// (Tam öncelik tasarımı ertelendi; şimdilik yalnızca medya en alta alındı.)
//
// Geçici etkinlikler (bildirim, ses, pano, pil/bluetooth, çalışma alanı,
// klavye, "ajan bitti") birkaç saniyelik banner'dır: Island.showFeedback ile
// view "feedback" olur ve süresi dolunca kalıcı etkinliklere geri dönülür.
// Geçici banner açıkken küçük kabarcıklar gizlenir.
//
// Her kalıcı etkinlik: id, aktif (koşul), gorunum (tıklayınca açılan
// görünüm; boşsa Island'daki özel davranış), kucuk (küçük kabarcıkta
// gösterilebilir mi) ve küçük gösterimin simge/metin/renk alanları.
// Medya listenin sonunda durur: en düşük öncelik bu sıralamadan gelir.
//
// Sabitleme (kullanıcı seçimi): bir kabarcığa tıklamak (ya da IPC `swap`)
// o etkinliği ana island'a alır, ana island'daki etkinlik tıklanan
// kabarcığın yerine iner (bkz. degistir). Kural tek yerde, `ana` hesabında:
//   - Sabitlenen etkinlik, koşulu sürdükçe öncelik sırasını ezer; koşulu
//     bitince sabitleme kalkar ve otomatik önceliğe dönülür.
//   - İstisna: dikkat isteyen durum — "onay bekliyor" (ajanOnay) — ve
//     kabarcık gösterimi olmayan etkinlikler (kurulum, indirme; gidecek
//     kabarcıkları yok) yine ana island'a çıkar; sabitleme kalkmaz, onlar
//     bitince geri gelir.
//   - Yeni gelen diğer etkinlikler sabitlemeyi bozmaz, kabarcığa gider.
QtObject {
  id: live
  required property var host

  readonly property var h: host
  readonly property bool dinlenme: h.view === "rest" && !h.setup.needsSetup

  // Her etkinliğin koşulu görünümden bağımsız tutulur (kosul): geçici bir
  // banner (ses, bildirim) dinlenmeyi bozunca sabitleme kalkmasın.
  readonly property var kalicilar: [
    { id: "kurulum", kosul: h.setup.needsSetup, aktif: h.view === "rest" && h.setup.needsSetup, kucuk: false },
    { id: "indirme", kosul: (h.downloads.finishedName !== "" || h.packages.finishedTitle !== ""
        || h.downloads.active || h.packages.active), kucuk: false },
    { id: "ajanOnay", kosul: h.agents.bekleyenVar, kucuk: true, gorunum: "",
      simge: "󰂞", metin: "onay", renk: h.theme.urgent, hareketli: false },
    // Kota uyarısı tek seferlik: kabarcığı yok (kucuk: false), ana island'a
    // çıkar; tıklanınca ya da süresi dolunca kapanır (bkz. AiQuotaWatch).
    { id: "kota", kosul: !!h.aiQuota.alarm, kucuk: false },
    // Ajan sabitlemesi onay beklerken de sürsün diye koşul "en az bir ajan".
    { id: "ajan", kosul: h.agents.sayi > 0, kucuk: true, gorunum: "",
      simge: "", metin: h.agents.sayi > 1 ? String(h.agents.sayi) : "", renk: h.agents.ozetRenk, hareketli: true },
    { id: "takvim", kosul: !!h.calendar.nextEvent, kucuk: true, gorunum: "calendar",
      simge: "󰃭", metin: !h.calendar.nextEvent ? "" : h.calendar.nextEvent.minutes <= 0 ? "now" : h.calendar.nextEvent.minutes + " min",
      renk: h.theme.accent },
    { id: "medya", kosul: h.nowPlaying.playing && !!h.settings.mediaPill, kucuk: true, gorunum: "player",
      simge: "󰝚", metin: "", renk: h.nowPlaying.tint, dalga: true }
  ].map(function(e) {
    if (e.aktif === undefined) e.aktif = dinlenme && e.kosul
    // Onay beklerken "ajan" yerine "ajanOnay" gösterilir.
    if (e.id === "ajan") e.aktif = e.aktif && !h.agents.bekleyenVar
    return e
  })

  readonly property var etkinler: kalicilar.filter(function(e) { return e.aktif })

  // ---------- Sabitleme ----------
  // Kullanıcının ana island'a aldığı etkinlik ("" = otomatik öncelik).
  property string sabit: ""
  // Kabarcıkların kullanıcı yer değiştirmeleriyle oluşan sırası (kimlikler);
  // listede olmayan yeni kabarcıklar öncelik sırasıyla sona eklenir.
  property var kabarcikSirasi: []

  function etkinlik(kimlik) {
    for (var i = 0; i < kalicilar.length; i++) if (kalicilar[i].id === kimlik) return kalicilar[i]
    return null
  }
  function aktifMi(kimlik) { var e = etkinlik(kimlik); return !!e && e.aktif }
  // Sabitlemeyi ezen etkinlik: onay bekleyen ajan ya da kabarcığı olmayan
  // (gidecek yeri olmayan) bir etkinlik.
  readonly property var ezen: {
    for (var i = 0; i < etkinler.length; i++)
      if (etkinler[i].id === "ajanOnay" || !etkinler[i].kucuk) return etkinler[i]
    return null
  }
  // Sabitleme olmasaydı ana island'da olacak etkinlik.
  readonly property var otomatikAna: etkinler.length ? etkinler[0] : null
  // Sabitleme ve önceliğe göre ana island'daki etkinlik.
  readonly property var anaEtkinlik: {
    if (sabit !== "" && !ezen && aktifMi(sabit)) return etkinlik(sabit)
    return otomatikAna
  }
  readonly property string ana: anaEtkinlik ? anaEtkinlik.id : ""

  // Sabitlenen etkinlik bitince (koşulu kalkınca) otomatik önceliğe dön.
  readonly property bool sabitSuruyor: sabit !== "" && !!etkinlik(sabit) && etkinlik(sabit).kosul
  // Temizlik, değişiklik işleyicisinde `sabit` yazılınca "sabitSuruyor"
  // bağlamasıyla döngü olmasın diye olay döngüsüne ertelenir; ara anda
  // anaEtkinlik zaten aktifMi(sabit) ile otomatik önceliğe düşer.
  onSabitSuruyorChanged: if (!sabitSuruyor && sabit !== "") Qt.callLater(sabitiTemizle)
  function sabitiTemizle() {
    if (!sabitSuruyor && sabit !== "") { sabit = ""; kabarcikSirasi = [] }
  }

  // Ana island'a sığmayan, küçük gösterimi olan etkinlikler: en fazla 2
  // kabarcık (1. sağda, 2. solda); kullanıcı sırası önce, kalanlar öncelik sırasıyla.
  readonly property int enFazlaKabarcik: 2
  readonly property var kucukler: {
    var adaylar = etkinler.filter(function(e) { return e.kucuk && e.id !== ana }).map(function(e) { return e.id })
    var r = kabarcikSirasi.filter(function(k) { return adaylar.indexOf(k) >= 0 })
    for (var i = 0; i < adaylar.length; i++) if (r.indexOf(adaylar[i]) < 0) r.push(adaylar[i])
    return r.slice(0, enFazlaKabarcik)
  }

  // Kabarcık ile ana island'ın yerini değiştir: `hedef` kabarcık kimliği ya
  // da sırası (0, 1). Ana island'daki etkinlik tıklanan kabarcığın yerine
  // iner. Yeni ana otomatik öncelikteki etkinlikse sabitleme kalkar.
  // Dönüş: yeni ana etkinlik kimliği ya da hata metni.
  function degistir(hedef) {
    hedef = String(hedef === undefined ? "" : hedef)
    var k = kucukler
    var sira = /^[0-9]+$/.test(hedef) ? Number(hedef) : k.indexOf(hedef)
    if (sira < 0 || sira >= k.length) return "error: no such bubble (" + k.join(",") + ")"
    var yeni = k[sira]
    var eski = ana
    var sirali = k.slice()
    if (eski !== "" && etkinlik(eski) && etkinlik(eski).kucuk) sirali[sira] = eski
    else sirali.splice(sira, 1)
    kabarcikSirasi = sirali
    sabit = otomatikAna && otomatikAna.id === yeni ? "" : yeni
    return ana
  }

  // Kabarcığı olabilecek tüm etkinliklerin kimlikleri (her biri için sabit
  // bir kabarcık nesnesi yaşar; bkz. components/LiveBubble.qml). Sabit
  // liste: kalicilar her güncellendiğinde kabarcıklar yeniden kurulmasın.
  readonly property var kabarcikKimlikleri: ["ajanOnay", "ajan", "takvim", "medya"]
}
