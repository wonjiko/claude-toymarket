# Toymarket Health Checklist

## 1. 마켓플레이스 정합성

- [ ] `marketplace.json`의 모든 플러그인 → `plugins/[name]/.claude-plugin/plugin.json`과 `plugins/[name]/.cursor-plugin/plugin.json` 존재
- [ ] `plugins/` 하위 모든 디렉토리 → `marketplace.json`에 등록됨
- [ ] `plugins/` 하위에 빈 디렉토리(plugin.json 없는) 없음

## 2. AGENTS.md 정합성

- [ ] "현재 플러그인" 표 ↔ `marketplace.json` 목록 일치
- [ ] 각 플러그인 설명의 주요 기능 ↔ 실제 컴포넌트(commands/skills/agents) 일치

## 3. 컴포넌트 유효성

`skills/*/SKILL.md`, `agents/*.md`, `commands/*.md`의 frontmatter를 검사한다.

```bash
python3 scripts/verify_repo.py --profile dual
```

- [ ] 에러 없이 통과

## 4. 린트

```bash
./plugins/matryoshka-plugin/scripts/lint-all.sh
```

- [ ] 에러 없이 통과
