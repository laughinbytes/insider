# Output template

Exact structure for every file produced by `/industry`. Research layer optimized for machine extraction. Every file gets YAML frontmatter. Prose is for narrative only; structured data lives in tables.

## Directory layout (per industry)

```
research/industries/<slug>/
├── thesis.md          # core analytical argument — entry point
├── macro.md           # industry structure, value chain, profit pool, moats
├── economics.md       # unit economics, revenue build, financial modeling
├── players.md         # competitive dynamics, game theory, talent flows
├── scenarios.md       # bull / base / bear with triggers and timelines
├── analogs.md         # historical pattern matching from comparable industries
├── gaps.md            # primary research required
├── open-secrets.md    # tagged claims with citations
├── sources.md         # full provenance per claim
└── meta.json          # machine-readable metadata
```

## YAML frontmatter (every file)

Every markdown file begins with:

```yaml
---
project: <slug>
project_type: industry
file: <filename>
generated_at: YYYY-MM-DD
version: 0.2.0
---
```

This makes extraction reliable — the parser always knows what project and file it's reading.

## `thesis.md` structure

```markdown
---
project: <slug>
project_type: industry
file: thesis.md
generated_at: YYYY-MM-DD
version: 0.2.0
---

# <Industry Name> — Thesis

## The core argument

<!-- claim: thesis-statement -->
1-2 sentences. What does the market get wrong? What non-consensus insight drives this analysis? The thesis must be falsifiable.

## Why it matters

<!-- claim: thesis-consequence -->
2-3 paragraphs on the consequences if the thesis is correct. Who wins, who loses, what changes in capital allocation, what shifts in competitive dynamics.

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
| Value chain | macro.md | Value chain decomposition |
| Unit economics | economics.md | Unit economics modeling |
| Competitive dynamics | players.md | Game theory |
| Scenarios | scenarios.md | Scenario transitions |
| Analogs | analogs.md | Pattern-derived predictions |
| Gaps | gaps.md | People to interview |
| Open secrets | open-secrets.md | Top 3 distinctive claims |
| Sources | sources.md | Primary |
```

## `macro.md` structure

```markdown
---
project: <slug>
project_type: industry
file: macro.md
generated_at: YYYY-MM-DD
version: 0.2.0
---

# <Industry> — Macro Analysis

## Industry definition

| Attribute | Value |
|-----------|-------|
| Boundary | what's in |
| Adjacent sectors | list |
| Segments | list |
| Buyer segments | list with distinguishing characteristics |

## Value chain decomposition

| Stage | Players | Revenue share | Gross margin | Profit pool weight | Direction |
|-------|---------|---------------|--------------|---------------------|-----------|

## Profit pool analysis

| Stage | Revenue share | Profit share | Direction | Driver |
|-------|---------------|--------------|-----------|--------|

## Top players

| Rank | Company | Scale metric | Strategic posture | Parent / ownership |
|------|---------|--------------|-------------------|--------------------|

## Competitive moats

| Power | Applies? | Evidence | Strength |
|-------|----------|----------|----------|

## Unit economics

| Metric | Value | Source | Notes |
|--------|-------|--------|-------|

## Capital intensity and cash conversion

| Metric | Value | Peer comparison |
|--------|-------|-----------------|

## Regulatory frame

| Regulator | Recent change | Pending | Impact |
|-----------|---------------|---------|--------|

## Secular vs. cyclical drivers

| Driver | Type | Time horizon | Confidence |
|--------|------|--------------|------------|

## Source list

| URL | Fetched | Source class | Claims supported |
|-----|---------|--------------|------------------|
```

## `economics.md` structure

```markdown
---
project: <slug>
project_type: industry
file: economics.md
generated_at: YYYY-MM-DD
version: 0.2.0
---

# <Industry> — Economics

## Revenue build (bottom-up)

| Segment | Units | Price/unit | Attach rate | Expansion | Implied revenue | Confidence |

## Public company financial profiles

| Company | Revenue | Growth | Gross margin | Operating margin | FCF margin | Net debt/EBITDA |

## Unit economics modeling

| Metric | Value | Source | Notes |
|--------|-------|--------|-------|

## Margin trajectory

| Quarter | Company | Gross margin | Operating margin | Driver |
|---------|---------|--------------|------------------|--------|

## Capital intensity profile

| Metric | Value | Peer comparison |
|--------|-------|-----------------|

## Financial anomalies

| Anomaly | Where seen | Why it's strange | Potential implication |
|---------|------------|------------------|----------------------|
```

## `players.md` structure

```markdown
---
project: <slug>
project_type: industry
file: players.md
generated_at: YYYY-MM-DD
version: 0.2.0
---

# <Industry> — Competitive Dynamics

## Strategic landscape

| Attribute | Assessment |
|-----------|------------|
| Concentration | fragmented / concentrated |
| Cooperation | cooperative / zero-sum |
| Stability | stable / dynamic |
| Key dynamic | 1-sentence summary |

## Top 10 players

| Rank | Company | Scale | Strategic posture | Key dependencies | Recent moves | Likely next moves |
|------|---------|-------|-------------------|------------------|--------------|-------------------|

## Game theory — response matrix

| If [Player A] does... | [Player B] responds... | [Player C] responds... | Industry outcome |
|-----------------------|------------------------|------------------------|------------------|

## Pricing dynamics

| Player | Pricing power | Pressure source | Discounting? |
|--------|---------------|-----------------|--------------|

## M&A probability

| Target | Likely acquirer | Logic | Regulatory barrier | Probability |
|--------|-----------------|-------|--------------------|-------------|

## Talent flows

| Person | From | To | Role | Date | Signal |
|--------|------|----|------|------|--------|

## Supply chain dependencies

| Supplier | Customer | Exclusive? | Min commitment | Bottleneck risk |
|----------|----------|------------|----------------|-----------------|
```

