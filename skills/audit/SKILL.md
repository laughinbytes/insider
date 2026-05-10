---
name: audit
description: Audit existing industry or company research for stale information, dead sources, and new developments. Uses the structured data layer for efficient cross-research analysis. Use when the user runs /audit or wants to know what's changed since research was generated.
argument-hint: <slug>
allowed-tools: [Read, Write, Bash, WebSearch, WebFetch, mcp__gemini-search__web_search, Glob]
---

# /audit — research freshness auditor

Re-check existing research against current sources. Uses the structured data layer (`data/claims.jsonl`, `data/sources.jsonl`) for efficient auditing across all projects.

## Inputs

`/audit <slug>`

## Resolution

1. Glob for `research/industries/<slug>/` or `research/companies/<slug>/`
2. Read `meta.json` to get: generated date, archetype, source counts
3. If not found: list available research from `research/*/*/meta.json`

## Audit process

### Phase 1 — Source health check

Read `data/sources.jsonl` and filter to URLs cited by this project:

```bash
jq -c 'select(.projects | contains(["<slug>"]))' data/sources.jsonl
```

For each URL:
1. WebFetch the URL (HEAD or GET)
2. If 404/410/403: mark DEAD, update `data/sources.jsonl`
3. If redirect (301/302): mark MOVED, update `data/sources.jsonl`
4. If 200 but content changed: mark CHANGED, update `data/sources.jsonl`
5. If 200 and stable: mark VALID, update `data/sources.jsonl`

Rate-limit to ~1 req/sec per domain.

### Phase 2 — Freshness assessment (data layer)

Read `data/claims.jsonl` and filter to this project:

```bash
jq -c 'select(.project_slug == "<slug>")' data/claims.jsonl
```

For each claim:
1. Check `stale_after` date
2. If past: mark STALE
3. If within 30 days of stale: mark AGING
4. Otherwise: FRESH

Also check `data/metrics.jsonl` for metrics that may have newer observations from other projects (e.g., Cursor's ARR was updated in a different industry research).

### Phase 3 — Cross-project contradiction detection

Query the data layer for claims about the same entity with conflicting values:

```bash
./tools/query.sh contradicts --entity "<key-entity>" --metric "<key-metric>"
```

Flag any contradictions found across projects.

### Phase 4 — New developments scan

WebSearch (fallback: `mcp__gemini-search__web_search`) for what's changed since `generated_at`:

Query patterns:
- `"<industry keyword>" "earnings" OR "announcement" after:YYYY-MM-DD`
- `site:sec.gov "<ticker>" "10-K" OR "10-Q"` (for company research)
- `"<key player>" "acquisition" OR "partnership" after:YYYY-MM-DD`

Limit to 5-10 searches.

### Phase 5 — Audit report

Write `research/<slug>/audit-<YYYY-MM-DD>.md`:

```markdown
# Audit: <Name>
*Audited: YYYY-MM-DD · Original: [date] · Archetype: [archetype]*

## Executive summary
- Total sources checked: N
- DEAD sources: X (X%)
- CHANGED sources: Y
- Stale claims: Z
- Aging claims: W
- New developments found: V
- Cross-project contradictions: U
- **Recommendation:** [refresh full / augment / no action]

## Source health
### Dead sources
| URL | Claim count | Status | Action |

### Changed sources
| URL | Claim count | What changed | Action |

### Valid sources
| URL | Status | Notes |

## Freshness assessment
### Stale claims
| ID | File | Claim | Source date | Stale after | Action |

### Aging claims
| ID | File | Claim | Source date | Days until stale | Action |

## Cross-project contradictions
| Entity | Metric | Value A (project) | Value B (project) | Resolution |

## New developments since [original date]
1. [Development] — Source, date, impact on research

## Recommendations
### Must-update
- [ ] Replace dead source for claim X
- [ ] Update stale claim Y
- [ ] Add new development Z

### Should-update
- [ ] Re-verify aging claim A
- [ ] Check if source B still supports claim C

### Optional
- [ ] No action needed for fresh claims
```

## Recommendation logic

- **REFRESH** if: >=3 stale claims OR >=2 new developments OR >=2 DEAD sources OR >=1 contradiction
- **AUGMENT** if: 1–2 stale claims OR 1 new development OR 1 DEAD source
- **NO ACTION** if: 0 stale, 0 new developments, all sources valid, no contradictions

## Constraints

- Do NOT re-run full macro analysis. This is an audit, not a rebuild.
- Do NOT fabricate new developments.
- Do NOT delete files. The audit report is additive.
- Rate-limit WebFetch to ~1 req/sec per domain.
