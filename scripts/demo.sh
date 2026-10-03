#!/usr/bin/env bash
# ArchIsland demo: animasyonları terminalden izlemek için senaryolar.
# Kullanım: island demo [senaryo]
set -uo pipefail

ARCHISLAND_PATH="${ARCHISLAND_PATH:-$HOME/.local/share/archisland}"
SHELL_BIN="$(command -v archisland-shell || echo "$ARCHISLAND_PATH/bin/archisland-shell")"
AYAR="${XDG_CONFIG_HOME:-$HOME/.config}/archisland/island.json"
KAYIT="$HOME/.local/state/archisland/ai-quota-shown.json"
YEDEK="$(mktemp -d "${TMPDIR:-/tmp}/archisland-demo.XXXXXX")"

ada() { "$SHELL_BIN" guilhermerisu.island "$@" >/dev/null 2>&1; }
adim() { printf '\033[1;36m▶ %s\033[0m\n' "$*"; }
bekle() { sleep "${1:-3}"; }

kullanim() {
  cat <<'KUL'
Kullanım: island demo [senaryo]

Senaryolar:
  ajan       Ajan çalışıyor → 2 ajan → onay bekliyor → bitti (limit kartı)
  baloncuk   İki ajan: ana island + baloncuk, ardından yer değiştirme (swap)
  goz        Göz atma: ajan çalışırken saat belirir ve kaybolur (peek)
  tiklama    Sol tık (kontrol merkezi) ve sağ tık (etkinlik detayı)
  kota       Kota uyarısı: süre dolunca kapanır, tıklayınca kapanır
  masaustu   Pencereli masaüstleri ve boş bir masaüstü arasında geçiş
  hepsi      Hepsini sırayla çalıştırır

Ctrl+C ile kesilirse demo oturumları ve ayarlar eski hâline döner.
KUL
}

# --- Temizlik ---------------------------------------------------------------
BASLANGIC_MD=""
KOTA_DEGISTI=0
AYAR_YEDEK_VAR=0
KAYIT_YEDEK_VAR=0
ANAHTARLAR_VARDI=0

ajanlari_temizle() {
  local o
  for o in demo-1 demo-2 demo-3; do
    ada agent claude idle "$o"
    ada agent agy idle "$o"
  done
}

kotayi_geri_yukle() {
  ((KOTA_DEGISTI)) || return 0
  if ((AYAR_YEDEK_VAR)); then
    if ((ANAHTARLAR_VARDI == 0)); then
      # Ayar yükleyici silinen anahtarı bellekte tutar: önce varsayılanları yaz,
      # yüklenmesini bekle, sonra dosyayı aynen geri koy.
      jq '. + {aiQuotaWarnPercent: 20, aiQuotaAlertSeconds: 60}' "$YEDEK/island.json" >"$AYAR.demo.tmp" \
        && mv "$AYAR.demo.tmp" "$AYAR"
      sleep 1.5
    fi
    cp -p "$YEDEK/island.json" "$AYAR"
  fi
  if ((KAYIT_YEDEK_VAR)); then
    cp -p "$YEDEK/ai-quota-shown.json" "$KAYIT"
  else
    rm -f "$KAYIT"
  fi
  KOTA_DEGISTI=0
  echo "Ayarlar eski hâline döndü."
}

temizle() {
  trap - INT TERM EXIT
  ada dismiss
  ada peek off
  ajanlari_temizle
  ada close
  kotayi_geri_yukle
  if [[ -n $BASLANGIC_MD ]] && command -v hyprctl >/dev/null; then
    hyprctl dispatch "hl.dsp.focus({ workspace = $BASLANGIC_MD })" >/dev/null 2>&1
  fi
  rm -rf "$YEDEK"
}
kes() { echo; echo "Kesildi, temizleniyor…"; exit 130; }
trap temizle EXIT
trap kes INT TERM

# --- Senaryolar -------------------------------------------------------------
s_ajan() {
  adim "Claude çalışıyor…"; ada agent claude working demo-1; bekle 4
  adim "İkinci oturum başladı (2 ajan)…"; ada agent claude working demo-2; bekle 4
  adim "Claude onay bekliyor…"; ada agent claude waiting demo-1; bekle 4
  adim "Bir oturum bitti (limit kartı)…"; ada agent claude done demo-1; bekle 4
  adim "Temizleniyor…"; ajanlari_temizle; bekle 2
}

s_baloncuk() {
  adim "Claude çalışıyor (ana island)…"; ada agent claude working demo-1; bekle 3
  adim "Antigravity de çalışıyor (iki baloncuk)…"; ada agent agy working demo-2; bekle 4
  adim "Baloncuk 0 ile yer değiştir…"; ada swap 0; bekle 4
  adim "Baloncuk 1 ile yer değiştir…"; ada swap 1; bekle 4
  adim "Temizleniyor…"; ajanlari_temizle; bekle 2
}

