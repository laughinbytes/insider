# Synthesis Agent

Synthesizes all raw research into the thesis, scenarios, analogs, gaps, and open secrets. This requires a single coherent voice — one brain reads everything and writes the analytical argument.

## Inputs

- All completed raw files: `thesis.md` (partial), `macro.md`, `economics.md`, `players.md`
- `${CLAUDE_PLUGIN_ROOT}/references/frameworks.md` § 3 (scenario planning, historical analogs, non-consensus insight)
- `${CLAUDE_PLUGIN_ROOT}/references/trust-signal-rules.md`

## Goal

**Distill non-consensus insights into an investable argument.**

Not every file needs equal depth. Focus on the thesis and what makes it different from market consensus.

## Quality bottom line (must meet)

1. **Thesis is falsifiable** — "If X does not happen by date Y, this thesis is wrong"
2. **≥5 cited claims with specific numbers** — Evidence, not assertion
3. **≥1 non-consensus insight with explicit consensus contrast** — Market believes X, we believe Y, here's why
4. **Genuine risks** — Not straw men, with specific triggers to watch
5. **Inference-chain arithmetic must self-check** — see below

## Inference-chain arithmetic (HARD)

Every claim with `[inference]` source class must include the supporting math chain in the cited evidence. The math must be self-consistent — the verifier and downstream readers will check it.

**FORBIDDEN pattern (the canonical bug):** Stating a percentage / ratio / fraction whose explicit denominator and numerator (in the same sentence) do NOT compute to the stated result.

> Bad: "Coding agents are ~40% of agent revenue today: $5.2B of ~$8-10B" — but $5.2B / $8-10B = 52-65%, not 40%. Either the percentage or the denominator is wrong.

> Good: "Coding agents are ~58% of true app-layer ARR today: $5.2B of ~$9B (midpoint of $8-10B range)."

**Self-check before persisting any inference claim:**

1. List every numeric premise in the inference chain
2. List the conclusion's numeric value
3. Compute: do the premises arithmetically support the conclusion (within ±5% tolerance)?
4. If not, EITHER fix the conclusion OR fix the premise — do not ship a chain that doesn't compute.

This catches the f-6 class of error before it reaches `claims.jsonl` and propagates to reading HTML.

## Reference files (flexible — write what serves the thesis)

- [ ] `thesis.md` — the core argument (mandatory, highest priority)
- [ ] `scenarios.md` — bull/base/bear (if thesis depends on scenario outcomes)
- [ ] `open-secrets.md` — non-consensus insights with citations (mandatory)
- [ ] `sources.md` — consolidated provenance (mandatory)
- [ ] `analogs.md` — historical comparisons (if they illuminate the thesis)
- [ ] `gaps.md` — remaining uncertainty (brief, if time allows)

**Rule of thumb:** If time runs short, prioritize thesis.md + open-secrets.md + sources.md. A sharp thesis with 3 strong open secrets beats a comprehensive but dull package.

## Stopping rule

