---
name: industry
description: Generate a deep-dive industry analysis using parallel specialized agents with checkpointing. Produces raw markdown, structured data layer, and intelligent reading artifact. Use when the user runs /industry or wants a VC / equity-research-grade breakdown of a sector.
argument-hint: <industry> [--resume]
allowed-tools: [Read, Write, Edit, Bash, WebSearch, WebFetch, mcp__gemini-search__web_search, Task, Glob, Grep]
---

# /industry — industry deep-dive generator (auto-pilot + self-healing)

**Blocking mode, fully automated.** The orchestrator spawns agents, waits for completion, handles failures automatically, and advances to the next phase without user intervention.

**No fixed time limits.** Agents cannot reliably perceive wall-clock time or tool-call counts; stopping is driven by marginal-insight signals from the agent itself, with the orchestrator only intervening when an agent reports completion or an unrecoverable error.

## Pipeline (auto-pilot)

```
User: /industry X
  ↓
Phase 1: macro              (blocking)
  ↓ PASS
Review Gate 1                     (blocking)
  │ ├── PASS / CONDITIONAL → Phase 2
  │ └── FAIL → Round 2 → Review Gate 1 again
  │     └── Still FAIL → mark PARTIAL → Phase 2
  ↓
Phase 2: economics + competition  (parallel)
  ↓ both PASS
Review Gate 2                     (blocking)
  │ ├── PASS / CONDITIONAL → Phase 3
  │ └── FAIL → Round 2 → Review Gate 2 again
  │     └── Still FAIL → mark PARTIAL → Phase 3
  ↓
Phase 3: synthesis          (blocking)
  ↓
Quality Gate                      (orchestrator checks 4 bottom lines)
  ↓ PASS
Review Gate 3                     (reviewer checks technical quality)
  │ ├── PASS / CONDITIONAL → Committee
  │ └── FAIL → Round 2 → Review Gate 3 again
  │     └── Still FAIL → mark PARTIAL → Committee
  ↓
Phase 3.5: Committee Vote         (parallel, 3 agents)
  │ ├── 3 PASS → Phase 3.7
  │ ├── 2 PASS + 1 CONDITIONAL → Phase 3.7 (record concerns)
  │ └── otherwise → FAIL → synthesis Round 2 → Committee again
  │     └── Still FAIL → mark PARTIAL → Phase 3.7
  ↓
Phase 3.7: extractor  (blocking)
  ↓
Phase 4: assembler            (blocking)
  ↓ PASS
Auto-open browser
Final Report
```

**Max review rounds per phase: 2.** After 2 rounds, mark as PARTIAL and continue. No infinite loops.

**Stopping signal.** Each research-producing agent (macro, economics, competitive, synthesis, consume) decides when to stop based on marginal insight per source. The orchestrator does not impose a wall-clock cap.

## Permissions

`.claude-plugin/required-permissions.json` documents the tools sub-agents need (Read, Write, Edit, WebFetch, WebSearch, mcp__gemini-search__web_search, Bash, Agent). Claude Code prompts the user the first time each tool is invoked; granted permissions are written to `.claude/settings.local.json` automatically. This skill does **not** auto-merge permissions into `settings.json`.

If a user has explicitly denied a required tool in `settings.local.json`, the relevant sub-agent will fail loudly and the orchestrator will report which tool needs to be re-allowed.

The search-backup `PostToolUse` hook is shipped as `${CLAUDE_PLUGIN_ROOT}/hooks/hooks.json` and loads automatically when the plugin is enabled — no setup script needed.

## Resilience architecture

| Rule | Trigger | Action |
|------|---------|--------|
| **Circuit breaker** | Same URL returns any error once | Mark `[dead]`, log failure, switch to next search tool per `.insider/search-priority.json` |
| **Marginal-insight stop** | Agent's last 3 fetches produced nothing new | Agent writes current state and stops |
| **Review gate** | Phase 1/2/3 complete | Spawn reviewer to check coverage, gaps, contradictions |
| **Hooks backup** | Every search tool call | PostToolUse hook auto-saves query+result to `.checkpoint/search-backup.jsonl` |
| **Quality over speed** | Marginal insight still high | Continue researching; no hard cap |
| **CDN zero** | Consume phase | All charts/diagrams are inline SVG; zero external dependencies |
| **Bilingual** | Consume phase | English primary + Chinese secondary in a single file with toggle |

These rules are enforced in every agent spec under `## Resilience rules (mandatory)`.

## Inputs

`/industry <industry> [--resume]`

