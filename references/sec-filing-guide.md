# SEC filing guide

How to extract insider-relevant signal from SEC filings. Used by the `/company` skill in Phase 1 (filings retrieval) and Phase 2 (narrative arc construction).

## EDGAR navigation

EDGAR (`sec.gov/edgar`) is free and machine-fetchable. Useful endpoints:

- Company filings list (by ticker, no auth):
  `https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=<ticker>&type=10-K`
- Full-text search:
  `https://efts.sec.gov/LATEST/search-index?q=<query>&forms=<form>`
- Recent filings RSS:
  `https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=<ticker>&type=&output=atom`
- Ticker → CIK mapping file:
  `https://www.sec.gov/files/company_tickers.json`
- XBRL company facts (machine-readable financials):
  `https://data.sec.gov/api/xbrl/companyfacts/CIK<10-digit-CIK>.json`

For private companies and recent IPOs, the S-1 / S-1/A series is essential.

## 10-K reading order

Filings are long; read in priority order. For most companies, items 1, 1A, 7, 8, 7A are 80% of the signal.

| Item | Section | Read priority |
|------|---------|---------------|
| Item 1 | Business — what the company does, segments, customers | High — read first |
| Item 1A | Risk Factors | High — see § "Risk Factor mining" |
| Item 7 | MD&A — management's discussion of financial condition | Highest — see § "MD&A reading" |
| Item 7A | Quantitative & qualitative disclosures about market risk | Medium — for financials and energy |
| Item 8 | Financial Statements + notes | High — segment data is in notes |
| Item 9A | Controls and Procedures | Skim only — flag any material weakness |
| Item 10–14 | Governance, exec comp, etc. | Use DEF 14A instead |

### Item 1 — Business

