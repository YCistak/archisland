import QtQuick
import Quickshell
import Quickshell.Hyprland

// Bir masaüstünün (çalışma alanı) baskın uygulamasını, pencere sınıfından
// uygulama adı ve simgesiyle çözer.
QtObject {
  id: model

  // Masaüstü girdileri geç yüklenebilir; okuyan bağlamalar yüklenince yenilensin.
  readonly property var kayitlar: DesktopEntries.applications.values

  // Masaüstünün simge için seçilen uygulaması: en büyük pencere (eşitse ilki).
  // { cls, name, icon } ya da pencere yoksa null.
  function baskin(ws) {
    void model.kayitlar
    if (!ws) return null
    var pencereler = ws.toplevels.values
    var secilen = null
    var enBuyuk = -1
    for (var i = 0; i < pencereler.length; i++) {
      var cls = model.sinifOf(pencereler[i])
      if (cls === "") continue
      var ipc = pencereler[i].lastIpcObject
      var alan = ipc && ipc.size ? ipc.size[0] * ipc.size[1] : 0
      if (alan > enBuyuk) { enBuyuk = alan; secilen = cls }
    }
    return secilen === null ? null : model.coz(secilen)
  }

  function sinifOf(pencere) {
    if (!pencere) return ""
    if (pencere.wayland && pencere.wayland.appId) return String(pencere.wayland.appId)
    var ipc = pencere.lastIpcObject
    return ipc && ipc["class"] ? String(ipc["class"]) : ""
  }

  // "org.mozilla.firefox" -> "Firefox", "zen-browser" -> "Zen Browser"
  function okunurAd(cls) {
    var son = String(cls).split(".").pop()
    var sozler = son.split(/[-_ ]+/).filter(function(s) { return s !== "" })
    return sozler.map(function(s) { return s.charAt(0).toUpperCase() + s.slice(1) }).join(" ")
  }

  function coz(cls) {
    var giris = DesktopEntries.byId(cls) || DesktopEntries.heuristicLookup(cls)
    var simge = ""
    if (giris && giris.icon) simge = Quickshell.iconPath(giris.icon, true)
    if (!simge) simge = Quickshell.iconPath(cls, true)
    if (!simge) simge = Quickshell.iconPath(cls.toLowerCase(), true)
    return {
      cls: cls,
      name: giris && giris.name ? String(giris.name) : okunurAd(cls),
      icon: simge || ""
    }
  }
}