- `<industry>`: one word, phrase, or niche segment
- `--resume`: resume from last checkpoint (auto-detected if checkpoint exists)

### Slug resolution

Lowercase, hyphens, strip special chars. Examples: "Semiconductor Capital Equipment" → `semiconductor-capital-equipment`.

### Checkpoint check

On invocation:
1. Check `.checkpoint/industries/<slug>/`
2. If checkpoints exist and not complete:
   - Read highest phase
   - Report: "Resuming from Phase {N}. Completed: {files}."
   - Skip completed phases
3. If no checkpoint or `--refresh`:
   - Delete old research and checkpoints
   - Start fresh

## Phase 1 — Macro foundation (blocking, single agent)

Spawn `macro` via Task tool.

Pass:
- Industry slug and name
- `${CLAUDE_PLUGIN_ROOT}/agents/macro.md` (full context)
- `${CLAUDE_PLUGIN_ROOT}/references/frameworks.md`
- `${CLAUDE_PLUGIN_ROOT}/references/data-sources.md`
- `${CLAUDE_PLUGIN_ROOT}/references/trust-signal-rules.md`

The agent writes `research/industries/<slug>/macro.md` and returns structured results when marginal insight per source drops.

### Checkpoint 1

Write `.checkpoint/industries/<slug>/phase-1-macro.json`:
```json
{"phase": 1, "phase_name": "macro", "status": "completed", "files": ["macro.md"], "archetype": "...", "sources": N}
```

### Review gate

After macro returns, spawn `reviewer` for Phase 1 checks (see `${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md` § "Phase 1 (macro)" for the canonical checklist). Verdict: PASS / CONDITIONAL / FAIL.

If FAIL → spawn `macro` Round 2 with the gap list.

### Recovery

If macro fails:
1. Check `.checkpoint/search-backup.jsonl` for raw research data
2. If backup exists: spawn `recovery` to reconstruct from backup, mark as `partial`
3. If no backup: retry once with simplified scope
4. If still fails: mark as `partial`, continue with warning

## Phase 2 — Deep-dive (parallel, two agents)

After macro completes, spawn TWO agents in parallel via Task tool. Each agent writes its output file when marginal insight drops.

**Agent A: economics**
- Reads `macro.md` from disk
- Writes `research/industries/<slug>/economics.md`
- Context: `${CLAUDE_PLUGIN_ROOT}/agents/economics.md` + frameworks + data-sources

**Agent B: competition**
- Reads `macro.md` from disk
- Writes `research/industries/<slug>/players.md`
- Context: `${CLAUDE_PLUGIN_ROOT}/agents/competition.md` + frameworks + data-sources

Both run simultaneously. The orchestrator waits for both to complete before proceeding.

### Checkpoint 2

Write `.checkpoint/industries/<slug>/phase-2-deep-dive.json` after both agents return.

### Review gate

After both agents return, spawn `reviewer` for Phase 2 economics + competitive checks (see `${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md` for the canonical checklists). Cross-check: do economics and competitive contradict each other on any key metric?

If FAIL → spawn Round 2 for the deficient agent.

### Recovery

If one agent fails and the other succeeds:
- Continue with the successful agent's output
- Check `.checkpoint/search-backup.jsonl` for failed agent's raw data
- If backup exists: spawn `recovery`, mark partial output
- If retry fails: mark section as "incomplete" in checkpoint, continue

If both fail:
- Report to user
- Offer to continue with partial data or abort

## Phase 3 — Synthesis (blocking, single agent)

Spawn `synthesis` via Task tool.

Pass:
- All completed raw files: `macro.md`, `economics.md`, `players.md`
- `${CLAUDE_PLUGIN_ROOT}/agents/synthesis.md`
- `${CLAUDE_PLUGIN_ROOT}/references/trust-signal-rules.md`

The agent writes (heartbeat — one file at a time):
- `thesis.md`
- `scenarios.md`
- `analogs.md`
- `gaps.md`
- `open-secrets.md`
- `sources.md`

### Quality gate (first pass)

After the agent returns, the orchestrator checks:
1. Does `thesis.md` contain a falsifiable claim?
2. Are there ≥5 cited claims in key evidence?
3. Are risks genuine (not straw men)?
4. Is inference share ≤ 20% **in open-secrets.md**?
5. Do top 3 open secrets have direct quotes?
6. **Does every open secret have an explicit consensus contrast?**

If any check fails, send the agent back to retry the failing section.

### Review gate (second pass)

After quality gate passes, spawn `reviewer` for Phase 3 checks (see `${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md` § "Phase 3 (synthesis)").

