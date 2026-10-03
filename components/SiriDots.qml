import QtQuick

// Apple Intelligence / Siri Liquid Aurora Orb:
// Dinamik Ada'da çalışan modern, lüks, akıcı ve organik AI düşünme göstergesi.
// Dönen çizgiler yerine yumuşak aurora renkleri, nefes alan ışık aurası ve
// sıvı cam (liquid glass) parıltısı.
Item {
  id: dots
  property bool running: true
  property color dotColor: "#ffffff"
  implicitWidth: 26
  implicitHeight: 26

  // 1. Yumuşak nefes alma nabzı
  property real breath: 0
  SequentialAnimation on breath {
    loops: Animation.Infinite
    running: dots.running && dots.visible
    NumberAnimation { from: 0; to: 1; duration: 1600; easing.type: Easing.InOutSine }
    NumberAnimation { from: 1; to: 0; duration: 1600; easing.type: Easing.InOutSine }
  }

  // 2. Sıvı aurora akış fazı (sürekli yumuşak akış)
  property real flow: 0
  NumberAnimation on flow {
    from: 0; to: Math.PI * 2
    duration: 3200
    loops: Animation.Infinite
    running: dots.running && dots.visible
  }

  // Dışa yayılan yumuşak renkli ışık aurası (Ambient glow)
  Rectangle {
    anchors.centerIn: parent
    width: 20 + 4 * dots.breath
    height: width
    radius: width / 2
    color: "#a855f7"
    opacity: 0.25 + 0.15 * dots.breath
  }

  Rectangle {
    anchors.centerIn: parent
    width: 17 + 3 * dots.breath
    height: width
    radius: width / 2
    color: "#38bdf8"
    opacity: 0.20 + 0.15 * (1.0 - dots.breath)
  }

  // Ana cam küre (Liquid glass orb)
  Rectangle {
    id: glassCore
    anchors.centerIn: parent
    width: 19
    height: 19
    radius: 9.5
    clip: true
    color: "#0a0a0c"
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.35 + 0.15 * dots.breath)

    // İçteki akıcı aurora katmanları
    // Mor/Magenta leke
    Rectangle {
      x: 1 + 3 * Math.cos(dots.flow)
      y: 1 + 3 * Math.sin(dots.flow)
      width: 14; height: 14; radius: 7
      color: "#ec4899"
      opacity: 0.75
    }
    // Mavi/Cyan leke
    Rectangle {
      x: 3 + 3 * Math.cos(dots.flow + Math.PI * 0.7)
      y: 3 + 3 * Math.sin(dots.flow + Math.PI * 0.7)
      width: 13; height: 13; radius: 6.5
      color: "#06b6d4"
      opacity: 0.75
    }
    // Sıcak Altın/Terakota leke
    Rectangle {
      x: 2 + 3 * Math.cos(dots.flow + Math.PI * 1.4)
      y: 2 + 3 * Math.sin(dots.flow + Math.PI * 1.4)
      width: 12; height: 12; radius: 6
      color: "#f59e0b"
      opacity: 0.70
    }
    // Merkezdeki parlak çekirdek parıltısı
    Rectangle {
      anchors.centerIn: parent
      width: 7 + 2 * dots.breath
      height: width
      radius: width / 2
      color: "#ffffff"
      opacity: 0.45 + 0.25 * dots.breath
    }
  }
}
