# Competition

Competitive dynamics, game theory, M&A probability, talent flows, and supply chain mapping. Builds the full strategic landscape.

## Inputs

- Completed `macro.md` (read from disk)
- `${CLAUDE_PLUGIN_ROOT}/references/frameworks.md` § 3 (competitive game theory)
- `${CLAUDE_PLUGIN_ROOT}/references/data-sources.md` § 2 (community sources for IC voice)
- `${CLAUDE_PLUGIN_ROOT}/references/trust-signal-rules.md`

## Goal

**Map the competitive landscape and identify strategic dynamics that affect the investment thesis.**

Not every player needs a full profile. Focus on competitive forces that matter for the thesis.

## Quality bottom line (must meet)

1. **Thesis-linked** — Every competitive insight connects back to the investment thesis
2. **≥5 specific numbers** — Market share, revenue, growth rates, deal sizes (with sources)
3. **Falsifiable claim** — "If X player does Y by date Z, our competitive assessment is wrong"

## Reference topics (flexible)

- [ ] **Strategic landscape** — Porter-style assessment (or equivalent framework)
- [ ] **Key players** — top companies with scale and posture (focus on thesis-relevant names, not exhaustive top-10)
- [ ] **Game theory** — likely competitive moves and responses (if relevant)
- [ ] **Pricing dynamics** — who has pricing power (if relevant)
- [ ] **M&A activity** — deals that reshape the landscape (if relevant)
- [ ] **Talent flows** — key executive moves (if relevant)
- [ ] **Supply chain** — critical dependencies and bottlenecks (if relevant)
- [ ] **Diagrams** — visual maps where they add insight

**Rule of thumb:** If a topic (talent, M&A, supply chain) has no material impact on the thesis, skip it. A focused competitive analysis beats an encyclopedic one.

## Stopping rule

Write a complete `players.md` before stopping. There is no time limit and no tool-call cap — stop when marginal insight per additional source drops sharply. If you must abort with partial output, mark incomplete sections with `[INCOMPLETE]`.

## Depth guidelines

- Map every player mentioned in earnings transcripts, not just the top 5.
- Talent flows: check LinkedIn, press releases, and industry forums for the last 18 months.
- Supply chain: trace dependencies 2 levels deep (who supplies the suppliers).
- Game theory: for each top-5 player, model their likely response to a 30% price cut by the leader.

## Tool usage guidance

1. **Adaptive search tool priority:**
   - At the start of your session, Read `.insider/search-priority.json` to discover your configured tool order.
   - Use search tools in the order specified by the `priority` array.
   - If the config is missing, default order is: `WebSearch` → `mcp__gemini-search__web_search` (if available) → Bash (`gemini search`, `curl`).
   - `WebFetch` is NEVER a primary search tool — only use it for specific URLs from the whitelist in `references/data-sources.md` § WebFetch domain whitelist.

2. **Bash usage guidance:**
   - **Preferred:** File operations, data processing, project tools
   - **Acceptable:** `gemini search` or `curl` as search fallback when native tools fail

## Resilience rules (mandatory)

1. **Circuit breaker (once-fail):** If WebFetch returns ANY error (404, 403, timeout, etc.) → mark the source status immediately, log the failure, and switch to the next search tool per `.insider/search-priority.json`. NEVER retry the same URL. Never retry WebFetch for the same request.
2. **WebFetch failure logging:** Every WebFetch failure MUST be recorded to `.checkpoint/webfetch-failures.jsonl` with this exact format (single line, valid JSON):
   ```
   {"ts":"2026-05-10T12:00:00Z","phase":"competitive","agent":"competition","url":"https://...","domain":"example.com","error_type":"not-found","error_detail":"404 Not Found"}
   ```
   Use Bash to append: `echo '{...}' >> .checkpoint/webfetch-failures.jsonl`
   Error types: `not-found`, `forbidden`, `unauthorized`, `gone`, `rate-limited`, `server-error`, `timeout`, `connection-failed`, `unknown`.
3. **Tool failure fallback:** If a tool fails, follow this order — do not retry the same tool:
   - A search tool fails → try the next tool in the `priority` array (read from `.insider/search-priority.json`)
   - All configured search tools fail → try Bash with `gemini search` or `curl` as last resort
   - If a tool returns 503/timeout, try the next tool in the array with the same query (reformulate if needed)
   - All search fails → mark source `[unreachable]`, skip, move on
   - WebFetch fails → log failure, try `Bash: curl -sL -A "Mozilla/5.0" --max-time 15 <URL>`. If curl fails, try `Bash: agent-browser open <URL> && agent-browser snapshot`. If all fail, mark source `[source: <URL> — <error_type>]`, switch to the next search tool per `.insider/search-priority.json`
   - Bash permission denied → use Read/Write on known paths only
4. **Quality over speed:** Research until marginal insight drops. Write the complete output file before stopping.

## Return format

```json
{
  "status": "completed",
  "files": ["players.md"],
  "sources": 24,
  "key_players": ["GitHub Copilot", "Cursor", "Claude Code"],
  "errors": [],
  "missing": []
}
```
