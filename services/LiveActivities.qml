import QtQuick

// Live activity manager: while the island is at rest (view "rest") it picks,
// in one place, which persistent activity is the main pill and which become
// the small bubbles next to it. Rule: at most 1 main + 2 small activities at
// once (bubble 1 to the right of the island, bubble 2 to its left; nothing
// else opens outside the island).
//
// Persistent activities are visible while their condition holds; priority is
// the order of the `persistent` array below (the higher one wins):
//   1. setup         — companion plugin missing/broken (warning text)
//   2. download      — a running or just finished download / package update
//   3. agentApproval — a coding agent is waiting for approval
//   4. quota         — AI quota alert (one-shot, has no bubble; temporarily
//                      moves agents and media down into bubbles)
//   5. agent         — a coding agent is working
//   6. calendar      — an event starting within the hour
//   7. media         — music/video is playing: always last; if any other
//                      activity exists it takes the island and media moves
//                      into a bubble.
// (The full priority design is postponed; for now only media is moved last.)
//
// Transient activities (notification, volume, clipboard, battery/bluetooth,
// workspace, keyboard, "agent done") are banners lasting a few seconds: they
// become view "feedback" through Island.showFeedback and when their time is up
// the island returns to the persistent activities. Small bubbles are hidden
// while a transient banner is open.
//
// Each persistent activity has: id, active (condition), view (the view opened
// on click; empty means Island's own behaviour), small (can it be shown as a
// small bubble) and the icon/text/color fields of the small rendering.
// Media sits at the end of the list: its lowest priority comes from this order.
//
// Pinning (user choice): clicking a bubble (or IPC `swap`) moves that activity
// to the main island, and the main island's activity moves into the clicked
// bubble's place (see swap). The rule lives in one place, the `main` binding:
//   - A pinned activity overrides the priority order while its condition
//     holds; when the condition ends the pin is dropped and automatic
//     priority returns.
//   - Exceptions: a state that needs attention — "waiting for approval"
//     (agentApproval) — and activities without a bubble rendering (setup,
//     download; they have no bubble to go to) still take the main island; the
//     pin is not dropped, it comes back when they end.
//   - Other newly arriving activities do not break the pin; they go to a bubble.
QtObject {
  id: live
  required property var host

  readonly property var h: host
  readonly property bool resting: h.view === "rest" && !h.setup.needsSetup

  // Each activity's condition is kept independent of the view (condition):
  // a transient banner (volume, notification) breaking the rest state must
  // not drop the pin.
  readonly property var persistent: [
    { id: "setup", condition: h.setup.needsSetup, active: h.view === "rest" && h.setup.needsSetup, small: false },
    { id: "download", condition: (h.downloads.finishedName !== "" || h.packages.finishedTitle !== ""
        || h.downloads.active || h.packages.active), small: false },
    { id: "agentApproval", condition: h.agents.anyWaiting, small: true, view: "",
      icon: "󰂞", text: "approve", color: h.theme.urgent, animated: false },
    // The quota alert is one-shot: it has no bubble (small: false) and takes
    // the main island; it closes on click or when its time runs out (see AiQuotaWatch).
    { id: "quota", condition: !!h.aiQuota.alert, small: false },
    // The condition is "at least one agent" so the agent pin survives while
    // it waits for approval.
    { id: "agent", condition: h.agents.count > 0, small: true, view: "",
      icon: "", text: h.agents.count > 1 ? String(h.agents.count) : "", color: h.agents.summaryColor, animated: true },
    { id: "calendar", condition: !!h.calendar.nextEvent, small: true, view: "calendar",
      icon: "󰃭", text: !h.calendar.nextEvent ? "" : h.calendar.nextEvent.minutes <= 0 ? "now" : h.calendar.nextEvent.minutes + " min",
      color: h.theme.accent },
    { id: "media", condition: h.nowPlaying.playing && !!h.settings.mediaPill, small: true, view: "player",
      icon: "󰝚", text: "", color: h.nowPlaying.tint, wave: true }
  ].map(function(e) {
    if (e.active === undefined) e.active = resting && e.condition
    // While waiting for approval "agentApproval" is shown instead of "agent".
    if (e.id === "agent") e.active = e.active && !h.agents.anyWaiting
    return e
  })

  readonly property var activeList: persistent.filter(function(e) { return e.active })

  // ---------- Pinning ----------
  // The activity the user moved to the main island ("" = automatic priority).
  property string pinned: ""
  // Bubble order produced by the user's swaps (ids); new bubbles not in the
  // list are appended in priority order.
  property var bubbleOrder: []

  function activity(id) {
    for (var i = 0; i < persistent.length; i++) if (persistent[i].id === id) return persistent[i]
    return null
  }
  function isActive(id) { var e = activity(id); return !!e && e.active }
  // The activity that overrides the pin: an agent waiting for approval or an
  // activity without a bubble (nowhere else to go).
  readonly property var overriding: {
    for (var i = 0; i < activeList.length; i++)
      if (activeList[i].id === "agentApproval" || !activeList[i].small) return activeList[i]
    return null
  }
  // The activity that would be on the main island without a pin.
  readonly property var autoMain: activeList.length ? activeList[0] : null
  // The activity on the main island, by pin and priority.
  readonly property var mainActivity: {
    if (pinned !== "" && !overriding && isActive(pinned)) return activity(pinned)
    return autoMain
  }
  readonly property string main: mainActivity ? mainActivity.id : ""

  // When the pinned activity ends (its condition goes away), return to
  // automatic priority.
  readonly property bool pinHolds: pinned !== "" && !!activity(pinned) && activity(pinned).condition
  // Clearing is deferred to the event loop so writing `pinned` inside the
  // change handler does not loop through the "pinHolds" binding; in the
  // meantime mainActivity already falls back to automatic priority via
  // isActive(pinned).
  onPinHoldsChanged: if (!pinHolds && pinned !== "") Qt.callLater(clearPin)
  function clearPin() {
    if (!pinHolds && pinned !== "") { pinned = ""; bubbleOrder = [] }
  }

  // Activities that do not fit on the main island and have a small rendering:
  // at most 2 bubbles (1st on the right, 2nd on the left); the user's order
  // first, the rest in priority order.
  readonly property int maxBubbles: 2
  readonly property var bubbles: {
    var candidates = activeList.filter(function(e) { return e.small && e.id !== main }).map(function(e) { return e.id })
    var r = bubbleOrder.filter(function(k) { return candidates.indexOf(k) >= 0 })
    for (var i = 0; i < candidates.length; i++) if (r.indexOf(candidates[i]) < 0) r.push(candidates[i])
    return r.slice(0, maxBubbles)
  }

  // Swap a bubble with the main island: `target` is a bubble id or its index
  // (0, 1). The main island's activity moves into the clicked bubble's place.
  // If the new main is the automatic-priority activity, the pin is dropped.
  // Returns the new main activity id or an error text.
  function swap(target) {
    target = String(target === undefined ? "" : target)
    var k = bubbles
    var index = /^[0-9]+$/.test(target) ? Number(target) : k.indexOf(target)
    if (index < 0 || index >= k.length) return "error: no such bubble (" + k.join(",") + ")"
    var incoming = k[index]
    var outgoing = main
    var ordered = k.slice()
    if (outgoing !== "" && activity(outgoing) && activity(outgoing).small) ordered[index] = outgoing
    else ordered.splice(index, 1)
    bubbleOrder = ordered
    pinned = autoMain && autoMain.id === incoming ? "" : incoming
    return main
  }

  // Ids of every activity that can have a bubble (one fixed bubble object
  // lives for each; see components/LiveBubble.qml). A fixed list, so the
  // bubbles are not rebuilt every time `persistent` updates.
  readonly property var bubbleIds: ["agentApproval", "agent", "calendar", "media"]
}
