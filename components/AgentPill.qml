import QtQuick

// Kodlama ajanı canlı etkinliği (aiAgents modülü): bir ya da birden çok ajan
// çalışırken island'ın ana hapı. Solda dönen organik Siri noktaları (onay
// bekleniyorsa uyarı simgesi), ortada "Claude çalışıyor" / "Antigravity çalışıyor",
// sağda ajanın canlı maskotu/logosu (Claude animasyonlu maskotu veya Gemini logosu) ve saat.
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

  // Claude için seçilebilir canlı animasyonlar (tıklandıkça değişir):
  // 1. laptop (laptop başında kod yazan, ekranında neon syntax akan Clawd)
  // 2. crabwalk (yan yan yürüyen, kolları ve gövdesi sallanan Clawd)
  // 3. vibing (mavi kulaklıkla müzik dinleyen, notalar uçuşan Clawd)
  // 4. celebrate (havaya zıplayan, konfetiler yağan zafer Clawd)
  // 5. coffee (kahvesini yudumlayan, dumanı tüten düşünceli Clawd)
  // 6. thinking (gözleri yukarı bakan, düşünce balonu çıkan Clawd)
  // 7. hammering (sarı baretli çekiçle inşa eden Clawd)
  readonly property var claudeAnims: [
    "claude-laptop.gif",
    "claude-crabwalk.gif",
    "claude-vibing.gif",
    "claude-celebrate.gif",
    "claude-coffee.gif",
    "claude-thinking.gif",
    "claude-hammering.gif"
  ]
  property int currentAnimIdx: 0

  Item {
    id: badge
    anchors.left: parent.left
    anchors.leftMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    width: 26; height: 26
    SiriDots {
      anchors.centerIn: parent
      scale: 0.65
      dotColor: pill.isClaude ? "#d97757" : (pill.isAgy ? "#60a5fa" : "#ffffff")
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

  // Sağ taraftaki ajan göstergesi: Claude canlı maskotu, Gemini logosu veya durum göstergesi
  Item {
    id: agentMark
    anchors.right: saat.visible ? saat.left : parent.right
    anchors.rightMargin: saat.visible ? 10 : 16
    anchors.verticalCenter: parent.verticalCenter
    width: pill.bekliyor ? 8 : (pill.isClaude ? Math.max(30, claudeMascot.width) : (pill.isAgy ? 19 : 8))
    height: 24

    // 1. Claude Maskotu (Clawd) - Gerçek canlı GIF animasyonları (Tıklandığında animasyon değişir)
    Item {
      id: claudeBox
      anchors.fill: parent
      visible: !pill.bekliyor && pill.isClaude

      AnimatedImage {
        id: claudeMascot
        anchors.centerIn: parent
        source: Qt.resolvedUrl("../assets/" + pill.claudeAnims[pill.currentAnimIdx])
        height: 22
        width: implicitHeight > 0 ? Math.round(implicitWidth * (height / implicitHeight)) : 34
        fillMode: Image.PreserveAspectFit
        smooth: false
        playing: pill.shown && claudeBox.visible
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          pill.currentAnimIdx = (pill.currentAnimIdx + 1) % pill.claudeAnims.length
        }
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
        smooth: true
      }

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
