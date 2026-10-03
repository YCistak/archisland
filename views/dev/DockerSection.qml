import QtQuick
import QtQuick.Layouts
import "../../components"

// docker modülü: konteynerler; yeniden başlat, durdur/başlat.
ColumnLayout {
  id: docker
  required property var stats
  readonly property var theme: stats.host.theme
  spacing: 6

  Text {
    visible: docker.stats.containers.length === 0
    Layout.leftMargin: 4
    text: docker.stats.loaded ? "Docker konteyneri bulunamadı." : "Yükleniyor…"
    color: docker.theme.muted
    font.family: "Adwaita Sans"
    font.pixelSize: 13
  }

  Repeater {
    model: docker.stats.containers
    delegate: Rectangle {
      id: row
      required property var modelData
      readonly property bool running: modelData.state === "running"
      Layout.fillWidth: true
      implicitHeight: 52
      radius: 14
      color: Qt.tint(docker.theme.background, docker.theme.withAlpha(docker.theme.text, 0.075))

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        spacing: 10
        Rectangle { width: 8; height: 8; radius: 4; color: row.running ? "#30d158" : "#ff453a" }
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 1
          Text {
            Layout.fillWidth: true
            text: row.modelData.name || "Bilinmiyor"
            elide: Text.ElideRight
            color: docker.theme.text
            font.family: "Adwaita Sans"
            font.pixelSize: 13
            font.weight: Font.DemiBold
          }
          Text {
            Layout.fillWidth: true
            text: (row.modelData.image || "") + " · " + (row.modelData.status || "")
            elide: Text.ElideRight
            color: docker.theme.muted
            font.family: "Adwaita Sans"
            font.pixelSize: 11
          }
        }
        ChipButton {
          theme: docker.theme; label: "󰑐"; tip: "Yeniden başlat"
          onClicked: docker.stats.run(["docker", "restart", row.modelData.name])
        }
        ChipButton {
          theme: docker.theme
          label: row.running ? "󰓛" : "󰐊"
          tip: row.running ? "Durdur" : "Başlat"
          ink: row.running ? "#ff453a" : "#30d158"
          onClicked: docker.stats.run(["docker", row.running ? "stop" : "start", row.modelData.name])
        }
      }
    }
  }
}
