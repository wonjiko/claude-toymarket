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

1. **레퍼런스 확인**: `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/*/skills/` 에서 기존 skill 예시 확인
2. **요구사항 파악**: 사용자가 원하는 skill의 목적, 트리거 조건 파악
3. **Skill 설계**:
   - name
   - description (트리거 조건)
   - 핵심 지식/워크플로우
4. **폴더 생성**: `skills/[skill-name]/SKILL.md` 생성

## Skill 구조

```
skill-name/
├── SKILL.md           # 필수 - 메인 skill 파일
├── scripts/           # 선택 - 실행 스크립트
├── references/        # 선택 - 참조 문서
└── assets/            # 선택 - 템플릿, 이미지 등
```

## SKILL.md 구조

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

## 필수 frontmatter 필드

| 필드 | 설명 |
|------|------|
| name | skill 이름 |
| description | 트리거 조건 ("This skill should be used when...") |
| version | 버전 |

## Progressive Disclosure

Skill은 3단계로 로딩됨:
1. **메타데이터** (name + description) - 항상 컨텍스트에 있음
2. **SKILL.md 본문** - skill 트리거시 로딩
3. **번들 리소스** - 필요시 로딩

SKILL.md는 간결하게 유지하고, 상세 내용은 `references/`에 분리.
