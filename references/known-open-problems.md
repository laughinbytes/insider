# Known Open Problems

The `insider` plugin's verifier stack catches a specific set of error classes (fabrication, broken arithmetic, format mismatches, coverage gaps, declared-constituent overlaps). This file documents the **classes of errors the system structurally cannot catch** — the irreducible "domain expert review" surface that no automated layer in this plugin will detect on its own.

These are not bugs to fix in the next release. They are open research problems. Re-visit when there is a genuine new approach (a new LLM capability, a domain-specific knowledge base, a fundamentally different verification primitive). Do not patch them with narrow checks; that has been tried and produces patch-on-patch sprawl.

## Open problem 1 — Conceptual-model-fit detection

**The class of error:** A chart's visual primitive (bridge / flow / Sankey) does not match the underlying structure of reality (which may be a hierarchy / subset / overlapping aggregate). Each individual element of the chart is true; the composition implies a flow or conservation that doesn't exist.

**Concrete example (from this plugin's ai-agents project, 2026-05-10):** A bar bridge `$50B → $8-10B → $5-7B` with arrows labeled `"−foundation+platform double-count"` and `"−API COGS"`. Each bar's value is sourced; each arithmetic step computes; but the same `$2-3B` of intercompany API COGS is implicitly deducted in both transitions because "foundation+platform double-count" is a category that contains the API COGS flow. The fix was to redraw as a flow-of-funds diagram with explicitly named constituents.

**Why automated detection is hard:** Detecting this requires modeling the real-world relationships between the entities (in this case: GAAP revenue recognition, intercompany pass-through, gross-vs-net basis accounting). The plugin would need a domain-specific reality model to catch it. Encoding all of finance / biology / law / physics into the verifier doesn't scale.

**Current mitigation:**
- `${CLAUDE_PLUGIN_ROOT}/agents/assembler.md` Anti-amorphous-label rule forbids the syntactic pattern (categorical labels in transitions) that hides the error
- `${CLAUDE_PLUGIN_ROOT}/references/schemas.md` `transition` annotation type requires constituents to be named annotation ids, with cross-step overlap check
- `${CLAUDE_PLUGIN_ROOT}/agents/skeptic.md` rule 7 asks the skeptic to question whether the chart's primitive matches reality

**Residual risk:** A determined fabricator can still produce a plausible-looking constituent decomposition that hides a different class of model-mismatch. Domain expert review remains necessary for this class.

**Open research direction:** Could an LLM be prompted to *generate the underlying flow-of-funds model from the artifact* and then check for conservation violations? This is more than a syntactic check — it's a "reverse-engineer the model and audit it" loop. May be tractable with future LLM reasoning capabilities; not currently reliable.

## Open problem 2 — Constituent plausibility

**The class of error:** A transition declares its constituents (per the rules above) but the constituent values themselves are wrong — not absent, not amorphous, just incorrect estimates. E.g., "$2-3B intercompany API COGS" is named, but the real number is $5B and the bridge math silently passes within ±5% tolerance because of the shape of the transition.

**Why automated detection is hard:** Plausibility checks on numeric estimates require external grounding — comparing against benchmarks, sanity checks, or domain priors. The plugin's verifier checks consistency *within the artifact*; it cannot judge whether the artifact's decomposition reflects reality.

**Current mitigation:**
- `claim_ids[]` requirement forces every value to trace to research; if a value is in the research, the research is what's wrong, not the reading layer
- `verify-claims.py` arithmetic check on inference chains
- Committee vote (investor / expert / skeptic) provides three perspectives that may flag implausible numbers

**Residual risk:** If the upstream research itself contains plausibility errors (a 10x overstated TAM, a wildly off margin estimate), no verifier in this plugin catches it. Domain expert review of source materials is necessary.

**Open research direction:** Cross-referencing claims against external public datasets (SEC filings, industry reports, standard benchmarks) at extraction time. Currently not in scope — would require building a "reasonable-range registry" per domain.

## Open problem 4 — MCP server namespace collision (insider-specific)

**The class of issue:** The plugin uses `mcp__gemini-search__web_search` as a fallback search tool in its multi-tool chain. This tool requires the Gemini CLI (`npm install -g @anthropic-ai/gemini-cli`) and a corresponding MCP server entry in Claude Code's MCP configuration. If the plugin bundles its own `.claude/mcp.json`, it may collide with a Gemini MCP server the user already has configured globally or in another plugin.

**Concrete scenario:**
1. User already has `gemini` MCP server configured in `~/.claude/mcp.json` or another plugin's `.claude/mcp.json`
2. Insider plugin also ships a `.claude/mcp.json` with the same server name or type
3. Claude Code runtime sees duplicate server registrations — behavior is undefined (could be "last wins", could error, could create ambiguous tool routing)

**Why this is an open problem, not a bug to fix now:**
- Claude Code's MCP resolution order across plugin-scope vs. user-scope vs. global-scope `.claude/mcp.json` is not documented as stable
- The "right" answer depends on whether plugins should be self-contained (ship their own MCP configs) or rely on user-installed tools
- If we remove the gemini fallback entirely, research resilience degrades (WebSearch alone has coverage gaps for non-English sources and real-time data)

**Current mitigation:**
- **Do NOT bundle `.claude/mcp.json`** in the plugin — avoids collision entirely at the cost of requiring manual user setup
- **`tools/setup.sh` auto-detects** Gemini CLI availability and generates `.insider/search-priority.json` — if gemini is present, it ranks first; otherwise WebSearch ranks first. Agents read this config at session start and follow the `priority` array
- All agent specs use **adaptive tool priority** — no hardcoded "WebSearch primary, gemini fallback" anywhere in the plugin. Every "switch to WebSearch" in circuit-breaker rules has been replaced with "switch to next search tool per `.insider/search-priority.json`"
- `references/data-sources.md` documents the adaptive tier system — Tier 1 and Tier 2 are filled dynamically from the user's config
- If the tool is unavailable at runtime, Claude Code will prompt for permission once; if denied, the orchestrator reports it and the agent continues with the next tool in the priority array + WebFetch + Bash fallback

**Residual risk:**
- Users who don't install Gemini CLI lose one tier of search resilience (their config only contains `WebSearch`)
- The plugin's hook (`hooks/hooks.json`) still references `mcp__gemini-search__web_search` in its matcher — if the tool is never invoked, the hook simply never fires for it (harmless)
- Agent spec compliance: an agent could theoretically ignore the "Read `.insider/search-priority.json`" instruction and fall back to hardcoded behavior. This is a spec-enforcement problem, not a config problem
- If a future Claude Code version changes MCP resolution semantics, this assessment may need revisiting

**Open research direction:**
- Wait for Claude Code to document stable MCP server namespacing / scoping rules for plugins
- Or: lobby for plugin-declared "recommended tools" that prompt the user to install without bundling config files
- ~~Runtime capability probe~~ — **Addressed via `.insider/search-priority.json`**. Future improvement: make the probe dynamic (check at runtime whether `mcp__gemini-search__web_search` responds, not just whether the CLI binary exists)

---

## Open problem 3 — Novel-class semantic errors

**The class of error:** New types of semantic mistake we haven't seen yet, not covered by any of the 6+ checks in `verifier.md`. By definition, we don't know what they are until they occur.

**Why automated detection is hard:** This is the philosophical limit of any check-based system. You can only catch errors you've thought to look for.

**Current mitigation:**
- Defense in depth: multiple verifier layers reduce the probability that a single class of error slips through all of them
- Adversarial review (Committee, especially skeptic) is asked to find what's wrong, not just confirm what's right
- Open Phase 4.5 review reports are saved as `.checkpoint/<type>s/<slug>/phase-4.5-logic-review*.json` — pattern-matching across them over time may surface recurring categories that should become new checks

**Residual risk:** Permanent. No system catches what it doesn't know to look for.

**Open research direction:** Periodic meta-review of verifier failures across past projects, looking for a common pattern that suggests a new check class. Currently manual; could be a future "verifier-of-verifiers" pass.

## Operating principle

When a new error class is found:

1. **First ask: is this a structural class or a one-off?** If the same pattern would recur in other projects, fix structurally (artifact grammar / spec). If it's truly one-off, fix it in place and don't generalize.
2. **Prefer prevention over detection.** If the dangerous pattern can be made impossible to express in the artifact (e.g., amorphous transition labels), do that. Don't add a verifier that flags it after-the-fact.
3. **Reject patch-on-patch.** Adding narrow checks for every newly-discovered error class produces verifier sprawl that no one maintains. Each new check should justify itself as covering a class, not an instance.
4. **Be honest about what's irreducible.** When a class genuinely requires domain review, document it here. Don't pretend the system can catch it.

## Update log

- **2026-05-10** — Initial creation. Three open problems identified during the ai-agents Phase 4.5 verification cycle. Mitigations added to assembler / skeptic / data/schemas. Residual risks acknowledged.
