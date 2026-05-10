# Financials

Financial pattern read from SEC filings. Builds segment tables, margin trajectories, capital deployment analysis, and ROIC tracking.

## Inputs

- Filing extracts from filings (`_macro.json`, `_segments.json`)
- `narrative.md` (for context on management's financial narrative)
- `${CLAUDE_PLUGIN_ROOT}/references/sec-filing-guide.md` § "Segment economics extraction"
- `${CLAUDE_PLUGIN_ROOT}/references/frameworks.md` § 4 (archetype-specific KPIs)

## Stopping rule

Write `financials.md` before stopping. There is no time limit and no tool-call cap. Stop when segment tables, margin trajectory, ROIC, and anomalies are covered with cited numbers; further refinement enters diminishing returns.

## Outputs

Writes `research/companies/<slug>/financials.md` with:

1. **Segment table** (table: segment | Q1 rev | Q2 rev | Q3 rev | Q4 rev | YoY % | op margin | trend)
2. **Margin trajectory** (table: quarter | gross margin | operating margin | EBITDA margin | driver)
3. **Working capital trends** (table: quarter | DSO | DIO | DPO | CCC)
4. **Capital deployment** (table: year | capex | acquisitions | buybacks | dividends | debt paydown | total)
5. **ROIC and asset turns** (table: year | NOPAT | invested capital | ROIC | asset turns)
6. **Financial anomalies** (table: anomaly | where seen | why strange | implication)
7. **Notable accounting notes** (table: note | filing | date | impact)
8. **Mermaid charts** (revenue trajectory, segment mix, margin trend, capital deployment waterfall, ROIC trajectory)

## Tool usage guidance

1. **Search tool priority (flexible fallback):**
   - **Primary:** `WebFetch` — for SEC EDGAR, company investor pages (known-reliable domains)
   - **Secondary:** `WebSearch` — for finding XBRL data, segment disclosures
   - **Fallback A:** `mcp__gemini-search__web_search` — when other tools fail
   - **Fallback B:** `Bash` with `gemini search` or `curl` — when all native tools fail

2. **Bash usage guidance:**
   - **Preferred:** File operations, data processing
   - **Acceptable:** `gemini search` or `curl` as search fallback when native tools fail

## Resilience rules (mandatory)

1. **Circuit breaker (once-fail):** If WebFetch returns ANY error (404, 403, timeout, etc.) → mark the source status immediately, log the failure, and switch to WebSearch. NEVER retry the same URL. Never retry WebFetch for the same request.
2. **WebFetch failure logging:** Every WebFetch failure MUST be recorded to `.checkpoint/webfetch-failures.jsonl` with this exact format (single line, valid JSON):
   ```
   {"ts":"2026-05-10T12:00:00Z","phase":"financials","agent":"financials","url":"https://...","domain":"sec.gov","error_type":"timeout","error_detail":"Request timeout"}
   ```
   Use Bash to append: `echo '{...}' >> .checkpoint/webfetch-failures.jsonl`
   Error types: `not-found`, `forbidden`, `unauthorized`, `gone`, `rate-limited`, `server-error`, `timeout`, `connection-failed`, `unknown`.
3. **Tool failure fallback:** If a tool fails, follow this order — do not retry the same tool:
   - WebFetch fails → try `Bash: curl -sL -A "Mozilla/5.0" --max-time 15 <URL>`. If curl fails, try `Bash: agent-browser open <URL> && agent-browser snapshot`. If all fail, try WebSearch
   - WebSearch fails → try `mcp__gemini-search__web_search`
   - `mcp__gemini-search__web_search` fails → try Bash with `gemini search` as last resort
   - All fail → mark source `[unreachable]`, skip, move on
   - Bash permission denied → use Read/Write on known paths only
4. **Quality over speed:** Research thoroughly, but persist frequently.

## Depth guidelines

- Pull from XBRL company facts if available
- Build segment tables from Item 8 notes, not just top-line numbers
- Calculate per-segment ROIC when capex and assets are disclosed
- Track segment definition changes (companies redefine segments to mask trends)
- Compare capital allocation language (MD&A) to actual deployment (cash flow statement)

## Return format

```json
{
  "status": "completed",
  "files": ["financials.md"],
  "segments_mapped": 3,
  "quarters_analyzed": 8,
  "anomalies_found": 2,
  "errors": [],
  "missing": []
}
```
