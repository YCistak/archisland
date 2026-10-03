import QtQuick
import Quickshell.Io

// The island's own settings, saved to ~/.config/archisland/island.json and
// changed live from Settings. `values` is the adapter: read and assign its
// properties directly. A missing file is written with the defaults below.
Item {
  id: islandSettings
  required property string home
  readonly property QtObject values: settingsData

  FileView {
    path: islandSettings.home + "/.config/archisland/island.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()
    onLoadFailed: function(error) {
      if (error !== FileViewError.FileNotFound) return
      writeAdapter()
      Qt.callLater(reload)
    }
    JsonAdapter {
      id: settingsData
      property real motionScale: 1.5
      property bool hoverLift: true
      property bool clock24h: true
      property bool mediaPill: true
      property bool ignoreBrowserMedia: true
      property bool volumeHud: true
      property int bannerSeconds: 5
      property bool notch: false
      property bool downloads: true
      property bool clipboard: true
      property bool systemUpdates: true
      property bool batteryActivity: true
      property bool bluetoothActivity: true
      property bool workspaceHud: false
      // Masaüstü değişince numaranın yanında o masaüstündeki uygulamaları göster
      property bool workspaceHudApps: true
      property bool keyboardHud: true
      property bool colorfulSettingsIcons: true
      property bool colorfulLiveActivities: true
      property string controlCenterOrder: "wifi,bluetooth,focus,night,sound,microphone,display"
      property string controlCenterHidden: "game,power,keyboard"
      property bool microphoneMuteControl: false
      property string askAi: "chatgpt"
      // Modüller (bkz. services/Modules.js). Geliştirici paketi varsayılan kapalı.
      property bool calendar: true
      property bool aiQuota: false
      property bool githubPrs: false
      property bool devPorts: false
      property bool docker: false
      // GitHub PR kartında gösterilecek depolar: ["sahip/depo", ...]
      property var devRepos: []
      // Canlı etkinlikler: kalan AI kotası bu yüzdenin altına düşünce uyarı;
      // kota uyarısının ekranda kalma süresi (saniye);
      // ajan "bitti" banner'ının süresi (saniye).
      property int aiQuotaWarnPercent: 20
      property int aiQuotaAlertSeconds: 60
      property bool aiAgents: false
      property int agentDoneSeconds: 6
    }
  }
}
