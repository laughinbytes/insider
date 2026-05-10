# Frameworks

The analytical frameworks applied during deep-dive generation. Three tiers: **core** (always run), **situational** (run when archetype matches), and **deep-dive** (VC-grade analytical approaches).

## How to use this file

- The macro analyst reads sections 1, 2, and 3 in full at the start of Phase 1.
- Section 4 is loaded by archetype: read only the playbooks matching the industry.
- Section 5 (anti-patterns) is read before synthesis to filter weak analytical moves.

---

## 1. Core frameworks (always apply)

### 1.1 Porter's Five Forces

Five structural forces that determine industry attractiveness.

| Force | Forcing question |
|-------|------------------|
| Supplier power | Who can raise prices on us? Concentration on the supply side? Switching costs to alternative suppliers? |
| Buyer power | Who can squeeze us on price? Customer concentration? Substitutes available? |
| Substitutes | What's the alternative way to solve the same job-to-be-done? Cross-elasticity? |
| New entrants | What stops a new player? Capital, regulation, scale, brand, IP? |
| Rivalry | Concentration (HHI, top-N share)? Differentiation? Exit barriers? Growth phase? |

Output: 1 paragraph per force, ending with a 1-line verdict (high / medium / low force, with the most binding constraint named).

### 1.2 Helmer's 7 Powers

| Power | One-line test |
|-------|---------------|
| Counter-positioning | Can incumbents not copy us without cannibalizing themselves? |
| Scale economies | Do unit costs fall meaningfully as we get bigger? |
| Switching costs | What does it cost a customer to leave us — money, time, risk? |
| Network economies | Does each new user make the product better for existing users? |
| Cornered resource | Do we have unique access to a scarce input (talent, IP, contract, location)? |
| Branding | Does our brand command a price premium that competitors can't match? |
| Process power | Do we have an organizational capability that takes years to replicate? |

Output: skip powers that don't apply. For each that does, provide evidence (numbers, quotes, examples).

### 1.3 Value chain decomposition

Trace the path from raw input to end customer. At each stage:
- Who plays (specific company names)
- Revenue share of total industry
- Margin profile (high / medium / low gross margin and why)
- Profit pool weight (% of total industry profit captured here)

Output as a table. The forcing question is "where does profit concentrate, and why does it stay there?"

### 1.4 Profit pool analysis (Gadiesh & Gilbert)

Where revenue is and where profit is — these are usually different.

Forcing questions:
- What % of industry revenue does each stage capture?
- What % of industry *profit*?
- If profit pools shift, in which direction?

Output: description of revenue weight vs. profit weight per stage plus 2-3 sentences on direction of shift.

### 1.5 Capital intensity / ROIC

Key metrics:
- Capex / sales
- Asset turns (revenue / total assets)
- ROIC (NOPAT / invested capital)
- Cash conversion cycle (DSO + DIO − DPO)
- Working capital intensity

Output: 2-3 sentences on whether this is asset-heavy or asset-light, with one comparable industry as reference.

---

## 2. Situational frameworks (apply per archetype)

### 2.1 Christensen's Jobs-To-Be-Done (JTBD)

What "job" is the customer hiring this product to do? Useful for consumer and product-led industries.

### 2.2 Wardley maps

Plots capabilities by visibility and evolution. Reveals what's about to commoditize.

### 2.3 Aggregation Theory (Stratechery / Ben Thompson)

Three-tier model: suppliers, distributors, end users. The party that owns the user relationship wins.

### 2.4 Crossing the Chasm (Geoffrey Moore)

Adoption lifecycle. The "chasm" is between early adopters and the early majority.

### 2.5 McKinsey 3 Horizons

Horizon 1 = current cash-cow. Horizon 2 = adjacent growth. Horizon 3 = future bets.

### 2.6 SaaS-specific: Rule of 40, Magic Number, CAC payback

- Rule of 40: revenue growth % + FCF margin % >= 40
- Magic Number: (current quarter ARR added) x 4 / (prior quarter S&M spend); >1 means efficient
- CAC payback: months to recover acquisition cost from gross margin
- NDR: % of cohort revenue retained after a year, including expansion. >100% is gold standard
- GRR: same without expansion. <90% is a leak

### 2.7 NPS / cohort retention / cohort revenue

Group customers by acquisition month or quarter; track behavior over time.

---

## 3. Deep-dive frameworks (VC-grade analysis)

These frameworks drive the analytical edge in `economics.md`, `players.md`, `scenarios.md`, and `analogs.md`.

### 3.1 Revenue build (bottom-up)

Don't take stated ARR at face value. Rebuild it:

| Component | Formula | Where to find data |
|-----------|---------|-------------------|
| Total addressable market (TAM) | # potential customers x annual value per customer | Industry reports, analyst estimates, bottoms-up calculation |
| Served addressable market (SAM) | TAM x realistic penetration % | Company disclosures, market share data |
| Current revenue | Seats/users x price x attach rate x expansion | S-1s, earnings calls, analyst models |

