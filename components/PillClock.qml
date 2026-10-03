import QtQuick

// Canlı etkinlik hapının sağ kenarındaki küçük, soluk saat (ör. "2 ajan
// çalışıyor · 14:32"). Biçim, dinlenme saatiyle aynı clock24h ayarına uyar.
Text {
  id: saat
  required property var host
  // Saatten önceki ince ayraç "·".
  text: "·  " + (host.settings.clock24h ? Qt.formatDateTime(host.clockDate, "HH:mm")
    : Qt.formatDateTime(host.clockDate, "h:mm AP").replace(/\s*[AP]M$/i, ""))
  textFormat: Text.PlainText
  color: host.theme.muted
  font.family: "Adwaita Sans"
  font.pixelSize: 13
  font.weight: Font.Medium
  font.features: { "tnum": 1, "case": 1 }
}
