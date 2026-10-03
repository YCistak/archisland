import QtQuick

// AI kota uyarısı (aiQuota modülü): bir kota penceresinde kalan oran
// island.json'daki aiQuotaWarnPercent eşiğinin altına düşünce ana island'da
// bir kez görünen hap, ör. "Claude %15 kaldı". Tıklayınca kapanır; tıklanmazsa
// aiQuotaAlertSeconds sonra kendiliğinden kapanır. Kabarcık olmaz.
LivePill {
  id: pill
  shown: host.quotaPill
  kimlikler: ["kota"]

  Rectangle {
    id: badge
    anchors.left: parent.left
    anchors.leftMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    width: 26; height: 26; radius: 13
    color: pill.host.theme.withAlpha(pill.host.theme.urgent, 0.25)
    Text {
      anchors.centerIn: parent
      text: "󱚣"
      color: pill.host.theme.urgent
      font.family: pill.host.theme.fontFamily
      font.pixelSize: 14
    }
  }
  Text {
    anchors.left: badge.right
    anchors.leftMargin: 10
    anchors.right: parent.right
    anchors.rightMargin: 16
    anchors.verticalCenter: parent.verticalCenter
    text: pill.host.aiQuota.metin
    textFormat: Text.PlainText
    elide: Text.ElideRight
    color: pill.host.theme.urgent
    font.family: "Adwaita Sans"
    font.pixelSize: 14
    font.weight: Font.DemiBold
    font.features: { "tnum": 1 }
  }
}
