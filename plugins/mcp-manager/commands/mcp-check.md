---
name: mcp-check
description: MCP 서버 상태 확인 및 확인 후 수정
allowed-tools:
  - Bash
  - Read
---

MCP 서버 상태를 확인하고 문제가 있으면 사용자 확인 후 수정한다.

## 확인 절차

1. `claude mcp list` 실행해서 현재 등록된 MCP 확인
2. 플러그인의 `.mcp.json` 파일과 비교
3. 누락된 MCP가 있으면 사용자에게 등록 여부를 확인한 뒤 등록

## 필수 MCP 목록

이 플러그인에서 관리하는 MCP:
- **figma**: `https://mcp.figma.com/mcp` (HTTP)
- **notion**: `https://mcp.notion.com/mcp` (HTTP)
- **slack**: `https://server.smithery.ai/slack/mcp` (HTTP)

## 확인 후 수정

누락된 MCP 발견 시 다음을 사용자에게 보여주고 등록해도 될지 확인한다: "다음 MCP 서버가 누락되었습니다: {목록}. 지금 등록할까요? (Y/n)"

승인 시 다음 명령어로 등록:

```bash
claude mcp add --transport http figma https://mcp.figma.com/mcp
claude mcp add --transport http notion https://mcp.notion.com/mcp
claude mcp add --transport http slack https://server.smithery.ai/slack/mcp
```

## 인증 안내

HTTP MCP 서버(figma, notion, slack)는 OAuth 인증이 필요할 수 있다.
등록 후 `/mcp` 명령어로 인증 상태를 확인하고, 필요시 사용자에게 인증을 안내한다.

## 실행

!`${CLAUDE_PLUGIN_ROOT}/hooks/check-mcp.sh`

위 결과에 따라:
- `MCP_CHECK: OK` → "모든 MCP 정상"이라고 알림
- `MCP_CHECK: MISSING_SERVERS` → 누락된 서버를 사용자에게 확인받은 뒤 등록 시도, 결과 보고
