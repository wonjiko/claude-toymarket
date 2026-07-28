# PRINCIPLES.md 준수 개선 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** PRINCIPLES.md 감사에서 확정된 세 가지 항목을 반영한다 — mcp-manager 자동 등록에 확인 절차 추가, make-pr-fe 스킬 삭제, pick-subagent 자기 설명 수정.

**Architecture:** 세 항목 모두 마크다운 문서/커맨드 파일 수정이거나 디렉토리 삭제다. 코드 로직 변경은 없다.

**Tech Stack:** Markdown, 저장소 자체 검증 스크립트(`scripts/verify_repo.py`, `plugins/matryoshka-plugin/scripts/lint-all.sh`)

## Global Constraints

- 설계 문서: `docs/superpowers/specs/2026-07-27-principles-conformance-fixes-design.md`
- 커밋은 `skills-toybox:commit` 스킬로 생성한다. 한 줄 Conventional Commit 형식.
- `catalog/toymarket.json`과 생성 파일(`.claude-plugin/plugin.json` 등)은 이번 작업 범위에서 변경하지 않는다. make-pr-fe는 스킬 단위 삭제이며 플러그인 메타데이터에는 영향이 없다.
- `docs/superpowers/plans/2026-07-23-repo-direction-principles.md`의 make-pr-fe 언급은 과거 작업 기록이므로 수정하지 않는다.

---

### Task 1: mcp-manager 자동 등록에 확인 단계 추가

**Files:**
- Modify: `plugins/mcp-manager/CLAUDE.md`
- Modify: `plugins/mcp-manager/commands/mcp-check.md`
- Modify: `plugins/mcp-manager/commands/mcp-fix.md`

**Interfaces:**
- 없음. 문서 텍스트 수정만 발생하며 다른 태스크가 참조하는 함수/타입 없음.

- [ ] **Step 1: `plugins/mcp-manager/CLAUDE.md`의 "자동 수정" 절 수정**

파일의 다음 블록을 찾는다:

```markdown
### 자동 수정

`MISSING_SERVERS` 발견 시 누락된 서버에 대해 다음 명령어로 자동 등록:

```bash
claude mcp add --transport http figma https://mcp.figma.com/mcp
claude mcp add --transport http notion https://mcp.notion.com/mcp
claude mcp add --transport http slack https://server.smithery.ai/slack/mcp
```

등록 후 사용자에게 `/mcp`로 OAuth 인증이 필요할 수 있음을 안내.
```

다음으로 교체한다:

```markdown
### 자동 수정

`MISSING_SERVERS` 발견 시 등록 전에 사용자에게 확인한다: "다음 MCP 서버가 누락되었습니다: {누락된 서버 목록}. 지금 등록할까요? (Y/n)"

사용자가 승인하면 다음 명령어로 등록:

```bash
claude mcp add --transport http figma https://mcp.figma.com/mcp
claude mcp add --transport http notion https://mcp.notion.com/mcp
claude mcp add --transport http slack https://server.smithery.ai/slack/mcp
```

등록 후 사용자에게 `/mcp`로 OAuth 인증이 필요할 수 있음을 안내.
```

- [ ] **Step 2: `plugins/mcp-manager/commands/mcp-fix.md` 전체를 아래 내용으로 교체**

```markdown
---
name: mcp-fix
description: 누락된 MCP 서버 확인 후 등록
allowed-tools:
  - Bash
---

누락된 MCP 서버를 사용자에게 확인받은 뒤 등록한다.

## MCP 등록 명령

```bash
claude mcp add --transport http figma https://mcp.figma.com/mcp
claude mcp add --transport http notion https://mcp.notion.com/mcp
claude mcp add --transport http slack https://server.smithery.ai/slack/mcp
```

## 절차

1. 누락된 MCP 목록을 사용자에게 보여주고 등록해도 될지 확인한다 (Y/n)
2. 승인하면 위 명령어를 실행해서 누락된 MCP 등록
3. 등록 성공 여부 확인
4. 사용자에게 `/mcp`로 OAuth 인증 완료하라고 안내

## 주의

- 이미 등록된 MCP를 다시 등록하면 에러 발생할 수 있음
- 먼저 `/mcp-check`로 상태 확인 권장
```

