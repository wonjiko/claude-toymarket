---
name: fe-task-card
description: This skill should be used when the user wants to log a frontend work item in the Meissa Notion ProductTeam Card Table — triggers include "FE 카드 만들어줘", "FE Task Card 생성", "노션에 프론트 업무 카드 등록", "이 작업 노션 카드로 만들어줘", "카드 하나 파줘". Not for Epic cards, bug reports from QA, or tech debt entries.
version: 0.1.0
---

# FE Task Card

## Overview

Meissa 노션 `ProductTeam Card Table`에 FE Task Card를 만든다.

**골격은 노션 템플릿이 원본이고, 문체는 요청자의 과거 카드가 원본이다.** 이 문서에는 섹션 구조도 문체 규칙도 적지 않는다. 노션에서 템플릿이 바뀌면 스킬이 따라가야 하기 때문이다. 대신 어디서 무엇을 읽어올지를 적는다.

## 고정 상수

| 항목 | 값 |
|---|---|
| data source | `collection://1d82973c-1a5f-81e6-9728-000b3e3cb467` |
| 템플릿 페이지 | `1d82973c-1a5f-8103-b6de-fd340d9f241a` |
| 데이터베이스 페이지 | `1d82973c1a5f808e8f3aea022ba4dfc6` |

템플릿 페이지 ID는 내용을 편집해도 유지된다. fetch가 실패하면 데이터베이스 페이지를 fetch해 `<templates>` 블록에서 `FE Task Card`를 이름으로 다시 찾는다.

## 절차

### 1. 요청자 확인

`notion-fetch`에 `self`를 넘겨 사용자 ID를 얻는다. 이 값이 `Who` 기본값이자 참고 카드 필터 기준이다.

### 2. 템플릿 구조 읽기

템플릿 페이지를 fetch한다. `<content>`의 heading과 회색 안내 문구가 이번 카드가 가져야 할 섹션 목록이다. 안내 문구는 그 섹션에 무엇을 쓸지 지시하므로 읽고 따르되 본문에 옮겨 적지 않는다.

### 3. 문체 참고 카드 수집

요청자가 최근에 쓴 FE 카드를 찾는다.

```sql
SELECT url, Subject, "Where", Release, "date:ETA:start", createdTime
FROM "collection://1d82973c-1a5f-81e6-9728-000b3e3cb467"
WHERE Who LIKE '%<사용자 ID>%' AND "Where" LIKE '%"FE"%'
ORDER BY createdTime DESC LIMIT 5
```

이 중 2~3건을 fetch해 본문을 읽고 관찰한다.

- 섹션 안에서 볼드 소제목으로 다시 묶는지, 불릿만 나열하는지
- 불릿 종결어미가 명사형인지 평서형인지
- 중첩 깊이를 어디까지 쓰는지
- 코드·패키지·경로를 인라인 코드로 감싸는지
- 범위 밖 항목이나 후속 메모를 따로 두는지

관찰 결과를 그대로 새 카드에 적용한다. 참고 카드가 한 건도 없으면 필터에서 `Where` 조건을 빼고 다시 조회한다.

### 4. 주제 참고 카드 수집

새 카드 주제의 키워드로 `notion-search`를 돌린다. `data_source_url`에 위 data source를 넘겨 이 DB 안으로 한정한다. 작성자는 가리지 않는다. 같은 기능이나 같은 모듈을 다룬 과거 카드가 있으면 fetch해 범위와 용어를 참고한다.

### 5. 속성 확정

| 속성 | 규칙 |
|---|---|
| Subject | 사용자가 준 제목. 없으면 작업 내역에서 한 줄로 뽑아 확인받는다 |
| Where | `["FE"]`. 백엔드나 다른 환경이 함께 걸리면 추가한다 |
| Who | 요청자. 사용자가 다른 담당자를 지정하면 `notion-get-users`로 ID를 찾아 넣는다 |
| Status | `TO-DO` |
| ETA | **비워두지 않는다.** 사용자가 주지 않았으면 반드시 물어본다 |
| Release | 사용자가 지정한 경우만. 옵션 문자열이 정확해야 하므로 아래 쿼리로 확인한다 |
| Priority | 사용자가 지정한 경우만 |
| Tag | 사용자가 지정한 경우만 |
| OKR | 사용자가 지정한 경우만 |
| 상위 항목 | 소속 Epic이 있으면 그 페이지 URL |

