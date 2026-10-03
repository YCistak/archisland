.pragma library

// Modül kaydı: island'ın aç/kapa yapılabilen her özelliği. Çoğu bir canlı
// etkinliktir; `aciklama` onun ne zaman belirdiğini anlatır.
// `id`, ~/.config/archisland/island.json içindeki anahtarın ta kendisidir;
// eski anahtarlar (mediaPill, downloads...) aynen korunur, böylece eski
// ayar dosyaları bozulmaz. Varsayılan değerler services/IslandSettings.qml
// içindeki JsonAdapter ile aynı olmalıdır.
// kategori: "temel" (herkes için) veya "gelistirici" (geliştirici paketi).

var kategoriler = [
  { id: "temel", ad: "Temel", aciklama: "Günlük kullanım için island özellikleri." },
  { id: "gelistirici", ad: "Geliştirici Paketi", aciklama: "Yazılım geliştirenler için canlı etkinlikler ve Geliştirici görünümünün bölümleri. Varsayılan olarak kapalı." }
]

var liste = [
  { id: "mediaPill", ad: "Şimdi Çalan", aciklama: "Müzik çalarken island'da kapak ve ses dalgası belirir", kategori: "temel", varsayilan: true },
  { id: "volumeHud", ad: "Ses Göstergesi", aciklama: "Ses değişince birkaç saniye seviye çubuğu belirir", kategori: "temel", varsayilan: true },
  { id: "downloads", ad: "İndirmeler", aciklama: "İndirme sürerken ilerleme, bitince dosya adı belirir", kategori: "temel", varsayilan: true },
  { id: "clipboard", ad: "Pano", aciklama: "Bir şey kopyalayınca birkaç saniye içeriği belirir", kategori: "temel", varsayilan: true },
  { id: "systemUpdates", ad: "Sistem Güncellemeleri", aciklama: "Paket güncellemesi sürerken ve bitince belirir", kategori: "temel", varsayilan: true },
  { id: "batteryActivity", ad: "Pil", aciklama: "Şarja takınca ve pil %20/%10'a düşünce belirir", kategori: "temel", varsayilan: true },
  { id: "bluetoothActivity", ad: "Bluetooth", aciklama: "Bir cihaz bağlanınca ya da ayrılınca belirir", kategori: "temel", varsayilan: true },
  { id: "workspaceHud", ad: "Çalışma Alanı Göstergesi", aciklama: "Çalışma alanı değişince numaralar kısa süre belirir", kategori: "temel", varsayilan: false },
  { id: "workspaceHudApps", ad: "Masaüstünde uygulama simgeleri", aciklama: "Masaüstü göstergesinde numaralar yerine uygulama simgeleri; boş masaüstleri nokta kalır, kapalıyken numara ve noktalar", kategori: "temel", varsayilan: true },
  { id: "keyboardHud", ad: "Klavye Düzeni", aciklama: "Klavye dili değişince kısa süre belirir", kategori: "temel", varsayilan: true },
  { id: "calendar", ad: "Takvim", aciklama: "Bir saat içinde etkinlik varsa geri sayımla belirir; sağ tık takvimi açar", kategori: "temel", varsayilan: true },
  { id: "aiQuota", ad: "AI Kota", aciklama: "Claude/Antigravity/Codex kotası eşiğin altına düşünce ana island'da bir kez uyarır (tıklayınca ya da 1 dk sonra kapanır; 5 dk'da bir yoklanır); Geliştirici görünümünde kota kartları", kategori: "gelistirici", varsayilan: false },
  { id: "aiAgents", ad: "Ajan Durumu", aciklama: "Claude Code, Antigravity veya Codex çalışırken görünür, bitince \"bitti\" der (ajan kancaları gerekir: install.sh --ajan-kancalari)", kategori: "gelistirici", varsayilan: false },
  { id: "githubPrs", ad: "GitHub PR'ları", aciklama: "Geliştirici görünümünde depolarındaki pull request'ler", kategori: "gelistirici", varsayilan: false },
  { id: "devPorts", ad: "Portlar", aciklama: "Geliştirici görünümünde dinleyen portlar", kategori: "gelistirici", varsayilan: false },
  { id: "docker", ad: "Docker", aciklama: "Geliştirici görünümünde konteynerler", kategori: "gelistirici", varsayilan: false }
]

function kategoridekiler(kategori) {
  return liste.filter(function(m) { return m.kategori === kategori })
}

