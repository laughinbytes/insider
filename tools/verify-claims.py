#!/usr/bin/env python3
"""
verify-claims.py [--project SLUG] [--json]

Scans data/claims.jsonl for inference claims with broken arithmetic chains.
Catches the f-6 class of error: claim text says "X% of $Y = $Z" but the math
doesn't compute (e.g., "40% of $8-10B = $5.2B" — actual ratio is 52-65%).

Heuristic regex parsing — covers the common percentage-of-range pattern.
Misses prose forms not matching the pattern; surface those manually.

Exit: 0 = all chains compute, 1 = broken chains, 2 = setup error.
"""

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLAIMS_FILE = ROOT / "data" / "claims.jsonl"

# Tolerance for arithmetic checks (±5 percentage points absolute)
TOL_PCT_POINTS = 5.0


def parse_args():
    p = argparse.ArgumentParser(description="Verify inference-claim arithmetic.")
    p.add_argument("--project", help="filter to project_slug")
    p.add_argument("--json", action="store_true", help="JSON output")
    return p.parse_args()


def colorize(s, color):
    if not sys.stdout.isatty():
        return s
    codes = {"green": "\033[32m", "yellow": "\033[33m", "red": "\033[31m", "reset": "\033[0m"}
    return f"{codes.get(color, '')}{s}{codes['reset']}"


def to_billions(num_str, suffix):
    """Convert numeric to billions for comparison."""
    val = float(num_str)
    if suffix.upper() == "M":
        val /= 1000
    elif suffix.upper() == "K":
        val /= 1_000_000
    elif suffix.upper() == "T":
        val *= 1000
    return val


# Match patterns like "roughly 40%", "~58%", "approximately 52-65%", "58%"
PCT_PATTERN = re.compile(
    r"(?:roughly|~|approximately|about)?\s*(\d+(?:\.\d+)?)(?:[-–](\d+(?:\.\d+)?))?\s*%(?!\w)",
    re.IGNORECASE,
)

# Match "$5.2B", "~$5.2B", "$5-7B", "~$5–7B", "$8-10B" with optional B/M/K/T suffix
DOLLAR_PATTERN = re.compile(
    r"~?\$(\d+(?:\.\d+)?)(?:[-–](\d+(?:\.\d+)?))?\s*([BMKT])",
    re.IGNORECASE,
)


def check_claim(claim_id, slug, text):
    """
    Check if 'X% of $A-$B = $C' arithmetic holds, where X is a stated percentage,
    $A-$B is a range denominator, and $C is the numerator.

    Returns: (status, detail) where status is 'ok', 'broken', or 'no_pattern'.
    """
    # Find all dollar amounts in the text
    dollars = list(DOLLAR_PATTERN.finditer(text))
    pcts = list(PCT_PATTERN.finditer(text))

    if not pcts or len(dollars) < 2:
        return ("no_pattern", "")

    # Heuristic: take the first percentage and look for "= $X" near "of $Y" pattern
    # Most common form: "[STATED_PCT]% of [DENOM_RANGE] ... = $[NUMERATOR]"
    #              or:  "[NUMERATOR] ... = STATED_PCT% of DENOM"
    #              or:  "...$NUMERATOR of $DENOM_RANGE..." with the percentage stated nearby

    # Strategy: find sub-string starting with first stated pct, look for "of" then $denom_range,
    # then look for the equals-numerator
    first_pct = pcts[0]
    pct_low = float(first_pct.group(1))
    pct_high = float(first_pct.group(2)) if first_pct.group(2) else pct_low

    # Look for "of $X(-Y)?B" pattern after the percentage
    after_pct = text[first_pct.end():]
    of_match = re.search(
        r"of\s+~?\$(\d+(?:\.\d+)?)(?:[-–](\d+(?:\.\d+)?))?\s*([BMKT])",
        after_pct,
        re.IGNORECASE,
    )

    # Look for "= $X" pattern (the numerator)
    eq_match = re.search(
        r"=\s+~?\$(\d+(?:\.\d+)?)\s*([BMKT])",
        text,
        re.IGNORECASE,
    )

    if not of_match or not eq_match:
        # Try alternate pattern: "$X of $Y-$Z" without explicit "="
        alt_match = re.search(
            r"\$(\d+(?:\.\d+)?)\s*([BMKT])\s+of\s+~?\$(\d+(?:\.\d+)?)(?:[-–](\d+(?:\.\d+)?))?\s*([BMKT])",
            text,
            re.IGNORECASE,
        )
        if alt_match:
            num_val = to_billions(alt_match.group(1), alt_match.group(2))
            d_low = to_billions(alt_match.group(3), alt_match.group(5))
            d_high_raw = alt_match.group(4)
            d_high = to_billions(d_high_raw, alt_match.group(5)) if d_high_raw else d_low
        else:
            return ("no_pattern", "")
    else:
        num_val = to_billions(eq_match.group(1), eq_match.group(2))
        d_low = to_billions(of_match.group(1), of_match.group(3))
        d_high_raw = of_match.group(2)
        d_high = to_billions(d_high_raw, of_match.group(3)) if d_high_raw else d_low

    # Compute ratio range
    if d_low <= 0 or d_high <= 0:
        return ("no_pattern", "")

    ratio_high = (num_val / d_low) * 100  # using smaller denom = larger ratio
    ratio_low = (num_val / d_high) * 100

    # Check if stated_pct overlaps with computed range (within tolerance)
    in_range = (
        pct_high >= (ratio_low - TOL_PCT_POINTS)
        and pct_low <= (ratio_high + TOL_PCT_POINTS)
    )

    detail = {
        "stated_pct": f"{pct_low}-{pct_high}%" if pct_low != pct_high else f"{pct_low}%",
        "computed_pct_range": f"{ratio_low:.1f}-{ratio_high:.1f}%",
        "numerator": f"${num_val}B",
        "denominator": f"${d_low}-{d_high}B" if d_low != d_high else f"${d_low}B",
    }

    return ("ok" if in_range else "broken", detail)


