#!/usr/bin/env bash
# jupiter GitHub 릴리즈별로 config.py에 박힌 엔진 태그를 뽑는다.
# 출력: TSV — tag / 발행시각(KST) / carta-core / pix4d-core / changed
set -uo pipefail

REPO="${1:-.}"
LIMIT="${2:-500}"
CONFIG="app/core/config.py"

cd "$REPO" || { echo "저장소 경로를 찾을 수 없다: $REPO" >&2; exit 1; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "git 저장소가 아니다: $REPO" >&2; exit 1; }

git fetch --tags -q origin 2>/dev/null || true

# PRODUCTION / STAGING 블록의 할당만 읽는다. 다른 프로필과 타입 어노테이션이 붙은
# 기본값 선언(`NAME: str = "latest"`)은 제외된다.
extract() {  # $1=config 본문, $2=변수명
  local vals uniq n
  vals=$(printf '%s' "$1" | awk -v name="$2" '
    /current_config.upper\(\) *== *"/ {
      profile = "OTHER"
      if ($0 ~ /"PRODUCTION"/ || $0 ~ /"STAGING"/) profile = "TARGET"
      next
    }
    profile == "TARGET" && $0 ~ name "[[:space:]]*=[[:space:]]*[\"'"'"']" {
      if (match($0, /[\"'"'"'][^\"'"'"']*[\"'"'"'][[:space:]]*,?[[:space:]]*$/)) {
        v = substr($0, RSTART + 1, RLENGTH - 2)
        gsub(/[\"'"'"'][[:space:]]*,?[[:space:]]*$/, "", v)
        print v
      }
    }')
  [ -z "$vals" ] && { echo "-"; return; }
  uniq=$(printf '%s\n' "$vals" | sort -u)
  n=$(printf '%s\n' "$uniq" | grep -c .)
  if [ "$n" -eq 1 ]; then printf '%s' "$uniq"
  else printf '%s' "$vals" | paste -sd'/' -   # PRODUCTION과 STAGING 값이 다르다
  fi
}

to_kst() {  # $1=ISO8601 UTC
  local epoch
  epoch=$(TZ=UTC date -jf '%Y-%m-%dT%H:%M:%SZ' "$1" '+%s' 2>/dev/null) ||
  epoch=$(date -u -d "$1" '+%s' 2>/dev/null) ||
  { printf '%s' "$1"; return; }
  TZ=Asia/Seoul date -r "$epoch" '+%Y-%m-%d %H:%M' 2>/dev/null ||
  TZ=Asia/Seoul date -d "@$epoch" '+%Y-%m-%d %H:%M' 2>/dev/null ||
  printf '%s' "$1"
}

releases=$(gh release list -L "$LIMIT" --exclude-drafts --json tagName,publishedAt \
           -q '.[] | select(.publishedAt != null and .publishedAt != "") | [.tagName, .publishedAt] | @tsv' \
           | sort -t"$(printf '\t')" -k2)

[ -z "$releases" ] && { echo "릴리즈를 찾을 수 없다" >&2; exit 1; }

count=$(printf '%s\n' "$releases" | grep -c .)
[ "$count" -ge "$LIMIT" ] && echo "경고: 릴리즈 ${LIMIT}건 상한에 도달했다. 더 오래된 릴리즈가 잘렸을 수 있다." >&2

printf 'tag\tpublished_kst\tcarta_core\tpix4d_core\tchanged\n'

prev_m=""; prev_p=""; first=1
while IFS=$'\t' read -r tag published; do
  cfg=$(git show "${tag}:${CONFIG}" 2>/dev/null)
  if [ -z "$cfg" ]; then m="?"; p="?"
  else
    m=$(extract "$cfg" ENGINE_MEISSA_V2_TAG)
    p=$(extract "$cfg" ENGINE_PIX4D_V2_TAG)
  fi

  if [ "$first" = 1 ]; then
    changed="기준"; first=0
  else
    changed=""
    [ "$m" != "$prev_m" ] && changed="carta-core"
    [ "$p" != "$prev_p" ] && changed="${changed:+$changed,}pix4d-core"
    changed="${changed:--}"
  fi

  printf '%s\t%s\t%s\t%s\t%s\n' "$tag" "$(to_kst "$published")" "$m" "$p" "$changed"
  prev_m="$m"; prev_p="$p"
done <<< "$releases"
