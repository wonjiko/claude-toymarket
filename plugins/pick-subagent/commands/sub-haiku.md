---
name: sub-haiku
description: Haiku 모델 서브에이전트에게 작업 위임
argument-hint: <작업 내용>
allowed-tools: Agent
---

# /sub-haiku

사용자가 입력한 작업을 **Haiku 모델** 서브에이전트에게 위임한다.

## 동작

1. 인자로 받은 내용을 서브에이전트의 prompt로 전달
2. Agent 도구를 호출할 때 `model: "haiku"` 지정
3. 서브에이전트 결과를 사용자에게 요약 전달

## 규칙

- 인자가 없으면 어떤 작업을 위임할지 물어본다
- 서브에이전트에게 충분한 컨텍스트를 전달한다 (현재 작업 디렉토리, 관련 파일 경로 등)
- 결과는 간결하게 요약한다
