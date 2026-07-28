---
name: setup-claudia-statusline-with-pr-link
description: This skill should be used when the user wants their Claude Code statusline to show open GitHub PRs for the repos they're actively working in — "스테이터스라인에 PR 링크", "PR 보여줘", "repo + PR 표시", "여러 레포 작업할 때 PR 다 보여줘", "claudia-statusline PR 연동" — while running claudia-statusline (the Rust `statusline` binary, `statusLine.command` in `~/.claude/settings.json`). Installs a shared orchestrator (if not already present) plus a togglable "pr-link" segment that appends one clickable "repo#PR" (OSC 8 hyperlink) line per distinct repo the current session has worked in, fetched asynchronously via `gh` with per-repo caching so the statusline never blocks.
version: 0.3.0
---

# claudia-statusline에 PR 링크 추가

claudia-statusline은 커스텀 세그먼트나 외부 명령 실행 기능이 없는 컴파일된 바이너리다. PR 표시는 바이너리 자체를 고치는 대신, 원본을 감싸는 **오케스트레이터**와 그 아래 켜고 끌 수 있는 **segment**로 구현한다. 오케스트레이터는 원본 바이너리를 실행한 뒤, `<command>-segments/` 안의 실행 가능한 `*.sh` 파일을 전부 돌려서 각자 출력한 줄을 덧붙인다. 다른 segment(예: `setup-claudia-statusline-with-notion-link`)와 독립적으로 공존한다 — 서로 다른 segment 파일이라 겹치지 않는다.

## 언제 쓰면 안 되는지

- `~/.claude/settings.json`의 `statusLine.command`가 claudia-statusline이 아닌 경우 (다른 도구는 구조가 다르다)
- `gh` CLI가 설치/인증되어 있지 않은 경우
- 저장소 origin이 github.com이 아닌 경우 (동작은 하지만 PR이 항상 표시되지 않는다)
- macOS가 아닌 환경 (segment가 `stat -f`, `shasum` 등 BSD 계열 명령을 쓴다. Linux `stat -f`는 파일시스템 상태를 뜻해 동작이 달라진다)

## 사전 확인

1. `cat ~/.claude/settings.json`에서 `statusLine.command` 경로 확인
2. `python3`가 PATH에 있는지 확인 (`workspace.current_dir` 파싱에 쓴다 — 없으면 PR 조회 없이 원본과 동일한 출력으로 조용히 폴백한다)
3. `gh auth status`로 GitHub 인증 확인
4. `<command>-bin`이 이미 있는지 확인한다 — 있으면 오케스트레이터가 이미 설치돼 있다는 뜻이니 설치 절차 1번을 건너뛴다 (다시 실행하면 오케스트레이터 코드가 `-bin`에 덮어써져 원본 바이너리가 사라진다)

**주의**: 확인 과정에서 원본(또는 `-bin`)에 대고 `generate-config`를 실행하지 않는다. 기존 `config.toml`을 덮어쓴다.

## 설치 절차

1. `<command>-bin`이 없을 때만: 원본 바이너리를 `<command>-bin`으로 `cp`한다 (`mv`가 아니라 `cp` — 실패 시 원본이 남아 있어야 한다).
2. `scripts/statusline-orchestrator.sh`를 `<command>` 경로에 복사하고 실행 권한을 준다. 이미 오케스트레이터가 설치돼 있어도 내용이 같으므로 덮어써도 안전하다.
3. `mkdir -p <command>-segments`
4. `scripts/statusline-segment-pr-link.sh`를 `<command>-segments/pr-link.sh`로 복사하고 실행 권한을 준다.

## 켜고 끄기

- **끄기**: `chmod -x <command>-segments/pr-link.sh` — 파일은 남고 오케스트레이터가 건너뛴다.
- **켜기**: `chmod +x <command>-segments/pr-link.sh`
- **제거**: `rm <command>-segments/pr-link.sh`

## 동작 방식

