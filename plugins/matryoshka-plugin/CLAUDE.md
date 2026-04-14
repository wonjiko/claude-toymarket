# matryoshka-plugin

플러그인 컴포넌트(skill, agent)를 생성하는 플러그인.

## 왜 존재하는지

skill이나 agent를 새로 만들 때마다 디렉토리 구조, frontmatter, 파일 네이밍 규칙을 기억하기 번거롭다. 이 플러그인이 규칙에 맞는 boilerplate를 자동 생성한다.

## 언제 쓰면 안 되는지

- 기존 skill/agent를 수정할 때 (생성 전용)
- 플러그인 자체(.claude-plugin/plugin.json)를 만들 때는 수동으로 해야 함
- command는 구조가 단순하므로 직접 작성하는 게 빠름

## 구성

- `skills/skill-creator/` - skill 생성기
- `agents/agent-creator.md` - agent 생성기
- `scripts/` - lint 스크립트 (lint-all.sh, lint-agent.sh, lint-skill.sh)
