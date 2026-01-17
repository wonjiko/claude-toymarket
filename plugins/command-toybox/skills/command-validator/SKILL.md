---
name: Command Validator
description: This skill should be used when the user wants to "validate a command", "review my command", "check command quality", "audit slash command", or needs evaluation of their Claude Code custom command against best practices.
version: 0.1.0
---

# Command Validator

Claude Code custom command를 공식 문서 기준과 베스트 프랙티스로 검증하고 점수를 매긴다.

## 검증 대상

사용자가 제공한 command 파일 (`.md`)

## 체크리스트

### 1. Frontmatter (25점)

| 항목 | 점수 | 기준 |
|------|------|------|
| description 존재 | 5 | frontmatter에 description 필드가 있는가 |
| description 품질 | 5 | 60자 이내, 동사로 시작, 명확한가 |
| allowed-tools 적절성 | 5 | 필요한 도구만 최소로, Bash는 command filter 사용 |
| argument-hint 제공 | 5 | 인자 사용 시 hint가 있는가 |
| model 적절성 | 5 | 복잡도에 맞는 모델 선택 (또는 생략) |

### 2. 본문 구조 (25점)

| 항목 | 점수 | 기준 |
|------|------|------|
| Agent 지향 작성 | 10 | Claude에게 지시하는 형식인가 (사용자 설명 X) |
| 단일 책임 | 5 | 하나의 command = 하나의 명확한 task |
| 프로세스 명확성 | 5 | 단계별 작업이 명확한가 |
| 불필요한 내용 없음 | 5 | 마케팅 언어, 과잉 설명 없는가 |

### 3. Dynamic 기능 활용 (25점)

| 항목 | 점수 | 기준 |
|------|------|------|
| $ARGUMENTS / $1, $2 사용 | 10 | 인자가 필요하면 적절히 사용하는가 |
| @file 참조 | 5 | 파일 참조가 필요하면 사용하는가 |
| !`command` 활용 | 5 | 동적 컨텍스트가 필요하면 bash 실행 사용하는가 |
| ${CLAUDE_PLUGIN_ROOT} | 5 | 플러그인 command면 경로 참조 활용 |

### 4. 안정성 & 에러 처리 (25점)

| 항목 | 점수 | 기준 |
|------|------|------|
| 입력 검증 | 10 | 필수 인자 없을 때 처리가 있는가 |
| 에러 케이스 고려 | 5 | 실패 상황에 대한 가이드가 있는가 |
| 보안 고려 | 5 | 민감한 정보 노출 위험이 없는가 |
| 파괴적 작업 경고 | 5 | 돌이킬 수 없는 작업 전 경고가 있는가 |

## 검증 프로세스

### Step 1: 파일 읽기

사용자가 제공한 command 파일을 읽는다.

### Step 2: 체크리스트 평가

각 항목을 평가하고 점수를 매긴다:
- 완전 충족: 만점
- 부분 충족: 절반
- 미충족: 0점
- 해당 없음: 만점 (패널티 없음)

### Step 3: 결과 출력

```
## Command Validation Report

### Summary
- **파일**: [파일명]
- **총점**: [X]/100
- **등급**: [S/A/B/C/D]

### Frontmatter (X/25)
- [x] description 존재 (5/5)
- [ ] description 품질 (2/5) - "60자 초과"
...

### 본문 구조 (X/25)
...

### Dynamic 기능 (X/25)
...

### 안정성 (X/25)
...

### 개선 제안
1. [구체적인 개선 사항]
2. [구체적인 개선 사항]

### 수정된 버전 (선택)
[점수가 B 이하면 개선된 버전 제안]
```

## 등급 기준

| 등급 | 점수 | 설명 |
|------|------|------|
| S | 90-100 | 모범 사례, 배포 권장 |
| A | 80-89 | 우수, 사소한 개선 가능 |
| B | 70-79 | 양호, 개선 권장 |
| C | 60-69 | 보통, 개선 필요 |
| D | 0-59 | 미흡, 재작성 권장 |

## 예외 처리

| 상황 | 대응 |
|------|------|
| 파일 경로 미제공 | 경로 요청 |
| 유효하지 않은 markdown | 파싱 에러 보고 |
| frontmatter 없음 | 없는 것으로 간주하고 평가 |
| 플러그인 vs 유저 command | 컨텍스트에 맞게 ${CLAUDE_PLUGIN_ROOT} 평가 |

## 참고 레퍼런스

평가 기준은 다음을 기반으로 함:
- Claude Code 공식 문서 (https://code.claude.com/docs/)
- `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/plugin-dev/skills/command-development/`
