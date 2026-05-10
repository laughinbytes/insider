# Known Open Problems

The `insider` plugin's verifier stack catches a specific set of error classes (fabrication, broken arithmetic, format mismatches, coverage gaps, declared-constituent overlaps). This file documents the **classes of errors the system structurally cannot catch** — the irreducible "domain expert review" surface that no automated layer in this plugin will detect on its own.

These are not bugs to fix in the next release. They are open research problems. Re-visit when there is a genuine new approach (a new LLM capability, a domain-specific knowledge base, a fundamentally different verification primitive). Do not patch them with narrow checks; that has been tried and produces patch-on-patch sprawl.

## Open problem 1 — Conceptual-model-fit detection

**The class of error:** A chart's visual primitive (bridge / flow / Sankey) does not match the underlying structure of reality (which may be a hierarchy / subset / overlapping aggregate). Each individual element of the chart is true; the composition implies a flow or conservation that doesn't exist.

**Concrete example (from this plugin's ai-agents project, 2026-05-10):** A bar bridge `$50B → $8-10B → $5-7B` with arrows labeled `"−foundation+platform double-count"` and `"−API COGS"`. Each bar's value is sourced; each arithmetic step computes; but the same `$2-3B` of intercompany API COGS is implicitly deducted in both transitions because "foundation+platform double-count" is a category that contains the API COGS flow. The fix was to redraw as a flow-of-funds diagram with explicitly named constituents.

**Why automated detection is hard:** Detecting this requires modeling the real-world relationships between the entities (in this case: GAAP revenue recognition, intercompany pass-through, gross-vs-net basis accounting). The plugin would need a domain-specific reality model to catch it. Encoding all of finance / biology / law / physics into the verifier doesn't scale.

**Current mitigation:**
- `${CLAUDE_PLUGIN_ROOT}/agents/consume-agent.md` Anti-amorphous-label rule forbids the syntactic pattern (categorical labels in transitions) that hides the error
- `${CLAUDE_PLUGIN_ROOT}/references/schemas.md` `transition` annotation type requires constituents to be named annotation ids, with cross-step overlap check
- `${CLAUDE_PLUGIN_ROOT}/agents/skeptic-agent.md` rule 7 asks the skeptic to question whether the chart's primitive matches reality

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

## Open problem 3 — Novel-class semantic errors

**The class of error:** New types of semantic mistake we haven't seen yet, not covered by any of the 6+ checks in `logic-verifier-agent.md`. By definition, we don't know what they are until they occur.

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

- **2026-05-10** — Initial creation. Three open problems identified during the ai-agents Phase 4.5 verification cycle. Mitigations added to consume-agent / skeptic-agent / data/schemas. Residual risks acknowledged.
