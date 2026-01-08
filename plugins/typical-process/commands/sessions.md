---
description: 현재 프로젝트의 세션 목록 조회 및 전환
allowed-tools: Bash(ls:*), Bash(cat:*), Bash(grep:*), Bash(mv:*), Bash(mkdir:*), Read, Write
argument-hint: [session_name to switch]
---

# Session List

## Active Sessions

Current: !`cat .claude/session/active 2>/dev/null || echo "(none)"`

!`for f in .claude/session/*-plan.md; do
  if [ -f "$f" ]; then
    name=$(basename "$f" -plan.md)
    context=".claude/session/$name-context.md"
    if [ -f "$context" ]; then
      phase=$(grep -m1 "Phase:" "$context" 2>/dev/null | sed 's/.*Phase: //')
      progress=$(grep -m1 "Progress:" "$context" 2>/dev/null | sed 's/.*Progress: //')
      echo "---"
      echo "Session: $name"
      echo "Phase: $phase"
      echo "Progress: $progress"
    fi
  fi
done 2>/dev/null`

## Archived Sessions

!`if [ -d .claude/session/archive ]; then
  count=$(ls .claude/session/archive/*-plan.md 2>/dev/null | wc -l | tr -d ' ')
  echo "($count archived sessions)"
  for f in .claude/session/archive/*-plan.md; do
    if [ -f "$f" ]; then
      name=$(basename "$f" -plan.md)
      echo "  - $name"
    fi
  done 2>/dev/null
else
  echo "(no archived sessions)"
fi`

## Instructions

If argument provided (`$ARGUMENTS`):
1. Check if session exists (look for [arg]-plan.md in .claude/session/ or archive/)
2. If in archive, ask if user wants to restore:
   ```bash
   mv .claude/session/archive/$ARGUMENTS-*.md .claude/session/
   ```
3. Switch active session: `echo "$ARGUMENTS" > .claude/session/active`
4. Confirm switch and show session status

If no argument:
1. Review the session list above
2. Summarize:
   - Active sessions count
   - Archived sessions count
3. Show available actions:
   - `/typical-process:sessions [name]` - Switch to session
   - `/typical-process:execute` - Continue active session
   - `/typical-process:retrospect` - Review active session
