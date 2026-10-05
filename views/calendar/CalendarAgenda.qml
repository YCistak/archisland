import QtQuick
import QtQuick.Layouts
import "../../components"

// Seçili günün etkinlikleri, yerinde ekleme formu ve silme düğmeleri.
// Enter kaydeder; Esc görünümü kapatır.
Rectangle {
  id: agenda
  required property var view
  property string title: ""
  readonly property var theme: view.theme
  readonly property var calendar: view.host.calendar
  readonly property var events: {
    calendar.events
    return calendar.eventsOn(view.selectedDateStr)
  }
  property bool formOpen: false

  function closeForm() {
    formOpen = false
    titleField.text = ""
    timeField.text = ""
  }
  function save() {
    if (!titleField.text.trim()) { titleField.forceActiveFocus(); return }
    calendar.add(view.selectedDateStr, timeField.text, titleField.text)
    closeForm()
    view.forceActiveFocus()
  }

  implicitHeight: column.implicitHeight + 24
  radius: 18
  color: view.card

  ColumnLayout {
    id: column
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 12
    spacing: 8

    RowLayout {
      Layout.fillWidth: true
      Layout.leftMargin: 4
      spacing: 8
      Text {
        text: agenda.title
        color: agenda.theme.text
        font.family: "Adwaita Sans"
        font.pixelSize: 14
        font.weight: Font.DemiBold
      }
      Text {
        visible: agenda.view.selectedIsToday
        text: "Today"
        color: agenda.theme.accent
        font.family: "Adwaita Sans"
        font.pixelSize: 12
        font.weight: Font.DemiBold
      }
      Item { Layout.fillWidth: true }
      ChipButton {
        theme: agenda.theme
        label: agenda.formOpen ? "󰅖" : "󰐕"
        tip: agenda.formOpen ? "Cancel" : "Add event"
        checked: agenda.formOpen
        tint: agenda.theme.accent
        onClicked: {
          if (agenda.formOpen) { agenda.closeForm(); agenda.view.forceActiveFocus() }
          else { agenda.formOpen = true; titleField.input.forceActiveFocus() }
        }
      }
    }

    // Ekleme formu: ad, saat (boşsa "All day"), kaydet.
    RowLayout {
      Layout.fillWidth: true
      visible: agenda.formOpen
      spacing: 6
      InputField { id: titleField; theme: agenda.theme; Layout.fillWidth: true; placeholder: "Event title"; onSubmitted: agenda.save() }
      InputField { id: timeField; theme: agenda.theme; Layout.preferredWidth: 70; placeholder: "14:00"; mono: true; onSubmitted: agenda.save() }
      ChipButton {
        theme: agenda.theme; glyph: false; label: "Save"
        checked: true; tint: agenda.theme.accent
        onClicked: agenda.save()
      }
    }

    Text {
      visible: agenda.events.length === 0
      Layout.leftMargin: 4
      Layout.topMargin: 2
      Layout.bottomMargin: 2
      text: "No events for this day."
      color: agenda.theme.muted
      font.family: "Adwaita Sans"
      font.pixelSize: 13
    }

    Repeater {
      model: agenda.events
      delegate: Rectangle {
        id: row
        required property var modelData
        Layout.fillWidth: true
        implicitHeight: 40
        radius: 12
        color: Qt.tint(agenda.theme.background, agenda.theme.withAlpha(agenda.theme.text, rowHover.hovered ? 0.11 : 0.06))
        Behavior on color { MotionColorAnimation { theme: agenda.theme } }
        HoverHandler { id: rowHover }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 6
          spacing: 10
          Rectangle { width: 3; height: 18; radius: 1.5; color: agenda.theme.accent }
          Text {
            text: row.modelData.time || "All day"
            color: agenda.theme.accent
            font.family: "Adwaita Sans"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
          }
          Text {
            Layout.fillWidth: true
            text: row.modelData.summary || "Etkinlik"
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: agenda.theme.text
            font.family: "Adwaita Sans"
            font.pixelSize: 13
            font.weight: Font.Medium
          }
          ChipButton {
            theme: agenda.theme
            implicitWidth: 28; implicitHeight: 28
            label: "󰆴"
            pixelSize: 13
            tip: "Sil"
            ink: rowHover.hovered ? "#ff453a" : agenda.theme.muted
            onClicked: agenda.calendar.remove(row.modelData.id || row.modelData.summary)
          }
        }
      }
    }

    // Alt satır: kayıt sayısı ve elle yenileme.
    RowLayout {
      Layout.fillWidth: true
      Layout.leftMargin: 4
      Layout.topMargin: 2
      Text {
        Layout.fillWidth: true
        text: agenda.calendar.eventsCount + " saved events"
        color: agenda.theme.muted
        font.family: "Adwaita Sans"
        font.pixelSize: 11
      }
      Text {
        text: "󰑐  Refresh"
        color: refreshMouse.containsMouse ? agenda.theme.text : agenda.theme.muted
        font.family: agenda.theme.fontFamily
        font.pixelSize: 11
        Behavior on color { MotionColorAnimation { theme: agenda.theme } }
        MouseArea {
          id: refreshMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: agenda.calendar.sync()
        }
      }
    }
  }
}
