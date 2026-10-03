#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$DIR:$HOME/.config/archisland/scripts:$HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH"

tmpdir=$(mktemp -d /tmp/cs-XXXXXX)

# ARCHISLAND_MODULES="ai,docker,ports,pr": yalnız açık modüllerin verisi toplanır.
# Tanımsızsa (ör. `island stats`) hepsi toplanır.
modul_acik() {
  [[ -z ${ARCHISLAND_MODULES+x} ]] && return 0
  [[ ",$ARCHISLAND_MODULES," == *",$1,"* ]]
}

if modul_acik ai && command -v archisland-agent-usage-claude >/dev/null 2>&1; then
  archisland-agent-usage-claude 2>/dev/null > "$tmpdir/claude.json" &
fi
pid1=$!

AGY_BIN=""
if [[ -x "$DIR/agent-agy.py" ]]; then
  AGY_BIN="$DIR/agent-agy.py"
elif command -v archisland-agent-usage-antigravity >/dev/null 2>&1; then
  AGY_BIN=$(which archisland-agent-usage-antigravity)
else
  AGY_BIN=$(find "$HOME/.config" -name "archisland-agent-usage-antigravity" -o -name "agent-agy.py" 2>/dev/null | head -n1)
fi

if modul_acik ai && [[ -n "$AGY_BIN" && -x "$AGY_BIN" ]]; then
  "$AGY_BIN" 2>/dev/null > "$tmpdir/agy.json" &
fi
pid2=$!

if modul_acik ai && command -v archisland-agent-usage-codex >/dev/null 2>&1; then
  archisland-agent-usage-codex 2>/dev/null > "$tmpdir/codex.json" &
fi
pid3=$!

PORTS_BIN=""
if [[ -x "$DIR/list-ports.sh" ]]; then
  PORTS_BIN="$DIR/list-ports.sh"
elif command -v list-ports.sh >/dev/null 2>&1; then
  PORTS_BIN=$(which list-ports.sh)
else
  PORTS_BIN=$(find "$HOME/.config" -name "list-ports.sh" 2>/dev/null | head -n1)
fi

if modul_acik ports && [[ -n "$PORTS_BIN" && -x "$PORTS_BIN" ]]; then
  "$PORTS_BIN" 2>/dev/null > "$tmpdir/ports.json" &
fi
pid4=$!

GH_PR_BIN=""
if [[ -x "$DIR/gh-pr.sh" ]]; then
  GH_PR_BIN="$DIR/gh-pr.sh"
elif command -v gh-pr.sh >/dev/null 2>&1; then
  GH_PR_BIN=$(which gh-pr.sh)
else
  GH_PR_BIN=$(find "$HOME/.config" -name "gh-pr.sh" 2>/dev/null | head -n1)
fi

if modul_acik pr && [[ -n "$GH_PR_BIN" && -x "$GH_PR_BIN" ]]; then
  "$GH_PR_BIN" summary 2>/dev/null > "$tmpdir/gh_prs.json" &
fi
pid5=$!

docker_raw="[]"
modul_acik docker && docker_raw=$(docker ps -a --format '{"name":"{{.Names}}","image":"{{.Image}}","status":"{{.Status}}","state":"{{.State}}"}' 2>/dev/null | jq -s '.' 2>/dev/null)

wait $pid1 $pid2 $pid3 $pid4 $pid5 2>/dev/null

claude_s=$(jq -r '.limits[0].percent // 0' "$tmpdir/claude.json" 2>/dev/null)
claude_w=$(jq -r '.limits[1].percent // 0' "$tmpdir/claude.json" 2>/dev/null)
claude_s=$(awk "BEGIN {printf \"%.0f\", ${claude_s:-0} * 100}")
claude_w=$(awk "BEGIN {printf \"%.0f\", ${claude_w:-0} * 100}")
claude_opus=$(jq -r '.todayTokensByModel["claude-opus-5-5"] // 0' "$tmpdir/claude.json" 2>/dev/null)
claude_sonnet=$(jq -r '.todayTokensByModel["claude-sonnet-5-5"] // 0' "$tmpdir/claude.json" 2>/dev/null)

