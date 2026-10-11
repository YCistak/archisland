#!/usr/bin/env bash
# ArchIsland installer
# A standalone Dynamic Island for Hyprland: the shell core, the island plugin,
# the notification companion, scripts and the `island` command.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/archisland"
CORE_DIR="${ARCHISLAND_PATH:-$HOME/.local/share/archisland}"
PLUGINS_DIR="$CONFIG_DIR/plugins"
SCRIPTS_DIR="$CONFIG_DIR/scripts"
BIN_DIR="$HOME/.local/bin"
ISLAND_JSON="$CONFIG_DIR/island.json"

# Developer Pack: --developer turns it on, --minimal turns it off. Without a
# flag it is asked in an interactive terminal; otherwise the current setting
# is left untouched.
DEV_PACK=""
AGENT_HOOKS=false
for arg in "$@"; do
  case "$arg" in
    --developer) DEV_PACK=true ;;
    --minimal) DEV_PACK=false ;;
    --agent-hooks) AGENT_HOOKS=true ;;
    -h|--help)
      echo "Usage: bash install.sh [--developer | --minimal] [--agent-hooks]"
      echo "  --developer     Enable the Developer Pack (AI quota, agent status, GitHub PRs, ports, Docker)"
      echo "  --minimal       Disable the Developer Pack"
      echo "  --agent-hooks   Add Claude Code / Codex / Antigravity hooks (existing hooks are kept, a .bak is made first)"
      exit 0 ;;
    *) echo "Unknown option: $arg (help: --help)" >&2; exit 1 ;;
  esac
done

for dep in quickshell rsync jq; do
  command -v "$dep" >/dev/null 2>&1 || { echo "Missing dependency: $dep" >&2; exit 1; }
done

echo "==> Installing ArchIsland..."
mkdir -p "$CORE_DIR" "$PLUGINS_DIR" "$SCRIPTS_DIR" "$BIN_DIR"

# 1. Shell core (QML shell, helper commands, default files)
echo "==> Core: $CORE_DIR"
rsync -a --delete "$HERE/core/" "$CORE_DIR/"

# Icon font (app logos in the menu)
mkdir -p "$HOME/.local/share/fonts"
install -m 644 "$HERE/core/default/fonts/archisland/archisland.ttf" "$HOME/.local/share/fonts/archisland.ttf"
fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true

# 2. Island plugin
echo "==> Island plugin: $PLUGINS_DIR/guilhermerisu.island"
rsync -a --delete \
  --exclude '.git' --exclude 'core' --exclude '__pycache__' \
  "$HERE/" "$PLUGINS_DIR/guilhermerisu.island/"

# 3. Notification companion
rsync -a --delete "$HERE/companion/guilhermerisu.notifications/" "$PLUGINS_DIR/guilhermerisu.notifications/"

# 4. User configuration: create the default if missing
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

# 4b. Developer Pack choice (island.json is not overwritten, it is merged with jq)
if [[ -z $DEV_PACK && -t 0 ]]; then
  read -r -p "Install the Developer Pack (AI quota, agent status, GitHub PRs, ports, Docker)? [y/N] " answer || answer=""
  case "${answer,,}" in
    y|yes) DEV_PACK=true ;;
    n|no) DEV_PACK=false ;;
    # Empty answer: keep the setting if it already exists, otherwise off.
    *) if [[ -f $ISLAND_JSON ]] && jq -e 'has("aiQuota")' "$ISLAND_JSON" >/dev/null 2>&1; then
         DEV_PACK=""
       else
         DEV_PACK=false
       fi ;;
  esac
fi
if [[ -n $DEV_PACK ]]; then
  extra=$(jq -n --argjson v "$DEV_PACK" '{aiQuota: $v, aiAgents: $v, githubPrs: $v, devPorts: $v, docker: $v}')
  if [[ -f $ISLAND_JSON ]]; then
    cp "$ISLAND_JSON" "$ISLAND_JSON.bak"
    tmp=$(mktemp "$ISLAND_JSON.XXXXXX")
    if jq --argjson extra "$extra" '. + $extra' "$ISLAND_JSON" >"$tmp"; then
      mv "$tmp" "$ISLAND_JSON"
    else
      rm -f "$tmp"
      echo "==> Warning: could not read $ISLAND_JSON, Developer Pack setting not written." >&2
    fi
  else
    echo "$extra" >"$ISLAND_JSON"
  fi
  [[ $DEV_PACK == true ]] && pack_state="on" || pack_state="off"
  echo "==> Developer Pack: $pack_state (can be changed in Settings → Modules)"
fi

