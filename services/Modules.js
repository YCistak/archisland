.pragma library

// Module registry: every feature of the island that can be switched on/off.
// Most are live activities; `description` says when it appears.
// `id` is exactly the key in ~/.config/archisland/island.json; older keys
// (mediaPill, downloads...) are kept as they are, so older settings files
// keep working. Defaults must match the JsonAdapter in
// services/IslandSettings.qml.
// category: "essentials" (for everyone) or "developer" (Developer Pack).

var categories = [
  { id: "essentials", name: "Essentials", description: "Everyday island features." },
  { id: "developer", name: "Developer Pack", description: "Live activities and Developer view sections for software developers. Off by default." }
]

var modules = [
  { id: "mediaPill", name: "Now Playing", description: "Shows cover art and a waveform on the island while music plays", category: "essentials", defaultValue: true },
  { id: "volumeHud", name: "Volume Indicator", description: "Shows a level bar for a few seconds when the volume changes", category: "essentials", defaultValue: true },
  { id: "downloads", name: "Downloads", description: "Shows progress while downloading and the file name when finished", category: "essentials", defaultValue: true },
  { id: "clipboard", name: "Clipboard", description: "Shows the copied content for a few seconds", category: "essentials", defaultValue: true },
  { id: "systemUpdates", name: "System Updates", description: "Appears while a package update runs and when it finishes", category: "essentials", defaultValue: true },
  { id: "batteryActivity", name: "Battery", description: "Appears when plugged in and when the battery drops to 20%/10%", category: "essentials", defaultValue: true },
  { id: "bluetoothActivity", name: "Bluetooth", description: "Appears when a device connects or disconnects", category: "essentials", defaultValue: true },
  { id: "workspaceHud", name: "Workspace Indicator", description: "Shows the workspace numbers briefly when the workspace changes", category: "essentials", defaultValue: false },
  { id: "workspaceHudApps", name: "App icons on workspaces", description: "App icons instead of numbers in the workspace indicator; empty workspaces stay as dots; when off, numbers and dots", category: "essentials", defaultValue: true },
  { id: "keyboardHud", name: "Keyboard Layout", description: "Appears briefly when the keyboard layout changes", category: "essentials", defaultValue: true },
  { id: "calendar", name: "Calendar", description: "Appears with a countdown when an event starts within an hour; right-click opens the calendar", category: "essentials", defaultValue: true },
  { id: "aiQuota", name: "AI Quota", description: "Warns once on the main island when Claude/Antigravity/Codex quota drops below the threshold (dismissed on click or after 1 min; polled every 5 min); quota cards in the Developer view", category: "developer", defaultValue: false },
  { id: "aiAgents", name: "Agent Status", description: "Shown while Claude Code, Antigravity or Codex is working and says \"done\" when finished (needs agent hooks: install.sh --agent-hooks)", category: "developer", defaultValue: false },
  { id: "githubPrs", name: "GitHub PRs", description: "Pull requests of your repositories in the Developer view", category: "developer", defaultValue: false },
  { id: "devPorts", name: "Ports", description: "Listening ports in the Developer view", category: "developer", defaultValue: false },
  { id: "docker", name: "Docker", description: "Containers in the Developer view", category: "developer", defaultValue: false }
]

function inCategory(category) {
  return modules.filter(function(m) { return m.category === category })
}

