# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 플러그인 개요

`command-toybox`는 자주 쓰는 slash command 모음집. 유틸리티 성격의 명령어들을 제공한다.

## 구조

```
command-toybox/
├── .claude-plugin/plugin.json   # 플러그인 메타데이터
├── commands/                    # slash command 정의
│   ├── commit.md               # /commit - Conventional Commit 형식 커밋
│   └── retrospect.md           # /retrospect - 세션 회고
└── skills/                      # AI 기반 skill
    └── command-validator/       # command 검증 도구
```

## Command 작성 규칙

### Frontmatter 필수 요소
```yaml
---
allowed-tools: Bash(git status:*), Bash(git diff:*)  # 도구 제한
description: 60자 이내, 동사로 시작
---
```

### Bash 명령어 실행
- 동적 컨텍스트: `!`git status --short`` (백틱 안에 명령어)
- allowed-tools에 명시된 명령어만 사용 가능
- Bash는 반드시 command filter 사용 (예: `Bash(git:*)`)

### 인자 처리
- `$ARGUMENTS` - 전체 인자
- `$1`, `$2` - 개별 인자
- `argument-hint` frontmatter로 힌트 제공

## 레퍼런스

새 command나 skill 추가 전 확인:
- 공식 플러그인: `~/.claude/plugins/marketplaces/claude-plugins-official/`
- Claude Code 문서: https://docs.anthropic.com/en/docs/claude-code
