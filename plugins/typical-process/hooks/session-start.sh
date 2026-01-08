#!/bin/bash
# 전형적인 프로세스 - Session Start Hook
# Load active session context into Claude's environment

ACTIVE_FILE="$CLAUDE_PROJECT_DIR/.claude/session/active"

if [ -f "$ACTIVE_FILE" ]; then
  SESSION=$(cat "$ACTIVE_FILE")
  CONTEXT_FILE="$CLAUDE_PROJECT_DIR/.claude/session/$SESSION-context.md"

  if [ -f "$CONTEXT_FILE" ]; then
    PHASE=$(grep -m1 "Phase:" "$CONTEXT_FILE" 2>/dev/null | sed 's/.*Phase: //')
    PROGRESS=$(grep -m1 "Progress:" "$CONTEXT_FILE" 2>/dev/null | sed 's/.*Progress: //')

    if [ "$PHASE" != "completed" ] && [ -n "$PHASE" ]; then
      echo "╔══════════════════════════════════════╗"
      echo "║  전형적인 프로세스 - Active Session  ║"
      echo "╠══════════════════════════════════════╣"
      echo "║  Session: $SESSION"
      echo "║  Phase: $PHASE"
      echo "║  Progress: $PROGRESS"
      echo "╠══════════════════════════════════════╣"
      echo "║  /typical-process:execute             ║"
      echo "║  /typical-process:sessions            ║"
      echo "║  /typical-process:retrospect          ║"
      echo "╚══════════════════════════════════════╝"
    fi
  fi
fi
