import QtQuick

// A small, faint clock at the right edge of a live activity pill (e.g. "2 agents
// working · 14:32"). The format follows the same clock24h setting as the resting clock.
Text {
  id: clock
  required property var host
  // The thin "·" separator before the clock.
  text: "·  " + (host.settings.clock24h ? Qt.formatDateTime(host.clockDate, "HH:mm")
    : Qt.formatDateTime(host.clockDate, "h:mm AP").replace(/\s*[AP]M$/i, ""))
  textFormat: Text.PlainText
  color: host.theme.muted
  font.family: "Adwaita Sans"
  font.pixelSize: 13
  font.weight: Font.Medium
  font.features: { "tnum": 1, "case": 1 }
}
