---
description: 현재 세션의 작업 실행
allowed-tools: Bash(*), Read, Write, Edit, Glob, Grep, Task
---

# Execution Phase

## Active Session Check

Active session: !`cat .claude/session/active 2>/dev/null || echo "(none)"`

## Pre-execution Check

!`SESSION=$(cat .claude/session/active 2>/dev/null); if [ -n "$SESSION" ]; then echo "=== Plan ==="; cat ".claude/session/$SESSION-plan.md" 2>/dev/null | head -50; echo ""; echo "=== Context ==="; cat ".claude/session/$SESSION-context.md" 2>/dev/null | tail -30; fi`

## Instructions

1. Read active session from `.claude/session/active`
2. Read `[session]-plan.md` and `[session]-context.md`
3. Verify plan is approved (Status should be "approved" or "in-progress")
4. Identify the next incomplete task from the plan
5. Execute the task
6. After each task:
   - Update the checkbox in `[session]-plan.md` to `[x]`
   - Append execution entry to `[session]-context.md`:
     ```markdown
     ### [timestamp] - Task: [name]
     - **Action:** [what was done]
     - **Files:** [files modified]
     - **Result:** success | blocked
     - **Notes:** [observations]
     ```
   - Update Progress in context State section
   - Update Status in plan Meta section to "in-progress"
7. If blocked, document the blocker and ask for guidance
8. Continue until all tasks complete or user stops

## Execution Principles
- One task at a time
- Verify each change before proceeding
- Document unexpected issues immediately
