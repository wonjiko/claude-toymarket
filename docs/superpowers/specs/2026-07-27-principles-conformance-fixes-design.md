# PRINCIPLES.md 준수 개선 설계

## 배경

PRINCIPLES.md 5개 원칙을 기준으로 6개 플러그인을 감사했다. 그중 반영하기로 확정한 항목 세 가지를 정리한다.

## 범위

### 1. mcp-manager 자동 등록에 확인 단계 추가

대상 파일
    `plugins/mcp-manager/CLAUDE.md`
    `plugins/mcp-manager/commands/mcp-check.md`
    `plugins/mcp-manager/commands/mcp-fix.md`

변경
    MCP 서버 등록(`claude mcp add ...`) 실행 직전에 사용자 확인을 받는 절차를 추가한다.

근거
    PRINCIPLES.md 원칙 1. 전역 Claude 설정을 세션마다 확인 없이 바꾸는 건 되돌리려면 사용자가 `claude mcp remove`를 알고 있어야 하고, 등록 즉시 OAuth 인증 흐름까지 이어질 수 있다.

건드리지 않는 것
    `plugins/mcp-manager/hooks/check-mcp.sh`는 등록 여부만 보고하고 실제 등록은 하지 않으므로 수정하지 않는다.

### 2. make-pr-fe 스킬 삭제

대상
    `plugins/skills-toybox/skills/make-pr-fe/` 디렉토리 전체(`SKILL.md`, `references/frontend-pr-guide.md`, `references/verification-prompt.md`)

변경
    디렉토리를 삭제하고, `plugins/skills-toybox/CLAUDE.md` 구조 목록에서 make-pr-fe 줄을 제거한다.

근거
    PRINCIPLES.md 원칙 5와 원칙 2. skills-toybox는 스스로 "범용 목적"이라 선언했는데 Meissa 전용 스킬을 포함하고 있었다. 별도 플러그인으로 옮기는 대신 삭제하기로 했다.

건드리지 않는 것
    `catalog/toymarket.json`은 플러그인 단위 메타데이터만 가지므로 수정 대상이 아니다. `AGENTS.md`의 "현재 플러그인" 표와 `README.md`는 이미 make-pr-fe를 나열하지 않으므로 수정 대상이 아니다. `docs/superpowers/plans/2026-07-23-repo-direction-principles.md`의 make-pr-fe 언급은 과거 작업 기록이므로 그대로 둔다.

### 3. pick-subagent — 구조는 유지, 자기 설명만 수정

대상
    `plugins/pick-subagent/CLAUDE.md`

변경
    "서브에이전트 모델을 골라 실행하는 슬래시 커맨드 모음 + 서브에이전트 루프 스킬"처럼 두 가지로 나눠 부르는 문장을, 커맨드와 subagent-loop를 하나의 개념으로 묶어 설명하는 문장으로 바꾼다. 파일 이동이나 catalog 변경은 없다.

근거
    커맨드 4개와 subagent-loop는 도구로서는 달라 보여도 "서브에이전트를 잘 활용한다"는 하나의 개념 아래 있다는 판단. 플러그인을 쪼개는 대신 자기 설명이 그 개념을 드러내도록 고친다.

## 검증

- 삭제 후 `grep -rl "make-pr-fe" --include="*.md" --include="*.json" .`로 남은 참조가 과거 계획 문서 하나뿐인지 확인
- `python3 scripts/verify_repo.py --profile dual --full` 통과
- `./plugins/matryoshka-plugin/scripts/lint-all.sh` 통과

## 검토한 대안

- make-pr-fe를 새 플러그인으로 분리 — 원칙에는 더 부합하지만, 팀 전용 워크플로우는 이 레포 밖에서 관리하는 게 낫다고 보고 삭제를 택했다.
- pick-subagent를 두 플러그인으로 분리 — 원칙 5엔 더 부합하지만, 두 구성요소를 하나의 개념으로 보는 판단에 따라 구조 변경 대신 설명 수정으로 대체했다.
