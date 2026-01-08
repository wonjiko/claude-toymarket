# 전형적인 프로세스 (Typical Process)

Claude Code용 세션 기반 개발 워크플로우 플러그인입니다.

## Overview

**Planning → Execution → Retrospective** 3단계 프로세스를 통해 체계적인 개발을 지원합니다.

- 세션 단위로 작업을 관리
- 작업 계획과 실행 로그를 문서화
- 세션 간 컨텍스트 유지
- 회고를 통한 지속적 개선

## Installation

### 로컬 설치
```bash
claude plugin marketplace add ./typical-process
claude plugin install typical-process@typical-process
```

### GitHub에서 설치 (배포 후)
```bash
claude plugin marketplace add pulp/typical-process
claude plugin install typical-process@typical-process
```

## Commands

| Command | Description |
|---------|-------------|
| `/typical-process:start [name]` | 새 세션 시작 |
| `/typical-process:execute` | 현재 세션 작업 실행 |
| `/typical-process:sync` | 문서-상태 동기화 |
| `/typical-process:sessions [name]` | 세션 목록/전환 |
| `/typical-process:retrospect` | 세션 회고 |

## Usage

### 1. 새 세션 시작
```
/typical-process:start add-authentication
```
- 계획 문서 (`add-authentication-plan.md`) 생성
- 컨텍스트 문서 (`add-authentication-context.md`) 생성
- 코드베이스 분석 후 작업 계획 제시
- 사용자 승인 대기

### 2. 작업 실행
```
/typical-process:execute
```
- 다음 미완료 작업 식별
- 작업 실행 및 문서 업데이트
- 진행상황 자동 기록

### 3. 세션 전환
```
/typical-process:sessions              # 목록 보기
/typical-process:sessions fix-bug      # 세션 전환
```

### 4. 동기화
```
/typical-process:sync
```
- 계획과 컨텍스트 문서 동기화
- 진행률 자동 계산

### 5. 회고 및 완료
```
/typical-process:retrospect
```
- 완료된 작업 요약
- 개선점 분석
- 아카이브 옵션 제공

## Session Files

플러그인은 프로젝트의 `.claude/session/`에 파일을 저장합니다:

```
.claude/session/
├── active                        # 현재 활성 세션명
├── add-auth-plan.md              # 계획 문서
├── add-auth-context.md           # 실행 컨텍스트
└── archive/                      # 완료된 세션
    ├── old-feature-plan.md
    ├── old-feature-context.md
    └── old-feature-retrospect.md
```

### 권장 .gitignore 설정
```
.claude/session/
```

## Document Templates

### Plan Document
```markdown
# Plan: [session_name]

## Meta
- Session: [session_name]
- Created: [timestamp]
- Status: draft | approved | in-progress | completed

## Objective
[What we're building and why]

## Tasks
- [ ] Task 1
- [ ] Task 2

## Files to Modify
- `path/to/file.ts` - [reason]

## Acceptance Criteria
[How we know it's done]
```

### Context Document
```markdown
# Context: [session_name]

## State
- Phase: planning | execution | completed
- Started: [timestamp]
- Last Activity: [timestamp]
- Progress: 0/N tasks

## Execution Log

### [timestamp] - Task: [name]
- **Action:** [what was done]
- **Files:** [files modified]
- **Result:** success | blocked
```

## Hooks

플러그인은 자동으로 두 개의 훅을 등록합니다:

- **SessionStart**: 활성 세션 상태 표시
- **SessionEnd**: 마지막 활동 시간 업데이트

## License

MIT
