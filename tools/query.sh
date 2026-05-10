#!/bin/bash
#
# Query the structured data layer.
# Usage:
#   ./tools/query.sh claims --project ai-coding-assistants
#   ./tools/query.sh claims --entity Cursor --confidence high
#   ./tools/query.sh sources --status dead
#   ./tools/query.sh entities --type company
#   ./tools/query.sh metrics --entity Cursor --metric ARR
#   ./tools/query.sh contradicts --entity Cursor --metric ARR
#   ./tools/query.sh webfetch-failures --error-type timeout
#   ./tools/query.sh webfetch-failures --domain sec.gov
#   ./tools/query.sh webfetch-failures --stats

set -e

ROOT="${INSIDER_PROJECT_ROOT:-$(pwd)}"
DATA_DIR="${DATA_DIR:-$ROOT/data}"
CHECKPOINT_DIR="${CHECKPOINT_DIR:-$ROOT/.checkpoint}"
COMMAND="$1"
shift

# Parse flags
PROJECT=""
ENTITY=""
CONFIDENCE=""
STATUS=""
TYPE=""
METRIC=""
FILE=""
SECTION=""
TAG=""
ERROR_TYPE=""
DOMAIN=""
PHASE=""
LIMIT=50

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --entity) ENTITY="$2"; shift 2 ;;
    --confidence) CONFIDENCE="$2"; shift 2 ;;
    --status) STATUS="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    --metric) METRIC="$2"; shift 2 ;;
    --file) FILE="$2"; shift 2 ;;
    --section) SECTION="$2"; shift 2 ;;
    --tag) TAG="$2"; shift 2 ;;
    --error-type) ERROR_TYPE="$2"; shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
    --phase) PHASE="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

build_filter() {
  local filter="."
  [[ -n "$PROJECT" ]] && filter="$filter | select(.project_slug == \"$PROJECT\")"
  [[ -n "$ENTITY" ]] && filter="$filter | select(.entities | contains([\"$ENTITY\"]))"
  [[ -n "$CONFIDENCE" ]] && filter="$filter | select(.confidence == \"$CONFIDENCE\")"
  [[ -n "$STATUS" ]] && filter="$filter | select(.status == \"$STATUS\")"
  [[ -n "$TYPE" ]] && filter="$filter | select(.type == \"$TYPE\")"
  [[ -n "$METRIC" ]] && filter="$filter | select(.metric == \"$METRIC\")"
  [[ -n "$FILE" ]] && filter="$filter | select(.file == \"$FILE\")"
  [[ -n "$SECTION" ]] && filter="$filter | select(.section == \"$SECTION\")"
  [[ -n "$TAG" ]] && filter="$filter | select(.tags | contains([\"$TAG\"]))"
  echo "$filter"
}

