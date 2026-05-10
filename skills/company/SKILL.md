---
name: company
description: Generate a company-level deep-dive analysis using parallel specialized agents with checkpointing. Anchored on SEC filings and earnings transcripts. Produces raw markdown, structured data layer, and intelligent reading artifact. Use when the user runs /company.
argument-hint: <name-or-ticker> [--resume]
allowed-tools: [Read, Write, Edit, Bash, WebSearch, WebFetch, mcp__gemini-search__web_search, Task, Glob, Grep]
---

# /company — company deep-dive generator (agent team + checkpointing)

Produces structured company analysis using parallel specialized agents. **No fixed time limits** — agents stop when marginal insight per source drops. Checkpointing enables resumption after interruption.

## Pipeline

```
Phase 1: filings-agent            (blocking)    → narrative.md + raw filing extracts
Phase 2: financials-agent         (parallel)    → financials.md
          competitive-agent       (parallel)    → competitive.md
Phase 3: synthesis-agent          (blocking)    → thesis.md, scenarios.md, gaps.md, sources.md
Phase 3.7: data-extraction-agent  (blocking)    → claims/sources/entities/metrics jsonl
Phase 4: consume-agent            (blocking)    → reading/<slug>/index.html (single bilingual file, zero deps)
```

## Permissions

Same as `/industry`: `.claude-plugin/required-permissions.json` documents the tools sub-agents need. Claude Code prompts the user the first time each tool is invoked; granted permissions are written to `.claude/settings.local.json` automatically. The search-backup `PostToolUse` hook ships as `${CLAUDE_PLUGIN_ROOT}/hooks/hooks.json` and loads automatically when the plugin is enabled — no setup script needed.

## Inputs

`/company <name-or-ticker> [--resume]`

- `<name-or-ticker>`: ticker (ASML), name (Snowflake), or abbreviated name (TSMC)
- `--resume`: resume from last checkpoint

### Resolution

1. If input matches US ticker (1-5 uppercase letters), use directly
2. Otherwise lookup via SEC EDGAR ticker file
3. For foreign issuers, prefer US ADR ticker
4. For private companies, use name-derived slug
5. If ambiguous, ask for clarification

### Checkpoint check

On invocation:
1. Check `.checkpoint/companies/<slug>/`
2. If checkpoints exist and not complete:
   - Read highest phase
   - Report: "Resuming from Phase {N}. Completed: {files}."
   - Skip completed phases
3. If no checkpoint or `--refresh`:
   - Delete old research and checkpoints
   - Start fresh

## Phase 1 — Filings foundation (blocking, single agent)

Spawn `filings-agent` via Task tool. Pass:
- Ticker / name and CIK
- `${CLAUDE_PLUGIN_ROOT}/agents/filings-agent.md`
- `${CLAUDE_PLUGIN_ROOT}/references/sec-filing-guide.md`
- `${CLAUDE_PLUGIN_ROOT}/references/trust-signal-rules.md`

The agent:
1. Fetches latest 10-K (or 20-F), 10-Q, 4–8 earnings transcripts, DEF 14A, recent 8-Ks
2. Extracts structured data
3. Writes `research/companies/<slug>/narrative.md` (quote table, KPI evolution, guidance changes, themes emerged/disappeared, hedge-language counts)
4. Returns filing inventory

### Checkpoint 1

Write `.checkpoint/companies/<slug>/phase-1-filings.json`.

### Recovery

If filings-agent fails:
1. Check if partial filings were retrieved
2. Retry with reduced scope (fewer transcripts, skip DEF 14A)
3. If still fails: mark as partial, continue with warning

## Phase 2 — Deep-dive (parallel, two agents)

After filings complete, spawn TWO agents in parallel:

**Agent A: financials-agent**
- Reads filing extracts + narrative.md
- Writes `research/companies/<slug>/financials.md`
- Context: `${CLAUDE_PLUGIN_ROOT}/agents/financials-agent.md` + sec-filing-guide

**Agent B: competitive-agent**
- Reads narrative.md + industry context if available
- Writes `research/companies/<slug>/competitive.md`
- Context: `${CLAUDE_PLUGIN_ROOT}/agents/competitive-agent.md`

Both run simultaneously. Orchestrator waits for both.

### Review gate

Spawn `review-agent` for Phase 2 economics + competitive checks (see `${CLAUDE_PLUGIN_ROOT}/agents/review-agent.md`). For company research, "economics" maps to financials.md and "competitive" maps to competitive.md.

