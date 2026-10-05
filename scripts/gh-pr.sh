#!/usr/bin/env bash
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH"

cmd="${1:-summary}"
repo="${2:-}"

# GitHub kullanıcı adı: gh'nin oturum açtığı hesap (oturum boyunca önbellekte tutulur).
gh_owner() {
  local cache="${XDG_RUNTIME_DIR:-/tmp}/archisland-gh-owner"
  if [[ ! -s $cache ]]; then
    gh api user -q .login >"$cache" 2>/dev/null || { rm -f "$cache"; return 1; }
  fi
  cat "$cache"
}

# summary dışındaki komutlar bir depo ister: "sahip/depo"
if [[ $cmd != summary && -z $repo ]]; then
  echo '[]'
  exit 0
fi

case "$cmd" in
  summary)
    owner=$(gh_owner) || owner=""
    if [[ -n $owner ]]; then
      open_prs=$(gh search prs --owner "$owner" --state open --json number,title,repository,author 2>/dev/null || echo "[]")
    else
      open_prs="[]"
    fi
    count=$(echo "$open_prs" | jq 'length // 0' 2>/dev/null)
    jq -n --argjson prs "${open_prs:-[]}" --arg c "${count:-0}" '{count: ($c | tonumber), openList: $prs}'
    ;;

  list)
    state="${3:-all}"
    prs=$(gh pr list -R "$repo" --state "$state" --limit 20 --json number,title,author,headRefName,baseRefName,mergeable,mergeStateStatus,state,url,createdAt,isDraft 2>/dev/null || echo "[]")
    echo "$prs" | jq '[.[] | {
      number: .number,
      title: .title,
      author: (.author.login // "unknown"),
      head: .headRefName,
      base: .baseRefName,
      state: .state,
      mergeable: .mergeable,
      mergeStateStatus: .mergeStateStatus,
      isDraft: .isDraft,
      url: .url,
      created: (.createdAt | split("T")[0])
    }]'
    ;;

  branches)
    gh api "repos/$repo/branches" --paginate --jq '.[].name' 2>/dev/null | grep -v 'master' | grep -v 'main' | jq -R . | jq -s .
    ;;

  merge)
    pr_num="$3"
    method="${4:-merge}"
    if [[ -z "$pr_num" ]]; then
      echo '{"success":false,"error":"PR number not specified"}'
      exit 1
    fi
    out=$(gh pr merge "$pr_num" -R "$repo" --"$method" 2>&1)
    status=$?
    if [[ $status -eq 0 ]]; then
      notify-send -u normal "ArchIsland - GitHub" "PR #$pr_num ($repo) merged successfully!" -i git 2>/dev/null || true
      echo "{\"success\":true,\"message\":\"PR #$pr_num merged.\"}"
    else
      notify-send -u critical "ArchIsland - GitHub" "PR #$pr_num could not be merged: $out" -i dialog-error 2>/dev/null || true
      jq -n --arg err "$out" '{"success":false,"error":$err}'
    fi
    ;;

  close)
    pr_num="$3"
    if [[ -z "$pr_num" ]]; then
      echo '{"success":false,"error":"PR number not specified"}'
      exit 1
    fi
    out=$(gh pr close "$pr_num" -R "$repo" 2>&1)
    status=$?
    if [[ $status -eq 0 ]]; then
      notify-send -u normal "ArchIsland - GitHub" "PR #$pr_num ($repo) closed." -i git 2>/dev/null || true
      echo "{\"success\":true,\"message\":\"PR #$pr_num closed.\"}"
    else
      notify-send -u critical "ArchIsland - GitHub" "PR #$pr_num could not be closed: $out" -i dialog-error 2>/dev/null || true
      jq -n --arg err "$out" '{"success":false,"error":$err}'
    fi
    ;;

  create)
    head_branch="$3"
    base_branch="${4:-}"
    title="$5"
    body="${6:-Created from ArchIsland.}"
    if [[ -z "$head_branch" || -z "$title" ]]; then
      echo '{"success":false,"error":"Branch and title not specified"}'
      exit 1
    fi
    # Hedef dal boşsa gh deponun varsayılan dalını kullanır.
    base_args=()
    [[ -n $base_branch ]] && base_args=(--base "$base_branch")
    out=$(gh pr create -R "$repo" --head "$head_branch" "${base_args[@]}" --title "$title" --body "$body" 2>&1)
    status=$?
    if [[ $status -eq 0 ]]; then
      url=$(echo "$out" | grep -o 'https://github.com/[^ ]*' | head -n1)
      notify-send -u normal "ArchIsland - GitHub" "New PR opened successfully: $title ($url)" -i git 2>/dev/null || true
      jq -n --arg u "$url" '{"success":true,"url":$u,"message":"PR opened successfully"}'
    else
      notify-send -u critical "ArchIsland - GitHub" "Could not open PR: $out" -i dialog-error 2>/dev/null || true
      jq -n --arg err "$out" '{"success":false,"error":$err}'
    fi
    ;;

  view-web)
    pr_num="$3"
    gh pr view "$pr_num" -R "$repo" --web 2>/dev/null &
    echo '{"success":true}'
    ;;

  diff)
    pr_num="$3"
    gh pr diff "$pr_num" -R "$repo" 2>/dev/null
    ;;

  *)
    echo "Usage: $0 {summary|list|branches|merge|close|create|view-web|diff} [repo] [args...]"
    exit 1
    ;;
esac
