---
name: Commit
description: This skill should be used when the user wants to "commit", "make a commit", "save changes", "git commit", "커밋", "커밋 해줘", "변경사항 저장", or needs to create a git commit following Conventional Commit format. Also triggers when the user asks to commit after finishing implementation work (e.g., "done, commit this", "작업 끝났어 커밋해줘"). Automatically analyzes staged/unstaged changes and generates a one-line conventional commit message.
version: 0.1.0
---

# Conventional Commit (One-liner)

변경사항을 분석하고 Conventional Commit 형식의 한 줄 커밋 메시지를 작성하여 커밋한다.

## 커밋 메시지 형식

```
<type>(<scope>): <subject>
```

**항상 한 줄로만 작성한다. body와 footer는 사용하지 않는다.**

## Type 종류

- **feat**: 새로운 기능 추가
- **fix**: 버그 수정
- **docs**: 문서만 변경
- **style**: 코드 의미에 영향을 주지 않는 변경 (공백, 포맷팅, 세미콜론 등)
- **refactor**: 버그 수정이나 기능 추가가 아닌 코드 변경
- **perf**: 성능 개선
- **test**: 테스트 추가 또는 수정
- **chore**: 빌드 프로세스, 도구, 라이브러리 등의 변경
- **ci**: CI 설정 파일 및 스크립트 변경
- **build**: 빌드 시스템 또는 외부 종속성에 영향을 미치는 변경

## 프로세스

### Step 1: 변경사항 파악

1. `git status`로 변경된 파일 목록 확인
2. `git diff`로 unstaged 변경사항 확인
3. `git diff --cached`로 staged 변경사항 확인

### Step 2: 컨텍스트 수집

1. `git log --oneline -10`으로 최근 커밋 스타일 확인
2. 변경사항의 성격 분석 (신규 기능, 버그 수정, 리팩토링 등)

### Step 3: 커밋 메시지 작성

1. 변경사항에 맞는 type 선택
2. scope는 변경된 주요 영역 (예: component명, 모듈명)
3. subject는 명령형으로 작성

### Step 4: 커밋 실행

1. 필요 시 `git add`로 파일 스테이징
2. 한 줄 형식으로 `git commit` 실행
3. push는 하지 않음

## 규칙

- subject는 한국어 또는 영어로 작성 (프로젝트 일관성 고려)
- scope는 소문자로 작성
- subject 끝에 마침표 넣지 않기
- 전체 커밋 메시지는 한 줄로만 작성
- Co-Authored-By 등 추가 정보는 넣지 않음

## 예외 처리

| 상황 | 대응 |
|------|------|
| 변경사항 없음 | 커밋할 내용이 없다고 안내 |
| staged와 unstaged 혼재 | 어떤 파일을 포함할지 사용자에게 확인 |
| 너무 다양한 변경 | 커밋 분리를 제안 |
