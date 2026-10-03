import QtQuick

// Kodlama ajanı canlı etkinliği (aiAgents modülü): bir ya da birden çok ajan
// çalışırken island'ın ana hapı. Solda çizgilerden dönen daire spinner,
// ortada "Claude çalışıyor" / "Antigravity çalışıyor" / "Claude onay bekliyor",
// sağda ajanın canlı maskotu/logosu (Claude maskotu veya Gemini logosu) ve saat.
LivePill {
  id: pill
  shown: host.agentPill
  kimlikler: ["ajan", "ajanOnay"]
  readonly property bool bekliyor: host.agents.bekleyenVar
  readonly property string activeAgent: {
    if (pill.host.agents.tekAjan) return pill.host.agents.tekAjan
    if (pill.host.agents.liste && pill.host.agents.liste.length > 0) return pill.host.agents.liste[0].ajan
    return ""
  }
  readonly property bool isClaude: activeAgent === "claude"
  readonly property bool isAgy: activeAgent === "agy" || activeAgent === "gemini"

  Item {
    id: badge
    anchors.left: parent.left
    anchors.leftMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    width: 26; height: 26
    SiriDots {
      anchors.centerIn: parent
      scale: 0.85
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
    anchors.right: agentMark.left
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

  // Sağ taraftaki ajan göstergesi: Claude animasyonlu maskotu, Gemini animasyonlu logosu
  Item {
    id: agentMark
    anchors.right: saat.visible ? saat.left : parent.right
    anchors.rightMargin: saat.visible ? 10 : 16
    anchors.verticalCenter: parent.verticalCenter
    width: pill.bekliyor ? 8 : (pill.isClaude ? 22 : (pill.isAgy ? 19 : 8))
    height: 24

    // 1. Claude Maskotu (Animasyonlu yürüme + hafif canlı salınım)
    Item {
      id: claudeBox
      anchors.fill: parent
      visible: !pill.bekliyor && pill.isClaude

      AnimatedImage {
        id: claudeMascot
        anchors.centerIn: parent
        source: Qt.resolvedUrl("../assets/claude-mascot.webp")
        width: 22
        height: 24
        fillMode: Image.PreserveAspectFit
        playing: pill.shown && claudeBox.visible
      }

      // Canlılık katan yumuşak nefes/salınım nabzı
      SequentialAnimation on y {
        loops: Animation.Infinite
        running: pill.shown && claudeBox.visible
        NumberAnimation { from: 0; to: -1.5; duration: 550; easing.type: Easing.InOutQuad }
        NumberAnimation { from: -1.5; to: 0; duration: 550; easing.type: Easing.InOutQuad }
      }
    }

    // 2. Gemini / AGY Logosu (Pulsing / parıldayan renkli yıldız)
    Item {
      id: geminiBox
      anchors.centerIn: parent
      width: 18; height: 18
      visible: !pill.bekliyor && pill.isAgy

      Image {
        id: geminiLogo
        anchors.fill: parent
        source: Qt.resolvedUrl("../assets/gemini-logo.svg")
        sourceSize.width: 48
        sourceSize.height: 48
        fillMode: Image.PreserveAspectFit
      }

      // Canlı parıldayan yıldız nabzı (nefes alma ve hafif açı salınımı)
      SequentialAnimation on scale {
        loops: Animation.Infinite
        running: pill.shown && geminiBox.visible
        NumberAnimation { from: 0.90; to: 1.15; duration: 900; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1.15; to: 0.90; duration: 900; easing.type: Easing.InOutSine }
      }
      SequentialAnimation on rotation {
        loops: Animation.Infinite
        running: pill.shown && geminiBox.visible
        NumberAnimation { from: -6; to: 6; duration: 1800; easing.type: Easing.InOutSine }
        NumberAnimation { from: 6; to: -6; duration: 1800; easing.type: Easing.InOutSine }
      }
    }

    // 3. Onay bekleyen ajan (Urgent dot)
    Rectangle {
      anchors.centerIn: parent
      visible: pill.bekliyor
      width: 8; height: 8; radius: 4
      color: pill.host.theme.urgent
    }

    // 4. Diğer veya nötr ajan (soluk alan nokta)
    Rectangle {
      anchors.centerIn: parent
      visible: !pill.bekliyor && !pill.isClaude && !pill.isAgy
      width: 8; height: 8; radius: 4
      color: pill.host.agents.ozetRenk
      SequentialAnimation on opacity {
        loops: Animation.Infinite
        running: parent.visible
        NumberAnimation { from: 0.4; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1.0; to: 0.4; duration: 800; easing.type: Easing.InOutSine }
      }
    }
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
