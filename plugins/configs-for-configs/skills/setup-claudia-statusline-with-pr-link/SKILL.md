---
name: setup-claudia-statusline-with-pr-link
description: This skill should be used when the user wants their Claude Code statusline to show the current branch's GitHub PR — "스테이터스라인에 PR 링크", "PR 보여줘", "repo + PR 표시", "claudia-statusline PR 연동" — while running claudia-statusline (the Rust `statusline` binary, `statusLine.command` in `~/.claude/settings.json`). Installs a wrapper script that appends a clickable "repo#PR" (OSC 8 hyperlink) segment for the current branch's open PR, fetched asynchronously via `gh` with caching so the statusline never blocks.
version: 0.1.0
---

# claudia-statusline에 PR 링크 추가

claudia-statusline은 커스텀 세그먼트나 외부 명령 실행 기능이 없는 컴파일된 바이너리다. PR 표시는 바이너리 자체를 고치는 대신, 원본을 감싸는 wrapper 스크립트로 구현한다.

## 언제 쓰면 안 되는지

- `~/.claude/settings.json`의 `statusLine.command`가 claudia-statusline이 아닌 경우 (다른 도구는 구조가 다르다)
- `gh` CLI가 설치/인증되어 있지 않은 경우
- 저장소 origin이 github.com이 아닌 경우 (동작은 하지만 PR이 항상 표시되지 않는다)
- macOS가 아닌 환경 (wrapper가 `stat -f`, `shasum` 등 BSD 계열 명령을 쓴다. Linux `stat -f`는 파일시스템 상태를 뜻해 동작이 달라진다)

## 사전 확인

1. `cat ~/.claude/settings.json`에서 `statusLine.command` 경로 확인
2. `<command> --version` 출력에 `statusline`이 포함되는지 확인해 claudia-statusline이 맞는지 검증
3. `gh auth status`로 GitHub 인증 확인
4. `python3`가 PATH에 있는지 확인 (`workspace.current_dir` 파싱에 쓴다 — 없으면 PR 조회 없이 원본과 동일한 출력으로 조용히 폴백한다)
5. `<command> --help`로 이미 wrapper가 설치돼 있지 않은지 확인 (subcommand 목록이 `generate-config`, `health`, `hook` 등 claudia-statusline 고유 목록과 같으면 원본, 아니면 이미 wrapper일 수 있다)

**주의**: 확인 과정에서 `<command> generate-config`를 실행하지 않는다. 기존 `config.toml`을 덮어쓴다.

## 설치 절차

1. 원본 바이너리를 같은 디렉터리에 `<command 파일명>-bin`으로 복사해 보존한다 (`mv`가 아니라 `cp` — 실패 시 원본이 남아 있어야 한다).
2. `scripts/statusline-pr-wrapper.sh`를 `<command>` 경로에 그대로 복사하고 실행 권한을 준다.
3. wrapper는 `BIN="${BASH_SOURCE[0]}-bin"`로 원본 바이너리를 자기 경로 기준 상대 위치에서 찾는다. 경로를 하드코딩할 필요가 없다.

## 동작 방식

- `--` 인자가 하나라도 있는 호출(`generate-config`, `health`, `list-vars`, `hook` 등)은 원본 바이너리로 그대로 패스스루한다. 인자 없이 stdin으로 JSON을 받는 기본 렌더링 호출에만 PR 세그먼트를 추가한다.
- PR 조회는 `gh pr list --repo <owner>/<repo> --head <branch> --state open`을 매번 동기 호출하지 않는다. 캐시가 30초 이상 오래됐을 때만 백그라운드 프로세스로 조회하고, 이번 렌더링에는 있으면 캐시값을, 없으면 아무것도 붙이지 않는다 — statusline 렌더링 자체는 항상 즉시 끝난다.
- 캐시는 `$TMPDIR/claudia-statusline-pr-cache/`에 저장소+브랜치 해시로 저장한다. lock 파일로 동시에 여러 백그라운드 조회가 겹치지 않게 한다. 백그라운드 `gh` 호출은 10초 타임아웃(수동 `sleep`+`kill`)으로 강제 종료한다 — macOS에 `timeout`이 없어서다. lock은 15초 뒤에야 stale로 보므로, 타임아웃보다 항상 여유 있게 유지되어 동시에 여러 `gh` 프로세스가 쌓이지 않는다.
- PR이 있으면 `repo#번호`를 OSC 8 이스케이프(`\033]8;;URL\033\\...텍스트...\033]8;;\033\\`)로 감싸 클릭 가능한 링크로 출력한다. OSC 8을 지원하지 않는 터미널에서는 이스케이프 시퀀스가 무시되고 텍스트만 보인다.

## 검증

1. `rm -rf "${TMPDIR:-/tmp}/claudia-statusline-pr-cache"`로 캐시 초기화
2. 열린 PR이 있는 브랜치의 디렉터리로 `workspace.current_dir`을 채운 JSON을 stdin으로 두 번 연속 호출 — 첫 호출은 기존 출력과 동일, 두 번째 호출(캐시가 채워진 뒤)에 `repo#PR`이 붙는지 확인
3. PR이 없는 브랜치, git 저장소가 아닌 디렉터리에서는 기존과 동일한 출력인지 확인
4. `<command> --version`, `<command> generate-config --help` 등 인자가 있는 호출이 원본과 동일하게 동작하는지 확인
5. `config.toml` 등 claudia-statusline의 기존 설정 파일이 그대로인지 확인
