# Dual Runtime Architecture

이 문서는 `claude-toymarket`를 Claude Code, Codex, Cursor에서 쓰는 하이브리드 마켓플레이스로 유지하기 위한 기준을 기록한다.

## 목표

- 공용 동작은 한 곳에 둔다.
- 런타임 전용 파일은 얇은 adapter 또는 generated file로 둔다.
- 구조 정합성은 LLM 없이, 네트워크 없이, 빠르게 검사한다.
- 검사 결과는 같은 입력에 대해 항상 같은 순서와 같은 exit code를 낸다.

## Source Of Truth

현재 공용 원본은 `catalog/toymarket.json`이다.

이 파일은 다음 값을 가진다.

- marketplace 이름, 설명, owner
- plugin 이름, 설명, version, author
- Claude marketplace category
- Codex marketplace category, interface metadata, migration status
- Cursor marketplace displayName

Python 3.9 환경에서 표준 라이브러리만 쓰기 위해 TOML 대신 JSON을 사용한다. 나중에 Python 3.11 이상을 기준으로 고정하면 TOML로 옮길 수 있지만, 지금은 의존성 없는 검사가 더 중요하다.

## Generated Targets

Claude generated targets:

- `.claude-plugin/marketplace.json`
- `plugins/<plugin>/.claude-plugin/plugin.json`

Cursor generated targets:

- `.cursor-plugin/marketplace.json`
- `plugins/<plugin>/.cursor-plugin/plugin.json`

Codex generated targets:

- `.agents/plugins/marketplace.json`
- `plugins/<plugin>/.codex-plugin/plugin.json`

Claude와 Cursor target은 `--profile claude`에서도 검사한다. Codex target은 `--profile dual`에서 검사한다.

## Shared Components

공용으로 유지할 파일:

- `plugins/<plugin>/skills/*/SKILL.md`
- `plugins/<plugin>/hooks/*.sh`
- `plugins/<plugin>/references/**`
- `plugins/<plugin>/assets/**`

플랫폼 전용으로 유지할 파일:

- `plugins/<plugin>/commands/*.md`: Claude slash command adapter. Cursor도 같은 `commands/`를 읽는다.
- `plugins/<plugin>/agents/*.md`: Claude agent definition. Cursor도 같은 `agents/`를 읽는다.
- `plugins/<plugin>/.claude-plugin/plugin.json`: Claude generated manifest
- `plugins/<plugin>/.cursor-plugin/plugin.json`: Cursor generated manifest
- `plugins/<plugin>/.codex-plugin/plugin.json`: Codex generated manifest

Codex에는 Claude의 `commands/`와 1:1로 같은 개념이 없다. 따라서 command 성격의 기능은 Codex에서는 skill, hook, MCP/app capability 중 하나로 명시적으로 재분류한다.

Cursor hook schema는 Claude와 다르다. Claude `hooks/hooks.json`이 있으면 Cursor manifest는 빈 `hooks`를 넣어 auto-discovery를 막는다. MCP config가 `.mcp.json`이면 Cursor manifest가 그 경로를 `mcpServers`로 가리킨다.

## Verification Model

`scripts/verify_repo.py`가 구조를 읽기 전용으로 검사한다.

검사기는 다음 순서로 동작한다.

1. `catalog/toymarket.json`을 읽고 schema를 검사한다.
2. `plugins/` 실제 디렉토리와 source plugin 목록을 대조한다.
3. Claude/Cursor marketplace와 plugin manifest를 source에서 다시 렌더링한다.
4. 실제 generated file과 byte-for-byte로 비교한다.
5. skill frontmatter와 command adapter 기본 구조를 검사한다.
6. `--profile dual`에서는 Codex marketplace와 manifest까지 같은 방식으로 검사한다.

검사기는 파일 수정시각, 랜덤값, 네트워크, 외부 패키지를 사용하지 않는다.

## Migration Gates

`codex.status` 값은 마이그레이션 상태를 표시한다.

- `planned`: Codex manifest metadata는 준비됐지만 기능 adapter가 아직 확정되지 않음
- `ready`: Codex에서 실제 기능 진입점이 검증됨
- `claude-only`: 의도적으로 Claude 전용으로 유지

`--profile dual`을 CI gate로 쓰려면 모든 플러그인의 `codex.status`가 `ready` 또는 `claude-only`여야 한다. `planned`가 남아 있으면 이중 런타임 완료 상태로 보지 않는다.

`ready`는 실제 Codex 진입점이 있을 때만 사용한다. 검증기는 `ready` plugin manifest에 `skills`, `hooks`, `mcpServers`, `apps` 중 하나가 없으면 실패시킨다.

`claude-only`는 Codex marketplace에 남기되 `policy.installation: "NOT_AVAILABLE"`로 렌더링한다. 이 상태의 Codex manifest는 표시용 metadata만 가지며 기능 entrypoint를 노출하지 않는다.

## Workflow

일반 수정 흐름:

1. `catalog/toymarket.json` 또는 공용 component를 수정한다.
2. 필요한 generated file을 갱신한다.
3. `python3 scripts/verify_repo.py --profile claude`로 Claude/Cursor 구조를 검사한다.
4. Codex 이식 단계에서는 `python3 scripts/verify_repo.py --profile dual`을 통과시킨다.
