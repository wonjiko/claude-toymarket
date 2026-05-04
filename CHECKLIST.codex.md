# Codex Compatibility Checklist

이 체크리스트는 Claude용 플러그인 저장소를 Codex에서도 쓸 수 있게 만들기 위한 기준이다. 현재 Claude 전용 체크는 `CHECKLIST.md`에 남긴다.

## 1. 공용 원본

- [ ] `catalog/toymarket.json`이 존재한다.
- [ ] 모든 `plugins/<name>/` 디렉토리가 `catalog/toymarket.json`에 등록되어 있다.
- [ ] `catalog/toymarket.json`의 모든 plugin entry가 실제 `plugins/<name>/` 디렉토리를 가진다.
- [ ] plugin `name`은 kebab-case이다.
- [ ] plugin `version`, `description`, `author.name`이 비어 있지 않다.
- [ ] Claude/Codex category와 Codex `interface` metadata가 공용 원본에 있다.

## 2. Codex Marketplace

- [ ] `.agents/plugins/marketplace.json`이 존재한다.
- [ ] Codex marketplace의 `plugins[]` 순서가 `catalog/toymarket.json`과 일치한다.
- [ ] 각 entry가 `source.source: "local"`과 `source.path: "./plugins/<name>"`을 가진다.
- [ ] 각 entry가 `policy.installation`과 `policy.authentication`을 가진다.
- [ ] 각 entry의 `category`가 공용 원본과 일치한다.
- [ ] marketplace file은 source에서 다시 렌더링한 결과와 byte-for-byte로 일치한다.

## 3. Codex Plugin Manifest

- [ ] 모든 plugin에 `plugins/<name>/.codex-plugin/plugin.json`이 존재한다.
- [ ] manifest `name`, `version`, `description`, `author`가 공용 원본과 일치한다.
- [ ] skill이 있는 plugin은 `skills: "./skills/"`를 선언한다.
- [ ] hook이 있는 plugin은 Codex에서 읽을 수 있는 hook path를 선언한다.
- [ ] MCP/app config가 있는 plugin은 `mcpServers` 또는 `apps` path를 선언한다.
- [ ] `interface.displayName`, `shortDescription`, `longDescription`, `developerName`, `category`, `capabilities`, `defaultPrompt`가 공용 원본과 일치한다.
- [ ] manifest file은 source에서 다시 렌더링한 결과와 byte-for-byte로 일치한다.

## 4. Shared Skills

- [ ] 모든 `skills/*/SKILL.md`가 Claude/Codex 양쪽에서 읽어도 의미가 통한다.
- [ ] frontmatter에 최소 `name`, `description`이 있다.
- [ ] `name`은 kebab-case이고 폴더명과 일치한다.
- [ ] `description`은 trigger 조건을 구체적으로 설명한다.
- [ ] Claude 전용 도구명이나 명령어가 core workflow에 박혀 있으면 Codex 분기 또는 reference로 분리한다.
- [ ] 큰 예시, 세부 정책, 긴 레퍼런스는 `references/`로 분리한다.

## 5. Commands And Adapters

- [ ] 모든 `commands/*.md`는 Claude 전용 adapter로 취급한다.
- [ ] 각 command의 실제 동작은 skill, script, hook 중 하나의 공용 component로 옮긴다.
- [ ] Codex에서는 command 기능을 skill 또는 hook으로 명시적으로 재분류한다.
- [ ] Codex 이식이 끝난 plugin은 `codex.status`를 `ready`로 바꾼다.
- [ ] 의도적으로 Claude 전용인 plugin은 `codex.status`를 `claude-only`로 바꾼다.

## 6. Hooks And Scripts

- [ ] shell script는 플랫폼별 wrapper가 아니라 공용 실행 단위로 둔다.
- [ ] Claude hook은 `${CLAUDE_PLUGIN_ROOT}` 같은 Claude 전용 변수를 adapter 안에서만 사용한다.
- [ ] Codex hook/skill은 같은 script를 상대 경로 또는 plugin root 기준으로 호출한다.
- [ ] executable script는 실행 권한을 가진다.
- [ ] hook config는 source에서 생성 가능하거나, source와 drift를 검사할 수 있다.

## 7. Fast Verification

```bash
python3 scripts/verify_repo.py --profile claude
```

- [ ] 현재 Claude 구조가 공용 원본과 일치한다.
- [ ] source에 없는 plugin directory가 없다.
- [ ] 실제 directory가 없는 source plugin entry가 없다.
- [ ] Claude marketplace와 plugin manifests가 source에서 렌더링한 결과와 일치한다.
- [ ] skill frontmatter와 command adapter 기본 검사가 통과한다.

## 8. Dual Runtime Gate

```bash
python3 scripts/verify_repo.py --profile dual
```

- [ ] Claude 검사가 통과한다.
- [ ] Codex marketplace가 존재하고 source와 일치한다.
- [ ] 모든 Codex plugin manifest가 존재하고 source와 일치한다.
- [ ] `codex.status: "planned"`가 남아 있지 않다.
- [ ] Codex에서 실제 진입점이 없는 plugin을 `ready`로 표시하지 않았다.
- [ ] `ready` plugin의 manifest에 `skills`, `hooks`, `mcpServers`, `apps` 중 하나가 있다.
- [ ] `claude-only` plugin은 Codex marketplace에서 `policy.installation: "NOT_AVAILABLE"`로 표시된다.
