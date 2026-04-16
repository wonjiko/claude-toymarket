---
name: subagent-loop
description: This skill should be used when the user wants to "서브에이전트 루프", "subagent loop", "검증 루프", "subagent pipeline", "서브에이전트 파이프라인", or needs iterative subagent execution with strict 10-point verification scoring. High token cost — only for tasks requiring rigorous quality assurance through repeated execution and verification cycles.
version: 0.2.0
---

# Subagent Loop

서브에이전트 파이프라인을 통해 작업을 수행하고, 10점 만점 검증 루프로 품질을 보장한다.
토큰을 많이 소모하지만 엄격한 검증을 통해 높은 품질을 확보하는 것이 목적.

## 파이프라인 개요

```
1. [조건부] Planner (opus) → plan.md 작성
2. Verification Planner (opus) → verification-plan.md 작성
3. Executor (sonnet) → 구현 + 커밋 + execution-{N}.md 작성
4. Verifier (opus) → 검증 + verification-{N}.md 작성
5. 10점 → squash 커밋 → 완료
   10점 미만 → 교착 감지 확인 → 3번으로 복귀
```

## 시작 절차

1. 사용자에게 topic 이름을 확인받는다 (영문 kebab-case, 예: "add-auth", "fix-parser")
2. `docs/subagent-loop/{topic}/` 디렉토리를 생성한다
3. 플랜 존재 여부를 확인한다:
   - 플랜이 있으면: 사용자가 알려준 경로의 파일을 `docs/subagent-loop/{topic}/plan.md`로 복사 → Verification Planner부터 시작
   - 플랜이 없으면: Planner부터 시작

## 서브에이전트 디스패치

### 1. Planner (opus) — 조건부

플랜이 없을 때만 실행.

```
Agent 도구:
  model: opus
  description: "Create implementation plan for {topic}"
  prompt: |
    아래 사용자 요청에 대한 구현 플랜을 작성하라.
    프로젝트를 탐색하고, 실행 가능한 단계별 플랜을 만들어라.

    ## 사용자 요청
    {사용자가 요청한 내용}

    ## 출력
    결과를 다음 파일에 작성하라: docs/subagent-loop/{topic}/plan.md

    파일 첫 줄은 반드시 `STATUS: DONE` 또는 `STATUS: BLOCKED`로 시작한다.
    BLOCKED인 경우 사유를 작성한다.
```

완료 후: `plan.md` 첫 줄에서 STATUS 확인. BLOCKED이면 사용자에게 보고.

### 2. Verification Planner (opus)

```
Agent 도구:
  model: opus
  description: "Create verification plan for {topic}"
  prompt: |
    다음 플랜 파일을 읽고, 10점 만점의 검증 계획을 작성하라.

    ## 플랜 파일
    docs/subagent-loop/{topic}/plan.md

    ## 지침
    - 플랜의 작업 유형에 맞는 채점 항목을 직접 설계하라
      - 코드 작업: 기능 완성도, 테스트 커버리지, 코드 품질, 스펙 정합성 등
      - 문서 작업: 정확성, 완성도, 일관성 등
      - 기타: 작업 유형에 적합한 항목
    - 각 항목의 배점과 채점 기준을 구체적으로 명시하라
    - 총합이 10점이 되도록 하라
    - 실행 가능한 검증 방법이 있으면 포함하라 (테스트 명령어, lint 등)

    ## 출력
    결과를 다음 파일에 작성하라: docs/subagent-loop/{topic}/verification-plan.md

    파일 첫 줄은 반드시 `STATUS: DONE` 또는 `STATUS: BLOCKED`로 시작한다.
```

완료 후: `verification-plan.md` 첫 줄에서 STATUS 확인.

### 3. Executor (sonnet)

**Round 1**과 **Round 2+**에서 프롬프트가 다르다. Round 2부터는 plan.md 대신 직전 검증의 Delta Prompt만 읽어 토큰을 절약한다.

#### Round 1 (최초 실행)

