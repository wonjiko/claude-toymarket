---
description: 현재 프로젝트의 세션 목록 조회 및 전환
allowed-tools: Read, Glob, Write
argument-hint: [session_name to switch]
---

# Session List

**IMPORTANT: Use only Glob, Read, Write tools. Do NOT use Bash.**

## Task

1. Use Glob to check if `.claude/session/` directory has any files: `.claude/session/*`
2. Use Read to get `.claude/session/active` (current active session)
3. Use Glob to find all plan files: `.claude/session/*-plan.md`
4. For each plan file, derive the session name from filename (e.g., `foo-plan.md` → `foo`)
5. Use Read on each `.claude/session/[name]-context.md` to extract Phase and Progress
6. Use Glob to check archived sessions: `.claude/session/archive/*-plan.md`

## Output Format

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

If Glob returns no files in `.claude/session/`:
```
(no sessions yet - run /typical-process:start to create one)
```

## Session Switch (when $ARGUMENTS provided)

1. Use Glob to find `$ARGUMENTS-plan.md` in `.claude/session/` or `.claude/session/archive/`
2. If in archive, ask user if they want to restore (user must do file move manually)
3. Use Write to update `.claude/session/active` with the session name
4. Confirm switch and show session status

## No Argument

1. Display the session list
2. Show available actions:
   - `/typical-process:sessions [name]` - Switch to session
   - `/typical-process:execute` - Continue active session
   - `/typical-process:retrospect` - Review active session
