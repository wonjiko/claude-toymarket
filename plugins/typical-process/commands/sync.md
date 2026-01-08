---
description: 현재 세션 문서와 상태 동기화
allowed-tools: Read, Write, Edit, Bash(cat:*), Bash(grep:*)
---

# Session Sync

## Active Session

Active session: !`cat .claude/session/active 2>/dev/null || echo "(none)"`

## Current State

!`SESSION=$(cat .claude/session/active 2>/dev/null); if [ -n "$SESSION" ]; then echo "Plan:"; [ -f ".claude/session/$SESSION-plan.md" ] && echo "exists" || echo "missing"; echo "Context:"; [ -f ".claude/session/$SESSION-context.md" ] && echo "exists" || echo "missing"; fi`

## Instructions

1. Read active session from `.claude/session/active`
2. Read `.claude/session/[session]-plan.md`
3. Count completed tasks (checked `- [x]`) vs total tasks (`- [ ]` and `- [x]`)
4. Read `.claude/session/[session]-context.md`
5. Update the State section in `[session]-context.md`:
   - Progress: X/Y tasks
   - Last Activity: current timestamp
   - Phase: infer from completion (all done = completed, some done = execution, none = planning)
6. Update the Meta section in `[session]-plan.md`:
   - Status: infer from progress
7. Report sync results:
   - Session: [session_name]
   - Tasks completed: X/Y
   - Current phase
   - Any discrepancies found
