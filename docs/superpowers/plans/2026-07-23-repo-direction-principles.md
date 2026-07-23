# Repo Direction Principles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 레포 루트에 `PRINCIPLES.md`를 만들어, 이 저장소에서 만드는 모든 결과물이 지켜야 할 다섯 가지 원칙을 담는다.

**Architecture:** 단일 마크다운 파일. 코드 변경 없음, 다른 파일 수정 없음.

**Tech Stack:** Markdown, bash(grep), Python(`scripts/verify_repo.py`, 회귀 확인용).

## Global Constraints

- 원칙 문장은 스펙(`docs/superpowers/specs/2026-07-23-repo-direction-principles-design.md`)에 확정된 5개를 토씨 하나 바꾸지 않고 그대로 쓴다.
- 문서 안 어떤 문장도 특정 스킬 이름, 파일 이름, 플러그인 이름 같은 고유명사를 포함하지 않는다.
- `README.md`, `CLAUDE.md`, `AGENTS.md`는 수정하지 않는다. 이번 계획의 범위 밖이다.
- 파일 위치는 레포 루트의 `PRINCIPLES.md` 하나뿐이다.
- 커밋은 `skills-toybox:commit` 스킬을 사용해 생성한다. Conventional Commit 한 줄 형식, body/footer 없음, `Co-Authored-By` 없음.

---

### Task 1: PRINCIPLES.md 생성

**Files:**
- Create: `PRINCIPLES.md` (레포 루트, `/Users/pulp/Desktop/Repositories/claude-toymarket/PRINCIPLES.md`)

**Interfaces:**
- Consumes: 없음 (첫 작업, 이전 태스크 없음)
- Produces: `PRINCIPLES.md` 파일 자체. 이후 어떤 다른 파일도 이 파일을 참조하지 않는다 (README/CLAUDE.md/AGENTS.md 연결은 별도 작업).

- [ ] **Step 1: PRINCIPLES.md 작성**

다음 내용 그대로 `/Users/pulp/Desktop/Repositories/claude-toymarket/PRINCIPLES.md`에 작성한다.

```markdown
# PRINCIPLES

이 저장소에서 만드는 모든 결과물이 일관되게 따라야 할 기준.

1. 되돌리기 어렵거나 외부에 흔적을 남기는 작업에는 검증 단계나 사용자 확인을 넣고, 한 줄 찍고 끝나는 작업에는 넣지 마세요. 되돌릴 수 없는 실수는 결국 사람이 직접 치워야 하니까요.
2. 모든 컴포넌트는 왜 존재하는지와 언제 쓰면 안 되는지를 스스로 말하게 하세요. 그래야 나중에 이 도구를 지금 써도 되는지 바로 판단할 수 있습니다.
3. 담백하고 직접적으로 쓰세요. 마케팅 언어나 과장된 수사는 쓰지 말고, 결론을 먼저 쓰고 설명은 뒤에 붙이세요. 같은 말이면 짧은 쪽을 고르세요. 읽는 사람이 이해하는 데 시간이 오래 걸릴수록 실제로 읽힐 확률은 줄어듭니다.
4. 기계적으로 검증되는 내용은 문서에 반복하지 마세요. 코드와 문서가 같은 사실을 따로 들고 있으면 둘 중 하나가 먼저 낡습니다.
5. 하나의 단위가 서로 무관한 여러 관심사를 담기 시작하면 쪼개세요. 관심사가 섞이면 하나를 고치다가 다른 하나를 깨뜨리기 쉬워집니다.
```

- [ ] **Step 2: 독립성 제약 검증 — 고유명사가 섞이지 않았는지 확인**

Run:
```bash
cd /Users/pulp/Desktop/Repositories/claude-toymarket
for name in dice matryoshka-plugin mcp-manager pick-subagent ppt-designer skills-toybox \
            skill-creator agent-creator subagent-loop make-pr make-pr-fe respond-review \
            retrospect reflection command-validator commit code-review project-check \
            verify_repo lint-all roll.py catalog toymarket CHECKLIST; do
  grep -in "$name" PRINCIPLES.md && echo "FOUND: $name"
done
echo "check done"
```

Expected: `FOUND:` 로 시작하는 줄이 하나도 없이 `check done`만 출력된다. 하나라도 걸리면 Step 1로 돌아가 해당 표현을 역할/행위 서술로 바꾼다.

- [ ] **Step 3: 기존 검증 스크립트 회귀 확인**

Run:
```bash
cd /Users/pulp/Desktop/Repositories/claude-toymarket
python3 scripts/verify_repo.py --profile claude --full
```

Expected: 기존과 동일하게 통과. 이 스크립트는 `catalog/toymarket.json` 기반 마켓플레이스/플러그인 정합성만 검사하므로 루트에 `PRINCIPLES.md`를 추가한 것과는 무관하다 — 통과하면 이번 변경이 다른 걸 건드리지 않았다는 확인이다.

- [ ] **Step 4: 커밋**

`skills-toybox:commit` 스킬을 사용해 커밋한다. 스테이징 대상은 `PRINCIPLES.md` 하나뿐이다. 커밋 메시지 예: `docs: add repo-wide principles document`.

---

## 다음 단계 (이번 계획 범위 밖)

스펙에 남겨둔 나머지 두 항목은 이 계획에 포함하지 않는다.

- `CLAUDE.md`, `AGENTS.md`에서 `PRINCIPLES.md`를 참조하도록 연결할지 여부와 방법
- `README.md`, `CLAUDE.md`의 기존 "원칙"/"규칙" 섹션을 `PRINCIPLES.md`로 대체하거나 축소할지 여부

필요하다고 판단되면 별도 브레인스토밍으로 다룬다.
