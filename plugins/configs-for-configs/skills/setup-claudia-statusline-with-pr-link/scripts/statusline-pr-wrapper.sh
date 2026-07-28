#!/usr/bin/env bash
# Wrapper around statusline-bin (claudia-statusline) that appends
# "repo#PR" for the current branch's open PR, fetched asynchronously via gh.
set -u

BIN="${BASH_SOURCE[0]}-bin"

# Any subcommand/flag (generate-config, health, list-vars, hook, ...) goes
# straight to the real binary so it behaves exactly as before.
if [ "$#" -gt 0 ]; then
  exec "$BIN" "$@"
fi

INPUT="$(cat)"
OUTPUT="$(printf '%s' "$INPUT" | "$BIN")"

CWD="$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("workspace", {}).get("current_dir", ""))
except Exception:
    print("")
' 2>/dev/null)"

PR_TAG=""

if [ -n "$CWD" ] && git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH="$(git -C "$CWD" branch --show-current 2>/dev/null)"
  REMOTE_URL="$(git -C "$CWD" remote get-url origin 2>/dev/null)"

  if [ -n "$BRANCH" ] && printf '%s' "$REMOTE_URL" | grep -q 'github\.com'; then
    OWNER_REPO="$(printf '%s' "$REMOTE_URL" | sed -E 's#(git@github\.com:|https://github\.com/|ssh://git@github\.com/)##; s#\.git$##')"
    REPO_NAME="$(basename "$OWNER_REPO")"

    CACHE_DIR="${TMPDIR:-/tmp}/claudia-statusline-pr-cache"
    mkdir -p "$CACHE_DIR"
    KEY="$(printf '%s' "$OWNER_REPO:$BRANCH" | shasum | cut -d' ' -f1)"
    CACHE_FILE="$CACHE_DIR/$KEY"
    LOCK_FILE="$CACHE_FILE.lock"

    NOW="$(date +%s)"

    if [ -f "$CACHE_FILE" ]; then
      CACHED="$(cat "$CACHE_FILE" 2>/dev/null)"
      MTIME="$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)"
      AGE=$(( NOW - MTIME ))
    else
      CACHED=""
      AGE=999999
    fi

    if [ "$AGE" -ge 30 ]; then
      LOCK_AGE=999999
      if [ -f "$LOCK_FILE" ]; then
        LOCK_MTIME="$(stat -f %m "$LOCK_FILE" 2>/dev/null || echo 0)"
        LOCK_AGE=$(( NOW - LOCK_MTIME ))
      fi
      if [ "$LOCK_AGE" -ge 15 ]; then
        touch "$LOCK_FILE"
        (
          gh pr list --repo "$OWNER_REPO" --head "$BRANCH" --state open --json number,url --limit 1 -q '.[0] | "\(.number)|\(.url)"' > "$CACHE_FILE.tmp" 2>/dev/null &
          GH_PID=$!
          ( sleep 10; kill -9 "$GH_PID" 2>/dev/null ) &
          WATCHER_PID=$!
          wait "$GH_PID" 2>/dev/null
          kill "$WATCHER_PID" 2>/dev/null
          mv -f "$CACHE_FILE.tmp" "$CACHE_FILE" 2>/dev/null
          rm -f "$LOCK_FILE"
        ) >/dev/null 2>&1 &
        disown
      fi
    fi

    if [ -n "$CACHED" ]; then
      PR_NUMBER="${CACHED%%|*}"
      PR_URL="${CACHED#*|}"
      LINK_TEXT="${REPO_NAME}#${PR_NUMBER}"
      if [ -n "$PR_URL" ] && [ "$PR_URL" != "$CACHED" ]; then
        PR_TAG=$'\033]8;;'"${PR_URL}"$'\033\\'$'\033[35m'"${LINK_TEXT}"$'\033[0m'$'\033]8;;\033\\'
      else
        PR_TAG=$'\033[35m'"${LINK_TEXT}"$'\033[0m'
      fi
    fi
  fi
fi

if [ -n "$PR_TAG" ]; then
  awk -v pr="$PR_TAG" 'NR==1{print $0" \xe2\x80\xa2 " pr; next} {print}' <<< "$OUTPUT"
else
  printf '%s\n' "$OUTPUT"
fi
