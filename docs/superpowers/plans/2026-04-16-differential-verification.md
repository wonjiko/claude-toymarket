# Differential Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** subagent-loop Verifier에 Differential Verification 패턴을 적용하여 Round 2+ 검증의 토큰 사용량과 속도를 개선한다.

**Architecture:** 단일 Verifier 프롬프트를 Round 1 (Full Sweep, opus) / Round 2+ (Differential, sonnet)로 분리하고, 오케스트레이션 루프에 pending_full_sweep 분기를 추가한다. Differential에서 10점 시 Executor를 건너뛰고 Full Sweep 졸업 시험을 실행한다.

**Tech Stack:** Markdown (SKILL.md)

---

### Task 1: Verifier 섹션을 Round 1 / Round 2+로 분리

**Files:**
- Modify: `plugins/pick-subagent/skills/subagent-loop/SKILL.md:168-217`

- [ ] **Step 1: Verifier 섹션 헤더에 Round 분리 설명 추가**

`### 4. Verifier (opus)` 아래의 설명을 Round 1/2+ 구분 설명으로 교체한다.

현재 내용 (168-169행):

```markdown
### 4. Verifier (opus)
```

변경 후:

```markdown
### 4. Verifier

**Round 1**과 **Round 2+**에서 프롬프트가 다르다. Round 1은 전체 검증(Full Sweep, opus), Round 2+는 감점 항목만 재검증(Differential, sonnet)하여 토큰을 절약한다.
```

- [ ] **Step 2: 기존 Verifier 프롬프트를 Round 1 (Full Sweep) 서브섹션으로 변환**

기존 단일 프롬프트 블록(170-217행)을 `#### Round 1 — Full Sweep (opus)` 서브섹션으로 감싼다. 프롬프트 내용은 그대로 유지하되, 출력 형식의 검증 결과 헤더에 `(Full Sweep)` 표기를 추가한다.

```markdown
#### Round 1 — Full Sweep (opus)

\```
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
    \```
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
    \```
\```
```

- [ ] **Step 3: Round 2+ Differential Verification 서브섹션 추가**

Round 1 서브섹션 바로 아래에 다음을 추가한다:

```markdown
#### Round 2+ — Differential Verification (sonnet)

\```
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
    \```
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
    \```
\```

완료 후: `verification-{NN}.md`에서 STATUS와 `**총점: X/10**` 파싱.
```

- [ ] **Step 4: lint 실행하여 구조 검증**

Run: `./plugins/matryoshka-plugin/scripts/lint-all.sh`
Expected: subagent-loop 스킬이 PASS

- [ ] **Step 5: 커밋**

```bash
git add plugins/pick-subagent/skills/subagent-loop/SKILL.md
git commit -m "perf(subagent-loop): split verifier into full sweep (opus) and differential (sonnet)"
```

---

### Task 2: 오케스트레이션 루프에 pending_full_sweep 분기 추가

**Files:**
- Modify: `plugins/pick-subagent/skills/subagent-loop/SKILL.md:222-242`

- [ ] **Step 1: 오케스트레이션 루프를 새 로직으로 교체**

현재 내용 (222-242행):

```markdown
## 오케스트레이션 루프

Verification Planner 완료 후, 오케스트레이터는 다음을 반복한다:

\```
N = 1
scores = []

loop:
  1. Executor 디스패치 (round N)
  2. execution-{NN}.md 에서 STATUS 확인
     - BLOCKED → 사용자에게 보고, 중단
  3. Verifier 디스패치 (round N)
  4. verification-{NN}.md 에서 점수 파싱
  5. scores에 점수 추가
  6. 판단:
     - 10점 → 완료 처리로 이동
     - 10점 미만:
       - len(scores) >= 5 이고 max(scores[-5:]) - min(scores[-5:]) <= 1 → 교착
         → 사용자에게 상황 보고 + 판단 요청
       - 그 외 → N++, loop로 복귀
\```
```

변경 후:

```markdown
## 오케스트레이션 루프

Verification Planner 완료 후, 오케스트레이터는 다음을 반복한다:

\```
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
\```
```

- [ ] **Step 2: lint 실행**

Run: `./plugins/matryoshka-plugin/scripts/lint-all.sh`
Expected: PASS

- [ ] **Step 3: 커밋**

```bash
git add plugins/pick-subagent/skills/subagent-loop/SKILL.md
git commit -m "perf(subagent-loop): add pending_full_sweep logic to orchestration loop"
```

---

### Task 3: 버전 범프 및 최종 검증

**Files:**
- Modify: `plugins/pick-subagent/skills/subagent-loop/SKILL.md:1-5`

- [ ] **Step 1: 버전을 0.1.0 → 0.2.0으로 범프**

현재 (3행):
```
version: 0.1.0
```

변경 후:
```
version: 0.2.0
```

- [ ] **Step 2: lint 최종 실행**

Run: `./plugins/matryoshka-plugin/scripts/lint-all.sh`
Expected: 전체 PASS

- [ ] **Step 3: SKILL.md 전체를 읽고 Executor Round 1/2+ 패턴과 Verifier Round 1/2+ 패턴이 대칭인지 확인**

확인 항목:
- Executor Round 1: plan.md 전체 → Verifier Round 1: verification-plan.md + execution 전체 (대칭)
- Executor Round 2+: Delta Prompt만 → Verifier Round 2+: 감점 항목만 (대칭)
- pending_full_sweep 시 Executor 스킵 + Full Sweep Verifier 실행

- [ ] **Step 4: 커밋**

```bash
git add plugins/pick-subagent/skills/subagent-loop/SKILL.md
git commit -m "chore(subagent-loop): bump version to 0.2.0"
```
