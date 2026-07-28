#!/usr/bin/env bash
# Segment for the claudia-statusline orchestrator: prints "repo#PR"
# (as a clickable OSC 8 hyperlink), one line per distinct git repo the
# CURRENT SESSION has worked in — not just the repo the statusline
# happens to be rendering for right now. Reads the orchestrator's raw
# stdin JSON on its own stdin.
#
# "Worked in" is detected from the `cwd` field Claude Code stamps on
# every transcript event, unioned with this render call's own
# `workspace.current_dir`. Capped at MAX_REPOS distinct repos
# (current dir first, then most-recently-visited from the transcript)
# to bound how many background `gh` calls a single render can spawn.
#
# Never blocks: each repo's PR lookup runs in its own detached
# background process with a 30s cache + 15s lock + 10s hard timeout
# per repo (macOS has no `timeout`, so it's a manual `sleep`+`kill`).
set -u

MAX_REPOS=8

INPUT="$(cat)"

CWD="$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("workspace", {}).get("current_dir", ""))
except Exception:
    print("")
' 2>/dev/null)"

TRANSCRIPT_PATH="$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("transcript_path", ""))
except Exception:
    print("")
' 2>/dev/null)"

CANDIDATES=()
[ -n "$CWD" ] && CANDIDATES+=("$CWD")

if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  while IFS= read -r dir; do
    [ -n "$dir" ] && CANDIDATES+=("$dir")
  done < <(tail -n 3000 "$TRANSCRIPT_PATH" | python3 -c '
import json, sys

lines = sys.stdin.readlines()
seen_set = set()
seen = []
for line in reversed(lines):
    try:
        obj = json.loads(line)
    except Exception:
        continue
    cwd = obj.get("cwd")
    if cwd and cwd not in seen_set:
        seen_set.add(cwd)
        seen.append(cwd)
for c in seen:
    print(c)
' 2>/dev/null)
fi

[ "${#CANDIDATES[@]}" -eq 0 ] && exit 0

REPO_ROOTS=()
for dir in "${CANDIDATES[@]}"; do
  [ "${#REPO_ROOTS[@]}" -ge "$MAX_REPOS" ] && break
  root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)"
  [ -z "$root" ] && continue
  dup=0
  if [ "${#REPO_ROOTS[@]}" -gt 0 ]; then
    for r in "${REPO_ROOTS[@]}"; do
      [ "$r" = "$root" ] && dup=1 && break
    done
  fi
  [ "$dup" -eq 1 ] && continue
  REPO_ROOTS+=("$root")
done

[ "${#REPO_ROOTS[@]}" -eq 0 ] && exit 0

render_repo() {
  local root="$1"
  local branch remote owner_repo repo_name cache_dir key cache_file lock_file now
  local cached mtime age lock_age lock_mtime pr_number pr_url link_text

  branch="$(git -C "$root" branch --show-current 2>/dev/null)"
  remote="$(git -C "$root" remote get-url origin 2>/dev/null)"
  [ -z "$branch" ] && return
  printf '%s' "$remote" | grep -q 'github\.com' || return

  owner_repo="$(printf '%s' "$remote" | sed -E 's#(git@github\.com:|https://github\.com/|ssh://git@github\.com/)##; s#\.git$##')"
  repo_name="$(basename "$owner_repo")"

  cache_dir="${TMPDIR:-/tmp}/claudia-statusline-pr-cache"
  mkdir -p "$cache_dir"
  key="$(printf '%s' "$owner_repo:$branch" | shasum | cut -d' ' -f1)"
  cache_file="$cache_dir/$key"
  lock_file="$cache_file.lock"
  now="$(date +%s)"

  if [ -f "$cache_file" ]; then
    cached="$(cat "$cache_file" 2>/dev/null)"
    mtime="$(stat -f %m "$cache_file" 2>/dev/null || echo 0)"
    age=$(( now - mtime ))
  else
    cached=""
    age=999999
  fi

  if [ "$age" -ge 30 ]; then
    lock_age=999999
    if [ -f "$lock_file" ]; then
      lock_mtime="$(stat -f %m "$lock_file" 2>/dev/null || echo 0)"
      lock_age=$(( now - lock_mtime ))
    fi
    if [ "$lock_age" -ge 15 ]; then
      touch "$lock_file"
      (
        gh pr list --repo "$owner_repo" --head "$branch" --state open --json number,url --limit 1 -q '.[0] // empty | "\(.number)|\(.url)"' > "$cache_file.tmp" 2>/dev/null &
        gh_pid=$!
        ( sleep 10; kill -9 "$gh_pid" 2>/dev/null ) &
        watcher_pid=$!
        wait "$gh_pid" 2>/dev/null
        kill "$watcher_pid" 2>/dev/null
        mv -f "$cache_file.tmp" "$cache_file" 2>/dev/null
        rm -f "$lock_file"
      ) >/dev/null 2>&1 &
      disown
    fi
  fi

  [ -z "$cached" ] && return

  pr_number="${cached%%|*}"
  pr_url="${cached#*|}"
  [ "$pr_number" = "null" ] && return

  link_text="${repo_name}#${pr_number}"
  if [ -n "$pr_url" ] && [ "$pr_url" != "$cached" ]; then
    printf '%s\n' $'\033]8;;'"${pr_url}"$'\033\\'$'\033[35m'"${link_text}"$'\033[0m'$'\033]8;;\033\\'
  else
    printf '%s\n' $'\033[35m'"${link_text}"$'\033[0m'
  fi
}

for root in "${REPO_ROOTS[@]}"; do
  render_repo "$root"
done
