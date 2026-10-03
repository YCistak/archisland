#!/usr/bin/env bash
# ArchIsland kurulum betiği
# Hyprland için bağımsız Dinamik Ada: shell çekirdeği, island eklentisi,
# bildirim yardımcısı, betikler ve `island` komutu.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/archisland"
CORE_DIR="${ARCHISLAND_PATH:-$HOME/.local/share/archisland}"
PLUGINS_DIR="$CONFIG_DIR/plugins"
SCRIPTS_DIR="$CONFIG_DIR/scripts"
BIN_DIR="$HOME/.local/bin"
ISLAND_JSON="$CONFIG_DIR/island.json"

# Geliştirici paketi: --gelistirici açar, --sade kapatır. Bayrak yoksa ve
# terminal etkileşimliyse sorulur; değilse mevcut ayara dokunulmaz.
GELISTIRICI=""
AJAN_KANCALARI=false
for arg in "$@"; do
  case "$arg" in
    --gelistirici) GELISTIRICI=true ;;
    --sade) GELISTIRICI=false ;;
    --ajan-kancalari) AJAN_KANCALARI=true ;;
    -h|--help)
      echo "Kullanım: bash install.sh [--gelistirici | --sade] [--ajan-kancalari]"
      echo "  --gelistirici     Geliştirici paketini aç (AI kota, ajan durumu, GitHub PR, portlar, Docker)"
      echo "  --sade            Geliştirici paketini kapat"
      echo "  --ajan-kancalari  Claude Code / Codex / Antigravity kancalarını ekle (mevcut kancalar korunur, önce .bak alınır)"
      exit 0 ;;
    *) echo "Bilinmeyen seçenek: $arg (yardım: --help)" >&2; exit 1 ;;
  esac
done

for dep in quickshell rsync jq; do
  command -v "$dep" >/dev/null 2>&1 || { echo "Eksik bağımlılık: $dep" >&2; exit 1; }
done

echo "==> ArchIsland kuruluyor..."
mkdir -p "$CORE_DIR" "$PLUGINS_DIR" "$SCRIPTS_DIR" "$BIN_DIR"

# 1. Shell çekirdeği (QML shell, yardımcı komutlar, varsayılan dosyalar)
echo "==> Çekirdek: $CORE_DIR"
rsync -a --delete "$HERE/core/" "$CORE_DIR/"

# Simge fontu (menüdeki uygulama logoları)
mkdir -p "$HOME/.local/share/fonts"
install -m 644 "$HERE/core/default/fonts/archisland/archisland.ttf" "$HOME/.local/share/fonts/archisland.ttf"
fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true

# 2. Island eklentisi
echo "==> Island eklentisi: $PLUGINS_DIR/guilhermerisu.island"
rsync -a --delete \
  --exclude '.git' --exclude 'core' --exclude '__pycache__' \
  "$HERE/" "$PLUGINS_DIR/guilhermerisu.island/"

# 3. Bildirim yardımcısı (companion)
rsync -a --delete "$HERE/companion/guilhermerisu.notifications/" "$PLUGINS_DIR/guilhermerisu.notifications/"

# 4. Kullanıcı yapılandırması: yoksa varsayılanı oluştur
if [[ ! -f $CONFIG_DIR/shell.json ]]; then
  cat >"$CONFIG_DIR/shell.json" <<'JSON'
{
  "version": 1,
  "bar": { "id": "guilhermerisu.island", "position": "top" },
  "plugins": [ { "id": "guilhermerisu.notifications" } ],
  "disabledPlugins": [ "archisland.notifications" ]
}
JSON
fi

# 4b. Geliştirici paketi tercihi (island.json ezilmez, jq ile birleştirilir)
if [[ -z $GELISTIRICI && -t 0 ]]; then
  read -r -p "Geliştirici paketi (AI kota, ajan durumu, GitHub PR, portlar, Docker) kurulsun mu? [e/H] " cevap || cevap=""
  case "${cevap,,}" in
    e|evet|y|yes) GELISTIRICI=true ;;
    h|hayir|hayır|n|no) GELISTIRICI=false ;;
    # Boş cevap: ayar zaten varsa koru, yoksa kapalı.
    *) if [[ -f $ISLAND_JSON ]] && jq -e 'has("aiQuota")' "$ISLAND_JSON" >/dev/null 2>&1; then
         GELISTIRICI=""
       else
         GELISTIRICI=false
       fi ;;
  esac
