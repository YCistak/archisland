import QtQuick

// Ajan işini bitirince birkaç saniyelik geçici kart: "Claude · bitti ✓".
// Süresi island.json'daki agentDoneSeconds (varsayılan 6 sn).
// Ajanın kota verisi varsa (aiQuota modülü, AiQuotaWatch.limitler) island
// yanlara doğru yaylanarak genişler (Island.qml targetWidth) ve sağda iki
// ince çubuk 5 saatlik ve haftalık kullanımı gösterir; çubuklar 0'dan gerçek
// değere dolar. Veri yoksa çubuksuz sade banner.
// Giriş/çıkış hareketi LivePill'den (gecikmeli ölçek + opaklık).
LivePill {
  id: pill
  shown: host.agentDonePill
  readonly property string ajan: host.agents.sonBiten
  readonly property string ad: host.agents.ad(ajan)
  readonly property color renk: host.agents.renk(ajan)
  readonly property var limit: host.aiQuota.limitler(ajan)
  // Kart kapanırken son değerler korunur (içerik solarak çıksın).
  property var sonLimit: null
  onLimitChanged: if (limit) sonLimit = limit
  onShownChanged: if (shown) sonLimit = limit
  readonly property bool cubuklu: !!sonLimit
  // Çubuklar kart açılınca 0'dan dolar; çıkışta dolu kalır (içerik solarak
  // çıkar), kart tamamen gizlenince sessizce sıfırlanır.
  property bool dolu: false
  onAcikChanged: if (acik) dolu = true
  onVisibleChanged: if (!visible) dolu = false

  Rectangle {
    id: badge
    anchors.left: parent.left
    anchors.leftMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    width: 26; height: 26; radius: 13
    color: pill.host.theme.withAlpha(pill.renk, 0.3)
    Text {
      anchors.centerIn: parent
      text: "󰄬"
      color: pill.renk
      font.family: pill.host.theme.fontFamily
      font.pixelSize: 14
    }
  }
  Text {
    anchors.left: badge.right
    anchors.leftMargin: 10
    anchors.right: pill.cubuklu ? bars.left : parent.right
    anchors.rightMargin: 16
    anchors.verticalCenter: parent.verticalCenter
    text: pill.ad + " · bitti ✓"
    textFormat: Text.PlainText
    elide: Text.ElideRight
    color: "#e2e6de"
    font.family: "Adwaita Sans"
    font.pixelSize: 14
    font.weight: Font.DemiBold
  }

  // Bir kullanım satırı: etiket, ince çubuk, yüzde.
  component Satir: Row {
    id: satir
    property string etiket: ""
    property int yuzde: 0
    spacing: 6
    height: 14
    Text {
      width: 44
      anchors.verticalCenter: parent.verticalCenter
      text: satir.etiket
      color: pill.host.theme.muted
      font.family: "Adwaita Sans"
      font.pixelSize: 10
    }
    Rectangle {
      width: 64; height: 4; radius: 2
      anchors.verticalCenter: parent.verticalCenter
      color: pill.host.theme.withAlpha(pill.host.theme.text, 0.12)
      Rectangle {
        // Kart açılınca 0'dan gerçek değere dolar.
        width: parent.width * (pill.dolu ? Math.max(0, Math.min(1, satir.yuzde / 100)) : 0)
        height: parent.height
        radius: 2
        color: satir.yuzde > 80 ? "#ff453a" : pill.renk
        Behavior on width {
          enabled: pill.shown
          MotionAnimation { theme: pill.host.theme; pace: "morph"; curve: "settle" }
        }
      }
    }
    Text {
      width: 28
      anchors.verticalCenter: parent.verticalCenter
      horizontalAlignment: Text.AlignRight
      text: "%" + satir.yuzde
      color: "#e2e6de"
      font.family: "Adwaita Sans"
      font.pixelSize: 10
      font.weight: Font.DemiBold
      font.features: { "tnum": 1 }
    }
  }

  Column {
    id: bars
    visible: pill.cubuklu
    anchors.right: parent.right
    anchors.rightMargin: 18
    anchors.verticalCenter: parent.verticalCenter
    spacing: 3
    Satir { etiket: "5 saat"; yuzde: pill.sonLimit ? pill.sonLimit.oturum : 0 }
    Satir {
      visible: !!pill.sonLimit && pill.sonLimit.haftalik >= 0
      etiket: "Haftalık"
      yuzde: pill.sonLimit ? Math.max(0, pill.sonLimit.haftalik) : 0
    }
  }
}
