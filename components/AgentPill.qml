import QtQuick

// Coding agent live activity (aiAgents module): the island's main pill while
// one or more agents are working. On the left spinning organic Siri dots (a
// warning icon when approval is needed), in the middle "Claude working" /
// "Antigravity working", on the right the agent's live mascot/logo (Claude's
// animated mascot or the Gemini logo) and the clock.
LivePill {
  id: pill
  shown: host.agentPill
  activityIds: ["agent", "agentApproval"]
  readonly property bool waiting: host.agents.anyWaiting
  readonly property string activeAgent: {
    if (pill.host.agents.singleAgent) return pill.host.agents.singleAgent
    if (pill.host.agents.entries && pill.host.agents.entries.length > 0) return pill.host.agents.entries[0].agent
    return ""
  }
  readonly property bool isClaude: activeAgent === "claude"
  readonly property bool isAgy: activeAgent === "agy" || activeAgent === "gemini"

  // Selectable live animations for Claude (cycle on each click):
  // 1. laptop (Clawd coding at a laptop, neon syntax scrolling on screen)
  // 2. crabwalk (Clawd walking sideways, arms and body swaying)
  // 3. vibing (Clawd listening to music on blue headphones, notes flying)
  // 4. celebrate (victorious Clawd jumping up, confetti falling)
  // 5. coffee (thoughtful Clawd sipping a steaming coffee)
  // 6. thinking (Clawd looking up, a thought bubble appearing)
  // 7. hammering (Clawd building with a hammer in a yellow hard hat)
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
      visible: !pill.waiting
      running: pill.shown && !pill.waiting
    }
    Rectangle {
      anchors.fill: parent
      radius: 13
      visible: pill.waiting
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
    text: pill.host.agents.summary
    textFormat: Text.PlainText
    elide: Text.ElideRight
    color: "#e2e6de"
    font.family: "Adwaita Sans"
    font.pixelSize: 14
    font.weight: Font.DemiBold
  }

  // Agent indicator on the right: Claude's live mascot, the Gemini logo or a state indicator
  Item {
    id: agentMark
    anchors.right: clock.visible ? clock.left : parent.right
    anchors.rightMargin: clock.visible ? 10 : 16
    anchors.verticalCenter: parent.verticalCenter
    width: pill.waiting ? 8 : (pill.isClaude ? Math.max(30, claudeMascot.width) : (pill.isAgy ? 19 : 8))
    height: 24

    // 1. Claude mascot (Clawd) - real animated GIFs (the animation changes on click)
    Item {
      id: claudeBox
      anchors.fill: parent
      visible: !pill.waiting && pill.isClaude

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

    // 2. Gemini / AGY logo (a pulsing, shimmering colored star)
    Item {
      id: geminiBox
      anchors.centerIn: parent
      width: 18; height: 18
      visible: !pill.waiting && pill.isAgy

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

    // 3. Agent waiting for approval (urgent dot)
    Rectangle {
      anchors.centerIn: parent
      visible: pill.waiting
      width: 8; height: 8; radius: 4
      color: pill.host.theme.urgent
    }

    // 4. Other or neutral agent (a breathing dot)
    Rectangle {
      anchors.centerIn: parent
      visible: !pill.waiting && !pill.isClaude && !pill.isAgy
      width: 8; height: 8; radius: 4
      color: pill.host.agents.summaryColor
      SequentialAnimation on opacity {
        loops: Animation.Infinite
        running: parent.visible
        NumberAnimation { from: 0.4; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1.0; to: 0.4; duration: 800; easing.type: Easing.InOutSine }
      }
    }
  }

  PillClock {
    id: clock
    host: pill.host
    visible: !pill.waiting
    anchors.right: parent.right
    anchors.rightMargin: 16
    anchors.verticalCenter: parent.verticalCenter
  }
}
