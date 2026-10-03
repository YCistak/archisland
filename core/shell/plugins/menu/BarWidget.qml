import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "archisland.menu"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\ue900"
    fontFamily: "archisland"
    horizontalMargin: 7.5
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("archisland-shell shell toggle archisland.menu '{\"menu\":\"root\"}'")
    }
  }
}
