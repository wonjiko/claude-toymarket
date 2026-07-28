# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 플러그인 개요

`configs-for-configs`는 로컬에 이미 설치된 특정 도구를 스크립트로 감싸거나 고쳐서 재현 가능한 방식으로 재설정하는 skill 모음.

## 왜 존재하는지

한 번 손으로 맞춘 로컬 도구 설정(예: claudia-statusline에 PR 링크 붙이기)을 다른 머신에서도 같은 절차로 재현하기 위해.

## 언제 쓰면 안 되는지

- 프로젝트 코드 자체를 바꾸는 작업 (이 플러그인은 로컬 도구/설정 대상)
- skill이 다루는 특정 도구가 설치돼 있지 않거나 다른 버전/구현인 경우 — 각 skill의 "언제 쓰면 안 되는지" 참고

## 구조

```
configs-for-configs/
├── .claude-plugin/plugin.json   # 플러그인 메타데이터
└── skills/
    ├── setup-claudia-statusline-with-pr-link/
    │   ├── SKILL.md
    │   └── scripts/statusline-pr-wrapper.sh      # 설치할 wrapper 스크립트 원본
    └── setup-claudia-statusline-with-notion-link/
        ├── SKILL.md
        └── scripts/statusline-notion-wrapper.sh  # 설치할 wrapper 스크립트 원본
```

두 skill 모두 같은 `statusLine.command` 바이너리 경로를 감싼다. 동시에 설치하면 나중 것이 앞선 wrapper를 덮어쓴다 — 각 skill의 "언제 쓰면 안 되는지" 참고.

## 레퍼런스

새 skill 추가 전 확인:
- 공식 플러그인: `~/.claude/plugins/marketplaces/claude-plugins-official/`
- Claude Code 문서: https://docs.anthropic.com/en/docs/claude-code
