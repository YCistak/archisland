import QtQuick
import Quickshell.Hyprland
import "../services"

// Shown for a moment when the workspace changes: a dot for each workspace
// (solid with windows, faint when empty), and a white capsule with the current
// workspace's number (or, with workspaceHudApps, the app icon of each workspace
// with windows) that slides from the one you left. Its neutral accent
// follows the appearance preference. The workspaces are
// ArchIsland's bar's: 1–5 always, and any other up to 10 that exists.
Item {
  id: pill
  required property var host
  readonly property bool shown: host.workspacesPill
  readonly property int slot: 18
  readonly property int gap: 6
  readonly property bool appsMode: host.settings.workspaceHudApps
  readonly property real islandWidth: host.workspaceIds.length * 24 + 42
  readonly property int focusedIndex: host.workspaceIds.indexOf(host.focusedWorkspaceId)

  opacity: shown ? 1 : 0
  visible: opacity > 0.01
  Behavior on opacity { MotionAnimation { theme: pill.host.theme; pace: "fade"; curve: "fade" } }

  WorkspaceApps { id: appModel }

  // Uygulama simgesi; bulunamazsa baş harf rozeti
  component AppGlyph: Item {
    property var app
    property int size: 14
    property bool onLight: false
    width: size
    height: size
    Image {
      id: img
      anchors.fill: parent
      source: parent.app ? parent.app.icon : ""
      sourceSize: Qt.size(parent.size * 2, parent.size * 2)
      fillMode: Image.PreserveAspectFit
      asynchronous: true
      visible: status === Image.Ready
    }
    Rectangle {
      anchors.fill: parent
      radius: 4
      visible: !img.visible
      color: parent.parent.onLight ? "#2a2d2a" : Qt.rgba(0.5, 0.5, 0.5, 0.45)
      Text {
        anchors.centerIn: parent
        text: parent.parent.app ? parent.parent.app.name.charAt(0).toUpperCase() : ""
        color: "#ffffff"
        font.family: "Adwaita Sans"
        font.pixelSize: 9
        font.weight: Font.Bold
      }
    }
  }

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) if (values[i].id === id) return values[i]
    return null
  }

  Item {
    anchors.centerIn: parent
    width: pill.host.workspaceIds.length * (pill.slot + pill.gap) - pill.gap
    height: pill.slot

    Row {
      spacing: pill.gap
      Repeater {
        model: pill.host.workspaceIds
        delegate: Item {
          id: workspaceSlot
          required property int modelData
          readonly property var workspace: pill.workspaceById(modelData)
          readonly property bool occupied: !!workspace && workspace.toplevels.values.length > 0
          readonly property var app: pill.appsMode && occupied ? appModel.baskin(workspace) : null
          width: pill.slot
          height: pill.slot
          // Pencere olan masaüstünde nokta yerine uygulama simgesi
          AppGlyph {
            visible: !!workspaceSlot.app
            anchors.centerIn: parent
            app: workspaceSlot.app
            size: 14
          }
          Rectangle {
            visible: !workspaceSlot.app
            anchors.centerIn: parent
            width: 7
            height: 7
            radius: 3.5
            color: Qt.rgba(1, 1, 1, workspaceSlot.occupied ? 0.7 : 0.22)
          }
        }
      }
    }

    // The capsule over the current workspace; it keeps its place while
    // hidden, so the next switch slides it from the last one.
    Rectangle {
      visible: pill.focusedIndex >= 0
      x: Math.max(0, pill.focusedIndex) * (pill.slot + pill.gap) - 5
      anchors.verticalCenter: parent.verticalCenter
      width: pill.slot + 10
      height: pill.slot
      radius: height / 2
      color: pill.host.settings.colorfulLiveActivities ? "#ffffff" : pill.host.theme.accent
      Behavior on x { MotionAnimation { theme: pill.host.theme; pace: "expressive" } }
      readonly property var app: pill.appsMode ? appModel.baskin(pill.workspaceById(pill.host.focusedWorkspaceId)) : null
      // Etkin masaüstünde beyaz kapsülün içinde simge; simge yoksa numara
      AppGlyph {
        visible: !!parent.app
        anchors.centerIn: parent
        app: parent.app
        size: 14
        onLight: true
      }
      Text {
        visible: !parent.app
        anchors.centerIn: parent
        text: pill.host.focusedWorkspaceId
        color: pill.host.settings.colorfulLiveActivities ? "#000000" : pill.host.theme.accentText
        font.family: "Adwaita Sans"
        font.pixelSize: 12
        font.weight: Font.Bold
        font.features: { "tnum": 1 }
      }
    }
  }
}
