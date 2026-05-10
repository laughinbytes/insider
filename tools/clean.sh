#!/bin/bash
# clean.sh — find and (optionally) remove cruft in user-output dirs.
#
# Usage:
#   tools/clean.sh                   (DRY-RUN: list candidates, no deletion)
#   tools/clean.sh --apply           (actually delete)
#   tools/clean.sh --quiet           (suppress per-file output, only summary)
#
# Allowlist per directory (anything NOT matching is a candidate):
#   reading/<slug>/   — index.html, numerics.json
#   research/<...>/   — *.md, meta.json
#   data/             — *.jsonl, *.json
#   .checkpoint/      — *.json, *.jsonl, README.md
#
# Always-cruft (deleted from anywhere): *.tmp, *.bak, *.old, *~, .DS_Store,
# __pycache__/, .backup/ subdirs.
#
# CWD-relative by default. Override with INSIDER_PROJECT_ROOT.

set -e

ROOT="${INSIDER_PROJECT_ROOT:-$(pwd)}"
APPLY=0
QUIET=0
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    --quiet) QUIET=1 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

GREEN=$(tput setaf 2 2>/dev/null || true)
YELLOW=$(tput setaf 3 2>/dev/null || true)
RED=$(tput setaf 1 2>/dev/null || true)
RESET=$(tput sgr0 2>/dev/null || true)

candidates=()
total_bytes=0

flag() {
  local path="$1"
  local reason="$2"
  candidates+=("$path|$reason")
  if [ -d "$path" ]; then
    bytes=$(du -sk "$path" 2>/dev/null | awk '{print $1*1024}')
  else
    bytes=$(stat -f%z "$path" 2>/dev/null || stat -c%s "$path" 2>/dev/null || echo 0)
  fi
  total_bytes=$((total_bytes + bytes))
}

# 1. reading/<slug>/ — anything not in allowlist
if [ -d "$ROOT/reading" ]; then
  for slug_dir in "$ROOT"/reading/*/; do
    [ -d "$slug_dir" ] || continue
    for f in "$slug_dir".[!.]* "$slug_dir"*; do
      [ -e "$f" ] || continue
      name=$(basename "$f")
      case "$name" in
        index.html|numerics.json) continue ;;
        .backup) flag "$f" "obsolete .backup/ snapshot" ;;
        *) flag "$f" "not in reading/<slug>/ allowlist (only index.html + numerics.json)" ;;
      esac
    done
  done
fi

# 2. research/<...>/ — non-{*.md, meta.json}
if [ -d "$ROOT/research" ]; then
  while IFS= read -r f; do
    name=$(basename "$f")
    case "$name" in
      *.md|meta.json) continue ;;
      *) flag "$f" "not in research/<slug>/ allowlist (only *.md + meta.json)" ;;
    esac
  done < <(find "$ROOT/research" -type f 2>/dev/null)
fi

# 3. data/ — non-{*.jsonl, *.json}
if [ -d "$ROOT/data" ]; then
  while IFS= read -r f; do
    name=$(basename "$f")
    case "$name" in
      *.jsonl|*.json) continue ;;
      *) flag "$f" "not in data/ allowlist (only *.jsonl + *.json)" ;;
    esac
  done < <(find "$ROOT/data" -maxdepth 1 -type f 2>/dev/null)
fi

# 4. .checkpoint/ — non-{*.json, *.jsonl, README.md}
if [ -d "$ROOT/.checkpoint" ]; then
  while IFS= read -r f; do
    name=$(basename "$f")
    case "$name" in
      *.json|*.jsonl|README.md) continue ;;
      *) flag "$f" "not in .checkpoint/ allowlist (only *.json + *.jsonl + README.md)" ;;
    esac
  done < <(find "$ROOT/.checkpoint" -type f 2>/dev/null)
fi

# 5. Always-cruft anywhere under user-output dirs
while IFS= read -r f; do
  flag "$f" "always-cruft pattern"
done < <(find "$ROOT/research" "$ROOT/data" "$ROOT/reading" "$ROOT/.checkpoint" \
  \( -name '*.tmp' -o -name '*.bak' -o -name '*.old' -o -name '*~' -o -name '.DS_Store' \) \
  -print 2>/dev/null)

# 6. __pycache__/ under tools/ (or anywhere reachable)
while IFS= read -r d; do
  flag "$d" "Python bytecode cache"
done < <(find "$ROOT" -type d -name '__pycache__' 2>/dev/null | grep -v '/.git/')

# 7. Empty reading/<slug>/ (no index.html)
if [ -d "$ROOT/reading" ]; then
  for slug_dir in "$ROOT"/reading/*/; do
    [ -d "$slug_dir" ] || continue
    if [ ! -f "$slug_dir/index.html" ]; then
      contents=$(ls -A "$slug_dir" 2>/dev/null | wc -l | tr -d ' ')
      if [ "$contents" -eq 0 ]; then
        flag "$slug_dir" "empty reading/<slug>/ (no index.html, pipeline likely never finished)"
      fi
    fi
  done
fi

# Output
echo ""
echo "Project root: $ROOT"
echo ""

if [ ${#candidates[@]} -eq 0 ]; then
  echo "${GREEN}OK${RESET} — no cruft found."
  exit 0
fi

human_size() {
  local bytes="$1"
  if [ "$bytes" -gt 1048576 ]; then
    awk -v b="$bytes" 'BEGIN { printf "%.1fM", b/1048576 }'
  elif [ "$bytes" -gt 1024 ]; then
    awk -v b="$bytes" 'BEGIN { printf "%.1fK", b/1024 }'
  else
    echo "${bytes}B"
  fi
}

if [ "$QUIET" -eq 0 ]; then
  for entry in "${candidates[@]}"; do
    path="${entry%%|*}"
    reason="${entry##*|}"
    echo "  $(echo "$path" | sed "s|$ROOT/||")  ${YELLOW}— $reason${RESET}"
  done
  echo ""
fi

count=${#candidates[@]}
size=$(human_size "$total_bytes")

if [ "$APPLY" -eq 0 ]; then
  echo "${YELLOW}DRY-RUN${RESET}: would remove $count item(s), freeing ~$size."
  echo "Re-run with ${GREEN}--apply${RESET} to actually delete."
  exit 0
fi

echo "${RED}APPLYING${RESET} — deleting $count item(s)..."
deleted=0
for entry in "${candidates[@]}"; do
  path="${entry%%|*}"
  if [ -d "$path" ]; then
    rm -rf "$path" && deleted=$((deleted + 1))
  else
    rm -f "$path" && deleted=$((deleted + 1))
  fi
done
echo "${GREEN}OK${RESET} — deleted $deleted/$count item(s), freed ~$size."
