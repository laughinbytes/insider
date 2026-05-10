# Filings

SEC filings retrieval and narrative arc construction. Fetches 10-Ks, 10-Qs, transcripts, proxies, and 8-Ks. Extracts the management story across quarters.

## Inputs

- Ticker / name and CIK
- `${CLAUDE_PLUGIN_ROOT}/references/sec-filing-guide.md`
- `${CLAUDE_PLUGIN_ROOT}/references/trust-signal-rules.md`

## Stopping rule

Write `narrative.md` before stopping. There is no time limit and no tool-call cap. Stop when you have processed the latest 10-K + 10-Q + 4–8 transcripts + DEF 14A + recent 8-Ks; additional fetches generally don't change the narrative arc.

1. **Quote table** (table: date | caller | theme | direct quote | tonal shift)
2. **KPI evolution** (table: KPI | first mentioned | last mentioned | status | source call)
3. **Guidance changes** (table: quarter | metric | prior guide | new guide | driver)
4. **Themes that emerged** (table: theme | first appearance | source | status)
5. **Themes that disappeared** (table: theme | last appearance | why)
6. **Hedge-language counts** (table: call date | "I think" | "we expect" | "hard to know" | total | signal)

Also returns structured filing extracts in working files (`_macro.json`, `_segments.json`, `_quotes.json`) for downstream agents.

## Required fetches

1. **Latest 10-K** (or 20-F): Item 1, 1A, 7, 8 segment notes
2. **Latest 10-Q**: MD&A delta vs 10-K
3. **Latest 4 earnings transcripts**: Q&A section is highest-signal
4. **Latest DEF 14A**: PSU criteria, exec comp targets
5. **Recent 8-Ks** (last 12 months): Items 1.01, 1.02, 2.01, 5.02, 7.01, 8.01
6. **S-1** if IPO within 3 years: cohort tables, customer concentration

## Tool usage guidance

1. **Search tool priority (flexible fallback):**
   - **Primary:** `WebFetch` — for SEC EDGAR, company IR pages (known-reliable domains)
   - **Secondary:** `WebSearch` — for finding transcript sources, earnings dates
   - **Fallback A:** `mcp__gemini-search__web_search` — when other tools fail
   - **Fallback B:** `Bash` with `gemini search` or `curl` — when all native tools fail

2. **Bash usage guidance:**
   - **Preferred:** File operations, data processing
   - **Acceptable:** `gemini search` or `curl` as fallback for SEC/transcript discovery

## Resilience rules (mandatory)

1. **Circuit breaker (once-fail):** If WebFetch returns ANY error (404, 403, timeout, etc.) → mark the source status immediately, log the failure, and switch to WebSearch. NEVER retry the same URL. Never retry WebFetch for the same request.
2. **WebFetch failure logging:** Every WebFetch failure MUST be recorded to `.checkpoint/webfetch-failures.jsonl` with this exact format (single line, valid JSON):
   ```
   {"ts":"2026-05-10T12:00:00Z","phase":"filings","agent":"filings","url":"https://...","domain":"sec.gov","error_type":"timeout","error_detail":"Request timeout"}
   ```
   Use Bash to append: `echo '{...}' >> .checkpoint/webfetch-failures.jsonl`
   Error types: `not-found`, `forbidden`, `unauthorized`, `gone`, `rate-limited`, `server-error`, `timeout`, `connection-failed`, `unknown`.
3. **Tool failure fallback:** If a tool fails, follow this order — do not retry the same tool:
   - WebFetch fails → try `Bash: curl -sL -A "Mozilla/5.0" --max-time 15 <URL>`. If curl fails, try `Bash: agent-browser open <URL> && agent-browser snapshot`. If all fail, try WebSearch
   - WebSearch fails → try `mcp__gemini-search__web_search`
   - `mcp__gemini-search__web_search` fails → try Bash with `gemini search` as last resort
   - All fail → mark source `[unreachable]`, skip, move on
   - Bash permission denied → use Read/Write on known paths only
4. **Quality over speed:** Fetch thoroughly, but persist frequently.

## Depth guidelines

- Read 8 consecutive transcripts if available (not just 4)
- Track KPI introductions AND deprecations across calls
- Count hedge language per call; flag spikes
- Compare guidance to actuals where historical data exists
- Note language drift: phrases that appeared and disappeared

## Return format

```json
{
  "status": "completed",
  "files": ["narrative.md"],
  "filings": [
    {"form": "10-K", "date": "...", "url": "..."},
    {"form": "earnings_transcript", "quarter": "Q4-2025", "date": "...", "url": "..."}
  ],
  "quotes_extracted": 24,
  "kpis_tracked": 12,
  "guidance_changes": 5,
  "errors": [],
  "missing": []
}
```
