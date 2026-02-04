---
name: Retrospect
description: This skill should be used when the user wants to "retrospect", "review session", "look back", or needs to analyze the current session and suggest more efficient collaboration methods.
version: 0.1.0
---

# 세션 회고 (Retrospect)

## 프로세스

### Step 1: 컨텍스트 수집

1. `git log --oneline -10 --pretty=format:'- %h %s (%ar)'`로 최근 커밋 확인
2. 지금까지의 대화 내용 분석

### Step 2: 회고 작성

아래 템플릿에 따라 회고를 작성한다.

## 회고 템플릿

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

#### 재작업 시 빠른 달성 방법
다음에 비슷한 작업을 할 때 더 빠르게 목적을 달성하는 구체적인 방법:
- 초기 요청 시 포함하면 좋을 정보 (파일 경로, 기술 스택, 제약 조건 등)
- 건너뛸 수 있는 탐색/확인 단계
- 미리 준비해두면 좋을 것들 (예: 관련 파일 열어두기, 요구사항 정리)
- 한 번에 요청할 수 있는 복합 지시 예시

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
