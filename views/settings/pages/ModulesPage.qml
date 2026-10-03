import QtQuick
import QtQuick.Layouts
import "../controls"
import "../../../services/Modules.js" as Modules

// Ayarlar → Modüller: island özelliklerini kategorilere göre aç/kapa.
// Değişiklik anında island.json'a yazılır ve yeniden başlatmadan uygulanır.
ColumnLayout {
  id: page
  required property var view
  visible: view.currentPage === "Modüller"
  Layout.fillWidth: true
  spacing: 20

  Repeater {
    model: Modules.kategoriler
    delegate: SettingsGroup {
      id: group
      required property var modelData
      readonly property var modules: Modules.kategoridekiler(modelData.id)
      view: page.view
      title: modelData.ad
      footer: modelData.aciklama
      Repeater {
        model: group.modules
        delegate: SettingsRow {
          required property var modelData
          required property int index
          view: page.view
          label: modelData.ad
          detail: modelData.aciklama
          last: index === group.modules.length - 1
          SettingsSwitch {
            view: page.view
            checked: !!page.view.settings[modelData.id]
            onToggled: function(on) { page.view.settings[modelData.id] = on }
          }
        }
      }
    }
  }

  // Sayı alanı: Enter'da (ya da odak gidince) island.json'a yazılır.
  component SayiAlani: Rectangle {
    id: alan
    required property string anahtar
    property int enAz: 1
    property int enCok: 99
    width: 64
    height: 28
    radius: 7
    color: page.view.well
    border.width: girdi.activeFocus ? 2 : 0
    border.color: page.view.host.theme.withAlpha(page.view.accent, 0.6)
    TextInput {
      id: girdi
      anchors.fill: parent
      anchors.leftMargin: 8
      anchors.rightMargin: 8
      verticalAlignment: TextInput.AlignVCenter
      horizontalAlignment: TextInput.AlignRight
      validator: IntValidator { bottom: alan.enAz; top: alan.enCok }
      color: page.view.text
      font.family: "Adwaita Sans"
      font.pixelSize: 13
      text: String(page.view.settings[alan.anahtar])
      onEditingFinished: {
        var n = parseInt(text)
        if (!isNaN(n)) page.view.settings[alan.anahtar] = Math.max(alan.enAz, Math.min(alan.enCok, n))
      }
    }
  }

  // Island'a tıklama ve üzerine gelme düzeni (kısa kullanım notu).
  SettingsGroup {
    view: page.view
    title: "Kullanım"
    SettingsRow { view: page.view; label: "Sol tık"; detail: "Island'ın kendisi: kontrol merkezi (kota uyarısında uyarıyı kapatır)" }
    SettingsRow { view: page.view; label: "Sağ tık"; detail: "Ana etkinliğin detayı (ajan/kota: limitler, müzik: oynatıcı); etkinlik yoksa takvim" }
    SettingsRow { view: page.view; label: "Üzerine gelme"; detail: "Saati geçici gösterir, etkinlik kabarcığa iner; çıkınca geri döner" }
    SettingsRow { view: page.view; label: "Kabarcığa tık"; detail: "Etkinliği ana island'a alır (sabitler)"; last: true }
  }

  // Geliştirici canlı etkinliklerinin eşikleri.
  SettingsGroup {
    view: page.view
    visible: !!page.view.settings.aiQuota || !!page.view.settings.aiAgents
    title: "Canlı Etkinlik Ayarları"
    footer: "Kota uyarısı, kalan oran bu yüzdenin altına düşünce ana island'da bir kez görünür; tıklayınca ya da süre dolunca kapanır. Enter ile kaydedilir."
    SettingsRow {
      view: page.view
      visible: !!page.view.settings.aiQuota
      label: "Kota uyarı eşiği (% kalan)"
      SayiAlani { anahtar: "aiQuotaWarnPercent"; enAz: 1; enCok: 99 }
    }
    SettingsRow {
      view: page.view
      visible: !!page.view.settings.aiQuota
      label: "Kota uyarısı süresi (sn)"
      last: !page.view.settings.aiAgents
      SayiAlani { anahtar: "aiQuotaAlertSeconds"; enAz: 5; enCok: 600 }
    }
    SettingsRow {
      view: page.view
      visible: !!page.view.settings.aiAgents
      label: "\"Bitti\" banner süresi (sn)"
      last: true
      SayiAlani { anahtar: "agentDoneSeconds"; enAz: 1; enCok: 30 }
    }
  }

  // GitHub PR kartındaki depolar (island.json → devRepos).
  SettingsGroup {
    view: page.view
    visible: !!page.view.settings.githubPrs
    title: "GitHub Depoları"
    footer: "Virgülle ayır, ör. sahip/depo, sahip/baska-depo. Enter ile kaydedilir."
    SettingsRow {
      view: page.view
      label: "Depolar"
      last: true
      Rectangle {
        width: 300
        height: 28
        radius: 7
        color: page.view.well
        border.width: reposInput.activeFocus ? 2 : 0
        border.color: page.view.host.theme.withAlpha(page.view.accent, 0.6)
        Text {
          anchors.left: parent.left
          anchors.leftMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          visible: reposInput.text === ""
          text: "sahip/depo"
          color: page.view.textMuted
          font.family: "Adwaita Sans"
          font.pixelSize: 13
        }
        TextInput {
          id: reposInput
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          verticalAlignment: TextInput.AlignVCenter
          clip: true
          color: page.view.text
          font.family: "Adwaita Sans"
          font.pixelSize: 13
          text: (page.view.settings.devRepos || []).join(", ")
          onEditingFinished: {
            var parts = text.split(",")
            var list = []
            for (var i = 0; i < parts.length; i++) {
              var r = parts[i].trim()
              if (r.indexOf("/") > 0 && list.indexOf(r) === -1) list.push(r)
            }
            page.view.settings.devRepos = list
          }
        }
      }
    }
  }
}
