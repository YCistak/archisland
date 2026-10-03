import QtQuick

// Claude Code CLI resmi piksel maskotu: "Clawd"
// 8-bit retro piksel yengeç/ahtapot sprite'ı.
// Canlı animasyonlar:
// 1. Tiptoe / crabwalk yürüyüşü (bacakların sırayla adımlaması)
// 2. Göz kırpma (belirli aralıklarla gözlerini kırpar)
// 3. Gövde sekmesi (adımlarla senkron hafif yaylanma)
Item {
  id: clawd
  property color bodyColor: "#d97757"
  property color eyeColor: "#141414"
  property bool running: true

  // Blok boyutu: 2.0px -> Toplam genişlik 24px, yükseklik 16px
  readonly property real u: 2.0

  implicitWidth: 12 * u
  implicitHeight: 8 * u

  // 1. Yürüyüş adımları: 0 -> 1 -> 0 (alternating legs)
  property int walkStep: 0
  Timer {
    interval: 220
    repeat: true
    running: clawd.running && clawd.visible
    onTriggered: clawd.walkStep = (clawd.walkStep + 1) % 2
  }

  // 2. Göz kırpma zamanlayıcısı
  property bool blink: false
  Timer {
    interval: 2800
    repeat: true
    running: clawd.running && clawd.visible
    onTriggered: {
      clawd.blink = true
      blinkTimer.start()
    }
  }
  Timer {
    id: blinkTimer
    interval: 140
    onTriggered: clawd.blink = false
  }

  // 3. Gövde ve kollar (hafif adımlama sekmesi)
  Item {
    id: torsoGroup
    anchors.fill: parent
    y: clawd.walkStep === 1 ? -1 : 0
    Behavior on y { NumberAnimation { duration: 100 } }

    // Sol kol: x: 0..2u, y: 2..4u
    Rectangle {
      x: 0; y: 2 * clawd.u
      width: 2 * clawd.u; height: 2 * clawd.u
      color: clawd.bodyColor
    }

    // Sağ kol: x: 10..12u, y: 2..4u
    Rectangle {
      x: 10 * clawd.u; y: 2 * clawd.u
      width: 2 * clawd.u; height: 2 * clawd.u
      color: clawd.bodyColor
    }

    // Ana gövde / baş: x: 2..10u (8u genişlik), y: 0..5u (5u yükseklik)
    Rectangle {
      x: 2 * clawd.u; y: 0
      width: 8 * clawd.u; height: 5 * clawd.u
      color: clawd.bodyColor

      // Sol göz: x: 1u, y: 1u (1u genişlik, 2u yükseklik)
      Rectangle {
        x: 1 * clawd.u; y: 1 * clawd.u
        width: 1 * clawd.u
        height: clawd.blink ? 0.5 * clawd.u : 2 * clawd.u
        color: clawd.eyeColor
      }

      // Sağ göz: x: 6u, y: 1u (1u genişlik, 2u yükseklik)
      Rectangle {
        x: 6 * clawd.u; y: 1 * clawd.u
        width: 1 * clawd.u
        height: clawd.blink ? 0.5 * clawd.u : 2 * clawd.u
        color: clawd.eyeColor
      }
    }
  }

  // 4. Bacaklar (4 bacak): y: 5..7u
  // Sol dış bacak: x: 2u
  Rectangle {
    x: 2 * clawd.u
    y: 5 * clawd.u
    width: 1 * clawd.u
    height: clawd.walkStep === 0 ? 2 * clawd.u : 1.2 * clawd.u
    color: clawd.bodyColor
  }
  // Sol iç bacak: x: 4u
  Rectangle {
    x: 4 * clawd.u
    y: 5 * clawd.u
    width: 1 * clawd.u
    height: clawd.walkStep === 1 ? 2 * clawd.u : 1.2 * clawd.u
    color: clawd.bodyColor
  }
  // Sağ iç bacak: x: 7u
  Rectangle {
    x: 7 * clawd.u
    y: 5 * clawd.u
    width: 1 * clawd.u
    height: clawd.walkStep === 0 ? 2 * clawd.u : 1.2 * clawd.u
    color: clawd.bodyColor
  }
  // Sağ dış bacak: x: 9u
  Rectangle {
    x: 9 * clawd.u
    y: 5 * clawd.u
    width: 1 * clawd.u
    height: clawd.walkStep === 1 ? 2 * clawd.u : 1.2 * clawd.u
    color: clawd.bodyColor
  }
}
