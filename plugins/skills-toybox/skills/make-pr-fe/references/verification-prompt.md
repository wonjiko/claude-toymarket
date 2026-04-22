# PR 검증 서브에이전트 프롬프트

`make-pr-fe` skill이 PR을 생성한 직후, 이 프롬프트를 채워 Agent 도구(`subagent_type: general-purpose`)로 dispatch한다. 서브에이전트는 Frontend PR Guide 준수 여부를 검증하고, 기계적으로 고칠 수 있는 항목은 `gh pr edit`으로 **직접 수정**한 뒤 보고한다.

---

## 프롬프트 템플릿

> 아래 내용을 그대로 Agent 프롬프트로 전달. `<...>`는 호출부에서 치환.

```
방금 생성된 Meissa Frontend PR의 품질을 Frontend PR Guide 기준으로 검증하고, 기계적으로 수정 가능한 문제는 `gh pr edit`으로 직접 고친 뒤 짧게 보고하라.

## 입력
- PR URL: <PR_URL>
- 기대 base 브랜치: <BASE_BRANCH>
- PR 타입 (Feature|Bridge|QA|Release|Test): <PR_TYPE>
- 저장소 PR 템플릿 경로: <TEMPLATE_PATH>   (none이면 템플릿 없음)
- 기대 assignee: <EXPECTED_ASSIGNEE>
- 기대 labels (JSON 배열): <EXPECTED_LABELS>

## 할 일

### 1. 상태 수집
- `gh pr view <PR_URL> --json number,title,body,baseRefName,headRefName,labels,assignees,author,isDraft,files,additions,deletions`
- `gh label list --limit 100 --json name` 로 레포 유효 라벨 확인
- `gh pr list --state merged --limit 5 --json title,body,labels`로 스타일 기준선 확보
- 가이드 재조회 시도: Notion MCP `notion-fetch`로 https://www.notion.so/meissa/Frontend-PR-Guide-2632973c1a5f804883e0eed52173b77c 호출. 실패하면 skill이 번들한 `references/frontend-pr-guide.md`를 읽는다 (skill 디렉토리 내).
- 템플릿이 있으면 해당 파일 Read로 섹션 구조 확보

### 2. 체크리스트

각 항목 pass/fail/warn 판정.

**A. 메타**
- [ ] base가 `<BASE_BRANCH>` 와 일치
- [ ] assignee에 `<EXPECTED_ASSIGNEE>` 포함
- [ ] labels가 `<EXPECTED_LABELS>` 와 일치 (순서 무시, 집합 동치)
- [ ] draft가 아님 (사용자가 요구했으면 예외)

**B. 제목 — Frontend PR Guide 규칙**
- [ ] 정규식 `^\[(Feature|Bridge|QA|Release|Test)\] .+$` 매칭
- [ ] `[타입]`이 `<PR_TYPE>`와 일치
- [ ] 70자 이하
- [ ] 마침표로 끝나지 않음
- [ ] 최근 merged PR의 어조·길이와 동떨어지지 않음

**C. 본문 — 가이드 섹션 준수**
다음 헤딩이 모두 존재하는지 정확 일치로 확인:
- [ ] `# Description about change`
- [ ] `## Context`
- [ ] `## Test scope / Change impact`
- [ ] `## References, Discussions, etc`

추가:
- [ ] 각 섹션에 내용 또는 `- N/A` 존재
- [ ] Feature 타입이면 Context가 비어 있지 않음
- [ ] Description에 주요 변경이 bullet으로 나열됨
- [ ] UI 변경이 감지되는데(styled-components, css, 이미지 diff) 스크린샷 플레이스홀더도 본문도 없으면 warn
- [ ] 변경 파일(번역 파일 제외)이 30개 초과인데 `## Files Changed 초과 사유` 섹션이 없으면 warn

**D. 본문 — 저장소 PR 템플릿 존재 시**
- [ ] 템플릿의 모든 섹션 헤딩이 보존됨 (가이드 섹션 추가와 별개로)
- [ ] 템플릿 체크리스트 형식 유지

**E. Label 적절성**
- [ ] 적용된 모든 라벨이 레포 라벨 목록에 실제로 존재
- [ ] 변경 성격과 모순되지 않음
  - 코드 변경 없이 docs만인데 `feat` 라벨 → 불일치
  - 마이그레이션 파일이 포함되는데 `migration` 라벨 없음 → 누락 가능성 warn
  - base가 release/*인데 `release` 라벨 없음 → 누락 가능성 warn
- [ ] 우선도 라벨(D-0/1/2/5)이 2개 이상 달리지 않음

**F. Review 준비**
- [ ] PR에 reviewer 지정 여부는 팀 정책(2인 이상)을 충족하도록 warn만 (자동 지정은 금지)

### 3. 자동 수정

**fail** 항목은 다음만 수정한다. 확신이 없으면 수정하지 말고 warn으로 보고.

| 항목 | 수정 방법 |
|------|-----------|
| base 불일치 | `gh pr edit <PR_URL> --base <BASE_BRANCH>` |
| assignee 누락 | `gh pr edit <PR_URL> --add-assignee <EXPECTED_ASSIGNEE>` |
| 라벨 불일치 | `gh pr edit <PR_URL> --add-label <name>` / `--remove-label <name>`. 레포에 없는 라벨은 추가하지 않음 |
| 본문 섹션 누락 | 누락된 가이드 섹션을 해당 위치에 삽입 (`# Description about change` → `## Context` → `## Test scope / Change impact` → `## References, Discussions, etc` 순서). 기존 섹션 내용 보존. 새 섹션 본문은 `- N/A` |
| 빈 섹션 | `- N/A` 한 줄 삽입 |
| 제목 형식 오류 (prefix 누락) | `[<PR_TYPE>] ` 를 앞에 붙여 `gh pr edit <PR_URL> --title "<new>"` |
| 제목이 마침표로 끝남 | 마침표 제거 |

본문 편집 시에는:
1. 현재 본문을 tmp 파일에 저장
2. 섹션 삽입/수정
3. `gh pr edit <PR_URL> --body-file <tmp>`
4. 임시 파일 삭제

**수정하지 않는 항목 (warn으로만 보고)**:
- 제목·본문의 의미적 재작성 (변경 요약이 diff와 다르거나 어조가 부적절 등)
- reviewer 지정
- 스크린샷 첨부 자체
- Files Changed 초과 사유 작성
- Context 섹션의 실제 맥락 작성 (Feature 타입인데 Context가 비어 있을 때)

### 4. 보고 형식

아래 형식만 출력하라. 서술형 설명 금지.

```
## PR 검증 결과

URL: <PR_URL>
Guide source: <notion|snapshot|failed>

### Pass
- <항목>

### Fixed (자동 수정됨)
- <항목>: <어떻게 수정했는지 한 줄>

### Warn (사용자 확인 필요)
- <항목>: <이유>

### 잔여 Fail
- <항목>: <이유>
```

각 섹션은 비어 있으면 `없음`으로 표시.

## 제약
- PR을 close/merge하지 않는다
- 사용자가 이미 작성한 유효 내용(체크리스트의 체크 상태 포함)은 보존
- 레포에 없는 라벨은 생성·추가하지 않음
- 확신 없으면 수정 대신 warn
- Notion MCP 조회 실패해도 작업 진행 (가이드 snapshot 사용)
- 한 번의 응답에 보고 형식만 포함
```
