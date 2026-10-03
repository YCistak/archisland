import QtQuick
import Quickshell
import Quickshell.Io
import "../../components"
// ArchIsland's own emoji data and keyword search, so results match its picker.
import "../../lib/EmojiSearch.js" as EmojiSearch

// Emoji picker: the shared list view as a grid of emoji. Type to search by
// name or keyword, arrows to move, Enter or a click to insert the emoji into
// the app you were using (it's also left out of your clipboard, as ArchIsland's
// picker does).
ListPicker {
  id: emojis
  placeholder: "Search emoji"
  emptyText: "No emoji match"
  columns: 10
  rowHeight: 54
  visibleRows: 6
  items: EmojiSearch.filterEmojis(all, query, 1000)
  onChosen: function(entry) { insert(entry.e) }

  readonly property string archislandPath: Quickshell.env("ARCHISLAND_PATH") || (Quickshell.env("HOME") + "/.local/share/archisland")
  property var all: []
  FileView {
    path: emojis.archislandPath + "/shell/plugins/emojis/emojis.json"
    printErrors: false
    onLoaded: emojis.all = EmojiSearch.parseEmojis(text())
  }

  row: Component {
    Item {
      id: cell
      property var entry: ({})
      property bool selected: false
      Text {
        anchors.centerIn: parent
        text: String(cell.entry.e || "")
        font.family: "Noto Color Emoji"
        font.pixelSize: 28
      }
    }
  }

  // Close first so the keyboard goes back to the previous app, then paste the
  // emoji there: copy it, send Shift+Insert, and drop the clipboard offer
  // again (the same steps as ArchIsland's archisland-menu-emoji-insert).
  Process { id: inserter }
  function insert(emoji) {
    if (!emoji) return
    host.view = "rest"
    inserter.command = ["bash", "-c",
      'printf "%s" "$1" | wl-copy --type text/plain --sensitive --foreground & copy=$!; ' +
      'sleep 0.25; wtype -M shift -k Insert -m shift 2>/dev/null; sleep 0.2; kill "$copy" 2>/dev/null',
      "--", String(emoji)]
    inserter.startDetached()
  }
}