For each public company: show the revenue build with actual numbers. For private companies: show the implied build with confidence intervals.

### 3.2 Scenario planning

Three scenarios minimum. Each scenario must have:
- **Key assumptions**: 3-5 beliefs that must be true for this scenario to play out
- **Probability**: estimate (can be a range: "30-40%")
- **Financial implications**: what happens to revenue, margins, market structure
- **Triggers**: specific events or data that would shift probability toward this scenario
- **Timeline**: "we'll know by Q3 2026" or "this resolves over 18-24 months"

### 3.3 Historical analog pattern matching

Find 2-3 industries that went through a similar structural transition.

For each analog:
- Starting conditions: what was similar about the pre-transition state?
- Timeline: what happened, in what order, over how long?
- Winners: who captured the value, and why?
- Losers: who lost, and why?
- Inflection points: what signals preceded the transition?
- Translation: what applies to this industry?
- Breakage: what differences make the analogy fail?

Good analogs are specific and contested, not obvious. "AI coding is like the cloud transition" is lazy. "AI coding is like the transition from on-premise PLM to SaaS PLM" is specific and testable.

### 3.4 Competitive game theory

Don't just list competitors. Model the interaction:

| Move | Likely response | Counter-response | Equilibrium outcome |
|------|-----------------|------------------|---------------------|

For each major player, ask: "If they cut prices by 30%, what happens?" "If they acquire X, who responds and how?" "If they lose their exclusive deal with Y, what's the cascade?"

### 3.5 Non-consensus insight identification

The core of `thesis.md`. A non-consensus insight is something that:
- Is falsifiable (there exists evidence that could prove it wrong)
- Is not widely believed by market participants
- Has significant consequences if correct
- Is grounded in specific evidence, not just contrarianism

Process:
1. List the consensus view (what does the average informed person believe?)
2. List evidence that contradicts or complicates the consensus
3. Formulate the smallest possible claim that captures the contradiction
4. Stress-test: what would prove this wrong? Is that evidence plausibly observable?

### 3.6 Primary research gap mapping

For every key claim in the thesis, ask: "What evidence would make me confident I'm right, and can I get it from public sources?"

If no: that's a primary research gap. Document it with:
- The question it answers
- Why web search can't answer it (paywall, proprietary data, human judgment required)
- Who to talk to (specific roles, specific companies)
- Estimated cost and time

---

## 4. Industry archetype playbooks

For each archetype, the situational frameworks to add and the archetype-specific KPIs.

### 4.1 SaaS / Software

- Frameworks: Rule of 40, Magic Number, CAC payback, NDR/GRR, cohort retention, JTBD
- KPIs: ARR, ARR per rep, NDR, GRR, CAC payback (months), gross margin, R&D as % of revenue
- Sources: SEC 10-Ks (especially S-1s), earnings transcripts, Stratechery, Sacra
- Watch for: "ARR" definitions vary widely; ask for GAAP-revenue conversion

### 4.2 Marketplace / Platform

- Frameworks: Aggregation Theory, network economies, JTBD, take rate analysis, cohort retention
- KPIs: GMV, take rate, contribution margin, supply / demand growth ratio, fill rate, frequency
- Sources: 10-Ks, S-1s (Airbnb, DoorDash, Uber), Stratechery, A16z marketplace content
- Watch for: companies quoting GMV as revenue; take rate is what matters

### 4.3 Hardware / Semiconductor

- Frameworks: Wardley, capital intensity, scale economies, process power
- KPIs: gross margin, design wins, ASP, yield, capacity utilization, capex/sales, inventory days, book-to-bill
- Sources: 10-Ks, earnings calls, SEMI, SemiWiki, AnandTech, EE Times
- Watch for: cyclical normalization — peak-cycle metrics flatter than normalized

### 4.4 Consumer / CPG

- Frameworks: JTBD, branding, distribution intensity, gross-to-net analysis
- KPIs: ASP, units per household, distribution (ACV), gross-to-net erosion, SG&A leverage
- Sources: 10-Ks, IRI / Nielsen scanner data references, Beverage Digest, trade pubs
- Watch for: gross-to-net; shrinkflation signals in unit metrics

### 4.5 Healthcare / Biotech

- Frameworks: regulatory moat, JTBD, patent runway, payer dynamics
- KPIs: DRG mix, denial rate, RVUs, days in AR, drug price erosion curve, payer mix
- Sources: 10-Ks, FDA approvals, AdvaMed, Modern Healthcare, STAT News, JAMA
- Watch for: patent cliff timing; RWE replacing biostatistics in regulatory submissions

### 4.6 Financial Services

