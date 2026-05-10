# Data sources

Where to look for industry intelligence, ranked by source quality. Encoded as patterns rather than rigid recipes — apply the right ones for the archetype.

The macro analyst sub-agent and the company skill both read this file. The orchestrator reads sections 6 and 7 (source quality scoring + what to avoid) before the synthesis pass.

---

## Tool Priority for Source Discovery

Agents MUST follow this tool priority. Using the wrong tool wastes tool calls and hits permission errors.

| Priority | Tool | When to use | When NOT to use |
|----------|------|-------------|-----------------|
| **1** | `WebSearch` | General research, discovery, finding sources, fact-checking | Never for direct file downloads |
| **2** | `mcp__gemini-search__web_search` | Fallback when WebSearch fails or returns thin results | Same as above |
| **3** | `WebFetch` | ONLY for known-reliable domains (see whitelist below). Fetching specific pages after discovering them via search. | NEVER for news sites, blogs, analyst sites — high 404/403/paywall rate |
| **4** | `Bash` | File ops, data processing (`jq`, `python3`), project scripts (`${CLAUDE_PLUGIN_ROOT}/tools/query.sh`); `curl` and `agent-browser` are acceptable as WebFetch fallbacks per the multi-tool fallback chain below | NEVER as the *primary* search tool — always try WebSearch / `mcp__gemini-search__web_search` first |

### WebFetch domain whitelist (reliable, low block rate)

| Domain | Content | Tool |
|--------|---------|------|
| `sec.gov` / `*.sec.gov` | SEC filings, EDGAR | WebFetch |
| `wikipedia.org` / `*.wikipedia.org` | General reference | WebFetch |
| `*.investor.*` | Company investor relations | WebFetch |
| `companiesmarketcap.com` | Market cap rankings | WebFetch |
| `github.com` / `github.blog` | Technical docs, releases | WebFetch |
| Company official domains | Press releases, annual reports | WebFetch |

**Do NOT WebFetch:** Reuters, Bloomberg, TechCrunch, The Information, The Verge, CNBC, Forbes, Motley Fool, Seeking Alpha (paywall/bot-blocking). Use WebSearch for these instead.

---

### WebFetch failure handling

When fetching a specific URL fails, agents MUST exhaust the multi-tool fallback chain before giving up:

1. **Log the failure** to `.checkpoint/webfetch-failures.jsonl`
2. **Try the next tool in the chain** — do not retry the same tool
3. **Only after all fetch tools fail**, switch to WebSearch

**Multi-tool fallback chain:**

| Step | Tool | Command / Notes |
|------|------|-----------------|
| 1 | `WebFetch` | Native tool, preferred |
| 2 | `Bash: curl` | `curl -sL -A "Mozilla/5.0" --max-time 15 <URL>` — different network stack |
| 3 | `Bash: agent-browser` | `agent-browser open <URL> && agent-browser snapshot` — real browser, may bypass anti-bot |
| 4 | `WebSearch` | `site:<domain> <keywords>` — get summary instead |

**Why multiple tools?** Each may succeed where others fail. WebFetch and curl use different HTTP libraries. agent-browser uses real Chromium and may bypass User-Agent blocks or simple bot detection.

**Log once, not per tool:** Log the original URL to `.checkpoint/webfetch-failures.jsonl` after the first failure. Do not log again for the same URL in the same session.

#### Error type classification (use these exact strings)

| Error | HTTP/Network | Classification | Action |
|-------|-------------|----------------|--------|
| 404 Not Found | HTTP | `not-found` | Page does not exist — website's problem |
| 403 Forbidden | HTTP | `forbidden` | Access denied — could be anti-bot or firewall |
| 401 Unauthorized | HTTP | `unauthorized` | Requires authentication |
| 410 Gone | HTTP | `gone` | Permanently removed |
| 429 Too Many Requests | HTTP | `rate-limited` | Request frequency blocked |
| 5xx Server Error | HTTP | `server-error` | Server-side problem |
| timeout | Network | `timeout` | Connection timed out |
| ECONNREFUSED / DNS / SSL | Network | `connection-failed` | Connection layer failure |
| Other | — | `unknown` | Unclassified |

**Log format** (single line JSONL, append with Bash):
```json
{"ts":"2026-05-10T12:00:00Z","phase":"macro","agent":"macro","url":"https://example.com/page","domain":"example.com","error_type":"not-found","error_detail":"404 Not Found"}
```

**After-the-fact analysis:** Use `${CLAUDE_PLUGIN_ROOT}/tools/query.sh webfetch-failures` to analyze patterns. A domain that repeatedly shows `timeout` or `forbidden` likely indicates a network restriction on our side.

---

## 1. General-purpose sources (always fair game)

### SEC EDGAR — `sec.gov/edgar`

