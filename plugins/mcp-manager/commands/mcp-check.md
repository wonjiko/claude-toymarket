---
description: MCP 서버 상태 확인 및 자동 수정
allowed-tools:
  - Bash
  - Read
---

MCP 서버 상태를 확인하고 문제가 있으면 자동으로 수정한다.

## 확인 절차

1. `claude mcp list` 실행해서 현재 등록된 MCP 확인
2. 플러그인의 `.mcp.json` 파일과 비교
3. 누락된 MCP가 있으면 자동 등록

## 필수 MCP 목록

이 플러그인에서 관리하는 MCP:
- **figma**: `https://mcp.figma.com/mcp` (HTTP)

## 자동 수정

누락된 MCP 발견 시:
```bash
claude mcp add --transport http figma https://mcp.figma.com/mcp
```

## 인증 안내

HTTP MCP 서버(figma 등)는 OAuth 인증이 필요할 수 있다.
등록 후 `/mcp` 명령어로 인증 상태를 확인하고, 필요시 사용자에게 인증을 안내한다.

## 실행

!`${CLAUDE_PLUGIN_ROOT}/hooks/check-mcp.sh`

위 결과에 따라:
- `MCP_CHECK: OK` → "모든 MCP 정상"이라고 알림
- `MCP_CHECK: MISSING_SERVERS` → 누락된 서버 자동 등록 시도 후 결과 보고
