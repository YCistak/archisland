import QtQuick

// Kodlama ajanı / Siri düşünme göstergesi: akıcı, organik, donanımsal
// hızlandırmalı yumuşak ışık parçacıkları ve soluk alan aurası.
Item {
  id: dots
  property bool running: true
  property color dotColor: "#ffffff"
  implicitWidth: 36
  implicitHeight: 36

  // Faz animasyonu: parçacıkların dalgalanması ve nefes alması için
  property real phase: 0
  NumberAnimation on phase {
    from: 0
    to: Math.PI * 2
    duration: 2200
    loops: Animation.Infinite
    running: dots.running && dots.visible
  }

  // Yörünge dönüşü: kesintisiz ve takılmasız (vsync kilitli) dönüş
  property real spin: 0
  NumberAnimation on spin {
    from: 0
    to: Math.PI * 2
    duration: 2800
    loops: Animation.Infinite
    running: dots.running && dots.visible
  }

  // Merkezdeki hafif nefes alan aura parıltısı
  Rectangle {
    anchors.centerIn: parent
    readonly property real auraPulse: 0.85 + 0.15 * Math.sin(dots.phase * 2)
    width: 14 * auraPulse
    height: width
    radius: width / 2
    color: dots.dotColor
    opacity: 0.14 + 0.08 * Math.sin(dots.phase)
  }

  Item {
    id: cluster
    anchors.fill: parent

    Repeater {
      model: [
        { offset: 0,              size: 6.8, amp: 1.4, r: 11.2, rAmp: 1.2, op: 0.95 },
        { offset: Math.PI * 0.45, size: 5.4, amp: 1.1, r: 10.8, rAmp: 1.0, op: 0.78 },
        { offset: Math.PI * 0.95, size: 4.2, amp: 0.9, r: 10.2, rAmp: 0.8, op: 0.58 },
        { offset: Math.PI * 1.48, size: 3.2, amp: 0.7, r: 9.6,  rAmp: 0.6, op: 0.38 }
      ]

      delegate: Item {
        required property int index
        required property var modelData

        readonly property real p: dots.phase + index * 0.65
        readonly property real curAngle: dots.spin + modelData.offset + 0.32 * Math.sin(p)
        readonly property real curRadius: modelData.r + modelData.rAmp * Math.sin(p)
        readonly property real curSize: modelData.size + modelData.amp * Math.sin(p)
        readonly property real curOpacity: Math.max(0.15, Math.min(1.0, modelData.op + 0.15 * Math.sin(p)))

        x: cluster.width / 2 + Math.cos(curAngle) * curRadius
        y: cluster.height / 2 + Math.sin(curAngle) * curRadius

        // Yumuşak ışık halesi (halo)
        Rectangle {
          anchors.centerIn: parent
          width: curSize + 3
          height: width
          radius: width / 2
          color: dots.dotColor
          opacity: curOpacity * 0.25
        }

        // Net çekirdek nokta
        Rectangle {
          anchors.centerIn: parent
          width: curSize
          height: width
          radius: width / 2
          color: dots.dotColor
          opacity: curOpacity
        }
      }
    }
  }
}
