---
description: 새 개발 세션 시작
allowed-tools: Read, Glob, Grep, Task, Write, Edit, Bash(mkdir:*)
argument-hint: <session_name>
---

# Start Session: $ARGUMENTS

## Instructions

1. Validate session_name: `$ARGUMENTS`
   - Convert to kebab-case if needed
   - Check if session already exists (look for [name]-plan.md)

2. Ensure session directory exists:
   ```
   mkdir -p .claude/session/archive
   ```

3. Analyze the codebase relevant to this task

4. Create `.claude/session/$ARGUMENTS-plan.md` with:
   - Clear objective statement
   - Current state analysis
   - Broken-down tasks
   - Files to be modified
   - Risks and dependencies

5. Create `.claude/session/$ARGUMENTS-context.md` with initial state:
   - Phase: planning
   - Started: current timestamp
   - Progress: 0/N tasks

6. Set active session:
   ```
   echo "$ARGUMENTS" > .claude/session/active
   ```

7. Present plan summary and ask for approval

Do NOT begin implementation until user approves the plan.

## Plan Template

```markdown
# Plan: [session_name]

## Meta
- Session: [session_name]
- Created: [timestamp]
- Status: draft

## Objective
[What we're building and why]

## Current State Analysis
[Assessment of existing code/system before changes]

## Tasks
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

## Files to Modify
- `path/to/file.ts` - [reason]

## Dependencies & Risks
[External dependencies, potential blockers]

## Acceptance Criteria
[How we know it's done]
```

## Context Template

```markdown
# Context: [session_name]

## State
- Phase: planning
- Started: [timestamp]
- Last Activity: [timestamp]
- Progress: 0/N tasks

## Execution Log

(No entries yet)
```
