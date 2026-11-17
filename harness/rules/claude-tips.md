---
name: claude-tips
description: Suggest Claude Code shortcuts and harness features when relevant
---

# Claude Code Tips

When the user's request or workflow clearly matches an available Claude Code feature or harness feature, append a one-line tip suggesting the shorthand. Do not repeat a tip the user has already seen in this session.

## Shorthand Suggestions

If the user's natural-language request matches a command, skill, or keyword below, suggest it:

**Built-in commands:**

| Command | Use when the user... |
|---------|---------------------|
| `/model <name>` | wants to switch models mid-session |
| `/effort <level>` | wants deeper or cheaper reasoning |
| `/advisor <model>` | wants a stronger model consulted on hard decisions |
| `/code-review` | asks for a code review |
| `/doctor` | suspects something in their config is broken |
| `/memory` | wants to edit persistent memory files |
| `/resume` | wants to continue a past session |
| `/init` | wants a CLAUDE.md generated for a new repo |

**Prompt keywords:**

| Keyword | Use when the user... |
|---------|---------------------|
| `ultrathink` | wants deep multi-step reasoning on a single prompt |
| `opusplan` | wants Opus for planning and Sonnet for execution |

**Model launchers (this harness):**

| Launcher | Use when the user... |
|----------|---------------------|
| `claude` | wants the default — Sonnet 5 on the Anthropic subscription |
| `claude-or <model>` | wants any OpenRouter model (defaults to z-ai/glm-5.3) |
| `claude-glm` | wants z-ai/glm-5.3 |
| `claude-gemini` | wants google/gemini-3.7-flash |
| `claude-deepseek` | wants deepseek/deepseek-v4-flash-0731 |

**Custom commands (this harness):**

| Command | Use when the user... |
|---------|---------------------|
| `/intro` | wants an orientation to Claude Code and this harness |
| `/onboard` | wants to set up Claude Code for a new repository |
| `/update` | wants to check for Claude Code updates (only in the claude-setup repo) |
| `/briefing <pr>` | wants an explainer (not a review) of a PR |
| `/merge-prs` | wants a batch of open PRs merged in order with conflicts resolved |

**Custom skills (this harness):**

| Skill | Use when the user... |
|-------|---------------------|
| `/brainstorming` | is about to start a new feature or project without a clear plan |
| `/model-scout` | wants to update model assignments based on benchmarks |
| `/frontend-design` | is making visual design decisions for UI |
| `/plugin-creator` | wants to build a Claude Code plugin |
| `/skill-creator` | wants to create a new skill |
| `/orca-phase` | wants to plan/launch/supervise a multi-PR phase with Orca (parallel worktree lanes, stacked PRs, gates) |
| `/pr-briefing` | wants a plain-language explainer of a PR, distinct from `/code-review` |
| `/agents-vault` | starts/resumes a multi-session project, or produces durable context worth keeping across sessions |
| `/ocr-review` | wants a second, independent model's critique of a diff/PR/branch |

**Harness agents** (delegate by asking for the agent, e.g. "use the security agent"):

`frontend`, `backend`, `architect`, `security`, `qa`, `legal`, `finance`, `researcher`, `content-writer`, `data-generator` — see `/intro` for the full roster.

## Feature Discovery

When the user manually does something Claude Code handles natively, suggest the feature. Examples:

- Manually reviewing their own diff → suggest `/code-review`
- Pasting the same instructions repeatedly → suggest turning them into a skill (`/skill-creator`)
- Long exploration flooding the conversation → suggest delegating to a subagent
- Working on something high-stakes without oversight → suggest `/advisor opus`
- Manually switching models via config edits → suggest `/model` or the `claude-or` launchers
- Asking "what can you do" → suggest `/intro`
- Independent tasks that could run in parallel → suggest background agents (`claude --bg`) or agent teams
- Two sessions fighting over the same working tree → suggest `claude --worktree`

**Format:** `Tip: you can use /command for this.` — one line, end of response. No preamble.
