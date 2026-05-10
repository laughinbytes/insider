# Committee Review Mechanism

Multi-agent voting system for quality validation. Runs after Phase 3 synthesis completes.

## When to run

After `synthesis-agent` completes and passes the Quality Gate (4 bottom lines met).

## Committee members (spawn in parallel)

1. **`agents/investor-agent.md`** — Would this lead to an investment decision?
2. **`agents/expert-agent.md`** — Would an industry insider find this novel?
3. **`agents/skeptic-agent.md`** — What are the vulnerabilities?

## Voting process

```
Phase 3 synthesis complete
    ↓
Quality Gate passed (4 bottom lines)
    ↓
Spawn 3 committee members in parallel:
    ├── investor-agent → reads thesis + scenarios → votes
    ├── expert-agent → reads thesis + open-secrets → votes
    └── skeptic-agent → reads all files → votes
    ↓
Orchestrator collects votes
    ↓
Decision
```

## Decision rules

| Investor | Expert | Skeptic | Decision | Action |
|----------|--------|---------|----------|--------|
| PASS | PASS | PASS | ✅ PASS | Enter Phase 3.7 |
| PASS | PASS | CONDITIONAL | ⚠️ CONDITIONAL | Enter Phase 3.7, record skeptic's concerns |
| PASS | CONDITIONAL | PASS | ⚠️ CONDITIONAL | Enter Phase 3.7, record expert's concerns |
| CONDITIONAL | PASS | PASS | ⚠️ CONDITIONAL | Enter Phase 3.7, record investor's concerns |
| PASS | PASS | FAIL | ❌ FAIL | Synthesis must address skeptic's objections |
| PASS | FAIL | PASS | ❌ FAIL | Synthesis must strengthen non-consensus claims |
| FAIL | PASS | PASS | ❌ FAIL | Synthesis must make thesis more actionable |
| Any other combination | | | ❌ FAIL | Synthesis Round 2 |

## Output

Orchestrator writes `.checkpoint/industries/<slug>/phase-3-committee.json`:

```json
{
  "phase": "3.5",
  "phase_name": "committee-review",
  "status": "completed",
  "decision": "PASS|CONDITIONAL|FAIL",
  "votes": {
    "investor": {"verdict": "PASS", "score": 8, "reason": "..."},
    "expert": {"verdict": "PASS", "score": 7, "reason": "..."},
    "skeptic": {"verdict": "CONDITIONAL", "score": 6, "reason": "..."}
  },
  "concerns": ["skeptic: ...", "..."],
  "action": "Enter Phase 4 with noted concerns"
}
```

## Recovery

If committee FAILs:
1. Orchestrator sends all 3 votes + concerns to `synthesis-agent`
2. Synthesis-agent has one round to address concerns
3. Re-run committee vote (only the dissenting members need to re-vote)
4. If still FAIL → mark as partial, continue to Phase 3.7 with warning
