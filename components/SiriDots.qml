import QtQuick

// Kodlama ajanı / AI düşünme göstergesi:
// Çizgilerden oluşan dönen daire (Apple iOS / macOS radyal çizgili spinner).
Item {
  id: dots
  property bool running: true
  property color dotColor: "#ffffff"
  implicitWidth: 26
  implicitHeight: 26

  Item {
    id: wheel
    anchors.fill: parent

    // Akıcı ve sürekli 360 derece dönüş
    RotationAnimation on rotation {
      from: 0
      to: 360
      duration: 1000
      loops: Animation.Infinite
      running: dots.running && dots.visible
    }

    Repeater {
      model: 12
      delegate: Item {
        id: spoke
        required property int index
        anchors.fill: parent
        rotation: index * 30

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          y: 2
          width: 2.2
          height: 5.8
          radius: 1.1
          color: dots.dotColor
          // Kuyruğa doğru azalan opaklık (0: 1.0, 11: 0.12)
          opacity: Math.max(0.12, 1.0 - (index / 12.0) * 0.88)
        }
      }
    }
  }
}
