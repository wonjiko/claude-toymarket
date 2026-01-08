---
description: 새로운 slash command를 만든다
argument-hint: command 이름과 설명
allowed-tools: ["Read", "Write", "Glob", "AskUserQuestion"]
---

# Create Command

새로운 Claude Code slash command를 생성한다.

## 사용법

```
/matryoshka-plugin:create-command [name] [description]
```

## 입력

**$ARGUMENTS**

## 프로세스

1. **레퍼런스 확인**: `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/` 에서 기존 command 예시 확인
2. **정보 수집**: 이름, 설명, 필요한 도구가 없으면 사용자에게 질문
3. **파일 생성**: `commands/[name].md` 생성

## Command 파일 구조

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

## 필수 frontmatter 필드

| 필드 | 설명 |
|------|------|
| description | command 설명 (트리거 조건) |
| argument-hint | 인자 힌트 (선택) |
| allowed-tools | 사용 가능한 도구 목록 |

## 출력

생성된 command 파일 경로와 내용 요약을 출력한다.
