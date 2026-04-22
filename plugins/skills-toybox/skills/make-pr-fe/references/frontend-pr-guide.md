# Frontend PR Guide (Meissa)

출처:
- Frontend PR Guide — https://www.notion.so/meissa/Frontend-PR-Guide-2632973c1a5f804883e0eed52173b77c (2026-04-17 기준)
- Meissa Code Review Convention (상위) — https://www.notion.so/b87481a90e944e29ab616ba2d2d0a413 (2026-02-11 기준)

FE 규칙은 상위 문서를 따르되, Frontend PR Guide가 더 구체적이면 그것을 우선한다. 이 문서는 skill이 실행될 때 참조용으로 쓰는 **정적 스냅샷**이다. skill은 실행 시점에 Notion MCP로 최신본을 재조회한다. 조회 실패 시 이 문서가 fallback.

## Principles
- 변경 의도와 맥락을 충분히 설명
- 작은 단위로 나누어 올림
- 빠른 리뷰가 가능한 PR 지향

## Base branch (FE)
- 기본 base: **`master`** (FE 기준)
- 릴리즈 준비 중이면 최신 `release/*` 브랜치
- 브랜치 이름에 따른 권장 base
  - `feature/*` → `release/*`가 있으면 그곳, 없으면 `master`
  - `bridge/*` → `release/*` 또는 `master`
  - `hotfix/*` → `master`
  - `release/*` 자체 → `master`

## Title
- 형식: `[타입] 변경 사항 요약`
- 예: `[Feature] 포토박스 앨범명 변경 팝업 높이 수정`
- 타입 목록
  - **Feature** — 기능 개발 브랜치
  - **Bridge** — 하나의 큰 작업 통합 브랜치
  - **QA** — QA 대응 브랜치
  - **Release** — 릴리즈용 브랜치
  - **Test** — 머지가 목적이 아닌 임시 목적용 브랜치
- 70자 이하 권장, 마침표로 끝내지 않음

## Body Template
```markdown
# Description about change
- 변경한 내용에 대한 간단/구체적 설명을 작성
- UI 변경이 있다면 스크린샷(또는 캡처 GIF)을 첨부
- 단순 스크린샷 한 장으로 빠른 이해가 된다면 첨부

## Context
- 변경점이 일어나게 된 맥락
- Feature 타입에 대해서만 작성

## References, Discussions, etc
- 관련 내용 첨부
```

보완 규칙 (상위 문서 PR Description)
- **Description about change**: 기술 필수 항목
- **Test scope / Change impact**: 기술 필수 항목. 변경이 기존 코드에 어떤 영향을 미치는지 기재
- **Ref link**: 선택 항목

## Files Changed
- 번역 파일은 카운트 제외
- 30개 초과 시 PR 본문에 사유와 대안(쪼갤 수 없는 이유) 명시 (근거 기준은 팀 합의에 따라 유동적)

## Label
기본적으로 하나만 사용하되, 필요하면 중복 사용 가능.

### 작업 단위 (level)
- **level 1** — Skeleton (구조)
- **level 2** — level 1 + Interface (선언)
- **level 3** — level 2 + Implement (구현)

### 우선도 (D-n)
- **D-0** — ASAP, 긴급은 유선/Slack 병행
- **D-1** — within 1 day
- **D-2** — within 2 days
- **D-5** — within 5 days

### 성격
- **release** — 이번 배포에 포함되어야 하는 feature/bridge
- **bug** — 버그 수정
- **enhancement** — 개선 (현재 default에 가까운 사용)
- **migration** — migration file 변경

### 중복 예시
- `bug + enhancement`: 버그 수정 + 개선점 동시
- `bug + deployment` (또는 `bug + release`): 핫픽스 즉시 릴리즈

## Review
- 머지 전 **2인 이상** 리뷰 (QA 건은 1명 이상)
- Conversation vs PR Comment 구분
  - 답변 받아야 넘어가길 원하면 Conversation
  - 그 외는 PR Comment
- 수정 반영 후 **re-request** 필수
- Conversation **resolve는 요청자만**
- AI가 만든 Conversation은 Resolve 전 반영/미반영 여부 기재, 작성자가 Resolve 가능

## Comment priority (Pn)
Reviewer가 달고 Assignee가 반응. 머지 전 모든 comment는 resolve 되어야 함.

- **P1** — 꼭 반영 (Request changes)
- **P2** — 적극 고려 (Request changes)
- **P3** — 웬만하면 반영 (Comment)
- **P4** — 반영해도 넘어가도 좋음 (Approve)
- **P5** — 사소한 의견 (Approve)

## PR 개수 / 분리
- 작은 단위 PR 선호
- 초과분은 사유와 쪼갤 수 없는 이유를 본문에 명시

## Scope 표기 (상위 문서)
- **Description about change**: 필수
- **Test scope / Change impact**: 필수
- 영향 범위 예: 특정 feature 영역, 공통 유틸, API 호출부 등