- [ ] **Step 3: `plugins/mcp-manager/commands/mcp-check.md` 전체를 아래 내용으로 교체**

```markdown
---
name: mcp-check
description: MCP 서버 상태 확인 및 확인 후 수정
allowed-tools:
  - Bash
  - Read
---

MCP 서버 상태를 확인하고 문제가 있으면 사용자 확인 후 수정한다.

## 확인 절차

1. `claude mcp list` 실행해서 현재 등록된 MCP 확인
2. 플러그인의 `.mcp.json` 파일과 비교
3. 누락된 MCP가 있으면 사용자에게 등록 여부를 확인한 뒤 등록

## 필수 MCP 목록

이 플러그인에서 관리하는 MCP:
- **figma**: `https://mcp.figma.com/mcp` (HTTP)
- **notion**: `https://mcp.notion.com/mcp` (HTTP)
- **slack**: `https://server.smithery.ai/slack/mcp` (HTTP)

## 확인 후 수정

누락된 MCP 발견 시 다음을 사용자에게 보여주고 등록해도 될지 확인한다: "다음 MCP 서버가 누락되었습니다: {목록}. 지금 등록할까요? (Y/n)"

승인 시 다음 명령어로 등록:

```bash
claude mcp add --transport http figma https://mcp.figma.com/mcp
claude mcp add --transport http notion https://mcp.notion.com/mcp
claude mcp add --transport http slack https://server.smithery.ai/slack/mcp
```

## 인증 안내

HTTP MCP 서버(figma, notion, slack)는 OAuth 인증이 필요할 수 있다.
등록 후 `/mcp` 명령어로 인증 상태를 확인하고, 필요시 사용자에게 인증을 안내한다.

## 실행

!`${CLAUDE_PLUGIN_ROOT}/hooks/check-mcp.sh`

위 결과에 따라:
- `MCP_CHECK: OK` → "모든 MCP 정상"이라고 알림
- `MCP_CHECK: MISSING_SERVERS` → 누락된 서버를 사용자에게 확인받은 뒤 등록 시도, 결과 보고
```

- [ ] **Step 4: `hooks/check-mcp.sh`는 수정하지 않는다는 것을 확인**

```bash
git diff --stat plugins/mcp-manager/hooks/check-mcp.sh
```

Expected: 출력 없음 (변경 없음)

- [ ] **Step 5: 세 파일 모두 "자동"이라는 단어가 확인 절차 없이 등록을 지시하는 문맥으로 남아있지 않은지 확인**

```bash
grep -n "자동" plugins/mcp-manager/CLAUDE.md plugins/mcp-manager/commands/mcp-check.md plugins/mcp-manager/commands/mcp-fix.md
```

Expected: 남아있는 "자동" 언급은 모두 "확인 후" 문맥 안에 있어야 한다. 파일명 그대로인 "자동 수정"/"자동 등록" 제목은 사용자 확인 절차가 그 아래에 명시돼 있으면 허용.

- [ ] **Step 6: Commit**

```bash
git add plugins/mcp-manager/CLAUDE.md plugins/mcp-manager/commands/mcp-check.md plugins/mcp-manager/commands/mcp-fix.md
git commit -m "fix(mcp-manager): require user confirmation before auto-registering MCP servers"
```

---

### Task 2: make-pr-fe 스킬 삭제

**Files:**
- Delete: `plugins/skills-toybox/skills/make-pr-fe/SKILL.md`
- Delete: `plugins/skills-toybox/skills/make-pr-fe/references/frontend-pr-guide.md`
- Delete: `plugins/skills-toybox/skills/make-pr-fe/references/verification-prompt.md`
- Modify: `plugins/skills-toybox/CLAUDE.md`

**Interfaces:**
- 없음. Task 1과 독립적이다.

- [ ] **Step 1: make-pr-fe 디렉토리 전체 삭제**

```bash
git rm -r plugins/skills-toybox/skills/make-pr-fe
```

Expected: 3개 파일이 삭제 스테이징됨

- [ ] **Step 2: `plugins/skills-toybox/CLAUDE.md`의 구조 목록에서 make-pr-fe 줄 제거**

파일의 다음 블록을 찾는다:

```markdown
## 구조

