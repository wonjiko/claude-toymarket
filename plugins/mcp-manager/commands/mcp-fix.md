---
description: 누락된 MCP 서버 자동 등록
allowed-tools:
  - Bash
---

누락된 MCP 서버를 자동으로 등록한다.

## MCP 등록 명령

Figma MCP 등록:
```bash
claude mcp add --transport http figma https://mcp.figma.com/mcp
```

## 절차

1. 위 명령어를 실행해서 MCP 등록
2. 등록 성공 여부 확인
3. 사용자에게 `/mcp`로 OAuth 인증 완료하라고 안내

## 주의

- 이미 등록된 MCP를 다시 등록하면 에러 발생할 수 있음
- 먼저 `/mcp-check`로 상태 확인 권장
