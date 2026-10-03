import QtQuick

// Kalıcı canlı etkinlik haplarının ortak giriş/çıkış hareketi (MediaPill,
// AgentPill, QuotaPill, EventPill bunun üstüne kurulur).
//  - Giriş: island genişliği yeni içeriğe oturmaya yaklaşırken
//    (contentRevealDelay kadar gecikmeyle) ölçek 0.92→1 + opaklık.
//  - Çıkış: hafif küçülüp solar; etkinlik bir kabarcığa iniyorsa
//    kabarcıkların olduğu sağ kenara doğru kayar (island kırptığı için
//    içerik kenardan dışarı akıyormuş gibi görünür).
// Tüm değerler Behavior ile canlandığından üst üste gelen değişikliklerde
// hareket kaldığı yerden yeni hedefe döner (retarget), sıçrama olmaz.
Item {
  id: pill
  required property var host
  // Etkinlik island'da görünmeli mi (alt bileşen bağlar).
  property bool shown: false
  // Bu hapın temsil ettiği etkinlik kimlikleri (LiveActivities.kalicilar).
  property var kimlikler: []
  readonly property bool kabarcikta: {
    var k = host.live.kucukler
    for (var i = 0; i < kimlikler.length; i++) if (k.indexOf(kimlikler[i]) >= 0) return true
    return false
  }
  // İçerik gerçekten açık mı: girişte kısa bir gecikmeyle true olur.
  property bool acik: false
  onShownChanged: {
    if (shown) revealTimer.restart()
    else { revealTimer.stop(); acik = false }
  }
  Component.onCompleted: acik = shown
  Timer {
    id: revealTimer
    interval: pill.host.theme.contentRevealDelay
    onTriggered: pill.acik = true
  }

  opacity: acik ? 1 : 0
  visible: opacity > 0.01
  scale: acik ? 1 : kabarcikta ? 0.86 : 0.92
  transform: Translate {
    x: pill.acik || !pill.kabarcikta ? 0 : 28
    Behavior on x { MotionAnimation { theme: pill.host.theme; pace: "standard"; curve: "fade" } }
  }

  Behavior on opacity {
    // Çıkışta hızlı düşen eğri: yeni içerik gelmeden eski büyük ölçüde solmuş olur.
    MotionAnimation { theme: pill.host.theme; pace: pill.acik ? "standard" : "exit"; curve: "fade" }
  }
  Behavior on scale {
    MotionAnimation { theme: pill.host.theme; pace: pill.acik ? "bubble" : "standard"; curve: pill.acik ? "spring" : "fade" }
  }
}
