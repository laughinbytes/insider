# insider — Claude Code plugin

Deep-dive industry and company analysis using parallel specialized agents with checkpointing. VC / equity-research-grade breakdowns with no fixed time limits.

## Architecture

```
Research layer (markdown)         Data layer (jsonl)         Reading layer (HTML)
└─ machines/agents                └─ queries/analytics       └─ humans
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/industry <industry>
  ↓
Phase 1: macro              (blocking)
  ↓
Phase 2: economics          (parallel)  ─┐
         competition        (parallel)  ─┘
  ↓
Phase 3: synthesis          (blocking)
  ↓
Phase 3.5: Committee Vote         (3 agents in parallel)
  ↓
Phase 3.7: extractor  (blocking)   ← reads raw md → writes data layer jsonl
  ↓
Phase 4: assembler            (blocking)   ← single HTML file, inline SVG, EN/中文 toggle
  ↓
Phase 4.5: verify-numerics + verifier  (blocking, two-stage)
  ↓
research/ + data/ + reading/
```

**No fixed time limits.** Agents cannot reliably perceive wall-clock time or tool-call counts. Stopping is driven by marginal insight per source — when the next 3 fetches return nothing new, the agent writes its output and stops.

**Checkpointing.** Every phase writes a checkpoint. Crash at phase 3? Resume from phase 3 on next invocation.

**Parallel agents.** Economics and competitive analysis run simultaneously after macro foundation completes. Committee members (investor / expert / skeptic) also vote in parallel.

**Hooks auto-loaded.** The plugin ships `hooks/hooks.json` with a `PostToolUse` hook on `WebSearch | WebFetch | mcp__gemini-search__web_search` that appends every search to `.checkpoint/search-backup.jsonl` in the user's CWD. When the plugin is enabled via `/plugin install`, the hook loads automatically — no setup script required. Permissions are handled by Claude Code's runtime prompts; granted tools land in `.claude/settings.local.json` automatically.

## Commands

| Command | Use when |
|---------|----------|
| `/industry <industry>` | Decode a sector |
| `/company <name-or-ticker>` | Diligence a specific company |
| `/consume <slug>` | Regenerate the reading from existing research |
| `/lens <slug> <stakeholder>` | Stakeholder-filtered prep doc |
| `/audit <slug>` | Freshness check using data layer |

### Examples

```
/industry semiconductor capital equipment
/industry B2B SaaS
/company ASML
/company Snowflake
/lens semiconductor-capital-equipment c-suite
/audit ai-coding-assistants
```

## Pipeline

### Industry research (7 phases)

| Phase | Agent | Output | Parallel? |
|-------|-------|--------|-----------|
| 1 | macro | macro.md | No |
| 2 | economics | economics.md | Yes |
| 2 | competition | players.md | Yes |
| 3 | synthesis | thesis.md, scenarios.md, analogs.md, gaps.md, open-secrets.md, sources.md | No |
| 3.5 | investor + expert + skeptic | committee vote (no file) | Yes |
| 3.7 | extractor | claims.jsonl, sources.jsonl, entities.json, metrics.jsonl (append/merge) | No |
| 4 | assembler | reading/<slug>/index.html | No |
| 4.5 | verify-numerics.sh + verifier | phase-4.5-logic-review.json | No |

### Company research (6 phases)

| Phase | Agent | Output | Parallel? |
|-------|-------|--------|-----------|
| 1 | filings | narrative.md | No |
| 2 | financials | financials.md | Yes |
| 2 | competition | competitive.md | Yes |
| 3 | synthesis | thesis.md, scenarios.md, gaps.md, sources.md | No |
| 3.7 | extractor | data layer jsonl | No |
| 4 | assembler | reading/<slug>/index.html | No |
| 4.5 | verify-numerics.sh + verifier | phase-4.5-logic-review.json | No |

## Permissions

`.claude-plugin/required-permissions.json` documents the tools sub-agents need: Read, Write, Edit, WebFetch, WebSearch, mcp__gemini-search__web_search, Bash, Agent.

The plugin does **not** auto-merge these into `.claude/settings.json`. Instead, Claude Code prompts the user the first time each tool is invoked, and granted tools accumulate in `.claude/settings.local.json`. To restrict a specific tool, add it to the `deny` array in `settings.local.json` — sub-agents will fail loudly and the orchestrator will report which tool needs to be re-allowed.

**Why this matters:** Sub-agents inherit the parent's permission context. When a permission is missing, Claude Code's prompt is the natural place to grant it; baking permissions into a JSON file pre-emptively just creates drift.

## Setup

**Installed as a Claude Code plugin** (recommended) — nothing to do. `hooks/hooks.json` auto-loads when the plugin is enabled. The search-backup hook creates `.checkpoint/` in your project on first fire.

