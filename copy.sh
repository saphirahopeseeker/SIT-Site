#!/usr/bin/env bash
set -euo pipefail

SRC="../SimpleInventoryTracker/site"

abspath() {
  local p=$1 dir
  [ -e "$p" ] || { printf 'abspath: missing: %s\n' "$p" >&2; return 1; }
  if [ -d "$p" ]; then
    ( cd -- "$p" && pwd -P )
  else
    dir=$(cd -- "$(dirname -- "$p")" && pwd -P) || return 1
    printf '%s/%s\n' "${dir%/}" "$(basename -- "$p")"
  fi
}

SRC_ABS=$(abspath "$SRC") || { printf 'bad source: %s\n' "$SRC" >&2; exit 1; }

SRC_ROOT=$(git -C "$SRC_ABS" rev-parse --show-toplevel 2>/dev/null) \
  || { printf 'not a git repo: %s\n' "$SRC_ABS" >&2; exit 1; }

BRANCH=$(git -C "$SRC_ABS" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
[ "$BRANCH" = "HEAD" ] && BRANCH="(detached HEAD — no branch)"

SHA=$(git -C "$SRC_ABS" rev-parse --short HEAD 2>/dev/null || printf 'no commits')
DIRTY=$(git -C "$SRC_ABS" status --porcelain | wc -l | tr -d ' ')
UPSTREAM=$(git -C "$SRC_ABS" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || printf 'none')
BEHIND_AHEAD=$(git -C "$SRC_ABS" rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null \
  || printf 'n/a\t')

printf '%-12s %s\n' \
  'Repo root'  "$SRC_ROOT" \
  'Copy from'  "$SRC_ABS" \
  'Branch'     "$BRANCH" \
  'Commit'     "$SHA" \
  'Dirty'      "$DIRTY file(s)" \
  'Upstream'   "$UPSTREAM" \
  'Behind/ahead' "$BEHIND_AHEAD"

printf '\nProceed with copy into %s? [y/N] ' "$PWD"
ans=
read -r ans || ans=
case $ans in
  y|Y) printf 'Proceeding.\n' ;;
  *)   printf 'Aborted.\n'; exit 1 ;;
esac

rm -rf ./src
mkdir src

cp -a "${SRC_ABS}/." src/. 

git commit -a -m "Commit and push @ $(date +%Y%m%d-%H%M%S)"
git push