fi
if [[ -n $GELISTIRICI ]]; then
  ek=$(jq -n --argjson v "$GELISTIRICI" '{aiQuota: $v, aiAgents: $v, githubPrs: $v, devPorts: $v, docker: $v}')
  if [[ -f $ISLAND_JSON ]]; then
    cp "$ISLAND_JSON" "$ISLAND_JSON.bak"
    tmp=$(mktemp "$ISLAND_JSON.XXXXXX")
    if jq --argjson ek "$ek" '. + $ek' "$ISLAND_JSON" >"$tmp"; then
      mv "$tmp" "$ISLAND_JSON"
    else
      rm -f "$tmp"
      echo "==> Uyarı: $ISLAND_JSON okunamadı, geliştirici paketi ayarı yazılmadı." >&2
    fi
  else
    echo "$ek" >"$ISLAND_JSON"
  fi
  [[ $GELISTIRICI == true ]] && durum="açık" || durum="kapalı"
  echo "==> Geliştirici paketi: $durum (Ayarlar → Modüller'den değiştirilebilir)"
fi

# 5. Island betikleri ve `island` komutu
echo "==> Betikler: $SCRIPTS_DIR"
rsync -a --exclude '__pycache__' "$HERE/scripts/" "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR"/*
install -m 755 "$HERE/bin/island" "$BIN_DIR/island"
[[ -f $HERE/bin/uwsm-app ]] && install -m 755 "$HERE/bin/uwsm-app" "$BIN_DIR/uwsm-app"

# 5b. Çekirdek yardımcı komutlarını BIN_DIR içine bağla
for cmd in "$CORE_DIR/bin"/archisland-*; do
  [[ -f "$cmd" ]] || continue
  base=$(basename "$cmd")
  [[ -e "$BIN_DIR/$base" ]] || ln -sf "$cmd" "$BIN_DIR/$base"
done

# 5b. Ajan kancası betiği (her zaman kopyalanır; ajan ayarlarına yalnız
# --ajan-kancalari ile yazılır).
HOOKS_DIR="$CONFIG_DIR/hooks"
mkdir -p "$HOOKS_DIR"
install -m 755 "$HERE/hooks/ajan-kanca.sh" "$HOOKS_DIR/ajan-kanca.sh"
KANCA="$HOOKS_DIR/ajan-kanca.sh"

# Bir JSON dosyasına jq süzgeciyle güvenli yazma: önce .bak, sonra geçici
# dosya; içerik `cat >` ile yazılır (dosya bağlantıysa bağlantı korunur).
json_birlestir() {
  local dosya="$1" ornek="$2" suzgec="$3" tmp
  mkdir -p "$(dirname "$dosya")"
  if [[ -f $dosya ]]; then
    cp "$dosya" "$dosya.bak"
  else
    echo '{}' >"$dosya"
  fi
  tmp=$(mktemp)
  if sed "s|__KANCA__|$KANCA|g" "$ornek" | jq --slurpfile ek /dev/stdin "$suzgec" "$dosya" >"$tmp"; then
    cat "$tmp" >"$dosya"
    rm -f "$tmp"
    echo "==> Kancalar eklendi: $dosya (yedek: $dosya.bak)"
  else
    rm -f "$tmp"
    echo "==> Uyarı: $dosya okunamadı, kancalar eklenmedi." >&2
  fi
}
# Claude Code ve Codex: olay → [{matcher?, hooks: [...]}]. Önce bizim eski
# girdilerimiz (ajan-kanca.sh içeren) çıkarılır, sonra yenisi eklenir;
# başka araçların kancalarına dokunulmaz.
OLAY_SUZGECI='
  def bizim: (.hooks // []) | any((.command // "") | contains("ajan-kanca.sh"));
  .hooks = (.hooks // {})
  | reduce ($ek[0].hooks | to_entries[]) as $e (.;
      .hooks[$e.key] = (((.hooks[$e.key] // []) | map(select(bizim | not))) + $e.value))'
if [[ $AJAN_KANCALARI == true ]]; then
  json_birlestir "$HOME/.claude/settings.json" "$HERE/hooks/claude-settings.json" "$OLAY_SUZGECI"
  if [[ -d $HOME/.codex ]]; then
    json_birlestir "$HOME/.codex/hooks.json" "$HERE/hooks/codex-hooks.json" "$OLAY_SUZGECI"
    echo "    Not: Codex yeni kancaları ilk açılışta onaylamanı isteyebilir."
  fi
  # Antigravity CLI (agy): ~/.gemini/config/hooks.json, adlandırılmış gruplar.
  if command -v agy >/dev/null 2>&1 && [[ -d $HOME/.gemini ]]; then
    json_birlestir "$HOME/.gemini/config/hooks.json" "$HERE/hooks/agy-hooks.json" '. + $ek[0]'
  fi
fi

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo "==> Not: $BIN_DIR PATH içinde olmalı."
fi

# 6. Çalışıyorsa yeniden başlat
if pgrep -f "^quickshell -n -p $CORE_DIR/shell" >/dev/null 2>&1; then
  echo "==> Island yeniden başlatılıyor..."
  "$BIN_DIR/island" restart || true
fi

echo "==> ArchIsland kuruldu."
echo "    Hyprland açılışında: exec /home/\$USER/.local/bin/island start"
echo "    Komutlar: island toggle | menu | apps | power | calendar | stats | ports"
echo "              island kill-port <P> | pr | save-session | restore-session | restart"
