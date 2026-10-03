import QtQuick

// Kodlama ajanı / AI düşünme göstergesi:
// Dönen (spinning) animasyon yerine sakin, nefes alan, yumuşak ışık dalgası yayan
// organik Claude / AI kıvılcımı ve parıltı aurası.
Item {
  id: dots
  property bool running: true
  property color dotColor: "#d97757"
  property string glyph: ""
  implicitWidth: 36
  implicitHeight: 36

  // 1. Sakin nefes alma nabzı (Breathing pulse): 0 -> 1 -> 0
  property real breath: 0
  SequentialAnimation on breath {
    loops: Animation.Infinite
    running: dots.running && dots.visible
    NumberAnimation {
      from: 0; to: 1
      duration: 1400
      easing.type: Easing.InOutSine
    }
    NumberAnimation {
      from: 1; to: 0
      duration: 1400
      easing.type: Easing.InOutSine
    }
  }

  // 2. Dışa yayılan yumuşak ışık dalgası (Radiant ripple): 0 -> 1
  property real ripple: 0
  NumberAnimation on ripple {
    from: 0; to: 1
    duration: 2400
    loops: Animation.Infinite
    running: dots.running && dots.visible
  }

  // Dışa yayılan yumuşak ışık halkası
  Rectangle {
    anchors.centerIn: parent
    readonly property real size: 12 + 18 * dots.ripple
    width: size
    height: size
    radius: size / 2
    color: "transparent"
    border.width: 1.5
    border.color: dots.dotColor
    opacity: (1.0 - dots.ripple) * 0.45
  }

  // Merkezdeki yumuşak nefes alan parıltı aurası
  Rectangle {
    anchors.centerIn: parent
    readonly property real auraSize: 18 + 6 * dots.breath
    width: auraSize
    height: auraSize
    radius: auraSize / 2
    color: dots.dotColor
    opacity: 0.12 + 0.18 * dots.breath
  }

  // İç halesi (glow halo)
  Rectangle {
    anchors.centerIn: parent
    readonly property real coreHaloSize: 13 + 3 * dots.breath
    width: coreHaloSize
    height: coreHaloSize
    radius: coreHaloSize / 2
    color: dots.dotColor
    opacity: 0.25 + 0.25 * dots.breath
  }

  // Merkezdeki Claude kıvılcımı
  Text {
    id: glyphText
    anchors.centerIn: parent
    text: dots.glyph
    color: dots.dotColor
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 15 + 2 * dots.breath
  }
}