```
Agent 도구:
  model: sonnet
  description: "Execute plan for {topic} (round 1)"
  prompt: |
    플랜을 읽고 구현하라.

    ## 플랜 파일
    docs/subagent-loop/{topic}/plan.md

    ## 지침
    - 플랜의 모든 항목을 구현하라
    - 구현 완료 후 커밋하라
    - 작업 불가능한 상황이면 BLOCKED로 보고하라

    ## 출력
    결과를 다음 파일에 작성하라: docs/subagent-loop/{topic}/execution-{NN}.md
    (NN은 2자리 패딩: 01, 02, ...)

    파일 형식:
    ```
    STATUS: DONE (또는 BLOCKED)

    ## 변경 파일
    - path/to/file1 — 설명
    - path/to/file2 — 설명

    ## 수행 내용 요약
    (무엇을 했는지 간결하게)

    ## 커밋
    (커밋 해시와 메시지)
    ```
```

#### Round 2+ (재실행)

```
Agent 도구:
  model: sonnet
  description: "Execute plan for {topic} (round {N})"
  prompt: |
    직전 검증에서 감점된 부분을 수정하라.

    ## Delta Prompt (수정 지시)
    docs/subagent-loop/{topic}/verification-{N-1}.md 파일의 `## Delta Prompt` 섹션을 읽어라.
    이 섹션에 다음 라운드에서 수정해야 할 내용이 파일 경로와 함께 구체적으로 기술되어 있다.
    Delta Prompt의 지시만 수행하라. plan.md를 다시 읽을 필요 없다.

    ## 지침
    - Delta Prompt의 지시 사항을 모두 수행하라
    - 수정 완료 후 커밋하라
    - 작업 불가능한 상황이면 BLOCKED로 보고하라

    ## 출력
    결과를 다음 파일에 작성하라: docs/subagent-loop/{topic}/execution-{NN}.md
    (NN은 2자리 패딩: 01, 02, ...)

    파일 형식:
    ```
    STATUS: DONE (또는 BLOCKED)

    ## 변경 파일
    - path/to/file1 — 설명
    - path/to/file2 — 설명

    ## 수행 내용 요약
    (무엇을 했는지 간결하게)

    ## 커밋
    (커밋 해시와 메시지)
    ```
```

완료 후: `execution-{NN}.md` 첫 줄에서 STATUS 확인.

### 4. Verifier

Round 1은 전체 검증(opus), Round 2+는 직전 감점 항목만 재검증(sonnet).

#### Round 1 — Full Sweep (opus)

```
Agent 도구:
  model: opus
  description: "Verify execution for {topic} (round {N}, full sweep)"
  prompt: |
    검증 계획에 따라 구현 결과를 검증하라.

    ## 검증 계획
    docs/subagent-loop/{topic}/verification-plan.md

    ## 실행 결과
    docs/subagent-loop/{topic}/execution-{NN}.md

    ## 지침
    - 검증 계획을 읽고 채점 항목을 확인하라
    - 실행 결과를 읽고 변경된 파일을 직접 확인하라
    - 실행 가능한 검증(테스트, lint 등)이 검증 계획에 있으면 직접 실행하라
    - 각 항목별로 채점하고 감점 사유를 구체적으로 기록하라
    - 개선 필요 사항은 다음 Executor가 읽고 바로 행동할 수 있는 수준으로 작성하라
    - 검증 계획의 기준을 엄격하게 적용하라. 관대하게 채점하지 마라.

    ## 출력
    결과를 다음 파일에 작성하라: docs/subagent-loop/{topic}/verification-{NN}.md

    파일 형식:
    ```
    STATUS: DONE

    ## 검증 결과: Round N (Full Sweep)

    **총점: X/10**

    | 항목 | 점수 | 감점 사유 |
    |------|------|-----------|
    | 항목명 | N/M | 구체적 사유 또는 "-" |

    ## 개선 필요 사항
    - (10점이면 "없음", 미만이면 구체적이고 실행 가능한 피드백)

    ## Delta Prompt
    (10점이면 이 섹션 생략)
    다음 Executor가 plan.md 없이 바로 작업할 수 있는 자기완결적 수정 지시문.
    각 지시는 대상 파일 경로와 구체적 변경 내용을 명령형으로 작성한다.
    예:
    - `plugins/foo/bar.md` — 3번째 항목의 description을 "X"에서 "Y"로 수정
    - `src/utils.ts` — validateInput 함수에 null 체크 추가
    ```