`Release` 옵션 문자열은 최근 실제 사용값에서 확인한다.

```sql
SELECT Release, createdTime
FROM "collection://1d82973c-1a5f-81e6-9728-000b3e3cb467"
WHERE Release IS NOT NULL ORDER BY createdTime DESC LIMIT 15
```

### 6. 생성

`create-pages`에 `parent`를 data source로, `template_id`에 템플릿 페이지 ID를, `properties`에 5단계 결과를 넘긴다. `template_id`를 쓸 때는 `content`를 넘기지 않는다.

이어서 `update-page`의 `replace_content`로 본문을 작성한다. 노션 마크다운 문법이 확실하지 않으면 `notion-fetch`에 `notion://docs/enhanced-markdown-spec`을 넘겨 먼저 읽는다.

### 7. 보고

생성된 카드 URL과 채운 속성을 요약해 알린다.

## 테스트 필요 범위 섹션은 QA가 읽는다

이 섹션의 독자는 코드를 보지 않는 QA다. 사용자가 화면에서 무엇을 해보고 무엇을 확인해야 하는지만 쓴다.

- 쓴다: 어떤 화면에서 어떤 동작을 했을 때 무엇이 보여야 하는지, 어떤 기능에 회귀가 없어야 하는지
- 쓰지 않는다: 테스트 명령어, 테스트 파일 경로, 유닛 테스트 추가 여부, 린트와 빌드 게이트, 패키지 버전 확인 명령
- 검증 도구나 자동 테스트는 개발자의 작업이므로 필요하면 `작업 내역`에 적는다

## 초안 확인이 필요한 때

- **바로 생성** — 사용자가 작업 내역을 직접 불러줬고 형식만 맞춘 경우
- **초안 먼저** — 코드베이스, PR, 설계 문서를 조사해 내용을 만들어낸 경우. 속성과 본문을 채팅에 보여주고 승인을 받은 뒤 생성한다

## 흔한 실수

| 실수 | 결과 |
|---|---|
| 데이터베이스 페이지를 통째로 fetch | 응답이 60KB를 넘어 토큰 한도를 초과하고 파일로 떨어진다. 템플릿 ID를 잃었을 때만 쓰고, 그때도 `<templates>` 블록만 잘라 읽는다 |
| ETA를 비워둠 | 기본 Table 뷰가 ETA 이후만 표시하므로 카드가 뷰에서 사라진다 |
| `template_id` 없이 `icon`으로 생성 | FE 카드 아이콘은 이모지가 아니라 첨부 이미지라 `icon` 파라미터로 재현되지 않는다 |
| 섹션 구조를 기억으로 작성 | 노션에서 템플릿이 바뀌면 틀린 구조가 된다. 매번 템플릿을 읽는다 |
| 회색 안내 문구를 본문에 옮겨 적음 | 안내 문구는 작성자에게 주는 지시이지 카드 내용이 아니다 |
| `Release` 값을 임의로 표기 | 옵션에 없는 문자열은 반영되지 않는다. 최근 사용값에서 정확한 문자열을 확인한다 |
| 링크 텍스트를 `[`로 시작 | `[[QA] 제목](url)` 형태는 마크다운 링크로 파싱되지 않고 대괄호가 그대로 남은 채 URL이 별도 멘션으로 떨어진다. 노션 카드 제목은 `[QA]` 같은 접두어를 자주 쓰므로 자주 밟는다. 링크 텍스트에서는 접두어의 대괄호를 벗겨 `[QA 제목](url)`으로 쓴다 |