Write all 6 files before stopping. Write each file immediately upon completion (heartbeat writes — don't batch). There is no time limit and no tool-call cap. If you must abort with partial output, prioritize thesis.md and open-secrets.md (these are the analytical core).

## Synthesis process

1. **Read all raw files** — macro, economics, players
2. **Identify the non-consensus insight** — what does the market get wrong?
3. **Build the thesis** — 1-2 sentence argument, evidence, risks, what to watch
4. **Design scenarios** — bull/base/bear with explicit assumptions and probability estimates
5. **Find analogs** — 2-3 comparable industries, structured comparison table
6. **Map gaps** — what primary research would close remaining uncertainty
7. **Build consensus baseline** — write down what "everyone knows" before identifying what's different
8. **Curate open secrets** — extract non-consensus candidates, apply trust-signal rules, run explicit contrast + red team

## Synthesis process detail: Open Secrets (non-consensus insights)

### Step 1: Consensus Baseline

Before identifying non-consensus insights, first write the **market consensus** — what an informed industry participant would already know:

```markdown
## Market Consensus (这些不是 edge，是背景)

1. [共识声明 1] — [支撑来源]
2. [共识声明 2] — [支撑来源]
3. [共识声明 3] — [支撑来源]
...
```

**Rule:** 共识声明必须来自主流媒体、分析师一致预期、或 earnings call 中的"安全"内容。这些**不评分**，不贡献 edge。

### Step 2: Extract Non-Consensus Candidates

从 raw 文件中提取与共识不同的声明。每个候选必须满足：

```markdown
## 洞察 [N]: [一句话声明]

**市场共识：** [一句话主流观点]
**我们的不同观点：** [一句话与市场共识不同的具体声明]
**证据：** [具体数字 + 来源 + 直接引用]
**反驳观点：** [不同意的人会说]
**为什么反驳不成立：** [我们的证据为什么更强]
**来源标签：** [reported] / [community] / [inference]
**置信度：** [high] / [medium] / [low]
```

**如果没有清晰的"市场共识"作为对比，这个候选就是 weak，删除。**

### Step 3: Self-Check Pass

1. 重读 `open-secrets.md`
2. 验证每个引用：确认声明出现在 fetch 的内容中
3. 审计 inference 项：确认推理链是 1-2 步从公开数据出发
4. **验证显式对比：每个非共识洞察都有对应的共识声明**
5. 删除或降级任何失败的项
6. 重新计数：确认 inference ≤ 20%
7. 报告计数："Open secrets: 12 kept, 4 deleted. Breakdown: 6 reported, 4 community, 2 inference. All have explicit consensus contrast."

## Quality gate

After writing, the agent must check:
- Does the thesis contain a falsifiable claim?
- Is the evidence specific (numbers, sources, dates)?
- Are risks genuine (not straw men)?
- Is inference share ≤ 20% **in open-secrets.md specifically**?
- Do top 3 open secrets have direct quotes?
- **Does every open secret have an explicit consensus contrast?** (市场共识 + 我们的不同观点)
- **Is the consensus baseline accurate?** (不是编造的"稻草人共识")

If any check fails, retry the failing section.

## Tool usage guidance

1. **Search tool priority (flexible fallback):**
   - **Primary:** `WebSearch` — for fact-checking and source verification
   - **Fallback A:** `mcp__gemini-search__web_search` — when WebSearch is unavailable or returns insufficient results
   - **Fallback B:** `Bash` with `gemini search` or `curl` — when both native search tools fail
   - **Last resort:** `WebFetch` — for specific URLs only

2. **Bash usage guidance:**
   - **Preferred:** File operations, data processing, project tools
   - **Acceptable:** `gemini search` or `curl` as search fallback when native tools fail

## Resilience rules (mandatory)

1. **Circuit breaker (once-fail):** If WebFetch returns ANY error (404, 403, timeout, etc.) → mark the source status immediately, log the failure, and switch to WebSearch. NEVER retry the same URL. Never retry WebFetch for the same request.
2. **WebFetch failure logging:** Every WebFetch failure MUST be recorded to `.checkpoint/webfetch-failures.jsonl` with this exact format (single line, valid JSON):
   ```
   {"ts":"2026-05-10T12:00:00Z","phase":"synthesis","agent":"synthesis-agent","url":"https://...","domain":"example.com","error_type":"not-found","error_detail":"404 Not Found"}
   ```
   Use Bash to append: `echo '{...}' >> .checkpoint/webfetch-failures.jsonl`
   Error types: `not-found`, `forbidden`, `unauthorized`, `gone`, `rate-limited`, `server-error`, `timeout`, `connection-failed`, `unknown`.
3. **Tool failure fallback:** If a tool fails, follow this order — do not retry the same tool:
   - WebSearch fails → try `mcp__gemini-search__web_search`
   - `mcp__gemini-search__web_search` fails (503/timeout) → try WebSearch with reformulated query
   - Both search tools fail → try Bash with `gemini search` as last resort
   - All search fails → mark source `[unreachable]`, skip, move on
   - WebFetch fails → log failure, try `Bash: curl -sL -A "Mozilla/5.0" --max-time 15 <URL>`. If curl fails, try `Bash: agent-browser open <URL> && agent-browser snapshot`. If all fail, mark source `[source: <URL> — <error_type>]`, switch to WebSearch
   - Bash permission denied → use Read/Write on known paths only
4. **Heartbeat writes:** Rewrite each output file to disk immediately after completing it. Do not batch all 6 files into one write.
5. **Quality over speed:** Synthesize thoroughly, but persist frequently.

## Return format

```json
{
  "status": "completed",
  "files": ["thesis.md", "scenarios.md", "analogs.md", "gaps.md", "open-secrets.md", "sources.md"],
  "thesis_falsifiable": true,
  "open_secrets_kept": 12,
  "open_secrets_deleted": 4,
  "inference_share": "8.3%",
  "errors": [],
  "missing": []
}
```
