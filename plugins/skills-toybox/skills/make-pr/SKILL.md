---
name: Make PR
description: This skill should be used when the user wants to "make a pr", "create a pr", "create pull request", "open pr", or needs to generate a pull request with title and body from current branch changes.
version: 0.1.0
---

# PR 생성

현재 브랜치의 변경사항을 분석하여 저장소 컨벤션에 맞는 PR을 생성한다.

## PR 형식

**제목:**

```
<type>(<scope>): <subject>
```

커밋 메시지와 동일한 Conventional Commit 형식을 따른다.

**본문:**

```
- 변경사항 1
- 변경사항 2
- 변경사항 3
```

불릿 리스트만 사용한다. 섹션 헤딩(## Summary 등), 부연 설명, 마케팅 언어 없이 사실만 나열한다.

## 프로세스

### Step 1: 변경사항 분석

1. `git log --oneline main..HEAD`로 현재 브랜치의 커밋 목록 확인
2. `git diff main...HEAD`로 전체 변경사항 확인
3. 커밋이 여러 개면 모든 커밋의 변경사항을 종합하여 파악

### Step 2: PR 컨텐츠 작성

1. 변경사항의 핵심 성격에 맞는 type 선택 (feat, fix, refactor, chore, docs 등)
2. scope는 가장 영향받는 플러그인 또는 모듈명
3. subject는 변경의 핵심을 한 줄로 요약
4. 본문은 주요 변경사항을 2~4개 불릿으로 나열

### Step 3: PR 생성

1. 리모트에 현재 브랜치를 push (`git push -u origin <branch>`)
2. `gh pr create`로 PR 생성
3. PR URL을 사용자에게 반환

## 규칙

- 제목은 커밋 컨벤션과 동일하게 작성
- 본문은 불릿 리스트만 사용 (2~4줄)
- 마침표 사용하지 않음
- Co-Authored-By 추가하지 않음
- base 브랜치는 main (별도 지정 없는 한)
- push는 PR 생성에 필요하므로 실행하되, 사용자에게 먼저 알림

## 예외 처리

| 상황 | 대응 |
|------|------|
| main 브랜치에서 실행 | PR 생성 불가 안내, 브랜치 생성 제안 |
| 리모트에 이미 PR 존재 | 기존 PR URL 안내 |
| 변경사항 없음 | main과 차이 없다고 안내 |
| 커밋이 없음 | 먼저 커밋하라고 안내 |
| gh CLI 미설치 | gh 설치 안내 (https://cli.github.com) |