**Standalone clone (no plugin install)** — run the fallback script from your project root to copy the same hook into your project's `.claude/settings.json`:

```bash
/path/to/insider/tools/setup.sh
```

Optional flags: `--check-only` (verify only) and `--project-root <dir>` (target a directory other than `$(pwd)`).

## Recovery

| Failure | Recovery |
|---------|----------|
| Agent crashes | Recovery-agent reconstructs from backup, marks `[RECOVERED]`; if no backup, mark partial |
| Agent returns thin output | Review gate detects; spawn Round 2 with gap list |
| Orchestrator crashes | Resume from last checkpoint on next invocation |
| Web search API error | Wait 5s, retry with reformulated query |
| All parallel agents fail | Report to user; offer abort or continue with partial |
| Sub-agent permission denied | Claude Code prompts the user; if denied, the orchestrator reports which tool needs re-allow |

## Output structure

```
research/                          # Research layer (markdown) — for machines/agents
├── industries/<slug>/
│   ├── thesis.md
│   ├── macro.md
│   ├── economics.md
│   ├── players.md
│   ├── scenarios.md
│   ├── analogs.md
│   ├── gaps.md
│   ├── open-secrets.md
│   ├── sources.md
│   └── meta.json
└── companies/<slug>/
    ├── thesis.md
    ├── financials.md
    ├── narrative.md
    ├── competitive.md
    ├── scenarios.md
    ├── gaps.md
    ├── sources.md
    └── meta.json

data/                              # Data layer (jsonl) — for queries/analytics, cross-project append/merge
├── claims.jsonl
├── entities.json
├── sources.jsonl
└── metrics.jsonl

reading/                           # Reading layer (HTML) — for humans, single file per slug
└── <slug>/
    └── index.html

.checkpoint/                       # Resume state
├── industries/<slug>/
│   ├── phase-1-macro.json
│   ├── phase-2-deep-dive.json
│   ├── phase-3-synthesis.json
│   ├── phase-3-committee.json
│   ├── phase-3.7-data.json
│   └── phase-4-complete.json
└── companies/<slug>/
    └── ...
```

## Trust-signal discipline

Every claim carries source class (`[reported]`, `[community]`, `[inference]`) and confidence (`[high]`, `[medium-high]`, `[medium]`, `[low]`). Inference capped at 20% of items per file. Top 3 claims require direct quotes. Self-check pass verifies citations and deletes stale items.

## Known limitations

The verifier stack catches a defined set of error classes (fabrication, broken arithmetic, format mismatches, coverage gaps, declared-constituent overlaps). It **structurally cannot catch** three classes that require domain modeling or expert review — see [`references/known-open-problems.md`](references/known-open-problems.md):

1. **Conceptual-model fit** — chart primitives (flow / Sankey) applied to underlying structures that are actually hierarchies / overlaps
2. **Constituent plausibility** — declared values that are syntactically correct but factually wrong
3. **Novel-class semantic errors** — error patterns we haven't seen yet

Mitigations are layered (anti-amorphous-label rule, transition constituent decomposition, skeptic structural-overlap check), but residual risk is real and acknowledged. Domain-expert review of high-stakes claims remains necessary.

## Query tools

```bash
./tools/query.sh claims --project <slug> --confidence high
./tools/query.sh sources --status dead
./tools/query.sh entities --type company
./tools/query.sh metrics --entity <name>
./tools/query.sh contradicts --entity <name> --metric <metric>
./tools/query.sh stale --project <slug>
./tools/query.sh stats
./tools/query.sh webfetch-failures --stats
```

## Cleanup

```bash
./tools/clean.sh           # dry-run: list cruft candidates, no deletion
./tools/clean.sh --apply   # actually delete
```

Removes anything outside the per-directory allowlist:

| Directory | Allowlist | Anything else flagged |
|---|---|---|
| `reading/<slug>/` | `index.html`, `numerics.json` | screenshots, drafts, `.backup/`, etc. |
| `research/<slug>/` | `*.md`, `meta.json` | tmp / draft files |
| `data/` | `*.jsonl`, `*.json` | tmp / backups |
| `.checkpoint/` | `*.json`, `*.jsonl`, `README.md` | tmp / backups |

Plus always-cruft anywhere: `*.tmp`, `*.bak`, `*.old`, `*~`, `.DS_Store`, `__pycache__/`. Empty `reading/<slug>/` (no `index.html`) is also flagged.

## Consumption

- **Primary**: Open `reading/<slug>/index.html` in any browser (single file, EN/中文 toggle, zero deps)
- **Deep dive**: Open `research/` folder as Obsidian vault
- **Query**: Use `./tools/query.sh` for cross-research search

## License

MIT License — see [`LICENSE`](LICENSE). Author: Chuang.