The single highest-signal corpus for any U.S. public company or recent IPO. Free, full-text searchable, machine-fetchable.

| Filing | What it contains | Read priority |
|--------|------------------|---------------|
| 10-K | Annual report — Items 1 (Business), 1A (Risk Factors), 7 (MD&A), 8 (Financials) | Always first |
| 10-Q | Quarterly update — usually only MD&A changes vs. 10-K | After 10-K |
| S-1 | IPO prospectus — first-time disclosure of cohorts, customer concentration, unit economics | Gold for recent IPOs |
| DEF 14A | Annual proxy — exec comp targets reveal real management priorities | Underused; high signal |
| 8-K | Material events — earnings releases, CEO changes, M&A, debt issuance | Skim only Items 1.01, 2.02, 5.02, 7.01 |

Useful EDGAR endpoints:
- Full-text search: `https://efts.sec.gov/LATEST/search-index?q=<query>&forms=10-K`
- Company filings list: `https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=<ticker>&type=10-K`
- Direct CIK lookup: company name → CIK via the EDGAR ticker file

### Earnings call transcripts

| Source | Cost | Notes |
|--------|------|-------|
| Company IR pages | Free | Often only audio + slides; no transcript |
| Seeking Alpha | Free with signup; some paywalled | Usually full transcript within 24h of call |
| Motley Fool | Free | Decent coverage of mid-cap and larger |
| AlphaSense | Paid | Highest fidelity if available; usable via WebFetch when shared |

The Q&A section is the highest-signal part of any transcript. Analyst questions reveal what the buy-side and sell-side actually care about — often more than management's prepared remarks.

### Government / macro data

- BLS (Bureau of Labor Statistics) — wages, employment by industry NAICS codes
- BEA — GDP by industry, capex statistics
- Census Bureau — demographic and household data
- OECD / Eurostat — international comparison data
- IMF World Economic Outlook — country-level macro
- Federal Reserve — bank call reports (FFIEC), industrial production, capacity utilization
- EIA / IEA — energy data
- FDA / FTC / FCC / FAA / FERC — regulator-specific filings

### Industry trade publications (per archetype, see section 4)

Trade publications are where industry insiders write to each other without translating for general audiences. Higher signal-to-noise than general business press.

---

## 2. Community / sentiment sources

These are where IC-level voice lives. Crucial for the IC layer brief and for surfacing open-secret candidates.

### Reddit

Per-archetype subreddit map:

- SaaS / Software: r/SaaS, r/startups, r/programming, r/sales, r/marketing, r/MachineLearning
- Marketplace: r/Entrepreneur, archetype-specific (r/Etsy, r/AmazonSeller, r/Shopify)
- Hardware / Semiconductor: r/semiconductor, r/ECE, r/hardware, r/chipdesign
- Consumer / CPG: r/CPG, r/RetailerStrats, r/FoodIndustry
- Healthcare / Biotech: r/medicine, r/HealthIT, r/biotech, r/pharma, r/nursing, r/medicalschool
- Financial Services: r/personalfinance (consumer voice), r/banking, r/wallstreetbets (sentiment, with skepticism), r/CreditCardBenefits
- Industrial: r/manufacturing, r/engineering, r/Construction, r/Plumbing
- Defense / Aerospace: r/AirForce, r/Military, r/Aerospace, r/DefenseContracting (small)
- Energy: r/oilandgasworkers, r/energy, r/Solar
- Utilities: r/Powerlineman, r/utilities

Search pattern: `site:reddit.com "<industry term>" "<insider phrase>"` via WebSearch (fallback: `mcp__gemini-search__web_search`), or fetch a subreddit's top posts of the year and search within.

### Hacker News

Best for tech-adjacent industries. Search: `https://hn.algolia.com/?q=<query>` — sort by popularity and date. The comment threads on a 200-point post about an industry are often more useful than the linked article.

### Glassdoor

- Reviews are noisy but skim for repeated themes
- **Interview experiences** — usually more candid than reviews; show what the company actually asks and how the process feels
- Salary data is unreliable as primary; corroborate with Levels.fyi for tech

### Blind

Anonymous professional network. High candor but only for tech / finance / consulting. Search public posts via WebSearch (fallback: `mcp__gemini-search__web_search`): `site:teamblind.com "<company>" "<topic>"`.

### Levels.fyi

The IC compensation source for tech. Per-company, per-level, per-location data. Useful for IC layer ("what's the comp band conversation") and for sizing engineering org costs.

### GitHub Issues

Public issue trackers reveal real product friction. For developer-tooling companies and open-source-adjacent industries, this is the highest-fidelity IC voice.

### X / Twitter expert lists

