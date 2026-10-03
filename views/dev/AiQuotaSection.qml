import QtQuick
import QtQuick.Layouts
import "../../components"

// aiQuota modülü: Claude Code, Antigravity ve (varsa) Codex kullanım yüzdeleri.
ColumnLayout {
  id: ai
  required property var stats
  readonly property var theme: stats.host.theme
  spacing: 8

  function tokens(n) {
    if (!n || n <= 0) return "0"
    if (n >= 1e6) return (n / 1e6).toFixed(1) + "M"
    if (n >= 1e3) return (n / 1e3).toFixed(1) + "K"
    return String(n)
  }

  // Sağlayıcı kartı: başlık satırı ve altında kota çubukları.
  component ProviderCard: Rectangle {
    id: providerCard
    required property var theme
    property string glyph: ""
    property string name: ""
    property string note: ""
    property color tint: theme.accent
    default property alias rows: body.data
    Layout.fillWidth: true
    implicitHeight: body.implicitHeight + 24
    radius: 16
    color: Qt.tint(theme.background, theme.withAlpha(theme.text, 0.075))
    ColumnLayout {
      id: body
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 12
      spacing: 8
      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text { text: providerCard.glyph; color: providerCard.tint; font.family: providerCard.theme.fontFamily; font.pixelSize: 15 }
        Text {
          Layout.fillWidth: true
          text: providerCard.name
          color: providerCard.theme.text
          font.family: "Adwaita Sans"
          font.pixelSize: 14
          font.weight: Font.DemiBold
        }
        Text { text: providerCard.note; color: providerCard.theme.muted; font.family: "Adwaita Sans"; font.pixelSize: 11 }
      }
    }
  }

  ProviderCard {
    theme: ai.theme
    glyph: ""; name: "Claude Code"; tint: "#d97757"
    note: "Opus " + ai.tokens(ai.stats.claude.opus) + " · Sonnet " + ai.tokens(ai.stats.claude.sonnet)
    QuotaBar { Layout.fillWidth: true; theme: ai.theme; tint: "#d97757"; label: "5 saatlik oturum"; percent: ai.stats.claude.session || 0 }
    QuotaBar { Layout.fillWidth: true; theme: ai.theme; tint: "#d97757"; label: "Haftalık kota"; percent: ai.stats.claude.weekly || 0 }
  }

  ProviderCard {
    theme: ai.theme
    glyph: "󰫢"; name: "Antigravity"; tint: "#60a5fa"
    note: ai.stats.antigravity.burn || ""
    QuotaBar { Layout.fillWidth: true; theme: ai.theme; tint: "#60a5fa"; label: "Gemini · 5 saatlik oturum"; percent: ai.stats.antigravity.session || 0 }
    QuotaBar { Layout.fillWidth: true; theme: ai.theme; tint: "#60a5fa"; label: "Gemini · haftalık kota"; percent: ai.stats.antigravity.weekly || 0 }
    QuotaBar { Layout.fillWidth: true; theme: ai.theme; tint: "#f59e0b"; label: "Claude ve GPT · 5 saatlik oturum"; percent: ai.stats.antigravity.session3p || 0 }
    QuotaBar { Layout.fillWidth: true; theme: ai.theme; tint: "#f59e0b"; label: "Claude ve GPT · haftalık kota"; percent: ai.stats.antigravity.weekly3p || 0 }
  }

  ProviderCard {
    visible: ai.stats.codexSession > 0
    theme: ai.theme
    glyph: ""; name: "Codex"; tint: "#9ca3af"
    QuotaBar { Layout.fillWidth: true; theme: ai.theme; tint: "#9ca3af"; label: "5 saatlik oturum"; percent: ai.stats.codexSession }
  }
}
