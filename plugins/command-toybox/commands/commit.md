---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*)
description: Conventional Commit 형식으로 한줄 커밋
---

# Git Commit

## 현재 상태

- git status: !`git status --short`
- staged diff: !`git diff --staged`
- unstaged diff: !`git diff`

## 작업

1. 변경사항이 없으면 "커밋할 내용이 없습니다" 안내 후 종료
2. 변경사항 분석 후 Conventional Commit 형식의 한줄 메시지 생성
3. 변경된 파일 staging 후 `git commit -m "메시지"` 로 커밋

## Conventional Commit 형식

```
<type>(<scope>): <subject>
```

- **type**: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
- **scope**: 변경된 모듈/컴포넌트 (선택)
- **subject**: 50자 이내, 소문자 시작, 현재형 동사, 마침표 없음

## 좋은 커밋 메시지 작성법

1. 하나의 커밋 = 하나의 논리적 변경
2. 커밋만 보고 변경 내용을 이해할 수 있어야 함
3. 코드 변경과 관련 없는 내용 포함 금지
4. 여러 파일 변경시에도 하나의 목적이어야 함
