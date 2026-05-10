# Company output template

Exact structure for files produced by `/company`. Research layer optimized for machine extraction. Every file gets YAML frontmatter. Prose is for narrative only; structured data lives in tables.

## Directory layout (per company)

```
research/companies/<slug>/
├── thesis.md         # core analytical argument — entry point
├── financials.md     # segment tables, margin trajectory, capital deployment
├── narrative.md      # cross-quarter narrative arc with quotes
├── competitive.md    # market position, peer comparison, strategic moves
├── scenarios.md      # bull / base / bear with triggers and timelines
├── gaps.md           # primary research required
├── sources.md        # provenance per claim
└── meta.json         # machine-readable metadata
```

## YAML frontmatter (every file)

Every markdown file begins with:

```yaml
---
project: <slug>
project_type: company
file: <filename>
generated_at: YYYY-MM-DD
version: 0.2.0
---
```

## `thesis.md` structure

```markdown
---
project: <slug>
project_type: company
file: thesis.md
generated_at: YYYY-MM-DD
version: 0.2.0
---

# <Company> (<ticker>) — Thesis

## Core argument

<!-- claim: thesis-statement -->
1-2 sentences. What does the market get wrong about this company? What non-consensus insight drives the analysis? Must be falsifiable.

## Why it matters

<!-- claim: thesis-consequence -->
2-3 paragraphs on consequences if the thesis is correct. Impact on valuation, competitive position, capital allocation.

## Key evidence

| # | Claim | Evidence | Source | Confidence |
|---|-------|----------|--------|------------|
| 1 | ... | ... | URL | high |

## Key risks

| # | Risk | What would invalidate it | Signal to watch |
|---|------|--------------------------|-----------------|
| 1 | ... | ... | ... |

## What to watch

| Metric / Event | Expected date | What it would confirm | What it would deny |
|----------------|---------------|----------------------|--------------------|

## Pointers to full analysis

| Topic | File | Section |
|-------|------|---------|
| Financial pattern | financials.md | Segment table |
| Narrative arc | narrative.md | Quote table |
| Competitive positioning | competitive.md | Market position |
| Scenarios | scenarios.md | Scenario overview |
| Gaps | gaps.md | People to interview |
| Sources | sources.md | Filings used |
```

## `financials.md` structure

```markdown
---
project: <slug>
project_type: company
file: financials.md
generated_at: YYYY-MM-DD
version: 0.2.0
---

# <Company> — Financial Pattern Read

## Segment table (last 4 quarters)

| Segment | Q1-25 Rev | Q2-25 Rev | Q3-25 Rev | Q4-25 Rev | YoY % | Op Margin | Trend |

## Margin trajectory (last 8 quarters)

| Quarter | Gross margin | Operating margin | EBITDA margin | Driver |
|---------|--------------|------------------|---------------|--------|

## Working capital trends

| Quarter | DSO | DIO | DPO | CCC |
|---------|-----|-----|-----|-----|

## Capital deployment table (last 4 years)

| Year | Capex | Acquisitions | Buybacks | Dividends | Debt paydown | Total |
|------|-------|--------------|----------|-----------|--------------|-------|

## ROIC and asset turns

| Year | NOPAT | Invested capital | ROIC | Asset turns |
|------|-------|------------------|------|-------------|

## Financial anomalies

| Anomaly | Where seen | Why it's strange | Potential implication |
|---------|------------|------------------|----------------------|

## Notable accounting notes

| Note | Filing | Date | Impact |
|------|--------|------|--------|

## Source list (filings only)

| Filing | Date | URL | Items extracted |
|--------|------|-----|-----------------|
```

## `narrative.md` structure

```markdown
---
project: <slug>
project_type: company
file: narrative.md
generated_at: YYYY-MM-DD
version: 0.2.0
---

# <Company> — Narrative Arc

## Quote table (last 8 earnings calls)

| Date | Caller | Theme | Direct quote | Tonal shift vs. prior |
|------|--------|-------|--------------|------------------------|

## KPI evolution

| KPI | First mentioned | Last mentioned | Status | Source call |
|-----|------------------|----------------|--------|-------------|

## Guidance changes

| Quarter | Metric | Prior guide | New guide | Driver |
|---------|--------|-------------|-----------|--------|

## Themes that emerged

| Theme | First appearance | Source | Current status |
|-------|------------------|--------|----------------|

## Themes that quietly disappeared

| Theme | Last appearance | Why it disappeared |
|-------|-----------------|--------------------|

## Hedge-language counts

| Call date | "I think" | "we expect" | "hard to know" | Total hedges | Signal |
|-----------|-----------|-------------|----------------|--------------|--------|
```