s_goz() {
  adim "Claude çalışıyor…"; ada agent claude working demo-1; bekle 3
  adim "Göz atma açık (saat görünür)…"; ada peek on; bekle 4
  adim "Göz atma kapalı…"; ada peek off; bekle 3
  adim "Temizleniyor…"; ajanlari_temizle; bekle 2
}

s_tiklama() {
  adim "Claude çalışıyor…"; ada agent claude working demo-1; bekle 3
  adim "Sol tık: kontrol merkezi açılıyor…"; ada click left; bekle 4
  adim "Kapatılıyor…"; ada close; bekle 2
  adim "Sağ tık: etkinlik detayı açılıyor…"; ada click right; bekle 4
  adim "Kapatılıyor…"; ada close; bekle 2
  adim "Temizleniyor…"; ajanlari_temizle; bekle 2
}

s_kota() {
  if [[ ! -f $AYAR ]]; then echo "island.json bulunamadı, kota senaryosu atlandı." >&2; return 1; fi
  cp -p "$AYAR" "$YEDEK/island.json"; AYAR_YEDEK_VAR=1
  if [[ -f $KAYIT ]]; then cp -p "$KAYIT" "$YEDEK/ai-quota-shown.json"; KAYIT_YEDEK_VAR=1; fi
  jq -e 'has("aiQuotaWarnPercent") and has("aiQuotaAlertSeconds")' "$AYAR" >/dev/null 2>&1 \
    && ANAHTARLAR_VARDI=1 || ANAHTARLAR_VARDI=0
  KOTA_DEGISTI=1

  adim "Eşik %99, uyarı süresi 8 sn yapılıyor; gösterildi kaydı sıfırlanıyor…"
  echo '{}' >"$KAYIT"
  jq '. + {aiQuotaWarnPercent: 99, aiQuotaAlertSeconds: 8}' "$YEDEK/island.json" >"$AYAR.demo.tmp" \
    && mv "$AYAR.demo.tmp" "$AYAR"
  bekle 3
  adim "Kota uyarısı bekleniyor, 8 sn sonra kendiliğinden kapanır…"; bekle 11
  adim "Kayıt sıfırlanıyor; uyarı bir kez daha gösterilecek…"
  echo '{}' >"$KAYIT"; bekle 4
  adim "Uyarıya tıklanmış gibi kapatılıyor (dismiss)…"; ada dismiss; bekle 3
  adim "Ayarlar geri yükleniyor…"; kotayi_geri_yukle; bekle 2
}

s_masaustu() {
  command -v hyprctl >/dev/null || { echo "hyprctl yok, masaüstü senaryosu atlandı." >&2; return 1; }
  [[ -n $BASLANGIC_MD ]] || BASLANGIC_MD="$(hyprctl activeworkspace -j | jq -r '.id')"
  local dolu bos=9 hedef
  mapfile -t dolu < <(hyprctl workspaces -j | jq -r '[.[]|select(.id>0 and .windows>0)|.id]|sort|.[]' | head -3)
  while hyprctl workspaces -j | jq -e --argjson b "$bos" '.[]|select(.id==$b and .windows>0)' >/dev/null; do bos=$((bos+1)); done
  adim "Başlangıç masaüstü: $BASLANGIC_MD"
  for hedef in "${dolu[@]}" "$bos"; do
    if [[ $hedef == "$bos" ]]; then adim "Boş masaüstü $hedef…"; else adim "Masaüstü $hedef…"; fi
    hyprctl dispatch "hl.dsp.focus({ workspace = $hedef })" >/dev/null 2>&1; bekle 2.5
  done
  adim "Başlangıca dönülüyor: $BASLANGIC_MD"
  hyprctl dispatch "hl.dsp.focus({ workspace = $BASLANGIC_MD })" >/dev/null 2>&1; bekle 2
}

s_hepsi() { s_ajan; s_baloncuk; s_goz; s_tiklama; s_kota; s_masaustu; }

# --- Giriş ------------------------------------------------------------------
case "${1:-}" in
  "" | -h | --help | yardim) kullanim ;;
  ajan | baloncuk | goz | tiklama | kota | masaustu | hepsi)
    command -v hyprctl >/dev/null && BASLANGIC_MD="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // empty')"
    "s_$1"
    ;;
  *) echo "Bilinmeyen senaryo: $1" >&2; echo >&2; kullanim >&2; exit 1 ;;
esac
