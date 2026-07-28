#!/usr/bin/env bash
# Wrapper around statusline-bin (claudia-statusline) that appends the most
# recently referenced Notion page in the current session as a clickable link.
set -u

BIN="${BASH_SOURCE[0]}-bin"

# Any subcommand/flag (generate-config, health, list-vars, hook, ...) goes
# straight to the real binary so it behaves exactly as before.
if [ "$#" -gt 0 ]; then
  exec "$BIN" "$@"
fi

INPUT="$(cat)"
OUTPUT="$(printf '%s' "$INPUT" | "$BIN")"

TRANSCRIPT_PATH="$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("transcript_path", ""))
except Exception:
    print("")
' 2>/dev/null)"

NOTION_TAG=""

if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  CACHE_DIR="${TMPDIR:-/tmp}/claudia-statusline-notion-cache"
  mkdir -p "$CACHE_DIR"
  KEY="$(printf '%s' "$TRANSCRIPT_PATH" | shasum | cut -d' ' -f1)"
  CACHE_FILE="$CACHE_DIR/$KEY"
  LOCK_FILE="$CACHE_FILE.lock"

  NOW="$(date +%s)"

  if [ -f "$CACHE_FILE" ]; then
    CACHED_TITLE="$(sed -n '1p' "$CACHE_FILE" 2>/dev/null)"
    CACHED_URL="$(sed -n '2p' "$CACHE_FILE" 2>/dev/null)"
    MTIME="$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)"
    AGE=$(( NOW - MTIME ))
  else
    CACHED_TITLE=""
    CACHED_URL=""
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
        tail -n 3000 "$TRANSCRIPT_PATH" | python3 -c '
import json, sys

lines = sys.stdin.readlines()

notion_calls = {}
for line in lines:
    try:
        obj = json.loads(line)
    except Exception:
        continue
    msg = obj.get("message")
    if not isinstance(msg, dict):
        continue
    content = msg.get("content")
    if not isinstance(content, list):
        continue
    for block in content:
        if isinstance(block, dict) and block.get("type") == "tool_use":
            name = block.get("name", "")
            if "notion" in name.lower() and ("fetch" in name.lower() or "search" in name.lower()):
                notion_calls[block.get("id")] = name

title = ""
url = ""
for line in reversed(lines):
    try:
        obj = json.loads(line)
    except Exception:
        continue
    msg = obj.get("message")
    if not isinstance(msg, dict):
        continue
    content = msg.get("content")
    if not isinstance(content, list):
        continue
    for block in content:
        if not isinstance(block, dict):
            continue
        if block.get("type") == "tool_result" and block.get("tool_use_id") in notion_calls:
            c = block.get("content")
            text = None
            if isinstance(c, list) and c and isinstance(c[0], dict):
                text = c[0].get("text")
            elif isinstance(c, str):
                text = c
            if not text:
                continue
            try:
                payload = json.loads(text)
            except Exception:
                continue
            t = payload.get("title")
            u = payload.get("url")
            if t and u:
                title, url = t, u
                break
    if url:
        break

title = title.replace("\n", " ").replace("\r", " ")
if len(title) > 24:
    title = title[:24] + "…"

print(title)
print(url)
' > "$CACHE_FILE.tmp" 2>/dev/null &
        PARSE_PID=$!
        ( sleep 10; kill -9 "$PARSE_PID" 2>/dev/null ) &
        WATCHER_PID=$!
        wait "$PARSE_PID" 2>/dev/null
        kill "$WATCHER_PID" 2>/dev/null
        mv -f "$CACHE_FILE.tmp" "$CACHE_FILE" 2>/dev/null
        rm -f "$LOCK_FILE"
      ) >/dev/null 2>&1 &
      disown
    fi
  fi

  if [ -n "$CACHED_URL" ]; then
    NOTION_TAG=$'\033]8;;'"${CACHED_URL}"$'\033\\'$'\033[34m'"${CACHED_TITLE}"$'\033[0m'$'\033]8;;\033\\'
  fi
fi

if [ -n "$NOTION_TAG" ]; then
  printf '%s\n%s\n' "$OUTPUT" "$NOTION_TAG"
else
  printf '%s\n' "$OUTPUT"
fi
