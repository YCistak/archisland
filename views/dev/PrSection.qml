import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../components"

// githubPrs modülü: island.json'daki devRepos depolarının pull request'leri.
// Depo seç, açık/tümü süz, daldan yeni PR aç, birleştir (merge) ya da reddet.
ColumnLayout {
  id: pr
  required property var stats
  property bool active: false
  readonly property var theme: stats.host.theme

  // Depolar: "sahip/depo" biçimindekiler.
  readonly property var repos: {
    var list = stats.host.settings.devRepos
    var out = []
    if (list) for (var i = 0; i < list.length; i++) {
      var r = String(list[i]).trim()
      if (r.indexOf("/") > 0) out.push(r)
    }
    return out
  }
  property string repo: ""
  onReposChanged: if (repos.indexOf(repo) === -1) repo = repos.length ? repos[0] : ""
  Component.onCompleted: if (repos.indexOf(repo) === -1) repo = repos.length ? repos[0] : ""

  property string filter: "all"
  property var prs: []
  property var branches: []
  property bool loading: false
  property bool formOpen: false

  function hasConflict(p) { return p.mergeStateStatus === "DIRTY" || p.mergeable === "CONFLICTING" }

  function fetch() {
    if (!repo) { prs = []; branches = []; return }
    loading = true
    listProc.command = stats.script("gh-pr.sh", ["list", repo, filter])
    listProc.running = true
    branchProc.command = stats.script("gh-pr.sh", ["branches", repo])
    branchProc.running = true
  }
  // gh eylemi bitince liste tazelenir.
  function act(args) {
    actionProc.command = stats.script("gh-pr.sh", args)
    actionProc.running = true
  }
  function createPr() {
    if (!branchField.text.trim() || !titleField.text.trim()) return
    act(["create", repo, branchField.text.trim(), baseField.text.trim(), titleField.text.trim()])
    formOpen = false
    titleField.text = ""
  }

  onActiveChanged: if (active) fetch()
  onRepoChanged: { baseField.text = ""; branchField.text = ""; if (active) fetch() }
  onFilterChanged: if (active) fetch()

  Process {
    id: listProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        pr.loading = false
        try { pr.prs = JSON.parse(text) } catch (e) { pr.prs = [] }
      }
    }
  }
  Process {
    id: branchProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try { pr.branches = JSON.parse(text) || [] } catch (e) { pr.branches = [] }
        if (pr.branches.length && !branchField.text) branchField.text = pr.branches[0]
      }
    }
  }
  Process {
    id: actionProc
    onExited: pr.fetch()
  }
  Process { id: opener }

  spacing: 8

  // ---------- Depo seçici ----------

  RowLayout {
    Layout.fillWidth: true
    spacing: 6
    Flow {
      Layout.fillWidth: true
      spacing: 6
      Repeater {
        model: pr.repos
        delegate: ChipButton {
          required property string modelData
          theme: pr.theme
          glyph: false
          label: modelData.split("/")[1]
          checked: pr.repo === modelData
          tint: "#30d158"
          onClicked: pr.repo = modelData
        }
      }
      Text {
        visible: pr.repos.length === 0
        width: parent.width
        wrapMode: Text.WordWrap
        text: "No repositories added. Add some in Settings → Modules."
        color: pr.theme.muted
        font.family: "Adwaita Sans"
        font.pixelSize: 13
      }
    }
    ChipButton { theme: pr.theme; label: "󰑐"; tip: "Refresh"; onClicked: pr.fetch() }
    ChipButton {
      theme: pr.theme
      visible: pr.repo !== ""
      label: pr.formOpen ? "󰅖" : "󰐕"
      tip: pr.formOpen ? "Cancel" : "New PR"
      checked: pr.formOpen
      tint: "#ff9f0a"
      onClicked: pr.formOpen = !pr.formOpen
    }
  }

  // ---------- Süzgeç ----------

  RowLayout {
    Layout.fillWidth: true
    visible: pr.repo !== ""
    spacing: 6
    ChipButton { theme: pr.theme; glyph: false; label: "Open"; checked: pr.filter === "open"; onClicked: pr.filter = "open" }
    ChipButton { theme: pr.theme; glyph: false; label: "All"; checked: pr.filter === "all"; onClicked: pr.filter = "all" }
    Item { Layout.fillWidth: true }
    Text {
      text: pr.loading ? "Loading…" : pr.prs.length + " PR"
      color: pr.theme.muted
      font.family: "Adwaita Sans"
      font.pixelSize: 12
    }
  }

  // ---------- Yeni PR formu ----------

  Rectangle {
    Layout.fillWidth: true
    visible: pr.formOpen
    implicitHeight: form.implicitHeight + 24
    radius: 16
    color: Qt.tint(pr.theme.background, pr.theme.withAlpha(pr.theme.text, 0.075))

    ColumnLayout {
      id: form
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 12
      spacing: 8
      Text {
        text: "New PR from branch · " + pr.repo
        color: "#ff9f0a"
        font.family: "Adwaita Sans"
        font.pixelSize: 13
        font.weight: Font.DemiBold
      }
      RowLayout {
        Layout.fillWidth: true
        spacing: 6
        InputField { id: branchField; theme: pr.theme; Layout.fillWidth: true; mono: true; placeholder: "source branch"; onSubmitted: pr.createPr() }
        Text { text: "󰁔"; color: pr.theme.muted; font.family: pr.theme.fontFamily; font.pixelSize: 14 }
        InputField { id: baseField; theme: pr.theme; Layout.preferredWidth: 110; mono: true; placeholder: "default"; onSubmitted: pr.createPr() }
      }
      Flow {
        Layout.fillWidth: true
        visible: pr.branches.length > 0
        spacing: 4
        Repeater {
          model: pr.branches.slice(0, 4)
          delegate: ChipButton {
            required property string modelData
            theme: pr.theme
            glyph: false
            implicitHeight: 24
            pixelSize: 11
            label: modelData
            checked: branchField.text === modelData
            onClicked: branchField.text = modelData
          }
        }
      }
      InputField { id: titleField; theme: pr.theme; Layout.fillWidth: true; placeholder: "PR title"; onSubmitted: pr.createPr() }
      RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Item { Layout.fillWidth: true }
        ChipButton {
          theme: pr.theme; glyph: false; label: "Open in browser"
          onClicked: { opener.command = ["gh", "pr", "create", "--web", "-R", pr.repo]; opener.startDetached() }
        }
        ChipButton { theme: pr.theme; glyph: false; label: "Create PR"; checked: true; tint: "#ff9f0a"; onClicked: pr.createPr() }
      }
    }
  }

  // ---------- PR listesi ----------

  Text {
    visible: pr.repo !== "" && !pr.loading && pr.prs.length === 0
    Layout.leftMargin: 4
    text: "No PRs match this filter."
    color: pr.theme.muted
    font.family: "Adwaita Sans"
    font.pixelSize: 13
  }

  Flickable {
    Layout.fillWidth: true
    visible: pr.prs.length > 0
    implicitHeight: Math.min(340, list.implicitHeight)
    contentHeight: list.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
      id: list
      width: parent.width
      spacing: 6

      Repeater {
        model: pr.prs
        delegate: Rectangle {
          id: card
          required property var modelData
          readonly property bool open: modelData.state === "OPEN"
          readonly property bool conflict: open && pr.hasConflict(modelData)
          readonly property color stateColor: conflict ? "#ff453a" : open ? "#30d158"
            : modelData.state === "MERGED" ? "#bf5af2" : pr.theme.muted
          Layout.fillWidth: true
          implicitHeight: body.implicitHeight + 24
          radius: 16
          color: Qt.tint(pr.theme.background, pr.theme.withAlpha(pr.theme.text, 0.075))

          ColumnLayout {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 6

            RowLayout {
              Layout.fillWidth: true
              spacing: 8
              Text {
                text: "#" + card.modelData.number
                color: pr.theme.accent
                font.family: "Adwaita Sans"
                font.pixelSize: 12
                font.weight: Font.Bold
              }
              Text {
                text: card.conflict ? "Conflicts" : card.open ? "Mergeable"
                  : card.modelData.state === "MERGED" ? "Merged" : "Closed"
                color: card.stateColor
                font.family: "Adwaita Sans"
                font.pixelSize: 12
                font.weight: Font.DemiBold
              }
              Item { Layout.fillWidth: true }
              Text {
                text: "@" + card.modelData.author + "  " + (card.modelData.created || "")
                color: pr.theme.muted
                font.family: "Adwaita Sans"
                font.pixelSize: 11
              }
            }
            Text {
              Layout.fillWidth: true
              text: card.modelData.title || ""
              textFormat: Text.PlainText
              wrapMode: Text.Wrap
              maximumLineCount: 2
              elide: Text.ElideRight
              color: pr.theme.text
              font.family: "Adwaita Sans"
              font.pixelSize: 13
              font.weight: Font.DemiBold
            }
            RowLayout {
              Layout.fillWidth: true
              spacing: 6
              Text {
                Layout.fillWidth: true
                text: " " + card.modelData.head + " → " + card.modelData.base
                elide: Text.ElideRight
                color: pr.theme.muted
                font.family: "monospace"
                font.pixelSize: 11
              }
              ChipButton {
                theme: pr.theme; label: "󰖟"; tip: "Open in browser"
                onClicked: { opener.command = ["xdg-open", card.modelData.url]; opener.startDetached() }
              }
              ChipButton {
                visible: card.open
                theme: pr.theme; label: "󰅖"; tip: "Reject (close)"; ink: "#ff453a"
                onClicked: pr.act(["close", pr.repo, String(card.modelData.number)])
              }
              ChipButton {
                visible: card.open
                theme: pr.theme; label: "󰘭"
                tip: card.conflict ? "Has conflicts, cannot merge" : "Merge"
                ink: card.conflict ? pr.theme.muted : "#30d158"
                opacity: card.conflict ? 0.5 : 1
                onClicked: if (!card.conflict) pr.act(["merge", pr.repo, String(card.modelData.number), "merge"])
              }
            }
          }
        }
      }
    }
  }
}
