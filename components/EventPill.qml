import QtQuick

// Dinlenme hâlinde "sıradaki etkinlik": bir saat içinde başlayacak takvim
// etkinliği varsa island küçük bir canlı etkinliğe dönüşür. Tıklayınca
// takvim görünümü açılır (bkz. Island.qml).
LivePill {
  id: pill
  shown: host.eventPill
  kimlikler: ["takvim"]
  readonly property var event: host.calendar.nextEvent

  Rectangle {
    id: badge
    anchors.left: parent.left
    anchors.leftMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    width: 26; height: 26; radius: 13
    color: pill.host.theme.withAlpha(pill.host.theme.accent, 0.25)
    Text {
      anchors.centerIn: parent
      text: "󰃭"
      color: pill.host.theme.accent
      font.family: pill.host.theme.fontFamily
      font.pixelSize: 14
    }
  }
  Text {
    anchors.left: badge.right
    anchors.leftMargin: 10
    anchors.right: remaining.left
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    text: pill.event ? pill.event.summary : ""
    textFormat: Text.PlainText
    elide: Text.ElideRight
    color: "#e2e6de"
    font.family: "Adwaita Sans"
    font.pixelSize: 14
    font.weight: Font.DemiBold
  }
  Text {
    id: remaining
    anchors.right: parent.right
    anchors.rightMargin: 16
    anchors.verticalCenter: parent.verticalCenter
    text: !pill.event ? "" : pill.event.minutes <= 0 ? "şimdi" : pill.event.minutes + " dk"
    color: pill.host.theme.accent
    font.family: "Adwaita Sans"
    font.pixelSize: 13
    font.weight: Font.DemiBold
    font.features: { "tnum": 1 }
  }
}
