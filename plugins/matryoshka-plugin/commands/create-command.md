---
description: 새로운 slash command를 만든다
argument-hint: <name> [description]
allowed-tools: ["Read", "Write", "Glob"]
---

# Create Command

새로운 Claude Code slash command를 생성한다.

## 사용법

```
/matryoshka-plugin:create-command <name> [description]
```

## 입력

**$ARGUMENTS**

## 프로세스

### 1. 입력 파싱

인자가 제공되면 파싱:
- 첫 번째 단어: command 이름
- 나머지: 설명

인자가 없거나 불충분하면 사용자에게 직접 질문:
- "어떤 command를 만들까요? 이름과 설명을 알려주세요."
- "예: `review` - PR 코드를 리뷰한다"

### 2. 레퍼런스 확인

`~/.claude/plugins/marketplaces/claude-plugins-official/plugins/*/commands/` 에서 유사한 command 패턴 확인.

### 3. Command 설계

다음 항목 결정:
- **name**: lowercase, hyphens 허용 (예: `code-review`)
- **description**: /help에 표시될 한 줄 설명
- **argument-hint**: 인자 형식 힌트 (예: `<file> [options]`)
- **allowed-tools**: 필요한 도구 목록
- **프로세스**: 단계별 동작 정의

### 4. 파일 생성

`commands/[name].md` 파일 생성:

```markdown
---
description: [한 줄 설명]
argument-hint: [인자 힌트]
allowed-tools: ["Read", "Write", ...]
---

# [Command Name]

[상세 설명]

## 사용법

[사용 예시]

## 프로세스

[단계별 동작]
```

### 5. Validation

생성된 파일 검증:
- [ ] frontmatter가 `---`로 시작하고 끝나는지
- [ ] `description` 필드가 존재하는지
- [ ] `description`이 비어있지 않은지
- [ ] 파일이 markdown 형식인지

검증 실패 시 문제점 보고 및 수정.

## 필수 frontmatter 필드

| 필드 | 필수 | 설명 |
|------|------|------|
| description | ✓ | command 설명 (/help에 표시) |
| argument-hint | | 인자 힌트 |
| allowed-tools | | 사전 승인 도구 목록 |
| model | | 모델 지정 (haiku, sonnet, opus) |

## 출력

생성 완료 후 출력:

```
## Command Created: [name]

- **파일**: `commands/[name].md`
- **설명**: [description]
- **도구**: [allowed-tools]

### 테스트 방법
`/[plugin-name]:[command-name]` 으로 실행
```