Curated lists per industry. Examples:
- Semis: Doug O'Laughlin, Chris Caso, Stacy Rasgon
- SaaS: Jamin Ball, Tomasz Tunguz, David Sacks
- Healthcare: Bob Wachter, Eric Topol
- Energy: Robert Rapier, Liam Denning
- Banking: Marc Rubinstein

### Discord / Slack archives

Many industry communities have Discord/Slack archives indexed by Google. Search: `<industry term> "discord.com/channels"` or via specialty community search engines.

---

## 3. Analyst / pundit content (with quality flags)

These are the public-facing equivalents of sell-side initiating coverage reports. Variable quality — flag each.

| Source | Coverage | Quality flag |
|--------|----------|--------------|
| Stratechery (Ben Thompson) | Tech, platforms, media | Highest signal for aggregation theory framing |
| The Information | Tech and AI, breaking news | Reporting > analysis; cite specific articles |
| Sacra | Private companies | Solid for venture-stage analysis; check date — fast-moving private market |
| Matt Levine (Money Stuff) | Finance, regulation | Highest for legal-finance framing; daily column |
| Benedict Evans | Tech, mobile, AI | Slide-deck style; clear thinking on adoption curves |
| Substacks per industry | Varies | Find via X follows of credible analysts |
| A16z, USV, Sequoia memos | Venture | Read for theses, not for unbiased market views |
| Sell-side notes summaries on X | Equity research | Quote-able when shared; primary access usually paywalled |

---

## 4. Per-archetype source maps

For each archetype, the canonical 5–10 sources to actually check.

### SaaS / Software

1. SEC 10-Ks of comparables (especially S-1s of recent IPOs for cohort tables)
2. Earnings transcripts
3. Stratechery
4. Jamin Ball's "Clouded Judgement" Substack
5. Tomasz Tunguz blog
6. Sacra (for private comparables)
7. Reddit: r/SaaS, r/startups
8. Levels.fyi (for engineering org cost sizing)
9. Public board materials when available (DocuSign, Okta historical investor days are good)
10. Battery Ventures' OpenCloud / Bessemer Cloud Index reports

### Marketplace / Platform

1. Airbnb, DoorDash, Uber S-1s + 10-Ks (gold standards)
2. Stratechery (aggregation theory primary source)
3. A16z marketplace content (Andrew Chen)
4. NFX papers
5. Sacra for private marketplaces
6. Operator-written posts on Substack / Medium
7. Reddit operator communities per archetype
8. Sensor Tower / Apptopia for app-based marketplaces
9. Industry-specific trade pubs

### Hardware / Semiconductor

1. SEC 10-Ks (TSMC 20-F, ASML 20-F, AMAT, LRCX, KLAC)
2. Earnings calls — semiconductor calls are unusually substantive
3. SEMI industry data and reports
4. SemiWiki
5. AnandTech / Tom's Hardware
6. EE Times / Electronic Design
7. Reddit r/semiconductor
8. Doug O'Laughlin's Semianalysis (Substack)
9. Stacy Rasgon's notes (when shared)
10. Industry conferences: SEMICON West, IEDM proceedings, ISSCC papers

### Consumer / CPG

1. SEC 10-Ks (PG, KO, PEP, KHC, NSRGY)
2. Earnings transcripts
3. Beverage Digest, Ad Age, Adweek
4. IRI / Circana / Nielsen scanner data references in earnings calls
5. Trade pubs: Grocery Dive, Convenience Store News
6. Reddit r/CPG, r/RetailerStrats
7. Walmart and Target investor day transcripts (largest customer)
8. Trade marketing job postings on LinkedIn (reveal CPG sales structure)

### Healthcare / Biotech

1. SEC 10-Ks (UnitedHealth, HCA, Pfizer, Lilly, Vertex)
2. FDA approvals database (drugs@fda.gov)
3. Modern Healthcare / Becker's Hospital Review
4. STAT News (biotech)
5. JAMA / NEJM (clinical evidence)
6. Endpoints News (pharma)
7. The Health Care Blog
8. Reddit r/medicine, r/pharma, r/biotech
9. Industry conferences: JPM Healthcare, ASCO, ASH abstracts
10. CMS rule-making documents

### Financial Services

1. SEC 10-Ks, 10-Qs (JPM, BAC, WFC, BlackRock, Schwab)
2. FFIEC call reports (Y-9C)
3. American Banker / S&P Global
4. Matt Levine
5. Marc Rubinstein's "Net Interest" Substack
6. Federal Reserve speeches (especially Vice Chair for Supervision)
7. Bank investor day transcripts
8. Reddit r/banking
9. Bond Buyer (muni / public finance)

### Industrial / Capex-heavy

