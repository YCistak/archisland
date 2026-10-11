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
      // Diagnostics: while true, island/bubble mouse events are logged as "[input] ..."
      // lines (journalctl --user -t archisland-shell).
      property bool debugInput: false
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
      // When the workspace changes, show that workspace's apps next to its number
      property bool workspaceHudApps: true
      property bool keyboardHud: true
      property bool colorfulSettingsIcons: true
      property bool colorfulLiveActivities: true
      property string controlCenterOrder: "wifi,bluetooth,focus,night,sound,microphone,display"
      property string controlCenterHidden: "game,power,keyboard"
      property bool microphoneMuteControl: false
      property string askAi: "chatgpt"
      // Modules (see services/Modules.js). The Developer Pack is off by default.
      property bool calendar: true
      property bool aiQuota: false
      property bool githubPrs: false
      property bool devPorts: false
      property bool docker: false
      // Repositories shown on the GitHub PR card: ["owner/repo", ...]
      property var devRepos: []
      // Live activities: alert when the remaining AI quota drops below this percent;
      // how long the quota alert stays on screen (seconds);
      // how long the agent "done" banner stays (seconds).
      property int aiQuotaWarnPercent: 20
      property int aiQuotaAlertSeconds: 60
      property bool aiAgents: false
      property int agentDoneSeconds: 6
    }
  }
}
