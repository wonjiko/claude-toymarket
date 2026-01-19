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

## 현재 플러그인

| 플러그인 | 설명 | 주요 기능 |
|----------|------|-----------|
| command-toybox | 범용 유틸리티 명령어 모음 | /commit, /code-review, /retrospect |
| typical-process | 세션 기반 워크플로우 관리 | /start, /execute, /retrospect, /sync, /sessions |
| matryoshka-plugin | 플러그인/컴포넌트 생성 도구 | /create-command, skill-creator agent |
| mcp-manager | MCP 서버 자동 관리 | 세션 시작 시 MCP 상태 체크 |
| dice | 주사위 굴리기 | /dice |

### 명령어 구분 참고

- **command-toybox**: 단독으로 사용 가능한 범용 명령어. typical-process 세션 없이도 동작
- **typical-process**: 세션(plan/context 파일) 기반 워크플로우. `/start`로 세션 시작 필요
- `/retrospect`가 양쪽에 존재함:
  - `command-toybox/retrospect`: 대화 기반 간단한 회고 (세션 불필요)
  - `typical-process/retrospect`: 세션 파일 기반 상세 회고 (세션 필요)

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
