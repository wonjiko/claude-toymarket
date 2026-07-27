# MCP Manager

MCP 서버 자동 연결 및 헬스체크 플러그인.

## 왜 존재하는지

세션 시작할 때마다 MCP 서버가 빠져있는지 수동으로 확인하기 번거롭다. 이 플러그인이 세션 시작 시 자동으로 MCP 상태를 체크하고 사용자 확인 후 누락된 서버를 등록한다.

## 동작 방식

세션 시작 시 `check-mcp.sh` 훅이 실행되어 MCP 상태를 확인한다.

### 훅 출력 해석 및 대응

훅 출력에 따라 다음과 같이 행동한다:

| 출력 | 의미 | 행동 |
|------|------|------|
| `MCP_CHECK: OK` | 모든 MCP 정상 | 아무것도 안 함 |
| `MCP_CHECK: MISSING_SERVERS` | MCP 누락 | 확인 후 등록 |
| `MCP_CHECK: NO_CONFIG` | 설정 파일 없음 | 무시 |

### 자동 수정

`MISSING_SERVERS` 발견 시 등록 전에 사용자에게 확인한다: "다음 MCP 서버가 누락되었습니다: {누락된 서버 목록}. 지금 등록할까요? (Y/n)"

사용자가 승인하면 다음 명령어로 등록:

```bash
claude mcp add --transport http figma https://mcp.figma.com/mcp
claude mcp add --transport http notion https://mcp.notion.com/mcp
claude mcp add --transport http slack https://server.smithery.ai/slack/mcp
```

등록 후 사용자에게 `/mcp`로 OAuth 인증이 필요할 수 있음을 안내.

## 관리 중인 MCP

| 이름 | URL | 타입 | 인증 |
|------|-----|------|------|
| figma | https://mcp.figma.com/mcp | HTTP | OAuth |
| notion | https://mcp.notion.com/mcp | HTTP | OAuth |
| slack | https://server.smithery.ai/slack/mcp | HTTP | OAuth (Smithery) |

## 명령어

- `/mcp-check`: 수동으로 MCP 상태 확인 및 수정
- `/mcp-fix`: 누락된 MCP 확인 후 등록

## 언제 쓰면 안 되는지

- MCP를 사용하지 않는 프로젝트
- 다른 MCP 관리 도구를 이미 사용 중인 경우
