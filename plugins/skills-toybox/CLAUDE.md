# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 플러그인 개요

`skills-toybox`는 범용 유틸리티 skill 모음. 커밋, 코드 리뷰, 회고 등의 기능을 제공한다.

## 왜 존재하는지

반복적으로 사용하는 개발 워크플로우(커밋, 코드 리뷰, PR 생성, 회고)를 skill로 정리해서 일관된 품질로 실행하기 위해.

## 언제 쓰면 안 되는지

- 프로젝트별 특화 워크플로우가 필요한 경우 (이 플러그인은 범용 목적)
- CI/CD 파이프라인을 대체하려는 경우 (로컬 검증 도구일 뿐)

## 구조

```
skills-toybox/
├── .claude-plugin/plugin.json   # 플러그인 메타데이터
└── skills/                      # AI 기반 skill
    ├── commit/                  # Conventional Commit 커밋 생성
    ├── code-review/             # 로컬 코드 품질 검증
    ├── make-pr/                 # 범용 PR 생성
    ├── make-pr-fe/              # 프론트엔드 PR 생성 (release/* 타겟, 템플릿 준수, 검증 하네스)
    ├── retrospect/              # 세션 회고
    ├── reflection/              # Claude instructions 분석/개선
    └── command-validator/       # command 검증 도구
```

## 레퍼런스

새 skill 추가 전 확인:
- 공식 플러그인: `~/.claude/plugins/marketplaces/claude-plugins-official/`
- Claude Code 문서: https://docs.anthropic.com/en/docs/claude-code
