# Trust-signal rules

These rules prevent the most dangerous failure mode in deep-dive analysis: confident-sounding claims that trace to nothing. They apply to every claim, with strictest enforcement on open secrets.

## Source-class tagging

Every claim in `open-secrets.md` and every "industry knows" assertion MUST carry one of these tags:

- `[reported]` — appears in an earnings call, journalistic piece, analyst report, regulatory filing, or company-published material. Citation required: URL + date.
- `[community]` — appears on Reddit, Hacker News, Glassdoor, Blind, or industry forum, with at least two corroborating posts (different authors, different threads). Citation required: >=2 URLs.
- `[inference]` — reasoning from public data. Must be flagged. Capped at 20% of items per file.
- `[unverified]` — excluded by default. Only included if user explicitly asks for "rumor mode."

Items without a tag are omitted.

## Confidence

Four levels: `[high]`, `[medium-high]`, `[medium]`, `[low]`. Map source class + corroboration + recency:

- `[reported]` from primary documents (SEC filings, regulator dockets, official transcripts) -> `[high]`
- `[reported]` with ≥2 independent sources, recent (≤6 months) -> `[high]`
- `[reported]` from mainstream business journalism (WSJ, FT, Reuters, Bloomberg) or specialist/trade press, recent -> `[medium-high]`
- `[reported]` single source, or older than 6 months -> `[medium]`
- `[community]` with 3+ posts, or credentialed author -> `[medium]`
- `[community]` with 2 posts, anonymous -> `[low]`
- `[inference]` -> `[low]` always

`${CLAUDE_PLUGIN_ROOT}/references/schemas.md` and `${CLAUDE_PLUGIN_ROOT}/references/data-sources.md` § 6 use the same 4-level scale; do not introduce additional levels.

## Staleness

Every citation includes the source publication date. Claims older than the archetype's stale window should be updated or dropped:

| Archetype | Stale after |
|-----------|-------------|
| AI / SaaS / Software | 9 months |
| Marketplace / Platform | 12 months |
| Hardware / Semiconductor | 18 months |
| Consumer / CPG | 18 months |
| Healthcare / Biotech | 24 months |
| Financial services | 18 months |
| Industrial / Capex-heavy | 24 months |
| Regulated utilities | 36 months |
| Defense / Aerospace | 36 months |
| Energy / Commodities | 18 months |

## Non-consensus insight rules

Every item in `open-secrets.md` must pass three additional tests beyond source class + citation:

### Test 1: Explicit consensus contrast

The item must include both:
- **What the market believes** (consensus view, one sentence)
- **What we believe differently** (non-consensus view, one sentence)

Without this contrast, the item is either (a) actually consensus, or (b) not clearly differentiated. Either way, it fails.

### Test 2: Falsifiability

The non-consensus view must include a falsification condition: "If X happens by date Y, this insight is wrong."

Example (good): "If TSMC adopts High-NA EUV for A16 by end of 2027, our 'pricing ceiling' thesis is wrong."
Example (bad): "ASML may face competition someday." (no falsification condition, no edge)

### Test 3: Red-team resistance

Before keeping an item, the author must articulate:
- **The strongest counter-argument** someone smart would make
- **Why that counter-argument is wrong** (with evidence, not dismissal)

If the counter-argument cannot be refuted with evidence, the item is weak. Delete it.

## The hard rule

> No item without source class + citation + explicit consensus contrast. Empty is better than wrong.

## The 20% inference cap

At most one in five items in `open-secrets.md` can be `[inference]`. If the macro pass produced 20 candidates and 8 are inference, drop the 4 weakest.

## Direct-quote requirement

For the top 3 most distinctive claims in each brief, a direct quote with attribution is required:

> "Direct quote here." — Person Name, Role, Company (source URL, date)

If no quote can be found, demote the claim.

## Self-check pass

After all phases complete:

1. Re-read `open-secrets.md` from scratch
2. Verify each citation: confirm the claim appears in fetched content
3. Audit inference items: confirm reasoning chain is 1-2 steps from public data
4. Delete or downgrade anything that fails
5. Recount classes; confirm inference <= 20%
6. Report counts: "Open secrets: 12 kept, 4 deleted. Breakdown: 6 reported, 4 community, 2 inference."

## Domain-metrics rule

Every brief must include at least 5 industry-specific quantitative metrics. Generic metrics (revenue, margin, EBITDA) do not count. The bar: a metric counts if searching for it returns industry-specific explanations, not generic finance-101 definitions.

Counts: RevPAR, ARPU, ARR per rep, gross-to-net, DRG mix, tape-out delay, takt time, yield ramp, contribution margin per cohort, fill rate, asset turns, NRR, magic number, LCOE, rate-base growth, expense ratio, NPL ratio.

Doesn't count: revenue growth, gross margin, EBITDA, market share (unless paired with HHI or top-N specifics).