def main():
    args = parse_args()

    if not CLAIMS_FILE.exists():
        print(f"ERROR: {CLAIMS_FILE} not found", file=sys.stderr)
        return 2

    issues = 0
    checked = 0
    no_pattern = 0
    broken_list = []

    if not args.json:
        print("=== verify-claims ===")
        if args.project:
            print(f"Project filter: {args.project}")

    with open(CLAIMS_FILE, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                c = json.loads(line)
            except json.JSONDecodeError:
                continue
            if c.get("source_class") != "inference":
                continue
            if args.project and c.get("project_slug") != args.project:
                continue
            checked += 1

            cid = c.get("id", "?")
            slug = c.get("project_slug", "?")
            text = c.get("claim", "")
            chain = c.get("inference_chain") or ""
            full_text = f"{text} {chain}"

            status, detail = check_claim(cid, slug, full_text)

            if status == "ok":
                if not args.json:
                    print(f"  {colorize('[OK]', 'green')}     {cid} ({slug}): "
                          f"{detail['stated_pct']} ≈ {detail['numerator']} / {detail['denominator']} "
                          f"(computed {detail['computed_pct_range']})")
            elif status == "broken":
                issues += 1
                broken_list.append({"id": cid, "slug": slug, **detail})
                if not args.json:
                    print(f"  {colorize('[BROKEN]', 'red')} {cid} ({slug}): "
                          f"stated {detail['stated_pct']}, computed {detail['computed_pct_range']} "
                          f"({detail['numerator']} / {detail['denominator']})")
                    print(f"            text: {text[:120]}...")
            else:  # no_pattern
                no_pattern += 1
                if not args.json:
                    print(f"  {colorize('[skip]', 'yellow')}   {cid} ({slug}): "
                          f"no parseable arithmetic chain in claim text")

    if args.json:
        print(json.dumps({
            "checked": checked,
            "broken_chains": issues,
            "no_pattern": no_pattern,
            "broken": broken_list,
        }, indent=2))
    else:
        print()
        print(f"Checked: {checked} inference claim(s); broken arithmetic: {issues}; "
              f"no parseable pattern: {no_pattern}")
        if issues > 0:
            print(colorize(f"Verdict: {issues} broken chain(s) — fix at the source", "red"))
        else:
            print(colorize("Verdict: all parseable inference chains compute correctly", "green"))

    return 1 if issues > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
