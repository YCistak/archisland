import QtQuick

// Shared enter/exit motion of the persistent live activity pills (MediaPill,
// AgentPill, QuotaPill, EventPill are built on top of it).
//  - Enter: as the island width approaches the new content (after a
//    contentRevealDelay delay) scale 0.92→1 + opacity.
//  - Exit: shrinks slightly and fades; if the activity is moving into a
//    bubble it slides toward the right edge where the bubbles are (since the
//    island clips, the content looks like it flows out over the edge).
// Every value animates through a Behavior, so on overlapping changes the
// motion turns from where it is toward the new target (retarget), no jumps.
Item {
  id: pill
  required property var host
  // Should the activity be visible on the island (bound by the subclass).
  property bool shown: false
  // The activity ids this pill represents (LiveActivities.persistent).
  property var activityIds: []
  readonly property bool inBubble: {
    var k = host.live.bubbles
    for (var i = 0; i < activityIds.length; i++) if (k.indexOf(activityIds[i]) >= 0) return true
    return false
  }
  // Is the content really revealed: becomes true shortly after entering.
  property bool revealed: false
  onShownChanged: {
    if (shown) revealTimer.restart()
    else { revealTimer.stop(); revealed = false }
  }
  Component.onCompleted: revealed = shown
  Timer {
    id: revealTimer
    interval: pill.host.theme.contentRevealDelay
    onTriggered: pill.revealed = true
  }

  opacity: revealed ? 1 : 0
  visible: opacity > 0.01
  scale: revealed ? 1 : inBubble ? 0.86 : 0.92
  transform: Translate {
    x: pill.revealed || !pill.inBubble ? 0 : 28
    Behavior on x { MotionAnimation { theme: pill.host.theme; pace: "standard"; curve: "fade" } }
  }

  Behavior on opacity {
    // A fast-falling curve on exit: the old content has mostly faded before the new one arrives.
    MotionAnimation { theme: pill.host.theme; pace: pill.revealed ? "standard" : "exit"; curve: "fade" }
  }
  Behavior on scale {
    MotionAnimation { theme: pill.host.theme; pace: pill.revealed ? "bubble" : "standard"; curve: pill.revealed ? "spring" : "fade" }
  }
}
