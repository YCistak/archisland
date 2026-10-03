import QtQuick
import QtQuick.Layouts
import "../../components"

// Takvim görünümü: ay ızgarası ve seçili günün ajandası. Veri
// services/CalendarEvents.qml'den (host.calendar) gelir; etkinlik ekleme ve
// silme yerinde yapılır (CalendarAgenda.qml). ←/→ gün, ↑/↓ hafta değiştirir,
// Esc kapatır.
ColumnLayout {
  id: cal
  required property var host
  property bool active: false

  readonly property var theme: host.theme
  readonly property color card: Qt.tint(theme.background, theme.withAlpha(theme.text, 0.075))

  readonly property var monthNames: ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
    "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
  readonly property var dayNamesLong: ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"]
  readonly property var weekHeader: ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]

  property int displayYear: 2000
  property int displayMonth: 0
  property int selectedDay: 1

  function pad(n) { return String(n).padStart(2, "0") }
  function dateStr(y, m, d) { return y + "-" + pad(m + 1) + "-" + pad(d) }
  readonly property string selectedDateStr: dateStr(displayYear, displayMonth, selectedDay)
  readonly property var today: host.clockDate
  readonly property bool selectedIsToday: today.getFullYear() === displayYear
    && today.getMonth() === displayMonth && today.getDate() === selectedDay

  function goToToday() {
    displayYear = today.getFullYear()
    displayMonth = today.getMonth()
    selectedDay = today.getDate()
  }
  // Gün ya da ay kaydırma; ay sınırı aşılırsa ay da değişir.
  function moveDays(delta) {
    var d = new Date(displayYear, displayMonth, selectedDay + delta)
    displayYear = d.getFullYear()
    displayMonth = d.getMonth()
    selectedDay = d.getDate()
  }
  function moveMonth(delta) {
    var d = new Date(displayYear, displayMonth + delta, 1)
    displayYear = d.getFullYear()
    displayMonth = d.getMonth()
    selectedDay = 1
  }

  // Pazartesiyle başlayan 6 haftalık ızgara (42 hücre).
  readonly property var cells: {
    var first = new Date(displayYear, displayMonth, 1)
    var offset = (first.getDay() + 6) % 7
    var marked = {}
    var events = host.calendar.events
    for (var i = 0; i < events.length; i++) marked[events[i].date] = true
    var out = []
    for (var c = 0; c < 42; c++) {
      var d = new Date(displayYear, displayMonth, c - offset + 1)
      var inMonth = d.getMonth() === displayMonth
      out.push({
        day: d.getDate(),
        inMonth: inMonth,
        isToday: d.toDateString() === today.toDateString(),
        hasEvents: inMonth && !!marked[dateStr(d.getFullYear(), d.getMonth(), d.getDate())]
      })
    }
    return out
  }

  onActiveChanged: {
    if (!active) { agenda.closeForm(); return }
    goToToday()
    host.calendar.sync()
    Qt.callLater(function() { cal.forceActiveFocus() })
  }
  Keys.onEscapePressed: host.view = "rest"
  Keys.onLeftPressed: moveDays(-1)
  Keys.onRightPressed: moveDays(1)
  Keys.onUpPressed: moveDays(-7)
  Keys.onDownPressed: moveDays(7)

  spacing: 12

  // ---------- Başlık ----------

  RowLayout {
    Layout.fillWidth: true
    Layout.leftMargin: 4
    spacing: 6
    Text {
      Layout.fillWidth: true
      text: cal.monthNames[cal.displayMonth] + " " + cal.displayYear
      color: cal.theme.text
      font.family: "Adwaita Sans"
      font.pixelSize: 17
      font.weight: Font.DemiBold
    }
    ChipButton { theme: cal.theme; label: "󰅁"; tip: "Önceki ay"; onClicked: cal.moveMonth(-1) }
    ChipButton { theme: cal.theme; label: "󰅂"; tip: "Sonraki ay"; onClicked: cal.moveMonth(1) }
    ChipButton {
      theme: cal.theme; glyph: false; label: "Bugün"
      checked: cal.selectedIsToday; tint: cal.theme.accent
      onClicked: cal.goToToday()
    }
  }

  // ---------- Ay ızgarası ----------

  Grid {
    id: grid
    Layout.fillWidth: true
    columns: 7
    columnSpacing: 4
    rowSpacing: 4
    readonly property real cellWidth: (width - 6 * columnSpacing) / 7

    Repeater {
      model: cal.weekHeader
      delegate: Text {
        required property string modelData
        required property int index
        width: grid.cellWidth
        horizontalAlignment: Text.AlignHCenter
        text: modelData
        color: cal.theme.muted
        opacity: index >= 5 ? 0.7 : 1
        font.family: "Adwaita Sans"
        font.pixelSize: 11
        font.weight: Font.DemiBold
      }
    }

    Repeater {
      model: cal.cells
      delegate: Rectangle {
        id: cell
        required property var modelData
        readonly property bool selected: modelData.inMonth && modelData.day === cal.selectedDay
        width: grid.cellWidth
        height: 36
        radius: 12
        color: modelData.isToday ? cal.theme.accent
          : selected ? cal.theme.withAlpha(cal.theme.accent, 0.22)
          : dayMouse.containsMouse && modelData.inMonth ? cal.card
          : cal.theme.withAlpha(cal.theme.background, 0)
        Behavior on color { MotionColorAnimation { theme: cal.theme } }

        Text {
          anchors.centerIn: parent
          anchors.verticalCenterOffset: cell.modelData.hasEvents ? -3 : 0
          text: cell.modelData.day
          color: cell.modelData.isToday ? cal.theme.accentText
            : !cell.modelData.inMonth ? cal.theme.withAlpha(cal.theme.muted, 0.35)
            : cal.theme.text
          font.family: "Adwaita Sans"
          font.pixelSize: 13
          font.weight: cell.modelData.isToday || cell.selected ? Font.Bold : Font.Normal
          font.features: { "tnum": 1 }
        }
        Rectangle {
          visible: cell.modelData.hasEvents
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 5
          width: 4; height: 4; radius: 2
          color: cell.modelData.isToday ? cal.theme.accentText : cal.theme.accent
        }
        MouseArea {
          id: dayMouse
          anchors.fill: parent
          enabled: cell.modelData.inMonth
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: cal.selectedDay = cell.modelData.day
        }
      }
    }
  }

  // ---------- Seçili günün ajandası ----------

  CalendarAgenda {
    id: agenda
    Layout.fillWidth: true
    view: cal
    title: cal.selectedDay + " " + cal.monthNames[cal.displayMonth] + ", "
      + cal.dayNamesLong[new Date(cal.displayYear, cal.displayMonth, cal.selectedDay).getDay()]
  }
}
