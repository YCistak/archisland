import QtQuick

// A transient card lasting a few seconds when an agent finishes: "Claude · done ✓".
// Its duration is agentDoneSeconds in island.json (default 6 s).
// If the agent has quota data (aiQuota module, AiQuotaWatch.limits) the
// island springs wider (Island.qml targetWidth) and two thin bars on the
// right show 5-hour and weekly usage; the bars fill from 0 to the real value.
// Without data it is a plain banner without bars.
// The enter/exit motion comes from LivePill (delayed scale + opacity).
LivePill {
  id: pill
  shown: host.agentDonePill
  readonly property string agent: host.agents.lastFinished
  readonly property string agentName: host.agents.displayName(agent)
  readonly property color agentColor: host.agents.agentColor(agent)
  readonly property var limit: host.aiQuota.limits(agent)
  // The last values are kept while the card closes (so the content fades out).
  property var lastLimit: null
  onLimitChanged: if (limit) lastLimit = limit
  onShownChanged: if (shown) lastLimit = limit
  readonly property bool hasBars: !!lastLimit
  // The bars fill from 0 when the card opens; they stay full on exit (the
  // content fades out) and are quietly reset once the card is fully hidden.
  property bool filled: false
  onRevealedChanged: if (revealed) filled = true
  onVisibleChanged: if (!visible) filled = false

  Rectangle {
    id: badge
    anchors.left: parent.left
    anchors.leftMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    width: 26; height: 26; radius: 13
    color: pill.host.theme.withAlpha(pill.agentColor, 0.3)
    Text {
      anchors.centerIn: parent
      text: "󰄬"
      color: pill.agentColor
      font.family: pill.host.theme.fontFamily
      font.pixelSize: 14
    }
  }
  Text {
    anchors.left: badge.right
    anchors.leftMargin: 10
    anchors.right: pill.hasBars ? bars.left : parent.right
    anchors.rightMargin: 16
    anchors.verticalCenter: parent.verticalCenter
    text: pill.agentName + " · done ✓"
    textFormat: Text.PlainText
    elide: Text.ElideRight
    color: "#e2e6de"
    font.family: "Adwaita Sans"
    font.pixelSize: 14
    font.weight: Font.DemiBold
  }

  // One usage row: label, thin bar, percentage.
  component UsageRow: Row {
    id: usageRow
    property string label: ""
    property int percent: 0
    spacing: 6
    height: 14
    Text {
      width: 44
      anchors.verticalCenter: parent.verticalCenter
      text: usageRow.label
      color: pill.host.theme.muted
      font.family: "Adwaita Sans"
      font.pixelSize: 10
    }
    Rectangle {
      width: 64; height: 4; radius: 2
      anchors.verticalCenter: parent.verticalCenter
      color: pill.host.theme.withAlpha(pill.host.theme.text, 0.12)
      Rectangle {
        // Fills from 0 to the real value when the card opens.
        width: parent.width * (pill.filled ? Math.max(0, Math.min(1, usageRow.percent / 100)) : 0)
        height: parent.height
        radius: 2
        color: usageRow.percent > 80 ? "#ff453a" : pill.agentColor
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
      text: usageRow.percent + "%"
      color: "#e2e6de"
      font.family: "Adwaita Sans"
      font.pixelSize: 10
      font.weight: Font.DemiBold
      font.features: { "tnum": 1 }
    }
  }

  Column {
    id: bars
    visible: pill.hasBars
    anchors.right: parent.right
    anchors.rightMargin: 18
    anchors.verticalCenter: parent.verticalCenter
    spacing: 3
    UsageRow { label: "5 hours"; percent: pill.lastLimit ? pill.lastLimit.session : 0 }
    UsageRow {
      visible: !!pill.lastLimit && pill.lastLimit.weekly >= 0
      label: "Weekly"
      percent: pill.lastLimit ? Math.max(0, pill.lastLimit.weekly) : 0
    }
  }
}
