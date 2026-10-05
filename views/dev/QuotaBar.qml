import QtQuick
import QtQuick.Layouts
import "../../components"

// Bir kota satırı: etiket, yüzde ve dolum çubuğu (%80 üstü kırmızı).
ColumnLayout {
  id: bar
  required property var theme
  property string label: ""
  property int percent: 0
  property color tint: theme.accent
  spacing: 5

  RowLayout {
    Layout.fillWidth: true
    Text {
      Layout.fillWidth: true
      text: bar.label
      color: bar.theme.muted
      font.family: "Adwaita Sans"
      font.pixelSize: 12
    }
    Text {
      text: bar.percent + "%"
      color: bar.theme.text
      font.family: "Adwaita Sans"
      font.pixelSize: 12
      font.weight: Font.DemiBold
      font.features: { "tnum": 1 }
    }
  }
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 6
    radius: 3
    color: bar.theme.withAlpha(bar.theme.text, 0.1)
    Rectangle {
      width: parent.width * Math.max(0, Math.min(1, bar.percent / 100))
      height: parent.height
      radius: 3
      color: bar.percent > 80 ? "#ff453a" : bar.tint
      Behavior on width { MotionAnimation { theme: bar.theme; pace: "standard" } }
    }
  }
}