```
skills-toybox/
├── .claude-plugin/plugin.json   # 플러그인 메타데이터
└── skills/                      # AI 기반 skill
    ├── commit/                  # Conventional Commit 커밋 생성
    ├── code-review/             # 로컬 코드 품질 검증
    ├── make-pr/                 # 범용 PR 생성
    ├── make-pr-fe/              # 프론트엔드 PR 생성 (release/* 타겟, 템플릿 준수, 검증 하네스)
    ├── retrospect/              # 세션 회고
    ├── reflection/              # Claude instructions 분석/개선
    ├── command-validator/       # command 검증 도구
    └── respond-review/          # PR 리뷰 대응
```
```

`make-pr-fe/` 줄을 제거하고 다음으로 교체한다:

```markdown
## 구조

```
skills-toybox/
├── .claude-plugin/plugin.json   # 플러그인 메타데이터
└── skills/                      # AI 기반 skill
    ├── commit/                  # Conventional Commit 커밋 생성
    ├── code-review/             # 로컬 코드 품질 검증
    ├── make-pr/                 # 범용 PR 생성
    ├── retrospect/              # 세션 회고
    ├── reflection/              # Claude instructions 분석/개선
    ├── command-validator/       # command 검증 도구
    └── respond-review/          # PR 리뷰 대응
```
```

- [ ] **Step 3: 잔여 참조 확인**

```bash
grep -rl "make-pr-fe" --include="*.md" --include="*.json" .
```

Expected: `docs/superpowers/plans/2026-07-23-repo-direction-principles.md` 한 줄만 출력됨 (과거 기록이므로 그대로 둠)

- [ ] **Step 4: `catalog/toymarket.json`에 make-pr-fe 관련 항목이 없는지 확인**

```bash
grep -n "make-pr-fe" catalog/toymarket.json
```

Expected: 출력 없음 (애초에 스킬 단위 항목이 없었으므로 변경 불필요)

- [ ] **Step 5: verify_repo 통과 확인**

```bash
python3 scripts/verify_repo.py --profile dual --full
```

Expected: 에러 없이 통과

- [ ] **Step 6: Commit**

```bash
git add plugins/skills-toybox/CLAUDE.md
git commit -m "refactor(skills-toybox): remove Meissa-specific make-pr-fe skill"
```

---

### Task 3: pick-subagent 자기 설명 수정

**Files:**
- Modify: `plugins/pick-subagent/CLAUDE.md`

**Interfaces:**
- 없음. Task 1, 2와 독립적이다.

- [ ] **Step 1: 첫 문단 교체**

파일의 다음 줄을 찾는다:

```markdown
# pick-subagent

서브에이전트 모델을 골라 실행하는 슬래시 커맨드 모음 + 서브에이전트 루프 스킬.
```

다음으로 교체한다:

```markdown
# pick-subagent

서브에이전트를 잘 활용하기 위한 도구 모음. 모델을 지정해 가볍게 위임하는 슬래시 커맨드 4개와, 계획→검증계획→실행→검증을 반복해 품질을 보장하는 subagent-loop 스킬을 함께 담는다.
```

나머지 섹션("왜 존재하는지", "언제 쓰면 안 되는지", "구성")은 그대로 둔다.

- [ ] **Step 2: "+" 형태의 이분법적 서술이 남아있지 않은지 확인**

```bash
grep -n "+" plugins/pick-subagent/CLAUDE.md
```

Expected: "구성" 목록의 `서브에이전트 파이프라인 + 10점 검증 루프` 한 줄만 남아 있어야 한다. 이는 subagent-loop 스킬 자체의 내부 동작을 설명하는 것으로, 플러그인 전체를 두 개념으로 나누는 서술이 아니므로 유지한다.

- [ ] **Step 3: Commit**

```bash
git add plugins/pick-subagent/CLAUDE.md
git commit -m "docs(pick-subagent): describe commands and subagent-loop as one concept"
```

---

## 최종 검증 (전체 태스크 완료 후)

```bash
python3 scripts/verify_repo.py --profile dual --full
./plugins/matryoshka-plugin/scripts/lint-all.sh
```

Expected: 둘 다 에러 없이 통과
