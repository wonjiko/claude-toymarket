---
name: Skill Creator
description: This skill should be used when the user wants to "create a skill", "add a skill", "make a new skill", or needs guidance on skill structure for Claude Code plugins.
version: 0.1.0
---

# Skill Creator

새로운 Claude Code skill을 생성하는 skill.

## Skill이란?

Skill은 Claude의 특정 도메인 지식과 워크플로우를 확장하는 모듈.
- 전문 워크플로우
- 도메인 지식
- 스크립트와 레퍼런스 번들

## 프로세스

### 1. 요구사항 파악

사용자가 원하는 skill의:
- 목적과 도메인
- 트리거 조건
- 필요한 지식/워크플로우

불명확하면 질문:
- "이 skill은 어떤 상황에서 활성화되어야 하나요?"
- "어떤 도메인 지식이나 워크플로우가 필요한가요?"

### 2. 레퍼런스 확인

`~/.claude/plugins/marketplaces/claude-plugins-official/plugins/*/skills/` 에서 유사한 skill 패턴 확인.

### 3. Skill 설계

다음 항목 결정:

**name**
- 명확하고 설명적인 이름

**description**
- "This skill should be used when..." 으로 시작
- 트리거 조건 명시

**구조**
```
skill-name/
├── SKILL.md           # 필수 - 메인 skill 파일
├── scripts/           # 선택 - 실행 스크립트
├── references/        # 선택 - 참조 문서
└── assets/            # 선택 - 템플릿, 이미지 등
```

### 4. 파일 생성

`skills/[skill-name]/SKILL.md` 파일 생성:

```markdown
---
name: [Skill Name]
description: This skill should be used when [트리거 조건]...
version: 0.1.0
---

# [Skill Name]

[상세 설명]

## [핵심 섹션들]

[도메인 지식, 워크플로우, 가이드라인 등]
```

### 5. Validation

생성된 파일 검증:
- [ ] frontmatter가 `---`로 시작하고 끝나는지
- [ ] `name` 필드가 존재하는지
- [ ] `description`이 "This skill should be used when"으로 시작하는지
- [ ] `version` 필드가 존재하는지
- [ ] 파일명이 `SKILL.md`인지 (대문자)
- [ ] 폴더 구조가 `skills/[name]/SKILL.md`인지

검증 실패 시:
1. 문제점 보고
2. 자동 수정
3. 재검증

## 필수 frontmatter 필드

| 필드 | 필수 | 설명 |
|------|------|------|
| name | ✓ | skill 이름 |
| description | ✓ | 트리거 조건 |
| version | ✓ | 버전 (semver) |

## Progressive Disclosure

Skill은 3단계로 로딩됨:
1. **메타데이터** (name + description) - 항상 컨텍스트에 있음
2. **SKILL.md 본문** - skill 트리거시 로딩
3. **번들 리소스** - 필요시 로딩

SKILL.md는 간결하게 유지하고, 상세 내용은 `references/`에 분리.

## 출력

생성 완료 후 출력:

```
## Skill Created: [name]

### Configuration
- **Name:** [name]
- **Triggers:** [트리거 조건 요약]
- **Version:** [version]

### Files Created
`skills/[name]/SKILL.md` ([word count] words)

### Validation
✓ frontmatter valid
✓ description format correct
✓ version present
✓ folder structure correct

### How to Test
[skill이 트리거될 상황 예시]

### Next Steps
- 테스트 실행 및 동작 확인
- 필요시 references/ 추가
```

## 엣지 케이스

| 상황 | 대응 |
|------|------|
| 모호한 요청 | 질문으로 명확화 |
| 복잡한 도메인 | references/로 분리 |
| 스크립트 필요 | scripts/ 폴더 생성 |
| 템플릿 필요 | assets/ 폴더 생성 |
