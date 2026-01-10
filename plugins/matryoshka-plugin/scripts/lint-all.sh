#!/bin/bash
# Lint all plugin components (agents, commands, skills)
# Usage: ./scripts/lint-all.sh

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

failed=0

echo -e "${BOLD}=== Linting Agents ===${NC}"
if [[ -d "$PLUGIN_DIR/agents" ]]; then
  "$SCRIPT_DIR/lint-agent.sh" "$PLUGIN_DIR/agents" || failed=$((failed + 1))
else
  echo "No agents/ directory"
fi

echo ""
echo -e "${BOLD}=== Linting Commands ===${NC}"
if [[ -d "$PLUGIN_DIR/commands" ]]; then
  "$SCRIPT_DIR/lint-command.sh" "$PLUGIN_DIR/commands" || failed=$((failed + 1))
else
  echo "No commands/ directory"
fi

echo ""
echo -e "${BOLD}=== Linting Skills ===${NC}"
if [[ -d "$PLUGIN_DIR/skills" ]]; then
  "$SCRIPT_DIR/lint-skill.sh" "$PLUGIN_DIR/skills" || failed=$((failed + 1))
else
  echo "No skills/ directory"
fi

echo ""
echo "========================================"
if [[ $failed -eq 0 ]]; then
  echo -e "${GREEN}All checks passed${NC}"
  exit 0
else
  echo -e "${RED}$failed component type(s) had failures${NC}"
  exit 1
fi
