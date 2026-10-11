import QtQuick

// AI quota alert (aiQuota module): a pill shown once on the main island when
// the remaining share of a quota window drops below the aiQuotaWarnPercent
// threshold in island.json, e.g. "Claude 15% left". It closes on click; if not
// clicked it closes by itself after aiQuotaAlertSeconds. It has no bubble.
LivePill {
  id: pill
  shown: host.quotaPill
  activityIds: ["quota"]

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
    text: pill.host.aiQuota.label
    textFormat: Text.PlainText
    elide: Text.ElideRight
    color: pill.host.theme.urgent
    font.family: "Adwaita Sans"
    font.pixelSize: 14
    font.weight: Font.DemiBold
    font.features: { "tnum": 1 }
  }
}
