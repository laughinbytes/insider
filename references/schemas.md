# Data Schemas

Structured data layer beneath the markdown output. Every claim, entity, source, and metric gets written here alongside the prose.

## claims.jsonl

One line per claim. Append-only. Regenerating a project truncates and rebuilds its claims.

```json
{
  "id": "claim-001",
  "project_slug": "ai-coding-assistants",
  "project_type": "industry",
  "claim": "App-layer vendors run negative gross margins on heavy users",
  "file": "economics.md",
  "section": "Unit economics",
  "source_class": "reported",
  "confidence": "medium-high",
  "sources": [
    {"url": "https://sacra.com/c/codeium", "pub_date": "2025-07-15"}
  ],
  "inference_chain": null,
  "entities": ["Codeium"],
  "tags": ["margin", "unit-economics"],
  "stale_after": "2026-04-15",
  "created_at": "2026-05-09"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | `claim-{N}` auto-incremented per project |
| `project_slug` | string | Links to research/industries/ or research/companies/ |
| `project_type` | enum | `industry` or `company` |
| `claim` | string | The factual statement |
| `file` | string | Which markdown file this claim appears in |
| `section` | string | Section heading within the file |
| `source_class` | enum | `reported`, `community`, `inference` |
| `confidence` | enum | `high`, `medium-high`, `medium`, `low` |
| `sources` | array | Objects with `url` and `pub_date` |
| `inference_chain` | string or null | For inference claims: reasoning steps |
| `entities` | array | Named entities this claim references |
| `tags` | array | Free-form topic tags |
| `stale_after` | string (ISO date) or null | Computed from archetype staleness window |
| `created_at` | string (ISO date) | When this claim was first written |

## entities.json

Accumulates across all projects. Updated on every research run.

```json
{
  "entities": [
    {
      "id": "entity-001",
      "name": "Cursor",
      "type": "company",
      "aliases": ["Anysphere"],
      "industries": ["ai-coding-assistants"],
      "first_seen": "2026-05-09",
      "last_seen": "2026-05-09",
      "claim_ids": ["claim-001", "claim-002"],
      "metrics_tracked": ["ARR", "gross-margin"]
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | `entity-{N}` global |
| `name` | string | Canonical name |
| `type` | enum | `company`, `person`, `product`, `metric`, `regulator` |
| `aliases` | array | Alternative names |
| `industries` | array | Slugs of industries where this entity appears |
| `first_seen` | string (ISO date) | First research run where entity appeared |
| `last_seen` | string (ISO date) | Most recent research run |
| `claim_ids` | array | All claims referencing this entity |
| `metrics_tracked` | array | Metrics tracked for this entity |

## sources.jsonl

One line per unique URL. Accumulates across all projects.

```json
{
  "url": "https://sacra.com/c/codeium",
  "title": "Codeium - Sacra",
  "first_seen": "2026-05-09",
  "last_checked": "2026-05-09",
  "status": "valid",
  "status_code": 200,
  "projects": ["ai-coding-assistants"],
  "claim_count": 3
}
```

| Field | Type | Description |
|-------|------|-------------|
| `url` | string | Primary key |
| `title` | string | Page title or description |
| `first_seen` | string (ISO date) | First time this URL was cited |
| `last_checked` | string (ISO date) | Last health check |
| `status` | enum | `valid`, `dead`, `moved`, `changed`, `unchecked` |
| `status_code` | int or null | HTTP status from last check |
| `projects` | array | Slugs of projects citing this URL |
| `claim_count` | int | Number of claims dependent on this URL |

## metrics.jsonl

One line per metric observation. Append-only.

```json
{
  "timestamp": "2026-05-09",
  "entity_id": "entity-001",
  "entity_name": "Cursor",
  "metric": "ARR",
  "value": 2000000000,
  "unit": "USD",
  "source_url": "https://sacra.com/c/cursor",
  "confidence": "medium",
  "project_slug": "ai-coding-assistants"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | string (ISO date) | Observation date |
| `entity_id` | string | Links to entities.json |
| `entity_name` | string | Denormalized for readability |
| `metric` | string | Metric name |
| `value` | number or string | Observed value |
| `unit` | string | `USD`, `%`, `count`, etc. |
| `source_url` | string | Where this number came from |
| `confidence` | enum | `high`, `medium`, `low` |
| `project_slug` | string | Which research project recorded this |

## Conventions

- All dates are ISO 8601: `YYYY-MM-DD`
- `null` is preferred over missing keys
- JSONL files are append-only from the orchestrator's perspective
- `entities.json` is read-modify-write (update existing, add new)
- `sources.jsonl` is read-modify-write by URL key

## reading/<slug>/numerics.json

Sibling of `reading/<slug>/index.html`. Written by `assembler` at the end of Phase 4. Lists every numeric annotation in the page (hero metrics, chart bars, table cells, open-secret quoted figures) with its grounding claim and (for ratios) its explicit denominator. Read by `${CLAUDE_PLUGIN_ROOT}/tools/verify-numerics.sh` for code-based validation; without it the verifier falls back to noisy regex extraction.

```json
{
  "slug": "ai-agents",
  "page": "reading/ai-agents/index.html",
  "generated_at": "2026-05-10",
  "annotations": [
    {
      "id": "hero-metric-arr",
      "label": "Headline Agent ARR",
      "text": "$50B",
      "value": 50,
      "unit": "USD_B",
      "approximate": true,
      "claim_ids": ["claim-3"],
      "context": "hero, gross-counted"
    },
    {
      "id": "chart1-bar-net",
      "label": "Net app-layer value-add",
      "text": "$5–7B",
      "value_min": 5,
      "value_max": 7,
      "unit": "USD_B",
      "claim_ids": ["claim-3"],
      "context": "section 1 chart, Bar 4"
    },
    {
      "id": "openSecret-3-nrr-delta",
      "type": "ratio",
      "label": "Intercom Fin NRR jump",
      "text": "112% → 146%",
      "numerator_id": "openSecret-3-nrr-after",
      "denominator_id": "openSecret-3-nrr-before",
      "claimed_delta": 34,
      "computed_delta": 34,
      "unit": "pct_points",
      "claim_ids": ["claim-2"]
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `slug` | string | yes | Project slug |
| `page` | string | yes | Path to the reading HTML this manifest covers |
| `generated_at` | string (ISO date) | yes | When the manifest was emitted |
| `annotations[].id` | string | yes | Unique within page (kebab-case) |
| `annotations[].label` | string | yes | Human-readable name (matches HTML label) |
| `annotations[].text` | string | yes | The exact text in the HTML (e.g., "$5–7B", "146%", "12.7x") |
| `annotations[].type` | enum | no | `value` (default) / `range` / `ratio` / `percentage` / `multiple` |
| `annotations[].value` | number or null | for type=value | Single numeric value |
| `annotations[].value_min`, `value_max` | number | for type=range | Range bounds |
| `annotations[].unit` | enum | yes | `USD_B` / `USD_M` / `USD_T` / `USD_K` / `pct` / `pct_points` / `x` / `count` |
| `annotations[].approximate` | bool | no | True if text uses "~" or "approx" |
| `annotations[].claim_ids` | array | yes | At least one `claim-N` id from `data/claims.jsonl` (project_slug = current) |
| `annotations[].context` | string | no | Where in the page (section, chart, etc.) |
| `annotations[].numerator_id`, `denominator_id` | string | for type=ratio | IDs of other annotations that the ratio relates |
| `annotations[].claimed_delta`, `computed_delta` | number | for type=ratio | Should match within ±5% tolerance |

**Verifier rules:**
1. Every `claim_ids[]` must exist in `data/claims.jsonl` with matching `project_slug`.
2. `text` must appear (substring) in at least one of the cited claims.
3. For `type=ratio` with denominator_id: verify (numerator.value − denominator.value) ≈ claimed_delta, OR (numerator.value / denominator.value) ≈ claimed_ratio.
4. For `type=range`: verify `value_min < value_max`.
5. For `type=percentage` with denominator_id: verify (value/100) × denominator.value ≈ numerator.value within ±5%.
6. For `type=transition`: every `removed[].constituent_id` and `added[].constituent_id` must reference an existing annotation in the same numerics.json. **Across all transitions in a chart (annotations sharing the same `chart_id` prefix), no `constituent_id` may appear in `removed[]` more than once** — this catches the "same dollars subtracted twice" double-count class of error (CRITICAL gap). Sum: `from.value − Σ removed.value + Σ added.value ≈ to.value` within ±5%.

### Annotation type: `transition`

Used for every `−` / `+` / `→` arrow in a chart that asserts a quantitative relationship between two boxes/bars. **Required when the chart has any bridge / waterfall / flow step.** Forbids amorphous labels like "−foundation+platform double-count" — every constituent must be named.

```json
{
  "id": "chart1-step-from-headline-to-app",
  "type": "transition",
  "chart_id": "chart1",
  "from_id": "chart1-headline-50b",
  "to_id": "chart1-app-topline",
  "removed": [
    {"constituent_id": "ff-foundation-direct", "value": 52, "unit": "USD_B"},
    {"constituent_id": "ff-platform-resale", "value": 5, "unit": "USD_B"}
  ],
  "added": [],
  "claim_ids": ["claim-3"],
  "context": "section 1 chart, headline → app-layer step",
  "label_text": "−$52–53B foundation direct + $5B platform resale"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | Unique within page |
| `type` | enum | yes | `"transition"` |
| `chart_id` | string | yes | Group key — annotations sharing this id form one chart, used for cross-step overlap check |
| `from_id` | string | yes | Annotation id of the source box/bar |
| `to_id` | string | yes | Annotation id of the destination box/bar |
| `removed` | array | yes | List of `{constituent_id, value, unit}` for each subtracted item — every `constituent_id` must reference an existing annotation |
| `added` | array | yes | List of `{constituent_id, value, unit}` for each added item (empty if pure subtraction) |
| `claim_ids` | array | yes | Underlying claim(s) supporting this transition |
| `label_text` | string | yes | The exact text used in the chart's HTML/SVG label — must enumerate constituents, not be a category name |
