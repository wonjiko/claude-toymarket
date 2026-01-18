---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*)
description: Conventional Commit 형식으로 한줄 커밋
---

# Conventional Commit (One-liner)

다음 규칙에 따라 컨벤셔널 커밋 메시지를 작성하여 커밋을 생성해주세요:

## 커밋 메시지 형식
```
<type>(<scope>): <subject>
```

**중요: 항상 한 줄로만 작성합니다. body와 footer는 사용하지 않습니다.**

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

## 작업 순서
1. `git status`와 `git diff`로 변경사항 확인
2. `git log --oneline -10`으로 최근 커밋 메시지 스타일 확인
3. 변경사항을 분석하여 적절한 type 선택
4. scope는 변경된 주요 영역 (예: component명, 모듈명)
5. subject는 명령형으로 작성하고 한 줄로 완결
6. **한 줄 형식으로 커밋 생성** (푸시는 하지 않음)

## 주의사항
- subject는 한국어 또는 영어로 작성 (프로젝트 일관성 고려)
- scope는 소문자로 작성
- subject 끝에 마침표 넣지 않기
- 전체 커밋 메시지는 한 줄로만 작성
- Co-Authored-By 등 추가 정보는 넣지 않음
