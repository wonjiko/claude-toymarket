---
name: setup-claudia-statusline-with-notion-link
description: This skill should be used when the user wants their Claude Code statusline to show the most recently referenced Notion page from the current session — "스테이터스라인에 노션 링크", "세션에서 본 노션 문서 표시", "claudia-statusline notion 연동" — while running claudia-statusline (the Rust `statusline` binary, `statusLine.command` in `~/.claude/settings.json`). Installs a shared orchestrator (if not already present) plus a togglable "notion-link" segment that scans the session transcript for the last Notion MCP fetch/search result and appends its title as a clickable OSC 8 hyperlink, computed asynchronously with caching so the statusline never blocks.
version: 0.2.0
---

# claudia-statusline에 Notion 링크 추가

이 세션에서 마지막으로 조회한 Notion 페이지를 클릭 가능한 링크로 statusline에 보여준다. `setup-claudia-statusline-with-pr-link`와 오케스트레이터+segment 구조를 공유한다 — 오케스트레이터는 원본 바이너리를 실행한 뒤 `<command>-segments/` 안의 실행 가능한 `*.sh`를 전부 돌려서 출력을 덧붙인다. 소스만 git/GitHub가 아니라 세션 transcript라는 점이 다르다.

## 언제 쓰면 안 되는지

- `~/.claude/settings.json`의 `statusLine.command`가 claudia-statusline이 아닌 경우
- Notion MCP(`mcp__..._notion__notion-fetch` / `notion-search`)를 세션에서 쓰지 않는 경우 — 조회할 기록 자체가 없다
- macOS가 아닌 환경 (`stat -f`, `shasum` 등 BSD 전용 명령 사용)

## 사전 확인

1. `cat ~/.claude/settings.json`에서 `statusLine.command` 경로 확인
2. `python3`가 PATH에 있는지 확인
3. `<command>-bin`이 이미 있는지 확인한다 — 있으면 오케스트레이터가 이미 설치돼 있다는 뜻이니 설치 절차 1번을 건너뛴다 (다시 실행하면 오케스트레이터 코드가 `-bin`에 덮어써져 원본 바이너리가 사라진다)

**주의**: 확인 과정에서 원본(또는 `-bin`)에 대고 `generate-config`를 실행하지 않는다. 기존 `config.toml`을 덮어쓴다.

## 설치 절차

1. `<command>-bin`이 없을 때만: 원본 바이너리를 `<command>-bin`으로 `cp`한다.
2. `scripts/statusline-orchestrator.sh`를 `<command>` 경로에 복사하고 실행 권한을 준다. 이미 오케스트레이터가 설치돼 있어도(예: PR 링크 skill로) 내용이 같으므로 덮어써도 안전하다.
3. `mkdir -p <command>-segments`
4. `scripts/statusline-segment-notion-link.sh`를 `<command>-segments/notion-link.sh`로 복사하고 실행 권한을 준다.

## 켜고 끄기

- **끄기**: `chmod -x <command>-segments/notion-link.sh`
- **켜기**: `chmod +x <command>-segments/notion-link.sh`
- **제거**: `rm <command>-segments/notion-link.sh`
- PR 링크 segment와는 서로 다른 파일이라 독립적으로 켜고 끌 수 있다. 둘 다 설치하면 기본적으로 둘 다 켜진 상태로 각자 자기 줄을 출력한다.

## 동작 방식

- 오케스트레이터는 인자가 있는 호출을 원본 바이너리로 그대로 패스스루한다. segment는 인자 없이 stdin으로 JSON을 받는 기본 렌더링 호출에서만 실행된다.
- Claude Code가 statusline에 넘기는 JSON에는 현재 세션 transcript 경로(`transcript_path`)가 들어있다. segment는 그 파일의 마지막 3000줄(`tail -n 3000`)만 읽어, `notion-fetch`/`notion-search` 계열 tool_use 호출과 그 결과(tool_result)를 역순으로 찾아 가장 최근 결과의 `title`/`url`을 뽑는다. 3000줄 창 경계에서 tool_use는 창 밖, 그 tool_result만 창 안에 걸치면 그 쌍은 조용히 건너뛴다 — 크래시는 안 나지만 아주 긴 세션에서는 최신 참조를 놓치고 그보다 오래된(또는 아예 없는) 참조가 표시될 수 있다.
- 매 렌더링마다 transcript를 다시 파싱하지 않는다. 캐시가 30초 이상 오래됐을 때만 백그라운드로 다시 파싱하고, 이번 렌더링에는 캐시값을 쓰거나 아무 줄도 출력하지 않는다. 백그라운드 파싱은 10초 타임아웃으로 강제 종료한다(PR 링크 segment와 동일한 lock+timeout 패턴 — macOS에 `timeout`이 없어서 수동 `sleep`+`kill`로 구현).
- 캐시는 `$TMPDIR/claudia-statusline-notion-cache/`에 transcript 경로 해시로 저장하고, title/url을 줄바꿈으로 구분해 저장한다(제목에 `|`가 올 수 있어 파이프 구분 대신 이 방식을 썼다). 제목 자체에 개행이 섞여 들어와 이 2줄 포맷을 깨는 걸 막기 위해, 캐시에 쓰기 전 제목의 `\n`/`\r`은 공백으로 치환한다.
- Notion 참조가 있으면 제목(최대 24자, 초과 시 `…`)을 OSC 8 하이퍼링크로 한 줄 출력한다.

## 검증

1. `rm -rf "${TMPDIR:-/tmp}/claudia-statusline-notion-cache"`로 캐시 초기화
2. Notion MCP를 실제로 호출한 세션의 `transcript_path`를 넣은 JSON으로 두 번 연속 호출 — 두 번째 호출(캐시가 채워진 뒤)에 제목이 클릭 가능한 링크로 새 줄에 붙는지 확인
3. `transcript_path`가 없거나 파일이 없는 경우 기존과 동일한 출력인지 확인
4. `chmod -x <command>-segments/notion-link.sh` 후 호출하면 Notion 줄이 사라지는지, PR 링크 segment(설치돼 있다면)는 영향받지 않는지 확인
5. 인자가 있는 호출(`--version` 등)이 원본과 동일하게 동작하는지 확인
6. 제목에 한글 등 비-ASCII 문자가 포함될 때 깨지지 않는지 확인 (`od`/`python3 -c "open(...).read()"`로 검증 — `cat -v`나 `strings`는 UTF-8을 바이트 단위로 쪼개 보여줘 오탐을 일으킨다)
