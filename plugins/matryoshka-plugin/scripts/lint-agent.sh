#!/bin/bash
# Agent file linter
# Usage: ./scripts/lint-agent.sh <agent-file.md>
#        ./scripts/lint-agent.sh agents/  (all files in directory)

set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

lint_file() {
  local file="$1"
  local errors=0
  local warnings=0

  echo "Linting: $file"
  echo "---"

  if [[ ! -f "$file" ]]; then
    echo -e "${RED}x file not found${NC}"
    return 1
  fi

  # frontmatter start
  if ! head -1 "$file" | grep -q "^---$"; then
    echo -e "${RED}x missing frontmatter start '---'${NC}"
    errors=$((errors + 1))
  fi

  # frontmatter end (second ---)
  local fm_end
  fm_end=$(awk '/^---$/{count++; if(count==2) print NR}' "$file")
  if [[ -z "$fm_end" ]]; then
    echo -e "${RED}x missing frontmatter end '---'${NC}"
    errors=$((errors + 1))
  fi

  # name field
  local name
  name=$(grep -m1 "^name:" "$file" | sed 's/name: *//' || true)
  if [[ -z "$name" ]]; then
    echo -e "${RED}x missing 'name' field${NC}"
    errors=$((errors + 1))
  elif ! echo "$name" | grep -qE "^[a-z][a-z0-9-]*$"; then
    echo -e "${RED}x invalid name format: '$name' (use lowercase-hyphens)${NC}"
    errors=$((errors + 1))
  else
    echo -e "${GREEN}v name: $name${NC}"
  fi

  # description field
  local desc
  desc=$(grep -m1 "^description:" "$file" || true)
  if [[ -z "$desc" ]]; then
    echo -e "${RED}x missing 'description' field${NC}"
    errors=$((errors + 1))
  elif ! echo "$desc" | grep -q "Use this agent when"; then
    echo -e "${YELLOW}! description should start with 'Use this agent when'${NC}"
    warnings=$((warnings + 1))
  else
    echo -e "${GREEN}v description format OK${NC}"
  fi

  # extract frontmatter content (between first and second ---)
  local frontmatter
  if [[ -n "$fm_end" ]]; then
    frontmatter=$(sed -n "2,$((fm_end - 1))p" "$file")
  else
    frontmatter=""
  fi

  # example blocks count (in frontmatter only)
  local examples
  examples=$(echo "$frontmatter" | grep -c "<example>" || echo 0)
  if [[ "$examples" -lt 2 ]]; then
    echo -e "${RED}x need 2+ examples, got $examples${NC}"
    errors=$((errors + 1))
  else
    echo -e "${GREEN}v examples: $examples${NC}"
  fi

  # example structure (in frontmatter only)
  local contexts commentaries
  contexts=$(echo "$frontmatter" | grep -c "Context:" 2>/dev/null || echo 0)
  commentaries=$(echo "$frontmatter" | grep -c "<commentary>" 2>/dev/null || echo 0)

  if [[ "$contexts" -lt "$examples" ]]; then
    echo -e "${YELLOW}! some examples missing Context${NC}"
    warnings=$((warnings + 1))
  fi
  if [[ "$commentaries" -lt "$examples" ]]; then
    echo -e "${YELLOW}! some examples missing commentary${NC}"
    warnings=$((warnings + 1))
  fi

  # system prompt length (after frontmatter)
  if [[ -n "$fm_end" ]]; then
    local body chars
    body=$(tail -n +"$((fm_end + 1))" "$file")
    chars=$(echo "$body" | wc -c | tr -d ' ')

    if [[ "$chars" -lt 500 ]]; then
      echo -e "${RED}x system prompt too short: ${chars} chars (min 500)${NC}"
      errors=$((errors + 1))
    else
      echo -e "${GREEN}v system prompt: ${chars} chars${NC}"
    fi
  fi

  # model field (optional)
  local model
  model=$(grep -m1 "^model:" "$file" | sed 's/model: *//' || true)
  if [[ -n "$model" ]]; then
    if ! echo "$model" | grep -qE "^(inherit|sonnet|haiku|opus)$"; then
      echo -e "${YELLOW}! unknown model: '$model' (inherit|sonnet|haiku|opus)${NC}"
      warnings=$((warnings + 1))
    else
      echo -e "${GREEN}v model: $model${NC}"
    fi
  fi

  # tools field (optional)
  local tools
  tools=$(grep -m1 "^tools:" "$file" || true)
  if [[ -n "$tools" ]]; then
    echo -e "${GREEN}v tools defined${NC}"
  fi

  echo "---"

  if [[ $errors -gt 0 ]]; then
    echo -e "${RED}FAILED: $errors errors, $warnings warnings${NC}"
    return 1
  elif [[ $warnings -gt 0 ]]; then
    echo -e "${YELLOW}PASSED with $warnings warnings${NC}"
    return 0
  else
    echo -e "${GREEN}PASSED${NC}"
    return 0
  fi
}

main() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <agent-file.md | agents-directory>"
    exit 1
  fi

  local target="$1"
  local failed=0
  local total=0

  if [[ -d "$target" ]]; then
    for file in "$target"/*.md; do
      [[ -f "$file" ]] || continue
      echo ""
      total=$((total + 1))
      if ! lint_file "$file"; then
        failed=$((failed + 1))
      fi
    done

    echo ""
    echo "========"
    echo "Total: $total files, $failed failed"
    [[ $failed -eq 0 ]] && exit 0 || exit 1
  else
    lint_file "$target"
  fi
}

main "$@"
