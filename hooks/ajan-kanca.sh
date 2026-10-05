#!/usr/bin/env bash
# ArchIsland ajan kancası: kodlama ajanının durumunu island'a bildirir.
#   ajan-kanca.sh <ajan> <working|waiting|done|idle>
# ajan: claude | agy | gemini | codex. Ajanın gönderdiği JSON stdin'den
# okunur, oturum kimliği oradan alınır. Hiçbir şey yazdırmaz (Claude Code
# UserPromptSubmit çıktısını isteme ek bağlam sayar) ve her zaman 0 ile
# çıkar; island kapalıysa ajan etkilenmez. IPC çağrısı arka plana atılır,
# ajan beklemez.
ajan="${1:-}"
durum="${2:-}"
[[ -z $ajan || -z $durum ]] && exit 0

veri=""
[[ -t 0 ]] || veri="$(timeout 2 cat 2>/dev/null || true)"
# Codex `notify` JSON'u stdin yerine son argüman olarak verir.
[[ -z $veri && -n ${3:-} ]] && veri="$3"

oturum=""
if [[ -n $veri ]] && command -v jq >/dev/null 2>&1; then
  oturum="$(jq -r '.session_id // .sessionId // .conversation_id // .conversationId // .thread_id // ."thread-id" // empty' <<<"$veri" 2>/dev/null | head -n1)"
fi
[[ -z $oturum ]] && oturum="default"

kabuk="${ARCHISLAND_PATH:-$HOME/.local/share/archisland}/bin/archisland-shell"
[[ -x $kabuk ]] || kabuk="$(command -v archisland-shell 2>/dev/null || true)"
[[ -z $kabuk ]] && exit 0

export ARCHISLAND_PATH="${ARCHISLAND_PATH:-$HOME/.local/share/archisland}"
setsid "$kabuk" -q guilhermerisu.island agent "$ajan" "$durum" "$oturum" </dev/null >/dev/null 2>&1 &
exit 0
