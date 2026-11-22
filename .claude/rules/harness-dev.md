---
name: harness-dev
description: "Claude Code harness config editing conventions, scoped to harness/ files"
paths:
  - "harness/**"
  - ".claude/**"
---

# Harness Development

This repository contains Claude Code configuration files. When editing files under `harness/`:
- **Launchers** (`harness/models/bin/*`): bash scripts, executable, each `exec`s `claude` with OpenRouter env vars. Base URL is `https://openrouter.ai/api`, auth via `ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"`, `ANTHROPIC_API_KEY=""`, plus `--settings '{"apiKeyHelper": "true"}'` to keep `x-api-key` empty (a non-empty x-api-key makes OpenRouter route as Anthropic BYOK and reject non-Anthropic models). Gemini models route through `harness/models/or-stream-fix.py` (local proxy, port 8791, auto-started) which strips Gemini's trailing signature-only thinking blocks that Claude Code cannot parse.
- **Agents** (`harness/agents/*.md`): YAML frontmatter requires `name` (lowercase, hyphens, no `:`) and `description`. Valid fields: `name`, `description`, `tools`, `disallowedTools`, `model`, `permissionMode`, `maxTurns`, `skills`, `mcpServers`, `hooks`, `memory`, `background`, `effort`, `isolation`, `color`, `initialPrompt`. Tool names are Capitalised (`Read`, `Write`, `Edit`, `Bash`, `Glob`, `Grep`, `Agent`). `model` accepts aliases (`sonnet`, `opus`, `haiku`, `fable`), full Claude IDs, or `inherit` — never OpenRouter IDs.
- **Rules** (`harness/rules/*.md`): YAML frontmatter requires `description`. Valid fields: `name`, `description`, `paths` (glob list, loads rule when matching files enter context). No frontmatter `paths` → rule loads at session start.
- **Skills** (`harness/skills/*/SKILL.md`): YAML frontmatter should include `description`. Valid fields: `name`, `description`, `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `background`, `hooks`, `paths`, `shell`, `metadata`, `license`, `compatibility`. The directory name is the command name.
- **Commands** (`harness/commands/*.md`): frontmatter like skills; filename (minus `.md`) is the command name. Arguments via `$ARGUMENTS`, `$0`, `$1`... Dynamic context via `` !`command` `` lines.
- **settings.json** (`harness/settings.json`): JSON. Relevant keys: `model`, `advisorModel`, `fallbackModel` (array), `env`, `permissions.defaultMode`, `hooks`, `tui`, `voice`. This file is symlinked to `~/.claude/settings.json` — keep it valid JSON.
- **Launchers** (`harness/models/bin/*`): bash scripts, executable, each `exec`s `claude` with OpenRouter env vars. Base URL is `https://openrouter.ai/api`, auth via `ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"`, `ANTHROPIC_API_KEY=""`.
- **bash-guard.sh** (`harness/hooks/bash-guard.sh`): PreToolUse hook. Safe commands exit 0 silently; flagged commands exit 0 with a JSON `permissionDecision: "ask"` so the user must confirm. Never use exit 1 to block: Claude Code treats it as a non-blocking error and runs the command.

When adding new agents, skills, or commands, also update `harness/rules/claude-tips.md` with a reference entry.

Symlinked locations: `harness/{CLAUDE.md,settings.json,rules,agents,skills,commands,hooks}` → `~/.claude/`; `harness/models/bin/*` → `~/.local/bin/`. `just link` repairs; `just unlink` restores originals from `~/.claude-backup/linked-originals/`.