## `competitive.md` structure

```markdown
---
project: <slug>
project_type: company
file: competitive.md
generated_at: YYYY-MM-DD
version: 0.2.0
---

# <Company> — Competitive Positioning

## Market position

| Company | Market share | Growth rate | Gross margin | Operating margin | Relative position |
|---------|--------------|-------------|--------------|------------------|-------------------|

## Strategic moves (last 18 months)

| Date | Move | Type | Impact | Source |
|------|------|------|--------|--------|

## Peer comparison

| Attribute | This company | Peer 1 | Peer 2 | Peer 3 |
|-----------|--------------|--------|--------|--------|

## M&A probability

| Target | Likely acquirer | Logic | Regulatory barrier | Probability |
|--------|-----------------|-------|--------------------|-------------|

## Management quality signals

| Signal | Evidence | Assessment |
|--------|----------|------------|
| Capital allocation track record | ... | ... |
| Guidance accuracy | ... | ... |
| Insider buying/selling | ... | ... |
```

## `scenarios.md` structure

```markdown
---
project: <slug>
project_type: company
file: scenarios.md
generated_at: YYYY-MM-DD
version: 0.2.0
---

# <Company> — Scenarios

## Scenario overview

| Scenario | Probability | Key assumption | Revenue impact | Margin impact | Valuation impact | Timeline |
|----------|-------------|----------------|----------------|---------------|------------------|----------|
| Bull | % | ... | ... | ... | ... | ... |
| Base | % | ... | ... | ... | ... | ... |
| Bear | % | ... | ... | ... | ... | ... |

## Bull case

| Attribute | Value |
|-----------|-------|
| Key assumptions | bullet list |
| Probability | % |
| Financial implications | ... |
| Trigger events | ... |
| Timeline | when will we know |

## Base case

| Attribute | Value |
|-----------|-------|
| Key assumptions | bullet list |
| Probability | % |
| Financial implications | ... |

## Bear case

| Attribute | Value |
|-----------|-------|
| Key assumptions | bullet list |
| Probability | % |
| Financial implications | ... |
| Trigger events | ... |
| Timeline | when will we know |

## Scenario transitions

| Trigger event | From scenario | To scenario | Probability shift | Date |
|---------------|---------------|-------------|--------------------|------|
```

## `gaps.md` structure

```markdown
---
project: <slug>
project_type: company
file: gaps.md
generated_at: YYYY-MM-DD
version: 0.2.0
---

# <Company> — Primary Research Gaps

## People to interview

| # | Role / Company | Why they matter | What to ask | Difficulty |

## Data sources to acquire

| # | Source | What it answers | Why public sources can't | Cost |

## Experiments / observations

| # | Experiment | What it reveals | How to conduct | Time |

## Cost / time estimate

| Category | Items | Estimated cost | Estimated time |
|----------|-------|----------------|----------------|
```

## `sources.md` structure

```markdown
---
project: <slug>
project_type: company
file: sources.md
generated_at: YYYY-MM-DD
version: 0.2.0
---

# <Company> — Sources

## Filings used

| Filing | Form | Date | URL | Key extractions |
|--------|------|------|-----|-----------------|

## Other sources

| URL | Fetched | Source class | Claims supported |
|-----|---------|--------------|------------------|
```

## `meta.json` schema

```json
{
  "ticker": "ASML",
  "name": "ASML Holding NV",
  "industry_slug": "semiconductor-capital-equipment",
  "generated_at": "2026-05-08T12:00:00Z",
  "version": "0.2.0",
  "filings_used": [
    {"form": "20-F", "date": "2025-02-12", "url": "..."},
    {"form": "earnings_transcript", "quarter": "Q4-2025", "date": "2026-01-31", "url": "..."}
  ],
  "source_counts": {
    "filings": 7,
    "transcripts": 4,
    "journalism": 9,
    "community": 5,
    "inference": 3
  },
  "files": ["thesis.md", "financials.md", "narrative.md", "competitive.md", "scenarios.md", "gaps.md", "sources.md"]
}
```

## Slug rules

Same as industry research — lowercase, hyphens for spaces. Companies usually slug by ticker: `asml`, `nvda`, `crm`. Foreign issuers: use U.S. ADR ticker if available, else local exchange ticker.

## Refresh logic

Same pattern as industry research — if `meta.json` exists, ask refresh / augment / cancel. Companies change faster than industries; default to refresh after 90 days. Use `${CLAUDE_PLUGIN_ROOT}/references/trust-signal-rules.md` archetype windows for per-claim staleness; the 90-day window is a coarse trigger for re-running the full pipeline, not a per-claim rule.
