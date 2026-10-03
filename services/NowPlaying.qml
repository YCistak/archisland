import QtQuick
import Quickshell

// What's playing, from ArchIsland's media service: the active player, its cover
// art, and a tint picked from the cover for the media pill and player view.
Item {
  id: nowPlaying
  required property var shell
  required property var theme
  property var settings: null

  readonly property var service: shell ? shell.firstPartyServiceFor("archisland.media") : null

  function isBrowser(p) {
    if (!p) return false
    var key = (String(p.desktopEntry || "") + " " + String(p.identity || "") + " " + String(p.dbusName || "")).toLowerCase()
    return key.indexOf("zen") !== -1
      || key.indexOf("firefox") !== -1
      || key.indexOf("chrome") !== -1
      || key.indexOf("chromium") !== -1
      || key.indexOf("brave") !== -1
      || key.indexOf("edge") !== -1
      || key.indexOf("vivaldi") !== -1
      || key.indexOf("opera") !== -1
      || key.indexOf("librewolf") !== -1
      || key.indexOf("tor") !== -1
  }

  function findPlayingNonBrowser() {
    if (!service) return null
    var list = service.players || []
    for (var i = 0; i < list.length; i++) {
      var p = list[i]
      if (p && p.isPlaying && !isBrowser(p)) return p
    }
    return null
  }

  readonly property var player: {
    if (!service) return null
    var music = findPlayingNonBrowser()
    if (music) return music
    return service.activePlayer || null
  }

  readonly property bool playing: !!(player && player.isPlaying)
  onPlayerChanged: console.log("NOW_PLAYING: player =", player ? player.identity : "null", "activePlayer =", service ? (service.activePlayer ? service.activePlayer.identity : "null") : "no-service")
  onPlayingChanged: console.log("NOW_PLAYING: playing changed to", playing, "player.isPlaying =", player ? player.isPlaying : "no-player")
  readonly property string title: player ? String(player.trackTitle || "") : ""
  // If the art URL goes empty while the title stays the same, the last art
  // keeps showing.
  readonly property string reportedArt: player && player.trackArtUrl ? String(player.trackArtUrl) : ""
  property string keptArt: ""
  property string keptArtTitle: ""
  onReportedArtChanged: if (reportedArt) { keptArt = reportedArt; keptArtTitle = title }
  onTitleChanged: if (title !== keptArtTitle) { keptArt = reportedArt; keptArtTitle = title }
  readonly property string art: reportedArt || (title === keptArtTitle ? keptArt : "")

  function runAction(name) {
    if (player) {
      if (name === "playPause" && player.canTogglePlaying) player.togglePlaying()
      else if (name === "play" && player.canPlay) player.play()
      else if (name === "pause" && player.canPause) player.pause()
      else if (name === "next" && player.canGoNext) player.next()
      else if (name === "previous" && player.canGoPrevious) player.previous()
      else if (service) service.runAction(name, false, "")
    } else if (service) {
      service.runAction(name, false, "")
    }
  }

  ColorQuantizer {
    id: coverColors
    source: nowPlaying.art
    depth: 2
    rescaleSize: 64
  }
  // The cover's most vivid colour, or the theme's accent for a grey cover.
  readonly property color tint: {
    var best = null, bestScore = -1
    var colors = coverColors.colors || []
    for (var i = 0; i < colors.length; i++) {
      var c = colors[i]
      var score = c.hsvSaturation * 0.7 + c.hsvValue * 0.3
      if (score > bestScore) { bestScore = score; best = c }
    }
    if (!best || best.hsvSaturation < 0.12) return theme.accent
    return Qt.hsva(best.hsvHue, Math.min(1, best.hsvSaturation), Math.max(0.75, best.hsvValue), 1)
  }
}
