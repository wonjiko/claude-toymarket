---
name: make-pr-fe
description: This skill should be used when the user wants to "make a pr fe", "create fe pr", "프론트 pr", "frontend pr", "릴리즈 pr" or needs to generate a pull request for a Meissa frontend repository — honors the Frontend PR Guide (타입 prefix, Description/Context template, D-n/level/release labels), auto-selects release/* (or master) base, applies assignee and labels, then runs a verification subagent.
version: 0.1.0
---

# Frontend PR 생성

Meissa Frontend 저장소용 PR 생성. Frontend PR Guide를 **엄격히 준수**하고, `release/*` 우선 base, assignee·label 자동 설정, 생성 후 검증 서브에이전트로 결과를 교차 확인한다.

범용 `make-pr`와의 차이:
- 제목은 `[Feature|Bridge|QA|Release|Test] subject` 형식 고정
- 본문은 Description about change / Context / References, Discussions, etc 템플릿 준수
- Test scope / Change impact 섹션 포함
- Label은 Meissa FE 라벨 체계(D-n, level-n, release, bug, enhancement, migration 등)에서 선택
- 생성 후 서브에이전트가 가이드 준수 여부를 검증하고 메타 항목은 자동 수정

## 가이드 소스

우선순위:
1. **Notion MCP** 실시간 재조회 — `notion-fetch` 로 `https://www.notion.so/meissa/Frontend-PR-Guide-2632973c1a5f804883e0eed52173b77c` (성공 시 최신본 우선)
2. **references/frontend-pr-guide.md** — 정적 스냅샷 fallback
3. **저장소 PR 템플릿** — `.github/PULL_REQUEST_TEMPLATE.md` 등이 별도로 있으면 섹션을 그대로 포함 (가이드와 상충하면 가이드 섹션을 추가로 덧붙임)
4. **최근 merged PR 5~10건** — 실제 레포에서 쓰고 있는 문구·라벨 패턴 확인

## 프로세스

### Step 1: 컨텍스트 수집 (병렬)

1. **브랜치 상태**
   - `git branch --show-current`
   - `git status --porcelain`
2. **Base 결정**
   - `git fetch origin --prune`
   - `git branch -r | grep -E 'origin/release/'` → `sort -V` 내림차순 최상위
   - release/* 없으면 `master` (없으면 `main`) fallback
   - 현재 브랜치가 `release/*` 자체면 base는 `master`
   - 현재 브랜치가 `hotfix/*`면 base는 `master`
   - 현재 브랜치가 `master`/`main`이면 PR 생성 불가 안내 후 종료
3. **변경사항**
   - `git log --oneline <base>..HEAD`
   - `git diff <base>...HEAD`
   - `git diff --stat <base>...HEAD`로 파일 수·수정량(번역 파일 제외 카운트) 파악
4. **가이드 조회**
   - Notion MCP `notion-fetch`로 Frontend PR Guide 재조회. 실패하면 `references/frontend-pr-guide.md`를 읽어 사용
5. **저장소 PR 템플릿**
   - `.github/PULL_REQUEST_TEMPLATE.md`, `.github/pull_request_template.md`, `docs/pull_request_template.md`, `PULL_REQUEST_TEMPLATE.md` 순 확인
6. **최근 PR 패턴 (5~10건)**
   - `gh pr list --state merged --limit 10 --json number,title,body,labels,headRefName,baseRefName,author`
   - 필요 시 `gh pr view <n> --json body,labels`로 2~3건 샘플링
7. **레포 라벨 목록**
   - `gh label list --limit 100 --json name,description,color`
8. **Assignee**
   - `gh api user --jq .login`
9. **중복 PR 확인**
   - `gh pr list --head <branch> --state open --json number,url`
   - 존재하면 기존 PR URL만 안내하고 종료

### Step 2: 타입·제목·라벨 결정

#### 2.1 타입 결정 (`[타입]` prefix)

현재 브랜치명과 변경 성격으로 결정.

| 신호 | 선택 |
|------|------|
| 브랜치 `feature/*` 또는 기능 추가 diff | `Feature` |
| 브랜치 `bridge/*` 또는 여러 feature 통합 | `Bridge` |
| 브랜치 `qa/*` 또는 QA 대응 커밋 메시지 | `QA` |
| 브랜치 `release/*` 또는 base가 master인 release 머지 | `Release` |
| 머지 목적이 아닌 임시 배포/실험 | `Test` |

confidence가 낮으면(예: 브랜치명이 관례와 맞지 않음) 사용자에게 1회 확인.

#### 2.2 제목

- 형식: `[타입] 변경 사항 요약`
- 70자 이하, 마침표로 끝내지 않음
- 최근 PR 중 동일 타입 PR의 어조·길이를 참조

#### 2.3 본문 (템플릿 **누락 금지**)

기본 본문은 가이드 템플릿을 그대로 쓰고, Test scope 섹션을 추가한다.

```markdown
# Description about change
- <주요 변경 요약 bullet 2~5개>
- <UI 변경 시 스크린샷 플레이스홀더>

## Context
- <변경 맥락. Feature 타입이면 필수, 그 외는 간략하거나 N/A>

## Test scope / Change impact
- <영향 범위 · 테스트한 경로>

## References, Discussions, etc
- <링크. 없으면 "- N/A">
```

보완 규칙:
- 저장소 PR 템플릿이 있으면 **그 섹션을 모두 유지**하면서 위 가이드 섹션이 누락되면 추가
- 채울 수 없는 섹션은 `- N/A`
- UI 변경(styled-components, css, 이미지 파일 변경 등) 감지 시 Description 하단에 `- [ ] 스크린샷 첨부 필요` 플레이스홀더를 남기고 사용자에게 고지
- Files Changed가 30개(번역 파일 제외)를 넘으면 본문 끝에 다음 섹션 추가
  ```
  ## Files Changed 초과 사유
  - <쪼갤 수 없는 이유>
  ```

#### 2.4 Label (교차검증)

라벨은 **가이드 라벨 ∩ 레포 라벨 ∩ 최근 PR 사용 패턴**의 교차검증으로 결정한다.

| 후보 | 붙이는 조건 |
|------|--------------|
| `D-0`/`D-1`/`D-2`/`D-5` | 사용자가 우선도를 명시했거나 hotfix·release 맥락이면 가장 짧은 값. 확신 없으면 달지 않음 |
| `release` | base가 release/*이거나 타입이 Release |
| `bug` | 변경이 버그 수정 성격 (커밋 메시지 `fix`, 이슈 `#bug`) |
| `enhancement` | 개선 성격, 기본값 성격이 강한 변경. bug/release와 구분 어려우면 단일 사용 |
| `migration` | 마이그레이션 파일 변경 감지 |
| `level-1`/`level-2`/`level-3` | 가이드의 skeleton/interface/implement 기준. 레포에 해당 라벨이 존재하고 최근 PR에서 사용 중일 때만 |

절차:
1. 레포 라벨 목록에서 위 후보명을 **정확·근사 매칭**으로 찾음 (대소문자·하이픈 차이 허용)
2. 최근 merged PR에서 같은 성격(브랜치명·diff 유형)의 PR이 어떤 라벨을 달았는지 다수결 추출
3. 두 집합의 **교집합**을 최종 라벨로 채택
4. 교집합이 비면 **레포 라벨 쪽으로만** 보수적으로 1개 선택
5. 그래도 명확하지 않으면 라벨 없이 생성하고 검증 단계에서 사용자 확인

라벨 중복 허용 (예: `bug` + `release`).

#### 2.5 Assignee
- `gh api user --jq .login` 결과를 assignee로 지정
- 여러 명 지정이 관례인 레포라면 최근 PR 다수결을 참고해 자기 자신 + 관례적 추가 assignee

### Step 3: PR 생성

1. 사용자에게 1줄 고지: `push 및 PR 생성 시작 — base=<base>, title="<title>", assignee=<login>, labels=<list|none>`
2. `git push -u origin <branch>` (upstream 이미 있으면 `git push`)
3. `gh pr create` 실행
   ```bash
   gh pr create \
     --base <base> \
     --head <branch> \
     --title "[<Type>] <subject>" \
     --assignee <login> \
     --label "<label1>" --label "<label2>" \
     --body "$(cat <<'EOF'
   <본문>
   EOF
   )"
   ```
   - 레포에 없는 라벨은 제외
   - 라벨이 하나도 없으면 `--label` 생략
4. 생성된 PR URL 캡처

### Step 4: 검증 서브에이전트 dispatch

`references/verification-prompt.md`를 그대로 채워 Agent 도구(`subagent_type: general-purpose`)로 dispatch.

전달 변수:
- `<PR_URL>`
- `<BASE_BRANCH>`
- `<TEMPLATE_PATH>` — 없으면 `none`
- `<EXPECTED_ASSIGNEE>`
- `<EXPECTED_LABELS>` — JSON 배열 문자열
- `<PR_TYPE>` — Feature/Bridge/QA/Release/Test

서브에이전트는 체크리스트를 검증하고 메타·라벨·섹션 누락 같은 **기계적 수정**을 직접 수행한다. 제목/본문의 의미적 재작성이 필요하면 warn으로 보고만 한다.

### Step 5: 결과 보고

```
✓ PR 생성: <URL>
  base: <base>
  type: <Feature|Bridge|QA|Release|Test>
  assignee: <login>
  labels: <labels or none>
  template: <template path or none>
  guide source: <notion|snapshot>

검증 결과:
  - Pass: <요약>
  - Fixed: <자동 수정된 항목>
  - Warn: <사용자 확인 필요 항목>
  - Fail: <미해결 항목>
```

## 규칙

- 제목은 `[Feature|Bridge|QA|Release|Test] subject` **고정**. 다른 형식 사용 금지
- Description / Context / References, Discussions, etc 섹션은 **삭제 금지**. Test scope/Change impact 섹션은 필수 추가
- 저장소 PR 템플릿이 있으면 그 섹션 **보존하며** 가이드 섹션 누락분을 추가
- base는 최신 `release/*` 우선, 없으면 `master` (또는 `main`)
- assignee 기본값은 `gh api user` 로그인 계정
- 라벨은 교차검증, 확신 낮으면 달지 않기
- Co-Authored-By 추가 금지
- 마케팅 언어 금지, 사실만
- UI 변경 감지 시 스크린샷 플레이스홀더 명시하고 사용자에게 고지
- Files Changed 30개 초과(번역 제외) 시 사유 섹션 추가
- 검증 서브에이전트는 **반드시** 실행

## 예외 처리

| 상황 | 대응 |
|------|------|
| 현재 브랜치가 master/main | PR 불가 안내, 브랜치 생성 제안 |
| 현재 브랜치가 release/* | base를 master로 설정하고 진행, 타입은 Release로 추정 |
| release/* 브랜치 없음 | master로 fallback, 사용자에게 알림 |
| 이미 열린 PR 존재 | 기존 PR URL 반환 후 종료 |
| 변경사항 없음 | base와 차이 없음을 안내 |
| 커밋 없음 | `/skills-toybox:commit` 사용 제안 |
| Notion MCP 실패 | `references/frontend-pr-guide.md`로 fallback, 그 사실 한 줄 고지 |
| PR 템플릿과 가이드 충돌 | 템플릿 섹션 유지 + 가이드 필수 섹션 병합 |
| 라벨 매칭 불가 | 라벨 없이 생성, 검증 단계에서 사용자 확인 요청 |
| gh CLI 미설치/미로그인 | 설치·로그인 안내 (https://cli.github.com) |
| 검증 서브에이전트 실패 | PR URL은 유지, 수동 확인 항목 나열 |

## 참고 파일

- 가이드 스냅샷: `references/frontend-pr-guide.md`
- 검증 서브에이전트 프롬프트: `references/verification-prompt.md`
- 범용 PR 생성: `/skills-toybox:make-pr`
