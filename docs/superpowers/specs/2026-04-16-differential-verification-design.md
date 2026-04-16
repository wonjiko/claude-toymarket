# Differential Verification for Subagent Loop

## 요약

subagent-loop 스킬의 Verifier 단계에 Differential Verification 패턴을 적용한다. Round 2+ Verifier는 감점 항목만 재검증(sonnet)하고, 전항목 통과 시에만 Full Sweep(opus)으로 졸업 시험을 실행한다.

## 동기

Executor에는 이미 Delta Prompt 패턴(f08e295)이 적용되어 Round 2+에서 plan.md를 다시 읽지 않는다. 그러나 Verifier는 매 라운드마다 verification-plan.md + 변경 파일 전체를 opus로 검증하므로 가장 큰 토큰/속도 병목이다.

## 설계

### Verifier 분리: Round 1 vs Round 2+

#### Round 1 — Full Sweep (opus)

현행과 동일. verification-plan.md + execution-01.md를 읽고 전체 검증.

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

### 오케스트레이션 루프 변경

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
  4. scores에 추가

  5. 판단:
     - 10점:
       if 이번이 Full Sweep → 완료 처리로 이동
       if 이번이 Differential → pending_full_sweep = true, N++, loop
     - 10점 미만:
       - len(scores) >= 5 이고 max(scores[-5:]) - min(scores[-5:]) <= 1 → 교착
         → 사용자에게 상황 보고 + 판단 요청
       - 그 외 → N++, loop
```

핵심 규칙: **Differential에서 10점이 나와도 바로 종료하지 않는다.** 다음 라운드에서 Full Sweep(opus)을 한 번 더 돌려 regression을 확인한 뒤에야 종료.

### 토큰 절약 흐름 예시

3라운드에서 완료되는 시나리오:

| Round | Executor | Verifier | Verifier 모델 | 읽는 파일 |
|-------|----------|----------|---------------|-----------|
| 1 | plan.md 전체 | Full Sweep | opus | verification-plan.md + execution-01.md + 소스 전체 |
| 2 | Delta Prompt만 | Differential | sonnet | verification-01.md + execution-02.md + 감점 관련 소스만 |
| 3 | 건너뜀 (수정 없음) | Full Sweep (졸업) | opus | verification-plan.md + execution-02.md(직전) + 소스 전체 |

Round 2에서 가장 큰 절약: sonnet 모델 + 감점 항목만 + verification-plan.md 미참조.
Round 3에서 추가 절약: Executor 호출 자체를 건너뜀.

### Full Sweep에서 regression 발견 시

졸업 시험(Full Sweep)에서 기존 만점 항목이 깨진 경우, 해당 항목이 새로운 감점 항목이 되어 Differential 루프로 복귀한다. 자연스럽게 기존 흐름을 따르므로 별도 처리가 필요 없다.

## 변경 범위

| 파일 | 변경 내용 |
|------|-----------|
| `plugins/pick-subagent/skills/subagent-loop/SKILL.md` | Verifier 섹션을 Round 1/2+로 분리, 오케스트레이션 루프에 pending_full_sweep 분기 추가 |

단일 파일 수정.

## 변경하지 않는 것

- Planner, Verification Planner 프롬프트
- Executor (Round 1/2+ Delta Prompt 패턴)
- 완료 처리 (squash 커밋)
- 교착 감지 로직
- verification/execution 파일 형식 (Differential의 검증 결과 헤더에 "(Differential)" 표기만 추가)
- 파이프라인 개요의 단계 수 (5단계 유지)
