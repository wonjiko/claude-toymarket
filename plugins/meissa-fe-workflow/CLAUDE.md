# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 플러그인 개요

`meissa-fe-workflow`는 Meissa 프로덕트팀의 노션 업무 카드를 만드는 skill 모음이다. 대상 데이터베이스는 `Meissa 자료실 › 프로덕트팀 › Task Tracker › ProductTeam Card Table` 하나다.

## 왜 존재하는지

업무 카드는 매번 같은 골격과 같은 문체로 써야 팀이 읽을 수 있는데, 손으로 쓰면 섹션이 빠지거나 문체가 흔들린다. 두 skill은 노션에서 템플릿 구조를 읽고 요청자의 과거 카드에서 문체를 관찰해 그대로 맞춘다.

**설계 원칙: 섹션 골격과 문체를 skill에 적어두지 않는다.** 노션에서 템플릿이 바뀌면 skill이 따라가야 하므로, SKILL.md에는 어디서 무엇을 읽어올지만 적는다. 고정한 것은 data source URL과 템플릿 페이지 ID뿐이다.

## 언제 쓰면 안 되는지

- Meissa 워크스페이스가 아닌 다른 노션 워크스페이스 (data source ID가 하드코딩되어 있다)
- QA 버그 리포트, 기술부채 등록처럼 별도 데이터베이스와 템플릿을 쓰는 항목
- Notion MCP 서버가 연결되지 않은 환경

## 구조

```
meissa-fe-workflow/
├── .claude-plugin/plugin.json   # 생성된 메타데이터
└── skills/
    ├── fe-task-card/            # FE 단일 업무 카드
    └── epic-card/               # 여러 파트에 걸친 상위 업무 카드
```

## 공통 동작

두 skill 모두 같은 흐름을 따른다.

1. `notion-fetch`에 `self`를 넘겨 요청자 ID를 얻는다
2. 템플릿 페이지를 fetch해 현재 섹션 구조를 읽는다
3. 요청자의 최근 같은 종류 카드에서 문체를 관찰한다
4. 주제 키워드로 유사 카드를 찾아 내용을 참고한다
5. `create-pages`에 `template_id`를 넘겨 만들고 `update-page`의 `replace_content`로 본문을 채운다

## 알아둘 제약

- 데이터베이스 페이지 전체 fetch는 60KB를 넘어 토큰 한도를 초과한다. 템플릿 ID를 잃었을 때의 fallback 경로에서만 쓴다
- `Where`, `Release`, `Tag`, `OKR` 옵션은 자주 바뀌므로 SQL로 최근 실제 사용값을 확인한다
- 노션 title과 본문은 inline markdown으로 처리된다. 링크 텍스트가 `[`로 시작하면 링크가 깨진다

## 레퍼런스

새 skill 추가 전 확인:
- 공식 플러그인: `~/.claude/plugins/marketplaces/claude-plugins-official/`
- Claude Code 문서: https://docs.anthropic.com/en/docs/claude-code
