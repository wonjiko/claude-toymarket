---
name: reflection
description: This skill should be used when the user wants to "reflect on instructions", "analyze claude config", "review claude setup", or needs analysis and improvement suggestions for Claude Code instructions and configuration.
version: 0.1.0
---

# Claude Instructions 분석 및 개선

Claude Code의 instructions와 config를 분석하고 개선을 제안한다.

## 프로세스

### Step 1: 분석

대화 히스토리를 리뷰한 후, 다음 파일들을 읽고 분석한다:

- `/CLAUDE.md` (project root)
- `**/**/CLAUDE.md` (nested directories)
- `/.claude/commands/*`
- `.claude/settings.json`
- `.claude/settings.local.json`

분석 항목:
- Claude 응답의 비일관성
- 사용자 요청 오해 패턴
- 더 상세하거나 정확한 정보를 제공할 수 있는 영역
- 특정 쿼리/작업 처리 개선 기회
- 새 command나 기존 command 개선점
- 권한 및 MCP 설정 중 config에 추가해야 할 것들

### Step 2: 인터랙션

발견 사항과 개선 아이디어를 사용자에게 제시한다. 각 제안마다:
1. 현재 이슈 설명
2. 구체적인 변경/추가 제안
3. 변경이 가져올 개선 효과 설명

사용자 피드백을 받아 승인된 변경만 구현으로 진행한다.

### Step 3: 구현

승인된 각 변경에 대해:
1. 수정할 instructions 섹션 명시
2. 새로운/수정된 텍스트 제시
3. 이 변경이 식별된 이슈를 어떻게 해결하는지 설명

### Step 4: 결과 출력

```
<analysis>
[식별된 이슈 및 잠재적 개선사항 목록]
</analysis>

<improvements>
[승인된 각 개선사항:
1. 수정 대상 섹션
2. 새로운/수정된 instruction 텍스트
3. 이슈 해결 방법 설명]
</improvements>

<final_instructions>
[승인된 모든 변경을 반영한 최종 instructions]
</final_instructions>
```
