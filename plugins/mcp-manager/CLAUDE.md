# MCP Manager

MCP 서버 자동 연결 및 헬스체크 플러그인.

## 동작 방식

세션 시작 시 `check-mcp.sh` 훅이 실행되어 MCP 상태를 확인한다.

### 훅 출력 해석 및 대응

훅 출력에 따라 다음과 같이 행동한다:

| 출력 | 의미 | 행동 |
|------|------|------|
| `MCP_CHECK: OK` | 모든 MCP 정상 | 아무것도 안 함 |
| `MCP_CHECK: MISSING_SERVERS` | MCP 누락 | 자동 등록 실행 |
| `MCP_CHECK: NO_CONFIG` | 설정 파일 없음 | 무시 |

### 자동 수정

`MISSING_SERVERS` 발견 시 다음 명령어로 자동 등록:

```bash
claude mcp add --transport http figma https://mcp.figma.com/mcp
```

등록 후 사용자에게 `/mcp`로 OAuth 인증이 필요할 수 있음을 안내.

## 관리 중인 MCP

| 이름 | URL | 타입 | 인증 |
|------|-----|------|------|
| figma | https://mcp.figma.com/mcp | HTTP | OAuth |
| notion | https://mcp.notion.com/mcp | HTTP | OAuth |
| slack | https://server.smithery.ai/slack/mcp | HTTP | OAuth (Smithery)

## 명령어

- `/mcp-check`: 수동으로 MCP 상태 확인 및 수정
- `/mcp-fix`: 누락된 MCP 강제 등록

## 안 쓸 때

- MCP를 사용하지 않는 프로젝트
- 다른 MCP 관리 도구를 이미 사용 중인 경우