# 5. Island scripts and the `island` command
echo "==> Scripts: $SCRIPTS_DIR"
rsync -a --exclude '__pycache__' "$HERE/scripts/" "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR"/*
install -m 755 "$HERE/bin/island" "$BIN_DIR/island"
[[ -f $HERE/bin/uwsm-app ]] && install -m 755 "$HERE/bin/uwsm-app" "$BIN_DIR/uwsm-app"

# 5b. Link the core helper commands into BIN_DIR
for cmd in "$CORE_DIR/bin"/archisland-*; do
  [[ -f "$cmd" ]] || continue
  base=$(basename "$cmd")
  [[ -e "$BIN_DIR/$base" ]] || ln -sf "$cmd" "$BIN_DIR/$base"
done

# 5c. Agent hook script (always copied; agent settings are only written
# with --agent-hooks).
HOOKS_DIR="$CONFIG_DIR/hooks"
mkdir -p "$HOOKS_DIR"
install -m 755 "$HERE/hooks/agent-hook.sh" "$HOOKS_DIR/agent-hook.sh"
HOOK="$HOOKS_DIR/agent-hook.sh"
# Compatibility: hook entries written by older releases point to the legacy
# script name below. Keep a shim there that execs the new script, so those
# agent settings keep working until --agent-hooks is re-run.
LEGACY_HOOK_NAME="ajan-kanca.sh"
cat >"$HOOKS_DIR/$LEGACY_HOOK_NAME" <<SHIM
#!/usr/bin/env bash
# Compatibility shim: older ArchIsland releases installed the agent hook
# under this name. Re-run install.sh --agent-hooks to switch to agent-hook.sh.
exec "$HOOK" "\$@"
SHIM
chmod 755 "$HOOKS_DIR/$LEGACY_HOOK_NAME"
# Antigravity hook group name used by older releases (replaced on re-install).
LEGACY_AGY_GROUP="archisland-ada"

# Safely write into a JSON file with a jq filter: a .bak first, then a
# temporary file; the content is written with `cat >` (a symlinked file stays
# a symlink).
json_merge() {
  local file="$1" template="$2" filter="$3" tmp
  mkdir -p "$(dirname "$file")"
  if [[ -f $file ]]; then
    cp "$file" "$file.bak"
  else
    echo '{}' >"$file"
  fi
  tmp=$(mktemp)
  if sed "s|__HOOK__|$HOOK|g" "$template" \
    | jq --slurpfile ext /dev/stdin --arg legacy "$LEGACY_HOOK_NAME" --arg agyLegacy "$LEGACY_AGY_GROUP" \
      "$filter" "$file" >"$tmp"; then
    cat "$tmp" >"$file"
    rm -f "$tmp"
    echo "==> Hooks added: $file (backup: $file.bak)"
  else
    rm -f "$tmp"
    echo "==> Warning: could not read $file, hooks not added." >&2
  fi
}
# Claude Code and Codex: event → [{matcher?, hooks: [...]}]. Our previous
# entries (those running agent-hook.sh or the legacy script name) are removed
# first, then the new ones are added; other tools' hooks are left untouched.
# shellcheck disable=SC2016 # jq program, not shell: $vars must stay literal
EVENT_FILTER='
  def ours: (.hooks // []) | any((.command // "") | (contains("archisland/hooks/agent-hook.sh") or contains($legacy)));
  .hooks = (.hooks // {})
  | reduce ($ext[0].hooks | to_entries[]) as $e (.;
      .hooks[$e.key] = (((.hooks[$e.key] // []) | map(select(ours | not))) + $e.value))'
if [[ $AGENT_HOOKS == true ]]; then
  json_merge "$HOME/.claude/settings.json" "$HERE/hooks/claude-settings.json" "$EVENT_FILTER"
  if [[ -d $HOME/.codex ]]; then
    json_merge "$HOME/.codex/hooks.json" "$HERE/hooks/codex-hooks.json" "$EVENT_FILTER"
    echo "    Note: Codex may ask you to approve the new hooks on first launch."
  fi
  # Antigravity CLI (agy): ~/.gemini/config/hooks.json, named groups.
  if command -v agy >/dev/null 2>&1 && [[ -d $HOME/.gemini ]]; then
    # shellcheck disable=SC2016 # jq program, not shell: $ext must stay literal
    json_merge "$HOME/.gemini/config/hooks.json" "$HERE/hooks/agy-hooks.json" 'del(.[$agyLegacy]) + $ext[0]'
  fi
fi

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo "==> Note: $BIN_DIR must be in your PATH."
fi

# 6. Restart if running
if pgrep -f "^quickshell -n -p $CORE_DIR/shell" >/dev/null 2>&1; then
  echo "==> Restarting Island..."
  "$BIN_DIR/island" restart || true
fi

echo "==> ArchIsland installed."
echo "    On Hyprland startup: exec /home/\$USER/.local/bin/island start"
echo "    Commands: island toggle | menu | apps | power | calendar | stats | ports"
echo "              island kill-port <P> | pr | save-session | restore-session | restart"
