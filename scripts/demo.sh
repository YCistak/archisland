#!/usr/bin/env bash
# ArchIsland demo: scenarios for watching the animations from the terminal.
# Usage: island demo [scenario]
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
Usage: island demo [scenario]

Scenarios:
  agent      Agent working → 2 agents → needs approval → done (limit card)
  bubbles    Two agents: main island + bubble, then swapping places
  clicks     Left click (control center) and right click (activity details)
  quota      Quota alert: closes when time runs out, closes on click
  workspaces Switching between workspaces with windows and an empty workspace
  all        Runs everything in order

If interrupted with Ctrl+C, demo sessions and settings are restored.
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
  echo "Settings restored."
}

temizle() {
  trap - INT TERM EXIT
  ada dismiss
  ajanlari_temizle
  ada close
  kotayi_geri_yukle
  if [[ -n $BASLANGIC_MD ]] && command -v hyprctl >/dev/null; then
    hyprctl dispatch "hl.dsp.focus({ workspace = $BASLANGIC_MD })" >/dev/null 2>&1
  fi
  rm -rf "$YEDEK"
}
kes() { echo; echo "Interrupted, cleaning up…"; exit 130; }
trap temizle EXIT
trap kes INT TERM

# --- Senaryolar -------------------------------------------------------------
s_agent() {
  adim "Claude working…"; ada agent claude working demo-1; bekle 4
  adim "Second session started (2 agents)…"; ada agent claude working demo-2; bekle 4
  adim "Claude needs approval…"; ada agent claude waiting demo-1; bekle 4
  adim "A session finished (limit card)…"; ada agent claude done demo-1; bekle 4
  adim "Cleaning up…"; ajanlari_temizle; bekle 2
}

s_bubbles() {
  adim "Claude working (main island)…"; ada agent claude working demo-1; bekle 3
  adim "Antigravity is working too (two bubbles)…"; ada agent agy working demo-2; bekle 4
  adim "Swapping with bubble 0…"; ada swap 0; bekle 4
  adim "Swapping with bubble 1…"; ada swap 1; bekle 4
  adim "Cleaning up…"; ajanlari_temizle; bekle 2
}

s_clicks() {
  adim "Claude working…"; ada agent claude working demo-1; bekle 3
  adim "Left click: opening the control center…"; ada click left; bekle 4
  adim "Closing…"; ada close; bekle 2
  adim "Right click: opening activity details…"; ada click right; bekle 4
  adim "Closing…"; ada close; bekle 2
  adim "Cleaning up…"; ajanlari_temizle; bekle 2
}

s_quota() {
  if [[ ! -f $AYAR ]]; then echo "island.json not found, quota scenario skipped." >&2; return 1; fi
  cp -p "$AYAR" "$YEDEK/island.json"; AYAR_YEDEK_VAR=1
  if [[ -f $KAYIT ]]; then cp -p "$KAYIT" "$YEDEK/ai-quota-shown.json"; KAYIT_YEDEK_VAR=1; fi
  jq -e 'has("aiQuotaWarnPercent") and has("aiQuotaAlertSeconds")' "$AYAR" >/dev/null 2>&1 \
    && ANAHTARLAR_VARDI=1 || ANAHTARLAR_VARDI=0
  KOTA_DEGISTI=1

  adim "Setting threshold to 99% and alert duration to 8 s; resetting the shown record…"
  echo '{}' >"$KAYIT"
  jq '. + {aiQuotaWarnPercent: 99, aiQuotaAlertSeconds: 8}' "$YEDEK/island.json" >"$AYAR.demo.tmp" \
    && mv "$AYAR.demo.tmp" "$AYAR"
  bekle 3
  adim "Waiting for the quota alert; it closes by itself after 8 s…"; bekle 11
  adim "Resetting the record; the alert will show once more…"
  echo '{}' >"$KAYIT"; bekle 4
  adim "Dismissing as if the alert was clicked (dismiss)…"; ada dismiss; bekle 3
  adim "Restoring settings…"; kotayi_geri_yukle; bekle 2
}

s_workspaces() {
  command -v hyprctl >/dev/null || { echo "hyprctl not found, workspaces scenario skipped." >&2; return 1; }
  [[ -n $BASLANGIC_MD ]] || BASLANGIC_MD="$(hyprctl activeworkspace -j | jq -r '.id')"
  local dolu bos=9 hedef
  mapfile -t dolu < <(hyprctl workspaces -j | jq -r '[.[]|select(.id>0 and .windows>0)|.id]|sort|.[]' | head -3)
  while hyprctl workspaces -j | jq -e --argjson b "$bos" '.[]|select(.id==$b and .windows>0)' >/dev/null; do bos=$((bos+1)); done
  adim "Starting workspace: $BASLANGIC_MD"
  for hedef in "${dolu[@]}" "$bos"; do
    if [[ $hedef == "$bos" ]]; then adim "Empty workspace $hedef…"; else adim "Workspace $hedef…"; fi
    hyprctl dispatch "hl.dsp.focus({ workspace = $hedef })" >/dev/null 2>&1; bekle 2.5
  done
  adim "Returning to start: $BASLANGIC_MD"
  hyprctl dispatch "hl.dsp.focus({ workspace = $BASLANGIC_MD })" >/dev/null 2>&1; bekle 2
}

s_all() { s_agent; s_bubbles; s_clicks; s_quota; s_workspaces; }

# --- Giriş ------------------------------------------------------------------
case "${1:-}" in
  "" | -h | --help | help) kullanim ;;
  agent | bubbles | clicks | quota | workspaces | all)
    command -v hyprctl >/dev/null && BASLANGIC_MD="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // empty')"
    "s_$1"
    ;;
  *) echo "Unknown scenario: $1" >&2; echo >&2; kullanim >&2; exit 1 ;;
esac
