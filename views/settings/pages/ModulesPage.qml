import QtQuick
import QtQuick.Layouts
import "../controls"
import "../../../services/Modules.js" as Modules

// Settings → Modules: switch island features on/off by category.
// Changes are written to island.json immediately and apply without a restart.
ColumnLayout {
  id: page
  required property var view
  visible: view.currentPage === "Modules"
  Layout.fillWidth: true
  spacing: 20

  Repeater {
    model: Modules.categories
    delegate: SettingsGroup {
      id: group
      required property var modelData
      readonly property var modules: Modules.inCategory(modelData.id)
      view: page.view
      title: modelData.name
      footer: modelData.description
      Repeater {
        model: group.modules
        delegate: SettingsRow {
          required property var modelData
          required property int index
          view: page.view
          label: modelData.name
          detail: modelData.description
          last: index === group.modules.length - 1
          SettingsSwitch {
            view: page.view
            checked: !!page.view.settings[modelData.id]
            onToggled: function(on) { page.view.settings[modelData.id] = on }
          }
        }
      }
    }
  }

  // Number field: written to island.json on Enter (or when focus leaves).
  component NumberField: Rectangle {
    id: field
    required property string key
    property int minimum: 1
    property int maximum: 99
    width: 64
    height: 28
    radius: 7
    color: page.view.well
    border.width: numberInput.activeFocus ? 2 : 0
    border.color: page.view.host.theme.withAlpha(page.view.accent, 0.6)
    TextInput {
      id: numberInput
      anchors.fill: parent
      anchors.leftMargin: 8
      anchors.rightMargin: 8
      verticalAlignment: TextInput.AlignVCenter
      horizontalAlignment: TextInput.AlignRight
      validator: IntValidator { bottom: field.minimum; top: field.maximum }
      color: page.view.text
      font.family: "Adwaita Sans"
      font.pixelSize: 13
      text: String(page.view.settings[field.key])
      onEditingFinished: {
        var n = parseInt(text)
        if (!isNaN(n)) page.view.settings[field.key] = Math.max(field.minimum, Math.min(field.maximum, n))
      }
    }
  }

  // How clicks on the island work and where the clock goes (a short usage note).
  SettingsGroup {
    view: page.view
    title: "Usage"
    SettingsRow { view: page.view; label: "Left click"; detail: "The island itself: control center (dismisses the alert on a quota warning)" }
    SettingsRow { view: page.view; label: "Right click"; detail: "Details of the main activity (agent/quota: limits, music: player); the calendar if there is no activity" }
    SettingsRow { view: page.view; label: "Clock"; detail: "The clock appears on the right of the island while an activity is shown" }
    SettingsRow { view: page.view; label: "Click a bubble"; detail: "Moves that activity to the main island (pins it)"; last: true }
  }

  // Thresholds of the developer live activities.
  SettingsGroup {
    view: page.view
    visible: !!page.view.settings.aiQuota || !!page.view.settings.aiAgents
    title: "Live Activity Settings"
    footer: "The quota alert appears once on the main island when the remaining share drops below this percentage; it closes on click or when the time runs out. Press Enter to save."
    SettingsRow {
      view: page.view
      visible: !!page.view.settings.aiQuota
      label: "Quota alert threshold (% left)"
      NumberField { key: "aiQuotaWarnPercent"; minimum: 1; maximum: 99 }
    }
    SettingsRow {
      view: page.view
      visible: !!page.view.settings.aiQuota
      label: "Quota alert duration (s)"
      last: !page.view.settings.aiAgents
      NumberField { key: "aiQuotaAlertSeconds"; minimum: 5; maximum: 600 }
    }
    SettingsRow {
      view: page.view
      visible: !!page.view.settings.aiAgents
      label: "\"Done\" banner duration (s)"
      last: true
      NumberField { key: "agentDoneSeconds"; minimum: 1; maximum: 30 }
    }
  }

  // Repositories on the GitHub PR card (island.json → devRepos).
  SettingsGroup {
    view: page.view
    visible: !!page.view.settings.githubPrs
    title: "GitHub Repositories"
    footer: "Separate with commas, e.g. owner/repo, owner/other-repo. Press Enter to save."
    SettingsRow {
      view: page.view
      label: "Repositories"
      last: true
      Rectangle {
        width: 300
        height: 28
        radius: 7
        color: page.view.well
        border.width: reposInput.activeFocus ? 2 : 0
        border.color: page.view.host.theme.withAlpha(page.view.accent, 0.6)
        Text {
          anchors.left: parent.left
          anchors.leftMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          visible: reposInput.text === ""
          text: "owner/repo"
          color: page.view.textMuted
          font.family: "Adwaita Sans"
          font.pixelSize: 13
        }
        TextInput {
          id: reposInput
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          verticalAlignment: TextInput.AlignVCenter
          clip: true
          color: page.view.text
          font.family: "Adwaita Sans"
          font.pixelSize: 13
          text: (page.view.settings.devRepos || []).join(", ")
          onEditingFinished: {
            var parts = text.split(",")
            var list = []
            for (var i = 0; i < parts.length; i++) {
              var r = parts[i].trim()
              if (r.indexOf("/") > 0 && list.indexOf(r) === -1) list.push(r)
            }
            page.view.settings.devRepos = list
          }
        }
      }
    }
  }
}
