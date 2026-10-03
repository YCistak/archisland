import QtQuick

// Island görünümlerindeki tek satırlık yazı alanı: koyu kuyu, odaklanınca
// vurgu kenarı, boşken soluk ipucu. Enter `submitted` sinyalini verir.
Rectangle {
  id: field
  required property var theme
  property alias text: input.text
  property alias input: input
  property string placeholder: ""
  property bool mono: false
  signal submitted()

  implicitHeight: 32
  radius: 10
  color: Qt.tint(theme.background, theme.withAlpha(theme.text, 0.05))
  border.width: 1
  border.color: input.activeFocus ? theme.accent : theme.withAlpha(theme.text, 0.12)
  Behavior on border.color { MotionColorAnimation { theme: field.theme } }

  TextInput {
    id: input
    anchors.fill: parent
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    verticalAlignment: TextInput.AlignVCenter
    clip: true
    color: field.theme.text
    selectionColor: field.theme.withAlpha(field.theme.accent, 0.4)
    font.family: field.mono ? "monospace" : "Adwaita Sans"
    font.pixelSize: 13
    Keys.onReturnPressed: field.submitted()
    Keys.onEnterPressed: field.submitted()
  }
  Text {
    anchors.left: parent.left
    anchors.leftMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    visible: !input.text
    text: field.placeholder
    color: field.theme.withAlpha(field.theme.muted, 0.7)
    font: input.font
  }
}
