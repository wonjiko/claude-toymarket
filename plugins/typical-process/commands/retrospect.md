---
description: 세션 워크플로우 회고 - Planning/Execution 단계 리뷰 및 분석
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(mv:*), Bash(mkdir:*)
---

# Retrospective Phase

## Active Session

Active session: !`cat .claude/session/active 2>/dev/null || echo "(none)"`

## Context

!`SESSION=$(cat .claude/session/active 2>/dev/null); if [ -n "$SESSION" ]; then echo "=== Plan ==="; cat ".claude/session/$SESSION-plan.md" 2>/dev/null; echo ""; echo "=== Context ==="; cat ".claude/session/$SESSION-context.md" 2>/dev/null; fi`

Git changes: !`git log --oneline -20 2>/dev/null`
Files changed: !`git diff --stat HEAD~5 2>/dev/null || echo "No recent commits"`

## Instructions

1. Read active session from `.claude/session/active`
2. Read `[session]-plan.md` and `[session]-context.md`
3. Assess what was completed vs planned
4. Analyze the git history for this session
5. Create `.claude/session/[session]-retrospect.md` with:
   - Summary of accomplishments
   - What worked well
   - What could be improved
   - Specific recommendations
   - Open items
6. Update Phase in `[session]-context.md` to "completed" or "paused"
7. Update Status in `[session]-plan.md` to "completed" or "paused"
8. Present key insights to the user
9. If session is completed, ask user:
   - "Archive this session to session/archive/?"
   - If yes:
     ```bash
     mkdir -p .claude/session/archive
     mv .claude/session/$SESSION-plan.md .claude/session/archive/
     mv .claude/session/$SESSION-context.md .claude/session/archive/
     mv .claude/session/$SESSION-retrospect.md .claude/session/archive/
     rm .claude/session/active
     ```
   - If no: clear active pointer only (`rm .claude/session/active`)

## Retrospective Template

```markdown
# Retrospective: [session_name]

## Summary
- **Session:** [session_name]
- **Started:** [timestamp]
- **Completed:** [timestamp]
- **Outcome:** completed | partial | blocked

## What Was Accomplished
[List of completed work with file references]

## What Worked Well
[Effective patterns, tools, approaches]

## What Could Be Improved
[Friction points, inefficiencies]

## Recommendations
[Specific, actionable improvements for next time]

## Open Items
[Anything left incomplete for next session]
```
