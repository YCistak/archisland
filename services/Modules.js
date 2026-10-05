.pragma library

// Modül kaydı: island'ın aç/kapa yapılabilen her özelliği. Çoğu bir canlı
// etkinliktir; `aciklama` onun ne zaman belirdiğini anlatır.
// `id`, ~/.config/archisland/island.json içindeki anahtarın ta kendisidir;
// eski anahtarlar (mediaPill, downloads...) aynen korunur, böylece eski
// ayar dosyaları bozulmaz. Varsayılan değerler services/IslandSettings.qml
// içindeki JsonAdapter ile aynı olmalıdır.
// kategori: "temel" (herkes için) veya "gelistirici" (geliştirici paketi).

var kategoriler = [
  { id: "temel", ad: "Essentials", aciklama: "Everyday island features." },
  { id: "gelistirici", ad: "Developer Pack", aciklama: "Live activities and Developer view sections for software developers. Off by default." }
]

var liste = [
  { id: "mediaPill", ad: "Now Playing", aciklama: "Shows cover art and a waveform on the island while music plays", kategori: "temel", varsayilan: true },
  { id: "volumeHud", ad: "Volume Indicator", aciklama: "Shows a level bar for a few seconds when the volume changes", kategori: "temel", varsayilan: true },
  { id: "downloads", ad: "Downloads", aciklama: "Shows progress while downloading and the file name when finished", kategori: "temel", varsayilan: true },
  { id: "clipboard", ad: "Clipboard", aciklama: "Shows the copied content for a few seconds", kategori: "temel", varsayilan: true },
  { id: "systemUpdates", ad: "System Updates", aciklama: "Appears while a package update runs and when it finishes", kategori: "temel", varsayilan: true },
  { id: "batteryActivity", ad: "Battery", aciklama: "Appears when plugged in and when the battery drops to 20%/10%", kategori: "temel", varsayilan: true },
  { id: "bluetoothActivity", ad: "Bluetooth", aciklama: "Appears when a device connects or disconnects", kategori: "temel", varsayilan: true },
  { id: "workspaceHud", ad: "Workspace Indicator", aciklama: "Shows the workspace numbers briefly when the workspace changes", kategori: "temel", varsayilan: false },
  { id: "workspaceHudApps", ad: "App icons on workspaces", aciklama: "App icons instead of numbers in the workspace indicator; empty workspaces stay as dots; when off, numbers and dots", kategori: "temel", varsayilan: true },
  { id: "keyboardHud", ad: "Keyboard Layout", aciklama: "Appears briefly when the keyboard layout changes", kategori: "temel", varsayilan: true },
  { id: "calendar", ad: "Calendar", aciklama: "Appears with a countdown when an event starts within an hour; right-click opens the calendar", kategori: "temel", varsayilan: true },
  { id: "aiQuota", ad: "AI Quota", aciklama: "Warns once on the main island when Claude/Antigravity/Codex quota drops below the threshold (dismissed on click or after 1 min; polled every 5 min); quota cards in the Developer view", kategori: "gelistirici", varsayilan: false },
  { id: "aiAgents", ad: "Agent Status", aciklama: "Shown while Claude Code, Antigravity or Codex is working and says \"done\" when finished (needs agent hooks: install.sh --agent-hooks)", kategori: "gelistirici", varsayilan: false },
  { id: "githubPrs", ad: "GitHub PRs", aciklama: "Pull requests of your repositories in the Developer view", kategori: "gelistirici", varsayilan: false },
  { id: "devPorts", ad: "Ports", aciklama: "Listening ports in the Developer view", kategori: "gelistirici", varsayilan: false },
  { id: "docker", ad: "Docker", aciklama: "Containers in the Developer view", kategori: "gelistirici", varsayilan: false }
]

function kategoridekiler(kategori) {
  return liste.filter(function(m) { return m.kategori === kategori })
}