## `scenarios.md` structure

```markdown
---
project: <slug>
project_type: industry
file: scenarios.md
generated_at: YYYY-MM-DD
version: 0.2.0
---

# <Industry> — Scenarios

## Scenario overview

| Scenario | Probability | Key assumption | Revenue impact | Margin impact | Timeline |
|----------|-------------|----------------|----------------|---------------|----------|
| Bull | % | ... | ... | ... | ... |
| Base | % | ... | ... | ... | ... |
| Bear | % | ... | ... | ... | ... |

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
| Why this is base | ... |

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

## `analogs.md` structure

```markdown
---
project: <slug>
project_type: industry
file: analogs.md
generated_at: YYYY-MM-DD
version: 0.2.0
---

# <Industry> — Historical Analogs

## Analog comparison

| Attribute | This industry | Analog 1 | Analog 2 | Analog 3 |
|-----------|---------------|----------|----------|----------|
| Industry name | ... | ... | ... | ... |
| Starting condition | ... | ... | ... | ... |
| Timeline (years) | ... | ... | ... | ... |
| Winners | ... | ... | ... | ... |
| Losers | ... | ... | ... | ... |
| Key inflection | ... | ... | ... | ... |
| What translates | ... | ... | ... | ... |
| What breaks | ... | ... | ... | ... |

## Pattern-derived predictions

| Prediction | Analog support | Confidence | Time horizon |
|------------|----------------|------------|--------------|
```

## `gaps.md` structure

```markdown
---
project: <slug>
project_type: industry
file: gaps.md
generated_at: YYYY-MM-DD
version: 0.2.0
---

# <Industry> — Primary Research Gaps

## People to interview

| # | Role / Company | Why they matter | What to ask | Estimated difficulty |

## Data sources to acquire

| # | Source | What it answers | Why web search can't | Estimated cost |

## Experiments / observations

| # | Experiment | What it would reveal | How to conduct | Time required |

## Cost / time estimate

| Category | Items | Estimated cost | Estimated time |
|----------|-------|----------------|----------------|
```

## `open-secrets.md` structure

```markdown
---
project: <slug>
project_type: industry
file: open-secrets.md
generated_at: YYYY-MM-DD
version: 0.2.0
---

# <Industry> — Open Secrets

Each item carries `[source-class]` and `[confidence]`. Items without both are forbidden. Inference share capped at 20%.

## Top 3 distinctive claims (direct quote + attribution)

### 1. [Headline]
`[reported]` `[high]`

> "Direct quote here." — Person, Role, Company (source URL, publication date)

Why it matters: 1-2 sentences.

### 2. ...
### 3. ...

## Other open secrets

| # | Claim | Source class | Confidence | Citation | Why it matters |
|---|-------|--------------|------------|----------|----------------|

## Self-check log

| Attribute | Value |
|-----------|-------|
| Candidates at start | N |
| Deleted (no citation) | M |
| Deleted (failed verification) | P |
| Kept | Q |
| Reported | X |
| Community | Y |
| Inference | Z |
| Inference share | % |
```

## `sources.md` structure

```markdown
---
project: <slug>
project_type: industry
file: sources.md
generated_at: YYYY-MM-DD
version: 0.2.0
---

# <Industry> — Sources

## Primary (filings, transcripts, official)

| URL | Fetched | Source class | Claims supported |
|-----|---------|--------------|------------------|

## Specialist / analyst content

| URL | Fetched | Source class | Claims supported |
|-----|---------|--------------|------------------|

## Community

| URL | Fetched | Source class | Claims supported |
|-----|---------|--------------|------------------|
```

## `meta.json` schema

```json
{
  "industry_slug": "semiconductor-capital-equipment",
  "industry_name": "Semiconductor Capital Equipment",
  "archetype": "hardware-semiconductor",
  "generated_at": "2026-05-08T12:00:00Z",
  "version": "0.2.0",
  "framework_set": ["porter-5f", "helmer-7p", "value-chain", "profit-pool", "capital-intensity"],
  "source_counts": {
    "reported": 18,
    "community": 7,
    "inference": 4,
    "total": 29
  },
  "open_secrets_kept": 12,
  "open_secrets_deleted_in_self_check": 4,
  "files": ["thesis.md", "macro.md", "economics.md", "players.md", "scenarios.md", "analogs.md", "gaps.md", "open-secrets.md", "sources.md"]
}
```

## Slug rules

- Lowercase
- Spaces -> hyphens
- Strip special characters
- Examples: "Semiconductor Capital Equipment" -> `semiconductor-capital-equipment`; "B2B SaaS" -> `b2b-saas`

## Refresh logic

If `research/industries/<slug>/meta.json` exists when `/industry <industry>` is invoked:

1. Read the existing meta.json
2. Show the user: generated date, file count, source counts
3. Ask: refresh (delete and rebuild), augment (add new sources, keep old), or cancel?
4. If augment: load existing files into context; new sub-agents must extend, not replace, with new claims tagged with current date
