---
name: consume
description: Generate a human-consumable HTML artifact from existing raw research. Intelligent design focused on reading comprehension — clear narrative flow, scannable structure, and insightful visualizations. Single bilingual file with EN/中文 toggle, zero external dependencies. Use when the user runs /consume or wants to regenerate the reading layer.
argument-hint: <slug> [--type industry|company]
allowed-tools: [Read, Write, Bash, Glob, Task]
---

# /consume — intelligent consume generator

Generate a human-consumable HTML artifact from existing raw research. This is an **intelligent design process** — the agent reads the raw files, understands the thesis and evidence, then designs the artifact for **reading comprehension**.

**Principle:** The reading layer is for reading, not playing. No sliders, no drag-and-drop, no live recalculation. The reader should understand the thesis and key evidence in 5 minutes.

## Automatic invocation

This skill is **automatically invoked** at the end of `/industry` and `/company` skills. You only need to run it manually if:
- You want to regenerate the reading without regenerating the research
- You modified research files and want to refresh the reading

## Inputs

`/consume <slug> [--type industry|company]`

- `<slug>` — project slug (e.g., `ai-coding-assistants`, `asml`)
- `--type` — `industry` (default) or `company`

## Resolution

1. Glob for `research/<type>s/<slug>/`
2. If not found: error with available slugs

## Pipeline

Spawn `consume-agent` via Task tool. The agent owns the full design + generation process.

Pass:
- `${CLAUDE_PLUGIN_ROOT}/agents/consume-agent.md` (full context, including HTML output specification, inline SVG patterns, bilingual toggle pattern)
- Project slug
- Project type (industry or company)

The agent:
1. **Selectively reads** raw files (thesis.md first, then 3-5 more based on what the thesis needs)
2. **Makes design decisions**: which tables become charts, what the narrative arc is, what to highlight
3. **Writes** `reading/<slug>/index.html` — single bilingual file with interactive EN/中文 toggle, zero external dependencies (inline CSS + inline SVG + minimal inline JS for the toggle only)

**See `${CLAUDE_PLUGIN_ROOT}/agents/consume-agent.md` for:** HTML structure, inline SVG chart formulas (bar / line / scatter / value-chain flow), bilingual toggle CSS+JS, translation quality rules.

## Hard constraints (verified by review gate)

1. **Zero external dependencies** — no `<script src="…">`, no CDN, no external fonts, no `<link rel="stylesheet" href="http…">`. Page must render fully with `file://`.
2. **Single file** — one `index.html` per slug. Bilingual content lives in the same file behind a CSS toggle. No `index.zh.html` companion file.
3. **Interactive language toggle works** — clicking the toggle switches the entire page between EN and 中文.
4. **Inline SVG charts only** — bar / line / scatter / flow diagrams as raw `<svg>` elements. No Plotly, no Mermaid, no Chart.js.

## Review gate (post-generation)

After consume-agent returns, the orchestrator verifies:
1. `grep -c '<script src=\"http' reading/<slug>/index.html` returns 0
2. `grep -c '<link.*href=\"http.*stylesheet' reading/<slug>/index.html` returns 0
3. Page renders with `file://` (manually or via test fetch)
4. Thesis is clear in the hero section
5. Chinese text is present in headings, metrics, and thesis
6. 1–3 inline SVG charts render

If any check fails → spawn `consume-agent` round 2 with specific fixes.

## Report

After successful generation:
> Reading artifact generated: `reading/<slug>/index.html`
> Inline SVG charts: N
> Sections: M
> Bilingual: EN + 中文 (CSS toggle)
> External dependencies: 0
> Open: `file://{absolute path}`

## Quality bar

After generating, ask: if someone who hasn't read the raw research views this for 5 minutes, do they understand the thesis and key evidence? If not, redesign.
