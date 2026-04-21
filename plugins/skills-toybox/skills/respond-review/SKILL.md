---
name: respond-review
description: This skill should be used when the user wants to "respond to review", "리뷰 대응", "PR 리뷰 반영", "리뷰 코멘트 처리", "address review comments", or needs to process PR review feedback by analyzing comments, deciding accept/reject, modifying code, and posting responses.
version: 0.1.0
---

# PR 리뷰 대응

GitHub PR에 달린 리뷰 코멘트를 수집하고, 각 코멘트에 대해 반영/미반영을 판단한 뒤, 유저 컨펌을 거쳐 코드 수정과 PR 코멘트를 수행한다. 분석과 코드 수정 모두 서브에이전트 병렬 실행을 활용한다.

## 왜 존재하는지

PR 리뷰를 받은 뒤 각 코멘트에 대응하는 작업(코멘트 읽기, 코드 확인, 반영 판단, 수정, 응답)을 자동화한다.

## 언제 쓰면 안 되는지

- PR을 새로 만들 때 (make-pr 사용)
- 로컬 코드 품질 검증 (code-review 사용)
- 리뷰를 작성할 때 (이 스킬은 리뷰를 "받은 뒤 대응"하는 스킬)

## 워크플로우

### Step 1: 초기 설정

1. PR URL 확인 — 유저가 입력하거나, `gh pr view --json url -q .url`로 현재 브랜치의 PR 자동 탐지
2. 자동화 범위 질문:
   > 코드 수정 후 자동으로 커밋하고 PR에 응답 코멘트를 남길까요? (Y/n)
3. `gh api`로 리뷰 코멘트 전체 수집:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{pr_number}/comments
   gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews
   ```
4. lessons 파일 로드:
   - 스킬 내장: 이 스킬 디렉토리의 `lessons.md`
   - 유저 레벨: `~/.claude/respond-review-lessons.md`
   - 두 파일 내용을 합쳐서 분석 시 참고

### Step 2: 분석

코멘트가 **4개 이상**이면 서브에이전트로 병렬 분석, **3개 이하**이면 메인 세션에서 순차 분석.

메인 세션이 각 코멘트에 대해:
- 코멘트 성격을 파악하고 **추천 읽기 범위**를 결정
- 분석 서브에이전트에게 전달

#### 분석 서브에이전트 프롬프트

```
## 작업
PR 리뷰 코멘트를 분석하고 반영 여부를 판단하라.

## 코멘트 정보
- 작성자: {reviewer}
- 위치: {file_path}:{line_range}
- 내용: {comment_body}

## 해당 코드의 diff
{diff_hunk}

## 현재 파일 내용
Read 도구로 {file_path}를 읽어라.
추천 읽기 범위: {recommended_range} ({range_reason})
필요하다고 판단되면 더 넓게 읽어도 된다.

## 기존 판단 기준 (lessons)
{lessons_content}

## 판단 기준
- 버그 수정, 보안 이슈 → 반영
- 코드 컨벤션, 가독성 향상 → 반영
- 취향 차이, 트레이드오프가 있는 설계 의견 → 미반영 가능
- 현재 PR 범위 밖의 리팩토링 제안 → 미반영 가능
- 기존 lessons가 있으면 우선 참고

## 출력 (이 포맷을 정확히 따라라)
판단: 반영 | 미반영
사유: (1-2문장, 기술적 근거)
근거: (왜 그 판단이 적절한지, 코드 기반 설명)
영향 범위:
  - {file_path}:{function_name 또는 line_range}
  - (수정 시 영향받는 다른 파일이 있으면 추가)
수정 계획: (반영일 경우) 구체적으로 무엇을 어떻게 바꿀지
  (미반영일 경우) "없음"

## 제약
- 코드를 수정하지 마라. 분석만 하라.
- Read/Grep 도구만 사용하라.
- 추측하지 말고 코드를 읽고 판단하라.
```

### Step 3: 유저 컨펌

분석 결과를 아래 포맷으로 한 번에 제시:

```markdown
## PR 리뷰 대응 계획 (#{pr_number})