If FAIL → spawn `synthesis` Round 2 with specific fixes.

### Phase 3.5 — Committee Vote (parallel, 3 agents)

After review gate passes, spawn **3 committee members in parallel**:

**Member 1: `investor`**
- Reads `thesis.md` + `scenarios.md`
- Asks: "Would I invest based on this analysis? Why?"
- Verdict: PASS / CONDITIONAL / FAIL

**Member 2: `expert`**
- Reads `thesis.md` + `open-secrets.md`
- Asks: "Would an industry insider find this novel?"
- Verdict: PASS / CONDITIONAL / FAIL

**Member 3: `skeptic`**
- Reads `thesis.md` + `open-secrets.md` + `macro.md`
- Asks: "What are the vulnerabilities? What could be wrong?"
- Verdict: PASS / CONDITIONAL / FAIL (derived from item-level KEEP/DEMOTE/DELETE counts — see `${CLAUDE_PLUGIN_ROOT}/agents/skeptic.md` for mapping)

**Decision rules:** see `${CLAUDE_PLUGIN_ROOT}/references/committee-protocol.md` for the canonical decision table. Summary:

| Investor | Expert | Skeptic | Decision | Action |
|----------|--------|---------|----------|--------|
| 3 × PASS | | | ✅ PASS | Enter Phase 3.7 |
| 2 × PASS + 1 × CONDITIONAL | | | ⚠️ CONDITIONAL | Enter Phase 3.7, record concerns |
| Any FAIL or majority CONDITIONAL | | | ❌ FAIL | Synthesis Round 2 → re-vote |

**Output:** Write `.checkpoint/industries/<slug>/phase-3-committee.json` with all 3 votes and the final decision.

### Checkpoint 3

Write `.checkpoint/industries/<slug>/phase-3-synthesis.json`.

## Phase 3.7 — Data extraction (blocking, single agent)

Spawn `extractor` via Task tool. Pass:
- All raw files in `research/industries/<slug>/`
- `${CLAUDE_PLUGIN_ROOT}/agents/extractor.md`
- `${CLAUDE_PLUGIN_ROOT}/references/schemas.md`

The agent reads every raw markdown file and writes/appends:
- `data/claims.jsonl` — every cited claim with source class, confidence, entities, tags
- `data/sources.jsonl` — every URL with status (read-modify-write by URL)
- `data/entities.json` — every named entity with project list (read-modify-write)
- `data/metrics.jsonl` — every quantitative observation with entity, metric, value, source

### Checkpoint 3.7

Write `.checkpoint/industries/<slug>/phase-3.7-data.json` with `claims_extracted`, `sources_added`, `entities_touched`, `metrics_observed` counts.

## Phase 4 — Reading generation (blocking, single agent)

Spawn `assembler` via Task tool.

Pass:
- `${CLAUDE_PLUGIN_ROOT}/agents/assembler.md`
- Industry slug

The agent is an **intelligent designer**, not a template filler. It:
1. **Selectively reads** raw files (thesis.md first, then 3-5 more based on what the thesis needs)
2. **Makes design decisions**: which tables become charts, what the narrative arc is, what to highlight
3. **Generates** a single `reading/<slug>/index.html` with:
   - **Inline SVG** charts (bar, line, scatter, flow) — no libraries, no CDN
   - **Bilingual content:** English primary + Chinese (中文) secondary, both in the same file behind a CSS toggle
   - **Zero external dependencies:** renders fully offline with `file://`
   - **Adaptive scope:** Sections are guidance, not a checklist. Exclude sections that do not advance the thesis.

### Review gate

After assembler returns, spawn `reviewer` for Phase 4 checks. See `${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md` § "Phase 4 (assembler)".

If FAIL → spawn `assembler` Round 2 with fixes.

### Phase 4.5 — Verification (blocking, two-stage)

Phase 4.5 catches numerical and logical defects that the Phase 4 review gate cannot. Two stages, both run after consume passes review:

**Stage A — `${CLAUDE_PLUGIN_ROOT}/tools/verify-numerics.sh <slug>`** (code, no LLM)

Cross-checks every numeric token in `reading/<slug>/index.html` against `data/claims.jsonl`. Flags numbers without a matching claim, stale claims, and adjacent `$amount + percentage` pairs that may carry implicit denominators. Pure code, fast, deterministic.

```bash
${CLAUDE_PLUGIN_ROOT}/tools/verify-numerics.sh <slug>
```

Exit codes: `0` all matched · `1` unmatched tokens or stale claims · `2` setup error.

