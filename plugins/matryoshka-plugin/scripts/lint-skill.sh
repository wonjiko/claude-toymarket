#!/bin/bash
# Skill file linter
# Usage: ./scripts/lint-skill.sh <SKILL.md>
#        ./scripts/lint-skill.sh skills/  (all skills in directory)

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

  # filename must be SKILL.md
  local filename
  filename=$(basename "$file")
  if [[ "$filename" != "SKILL.md" ]]; then
    echo -e "${RED}x filename must be 'SKILL.md', got '$filename'${NC}"
    errors=$((errors + 1))
  else
    echo -e "${GREEN}v filename: SKILL.md${NC}"
  fi

  # folder structure: skills/[name]/SKILL.md
  local dirpath
  dirpath=$(dirname "$file")
  local dirname
  dirname=$(basename "$dirpath")
  local parentdir
  parentdir=$(basename "$(dirname "$dirpath")")

  if [[ "$parentdir" != "skills" ]]; then
    echo -e "${YELLOW}! expected path: skills/[name]/SKILL.md${NC}"
    warnings=$((warnings + 1))
  else
    echo -e "${GREEN}v path: skills/$dirname/SKILL.md${NC}"
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

  # name field (required)
  local name
  name=$(echo "$frontmatter" | grep -m1 "^name:" | sed 's/name: *//' || true)
  if [[ -z "$name" ]]; then
    echo -e "${RED}x missing 'name' field${NC}"
    errors=$((errors + 1))
  else
    echo -e "${GREEN}v name: $name${NC}"
  fi

  # description field (required, should start with "This skill should be used when")
  local desc
  desc=$(echo "$frontmatter" | grep -m1 "^description:" || true)
  if [[ -z "$desc" ]]; then
    echo -e "${RED}x missing 'description' field${NC}"
    errors=$((errors + 1))
  elif ! echo "$desc" | grep -q "This skill should be used when"; then
    echo -e "${YELLOW}! description should start with 'This skill should be used when'${NC}"
    warnings=$((warnings + 1))
  else
    echo -e "${GREEN}v description format OK${NC}"
  fi

  # version field (required, semver format)
  local version
  version=$(echo "$frontmatter" | grep -m1 "^version:" | sed 's/version: *//' || true)
  if [[ -z "$version" ]]; then
    echo -e "${RED}x missing 'version' field${NC}"
    errors=$((errors + 1))
  elif ! echo "$version" | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+"; then
    echo -e "${YELLOW}! version should be semver format: '$version'${NC}"
    warnings=$((warnings + 1))
  else
    echo -e "${GREEN}v version: $version${NC}"
  fi

  # body content check
  if [[ -n "$fm_end" ]]; then
    local body chars
    body=$(tail -n +"$((fm_end + 1))" "$file")
    chars=$(echo "$body" | wc -c | tr -d ' ')

    if [[ "$chars" -lt 100 ]]; then
      echo -e "${YELLOW}! body content very short: ${chars} chars${NC}"
      warnings=$((warnings + 1))
    else
      echo -e "${GREEN}v body: ${chars} chars${NC}"
    fi
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
    echo "Usage: $0 <SKILL.md | skills-directory>"
    exit 1
  fi

  local target="$1"
  local failed=0
  local total=0

  if [[ -d "$target" ]]; then
    # find all SKILL.md files in subdirectories
    while IFS= read -r -d '' file; do
      echo ""
      total=$((total + 1))
      if ! lint_file "$file"; then
        failed=$((failed + 1))
      fi
    done < <(find "$target" -name "SKILL.md" -print0)

    if [[ $total -eq 0 ]]; then
      echo "No SKILL.md files found in $target"
      exit 0
    fi

    echo ""
    echo "========"
    echo "Total: $total files, $failed failed"
    [[ $failed -eq 0 ]] && exit 0 || exit 1
  else
    lint_file "$target"
  fi
}

main "$@"
