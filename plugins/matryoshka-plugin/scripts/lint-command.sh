#!/bin/bash
# Command file linter
# Usage: ./scripts/lint-command.sh <command-file.md>
#        ./scripts/lint-command.sh commands/  (all files in directory)

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

  # extract frontmatter
  local frontmatter
  if [[ -n "$fm_end" ]]; then
    frontmatter=$(sed -n "2,$((fm_end - 1))p" "$file")
  else
    frontmatter=""
  fi

  # description field (required)
  local desc
  desc=$(echo "$frontmatter" | grep -m1 "^description:" | sed 's/description: *//' || true)
  if [[ -z "$desc" ]]; then
    echo -e "${RED}x missing 'description' field${NC}"
    errors=$((errors + 1))
  elif [[ "$desc" == '""' ]] || [[ "$desc" == "''" ]] || [[ -z "${desc// }" ]]; then
    echo -e "${RED}x description is empty${NC}"
    errors=$((errors + 1))
  else
    echo -e "${GREEN}v description: $desc${NC}"
  fi

  # argument-hint field (optional)
  local hint
  hint=$(echo "$frontmatter" | grep -m1 "^argument-hint:" | sed 's/argument-hint: *//' || true)
  if [[ -n "$hint" ]]; then
    echo -e "${GREEN}v argument-hint: $hint${NC}"
  fi

  # allowed-tools field (optional)
  local tools
  tools=$(echo "$frontmatter" | grep -m1 "^allowed-tools:" || true)
  if [[ -n "$tools" ]]; then
    echo -e "${GREEN}v allowed-tools defined${NC}"
  fi

  # model field (optional)
  local model
  model=$(echo "$frontmatter" | grep -m1 "^model:" | sed 's/model: *//' || true)
  if [[ -n "$model" ]]; then
    if ! echo "$model" | grep -qE "^(haiku|sonnet|opus)$"; then
      echo -e "${YELLOW}! unknown model: '$model' (haiku|sonnet|opus)${NC}"
      warnings=$((warnings + 1))
    else
      echo -e "${GREEN}v model: $model${NC}"
    fi
  fi

  # body content check
  if [[ -n "$fm_end" ]]; then
    local body chars
    body=$(tail -n +"$((fm_end + 1))" "$file")
    chars=$(echo "$body" | wc -c | tr -d ' ')

    if [[ "$chars" -lt 50 ]]; then
      echo -e "${YELLOW}! body content very short: ${chars} chars${NC}"
      warnings=$((warnings + 1))
    else
      echo -e "${GREEN}v body: ${chars} chars${NC}"
    fi
  fi

  # filename check (should be lowercase with hyphens)
  local filename
  filename=$(basename "$file" .md)
  if ! echo "$filename" | grep -qE "^[a-z][a-z0-9-]*$"; then
    echo -e "${YELLOW}! filename should be lowercase-hyphens: '$filename'${NC}"
    warnings=$((warnings + 1))
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
    echo "Usage: $0 <command-file.md | commands-directory>"
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
