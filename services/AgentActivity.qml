import QtQuick

// Live state of coding agents (Claude Code, Antigravity/Gemini, Codex).
// The agents' hooks (hooks/) report their state over the island IPC:
//   archisland-shell guilhermerisu.island agent <agent> <working|waiting|done|idle> <session>
// Each session is tracked separately; one agent can have several sessions.
// A "working" report that is not refreshed for 5 minutes is considered stale
// and the session is dropped.
Item {
  id: agents
  property bool enabled: false

  // Agent id → display name and color.
  readonly property var names: ({ claude: "Claude", agy: "Antigravity", gemini: "Gemini", codex: "Codex" })
  readonly property var colors: ({ claude: "#d97757", agy: "#60a5fa", gemini: "#60a5fa", codex: "#9ca3af" })
  function displayName(agent) { return names[agent] || agent }
  function agentColor(agent) { return colors[agent] || "#e2e6de" }

  // "agent/session" → { agent, state: "working"|"waiting", time }
  property var sessions: ({})
  readonly property int staleMs: 5 * 60 * 1000

  readonly property var entries: {
    var out = []
    for (var k in sessions) out.push(sessions[k])
    return out
  }
  readonly property int count: entries.length
  readonly property bool anyWaiting: entries.some(function(o) { return o.state === "waiting" })
  // The agent's name if only one kind of agent is active, empty if mixed.
  readonly property string singleAgent: {
    var a = ""
    for (var i = 0; i < entries.length; i++) {
      if (a !== "" && a !== entries[i].agent) return ""
      a = entries[i].agent
    }
    return a
  }
  readonly property string summary: {
    if (count === 0) return ""
    if (anyWaiting) {
      var b = entries.filter(function(o) { return o.state === "waiting" })[0]
      return displayName(b.agent) + " needs approval"
    }
    if (count === 1) return displayName(entries[0].agent) + " working"
    return count + " agents working"
  }
  readonly property color summaryColor: singleAgent !== "" ? agentColor(singleAgent) : "#e2e6de"

  // The agent that finished last: the "done" banner shows it.
  property string lastFinished: ""
  signal finished(string agent)

  function sessionList() {
    var out = []
    for (var k in sessions) {
      var o = sessions[k]
      var sec = Math.round((Date.now() - o.time) / 1000)
      out.push(k + " (" + o.state + ", " + sec + "s ago)")
    }
    return out.length ? out.join(", ") : "no active agents"
  }

  function report(agent, state, session) {
    agent = String(agent || "").toLowerCase()
    state = String(state || "").toLowerCase()
    session = String(session || "default")
    if (!enabled) return "disabled"
    if (state === "list" || state === "status" || agent === "list") {
      return sessionList()
    }
    if (agent === "clear" || state === "clear" || state === "reset") {
      sessions = ({})
      return "cleared"
    }
    if (!agent) return "error: missing agent name"
    var key = agent + "/" + session
    var copy = Object.assign({}, sessions)
    if (state === "working" || state === "waiting") {
      copy[key] = { agent: agent, state: state, time: Date.now() }
    } else if (state === "done") {
      var existed = !!copy[key]
      delete copy[key]
      sessions = copy
      lastFinished = agent
      finished(agent)
      return existed ? "done" : "done (unknown session)"
    } else if (state === "idle") {
      if (session === "all" || session === "*" || session === "default") {
        for (var k in copy) {
          if (copy[k].agent === agent) delete copy[k]
        }
      } else {
        delete copy[key]
      }
    } else {
      return "error: state must be working|waiting|done|idle|clear|reset"
    }
    sessions = copy
    return state
  }

  onEnabledChanged: if (!enabled) sessions = ({})

  // Drop stale sessions.
  Timer {
    interval: 15000
    repeat: true
    running: agents.enabled && agents.count > 0
    onTriggered: {
      var now = Date.now(), copy = {}, changed = false
      for (var k in agents.sessions) {
        if (now - agents.sessions[k].time > agents.staleMs) changed = true
        else copy[k] = agents.sessions[k]
      }
      if (changed) agents.sessions = copy
    }
  }
}
