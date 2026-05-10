#!/usr/bin/env bash
#
# verify-numerics.sh <slug> [--json]
#
# Cross-checks numeric content in `consume/<slug>/index.html` against
# `data/claims.jsonl`.
#
# Two modes:
#   1. Structured (preferred): if `consume/<slug>/numerics.json` exists,
#      validate every declared annotation against its `claim_ids[]` and
#      do arithmetic checks for ratio/range types. Clean output, no noise.
#   2. Regex fallback: if numerics.json is absent, extract numeric tokens
#      from HTML with regex and check for substring presence in claims.
#      Heuristic, ~20-50% false-positive rate from text-format variations.
#
# Exit codes: 0 = clean, 1 = issues found, 2 = setup error.

set -uo pipefail

SLUG="${1:?Usage: $0 <slug> [--json] [--lax]}"
JSON_OUT=0
STRICT=1   # default: coverage gaps count as issues
for arg in "${@:2}"; do
  case "$arg" in
    --json) JSON_OUT=1 ;;
    --lax)  STRICT=0 ;;
  esac
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HTML_FILE="$ROOT/consume/$SLUG/index.html"
CLAIMS_FILE="$ROOT/data/claims.jsonl"
NUMERICS_FILE="$ROOT/consume/$SLUG/numerics.json"

[[ -f "$HTML_FILE" ]] || { echo "ERROR: $HTML_FILE not found" >&2; exit 2; }
[[ -f "$CLAIMS_FILE" ]] || { echo "ERROR: $CLAIMS_FILE not found" >&2; exit 2; }
command -v jq >/dev/null || { echo "ERROR: jq required" >&2; exit 2; }

if [[ -t 1 && $JSON_OUT -eq 0 ]]; then
  GREEN=$(tput setaf 2 2>/dev/null || true)
  YELLOW=$(tput setaf 3 2>/dev/null || true)
  RED=$(tput setaf 1 2>/dev/null || true)
  RESET=$(tput sgr0 2>/dev/null || true)
else
  GREEN=""; YELLOW=""; RED=""; RESET=""
fi

# --- Common helpers -----------------------------------------------------

log()     { [[ $JSON_OUT -eq 0 ]] && echo "$@"; }
log_ok()  { log "  ${GREEN}[OK]${RESET}   $1"; }
log_bad() { log "  ${YELLOW}[?] ${RESET}   $1"; }
log_err() { log "  ${RED}[X] ${RESET}    $1"; }

# Project's claims (used by both modes)
PROJECT_CLAIMS=$(jq -c "select(.project_slug == \"$SLUG\")" "$CLAIMS_FILE")
CLAIMS_COUNT=$(printf '%s\n' "$PROJECT_CLAIMS" | grep -c '^.' || true)

if [[ ${CLAIMS_COUNT:-0} -eq 0 ]]; then
  echo "ERROR: no claims found for project '$SLUG' in $CLAIMS_FILE" >&2
  echo "  (run /industry $SLUG --resume or data-extraction-agent first)" >&2
  exit 2
fi

# Determine mode
if [[ -f "$NUMERICS_FILE" ]]; then
  MODE="structured"
else
  MODE="regex"
fi

log "=== verify-numerics: $SLUG (mode: $MODE) ==="
log "HTML    : $HTML_FILE"
[[ "$MODE" == "structured" ]] && log "Numerics: $NUMERICS_FILE"
log "Claims  : $CLAIMS_COUNT entries"
log ""

issues=0

# ==========================================================================
# Mode 1: STRUCTURED (preferred — uses numerics.json)
# ==========================================================================

