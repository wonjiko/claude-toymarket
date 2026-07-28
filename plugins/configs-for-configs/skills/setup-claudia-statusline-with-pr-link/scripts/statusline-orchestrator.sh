#!/usr/bin/env bash
# Orchestrator wrapper around statusline-bin (claudia-statusline).
# Runs the original binary, then runs every executable *.sh in the
# sibling "<this file>-segments/" directory and appends whatever each
# one prints as an extra line. A segment is "on" iff its file exists
# AND is executable — `chmod -x segment.sh` turns it off without
# deleting it, `chmod +x segment.sh` turns it back on.
#
# Each segment script receives the raw statusline stdin JSON on its
# own stdin and must print either nothing (no tag this render) or
# exactly one line to append. Segments must not block — do caching /
# timeouts internally, same pattern as the bundled PR/Notion segments.
set -u

BIN="${BASH_SOURCE[0]}-bin"
SEGMENTS_DIR="${BASH_SOURCE[0]}-segments"

# Any subcommand/flag (generate-config, health, list-vars, hook, ...) goes
# straight to the real binary so it behaves exactly as before.
if [ "$#" -gt 0 ]; then
  exec "$BIN" "$@"
fi

INPUT="$(cat)"
OUTPUT="$(printf '%s' "$INPUT" | "$BIN")"

EXTRA_LINES=()
if [ -d "$SEGMENTS_DIR" ]; then
  for seg in "$SEGMENTS_DIR"/*.sh; do
    [ -e "$seg" ] || continue
    [ -x "$seg" ] || continue
    line="$(printf '%s' "$INPUT" | "$seg" 2>/dev/null)"
    [ -n "$line" ] && EXTRA_LINES+=("$line")
  done
fi

printf '%s\n' "$OUTPUT"
if [ "${#EXTRA_LINES[@]}" -gt 0 ]; then
  printf '%s\n' "${EXTRA_LINES[@]}"
fi