agy_s=$(jq -r '.limits[] | select(.group=="gemini-5h") | .percent' "$tmpdir/agy.json" 2>/dev/null | head -n1)
agy_w=$(jq -r '.limits[] | select(.group=="gemini-weekly") | .percent' "$tmpdir/agy.json" 2>/dev/null | head -n1)
agy_s=$(awk "BEGIN {printf \"%.0f\", ${agy_s:-0} * 100}")
agy_w=$(awk "BEGIN {printf \"%.0f\", ${agy_w:-0} * 100}")
agy_burn=$(jq -r '.limits[] | select(.group=="gemini-5h") | .burnRateText' "$tmpdir/agy.json" 2>/dev/null | head -n1)

agy_3p_s=$(jq -r '.limits[] | select(.group=="3p-5h") | .percent' "$tmpdir/agy.json" 2>/dev/null | head -n1)
agy_3p_w=$(jq -r '.limits[] | select(.group=="3p-weekly") | .percent' "$tmpdir/agy.json" 2>/dev/null | head -n1)
agy_3p_s=$(awk "BEGIN {printf \"%.0f\", ${agy_3p_s:-0} * 100}")
agy_3p_w=$(awk "BEGIN {printf \"%.0f\", ${agy_3p_w:-0} * 100}")
agy_3p_burn=$(jq -r '.limits[] | select(.group=="3p-5h") | .burnRateText' "$tmpdir/agy.json" 2>/dev/null | head -n1)

codex_s=$(jq -r '.limits[0].percent // 0' "$tmpdir/codex.json" 2>/dev/null)
codex_s=$(awk "BEGIN {printf \"%.0f\", ${codex_s:-0} * 100}")

ports_list=$(cat "$tmpdir/ports.json" 2>/dev/null | jq '[.[] | select(.port != "53" and .port != "631" and .port != "5355")]' 2>/dev/null)
ports_cnt=$(echo "$ports_list" | jq 'length' 2>/dev/null)
docker_cnt=$(echo "$docker_raw" | jq '[.[] | select(.state == "running")] | length' 2>/dev/null)
pr_cnt=$(jq -r '.count // 0' "$tmpdir/gh_prs.json" 2>/dev/null)
pr_list=$(jq -c '.openList // []' "$tmpdir/gh_prs.json" 2>/dev/null)

rm -f "$tmpdir"/* && rmdir "$tmpdir" 2>/dev/null

claude_s=${claude_s:-0}
claude_w=${claude_w:-0}
claude_opus=${claude_opus:-0}
claude_sonnet=${claude_sonnet:-0}
agy_s=${agy_s:-0}
agy_w=${agy_w:-0}
agy_3p_s=${agy_3p_s:-0}
agy_3p_w=${agy_3p_w:-0}
codex_s=${codex_s:-0}

result=$(jq -n \
  --arg cs "$claude_s" --arg cw "$claude_w" --arg co "$claude_opus" --arg csn "$claude_sonnet" \
  --arg as "$agy_s" --arg aw "$agy_w" --arg ab "$agy_burn" \
  --arg a3s "$agy_3p_s" --arg a3w "$agy_3p_w" --arg a3b "$agy_3p_burn" \
  --arg cx "$codex_s" \
  --arg dc "${docker_cnt:-0}" --argjson dlist "${docker_raw:-[]}" \
  --arg pc "${ports_cnt:-0}" --argjson plist "${ports_list:-[]}" \
  --arg prc "${pr_cnt:-0}" --argjson prlist "${pr_list:-[]}" \
  '{
    claude: { session: ($cs | tonumber), weekly: ($cw | tonumber), opus: ($co | tonumber), sonnet: ($csn | tonumber) },
    antigravity: {
      session: ($as | tonumber),
      weekly: ($aw | tonumber),
      burn: $ab,
      session3p: ($a3s | tonumber),
      weekly3p: ($a3w | tonumber),
      burn3p: $a3b
    },
    codex: { session: ($cx | tonumber) },
    docker: { count: ($dc | tonumber), containers: $dlist },
    ports: { count: ($pc | tonumber), list: $plist },
    github: { count: ($prc | tonumber), openList: $prlist }
  }')

if [[ -f /tmp/archisland-corner-stats.json ]]; then
  result=$(jq -s '.[0] * .[1]' /tmp/archisland-corner-stats.json <(echo "$result") 2>/dev/null || echo "$result")
fi

echo "$result" > /tmp/archisland-corner-stats.json.tmp && mv /tmp/archisland-corner-stats.json.tmp /tmp/archisland-corner-stats.json
echo "$result"
