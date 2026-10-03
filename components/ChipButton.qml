import QtQuick

// Island görünümlerindeki küçük yuvarlak düğme: bir simge ya da kısa yazı.
// Renk geçişleri ortak hareket sistemiyle (MotionColorAnimation) yapılır.
Rectangle {
  id: chip
  required property var theme
  property string label: ""
  // true: simge yazı tipi (Nerd Font), false: Adwaita Sans.
  property bool glyph: true
  property color ink: theme.text
  // Seçili/vurgulu hâl (sekme, açık form...).
  property bool checked: false
  property color tint: theme.text
  property string tip: ""
  property int pixelSize: glyph ? 14 : 12
  signal clicked()

  implicitWidth: glyph && label.length <= 2 ? 30 : labelText.implicitWidth + 20
  implicitHeight: 30
  radius: height / 2
  color: checked ? theme.withAlpha(tint, mouse.containsMouse ? 0.3 : 0.22)
    : mouse.containsMouse ? Qt.tint(theme.background, theme.withAlpha(theme.text, 0.18))
    : Qt.tint(theme.background, theme.withAlpha(theme.text, 0.09))
  Behavior on color { MotionColorAnimation { theme: chip.theme } }

  Text {
    id: labelText
    anchors.centerIn: parent
    text: chip.label
    color: chip.ink
    font.family: chip.glyph ? chip.theme.fontFamily : "Adwaita Sans"
    font.pixelSize: chip.pixelSize
    font.weight: Font.DemiBold
  }
  Tooltip { theme: chip.theme; text: chip.tip }
  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: chip.clicked()
  }
}