case "$COMMAND" in
  claims)
    if [[ ! -f "$DATA_DIR/claims.jsonl" ]]; then
      echo "No claims data yet."
      exit 0
    fi
    FILTER=$(build_filter)
    jq -c "$FILTER" "$DATA_DIR/claims.jsonl" | head -n "$LIMIT" | jq -s '.'
    ;;

  sources)
    if [[ ! -f "$DATA_DIR/sources.jsonl" ]]; then
      echo "No sources data yet."
      exit 0
    fi
    FILTER=$(build_filter)
    jq -c "$FILTER" "$DATA_DIR/sources.jsonl" | head -n "$LIMIT" | jq -s '.'
    ;;

  entities)
    if [[ ! -f "$DATA_DIR/entities.json" ]]; then
      echo "No entities data yet."
      exit 0
    fi
    FILTER=".entities[]"
    [[ -n "$TYPE" ]] && FILTER="$FILTER | select(.type == \"$TYPE\")"
    [[ -n "$ENTITY" ]] && FILTER="$FILTER | select(.name == \"$ENTITY\" or (.aliases | contains([\"$ENTITY\"])))"
    jq "$FILTER" "$DATA_DIR/entities.json" | jq -s '.'
    ;;

  metrics)
    if [[ ! -f "$DATA_DIR/metrics.jsonl" ]]; then
      echo "No metrics data yet."
      exit 0
    fi
    FILTER=$(build_filter)
    jq -c "$FILTER" "$DATA_DIR/metrics.jsonl" | head -n "$LIMIT" | jq -s '.'
    ;;

  contradicts)
    if [[ ! -f "$DATA_DIR/claims.jsonl" ]]; then
      echo "No claims data yet."
      exit 0
    fi
    # Find claims about the same entity+metric with different values
    if [[ -z "$ENTITY" || -z "$METRIC" ]]; then
      echo "Usage: query.sh contradicts --entity <name> --metric <metric>"
      exit 1
    fi
    jq -c "select(.entities | contains([\"$ENTITY\"])) | select(.tags | contains([\"$METRIC\"]))" "$DATA_DIR/claims.jsonl" | \
      jq -s 'group_by(.claim) | map(select(length > 1)) | .[]'
    ;;

  stale)
    if [[ ! -f "$DATA_DIR/claims.jsonl" ]]; then
      echo "No claims data yet."
      exit 0
    fi
    TODAY=$(date +%Y-%m-%d)
    FILTER="select(.stale_after != null and .stale_after < \"$TODAY\")"
    [[ -n "$PROJECT" ]] && FILTER="$FILTER | select(.project_slug == \"$PROJECT\")"
    jq -c "$FILTER" "$DATA_DIR/claims.jsonl" | head -n "$LIMIT" | jq -s '.'
    ;;

  webfetch-failures)
    LOG_FILE="$CHECKPOINT_DIR/webfetch-failures.jsonl"
    if [[ ! -f "$LOG_FILE" ]]; then
      echo "No WebFetch failure logs yet."
      exit 0
    fi
    if [[ "$1" == "--stats" ]]; then
      echo "=== WebFetch Failure Stats ==="
      TOTAL=$(wc -l < "$LOG_FILE" | tr -d ' ')
      echo "Total failures: $TOTAL"
      echo ""
      echo "By error type:"
      jq -r '.error_type' "$LOG_FILE" | sort | uniq -c | sort -rn
      echo ""
      echo "By domain:"
      jq -r '.domain' "$LOG_FILE" | sort | uniq -c | sort -rn | head -20
      echo ""
      echo "By phase:"
      jq -r '.phase' "$LOG_FILE" | sort | uniq -c | sort -rn
    else
      FILTER="."
      [[ -n "$ERROR_TYPE" ]] && FILTER="$FILTER | select(.error_type == \"$ERROR_TYPE\")"
      [[ -n "$DOMAIN" ]] && FILTER="$FILTER | select(.domain == \"$DOMAIN\")"
      [[ -n "$PHASE" ]] && FILTER="$FILTER | select(.phase == \"$PHASE\")"
      [[ -n "$AGENT" ]] && FILTER="$FILTER | select(.agent == \"$AGENT\")"
      jq -c "$FILTER" "$LOG_FILE" | head -n "$LIMIT" | jq -s '.'
    fi
    ;;

  stats)
    echo "=== Data Layer Stats ==="
    [[ -f "$DATA_DIR/claims.jsonl" ]] && echo "Claims: $(wc -l < "$DATA_DIR/claims.jsonl")" || echo "Claims: 0"
    [[ -f "$DATA_DIR/sources.jsonl" ]] && echo "Sources: $(wc -l < "$DATA_DIR/sources.jsonl")" || echo "Sources: 0"
    [[ -f "$DATA_DIR/metrics.jsonl" ]] && echo "Metrics: $(wc -l < "$DATA_DIR/metrics.jsonl")" || echo "Metrics: 0"
    [[ -f "$DATA_DIR/entities.json" ]] && echo "Entities: $(jq '.entities | length' "$DATA_DIR/entities.json")" || echo "Entities: 0"
    [[ -f "$CHECKPOINT_DIR/webfetch-failures.jsonl" ]] && echo "WebFetch failures: $(wc -l < "$CHECKPOINT_DIR/webfetch-failures.jsonl")" || echo "WebFetch failures: 0"
    ;;

  *)
    echo "Unknown command: $COMMAND"
    echo "Usage: query.sh {claims|sources|entities|metrics|contradicts|stale|stats|webfetch-failures} [flags]"
    exit 1
    ;;
esac
