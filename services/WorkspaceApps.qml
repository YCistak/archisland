import QtQuick
import Quickshell
import Quickshell.Hyprland

// Resolves a workspace's dominant app from its window class into an app name
// and icon.
QtObject {
  id: model

  // Desktop entries may load late; bindings reading them refresh once loaded.
  readonly property var entries: DesktopEntries.applications.values

  // The app chosen for a workspace's icon: the largest window (first on a tie).
  // { cls, name, icon } or null if the workspace has no windows.
  function dominant(ws) {
    void model.entries
    if (!ws) return null
    var windows = ws.toplevels.values
    var chosen = null
    var largest = -1
    for (var i = 0; i < windows.length; i++) {
      var cls = model.classOf(windows[i])
      if (cls === "") continue
      var ipc = windows[i].lastIpcObject
      var area = ipc && ipc.size ? ipc.size[0] * ipc.size[1] : 0
      if (area > largest) { largest = area; chosen = cls }
    }
    return chosen === null ? null : model.resolve(chosen)
  }

  function classOf(window) {
    if (!window) return ""
    if (window.wayland && window.wayland.appId) return String(window.wayland.appId)
    var ipc = window.lastIpcObject
    return ipc && ipc["class"] ? String(ipc["class"]) : ""
  }

  // "org.mozilla.firefox" -> "Firefox", "zen-browser" -> "Zen Browser"
  function readableName(cls) {
    var last = String(cls).split(".").pop()
    var words = last.split(/[-_ ]+/).filter(function(s) { return s !== "" })
    return words.map(function(s) { return s.charAt(0).toUpperCase() + s.slice(1) }).join(" ")
  }

  function resolve(cls) {
    var entry = DesktopEntries.byId(cls) || DesktopEntries.heuristicLookup(cls)
    var icon = ""
    if (entry && entry.icon) icon = Quickshell.iconPath(entry.icon, true)
    if (!icon) icon = Quickshell.iconPath(cls, true)
    if (!icon) icon = Quickshell.iconPath(cls.toLowerCase(), true)
    return {
      cls: cls,
      name: entry && entry.name ? String(entry.name) : readableName(cls),
      icon: icon || ""
    }
  }
}
