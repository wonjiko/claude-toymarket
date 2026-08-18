# AGENTS.md

This repository is a Claude Code / Codex / Cursor hybrid plugin marketplace.

## Principles

All work in this repo follows the principles in `PRINCIPLES.md`.

@PRINCIPLES.md

## 규칙

- 과잉 설계 금지
- git push는 명시적 요청 시에만

## Current Source Of Truth

- Shared catalog metadata lives in `catalog/toymarket.json`.
- The migration design lives in `docs/dual-runtime-architecture.md`.
- Codex compatibility work is tracked in `CHECKLIST.codex.md`.

## 구조

```
claude-toymarket/
├── catalog/toymarket.json            # 공용 원본 (source of truth)
├── .claude-plugin/marketplace.json   # 생성된 Claude 플러그인 카탈로그
├── .cursor-plugin/marketplace.json   # 생성된 Cursor 플러그인 카탈로그
├── .agents/plugins/marketplace.json  # 생성된 Codex 플러그인 카탈로그
├── plugins/
│   └── [plugin-name]/                # 플러그인별로 필요한 디렉토리만 포함
│       ├── .claude-plugin/plugin.json  # 생성된 메타데이터 (Claude)
│       ├── .cursor-plugin/plugin.json  # 생성된 메타데이터 (Cursor)
│       ├── .codex-plugin/plugin.json   # 생성된 메타데이터 (Codex)
│       ├── commands/                 # slash commands (*.md, Claude/Cursor)
│       ├── agents/                   # 에이전트 정의 (*.md, Claude/Cursor)
│       ├── skills/                   # AI skills (*/SKILL.md, 공유)
│       └── hooks/                    # Claude hooks.json + 공용 shell scripts
├── templates/                        # 새 플러그인 템플릿
├── AGENTS.md                         # Claude/Codex/Cursor 공용 컨텍스트
├── CLAUDE.md                         # @AGENTS.md import
└── PRINCIPLES.md                     # 작업 결과물 원칙
```

## 현재 플러그인

| 플러그인 | 설명 | 주요 기능 |
|----------|------|-----------|
| skills-toybox | 범용 유틸리티 skill 모음 | commit, code-review, make-pr, retrospect, reflection, command-validator, respond-review |
| matryoshka-plugin | 플러그인/컴포넌트 생성 도구 | skill-creator, agent-creator |
| mcp-manager | MCP 서버 자동 관리 | 세션 시작 시 MCP 상태 체크 |
| ppt-designer | HTML 프레젠테이션 생성 | ppt-designer |
| pick-subagent | 서브에이전트 활용 도구 모음 | /sub-opus, /sub-sonnet, /sub-haiku, /sub-fable, subagent-loop |
| dice | 결정장애를 위한 주사위 | /dice |
| configs-for-configs | 로컬 개발 도구 설정 재구성 | setup-claudia-statusline-with-pr-link, setup-claudia-statusline-with-notion-link |
| meissa-fe-workflow | Meissa 프로덕트팀 업무 skill 모음 | fe-task-card, epic-card, jupiter-engine-versions |

## 개발

### 플러그인 생성

1. `plugins/[name]/` 디렉토리 생성, 실제 컴포넌트(commands/skills/agents/hooks) 작성
2. `catalog/toymarket.json`의 `plugins` 배열에 항목 추가 (name, description, version, author, claude.category, codex.category, codex.status 등)
3. `python3 scripts/verify_repo.py --profile dual --fix` 실행 — `catalog/toymarket.json`으로부터 Claude/Cursor/Codex marketplace와 plugin.json을 생성한다. 이 파일들은 손으로 직접 쓰지 않는다 (## Editing Rules 참고)

### 컴포넌트 생성 (matryoshka-plugin 사용)

skill-creator skill 또는 agent-creator agent가 자동 트리거됨.

## Reference

새 컴포넌트 작성 전 공식 레퍼런스 확인 필수:

| 작업 | 레퍼런스 |
|------|----------|
| 플러그인 구조 | `~/.claude/plugins/marketplaces/claude-plugins-official/` |
| Claude Code 문서 | https://docs.anthropic.com/en/docs/claude-code |

Anthropic 공식 소스만 참고:
- https://docs.anthropic.com/
- https://github.com/anthropics/

## Verification

Run the current Claude structural check:

```bash
python3 scripts/verify_repo.py --profile claude --full
```

Run the dual-runtime gate (Claude + Cursor + Codex):

```bash
python3 scripts/verify_repo.py --profile dual
```

Both commands should pass before changing plugin metadata or generated manifests.

Also run the component lint before considering agent/skill work done:

```bash
./plugins/matryoshka-plugin/scripts/lint-all.sh
```

This checks required frontmatter fields and structure rules for agents and skills.

## Codex Registration

Register this local marketplace with Codex:

```bash
codex plugin marketplace add /Users/pulp/Desktop/Repositories/claude-toymarket
```

Register from GitHub instead:

```bash
codex plugin marketplace add wonjiko/claude-toymarket
```

Git marketplaces can be updated with:

```bash
codex plugin marketplace upgrade claude-toymarket
```

Local path marketplaces are not Git marketplaces, so `upgrade` does not apply to them.

## Editing Rules

- Treat `catalog/toymarket.json` as the source for marketplace and plugin manifest metadata.
- Keep shared behavior in `skills/`, `hooks/*.sh`, `references/`, `assets/`, and scripts.
- Treat `commands/*.md` as Claude adapters. Cursor also reads `commands/` and `agents/`.
- Treat `hooks/hooks.json` as Claude-only. Cursor manifests use empty `hooks` so that file is not auto-discovered.
- Keep generated Claude/Cursor/Codex manifest files in sync with `scripts/verify_repo.py --fix` rather than hand-editing them.
