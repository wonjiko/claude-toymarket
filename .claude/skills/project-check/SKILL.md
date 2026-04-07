---
name: project-check
description: "This skill should be used when the user wants to \"check project health\", \"run checklist\", \"validate project\", \"프로젝트 점검\", \"헬스체크\", \"정합성 검사\", \"체크리스트 돌려줘\", or needs to verify that the toymarket plugin marketplace repository is in a consistent state. Checks marketplace.json registration, CLAUDE.md sync, component frontmatter validity, and lint pass."
version: 0.1.0
---

# Project Check

CHECKLIST.md 기반으로 toymarket 저장소 정합성을 자동 검증한다.

## 검증 항목

### 1. 마켓플레이스 정합성

1. `.claude-plugin/marketplace.json` 읽기
2. 각 플러그인의 `source` 경로에 `.claude-plugin/plugin.json` 존재 확인
3. `plugins/` 하위 디렉토리 중 marketplace.json에 미등록인 것 확인
4. `plugins/` 하위에 plugin.json 없는 빈 디렉토리 확인

### 2. CLAUDE.md 정합성

1. `CLAUDE.md`의 "현재 플러그인" 표에서 플러그인명 추출
2. marketplace.json 목록과 비교하여 누락/불일치 확인
3. 각 플러그인의 "주요 기능" 내용이 실제 컴포넌트(commands/, skills/, agents/)와 일치하는지 확인

### 3. 컴포넌트 유효성

1. 모든 `plugins/*/skills/*/SKILL.md` — name, description, version frontmatter 존재 확인
2. 모든 `plugins/*/agents/*.md` — name, description frontmatter 존재 확인
3. 모든 `plugins/*/commands/*.md` — 파일 비어있지 않은지 확인

### 4. 린트

```bash
./plugins/matryoshka-plugin/scripts/lint-all.sh
```

## 결과 보고 형식

```
## Project Health Check

| 항목 | 결과 |
|------|------|
| 마켓플레이스 정합성 | ✅ or ❌ 상세 |
| CLAUDE.md 정합성 | ✅ or ❌ 상세 |
| 컴포넌트 유효성 | ✅ or ❌ 상세 |
| 린트 | ✅ or ❌ 상세 |
```

실패 항목은 문제와 수정 방법을 안내한다. 수정은 사용자 요청 전까지 하지 않는다.
