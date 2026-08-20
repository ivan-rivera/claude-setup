---
name: model-scout
description: "Benchmark-driven model selection and rotation for the Claude Code harness. Use when the user wants to update model assignments, check which models are best for specific tasks, compare model performance, review pricing, or keep their model config on the bleeding edge. Also use when new models are released and the user wants to know if they should switch."
---

# Model Scout

Keep the harness model config current with the best available models across task categories.

## How Models Are Configured

This harness splits models across two surfaces:

1. **Subscription models** (billed to the Anthropic subscription):
   - `harness/settings.json` → `model` — the main session model
   - `harness/settings.json` → `advisorModel` — the advisor consulted on hard decisions
   - `harness/settings.json` → `fallbackModel` — the chain used when the main model is overloaded
   - Agent frontmatter `model:` field — `sonnet`, `opus`, or `haiku` per agent
2. **OpenRouter switch-in models** (billed to OpenRouter credits):
   - `harness/models/bin/claude-or` — default model and alias mappings
   - `harness/models/bin/claude-glm`, `claude-gemini`, `claude-deepseek` — per-model launchers

Model assignment history lives in `harness/models-changelog.md`.

## Process

### 1. Gather Benchmark Data

Fetch current model data from OpenRouter:

```bash
curl -s https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" | head -c 50000
```

The response includes per-model: `id`, `pricing`, `context_length`, `top_provider`, and benchmark scores.

Also check these sources if available:
- Chatbot Arena / LMSYS leaderboard (for head-to-head rankings)
- Artificial Analysis (for throughput and latency benchmarks)
- Provider-specific benchmarks (Anthropic, OpenAI, Google evals)
- Anthropic model announcements for new Claude releases

### 2. Map Benchmark Categories to Harness Surfaces

| Benchmark Category | Surface | Assignments |
|--------------------|---------|-------------|
| Code generation (HumanEval, SWE-bench) | main model, frontend/backend/qa agents | `model`, agent `model: sonnet` |
| Reasoning (GPQA, MATH, ARC-AGI) | advisor, architect/security/legal agents | `advisorModel`, agent `model: opus` |
| Cheap bulk tasks | data-generator agent | agent `model: haiku` |
| Alternative-provider quality/cost | OpenRouter launchers | `claude-or` family |

### 3. Generate Performance Report

When the user asks for a performance report, create a detailed table with:

| Task | Model | ELO/Score | Cost/1M (in/out) | Benchmark Source |
|------|-------|-----------|------------------|------------------|
| Main coding | claude-sonnet-5 | SWE-bench: 77.7 | subscription | Anthropic |
| Reasoning switch-in | z-ai/glm-5.3 | Arena: 1580+ | $1.4/$4.4 | LMSYS Arena |
| Fast switch-in | google/gemini-3.7-flash | Coding: 76.1 | $0.375/$1.875 | Artificial Analysis |
| Cheap switch-in | deepseek/deepseek-v4-flash-0731 | N/A | $0.14/$0.28 | OpenRouter |

Include notes on:
- **Benchmark Sources**: Arena ELO, Artificial Analysis indices, or "N/A" if unavailable
- **Task Performance**: Specific scores for coding, reasoning, intelligence indices
- **Cost Efficiency**: $/1M tokens for input and output (OpenRouter); subscription usage for Claude models
- **Recommendations**: Which models are best for each task and tier

### 4. Recommend Changes Per Surface

Present recommendations as a comparison table:

| Surface | Current | Recommended | Benchmark Delta | Cost Delta |
|---------|---------|-------------|-----------------|------------|
| settings.json `model` | claude-sonnet-5 | (new sonnet) | +X% SWE-bench | subscription |
| settings.json `advisorModel` | opus | (new opus/fable) | +X% GPQA | subscription |
| claude-or default | z-ai/glm-5.3 | (new model) | +X Arena ELO | +$Y/1M |
| agent model (architect) | opus | (new model) | — | — |

### 5. Present Analysis and Get Approval

Show the user:
1. A table of proposed changes (current → recommended, with benchmark and cost deltas)
2. Total estimated monthly cost impact (if they provide usage patterns)
3. Any models that are new releases worth noting

**Never auto-apply changes.** Wait for explicit approval.

### 6. Apply Changes

On approval, edit the relevant files:

- **Subscription models**: update `model`, `advisorModel`, or `fallbackModel` in `harness/settings.json`; update agent frontmatter `model:` fields
- **OpenRouter models**: update the default or alias mappings in `harness/models/bin/claude-or`, or the model ID in a per-model launcher
- Append a dated entry to `harness/models-changelog.md`:

```markdown
## YYYY-MM-DD

- Main model: claude-sonnet-5 → <new> (benchmark: +X% on SWE-bench)
- claude-or default: z-ai/glm-5.3 → <new> (benchmark: +X Arena ELO)

**Unchanged:** advisorModel, fallbackModel, agent models
```

- If `models-changelog.md` doesn't exist, create it with a header

## Constraints

- Only recommend OpenRouter models that are actually available on OpenRouter — verify with the `/api/v1/models` response before recommending
- Subscription-surface changes only apply to Claude models (aliases: `sonnet`, `opus`, `haiku`, `fable`, or full IDs like `claude-sonnet-5`)
- Don't change the `advisorModel` without explicit discussion — it's intentionally the strongest reasoning model
- If benchmark data is unavailable or stale, say so rather than guessing
- Claude model IDs in agent frontmatter must be aliases or full Claude IDs — OpenRouter IDs belong only in the launcher scripts