- 오케스트레이터는 인자가 있는 호출(`generate-config`, `health`, `list-vars`, `hook` 등)을 원본 바이너리로 그대로 패스스루한다. segment는 인자 없이 stdin으로 JSON을 받는 기본 렌더링 호출에서만 실행된다.
- 표시 대상은 현재 디렉터리(`workspace.current_dir`) 레포 하나가 아니라 **이 세션이 작업한 모든 레포**다. Claude Code가 세션 transcript(`transcript_path`)의 모든 이벤트에 그 시점의 `cwd`를 남기는 걸 이용해, transcript의 마지막 3000줄에서 서로 다른 `cwd`를 최신순으로 모으고 `workspace.current_dir`을 맨 앞에 더한다. 각 후보 디렉터리를 `git rev-parse --show-toplevel`로 저장소 루트에 매핑해 중복 제거하고, 최대 8개 저장소까지만 본다(`MAX_REPOS`) — 그 이상은 백그라운드 `gh` 호출이 과도하게 쌓이는 걸 막기 위한 상한이며, 넘는 만큼은 화면에 안 뜬다.
- 저장소별로 독립적인 캐시 키(저장소+브랜치 해시)를 쓴다. PR 조회는 `gh pr list --repo <owner>/<repo> --head <branch> --state open`을 저장소마다 매번 동기 호출하지 않는다. 각 저장소는 자기 캐시가 30초 이상 오래됐을 때만 백그라운드 프로세스로 조회하고, 이번 렌더링에는 캐시값이 있으면 그 줄을, 없으면 아무것도 출력하지 않는다 — 렌더링 자체는 항상 즉시 끝난다. PR이 없어 `gh pr list`가 빈 배열을 반환할 때는 jq 쿼리에 `// empty`를 붙여 캐시에 아무것도 안 쓴다 — 빠뜨리면 `.[0]`이 `null`이 되고 jq가 null의 필드 접근을 에러 없이 허용해 `repo#null`이라는 가짜 링크가 캐시되고 표시된다.
- 캐시는 `$TMPDIR/claudia-statusline-pr-cache/`에 저장소+브랜치 해시로 저장한다. 저장소별 lock 파일(15초 이상 stale일 때만 재조회)과 백그라운드 `gh` 호출의 수동 타임아웃(10초, `sleep`+`kill` — macOS에 `timeout`이 없어서)으로, 여러 저장소를 동시에 조회하더라도 저장소당 `gh` 프로세스가 하나 이상 쌓이지 않는다.
- PR이 있는 저장소마다 `repo#번호`를 OSC 8 이스케이프(`\033]8;;URL\033\\...텍스트...\033]8;;\033\\`)로 감싸 한 줄씩 출력한다. OSC 8을 지원하지 않는 터미널에서는 이스케이프 시퀀스가 무시되고 텍스트만 보인다.

## 검증

1. `rm -rf "${TMPDIR:-/tmp}/claudia-statusline-pr-cache"`로 캐시 초기화
2. 열린 PR이 있는 브랜치의 디렉터리로 `workspace.current_dir`을 채운 JSON을 stdin으로 두 번 연속 호출 — 첫 호출은 기존 출력과 동일, 두 번째 호출(캐시가 채워진 뒤)에 새 줄로 `repo#PR`이 붙는지 확인
3. `transcript_path`에 서로 다른 레포의 `cwd`를 담은 이벤트가 섞인 transcript를 넣고, 열린 PR이 있는 레포 두 개를 오갔을 때 두 줄 모두 뜨는지 확인 — 실제 두 레포로 검증해봤다(하나는 `workspace.current_dir`, 하나는 transcript의 `cwd`로만 등장)
4. PR이 없는 브랜치, git 저장소가 아닌 디렉터리에서는 기존과 동일한 출력인지 확인 — `repo#null`처럼 PR 번호 자리에 `null`이 나오면 회귀다
5. `transcript_path`가 없는 예전 스타일 JSON에서도 `workspace.current_dir` 하나만으로 정상 동작하는지 확인 (하위 호환)
6. `chmod -x <command>-segments/pr-link.sh` 후 호출하면 PR 줄이 모두 사라지는지, 다른 segment(설치돼 있다면)는 영향받지 않는지 확인
7. `<command> --version` 등 인자가 있는 호출이 원본과 동일하게 동작하는지 확인
8. `config.toml` 등 claudia-statusline의 기존 설정 파일이 그대로인지 확인
