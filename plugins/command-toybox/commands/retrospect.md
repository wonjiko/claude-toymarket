---
allowed-tools: Bash(git log:*)
description: 세션 회고 - Claude와의 작업을 분석하고 효율적인 협업 방법 제안
---

# 세션 회고 (Retrospect)

## Task

1. Use Bash to get recent git commits: `git log --oneline -10 --pretty=format:'- %h %s (%ar)'`
2. Generate retrospective based on the template below

## Retrospective Template

위 커밋 내역(있는 경우)과 지금까지의 대화를 돌아보고 다음 형식으로 회고를 작성해:

### 1. 완료한 작업 요약
- 이번 세션에서 완료한 주요 작업들

### 2. 잘된 점
- 효율적으로 진행된 부분
- 좋은 요청 방식이나 패턴

### 3. 개선 제안

#### 요청 방식 개선
- 더 명확하게 요청할 수 있었던 부분
- 컨텍스트를 더 잘 제공하는 방법

#### Claude 활용 팁
- 이 작업에 더 적합했을 도구나 접근 방식
- 병렬 작업, 에이전트 활용 등 효율성 개선 방법

#### 워크플로우 제안
- 비슷한 작업을 더 빠르게 처리하는 방법
- 자동화할 수 있는 패턴

### 4. 자동화 제안

#### 기존 프롬프트 개선
- 이번 세션에서 사용된 command/skill 중 개선이 필요한 부분
- 프롬프트 문구, 단계, 도구 권한 등 구체적인 수정 제안

#### 새 command/skill 아이디어
- 반복된 패턴을 자동화할 수 있는 새로운 command
- 기존 command들을 조합한 워크플로우 자동화

### 5. 다음 단계
- 남은 작업이나 후속 조치
- 우선순위 제안
