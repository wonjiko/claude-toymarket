# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 개요

Claude Code 플러그인 모음 저장소. 각 플러그인은 commands, agents, skills, hooks 조합으로 구성.

## 구조

```
plugins/
├── [plugin-name]/
│   ├── .claude-plugin/plugin.json  # 메타데이터 (필수)
│   ├── commands/                   # slash commands (*.md)
│   ├── agents/                     # 에이전트 정의 (*.md)
│   ├── skills/                     # AI skills (*/SKILL.md)
│   └── hooks/                      # hooks.json + shell scripts
.claude-plugin/marketplace.json     # 플러그인 카탈로그
```

## 개발

### 플러그인 생성
1. `plugins/[name]/` 디렉토리 생성
2. `.claude-plugin/plugin.json` 작성 (templates/plugin.json 참고)
3. `.claude-plugin/marketplace.json`에 등록

### 컴포넌트 생성 (matryoshka-plugin 사용)
```
/matryoshka-plugin:create-command <name> [description]
```

### Lint
```bash
./plugins/matryoshka-plugin/scripts/lint-all.sh
```

## 레퍼런스

새 컴포넌트 작성 전 공식 레퍼런스 확인 필수:

| 작업 | 레퍼런스 |
|------|----------|
| 플러그인 구조 | `~/.claude/plugins/marketplaces/claude-plugins-official/` |
| Claude Code 문서 | https://docs.anthropic.com/en/docs/claude-code |

Anthropic 공식 소스만 참고:
- https://docs.anthropic.com/
- https://github.com/anthropics/

## 규칙

- 마케팅 언어 금지
- 각 플러그인에 "왜 존재하는지"와 "언제 쓰면 안 되는지" 명시
- 과잉 설계 금지
- git push는 명시적 요청 시에만
