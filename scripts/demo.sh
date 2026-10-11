#!/usr/bin/env bash
# ArchIsland demo: scenarios for watching the animations from the terminal.
# Usage: island demo [scenario]
set -uo pipefail

ARCHISLAND_PATH="${ARCHISLAND_PATH:-$HOME/.local/share/archisland}"
SHELL_BIN="$(command -v archisland-shell || echo "$ARCHISLAND_PATH/bin/archisland-shell")"
SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/archisland/island.json"
SHOWN_FILE="$HOME/.local/state/archisland/ai-quota-shown.json"
BACKUP="$(mktemp -d "${TMPDIR:-/tmp}/archisland-demo.XXXXXX")"

island_ipc() { "$SHELL_BIN" guilhermerisu.island "$@" >/dev/null 2>&1; }
step() { printf '\033[1;36m▶ %s\033[0m\n' "$*"; }
pause() { sleep "${1:-3}"; }

usage() {
  cat <<'USAGE'
Usage: island demo [scenario]

Scenarios:
  agent      Agent working → 2 agents → needs approval → done (limit card)
  bubbles    Two agents: main island + bubble, then swapping places
  clicks     Left click (control center) and right click (activity details)
  quota      Quota alert: closes when time runs out, closes on click
  workspaces Switching between workspaces with windows and an empty workspace
  all        Runs everything in order

If interrupted with Ctrl+C, demo sessions and settings are restored.
USAGE
}

# --- Cleanup ----------------------------------------------------------------
START_WS=""
QUOTA_CHANGED=0
SETTINGS_BACKED_UP=0
SHOWN_BACKED_UP=0
KEYS_EXISTED=0

clear_agents() {
  local o
  for o in demo-1 demo-2 demo-3; do
    island_ipc agent claude idle "$o"
    island_ipc agent agy idle "$o"
  done
}

restore_quota() {
  ((QUOTA_CHANGED)) || return 0
  if ((SETTINGS_BACKED_UP)); then
    if ((KEYS_EXISTED == 0)); then
      # The settings loader keeps a removed key in memory: write the defaults
      # first, wait for them to load, then put the file back exactly.
      jq '. + {aiQuotaWarnPercent: 20, aiQuotaAlertSeconds: 60}' "$BACKUP/island.json" >"$SETTINGS.demo.tmp" \
        && mv "$SETTINGS.demo.tmp" "$SETTINGS"
      sleep 1.5
    fi
    cp -p "$BACKUP/island.json" "$SETTINGS"
  fi
  if ((SHOWN_BACKED_UP)); then
    cp -p "$BACKUP/ai-quota-shown.json" "$SHOWN_FILE"
  else
    rm -f "$SHOWN_FILE"
  fi
  QUOTA_CHANGED=0
  echo "Settings restored."
}

cleanup() {
  trap - INT TERM EXIT
  island_ipc dismiss
  clear_agents
  island_ipc close
  restore_quota
  if [[ -n $START_WS ]] && command -v hyprctl >/dev/null; then
    hyprctl dispatch "hl.dsp.focus({ workspace = $START_WS })" >/dev/null 2>&1
  fi
  rm -rf "$BACKUP"
}
interrupt() { echo; echo "Interrupted, cleaning up…"; exit 130; }
trap cleanup EXIT
trap interrupt INT TERM

# --- Scenarios --------------------------------------------------------------
s_agent() {
  step "Claude working…"; island_ipc agent claude working demo-1; pause 4
  step "Second session started (2 agents)…"; island_ipc agent claude working demo-2; pause 4
  step "Claude needs approval…"; island_ipc agent claude waiting demo-1; pause 4
  step "A session finished (limit card)…"; island_ipc agent claude "done" demo-1; pause 4
  step "Cleaning up…"; clear_agents; pause 2
}

