---
name: setup-claudia-statusline-with-notion-link
description: This skill should be used when the user wants their Claude Code statusline to show the most recently referenced Notion page from the current session — "스테이터스라인에 노션 링크", "세션에서 본 노션 문서 표시", "claudia-statusline notion 연동" — while running claudia-statusline (the Rust `statusline` binary, `statusLine.command` in `~/.claude/settings.json`). Installs a wrapper script that scans the session transcript for the last Notion MCP fetch/search result and appends its title as a clickable OSC 8 hyperlink, computed asynchronously with caching so the statusline never blocks.
version: 0.1.0
---

# claudia-statusline에 Notion 링크 추가

이 세션에서 마지막으로 조회한 Notion 페이지를 클릭 가능한 링크로 statusline에 보여준다. PR 링크(`setup-claudia-statusline-with-pr-link`)와 원리는 같지만 소스가 git/GitHub가 아니라 세션 transcript다.

## 언제 쓰면 안 되는지

- `~/.claude/settings.json`의 `statusLine.command`가 claudia-statusline이 아닌 경우
- Notion MCP(`mcp__..._notion__notion-fetch` / `notion-search`)를 세션에서 쓰지 않는 경우 — 조회할 기록 자체가 없다
- macOS가 아닌 환경 (`stat -f`, `shasum` 등 BSD 전용 명령 사용)
- **이미 `setup-claudia-statusline-with-pr-link`를 설치한 경우**: 두 skill 모두 같은 바이너리 경로(`<command>`)를 감싸므로, 나중에 설치하는 쪽이 앞서 설치된 wrapper를 원본으로 착각하고 덮어써 먼저 설치한 기능이 사라진다. 둘 다 원하면 두 wrapper의 세그먼트 추가 로직을 하나의 스크립트로 합쳐야 한다 — 이 skill은 그 작업을 하지 않는다.

## 사전 확인

1. `cat ~/.claude/settings.json`에서 `statusLine.command` 경로 확인
2. `<command> --version` 출력에 `statusline`이 포함되는지 확인
3. `python3`가 PATH에 있는지 확인
4. `<command> --help`로 이미 wrapper가 설치돼 있지 않은지 확인 — 특히 `setup-claudia-statusline-with-pr-link`가 먼저 설치돼 있으면 위 "언제 쓰면 안 되는지" 참고

**주의**: 확인 과정에서 `<command> generate-config`를 실행하지 않는다. 기존 `config.toml`을 덮어쓴다.

## 설치 절차

1. 원본 바이너리를 같은 디렉터리에 `<command 파일명>-bin`으로 `cp`로 복사해 보존한다.
2. `scripts/statusline-notion-wrapper.sh`를 `<command>` 경로에 그대로 복사하고 실행 권한을 준다.
3. wrapper는 `BIN="${BASH_SOURCE[0]}-bin"`로 원본 바이너리를 찾는다. 경로 하드코딩 불필요.

## 동작 방식

- 인자가 있는 호출은 원본 바이너리로 패스스루한다. 인자 없이 stdin으로 JSON을 받는 기본 렌더링 호출에만 Notion 세그먼트를 추가한다.
- Claude Code가 statusline에 넘기는 JSON에는 현재 세션 transcript 경로(`transcript_path`)가 들어있다. wrapper는 그 파일의 마지막 3000줄(`tail -n 3000`)만 읽어, `notion-fetch`/`notion-search` 계열 tool_use 호출과 그 결과(tool_result)를 역순으로 찾아 가장 최근 결과의 `title`/`url`을 뽑는다. 3000줄 창 경계에서 tool_use는 창 밖, 그 tool_result만 창 안에 걸치면 그 쌍은 조용히 건너뛴다 — 크래시는 안 나지만 아주 긴 세션에서는 최신 참조를 놓치고 그보다 오래된(또는 아예 없는) 참조가 표시될 수 있다.
- 매 렌더링마다 transcript를 다시 파싱하지 않는다. 캐시가 30초 이상 오래됐을 때만 백그라운드로 다시 파싱하고, 이번 렌더링에는 캐시값을 쓰거나 아무것도 붙이지 않는다. 백그라운드 파싱은 10초 타임아웃으로 강제 종료한다(PR 링크 skill과 동일한 lock+timeout 패턴 — macOS에 `timeout`이 없어서 수동 `sleep`+`kill`로 구현).
- 캐시는 `$TMPDIR/claudia-statusline-notion-cache/`에 transcript 경로 해시로 저장하고, title/url을 줄바꿈으로 구분해 저장한다(제목에 `|`가 올 수 있어 PR skill의 파이프 구분과 다르게 했다). 제목 자체에 개행이 섞여 들어와 이 2줄 포맷을 깨는 걸 막기 위해, 캐시에 쓰기 전 제목의 `\n`/`\r`은 공백으로 치환한다.
- Notion 참조가 있으면 원래 출력 뒤에 새 줄로 제목(최대 24자, 초과 시 `…`)을 OSC 8 하이퍼링크로 추가한다. git/디렉터리 줄은 건드리지 않는다.

## 검증

1. `rm -rf "${TMPDIR:-/tmp}/claudia-statusline-notion-cache"`로 캐시 초기화
2. Notion MCP를 실제로 호출한 세션의 `transcript_path`를 넣은 JSON으로 두 번 연속 호출 — 두 번째 호출(캐시가 채워진 뒤)에 제목이 클릭 가능한 링크로 붙는지 확인
3. `transcript_path`가 없거나 파일이 없는 경우 기존과 동일한 출력인지 확인
4. 인자가 있는 호출(`--version` 등)이 원본과 동일하게 동작하는지 확인
5. 제목에 한글 등 비-ASCII 문자가 포함될 때 깨지지 않는지 확인 (`od`/`python3 -c "open(...).read()"`로 검증 — `cat -v`나 `strings`는 UTF-8을 바이트 단위로 쪼개 보여줘 오탐을 일으킨다)