**Stage B — `verifier`** (LLM, semantic)

Spawn `${CLAUDE_PLUGIN_ROOT}/agents/verifier.md` for checks that code cannot do: arithmetic in chart denominators, cross-file contradictions, definition drift, inference-chain validity, scenario probability consistency, top-3 open-secret novelty, and source-claim spot-checks. Writes findings to `.checkpoint/industries/<slug>/phase-4.5-logic-review.json`.

Verdicts:
- `PASS` (no critical, no major) → proceed to Checkpoint 4
- `CONDITIONAL` (no critical, ≤2 major) → proceed, log concerns to user
- `FAIL` (≥1 critical or >2 major) → spawn `assembler` Round 2 with the findings list

**Why two stages:** Code catches "this number doesn't exist in our claims"; LLM catches "these grounded numbers don't fit together logically." The chart that motivated this phase (a bar labeled `40%` against the wrong denominator) needs the LLM stage — both numbers were independently grounded but the relationship between them was wrong.

### Checkpoint 4 (complete)

Write `.checkpoint/industries/<slug>/phase-4-complete.json`.

**Auto-open:** The orchestrator MUST automatically open the reading HTML in the user's default browser immediately after Phase 4 completes. Do not wait for the user to ask.

```bash
open "reading/<slug>/index.html"
```

If the user wants to view it again later, use `${CLAUDE_PLUGIN_ROOT}/tools/open.sh <slug>`.

## Final report

```
Research complete: <Industry Name>
─────────────────────────────────────
Phases:     6/6 (1 + 2 + 3 + 3.5 + 3.7 + 4)
Raw files:  9
Data layer: X claims, Y entities, Z sources, W metrics
Consume:    reading/<slug>/index.html  ← Auto-opened in browser
            └─ Zero dependencies (inline SVG, no CDN)
            └─ Bilingual: EN + 中文 (single file, CSS toggle)
Checkpoint: .checkpoint/industries/<slug>/phase-4-complete.json

To resume later: /industry <industry> --resume
To query data:   ${CLAUDE_PLUGIN_ROOT}/tools/query.sh stats
To regenerate the reading only: /consume <slug>
To open the reading: ${CLAUDE_PLUGIN_ROOT}/tools/open.sh <slug>
```

## Self-healing recovery (automated)

The orchestrator handles all failures without user intervention:

```
spawn agent
    │
    ├── returns {status: "completed"} → normal path
    │
    ├── returns {status: "error", errors: [...]}
    │   → read backup file
    │   → read existing output (if any)
    │   → spawn recovery with backup data
    │   → recovery writes formatted output
    │   → if recovery succeeds → review gate
    │   → if recovery fails → mark partial → next phase
    │
    └── stuck in retry loop (detected by orchestrator)
        → send interrupt
        → agent writes current state
        → if unresponsive → kill
        → recovery from backup or mark partial
```

### Recovery agent

When an agent crashes, spawn `recovery`:

**Inputs:**
- `.checkpoint/search-backup.jsonl` (raw search data)
- Partial output file (if agent wrote anything before crash)
- Agent spec (what sections were required)

**Task:**
1. Read backup file, extract all search results
2. Read partial output file
3. Organize raw data into the required markdown sections
4. Write complete or partial output file
5. Mark missing sections with `[RECOVERED FROM BACKUP]` or `[INCOMPLETE]`

### Failure modes summary

| Failure | Automated Recovery |
|---------|-------------------|
| Agent crash | Recovery-agent from backup → retry |
| Agent stuck in loop | Interrupt → write current state → kill → recovery |
| Review Round 1 FAIL | Round 2 agent → re-review |
| Review Round 2 FAIL (no critical gap) | Mark PARTIAL → continue next phase |
| Review Round 2 FAIL (critical gap remains) | ABORT → user report |
| All parallel agents fail | Mark both partial → continue with synthesis |
| Web search API error | Wait 5s → retry with reformulated query |
| Source returns any error (once) | Log to `.checkpoint/webfetch-failures.jsonl` → mark `[dead]` → switch to next search tool per `.insider/search-priority.json` |
| Socket disconnect | Resume from checkpoint on next invocation |
| Disk write fails | Report error → skip checkpoint → continue |
| Consume CDN unavailable | Not possible — zero external dependencies |

## Quality bar

After reading the thesis, ask: does this analysis contain an insight that a well-informed industry participant would find novel or argue with? If the analysis merely restates consensus, the pipeline failed. The goal is edge, not completeness. Length and section count are not scored; trust signals and non-consensus insights are.