1. SEC 10-Ks (Caterpillar, Deere, Honeywell, Illinois Tool Works, Emerson)
2. Earnings transcripts
3. IndustryWeek, Modern Materials Handling
4. ISM Manufacturing PMI (monthly)
5. ABI (Architecture Billings Index — leading construction)
6. Reuters / Bloomberg industrials coverage
7. FRED industrial production series
8. Trade journals per sub-segment (e.g., Plastics News, American Machinist)

### Regulated Utilities

1. SEC 10-Ks (Duke, Southern, Dominion, NextEra, Sempra)
2. State PUC dockets (each company's utility state)
3. FERC filings and orders
4. S&P Global Utilities
5. Edison Electric Institute (EEI) reports
6. Earnings transcripts (utility analysts ask very specific questions)
7. Smart Electric Power Alliance (SEPA)
8. Investor days — utilities run very disciplined IR

### Defense / Aerospace

1. SEC 10-Ks (Lockheed, Northrop, RTX, Boeing, GD)
2. DoD budget appropriations (House and Senate Armed Services Committee documents)
3. Aviation Week
4. Breaking Defense
5. Defense News
6. CSIS / RAND / CNAS think-tank reports
7. Government accountability office (GAO) reports on specific programs
8. Trade events: Paris Air Show, Farnborough, AUSA

### Energy / Commodities

1. SEC 10-Ks (XOM, CVX, OXY, EOG, Pioneer)
2. EIA STEO and weekly petroleum data
3. IEA reports (when shared free)
4. Wood Mackenzie summaries (paid but referenced in news)
5. Bloomberg / Reuters energy coverage
6. Argus Media, Platts (paid but quoted in news)
7. Industry conferences: CERAWeek, OTC, NAPE
8. State oil and gas commission data (Texas RRC, North Dakota DMR)
9. Reddit r/oilandgasworkers (operator voice)

---

## 5. Search query patterns

For specific information needs, these query patterns work via WebSearch (fallback: `mcp__gemini-search__web_search`):

| Information need | Query pattern |
|------------------|---------------|
| Open secret candidates | `"<industry>" "open secret" OR "everybody knows" OR "dirty secret"` |
| IC frustration | `site:reddit.com "<industry>" "frustrating" OR "annoying" OR "stupid"` |
| Earnings call concerns | `"<company>" "earnings call" "concerned about" OR "watching closely"` |
| Specific KPI explanations | `"<KPI>" "<industry>" "definition" OR "calculation"` |
| Competitive dynamics | `"<company>" vs. "<competitor>" "win rate" OR "displaced" OR "switching"` |
| Pricing reality | `"<industry>" "discount" OR "concession" OR "pricing pressure"` |
| Hiring signals | `site:linkedin.com/jobs "<company>" "<role>"` (often reveals stack and team structure) |
| Product roadmap leaks | `site:github.com "<company>" "issue" "roadmap"` (open-source-adjacent only) |

---

## 6. Source quality scoring

Used to assign source classes per `trust-signal-rules.md`. From highest to lowest:

1. **Primary documents** — SEC filings, regulator dockets, official transcripts. → `[reported]` `[high]`
2. **Mainstream business journalism** — WSJ, FT, Reuters, Bloomberg with named reporter. → `[reported]` `[medium-high]`
3. **Specialist / trade journalism** — STAT, The Information, Aviation Week. → `[reported]` `[medium-high]`
4. **Recognized analyst / pundit blogs** — Stratechery, Matt Levine, Net Interest. → `[reported]` `[medium]` (with byline + date)
5. **Industry conference materials** — slides, recordings. → `[reported]` `[medium]`
6. **Corroborated community posts** — multiple independent posts on Reddit / HN / Blind / Glassdoor. → `[community]` `[medium]` (with ≥2 sources, different authors)
7. **Single community post** — one anonymous post, even on a credible forum. → `[community]` `[low]` only if a precise specific factual claim
8. **Social media** — X / LinkedIn posts, even from credible figures, without underlying citation. → `[community]` `[low]` and only if clearly attributable
9. **AI-generated summaries** — never. Skip entirely.

---

## 7. What to avoid

These sources tend to fabricate, paraphrase imprecisely, or recycle outdated info. Skip them.

- AI-summary "industry trends" sites (most appearing in 2024–2026 with thin source citations)
- Content farms with title patterns like "10 surprising trends in [industry] for 2026"
- Industry consultancy "trend reports" >2 years old; the methodology age compounds
- Vendor-sponsored "research" presented as neutral analysis
- Wikipedia for current dynamics (fine for historical facts)
- Marketing-deck "thought leadership" without specific citations
- Anonymous "industry insider" Substacks without verifiable bylines or methodology
- Press release rewrites — find the original release on the company IR site instead
- Generic Investopedia explanations of industry-specific terms — not wrong, but pedagogical, and using their phrasing flags you as outsider

When in doubt, follow the citation chain backward to a primary source. If there isn't one, omit the claim.
