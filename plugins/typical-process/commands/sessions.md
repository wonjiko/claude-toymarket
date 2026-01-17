---
description: 현재 프로젝트의 세션 목록 조회 및 전환
allowed-tools: Bash(ls:*), Bash(cat:*), Bash(grep:*), Bash(mv:*), Bash(mkdir:*), Read, Glob
argument-hint: [session_name to switch]
---

# Session List

## Task

1. Check if `.claude/session/` directory exists
2. Read `.claude/session/active` to get current active session (if exists)
3. Use Glob to find all `*-plan.md` files in `.claude/session/`
4. For each plan file found, read its corresponding `*-context.md` to extract Phase and Progress
5. Check `.claude/session/archive/` for archived sessions

## Output Format

Display results like:
```
Current: [active session name or "(none)"]

Active Sessions:
---
Session: [name]
Phase: [phase]
Progress: [progress]
---

Archived: [count] sessions
  - [name1]
  - [name2]
```

If no `.claude/session/` directory exists, output:
```
(no sessions yet - run /typical-process:start to create one)
```

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
