#!/bin/bash

echo ""
echo "=== MCP & CLI Setup ==="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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
if grep -q '"slack"' ~/.claude.json 2>/dev/null || grep -q '"slack"' .claude/settings.local.json 2>/dev/null; then
    echo -e "  ${GREEN}✓ 설치됨${NC}"
else
    echo "  ✗ 미설치"
    read -p "  설치? (l=로컬, g=글로벌, n=스킵): " choice
    case $choice in
        l) npx -y @smithery/cli@latest install slack --client claude-code ;;
        g) npx -y @smithery/cli@latest install slack --client claude-code -g ;;
    esac
fi

echo ""

# Notion MCP
echo -e "${YELLOW}[Notion MCP]${NC}"
if grep -q '"notion"' ~/.claude.json 2>/dev/null || grep -q '"notion"' .claude/settings.local.json 2>/dev/null; then
    echo -e "  ${GREEN}✓ 설치됨${NC}"
else
    echo "  ✗ 미설치"
    read -p "  설치? (l=로컬, g=글로벌, n=스킵): " choice
    case $choice in
        l) npx -y @smithery/cli@latest install notion --client claude-code ;;
        g) npx -y @smithery/cli@latest install notion --client claude-code -g ;;
    esac
fi

echo ""
echo "=== 완료 ==="
