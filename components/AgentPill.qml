import QtQuick

// Kodlama ajanı canlı etkinliği (aiAgents modülü): bir ya da birden çok ajan
// çalışırken island'ın ana hapı. Solda dönen Siri noktaları (onay
// bekleniyorsa uyarı simgesi), ortada "Claude çalışıyor" / "2 ajan
// çalışıyor" / "Claude onay bekliyor". Çalışırken sağ kenarda küçük, soluk
// saat durur (onay beklerken dikkat dağılmasın diye gösterilmez); yer darsa
// özet metni kısalır, saat kalır.
LivePill {
  id: pill
  shown: host.agentPill
  kimlikler: ["ajan", "ajanOnay"]
  readonly property bool bekliyor: host.agents.bekleyenVar

  Item {
    id: badge
    anchors.left: parent.left
    anchors.leftMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    width: 26; height: 26
    SiriDots {
      anchors.centerIn: parent
      scale: 0.62
      dotColor: pill.host.agents.renk || "#d97757"
      visible: !pill.bekliyor
      running: pill.shown && !pill.bekliyor
    }
    Rectangle {
      anchors.fill: parent
      radius: 13
      visible: pill.bekliyor
      color: pill.host.theme.withAlpha(pill.host.theme.urgent, 0.25)
      Text {
        anchors.centerIn: parent
        text: "󰂞"
        color: pill.host.theme.urgent
        font.family: pill.host.theme.fontFamily
        font.pixelSize: 14
      }
    }
  }
  Text {
    anchors.left: badge.right
    anchors.leftMargin: 10
    anchors.right: dot.left
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    text: pill.host.agents.ozet
    textFormat: Text.PlainText
    elide: Text.ElideRight
    color: "#e2e6de"
    font.family: "Adwaita Sans"
    font.pixelSize: 14
    font.weight: Font.DemiBold
  }
  // Ajanın rengi (birden çok tür ajan varsa nötr).
  Rectangle {
    id: dot
    anchors.right: saat.visible ? saat.left : parent.right
    anchors.rightMargin: saat.visible ? 10 : 16
    anchors.verticalCenter: parent.verticalCenter
    width: 8; height: 8; radius: 4
    color: pill.bekliyor ? pill.host.theme.urgent : pill.host.agents.ozetRenk
  }
  PillClock {
    id: saat
    host: pill.host
    visible: !pill.bekliyor
    anchors.right: parent.right
    anchors.rightMargin: 16
    anchors.verticalCenter: parent.verticalCenter
  }
}
