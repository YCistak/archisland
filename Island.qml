import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import "components"
import "services"
import "views"

Item {
  id: root
  property var shell: null
  property var manifest: null
  property var pluginRegistry: null
  property var barWidgetRegistry: null
  property var barConfig: ({})
  property string archislandPath: ""

  readonly property var nowPlaying: nowPlayingData
  NowPlaying { id: nowPlayingData; shell: root.shell; theme: root.theme; settings: root.settings }
  // Hangi kalıcı canlı etkinliğin ana hap, hangisinin küçük kabarcık
  // olacağı ve öncelik sırası: services/LiveActivities.qml.
  readonly property var live: liveActivities
  LiveActivities { id: liveActivities; host: root }
  readonly property bool mediaPill: live.ana === "medya"
  onMediaPillChanged: console.log("DEBUG_ISLAND: mediaPill =", mediaPill, "view =", view, "needsSetup =", setup.needsSetup, "settings.mediaPill =", settings.mediaPill, "downloadPill =", downloadPill, "downloadDone =", downloadDone, "pkgFinished =", packages.finishedTitle, "dlFinished =", downloads.finishedName)

  property string askQuestion: ""
  readonly property var askProviders: ({
    claude: { name: "Claude", cli: "claude", glyph: "\uec82", tile: "#d97757", ink: "#ffffff" },
    chatgpt: { name: "Codex", cli: "codex", glyph: "\uec81", tile: "#f2f2f2", ink: "#000000" }
  })
  readonly property var askProvider: settings.askAi === "none" ? null : askProviders[settings.askAi] || askProviders.chatgpt
  function ask(question) {
    question = String(question || "").trim()
    if (!question || !askProvider) return
    askQuestion = question
    view = "answer"
  }

  readonly property var downloads: downloadTracker
  DownloadTracker { id: downloadTracker; enabled: root.settings.downloads }
  readonly property var packages: packageTracker
  PackageUpdateTracker { id: packageTracker; enabled: root.settings.systemUpdates }
  readonly property bool downloadDone: live.ana === "indirme"
    && (downloads.finishedName !== "" || packages.finishedTitle !== "")
  readonly property bool downloadActive: live.ana === "indirme" && !downloadDone
  readonly property bool downloadPill: downloadDone || downloadActive
  Process { id: downloadOpener }
  function openDownloads() {
    if (!downloads.active && downloads.finishedName === "") {
      packages.dismissFinished()
      return
    }
    var path = downloadDone ? downloads.finishedPath : downloads.folder
    downloads.dismissFinished()
    downloadOpener.command = ["sh", "-c", '[ -e "$1" ] && exec xdg-open "$1"; exec xdg-open "$(dirname "$1")"', "sh", path]
    downloadOpener.startDetached()
  }

  readonly property real volume: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
    ? Pipewire.defaultAudioSink.audio.volume : -1
  readonly property bool muted: !!(Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
    && Pipewire.defaultAudioSink.audio.muted)
  readonly property string wantedOutput: String(barConfig.output || "DP-1")
  readonly property string outputName: {
    var screens = Quickshell.screens
    for (var i = 0; i < screens.length; i++)
      if (screens[i].name === wantedOutput) return wantedOutput
    var focused = Hyprland.focusedMonitor
    if (focused && focused.name) return String(focused.name)
    return screens.length ? String(screens[0].name) : ""
  }
  readonly property string home: Quickshell.env("HOME")

  readonly property var theme: themeData
  Theme { id: themeData; settings: root.settings; home: root.home }
  readonly property QtObject settings: islandSettings.values
  IslandSettings { id: islandSettings; home: root.home }

  readonly property var clockDate: clock.date
  property string view: "rest"
  readonly property bool notificationPill: view === "feedback" && feedbackKind === "notification"
  readonly property bool volumePill: view === "feedback" && feedbackKind === "volume"
  readonly property bool clipboardPill: view === "feedback" && feedbackKind === "clipboard"
  readonly property bool activityPill: view === "feedback" && feedbackKind === "activity"
  readonly property bool workspacesPill: view === "feedback" && feedbackKind === "workspaces"
  readonly property bool keyboardPill: view === "feedback" && feedbackKind === "keyboard"
  readonly property bool agentDonePill: view === "feedback" && feedbackKind === "agent"

  // ---------- Geliştirici canlı etkinlikleri: ajanlar, AI kota ----------

  // Ajan durumu kancalardan IPC ile gelir (bkz. hooks/, `island agent`).
  readonly property var agents: agentActivity
  AgentActivity {
    id: agentActivity
    enabled: !!root.settings.aiAgents
    onBitti: function(ajan) {
      // Limit kartı için kota verisi yoksa bir kez yokla (bkz. AgentDonePill).
      if (!root.aiQuota.limitler(ajan)) root.aiQuota.yokla()
      root.showFeedback("", Math.max(1, root.settings.agentDoneSeconds || 6) * 1000, "agent")
    }
  }
  readonly property bool agentPill: live.ana === "ajan" || live.ana === "ajanOnay"
  readonly property var aiQuota: aiQuotaWatch
  AiQuotaWatch {
    id: aiQuotaWatch
    enabled: !!root.settings.aiQuota
    pluginDir: root.setup.pluginDir
    esik: root.settings.aiQuotaWarnPercent > 0 ? root.settings.aiQuotaWarnPercent : 20
  }
  readonly property bool quotaPill: live.ana === "kota"
  // Kota uyarısı tek seferlik: ana island'da aiQuotaAlertSeconds (varsayılan
  // 60 sn) kalır, tıklanmazsa kendiliğinden kapanır. Uyarı ana island'da
  // değilken (ör. onay bekleyen ajan önde) süre işlemez.
  Timer {
    id: kotaSure
    interval: Math.max(1, root.settings.aiQuotaAlertSeconds || 60) * 1000
    running: root.quotaPill
    property var alarm: root.aiQuota.alarm
    onAlarmChanged: if (running) restart()
    onTriggered: root.aiQuota.kapat()
  }
  // Geliştirici görünümünü belli bir sekmede aç (ör. "ai").
  property string devTab: ""
  function openDev(tab) {
    if (!viewAllowed("dev")) return
    devTab = String(tab || "")
    view = "dev"
  }
  // Ana island'daki etkinliğin detayı: island'a SAĞ tık (kabarcık tıklaması
  // ise yer değiştirir: LiveActivities.degistir). Sol tık her zaman island'ın
  // kendisini (kontrol merkezi) açar.
  function openActivity(etkinlik) {
    if (!etkinlik) return
    if (etkinlik.id === "ajan" || etkinlik.id === "ajanOnay" || etkinlik.id === "kota") {
      if (viewAllowed("dev") && settings.aiQuota) openDev("ai")
      else view = "controls"
    }
    else if (etkinlik.id === "indirme") openDownloads()
    else if (etkinlik.gorunum && viewAllowed(etkinlik.gorunum)) view = etkinlik.gorunum
  }

  // Island'a tıklama (fare ve IPC aynı işlevi kullanır). Sol: island'ın
  // kendisi; sağ: ana etkinliğin detayı, etkinlik yoksa takvim.
  function islandClick(right) {
    feedbackTimer.stop()
    if (right) {
      if (view !== "rest") return
      if (live.anaEtkinlik && live.ana !== "kurulum") openActivity(live.anaEtkinlik)
      else if (viewAllowed("calendar")) view = "calendar"
      return
    }
    if (notificationPill && notifications.last && notifications.last.islandUpdate) updateIsland()
    else if (notificationPill && notifications.last && notifications.last.islandSetupRetry) { feedbackKind = ""; view = "rest"; setup.install() }
    else if (notificationPill) dismissPillNotification()
    else if (clipboardPill) view = "clipboard"
    else if (activityPill) view = activities.current.kind === "bluetooth" ? "bluetooth" : "controls"
    else if (view === "rest" && setup.needsSetup) setup.pillClicked()
    else if (quotaPill) aiQuota.kapat()
    else if (agentDonePill) { feedbackKind = ""; view = "rest" }
    else view = "controls"
  }

  // ---------- Workspace switches ----------

  // ArchIsland's bar's workspaces: 1–5 always, and any other up to 10 that
  // exists. Switching shows them for a moment (see WorkspacePill).
  readonly property var workspaceIds: {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }
    return ids.sort(function(a, b) { return a - b })
  }
  readonly property int focusedWorkspaceId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
  property bool isFullscreen: false
  onIsFullscreenChanged: console.log("DEBUG_FULLSCREEN: isFullscreen =", isFullscreen)
  Timer {
    interval: 300
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!fsChecker.running) fsChecker.running = true
    }
  }
  Process {
    id: fsChecker
    command: ["hyprctl", "activeworkspace", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var d = JSON.parse(text)
          root.isFullscreen = !!d.hasfullscreen
        } catch(e) {
          console.log("FS_CHECKER_ERROR:", e)
        }
      }
    }
  }
  onFocusedWorkspaceIdChanged: {
    if (activities.ready && settings.workspaceHud && focusedWorkspaceId > 0) showFeedback("", 1200, "workspaces")
  }

  // ---------- Keyboard layout switches ----------

  // The main keyboard's layouts ("us", "mn") and which is active, read from
  // Hyprland on each switch and shown for a moment (see KeyboardPill).
  // Hyprland also sends activelayout on focus and workspace changes, so the
  // pill only shows when the active layout differs from the last reading.
  property bool keyboardLayoutKnown: false
  property string keyboardLayoutName: ""
  property var keyboardLayoutCodes: []
  property int keyboardLayoutIndex: 0
  Process {
    id: keyboardLayoutRead
    command: ["hyprctl", "devices", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var boards = JSON.parse(text).keyboards || []
          var main = boards.filter(function(k) { return k.main })[0] || boards[0]
          if (!main) return
          var name = String(main.active_keymap || "")
          var changed = root.keyboardLayoutKnown && name !== root.keyboardLayoutName
          root.keyboardLayoutKnown = true
          root.keyboardLayoutName = name
          root.keyboardLayoutCodes = String(main.layout || "").split(",").filter(function(l) { return l !== "" })
          root.keyboardLayoutIndex = main.active_layout_index || 0
          if (changed) root.showFeedback("", 1400, "keyboard")
        } catch (e) {}
      }
    }
  }
  // "activelayout>>keyboard,layout" arrives whenever any keyboard switches;
  // Hyprland is only asked for the rest when the layout's name is new.
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name !== "activelayout" || !root.activities.ready || !root.settings.keyboardHud || keyboardLayoutRead.running) return
      if (root.keyboardLayoutKnown && event.parse(2)[1] === root.keyboardLayoutName) return
      keyboardLayoutRead.running = true
    }
  }

  // ---------- Device live activities: battery, Bluetooth ----------

  readonly property var activities: deviceActivities
  DeviceActivities {
    id: deviceActivities
    settings: root.settings
    onShow: root.showFeedback("", 3200, "activity")
  }


  // Takvim verisi: takvim görünümü ve "sıradaki etkinlik" hapı paylaşır.
  readonly property var calendar: calendarEvents
  CalendarEvents {
    id: calendarEvents
    enabled: !!root.settings.calendar
    pluginDir: root.setup.pluginDir
    now: root.clockDate
  }
  readonly property bool devEnabled: !!(settings.aiQuota || settings.githubPrs || settings.devPorts || settings.docker)
  // Modülü kapalı görünüm açılmaz.
  function viewAllowed(name) {
    if (name === "calendar") return !!settings.calendar
    if (name === "dev") return devEnabled
    return true
  }
  // Bir saat içinde etkinlik varsa dinlenme hâlinde küçük canlı etkinlik.
  readonly property bool eventPill: live.ana === "takvim"

  readonly property var clipboard: clipboardWatcher
  ClipboardWatcher {
    id: clipboardWatcher
    home: root.home
    settings: root.settings
    onCopied: root.showFeedback("", 2200, "clipboard")
  }

  property bool surfaceContentReady: false
  property string feedback: ""
  property string feedbackKind: ""
  property var surfaceNames: []
  function registerSurface(name) {
    if (surfaceNames.indexOf(name) === -1) surfaceNames = surfaceNames.concat([name])
  }
  readonly property bool surfaceOpen: surfaceNames.indexOf(view) !== -1
  property bool initialized: false
  readonly property bool barHidden: barOffFlag.count > 0
  FolderListModel {
    id: barOffFlag
    folder: "file://" + root.home + "/.local/state/archisland/toggles"
    nameFilters: ["bar-off"]
    showDirs: false
    showHidden: true
  }
  readonly property int barSize: 0
  readonly property string position: "top"

  function surfaceOpenFor(v) { return surfaceNames.indexOf(v) !== -1 }

  // Bir görünüm (yüzey) kapanırken island eski yumuşak inişle küçülür;
  // canlı etkinlik geçişlerindeki yay eğrisi yalnızca bunun dışında.
  property string oncekiGorunum: "rest"
  property bool yuzeyKapaniyor: false
  Timer {
    id: yuzeyKapanisTimer
    interval: root.theme.motionDuration("collapse")
    onTriggered: root.yuzeyKapaniyor = false
  }
  readonly property bool canliGecis: !surfaceOpen && !yuzeyKapaniyor

  onViewChanged: {
    if (surfaceOpenFor(oncekiGorunum) && !surfaceOpenFor(view)) {
      yuzeyKapaniyor = true
      yuzeyKapanisTimer.restart()
    }
    oncekiGorunum = view
    if (view === "rest" && updateAnnouncePending) Qt.callLater(announceUpdate)
    surfaceContentReady = false
    if (surfaceOpenFor(view)) surfaceRevealTimer.restart()
    else surfaceRevealTimer.stop()
  }

  SystemClock { id: clock; precision: SystemClock.Minutes }
  PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

  function showFeedback(message, duration, kind) {
    if (surfaceOpen) return
    if (feedbackKind === "notification" && kind !== "notification" && feedbackTimer.running) return
    feedback = String(message || "")
    feedbackKind = String(kind || "system")
    view = "feedback"
    feedbackTimer.interval = duration || 2800
    feedbackTimer.restart()
  }

  // The HUD shows when the volume or mute state differs from the last one seen
  // on the same output. An output's first reading (at startup, or after
  // switching outputs) is it reporting in, so it's only remembered.
  property var hudSink: null
  property real hudVolume: -1
  property bool hudMuted: false
  function volumeFeedback() {
    var sink = Pipewire.defaultAudioSink
    if (!initialized || !sink || !sink.ready || volume < 0) return
    var changed = hudSink === sink && (volume !== hudVolume || muted !== hudMuted)
    hudSink = sink
    hudVolume = volume
    hudMuted = muted
    if (changed && settings.volumeHud) showFeedback("", 1800, "volume")
  }
  readonly property bool sinkReady: !!(Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.ready)
  onVolumeChanged: volumeFeedback()
  onMutedChanged: volumeFeedback()
  onSinkReadyChanged: volumeFeedback()
  Component.onCompleted: {
    initialized = true
    keyboardLayoutRead.running = true
    console.log("DEBUG_STARTUP: mediaPill =", mediaPill, "nowPlaying.playing =", nowPlaying.playing, "needsSetup =", setup.needsSetup, "status =", setup.status, "pkgTitle =", packages.finishedTitle, "dlName =", downloads.finishedName)
  }

  readonly property var setup: companionSetup
  CompanionSetup {
    id: companionSetup
    home: root.home
    onFailureBanner: function(row) { root.showBanner(row, 10000) }
  }

  readonly property var updater: islandUpdater
  IslandUpdater {
    id: islandUpdater
    pluginDir: root.setup.pluginDir
    onAvailable: root.announceUpdate()
  }
  // The banner waits until nothing else is on the island.
  property bool updateAnnouncePending: false
  function announceUpdate() {
    if (surfaceOpen || view === "feedback") { updateAnnouncePending = true; return }
    updateAnnouncePending = false
    showBanner(updater.bannerRow("A new version is ready. Click to update."), 10000)
  }
  function updateIsland() {
    if (updater.status === "updating") return
    showBanner(updater.bannerRow("Updating Island…"), 120000)
    updater.update()
  }

  Timer {
    id: feedbackTimer
    repeat: false
    onTriggered: {
      if (root.view === "feedback") root.view = "rest"
      root.feedbackKind = ""
    }
  }

  Timer {
    id: surfaceRevealTimer
    interval: root.theme.contentRevealDelay
    repeat: false
    onTriggered: root.surfaceContentReady = true
  }

  readonly property var notifications: notificationClient
  NotificationClient {
    id: notificationClient
    home: root.home
    historyVisible: root.view === "controls"
    onArrived: function(row) {
      if (!root.surfaceOpen) root.showFeedback(String(row.summary || row.app || "Notification"), root.settings.bannerSeconds * 1000, "notification")
    }
  }
  // The island's own banners (setup, updates) in the notification pill.
  function showBanner(row, duration) {
    notifications.last = row
    showFeedback("", duration, "notification")
  }

  function dismissPillNotification() {
    var row = notifications.last
    feedbackKind = ""
    view = "rest"
    if (row) notifications.command("dismissKey", row)
  }

  property string menuRoute: "root"

  function toggleView(name) {
    if (!viewAllowed(name)) return view
    view = view === name ? "rest" : name
    return view
  }

  IpcHandler {
    target: "guilhermerisu.island"
    function show(name: string): string {
      if (name === "menu") root.menuRoute = "root"
      return root.toggleView(name)
    }
    function openMenu(route: string): string {
      root.menuRoute = String(route || "root")
      root.view = "menu"
      return root.view
    }
    function toggle(): string { return root.toggleView("controls") }
    function themes(): string { return root.toggleView("themes") }
    function wallpapers(): string { return root.toggleView("wallpapers") }
    function apps(): string { return root.toggleView("apps") }
    function power(): string { return root.toggleView("power") }
    function ask(question: string): string {
      root.ask(question)
      return root.view
    }
    function companionStatus(): string { return root.setup.status }
    function installCompanion(): string {
      root.setup.install()
      return "installing"
    }
    function showHistory(): string {
      root.view = "controls"
      return root.view
    }
    function close(): string {
      root.view = "rest"
      return "rest"
    }
    // Kodlama ajanı durumu (aiAgents modülü): ajan = claude|agy|gemini|codex,
    // durum = working|waiting|done|idle, oturum = oturum kimliği.
    function agent(name: string, state: string, session: string): string {
      return root.agents.bildir(name, state, session)
    }
    // Kabarcık ile ana island'ın yerini değiştir (kabarcık tıklamasıyla aynı
    // işlev): hedef = etkinlik kimliği (medya, ajan, kota…) ya da kabarcık
    // sırası (0, 1). Dönüş: yeni ana etkinlik.
    function swap(target: string): string {
      return root.live.degistir(target)
    }
    // Island'a tıklama (fareyle aynı işlev): "left" ya da "right".
    function click(button: string): string {
      if (button !== "left" && button !== "right") return "hata: left|right"
      root.islandClick(button === "right")
      return root.view
    }
    // Kota uyarısını kapat (uyarıya tıklamakla aynı işlev).
    function dismiss(): string {
      var vardi = !!root.aiQuota.alarm
      root.aiQuota.kapat()
      return vardi ? "kapandi" : "uyari yok"
    }
  }

  // An open view closes on a click outside the island (see outsideArea),
  // armed a moment after it opens so the click that opened it can't count.
  property bool outsideClickArmed: false
  readonly property bool closesOnOutsideClick: surfaceOpen && outsideClickArmed
  Timer {
    interval: 120
    running: root.surfaceOpen && !root.outsideClickArmed
    onTriggered: root.outsideClickArmed = true
  }
  onSurfaceOpenChanged: if (!surfaceOpen) outsideClickArmed = false
  Variants {
    model: Quickshell.screens
    delegate: Component {
      PanelWindow {
        id: window
        required property var modelData
        screen: modelData
        visible: modelData.name === root.outputName
        // i. kabarcık görünürse kendisi, değilse null (giriş maskesi için).
        function kabarcik(i) {
          var b = kabarcikRep.count > i ? kabarcikRep.itemAt(i) : null
          return b && b.shown ? b : null
        }
        color: "transparent"
        surfaceFormat.opaque: false
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "archisland-island"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: island.activeSurface && island.activeSurface.wantsKeyboard
          ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        // Only the island takes input, except while a view is open: then the
        // whole screen does, so outsideArea can close it. The island holds the
        // keyboard exclusively then, and Hyprland sends no pointer input to
        // any other surface, so a focus grab or a separate layer never sees
        // the click. The click that closes the view goes no further.
        mask: Region {
          item: (root.isFullscreen && root.view === "rest") ? null : (root.closesOnOutsideClick ? outsideArea : island)
          // Görünen canlı etkinlik kabarcıkları da tıklanabilir (kimlik başına
          // bir kabarcık; bkz. LiveActivities.kabarcikKimlikleri).
          Region { item: window.kabarcik(0) }
          Region { item: window.kabarcik(1) }
          Region { item: window.kabarcik(2) }
          Region { item: window.kabarcik(3) }
          Region { item: window.kabarcik(4) }
        }
        MouseArea {
          id: outsideArea
          anchors.fill: parent
          enabled: root.closesOnOutsideClick
          acceptedButtons: Qt.AllButtons
          // Clicks on the island's blank space fall through to here too.
          onPressed: function(mouse) {
            if (!island.contains(mapToItem(island, mouse.x, mouse.y))) root.view = "rest"
          }
        }


        Canvas {
          id: leftEar
          readonly property real r: 10
          visible: root.settings.notch && !(root.isFullscreen && root.view === "rest")
          x: island.x - r
          y: island.y
          width: r
          height: r
          onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.fillStyle = root.theme.background
            ctx.beginPath()
            ctx.moveTo(r, 0)
            ctx.lineTo(r, r)
            ctx.arc(0, r, r, 0, -Math.PI / 2, true)
            ctx.closePath()
            ctx.fill()
          }
        }
        Canvas {
          id: rightEar
          readonly property real r: 10
          visible: root.settings.notch && !(root.isFullscreen && root.view === "rest")
          x: island.x + island.width
          y: island.y
          width: r
          height: r
          onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.fillStyle = root.theme.background
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(0, r)
            ctx.arc(r, r, r, Math.PI, 1.5 * Math.PI, false)
            ctx.closePath()
            ctx.fill()
          }
        }

        Rectangle {
          id: island
          x: (parent.width - width) / 2
          y: (root.barHidden || (root.isFullscreen && root.view === "rest")) ? -height - 20 : root.settings.notch ? 0 : 8
          visible: !(root.isFullscreen && root.view === "rest")
          Behavior on y { MotionAnimation { theme: root.theme; pace: "standard" } }
          readonly property Item activeSurface: views.surfaceFor(root.view)
          readonly property real targetWidth: activeSurface ? activeSurface.islandWidth
            : root.notificationPill ? 440
            : root.volumePill ? 240
            : root.activityPill && root.activities.current.kind === "bluetooth" ? 360
            : root.clipboardPill || root.activityPill ? 320
            : root.workspacesPill ? workspacePill.islandWidth
            : root.keyboardPill ? 170 + root.keyboardLayoutCodes.length * 38
            : root.agentDonePill ? (root.aiQuota.limitler(root.agents.sonBiten) ? 400 : 260)
            : root.view === "feedback" ? 280
            : root.setup.needsSetup ? (root.setup.warning.length > 24 ? 320 : 250)
            : root.downloadDone ? 360
            : root.downloadActive ? (root.downloads.active ? 240 : 280)
            : root.mediaPill ? 240
            // Ajan ve takvim haplarında sağdaki saat için ölçülü ek genişlik
            // (onay beklerken saat yok; bkz. PillClock).
            : root.agentPill ? (root.agents.bekleyenVar ? 280 : 320)
            : root.quotaPill ? 250
            : root.eventPill ? 340
            : 100
          readonly property real targetHeight: activeSurface ? activeSurface.islandHeight
            : root.notificationPill ? 84
            : root.activityPill && root.activities.current.kind === "bluetooth" ? 64
            : root.clipboardPill || root.activityPill || root.keyboardPill || root.agentDonePill ? (root.settings.notch ? 40 : 44)
            : root.workspacesPill ? (root.settings.notch ? 36 : 40)
            : root.downloadDone ? 64
            : root.mediaPill || root.downloadPill || root.eventPill || root.agentPill || root.quotaPill ? (root.settings.notch ? 40 : 44)
            : root.volumePill ? (root.settings.notch ? 40 : 44)
            : root.view === "rest" ? (root.settings.notch ? 36 : 40) : 52
          property real radiusCap: root.view === "answer" ? 44 : root.surfaceOpen ? 30 : 38
          Behavior on radiusCap {
            MotionAnimation { theme: root.theme; pace: root.surfaceOpen ? "morph" : "collapse"; curve: "morph" }
          }
          radius: Math.min(height / 2, root.settings.notch && !root.surfaceOpen ? Math.min(radiusCap, 16) : radiusCap)
          topLeftRadius: root.settings.notch ? 0 : radius
          topRightRadius: root.settings.notch ? 0 : radius
          scale: root.view === "rest" && clockHover.hovered && root.settings.hoverLift && !root.settings.notch ? 1.018 : 1
          Behavior on scale { MotionAnimation { theme: root.theme; pace: "quick" } }
          HoverHandler { id: clockHover; enabled: root.view === "rest" }
          color: root.theme.background
          clip: true
          // Width, height and corners travel together and settle softly.
          property real animatedWidth: targetWidth
          property real animatedHeight: targetHeight
          // Dinlenme hâlindeki canlı etkinlik değişimlerinde genişlik yeni
          // içeriğe hafif yaylanarak oturur (Theme "spring"); görünümler
          // açılıp kapanırken eski yumuşak iniş korunur.
          Behavior on animatedWidth {
            MotionAnimation {
              theme: root.theme
              pace: root.surfaceOpen ? "morph" : root.canliGecis ? "bubble" : "collapse"
              curve: root.canliGecis ? "spring" : "morph"
            }
          }
          Behavior on animatedHeight {
            MotionAnimation { theme: root.theme; pace: root.surfaceOpen ? "morph" : "collapse"; curve: "morph" }
          }
          width: Math.max(40, animatedWidth)
          height: Math.max(28, animatedHeight)
          Behavior on color { MotionColorAnimation { theme: root.theme } }

          // Sol tık: island'ın kendisi (kontrol merkezi); sağ tık: ana
          // etkinliğin detayı, etkinlik yoksa takvim (bkz. islandClick).
          MouseArea {
            anchors.fill: parent
            enabled: root.view === "rest" || root.view === "feedback"
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(mouse) { root.islandClick(mouse.button === Qt.RightButton) }
          }

          NotificationPill { host: root; shape: island; anchors.fill: parent }

          VolumeSlider { host: root; anchors.fill: parent }

          ClipboardPill { host: root; anchors.fill: parent }

          DevicePill { host: root; anchors.fill: parent }

          WorkspacePill { id: workspacePill; host: root; anchors.fill: parent }

          KeyboardPill { host: root; anchors.fill: parent }

          MediaPill { host: root; anchors.fill: parent }

          DownloadPill { host: root; anchors.fill: parent }

          EventPill { host: root; anchors.fill: parent }

          AgentPill { host: root; anchors.fill: parent }

          QuotaPill { host: root; anchors.fill: parent }

          AgentDonePill { host: root; anchors.fill: parent }

          IslandLabel { host: root; anchors.centerIn: parent }

          Views { id: views; host: root; anchors.fill: parent }
        }

        // Ana island'a sığmayan canlı etkinlikler: island'ın sağında 1.,
        // solunda 2. küçük kabarcık. Island'dan sonra gelir ki üstünde çizilsin
        // (island'dan ayrılırken/emilirken kenarla birleşik görünür).
        Item {
          id: kabarcikAlani
          anchors.fill: parent
          // Temsilcinin kendi "island" özelliğiyle çakışmasın diye.
          readonly property Item ada: island
          Repeater {
            id: kabarcikRep
            model: root.live.kabarcikKimlikleri
            delegate: LiveBubble {
              required property string modelData
              host: root
              island: kabarcikAlani.ada
              kimlik: modelData
            }
          }
        }
      }
    }
  }

  Variants {
    model: Quickshell.screens
    delegate: Component {
      PanelWindow {
        id: spacer
        required property var modelData
        screen: modelData
        visible: modelData.name === root.outputName && !(root.isFullscreen && root.view === "rest")
        color: "transparent"
        surfaceFormat.opaque: false
        anchors { top: true; left: true; right: true }
        height: 42
        exclusionMode: ExclusionMode.Auto
        WlrLayershell.namespace: "archisland-island-spacer"
        WlrLayershell.layer: WlrLayer.Top
        mask: Region {}
      }
    }
  }
}
