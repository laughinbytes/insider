#!/bin/bash
# Open consume HTML in default browser
# Usage: ./tools/open.sh <slug>

set -e

SLUG="$1"

if [ -z "$SLUG" ]; then
  echo "Usage: ./tools/open.sh <slug>"
  echo "Example: ./tools/open.sh semiconductor-capital-equipment"
  exit 1
fi

HTML_FILE="$(dirname "$0")/../consume/${SLUG}/index.html"

if [ ! -f "$HTML_FILE" ]; then
  echo "No consume HTML found for: ${SLUG}"
  echo "Expected: ${HTML_FILE}"
  echo ""
  echo "Available slugs:"
  ls -1 "$(dirname "$0")/../consume/" 2>/dev/null || echo "  (none)"
  exit 1
fi

open "$HTML_FILE"
echo "Opened: ${HTML_FILE}"