### 1. [반영] {file_path}:{line} — @{reviewer}
> 원본 코멘트: "{comment_body}"

\`\`\`diff
{diff_hunk}
\`\`\`

**사유**: {reason}
**근거**: {evidence}
**수정 계획**: {plan}

---

### 2. [미반영] {file_path}:{line} — @{reviewer}
> 원본 코멘트: "{comment_body}"

\`\`\`diff
{diff_hunk}
\`\`\`

**사유**: {reason}
**근거**: {evidence}
**수정 계획**: 없음

---

> 수정할 항목이 있으면 번호와 변경 내용을 알려주세요.
> 없으면 "확인"으로 진행합니다.
```

유저가 수정할 항목만 고치고, 나머지는 그대로 승인.

### Step 4: 그룹핑

반영 항목만 대상으로, Step 2에서 보고된 영향 범위 기반으로 그룹핑:
- 같은 파일의 같은 함수를 수정하는 코멘트 → 같은 그룹
- 파일 간 의존성이 있는 코멘트(import 관계 등) → 같은 그룹
- 독립적인 코멘트 → 별도 그룹

### Step 5: 코드 수정

그룹별로 서브에이전트를 병렬 디스패치.

#### 수정 서브에이전트 프롬프트

```
## 작업
유저가 승인한 PR 리뷰 코멘트를 코드에 반영하라.

## 반영할 코멘트 목록
{각 코멘트별:}
- 코멘트: {comment_body}
- 파일: {file_path}:{line_range}
- 승인된 수정 계획: {modification_plan}

## 제약
- 승인된 수정 계획에 명시된 범위만 수정하라.
- 수정 계획에 없는 추가 개선을 하지 마라.
- 수정 후 관련 파일의 import, 타입, 호출부가 깨지지 않는지 확인하라.
- Edit 도구를 사용하라.

## 완료 보고
수정한 파일 목록:
  - {file_path}: {무엇을 변경했는지 1줄 요약}
```

### Step 6: 마무리

1. **수정 결과 취합** — 각 서브에이전트의 완료 보고를 모아 유저에게 요약
2. **커밋** (자동화 선택 시) — 변경 파일을 스테이징하고 커밋
3. **PR 코멘트** (자동화 선택 시) — 각 리뷰 코멘트에 개별 reply:
   - 반영 항목: `반영: {수정 내용 1-2문장 요약}`
   - 미반영 항목: `미반영: {사유 1-2문장}`
4. **lessons 축적** — 유저가 Step 3에서 판단을 수정한 항목이 있으면:
   - 수정 패턴 추출
   - `~/.claude/respond-review-lessons.md`에 추가할 규칙 제안
   - 유저 컨펌 후 저장
5. **lessons 안내** (lessons 파일이 충분히 쌓였을 때, 가끔):
   > `~/.claude/respond-review-lessons.md`에 규칙이 쌓이고 있습니다. 확정된 규칙은 스킬 내장으로 옮길 수 있어요.

## PR 코멘트 작성 방법

```bash
# 특정 리뷰 코멘트에 reply
gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies \
  -f body="반영: {내용}"
```

## lessons 파일 포맷

```markdown
# respond-review lessons

## 반영 경향
- {규칙} ({날짜} 학습)

## 미반영 경향
- {규칙} ({날짜} 학습)
```

## 예외 처리

| 상황 | 대응 |
|------|------|
| 리뷰 코멘트 없음 | 처리할 코멘트가 없다고 안내 |
| PR URL 잘못됨 | 올바른 URL인지 확인 요청 |
| 이미 resolved된 코멘트 | 건너뛰고 안내 |
| 서브에이전트 수정 충돌 | 충돌 파일을 유저에게 보여주고 수동 해결 요청 |
| lessons 파일 없음 | 기본 판단 기준만으로 진행, 파일 자동 생성 |