if [[ "$MODE" == "structured" ]]; then

  if ! jq empty "$NUMERICS_FILE" 2>/dev/null; then
    echo "ERROR: $NUMERICS_FILE is not valid JSON" >&2
    exit 2
  fi

  ANN_COUNT=$(jq '.annotations | length' "$NUMERICS_FILE")
  log "## Structured validation: $ANN_COUNT annotations"
  log ""

  # Build claim id -> claim text lookup
  declare CLAIM_TEXT_BY_ID
  CLAIM_TEXT_BY_ID=$(printf '%s\n' "$PROJECT_CLAIMS" | jq -s 'map({key: .id, value: .claim}) | from_entries')

  # Iterate each annotation
  while IFS= read -r ann; do
    id=$(echo "$ann" | jq -r '.id')
    label=$(echo "$ann" | jq -r '.label')
    text=$(echo "$ann" | jq -r '.text // ""')
    type=$(echo "$ann" | jq -r '.type // "value"')
    derived=$(echo "$ann" | jq -r '.derived // false')
    claim_ids=$(echo "$ann" | jq -r '.claim_ids[]?')

    # Check 1: claim_ids non-empty (unless derived)
    if [[ -z "$claim_ids" ]]; then
      if [[ "$derived" == "true" ]]; then
        log "  ${YELLOW}[DERIVED]${RESET} $id ($label) — analytical derivation, no direct claim"
      else
        log_err "$id ($label) — has NO claim_ids declared (mark 'derived: true' if intentional)"
        issues=$((issues+1))
      fi
      continue
    fi

    # Check 2: each claim_id resolves
    missing_ids=""
    for cid in $claim_ids; do
      cid_text=$(echo "$CLAIM_TEXT_BY_ID" | jq -r --arg id "$cid" '.[$id] // empty')
      if [[ -z "$cid_text" ]]; then
        missing_ids="$missing_ids $cid"
      fi
    done
    if [[ -n "$missing_ids" ]]; then
      log_err "$id ($label) — claim_id(s) not found in claims.jsonl:$missing_ids"
      issues=$((issues+1))
      continue
    fi

    # Check 3: text appears in at least one cited claim
    # (skipped for ratio/percentage types where the text is a computed
    # result, not a quoted figure — those are validated by arithmetic in
    # check 4 below)
    if [[ -n "$text" && "$type" != "ratio" && "$type" != "percentage" && "$derived" != "true" ]]; then
      # Build normalized variants for fuzzy matching
      norm_text="${text//\~/}"          # strip leading ~ (escape tilde for bash)
      norm_text="${norm_text//+/}"      # strip leading +
      norm_text="${norm_text//−/-}"     # unicode minus → ASCII hyphen
      norm_text2="${norm_text//–/-}"    # en-dash → hyphen
      norm_text3="${norm_text//-/–}"    # hyphen → en-dash (reverse)
      # Unit-suffix variants: "B" ↔ " billion", "M" ↔ " million"
      norm_text4=$(echo "$norm_text" | sed -E 's/([0-9])B(\b|$)/\1 billion/g; s/([0-9])M(\b|$)/\1 million/g; s/([0-9])T(\b|$)/\1 trillion/g')

      found=0
      for cid in $claim_ids; do
        cid_text=$(echo "$CLAIM_TEXT_BY_ID" | jq -r --arg id "$cid" '.[$id]')
        for variant in "$text" "$norm_text" "$norm_text2" "$norm_text3" "$norm_text4"; do
          [[ -z "$variant" ]] && continue
          if echo "$cid_text" | grep -qF -- "$variant"; then
            found=1; break 2
          fi
        done
      done
      if [[ $found -eq 0 ]]; then
        log_bad "$id ($label) — text '$text' not in cited claims ($(echo $claim_ids | tr ' ' ','))"
        issues=$((issues+1))
        continue
      fi
    fi

    # Check 4: type-specific
    case "$type" in
      range)
        vmin=$(echo "$ann" | jq -r '.value_min // empty')
        vmax=$(echo "$ann" | jq -r '.value_max // empty')
        if [[ -n "$vmin" && -n "$vmax" ]]; then
          if (( $(echo "$vmax > $vmin" | bc -l 2>/dev/null || echo 0) )); then
            : # OK
          else
            log_err "$id ($label) — range value_min ($vmin) >= value_max ($vmax)"
            issues=$((issues+1))
            continue
          fi
        fi
        ;;
      ratio)
        nid=$(echo "$ann" | jq -r '.numerator_id // empty')
        did=$(echo "$ann" | jq -r '.denominator_id // empty')
        claimed_delta=$(echo "$ann" | jq -r '.claimed_delta // empty')
        claimed_ratio=$(echo "$ann" | jq -r '.claimed_ratio // empty')
        if [[ -n "$nid" && -n "$did" ]]; then
          nval=$(jq -r --arg id "$nid" '.annotations[] | select(.id == $id) | (.value // .value_min // empty)' "$NUMERICS_FILE")
          dval=$(jq -r --arg id "$did" '.annotations[] | select(.id == $id) | (.value // .value_min // empty)' "$NUMERICS_FILE")
          if [[ -n "$nval" && -n "$dval" ]]; then
            if [[ -n "$claimed_delta" ]]; then
              actual=$(echo "$nval - $dval" | bc -l)
              diff=$(echo "scale=2; ($actual - $claimed_delta) / ($claimed_delta + 0.001) * 100" | bc -l 2>/dev/null || echo 999)
              # Allow ±5% tolerance
              if (( $(echo "${diff#-} < 5" | bc -l 2>/dev/null || echo 0) )); then
                : # OK
              else
                log_err "$id ($label) — claimed_delta=$claimed_delta but $nval - $dval = $actual (off by ${diff}%)"
                issues=$((issues+1))
                continue
              fi
            elif [[ -n "$claimed_ratio" ]]; then
              actual=$(echo "scale=4; $nval / $dval" | bc -l)
              diff=$(echo "scale=2; ($actual - $claimed_ratio) / ($claimed_ratio + 0.001) * 100" | bc -l 2>/dev/null || echo 999)
              if (( $(echo "${diff#-} < 5" | bc -l 2>/dev/null || echo 0) )); then
                :
              else
                log_err "$id ($label) — claimed_ratio=$claimed_ratio but $nval/$dval = $actual (off by ${diff}%)"
                issues=$((issues+1))
                continue
              fi
            fi
          fi
        fi
        ;;
    esac

    log_ok "$id ($label) → $text"
  done <<< "$(jq -c '.annotations[]' "$NUMERICS_FILE")"

  # Coverage check: any HTML token not declared in numerics.json
  log ""
  log "## Coverage check (HTML tokens vs declared annotations)"
  declared_texts=$(jq -r '.annotations[].text' "$NUMERICS_FILE" | sort -u)

  # Re-extract HTML tokens (same as fallback regex)
  TEXT=$(awk '
    /<style[^>]*>/ { instyle=1 }
    /<\/style>/    { instyle=0; next }
    /<script[^>]*>/{ inscript=1 }
    /<\/script>/   { inscript=0; next }
    !instyle && !inscript { print }
  ' "$HTML_FILE" \
    | sed -E 's/<[^>]*>/ /g' \
    | sed -E 's/&nbsp;/ /g; s/&amp;/\&/g; s/&mdash;/—/g; s/&middot;/·/g; s/&[a-z]+;/ /g' \
    | tr -s ' ')

  HTML_DOLLARS=$(echo "$TEXT" | grep -oE '\$[0-9]+(\.[0-9]+)?([–-][0-9]+(\.[0-9]+)?)?[BbMmKkTt]\+?' | sort -u || true)
  HTML_PCTS=$(echo "$TEXT" | grep -oE '[0-9]+(\.[0-9]+)?([–-][0-9]+(\.[0-9]+)?)?%\+?' \
    | sort -u | grep -vE '^(0|10|20|25|30|40|50|60|70|75|80|90|100|120|140)%\+?$' || true)

  uncovered=0
  for tok in $HTML_DOLLARS $HTML_PCTS; do
    if ! echo "$declared_texts" | grep -qF -- "$tok"; then
      log "  ${YELLOW}[uncovered]${RESET} $tok in HTML but not declared in numerics.json"
      uncovered=$((uncovered+1))
    fi
  done
  if [[ $uncovered -eq 0 ]]; then
    log "  ${GREEN}All HTML tokens accounted for${RESET}"
  elif [[ $STRICT -eq 1 ]]; then
    log "  ${RED}$uncovered tokens uncovered — strict mode treats as issues. Use --lax to downgrade to warnings.${RESET}"
    issues=$((issues + uncovered))
  else
    log "  ${YELLOW}($uncovered tokens not declared — informational, --lax mode)${RESET}"
  fi
fi

# ==========================================================================
# Mode 2: REGEX FALLBACK (when numerics.json is absent)
# ==========================================================================

if [[ "$MODE" == "regex" ]]; then

  log "(running regex heuristic — for clean output, have consume-agent emit numerics.json)"
  log ""

  TEXT=$(awk '
    /<style[^>]*>/ { instyle=1 }
    /<\/style>/    { instyle=0; next }
    /<script[^>]*>/{ inscript=1 }
    /<\/script>/   { inscript=0; next }
    !instyle && !inscript { print }
  ' "$HTML_FILE" \
    | sed -E 's/<[^>]*>/ /g' \
    | sed -E 's/&nbsp;/ /g; s/&amp;/\&/g; s/&mdash;/—/g; s/&middot;/·/g; s/&[a-z]+;/ /g' \
    | tr -s ' ')

  DOLLARS=$(echo "$TEXT" | grep -oE '\$[0-9]+(\.[0-9]+)?([–-][0-9]+(\.[0-9]+)?)?[BbMmKkTt]\+?' | sort -u || true)
  PCTS=$(echo "$TEXT" | grep -oE '[0-9]+(\.[0-9]+)?([–-][0-9]+(\.[0-9]+)?)?%\+?' \
    | sort -u | grep -vE '^(0|10|20|25|30|40|50|60|70|75|80|90|100|120|140)%\+?$' || true)
  MULTIPLES=$(echo "$TEXT" | grep -oE '[0-9]+(\.[0-9]+)?([–-][0-9]+(\.[0-9]+)?)?x\+?' | sort -u || true)

  CLAIM_CORPUS=$(printf '%s\n' "$PROJECT_CLAIMS" | jq -r '.claim')

  check_token() {
    local token="$1"
    if echo "$CLAIM_CORPUS" | grep -qF -- "$token"; then return 0; fi
    if echo "$CLAIM_CORPUS" | grep -qF -- "${token//–/-}"; then return 0; fi
    if echo "$CLAIM_CORPUS" | grep -qF -- "${token// /}"; then return 0; fi
    return 1
  }

  log "## Dollar amounts"
  for d in $DOLLARS; do
    [[ -z "$d" ]] && continue
    if check_token "$d"; then log_ok "$d"; else log_bad "$d — not found in claim text"; issues=$((issues+1)); fi
  done

  log ""
  log "## Percentages (axis labels excluded)"
  for p in $PCTS; do
    [[ -z "$p" ]] && continue
    if check_token "$p"; then log_ok "$p"; else log_bad "$p — not found in claim text"; issues=$((issues+1)); fi
  done

  log ""
  log "## Multiples (Nx)"
  for m in $MULTIPLES; do
    [[ -z "$m" ]] && continue
    if check_token "$m"; then log_ok "$m"; else log_bad "$m — not found in claim text"; issues=$((issues+1)); fi
  done
fi

# ==========================================================================
# Staleness (both modes)
# ==========================================================================

TODAY=$(date +%Y-%m-%d)
STALE=$(printf '%s\n' "$PROJECT_CLAIMS" | jq -c "select(.stale_after != null and .stale_after < \"$TODAY\")" 2>/dev/null || true)
if [[ -z "$STALE" ]]; then
  STALE_COUNT=0
else
  STALE_COUNT=$(printf '%s\n' "$STALE" | grep -c '^.' || true)
  STALE_COUNT=${STALE_COUNT:-0}
fi

if [[ $JSON_OUT -eq 0 ]]; then
  log ""
  log "## Staleness (claims past stale_after as of $TODAY)"
  if [[ $STALE_COUNT -gt 0 ]]; then
    log "  ${YELLOW}$STALE_COUNT claims are stale${RESET} (re-verify or refresh)"
    printf '%s\n' "$STALE" | jq -r '"  · \(.id): \(.claim[:80])... [stale_after \(.stale_after)]"' | head -5
    [[ $STALE_COUNT -gt 5 ]] && log "  ... ($((STALE_COUNT-5)) more)"
  else
    log "  ${GREEN}All claims fresh${RESET}"
  fi
fi

# ==========================================================================
# Verdict
# ==========================================================================

if [[ $JSON_OUT -eq 1 ]]; then
  jq -n \
    --arg slug "$SLUG" \
    --arg today "$TODAY" \
    --arg mode "$MODE" \
    --argjson issues "${issues:-0}" \
    --argjson stale "${STALE_COUNT:-0}" \
    --argjson claims "${CLAIMS_COUNT:-0}" \
    '{slug: $slug, date: $today, mode: $mode, issues: $issues, stale_claims: $stale, claims_indexed: $claims}'
  if [[ $issues -gt 0 || $STALE_COUNT -gt 0 ]]; then exit 1; fi
  exit 0
fi

log ""
if [[ $issues -gt 0 ]]; then
  log "${YELLOW}Verdict: $issues issue(s) — review needed${RESET}"
  [[ $STALE_COUNT -gt 0 ]] && log "${YELLOW}Plus $STALE_COUNT stale claim(s)${RESET}"
  exit 1
elif [[ $STALE_COUNT -gt 0 ]]; then
  log "${YELLOW}Verdict: numerics clean, but $STALE_COUNT stale claim(s) need refresh${RESET}"
  exit 1
fi
log "${GREEN}Verdict: all numeric annotations grounded${RESET}"
exit 0
