---
name: lens
description: Generate a stakeholder-specific prep doc from an existing industry or company deep-dive. Fast (no new research) — filters research to one of c-suite, vp, or ic. Use when the user runs /lens or needs quick prep before a stakeholder conversation.
argument-hint: <slug> <c-suite|vp|ic> [meeting-context]
allowed-tools: [Read, Write, Bash, Glob]
---

# /lens — stakeholder-filtered prep

Compose a 1–2 page prep doc for a specific stakeholder layer from existing research. No new research. Designed for the "I have 60 minutes before this meeting" workflow.

## Inputs

`/lens <slug> <stakeholder> [meeting-context]`

- `<slug>` — the slug used in `research/industries/<slug>/` or `research/companies/<slug>/`
- `<stakeholder>` — one of `c-suite`, `vp`, or `ic` (case-insensitive)
- `[meeting-context]` — optional, in quotes. Example: `"first call with CFO"`

## Resolution

1. Glob for `research/industries/<slug>/` first, then `research/companies/<slug>/`. If neither exists, error with available slugs.
2. Read `thesis.md`, `macro.md`, `economics.md`, `players.md`, `scenarios.md`, `open-secrets.md`, `meta.json`.

## Composition

Build a single prep doc:

```markdown
# Prep: <Name> · <Stakeholder> Layer
*Source: research/<slug>/ generated YYYY-MM-DD · Meeting context: <if provided>*

## The argument (stakeholder angle)
<2-3 bullets from thesis.md weighted to what this stakeholder cares about>

## Key numbers they own
<5-7 metrics from economics.md relevant to this layer>

## Competitive context
<2-3 bullets from players.md about moves that affect this stakeholder's world>

## Two insights you can drop
<top 2 from open-secrets.md filtered to this stakeholder level>

## Three questions to ask
<3 skeptical questions drawn from thesis risks and scenarios, weighted to meeting context>

## What to watch
<1-2 metrics or events from thesis.md "what to watch" relevant to this stakeholder>
```

### Weighting by meeting context

If `[meeting-context]` is provided:
- For specific roles: emphasize metrics that role owns
- For specific topics: pull related entries forward
- For specific company names: add 1-2 sentence company-specific addendum
- If no context: balance across all topics

## Output

By default: print to stdout.

If user adds `--save`: write to `research/<slug>/lens/<stakeholder>-<YYYYMMDD-HHMMSS>.md`.

## Stale research warning

If source `meta.json` shows generation >90 days ago, prepend a warning.
