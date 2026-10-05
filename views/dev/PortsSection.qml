import QtQuick
import QtQuick.Layouts
import "../../components"

// devPorts modülü: dinleyen geliştirme portları; tarayıcıda aç, süreci kapat.
ColumnLayout {
  id: ports
  required property var stats
  readonly property var theme: stats.host.theme
  spacing: 6

  Text {
    visible: ports.stats.ports.length === 0
    Layout.leftMargin: 4
    text: ports.stats.loaded ? "No listening ports." : "Loading…"
    color: ports.theme.muted
    font.family: "Adwaita Sans"
    font.pixelSize: 13
  }

  Flickable {
    Layout.fillWidth: true
    visible: ports.stats.ports.length > 0
    implicitHeight: Math.min(300, list.implicitHeight)
    contentHeight: list.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
      id: list
      width: parent.width
      spacing: 6

      Repeater {
        model: ports.stats.ports
        delegate: Rectangle {
          id: row
          required property var modelData
          Layout.fillWidth: true
          implicitHeight: 50
          radius: 14
          color: Qt.tint(ports.theme.background, ports.theme.withAlpha(ports.theme.text, 0.075))

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 10
            Rectangle {
              implicitWidth: portLabel.implicitWidth + 14
              implicitHeight: 26
              radius: 8
              color: ports.theme.withAlpha("#bf5af2", 0.2)
              Text {
                id: portLabel
                anchors.centerIn: parent
                text: ":" + row.modelData.port
                color: "#d4a5ff"
                font.family: "Adwaita Sans"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
              }
            }
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1
              Text {
                Layout.fillWidth: true
                text: (row.modelData.process || "process") + " · PID " + (row.modelData.pid || "?")
                elide: Text.ElideRight
                color: ports.theme.text
                font.family: "Adwaita Sans"
                font.pixelSize: 13
                font.weight: Font.DemiBold
              }
              Text {
                Layout.fillWidth: true
                text: row.modelData.cwd || "-"
                elide: Text.ElideMiddle
                color: ports.theme.muted
                font.family: "monospace"
                font.pixelSize: 10
              }
            }
            ChipButton {
              theme: ports.theme; label: "󰖟"; tip: "Open in browser"
              onClicked: ports.stats.run(["xdg-open", "http://localhost:" + row.modelData.port])
            }
            ChipButton {
              theme: ports.theme; label: "󰅖"; tip: "Kill process"; ink: "#ff453a"
              onClicked: ports.stats.run(["bash", "-c", 'kill -9 "$1" 2>/dev/null || fuser -k -n tcp "$2" 2>/dev/null || true',
                "kill-port", String(Number(row.modelData.pid)), String(Number(row.modelData.port))])
            }
          }
        }
      }
    }
  }
}