- Frameworks: regulatory moat, scale economies, switching costs, cohort retention
- KPIs: NIM, efficiency ratio, NPL ratio, ROE, CET1, deposit beta, fee income share
- Sources: 10-Ks, 10-Qs, Y-9C call reports, American Banker, Matt Levine
- Watch for: deposit beta sensitivity; "operating leverage" claims that are rate cycles

### 4.7 Industrial / Capex-heavy

- Frameworks: capital intensity, asset turns, scale economies, process power, cyclicality
- KPIs: ROIC, asset turns, capex/sales, working capital days, segment margins, backlog/orders
- Sources: 10-Ks, earnings transcripts, IndustryWeek, ISM PMI
- Watch for: order book vs. backlog vs. shipments

### 4.8 Regulated Utilities

- Frameworks: regulatory moat, capital intensity, cost of capital, rate-base growth
- KPIs: rate-base growth, allowed ROE, cost of capital, EPS growth tied to rate-base, T&D capex
- Sources: 10-Ks, FERC filings, state PUC dockets, S&P Global Utilities
- Watch for: EPS growth that's rate-base growth in disguise; allowed vs. earned ROE

### 4.9 Defense / Aerospace

- Frameworks: cornered resource, regulatory moat, switching costs
- KPIs: backlog, book-to-bill, program margins, R&D as % of sales, classified vs. unclassified mix
- Sources: 10-Ks, DoD budget, Aviation Week, Breaking Defense, CSIS / RAND
- Watch for: program transitions — declining margins late in production; cost-plus vs. fixed-price

### 4.10 Energy / Commodities

- Frameworks: capital intensity, cyclicality, scale economies, regulatory moat
- KPIs: LCOE, F&D costs, recycle ratio, breakeven price, decline rate, capex/cash flow, hedge book
- Sources: 10-Ks, EIA, IEA, Wood Mackenzie, oil and gas trade pubs
- Watch for: hedging policies that smooth reported earnings

---

## 5. Anti-patterns (avoid in output)

### 5.1 SWOT

Taught in Business 101; used by no practicing analyst. Reads like a college case study.

### 5.2 PESTLE

Pedagogical, not analytical. Practicing analysts absorb the same content into Porter's forces and regulatory frame.

### 5.3 Ansoff Matrix

Over-academic; rarely used outside b-school.

### 5.4 Generic "value proposition canvas"

Lifted from startup curriculum. Insider equivalents: JTBD, willingness-to-pay, gross-to-net.

### 5.5 "Synergy" without quantification

The word itself is a flag. Use specific mechanisms: "consolidation of back-office reducing G&A by ~150 bps."

### 5.6 Consensus restatement

The worst failure mode. If the analysis merely restates what informed people already believe, it has no value. Every thesis must contain at least one claim that a well-informed industry participant would find novel or would argue with.

### 5.7 Qualitative without quantitative anchor

"Growing fast" is worthless. "Grew 47% YoY to $2.1B, vs. 32% for the category" is useful. Every qualitative claim should have a quantitative anchor where possible.

---

## 6. Vocabulary primers

| Term | Definition | What high means | What low means |
|------|------------|-----------------|----------------|
| Capital intensity | Capex as % of sales | Asset-heavy; ROIC depends on utilization | Asset-light; can scale without proportional capex |
| Asset turns | Revenue / total assets | Efficient asset utilization | Excess capacity or asset-heavy model |
| ROIC | NOPAT / invested capital | Capital-allocation skill | Either over-investing or undifferentiated |
| Cash conversion cycle | DSO + DIO − DPO (days) | Working capital tied up | Negative — customers fund the business |
| Gross-to-net | Gross revenue − rebates/returns/allowances = net revenue | Healthy net realization | Trade promotion or rebate erosion |
| Take rate | Platform revenue / GMV | Strong platform power | Commoditized; suppliers retain pricing |
| Contribution margin | Revenue − variable cost (ex-fixed) | Unit economics work | Unit economics broken |
| NRR / NDR | Cohort revenue end / cohort revenue start; >100% = expansion exceeds churn | Best-in-class SaaS | Leaking cohort |
| GRR | NRR without expansion | Even retention is healthy | Product-market-fit erosion |
| Magic Number | (ΔARR x 4) / S&M; >1 = efficient | Add reps | Don't add reps |
| Rule of 40 | Growth % + FCF margin % >= 40 | Healthy growth-profitability balance | One of the two is breaking |
| Backlog / book-to-bill | Orders / shipments | Demand is leading shipments | Demand is softening |
| Net interest margin (NIM) | (Interest income − interest expense) / earning assets | Pricing power on lending | Compressed lending economics |
| Efficiency ratio (banks) | Non-interest expense / revenue | (high = bad) | (low = good — banks aim for 50–60%) |
| LCOE | Levelized cost of energy ($/MWh) | Expensive | Competitive vs. alternatives |
| Decline rate (E&P) | Year-over-year production decline of existing wells | Treadmill is faster | Capital efficiency favors investment |

When in doubt, prefer the industry-specific term over the general finance term.
