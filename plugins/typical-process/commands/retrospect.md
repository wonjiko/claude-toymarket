---
description: 세션 워크플로우 회고 - Planning/Execution 단계 리뷰 및 분석
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(mv:*), Bash(mkdir:*), Bash(rm:*), Glob, AskUserQuestion
---

# Retrospective Phase

## Task

1. Read `.claude/session/active` to get active session name
2. If no active session, display "(no active session)" and exit
3. Read `.claude/session/[session]-plan.md` and `.claude/session/[session]-context.md`
4. Use Bash to get git history: `git log --oneline -20` and `git diff --stat HEAD~5`
5. Follow the instructions below

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
