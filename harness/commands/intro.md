---
description: "Claude Code orientation — overview of your harness, features, and workflows"
disable-model-invocation: true
---

Give the user a comprehensive orientation to Claude Code and their custom harness. Generate the overview dynamically by reading the current state.

## Steps

1. **Read the harness config.** Scan these paths and summarise what's configured:
   - `~/.claude/agents/*.md` — list each agent, its role, model, and tool access
   - `~/.claude/skills/*/SKILL.md` — list each skill and how to invoke it
   - `~/.claude/commands/*.md` — list each custom command
   - `~/.claude/rules/*.md` — list each rule, note which are always-on vs path-scoped (with `paths` globs)
   - `~/.claude/settings.json` — main model, advisor model, fallback chain, permission mode, hooks
   - `~/.local/bin/claude-*` launchers — the OpenRouter model switch-ins
   - `~/.claude/models-changelog.md` — model assignment history

2. **Present a structured overview** using tables for scannability:
   - **Your agents** — name, purpose, model, tools
   - **Your skills** — name, trigger, how to invoke (`/name`)
   - **Your commands** — name, what it does
   - **Your rules** — name, always-on vs path-scoped (with globs)
   - **Model routing** — main model (subscription), advisor, fallback chain, OpenRouter launchers, agent models, how to switch (`/model`, `claude-or <model>`, `/model-scout`)
   - **MCP servers** — what's connected (context7, tavily)
   - **Memory** — CLAUDE.md files, auto-memory, `/memory`

3. **Key Claude Code features** — summarise these built-in capabilities:
   - `/model <name>` or `sonnet`/`opus`/`haiku`/`fable` — switch models mid-session
   - `/effort <level>` — reasoning effort (low → max)
   - `ultrathink` — keyword for deep multi-step reasoning in one prompt
   - `/advisor <model>` — pair a stronger model for hard decisions
   - `opusplan` — Opus for planning, Sonnet for execution
   - `/code-review` — code review
   - Plan mode (Shift+Tab) — read-only research before edits
   - Subagents — delegate to specialised agents (`@agent-name` or automatic)
   - `claude --bg` — background agents; agent view to manage them
   - Agent teams — coordinated multi-session work
   - `claude --worktree` — isolated git worktrees for parallel sessions
   - `/doctor` — config health check
   - `/resume` — continue past sessions

4. **Workflow examples** — provide 3-5 practical examples:
   - "Start a new feature": `/brainstorming` → plan mode → implement
   - "Research a topic": delegate to `researcher` agent
   - "Review code": `/code-review` or delegate to `qa` agent
   - "Run on a different model": exit, run `claude-glm` / `claude-gemini` / `claude-deepseek` (bills OpenRouter)
   - "Update model config": `/model-scout`

5. **Stay conversational.** Answer follow-up questions about any feature. If the user asks about something Claude Code can do that isn't in the harness, explain how to set it up.
