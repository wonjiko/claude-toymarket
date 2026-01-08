#!/bin/bash
# 전형적인 프로세스 - Session End Hook
# Auto-update last activity on exit

ACTIVE_FILE="$CLAUDE_PROJECT_DIR/.claude/session/active"

if [ -f "$ACTIVE_FILE" ]; then
  SESSION=$(cat "$ACTIVE_FILE")
  CONTEXT_FILE="$CLAUDE_PROJECT_DIR/.claude/session/$SESSION-context.md"

  if [ -f "$CONTEXT_FILE" ]; then
    # Update Last Activity timestamp in context file
    TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # macOS compatible sed
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/Last Activity:.*/Last Activity: $TIMESTAMP/" "$CONTEXT_FILE"
    else
      sed -i "s/Last Activity:.*/Last Activity: $TIMESTAMP/" "$CONTEXT_FILE"
    fi
  fi
fi
