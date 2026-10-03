import QtQuick

// Ana island'a sığmayan bir canlı etkinliğin küçük kabarcığı. En fazla 2
// kabarcık vardır: 1. kabarcık island'ın SAĞINDA, 2. kabarcık SOLUNDA durur
// (bkz. services/LiveActivities.qml → kucukler). Her etkinlik kimliğinin kendi
// kabarcık nesnesi vardır; içerik sıra değişince değişmez.
// Yalnızca simge + kısa değer gösterir; island dışında panel açılmaz.
// Tıklayınca yer değiştirir: bu etkinlik ana island'a geçer, ana island'daki
// etkinlik bu kabarcığın yerine iner (LiveActivities.degistir).
//
// Hareket: görünürken kendi tarafındaki island kenarından "damla gibi ayrılır"
// (ölçek 0.6→1, opaklık); kaybolurken aynı yolu tersine izleyip island'a
// "emilir". Sol kabarcık sağdakinin aynasıdır. Taraf değişecekse (sağdaki
// bitti, soldaki 1. sıraya geçti) kabarcık önce bulunduğu kenardan island'a
// emilir, sonra yeni tarafta yeniden ayrılır; island'ın arkasından geçmez.
Rectangle {
  id: bubble
  required property var host
  // Ana island; kabarcık onun sağ kenarını izler.
  required property Item island
  // Bu kabarcığın etkinlik kimliği (LiveActivities.kabarcikKimlikleri).
  required property string kimlik
  readonly property int sira: host.live.kucukler.indexOf(kimlik)
  readonly property var etkinlik: host.live.etkinlik(kimlik)
  // Kabarcık kaybolurken son içeriği koru.
  property var son: null
  readonly property bool etkin: sira >= 0
  onEtkinlikChanged: if (etkin && etkinlik) son = etkinlik
  onEtkinChanged: if (etkin && etkinlik) son = etkinlik
  readonly property bool shown: etkin && yanTamam && host.view === "rest" && island.visible

  readonly property real gap: host.settings.notch ? 16 : 8
  readonly property real hedefGenislik: Math.max(height, row.implicitWidth + 20)

  // Taraf: +1 sağ (1. kabarcık), -1 sol (2. kabarcık). Yalnızca kabarcık
  // görünmezken değişir; görünürken hedef değişirse önce emilir.
  readonly property int hedefYan: sira === 1 ? -1 : 1
  property int yan: 1
  readonly property bool yanTamam: yan === hedefYan
  onHedefYanChanged: if (!visible) yan = hedefYan
  onVisibleChanged: if (!visible) yan = hedefYan

  // Gizliyken kabarcığın merkezi island kenarının biraz içinde durur.
  property real ayrilma: shown ? 0 : -(gap + width * 0.6)
  Behavior on ayrilma {
    MotionAnimation {
      theme: bubble.host.theme
      pace: bubble.shown ? "bubble" : "standard"
      curve: bubble.shown ? "spring" : "fade"
    }
  }

  x: yan > 0 ? island.x + island.width + gap + ayrilma
               : island.x - gap - width - ayrilma
  height: host.settings.notch ? 32 : 36
  y: host.settings.notch ? 4 : island.y + (island.height - height) / 2
  width: hedefGenislik
  radius: height / 2
  color: host.theme.background
  border.width: 1
  border.color: host.theme.withAlpha(host.theme.text, 0.08 * (shown ? 1 : 0))

  opacity: shown ? 1 : 0
  visible: opacity > 0.01
  // Emilen kabarcık island'a dönerken görünür olanın altından geçsin.
  z: shown ? 1 : 0
  scale: shown ? 1 : 0.6
  Behavior on opacity {
    MotionAnimation { theme: bubble.host.theme; pace: bubble.shown ? "standard" : "collapse"; curve: "fade" }
  }
  Behavior on scale {
    MotionAnimation {
      theme: bubble.host.theme
      pace: bubble.shown ? "bubble" : "standard"
      curve: bubble.shown ? "spring" : "fade"
    }
  }
  Behavior on width { MotionAnimation { theme: bubble.host.theme; pace: "bubble"; curve: "spring" } }
  Behavior on border.color { MotionColorAnimation { theme: bubble.host.theme } }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 6
    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: !!bubble.son && !!bubble.son.simge
      text: bubble.son ? bubble.son.simge : ""
      color: bubble.son ? bubble.son.renk : bubble.host.theme.text
      font.family: bubble.host.theme.fontFamily
      font.pixelSize: 14
    }
    SoundWave {
      anchors.verticalCenter: parent.verticalCenter
      visible: !!bubble.son && !!bubble.son.dalga
      color: bubble.son ? bubble.son.renk : bubble.host.theme.accent
      bars: 4
      maxHeight: 14
      playing: bubble.shown && visible
    }
    // Çalışan ajan: küçük dönen halka.
    Item {
      anchors.verticalCenter: parent.verticalCenter
      visible: !!bubble.son && !!bubble.son.hareketli
      width: 14; height: 14
      SiriDots {
        anchors.centerIn: parent
        scale: 0.42
        running: bubble.shown && parent.visible
      }
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: text !== ""
      text: bubble.son ? bubble.son.metin : ""
      color: "#e2e6de"
      font.family: "Adwaita Sans"
      font.pixelSize: 13
      font.weight: Font.DemiBold
      font.features: { "tnum": 1 }
    }
  }

  // Tıklama: IPC `swap` ile aynı işlev (LiveActivities.degistir). Kabarcığın
  // en üstünde durur; giriş maskesi Region'ı bu kabarcığın kendisidir.
  MouseArea {
    id: fare
    anchors.fill: parent
    z: 10
    enabled: bubble.shown
    hoverEnabled: bubble.host.settings.debugInput
    preventStealing: true
    onEntered: bubble.host.girdiLog("kabarcık " + bubble.kimlik + " üzerine gelindi " + bubble.host.sahneDikdortgen(bubble))
    onPressed: function(mouse) {
      bubble.host.girdiLog("kabarcık " + bubble.kimlik + " basış (sıra " + bubble.sira + ") " + bubble.host.sahneDikdortgen(bubble))
    }
    onCanceled: bubble.host.girdiLog("kabarcık " + bubble.kimlik + " basış iptal")
    onClicked: {
      var sonuc = bubble.host.live.degistir(bubble.kimlik)
      bubble.host.girdiLog("kabarcık " + bubble.kimlik + " tık → degistir: " + sonuc)
    }
  }
}
