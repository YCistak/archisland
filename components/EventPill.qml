import QtQuick

// "Next event" at rest: if a calendar event starts within the hour the island
// turns into a small live activity. A click opens the calendar view (see
// Island.qml). A small, faint clock sits at the right edge; the event name
// is shortened when space is tight.
LivePill {
  id: pill
  shown: host.eventPill
  activityIds: ["calendar"]
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
    anchors.right: clock.left
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    text: !pill.event ? "" : pill.event.minutes <= 0 ? "now" : pill.event.minutes + " min"
    color: pill.host.theme.accent
    font.family: "Adwaita Sans"
    font.pixelSize: 13
    font.weight: Font.DemiBold
    font.features: { "tnum": 1 }
  }
  PillClock {
    id: clock
    host: pill.host
    anchors.right: parent.right
    anchors.rightMargin: 16
    anchors.verticalCenter: parent.verticalCenter
  }
}
