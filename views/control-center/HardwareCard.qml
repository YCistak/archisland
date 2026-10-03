import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../components"

CcSection {
  id: card
  title: "Performance & Hardware"
  detail: "Click for btop"

  property int cpu: 0
  property int temp: 0
  property string ramUsed: "0"
  property string ramTotal: "0"
  property int ramPercent: 0
  property int gpuUtil: 0
  property int gpuTemp: 0
  property int gpuMemUsed: 0
  property int gpuMemTotal: 0
  Process {
    id: statsProc
    command: ["bash", "-c", "script=$(find \"$HOME/.config/archisland\" -name \"hw-stats.sh\" 2>/dev/null | head -n1); [[ -n \"$script\" && -x \"$script\" ]] && exec \"$script\" || exit 0"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          card.cpu = data.cpu || 0
          card.temp = data.temp || 0
          card.ramUsed = data.ram_used || "0"
          card.ramTotal = data.ram_total || "0"
          card.ramPercent = data.ram_percent || 0
          card.gpuUtil = data.gpu_util || 0
          card.gpuTemp = data.gpu_temp || 0
          card.gpuMemUsed = data.gpu_mem_used || 0
          card.gpuMemTotal = data.gpu_mem_total || 0
        } catch (e) {}
      }
    }
  }

  Timer {
    interval: 2500
    running: card.center.active
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!statsProc.running) statsProc.running = true
    }
  }

  Process {
    id: btopLauncher
    command: ["konsole", "-e", "btop"]
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: 46

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: btopLauncher.startDetached()
    }

    RowLayout {
      anchors.fill: parent
      spacing: 8

    // CPU Pill
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 46
      radius: 10
      color: card.center.well
      ColumnLayout {
        anchors.centerIn: parent
        spacing: 2
        RowLayout {
          spacing: 4
          Text { text: ""; color: "#fab387"; font.family: card.center.iconFont; font.pixelSize: 13 }
          Text { text: "CPU " + card.cpu + "%"; color: card.center.text; font.family: "Adwaita Sans"; font.pixelSize: 12; font.weight: Font.DemiBold }
        }
        Text { text: card.temp > 0 ? card.temp + "°C" : "Normal"; color: card.temp > 75 ? "#f38ba8" : card.center.textMuted; font.family: "Adwaita Sans"; font.pixelSize: 11 }
      }
    }

    // RAM Pill
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 46
      radius: 10
      color: card.center.well
      ColumnLayout {
        anchors.centerIn: parent
        spacing: 2
        RowLayout {
          spacing: 4
          Text { text: "󰍛"; color: "#cba6f7"; font.family: card.center.iconFont; font.pixelSize: 13 }
          Text { text: "RAM " + card.ramPercent + "%"; color: card.center.text; font.family: "Adwaita Sans"; font.pixelSize: 12; font.weight: Font.DemiBold }
        }
        Text { text: card.ramUsed + "G / " + card.ramTotal + "G"; color: card.center.textMuted; font.family: "Adwaita Sans"; font.pixelSize: 11 }
      }
    }

    // GPU Pill (RTX 4060)
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 46
      radius: 10
      color: card.center.well
      ColumnLayout {
        anchors.centerIn: parent
        spacing: 2
        RowLayout {
          spacing: 4
          Text { text: "󰢮"; color: "#a6e3a1"; font.family: card.center.iconFont; font.pixelSize: 13 }
          Text { text: "RTX 4060 " + card.gpuUtil + "%"; color: card.center.text; font.family: "Adwaita Sans"; font.pixelSize: 12; font.weight: Font.DemiBold }
        }
        Text { text: (card.gpuTemp > 0 ? card.gpuTemp + "°C · " : "") + (card.gpuMemUsed > 0 ? Math.round(card.gpuMemUsed/1024*10)/10 + "G VRAM" : ""); color: card.gpuTemp > 75 ? "#f38ba8" : card.center.textMuted; font.family: "Adwaita Sans"; font.pixelSize: 11 }
      }
    }
  }
}
}
