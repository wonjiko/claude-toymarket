#!/usr/bin/env bash
# jupiter GitHub 릴리즈별로 config.py에 박힌 엔진 태그를 뽑는다.
# 출력: TSV — tag / 발행시각(KST) / carta-core / pix4d-core / changed
set -uo pipefail

REPO="${1:-.}"
LIMIT="${2:-100}"
CONFIG="app/core/config.py"

cd "$REPO" || { echo "저장소 경로를 찾을 수 없다: $REPO" >&2; exit 1; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "git 저장소가 아니다: $REPO" >&2; exit 1; }

git fetch --tags -q origin 2>/dev/null || true

extract() {  # $1=config 본문, $2=변수명 → PROD/STAGING 값. 다르면 "prod|stg"
  local vals
  vals=$(printf '%s' "$1" | grep -E "^ +${2}=\"" | sed 's/.*"\(.*\)".*/\1/')
  local prod stg
  prod=$(printf '%s' "$vals" | sed -n '1p')
  stg=$(printf '%s' "$vals" | sed -n '2p')
  if [ -z "$prod" ]; then echo "-"
  elif [ "$prod" = "$stg" ] || [ -z "$stg" ]; then echo "$prod"
  else echo "${prod}|${stg}"
  fi
}

printf 'tag\tpublished_kst\tcarta_core\tpix4d_core\tchanged\n'

prev_m=""; prev_p=""
gh release list -L "$LIMIT" --json tagName,publishedAt \
  -q '.[] | [.tagName, .publishedAt] | @tsv' | sort -t"$(printf '\t')" -k2 |
while IFS=$'\t' read -r tag published; do
  cfg=$(git show "${tag}:${CONFIG}" 2>/dev/null)
  if [ -z "$cfg" ]; then
    m="?"; p="?"
  else
    m=$(extract "$cfg" ENGINE_MEISSA_V2_TAG)
    p=$(extract "$cfg" ENGINE_PIX4D_V2_TAG)
  fi

  epoch=$(TZ=UTC date -jf '%Y-%m-%dT%H:%M:%SZ' "$published" '+%s' 2>/dev/null)
  kst=$([ -n "$epoch" ] && date -r "$epoch" '+%Y-%m-%d %H:%M' || echo "$published")

  changed=""
  [ -n "$prev_m" ] && [ "$m" != "$prev_m" ] && changed="carta-core"
  if [ -n "$prev_p" ] && [ "$p" != "$prev_p" ]; then
    changed="${changed:+$changed,}pix4d-core"
  fi
  [ -z "$prev_m" ] && changed="최초"

  printf '%s\t%s\t%s\t%s\t%s\n' "$tag" "$kst" "$m" "$p" "${changed:--}"
  prev_m="$m"; prev_p="$p"
done
