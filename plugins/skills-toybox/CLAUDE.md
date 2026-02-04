# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 플러그인 개요

`skills-toybox`는 자주 쓰는 유틸리티 skill 모음집. 커밋, 코드 리뷰, 회고 등의 기능을 제공한다.

## 구조

```
skills-toybox/
├── .claude-plugin/plugin.json   # 플러그인 메타데이터
└── skills/                      # AI 기반 skill
    ├── commit/                  # Conventional Commit 커밋 생성
    ├── code-review/             # 로컬 코드 품질 검증
    ├── retrospect/              # 세션 회고
    ├── reflection/              # Claude instructions 분석/개선
    └── command-validator/       # command 검증 도구
```

## 레퍼런스

새 skill 추가 전 확인:
- 공식 플러그인: `~/.claude/plugins/marketplaces/claude-plugins-official/`
- Claude Code 문서: https://docs.anthropic.com/en/docs/claude-code
