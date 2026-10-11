#!/usr/bin/env bash
# ArchIsland agent hook: reports a coding agent's state to the island.
#   agent-hook.sh <agent> <working|waiting|done|idle>
# agent: claude | agy | gemini | codex. The JSON the agent sends is read from
# stdin and the session id is taken from it. It prints nothing (Claude Code
# treats UserPromptSubmit output as extra prompt context) and always exits 0;
# the agent is not affected if the island is not running. The IPC call is
# sent to the background, so the agent does not wait.
agent="${1:-}"
state="${2:-}"
[[ -z $agent || -z $state ]] && exit 0

payload=""
[[ -t 0 ]] || payload="$(timeout 2 cat 2>/dev/null || true)"
# Codex `notify` passes its JSON as the last argument instead of stdin.
[[ -z $payload && -n ${3:-} ]] && payload="$3"

session=""
if [[ -n $payload ]] && command -v jq >/dev/null 2>&1; then
  session="$(jq -r '.session_id // .sessionId // .conversation_id // .conversationId // .thread_id // ."thread-id" // empty' <<<"$payload" 2>/dev/null | head -n1)"
fi
[[ -z $session ]] && session="default"

shell_bin="${ARCHISLAND_PATH:-$HOME/.local/share/archisland}/bin/archisland-shell"
[[ -x $shell_bin ]] || shell_bin="$(command -v archisland-shell 2>/dev/null || true)"
[[ -z $shell_bin ]] && exit 0

export ARCHISLAND_PATH="${ARCHISLAND_PATH:-$HOME/.local/share/archisland}"
setsid "$shell_bin" -q guilhermerisu.island agent "$agent" "$state" "$session" </dev/null >/dev/null 2>&1 &
exit 0
