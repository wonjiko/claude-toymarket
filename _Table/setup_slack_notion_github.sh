#!/bin/bash

echo ""
echo "=== MCP & CLI Setup ==="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
NC='\033[0m'

echo -e "${GRAY}MCP 서버는 현재 경로에 설치됩니다: $(pwd)${NC}"
echo ""

# MCP 서버 목록 캐시
MCP_LIST=$(claude mcp list 2>/dev/null)

# GitHub CLI
echo -e "${YELLOW}[GitHub CLI]${NC}"
if command -v gh &> /dev/null; then
    echo -e "  ${GREEN}✓ 설치됨${NC}"
else
    echo "  ✗ 미설치"
    read -p "  설치? (y/n): " choice
    [ "$choice" = "y" ] && brew install gh
fi

echo ""

# Slack MCP
echo -e "${YELLOW}[Slack MCP]${NC}"
if echo "$MCP_LIST" | grep -qi "slack"; then
    echo -e "  ${GREEN}✓ 설치됨${NC}"
else
    echo "  ✗ 미설치"
    read -p "  설치? (y/n): " choice
    [ "$choice" = "y" ] && npx -y @smithery/cli@latest install slack --client claude-code
fi

echo ""

# Notion MCP
echo -e "${YELLOW}[Notion MCP]${NC}"
if echo "$MCP_LIST" | grep -qi "notion"; then
    echo -e "  ${GREEN}✓ 설치됨${NC}"
else
    echo "  ✗ 미설치"
    read -p "  설치? (y/n): " choice
    [ "$choice" = "y" ] && npx -y @smithery/cli@latest install notion --client claude-code
fi

echo ""
echo "=== 완료 ==="
