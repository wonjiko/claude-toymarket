---
name: project-check
description: "This skill should be used when the user wants to \"check project health\", \"run checklist\", \"validate project\", \"프로젝트 점검\", \"헬스체크\", \"정합성 검사\", \"체크리스트 돌려줘\", or needs to verify that the toymarket plugin marketplace repository is in a consistent state. Checks marketplace.json registration, AGENTS.md sync, component frontmatter validity, and lint pass."
version: 0.2.0
---

# Project Check

CHECKLIST.md 기반으로 toymarket 저장소 정합성을 자동 검증한다.

## 검증 항목

### 1. 마켓플레이스 정합성

1. `.claude-plugin/marketplace.json` 읽기
2. 각 플러그인의 `source` 경로에 `.claude-plugin/plugin.json` 존재 확인
3. `plugins/` 하위 디렉토리 중 marketplace.json에 미등록인 것 확인
4. `plugins/` 하위에 plugin.json 없는 빈 디렉토리 확인

### 2. AGENTS.md 정합성

1. `AGENTS.md`의 "현재 플러그인" 표에서 플러그인명 추출
2. marketplace.json 목록과 비교하여 누락/불일치 확인
3. 각 플러그인의 "주요 기능" 내용이 실제 컴포넌트(commands/, skills/, agents/)와 일치하는지 확인

### 3. 컴포넌트 유효성

```bash
python3 scripts/verify_repo.py --profile dual
```

skill, agent, command의 frontmatter를 검사한다. YAML 파싱 여부, name과 description 존재, kebab-case, 빈 command 파일이 대상이다.

frontmatter를 눈으로 읽어 판정하지 않는다. 필드 이름이 다 보여도 YAML 파싱은 실패할 수 있고, 그 파일은 런타임에 로드되지 않는다. 스크립트 결과만 근거로 쓴다.

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
| AGENTS.md 정합성 | ✅ or ❌ 상세 |
| 컴포넌트 유효성 | ✅ or ❌ 상세 |
| 린트 | ✅ or ❌ 상세 |
```

실패 항목은 문제와 수정 방법을 안내한다. 수정은 사용자 요청 전까지 하지 않는다.