s_bubbles() {
  step "Claude working (main island)…"; island_ipc agent claude working demo-1; pause 3
  step "Antigravity is working too (two bubbles)…"; island_ipc agent agy working demo-2; pause 4
  step "Swapping with bubble 0…"; island_ipc swap 0; pause 4
  step "Swapping with bubble 1…"; island_ipc swap 1; pause 4
  step "Cleaning up…"; clear_agents; pause 2
}

s_clicks() {
  step "Claude working…"; island_ipc agent claude working demo-1; pause 3
  step "Left click: opening the control center…"; island_ipc click left; pause 4
  step "Closing…"; island_ipc close; pause 2
  step "Right click: opening activity details…"; island_ipc click right; pause 4
  step "Closing…"; island_ipc close; pause 2
  step "Cleaning up…"; clear_agents; pause 2
}

s_quota() {
  if [[ ! -f $SETTINGS ]]; then echo "island.json not found, quota scenario skipped." >&2; return 1; fi
  cp -p "$SETTINGS" "$BACKUP/island.json"; SETTINGS_BACKED_UP=1
  if [[ -f $SHOWN_FILE ]]; then cp -p "$SHOWN_FILE" "$BACKUP/ai-quota-shown.json"; SHOWN_BACKED_UP=1; fi
  jq -e 'has("aiQuotaWarnPercent") and has("aiQuotaAlertSeconds")' "$SETTINGS" >/dev/null 2>&1 \
    && KEYS_EXISTED=1 || KEYS_EXISTED=0
  QUOTA_CHANGED=1

  step "Setting threshold to 99% and alert duration to 8 s; resetting the shown record…"
  echo '{}' >"$SHOWN_FILE"
  jq '. + {aiQuotaWarnPercent: 99, aiQuotaAlertSeconds: 8}' "$BACKUP/island.json" >"$SETTINGS.demo.tmp" \
    && mv "$SETTINGS.demo.tmp" "$SETTINGS"
  pause 3
  step "Waiting for the quota alert; it closes by itself after 8 s…"; pause 11
  step "Resetting the record; the alert will show once more…"
  echo '{}' >"$SHOWN_FILE"; pause 4
  step "Dismissing as if the alert was clicked (dismiss)…"; island_ipc dismiss; pause 3
  step "Restoring settings…"; restore_quota; pause 2
}

s_workspaces() {
  command -v hyprctl >/dev/null || { echo "hyprctl not found, workspaces scenario skipped." >&2; return 1; }
  [[ -n $START_WS ]] || START_WS="$(hyprctl activeworkspace -j | jq -r '.id')"
  local occupied empty=9 target
  mapfile -t occupied < <(hyprctl workspaces -j | jq -r '[.[]|select(.id>0 and .windows>0)|.id]|sort|.[]' | head -3)
  while hyprctl workspaces -j | jq -e --argjson b "$empty" '.[]|select(.id==$b and .windows>0)' >/dev/null; do empty=$((empty+1)); done
  step "Starting workspace: $START_WS"
  for target in "${occupied[@]}" "$empty"; do
    if [[ $target == "$empty" ]]; then step "Empty workspace $target…"; else step "Workspace $target…"; fi
    hyprctl dispatch "hl.dsp.focus({ workspace = $target })" >/dev/null 2>&1; pause 2.5
  done
  step "Returning to start: $START_WS"
  hyprctl dispatch "hl.dsp.focus({ workspace = $START_WS })" >/dev/null 2>&1; pause 2
}

s_all() { s_agent; s_bubbles; s_clicks; s_quota; s_workspaces; }

# --- Entry point ------------------------------------------------------------
case "${1:-}" in
  "" | -h | --help | help) usage ;;
  agent | bubbles | clicks | quota | workspaces | all)
    command -v hyprctl >/dev/null && START_WS="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // empty')"
    "s_$1"
    ;;
  *) echo "Unknown scenario: $1" >&2; echo >&2; usage >&2; exit 1 ;;
esac
