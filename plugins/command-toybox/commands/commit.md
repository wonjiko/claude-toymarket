---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*)
description: Conventional Commit 형식으로 커밋
---

# Git Commit

## 현재 상태

- git status: !`git status --short`
- staged diff: !`git diff --staged`
- unstaged diff: !`git diff`

## 작업

1. 위 변경사항을 분석해서 커밋 메시지를 생성해
2. 변경된 파일들을 staging하고 커밋해

## Conventional Commit 형식

```
<type>(<scope>): <subject>
```

### Type (필수)
- `feat`: 새로운 기능 추가
- `fix`: 버그 수정
- `docs`: 문서 변경 (README, 주석 등)
- `style`: 코드 포맷팅, 세미콜론 누락 등 (기능 변경 없음)
- `refactor`: 코드 리팩토링 (기능/버그 수정 아님)
- `perf`: 성능 개선
- `test`: 테스트 추가/수정
- `build`: 빌드 시스템/외부 의존성 변경 (npm, gradle 등)
- `ci`: CI 설정 변경 (GitHub Actions, Jenkins 등)
- `chore`: 기타 변경사항 (빌드 스크립트, 패키지 매니저 설정 등)
- `revert`: 이전 커밋 되돌리기

### Scope (선택)
- 변경된 모듈/컴포넌트/파일명 (예: auth, api, ui, parser)
- 여러 scope인 경우 쉼표로 구분 또는 생략

### Subject 규칙 (필수)
- 영어로 작성
- 50자 이내 (한 줄)
- 현재형 동사로 시작 (add, fix, update, remove, refactor)
- 첫 글자 소문자
- 마침표 없음
- "what"과 "why"를 간결하게 표현

### 좋은 커밋 메시지 작성법
1. 하나의 커밋 = 하나의 논리적 변경
2. 커밋만 보고 변경 내용을 이해할 수 있어야 함
3. 코드 변경과 관련 없는 내용 포함 금지
4. 여러 파일 변경시에도 하나의 목적이어야 함

### 좋은 예시
- `feat(auth): add OAuth2 Google login support`
- `fix(api): handle null response from payment gateway`
- `refactor(database): extract connection pooling logic`
- `perf(query): optimize user search with index`
- `test(utils): add unit tests for date formatting`

### 피해야 할 예시
- `fix: bug fix` (무엇을 고쳤는지 불명확)
- `update code` (type 누락, 내용 불명확)
- `feat: Add new feature` (대문자 시작)
- `misc changes` (의미 없는 메시지)
- `fix: resolve issue.` (마침표 포함)
