#!/bin/bash
# MCP 헬스체크 스크립트
# SessionStart 훅에서 실행되어 MCP 상태를 확인

# 필요한 MCP 서버 목록 (이름|타입|URL 형식)
# stdio 타입은 URL 대신 명령어 사용
REQUIRED_MCPS=(
    "figma|http|https://mcp.figma.com/mcp"
    "notion|http|https://mcp.notion.com/mcp"
    "slack|http|https://server.smithery.ai/slack/mcp"
)

# 현재 등록된 MCP 서버 목록 가져오기
REGISTERED_MCPS=$(claude mcp list 2>/dev/null)

MISSING=""

for entry in "${REQUIRED_MCPS[@]}"; do
    IFS='|' read -r name type url <<< "$entry"

    if ! echo "$REGISTERED_MCPS" | grep -q "$name"; then
        MISSING="$MISSING $name"
    fi
done

# 결과 출력
if [ -n "$MISSING" ]; then
    echo "MCP_CHECK: MISSING_SERVERS"
    echo "MISSING:$MISSING"
    echo ""
    echo "ACTION_REQUIRED: 다음 MCP 서버를 등록해야 합니다."
    for entry in "${REQUIRED_MCPS[@]}"; do
        IFS='|' read -r name type cmd <<< "$entry"
        if echo "$MISSING" | grep -q "$name"; then
            if [ "$type" = "http" ]; then
                echo "  claude mcp add --transport http $name $cmd"
            else
                echo "  claude mcp add --transport stdio $name -- $cmd"
            fi
        fi
    done
else
    echo "MCP_CHECK: OK"
    echo "STATUS: 모든 MCP 서버가 정상 등록되어 있습니다."
fi
