#!/bin/bash
# check-tracked.sh — verify that every expected plugin asset is git-tracked.
#
# Catches the failure mode where an unanchored .gitignore pattern silently
# excludes a plugin asset (e.g., `consume/` matching `skills/consume/`).
# Run before committing or releasing.

set -e

cd "$(dirname "$0")/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -d .git ]; then
  echo "Not a git repo; nothing to check."
  exit 0
fi

TRACKED_RAW="$(git ls-files)"

in_tracked() {
  local target="$1"
  printf '%s\n' "$TRACKED_RAW" | grep -qFx -- "$target"
}

missing=()
checked=0

check() {
  local f="$1"
  checked=$((checked + 1))
  if ! in_tracked "$f"; then
    missing+=("$f")
  fi
}

# Top-level required files
for f in README.md LICENSE .gitignore \
         .claude-plugin/plugin.json \
         .claude-plugin/required-permissions.json \
         hooks/hooks.json \
         hooks/log-search.sh; do
  check "$f"
done

# Every skill must have a SKILL.md
for d in skills/*/; do
  [ -d "$d" ] || continue
  check "${d}SKILL.md"
done

# Every directory below tracks .md / script files
for f in agents/*.md; do
  [ -f "$f" ] && check "$f"
done

for f in references/*.md; do
  [ -f "$f" ] && check "$f"
done

for f in tools/*.sh tools/*.py; do
  [ -f "$f" ] && check "$f"
done

echo ""
if [ ${#missing[@]} -eq 0 ]; then
  echo -e "${GREEN}OK${NC} — all $checked expected plugin assets are tracked."
  exit 0
else
  echo -e "${RED}FAIL${NC} — ${#missing[@]} expected asset(s) are NOT tracked:"
  for f in "${missing[@]}"; do
    echo "  - $f"
    if git check-ignore -v "$f" >/dev/null 2>&1; then
      reason=$(git check-ignore -v "$f" 2>/dev/null)
      echo -e "      ${YELLOW}ignored by:${NC} $reason"
    else
      echo -e "      ${YELLOW}reason:${NC} file exists but is not staged/tracked"
    fi
  done
  echo ""
  echo "Likely cause: an unanchored pattern in .gitignore is matching at depth."
  echo "Anchor specific top-level directories with a leading '/'."
  exit 1
fi