### Checkpoint 2

Write `.checkpoint/companies/<slug>/phase-2-deep-dive.json`.

### Recovery

Same as industry Phase 2: retry failed agents once, mark partial if needed.

## Phase 3 — Synthesis (blocking, single agent)

Spawn `synthesis-agent` via Task tool. Pass:
- All completed raw files: `narrative.md`, `financials.md`, `competitive.md`
- `${CLAUDE_PLUGIN_ROOT}/agents/synthesis-agent.md`
- `${CLAUDE_PLUGIN_ROOT}/references/trust-signal-rules.md`

The agent writes:
- `thesis.md`
- `scenarios.md`
- `gaps.md`
- `sources.md`

### Quality gate

Same as industry Phase 3: falsifiable thesis, ≥5 cited evidence, genuine risks, inference ≤ 20% in open-secrets, top 3 with direct quotes, every open secret has explicit consensus contrast.

### Review gate

Spawn `review-agent` for Phase 3 checks. PASS / CONDITIONAL / FAIL.

### Checkpoint 3

Write `.checkpoint/companies/<slug>/phase-3-synthesis.json`.

## Phase 3.7 — Data extraction (blocking, single agent)

Spawn `data-extraction-agent` via Task tool. Pass:
- All raw files in `research/companies/<slug>/`
- `${CLAUDE_PLUGIN_ROOT}/agents/data-extraction-agent.md`
- `${CLAUDE_PLUGIN_ROOT}/references/schemas.md`

Writes/appends `data/claims.jsonl`, `data/sources.jsonl`, `data/entities.json`, `data/metrics.jsonl`.

### Checkpoint 3.7

Write `.checkpoint/companies/<slug>/phase-3.7-data.json`.

## Phase 4 — Reading generation (blocking, single agent)

Spawn `consume-agent`. The agent reads raw files, designs the artifact, and writes one `reading/<slug>/index.html` (single bilingual file, zero external dependencies, inline SVG charts).

### Review gate

Spawn `review-agent` for Phase 4 checks (zero CDN, thesis clear, bilingual toggle works, inline SVG renders, numerical consistency).

### Phase 4.5 — Verification (blocking, two-stage)

Same two-stage verifier as the industry pipeline (see `skills/industry/SKILL.md` § "Phase 4.5"):

1. **Code stage**: `${CLAUDE_PLUGIN_ROOT}/tools/verify-numerics.sh <slug>` cross-checks every numeric token in the reading HTML against `data/claims.jsonl`. Exit 0 = matched, 1 = unmatched / stale.
2. **LLM stage**: spawn `${CLAUDE_PLUGIN_ROOT}/agents/logic-verifier-agent.md` for chart-arithmetic, cross-file contradictions, definition drift, inference-chain validity, source-claim spot-checks. Writes `.checkpoint/companies/<slug>/phase-4.5-logic-review.json`.

Verdict mapping is the same: PASS / CONDITIONAL / FAIL → if FAIL, regenerate via `consume-agent` Round 2 with the findings list.

### Checkpoint 4 (complete)

Write `.checkpoint/companies/<slug>/phase-4-complete.json`.

**Auto-open:** Orchestrator MUST automatically open the reading HTML in the user's default browser immediately after Phase 4 completes:

```bash
open "reading/<slug>/index.html"
```

## Final report

```
Research complete: <Company> (<ticker>)
─────────────────────────────────────────
Phases:     5/5 (1 + 2 + 3 + 3.7 + 4)
Raw files:  7
Filings:    N 10-Ks, M transcripts, P 8-Ks
Data layer: X claims, Y entities, Z sources, W metrics
Consume:    reading/<slug>/index.html  ← Auto-opened in browser
Checkpoint: .checkpoint/companies/<slug>/phase-4-complete.json
```

## Failure modes and recovery

Same recovery patterns as industry skill. Additional company-specific failures:

| Failure | Recovery |
|---------|----------|
| Private company (no filings) | Skip Phase 1, reduce to press/interviews/community |
| Foreign issuer (20-F lag) | Use 20-F + home-country filings if accessible |
| Recent earnings not transcribed | Use press release + deck; note gap |
| 10-K and earnings deck conflict | Defer to 10-K; note discrepancy |

## Quality bar

After reading the thesis, ask: does this analysis contain an insight that a well-informed analyst who covers this company would find novel or argue with? If not, the pipeline failed. The goal is edge.