```

#### Round 2+ — Differential Verification (sonnet)

```
Agent 도구:
  model: sonnet
  description: "Verify execution for {topic} (round {N}, differential)"
  prompt: |
    직전 검증에서 감점된 항목만 재검증하라.

    ## 직전 검증 결과
    docs/subagent-loop/{topic}/verification-{N-1}.md

    ## 이번 실행 결과
    docs/subagent-loop/{topic}/execution-{NN}.md

    ## 지침
    - 직전 검증에서 감점된 항목만 재검증하라
    - 만점이었던 항목은 직전 점수를 그대로 유지하라 (재검증하지 않음)
    - 감점 항목에 대해: execution-{NN}.md의 변경 파일만 확인하라
    - 실행 가능한 검증이 있으면 해당 항목에 한해서만 실행하라
    - verification-plan.md를 다시 읽을 필요 없다 — 직전 verification에 채점 기준이 이미 있다

    ## 출력
    결과를 다음 파일에 작성하라: docs/subagent-loop/{topic}/verification-{NN}.md

    파일 형식:
    ```
    STATUS: DONE

    ## 검증 결과: Round N (Differential)

    **총점: X/10**

    | 항목 | 점수 | 감점 사유 |
    |------|------|-----------|
    | 항목명 | N/M | 구체적 사유 또는 "-" |
    | (만점 유지) 항목명 | M/M | 직전 라운드 점수 유지 |

    ## 개선 필요 사항
    - (10점이면 "없음", 미만이면 구체적이고 실행 가능한 피드백)

    ## Delta Prompt
    (10점이면 이 섹션 생략)
    다음 Executor가 plan.md 없이 바로 작업할 수 있는 자기완결적 수정 지시문.
    각 지시는 대상 파일 경로와 구체적 변경 내용을 명령형으로 작성한다.
    ```
```

완료 후: `verification-{NN}.md`에서 STATUS와 `**총점: X/10**` 파싱.

## 오케스트레이션 루프

Verification Planner 완료 후, 오케스트레이터는 다음을 반복한다:

```
N = 1
scores = []
pending_full_sweep = false

loop:
  1. if pending_full_sweep:
       Executor 건너뜀 (수정할 내용 없음)
     else:
       Executor 디스패치 (round N)
       execution-{NN}.md에서 STATUS 확인
         - BLOCKED → 사용자에게 보고, 중단

  2. Verifier 디스패치:
     if N == 1 또는 pending_full_sweep:
       Full Sweep Verifier (opus)
       — pending_full_sweep인 경우 직전 execution 파일을 참조
       pending_full_sweep = false
     else:
       Differential Verifier (sonnet, 감점 항목만)

  3. verification-{NN}.md에서 점수 파싱
  4. scores에 점수 추가

  5. 판단:
     - 10점:
       if 이번이 Full Sweep → 완료 처리로 이동
       if 이번이 Differential → pending_full_sweep = true, N++, loop
     - 10점 미만:
       - len(scores) >= 5 이고 max(scores[-5:]) - min(scores[-5:]) <= 1 → 교착
         → 사용자에게 상황 보고 + 판단 요청
       - 그 외 → N++, loop
```

## 완료 처리

10점 달성 시:

1. 라운드 커밋들을 squash하여 단일 커밋으로 만든다
2. 사용자에게 완료 보고한다
3. `docs/subagent-loop/{topic}/` 파일들은 그대로 남긴다 (히스토리 추적용)

## 교착 시 보고 형식

```
## 교착 상태 감지

직전 5회 점수: [X, X, X, X, X]
최고점: X, 최저점: X (차이: N)

현재 상태를 확인하시고 다음 중 하나를 선택해주세요:
1. 계속 진행 (추가 라운드 실행)
2. 플랜 수정 후 재시도
3. 현재 상태로 완료 처리
4. 중단
```
