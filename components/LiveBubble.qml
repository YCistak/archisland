import QtQuick

// The small bubble of a live activity that does not fit on the main island.
// There are at most 2 bubbles: bubble 1 sits to the RIGHT of the island,
// bubble 2 to its LEFT (see services/LiveActivities.qml → bubbles). Each
// activity id has its own bubble object; its content does not change when the
// order changes.
// It shows only an icon + a short value; no panel opens outside the island.
// A click swaps places: this activity moves to the main island and the main
// island's activity moves into this bubble's place (LiveActivities.swap).
//
// Motion: when appearing it "splits off like a droplet" from the island edge
// on its side (scale 0.6→1, opacity); when disappearing it follows the same
// path backwards and is "absorbed" into the island. The left bubble mirrors
// the right one. If the side is about to change (the right one ended, the
// left one moved to index 1) the bubble is first absorbed at its current edge,
// then splits off again on the new side; it never passes behind the island.
Rectangle {
  id: bubble
  required property var host
  // The main island; the bubble follows its edge.
  required property Item island
  // This bubble's activity id (LiveActivities.bubbleIds).
  required property string activityId
  readonly property int slot: host.live.bubbles.indexOf(activityId)
  readonly property var activity: host.live.activity(activityId)
  // Keep the last content while the bubble disappears.
  property var last: null
  readonly property bool active: slot >= 0
  onActivityChanged: if (active && activity) last = activity
  onActiveChanged: if (active && activity) last = activity
  readonly property bool shown: active && sideReady && host.view === "rest" && island.visible

  readonly property real gap: host.settings.notch ? 16 : 8
  readonly property real targetWidth: Math.max(height, row.implicitWidth + 20)

  // Side: +1 right (bubble 1), -1 left (bubble 2). It only changes while the
  // bubble is invisible; if the target changes while visible it is absorbed first.
  readonly property int targetSide: slot === 1 ? -1 : 1
  property int side: 1
  readonly property bool sideReady: side === targetSide
  onTargetSideChanged: if (!visible) side = targetSide
  onVisibleChanged: if (!visible) side = targetSide

  // While hidden the bubble's center sits slightly inside the island edge.
  property real separation: shown ? 0 : -(gap + width * 0.6)
  Behavior on separation {
    MotionAnimation {
      theme: bubble.host.theme
      pace: bubble.shown ? "bubble" : "standard"
      curve: bubble.shown ? "spring" : "fade"
    }
  }

  x: side > 0 ? island.x + island.width + gap + separation
               : island.x - gap - width - separation
  height: host.settings.notch ? 32 : 36
  y: host.settings.notch ? 4 : island.y + (island.height - height) / 2
  width: targetWidth
  radius: height / 2
  color: host.theme.background
  border.width: 1
  border.color: host.theme.withAlpha(host.theme.text, 0.08 * (shown ? 1 : 0))

  opacity: shown ? 1 : 0
  visible: opacity > 0.01
  // An absorbed bubble passes beneath the visible one on its way back to the island.
  z: shown ? 1 : 0
  scale: shown ? 1 : 0.6
  Behavior on opacity {
    MotionAnimation { theme: bubble.host.theme; pace: bubble.shown ? "standard" : "collapse"; curve: "fade" }
  }
  Behavior on scale {
    MotionAnimation {
      theme: bubble.host.theme
      pace: bubble.shown ? "bubble" : "standard"
      curve: bubble.shown ? "spring" : "fade"
    }
  }
  Behavior on width { MotionAnimation { theme: bubble.host.theme; pace: "bubble"; curve: "spring" } }
  Behavior on border.color { MotionColorAnimation { theme: bubble.host.theme } }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 6
    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: !!bubble.last && !!bubble.last.icon
      text: bubble.last ? bubble.last.icon : ""
      color: bubble.last ? bubble.last.color : bubble.host.theme.text
      font.family: bubble.host.theme.fontFamily
      font.pixelSize: 14
    }
    SoundWave {
      anchors.verticalCenter: parent.verticalCenter
      visible: !!bubble.last && !!bubble.last.wave
      color: bubble.last ? bubble.last.color : bubble.host.theme.accent
      bars: 4
      maxHeight: 14
      playing: bubble.shown && visible
    }
    // Working agent: a small spinning ring.
    Item {
      anchors.verticalCenter: parent.verticalCenter
      visible: !!bubble.last && !!bubble.last.animated
      width: 14; height: 14
      SiriDots {
        anchors.centerIn: parent
        scale: 0.42
        running: bubble.shown && parent.visible
      }
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: text !== ""
      text: bubble.last ? bubble.last.text : ""
      color: "#e2e6de"
      font.family: "Adwaita Sans"
      font.pixelSize: 13
      font.weight: Font.DemiBold
      font.features: { "tnum": 1 }
    }
  }

  // Click: the same function as IPC `swap` (LiveActivities.swap). It sits on
  // top of the bubble; the input mask Region is this bubble itself.
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    z: 10
    enabled: bubble.shown
    hoverEnabled: bubble.host.settings.debugInput
    preventStealing: true
    onEntered: bubble.host.inputLog("bubble " + bubble.activityId + " hovered " + bubble.host.sceneRect(bubble))
    onPressed: function(mouse) {
      bubble.host.inputLog("bubble " + bubble.activityId + " press (index " + bubble.slot + ") " + bubble.host.sceneRect(bubble))
    }
    onCanceled: bubble.host.inputLog("bubble " + bubble.activityId + " press canceled")
    onClicked: {
      var result = bubble.host.live.swap(bubble.activityId)
      bubble.host.inputLog("bubble " + bubble.activityId + " click → swap: " + result)
    }
  }
}
