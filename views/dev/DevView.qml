import QtQuick
import QtQuick.Layouts
import "../../components"

// Geliştirici görünümü: AI kota, Docker, portlar ve GitHub PR'ları. Her
// bölüm kendi modülüne bağlıdır (Ayarlar → Modüller); sekmeler yalnız açık
// modülleri gösterir. ←/→ (ya da Tab) sekme değiştirir, Esc kapatır.
ColumnLayout {
  id: dev
  required property var host
  property bool active: false
  readonly property var theme: host.theme

  readonly property DevStats stats: DevStats { host: dev.host; active: dev.active }

  readonly property var tabs: {
    var all = [
      { key: "ai", glyph: "󱚣", name: "AI quota", tint: "#d97757", on: stats.showAi },
      { key: "docker", glyph: "󰡨", name: "Docker", tint: "#0a84ff", on: stats.showDocker },
      { key: "ports", glyph: "󰛳", name: "Ports", tint: "#bf5af2", on: stats.showPorts },
      { key: "pr", glyph: "󰊤", name: "PRs", tint: "#30d158", on: stats.showPr }
    ]
    return all.filter(function(t) { return t.on })
  }
  property string tab: ""
  readonly property string currentTab: {
    for (var i = 0; i < tabs.length; i++) if (tabs[i].key === tab) return tab
    return tabs.length ? tabs[0].key : ""
  }
  function moveTab(delta) {
    if (!tabs.length) return
    var i = 0
    for (var j = 0; j < tabs.length; j++) if (tabs[j].key === currentTab) i = j
    tab = tabs[(i + delta + tabs.length) % tabs.length].key
  }

  onActiveChanged: {
    if (!active) return
    // Canlı etkinlikten açıldıysa istenen sekme (ör. kota uyarısı → "ai").
    if (host.devTab !== "") { tab = host.devTab; host.devTab = "" }
    Qt.callLater(function() { dev.forceActiveFocus() })
  }
  Keys.onEscapePressed: host.view = "rest"
  Keys.onLeftPressed: moveTab(-1)
  Keys.onRightPressed: moveTab(1)
  Keys.onTabPressed: moveTab(1)
  Keys.onBacktabPressed: moveTab(-1)

  spacing: 12

  RowLayout {
    Layout.fillWidth: true
    Layout.preferredHeight: 34
    Layout.leftMargin: 4
    spacing: 6
    Text {
      Layout.fillWidth: true
      text: "Developer"
      color: dev.theme.text
      font.family: "Adwaita Sans"
      font.pixelSize: 17
      font.weight: Font.DemiBold
    }
    Repeater {
      model: dev.tabs
      delegate: ChipButton {
        required property var modelData
        theme: dev.theme
        label: modelData.glyph
        tip: modelData.name
        ink: modelData.tint
        tint: modelData.tint
        checked: dev.currentTab === modelData.key
        onClicked: dev.tab = modelData.key
      }
    }
  }

  Text {
    visible: dev.tabs.length === 0
    Layout.fillWidth: true
    Layout.leftMargin: 4
    Layout.bottomMargin: 4
    wrapMode: Text.WordWrap
    text: "Developer modules are off. You can turn them on in Settings → Modules."
    color: dev.theme.muted
    font.family: "Adwaita Sans"
    font.pixelSize: 13
  }

  AiQuotaSection { Layout.fillWidth: true; visible: dev.currentTab === "ai"; stats: dev.stats }
  DockerSection { Layout.fillWidth: true; visible: dev.currentTab === "docker"; stats: dev.stats }
  PortsSection { Layout.fillWidth: true; visible: dev.currentTab === "ports"; stats: dev.stats }
  PrSection { Layout.fillWidth: true; visible: dev.currentTab === "pr"; stats: dev.stats; active: dev.active && dev.currentTab === "pr" }
}