What to extract:
- Reportable segments (these define how to think about the business)
- Geographic mix
- Top customers (especially if disclosed by name or 10%+ concentration)
- Distribution channels
- Sources of competitive differentiation as management describes them
- Recent strategic shifts (compare to prior year's Item 1)

### Item 8 — Financial Statements

The income statement, balance sheet, and cash flow statement are tables. The signal is in the notes, especially:

- Segment reporting note — per-segment revenue, operating income, capex, identifiable assets
- Revenue note — disaggregation by product, geography, contract type
- Customer concentration note (if any)
- Recent acquisitions note — purchase price allocations reveal what management actually paid for
- Fair value note — for financials, the level 1/2/3 mix
- Income taxes note — effective tax rate and the rate reconciliation
- Goodwill note — impairment language is a leading indicator

## Risk Factor mining

Item 1A is where companies disclose what they're worried about. The trick is separating boilerplate from specific.

### Boilerplate (skip)

- "We may not be able to compete effectively"
- "Cybersecurity incidents could harm our business"
- "Adverse economic conditions could affect our results"
- "We rely on key personnel"
- "Litigation is uncertain"

### Specific (extract)

- Specific named competitors or specific products
- Specific named regulators or specific pending rules
- Quantified exposures ("approximately 25% of our revenue is derived from...")
- Concentration disclosures (top customer, top supplier, top geography)
- New risk factors that weren't in the prior year's 10-K (year-over-year diffing is high-signal)

### Year-over-year diffing

For any company with multiple 10-Ks, compare consecutive years' Item 1A. New risk factors are the highest signal — they reveal what management started worrying about in the past year. Removed risk factors (less common) reveal what they think they've solved.

WebSearch for "site:sec.gov \"<ticker>\" 10-K" to find consecutive years.

### Industry-relative reading

Compare a company's risk factors to peers' risk factors. If everyone else mentions a specific regulatory risk and this company doesn't, that's a signal — either of strategic positioning or of management blind spots.

## MD&A reading

Item 7 is the single highest-signal section in any 10-K. Management's discussion and analysis is where they have to translate the numbers into a narrative.

### What to extract

- Year-over-year revenue change *attribution* — how much from volume, price, mix, FX, M&A
- Margin walk — what drove margin up or down
- Capital allocation language — buybacks, dividends, M&A, capex priorities
- Segment performance — especially divergence between segments
- Forward-looking statements — quantified guidance vs. qualitative trends
- What management chose to highlight vs. de-emphasize

### Linguistic patterns to flag

- Hedge words: "we believe," "we expect," "we are seeing" — softer than "is" or "did"
- "Headwinds" / "tailwinds" — the categorization reveals which they're attributing to themselves vs. exogenous
- "Continued investment in..." — usually code for spending more, often without proportional revenue
- "Disciplined approach to..." — usually code for slowing spending
- "Operating leverage" — true operating leverage means margins expand as revenue grows; check whether the math actually supports this in segment data
- Removed phrasing — compare to prior year's MD&A; phrases that were prominent and are now absent reveal narrative drift

## Earnings transcript reading

Earnings calls have prepared remarks (PR release script + supplementary commentary) and Q&A. The Q&A is the highest-signal section in any transcript.

### Prepared remarks

Skim for:
- Quantified guidance changes (especially mid-quarter or mid-year)
- New segment disclosures
- New KPI introductions or KPI deprecations
- Specific named customers, programs, products
- Capital allocation moves announced

### Q&A — the goldmine

What to look for:
- **Analyst question patterns** — what sell-side and buy-side analysts repeatedly press on. The pattern reveals what the buy-side actually cares about.
- **Management hedge language** — does the answer directly address the question? Counts of "I think" / "we'll have to see" / "it's hard to know" are signals.
- **Quantified vs. qualitative answers** — when management has good news, they quantify; when they don't, they go qualitative
- **Topic redirection** — analyst asks about X, management answers about Y. Y is what they wanted to talk about; X is what they didn't.
- **Pricing power questions** — usually the most-asked question across calls, and the most evasively answered

### Cross-quarter narrative arc

Read 4–8 consecutive transcripts. Track:
- KPIs added or removed
- Tone on specific themes (e.g., "AI strategy")
- Guidance changes
- Specific phrases that appear and disappear

This is what `/company` Phase 2 (narrative arc) builds on.

## Proxy (DEF 14A)

The annual proxy is undervalued. Exec comp targets reveal real management priorities better than press releases.

### What to extract

- **Performance share grant criteria** — what metrics determine the CEO's PSU vest? These are the metrics the board has agreed are real measures of performance. They almost always differ from what management emphasizes publicly.
- **Equity grant patterns** — sizes year-over-year reveal board confidence
- **Board composition changes** — new committee assignments, especially audit committee chair changes, can leading-indicate disclosure issues
- **Related party transactions** — disclosed in the proxy under specific rules

If the proxy says CEO PSUs vest based on "3-year ROIC vs. peers" but management's calls all talk about revenue growth, that's a meaningful gap.

## 8-K material events

Most 8-Ks are boilerplate. Track these items only:

| Item | Content |
|------|---------|
| 1.01 | Material definitive agreement (large contract, M&A) |
| 1.02 | Termination of material agreement |
| 2.01 | Completion of acquisition or disposition |
| 2.02 | Earnings press release |
| 5.02 | Departure / appointment of officers / directors |
| 5.07 | Submission of matters to security holder vote (proxy results) |
| 7.01 | Regulation FD disclosure (often used for investor day decks) |
| 8.01 | Other material events |

Skip everything else.

## S-1 reading (recent IPOs)

S-1s contain disclosures companies don't repeat in subsequent 10-Ks. For any IPO from the past ~3 years, the S-1 is gold.

### What's in an S-1 that's not in 10-Ks

- **Cohort tables** — many SaaS / consumer / marketplace S-1s include detailed cohort retention or expansion tables. These often disappear after the IPO.
- **Customer concentration in detail** — top customers by name, by revenue, by tenure
- **Unit economics breakdowns** — CAC, LTV, payback — sometimes by segment or vintage
- **Pre-IPO financials** — shorter operating history may include earlier-stage metrics
- **Use of proceeds** — what management said they'd do with the IPO money. Compare to actual capital deployment.
- **Lockup details** — when insider selling pressure unlocks
- **Risk Factors specific to going public** — many disappear in subsequent 10-Ks

## Foreign issuers

Non-U.S. companies file 20-F (annual) and 6-K (interim). Differences from 10-K:

- 20-F is filed within 4 months of fiscal year-end (more lag than 10-K)
- 6-K filings are less standardized than 10-Q
- Statutory disclosure standards may differ — e.g., European companies disclose more on segment R&D
- ASML, TSMC, Samsung's U.S. ADRs all use 20-F. SAP files 20-F. Toyota files 20-F.

For any of these, the home-country filings (in their local language) often have more detail than the 20-F. Source via WebFetch or local market regulator's website (e.g., AFM for the Netherlands, FCA for the UK).

## Segment economics extraction

Segment reporting in Item 8 financial notes is where to find per-segment unit economics. Steps:

1. Identify reportable segments
2. Build a segment table per quarter (or per year):
   - Revenue
   - Operating income
   - Operating margin
   - Capex (if disclosed)
   - Identifiable assets
3. Calculate per-segment ROIC (NOPAT / capital employed) when capex and assets are disclosed
4. Look for divergence between segments — companies often manage to consolidated numbers while one segment subsidizes another
5. Track segment composition over time — segment definitions sometimes change, which can mask underlying trends

Companies that disclose segments by product / customer type / geography give different signals. The most useful is product-segment disclosure when it reveals concentration in profitable lines.

## Citation discipline

Per `references/trust-signal-rules.md`, every claim must carry a source class and citation. SEC filings are `[reported] [high]`. Earnings transcripts are `[reported] [high]` if from the call directly; `[reported] [medium]` if paraphrased in news. Proxy disclosures are `[reported] [high]`. Note the filing date and Item / Section reference for each claim.
