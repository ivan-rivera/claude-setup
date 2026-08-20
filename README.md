# Claude Code Harness

Personal Claude Code harness for a solo full-stack developer exploring multiple business ideas. Version-controlled rules, skills, agents, commands, hooks, and model routing — symlinked into `~/.claude/`. Modelled on the [omp-setup](https://github.com/ivan-rivera/omp-setup) harness built for Oh-My-Pi.

## What's Included

| Component | Location | Purpose |
|-----------|----------|---------|
| Global context | `harness/CLAUDE.md` | Identity, communication style, quality bar |
| Settings | `harness/settings.json` | Sonnet 5 main model, Opus advisor, fallback chain, bash-guard hook, auto permission mode |
| 4 rules | `harness/rules/` | python-style, typescript-style (path-scoped), pr-size-limit, claude-tips (always-on) |
| 10 agents | `harness/agents/` | frontend, backend, architect, security, qa, legal, finance, researcher, content-writer, data-generator |
| 5 skills | `harness/skills/` | brainstorming, frontend-design, model-scout, skill-creator, plugin-creator |
| 2 commands | `harness/commands/` | `/intro` (orientation), `/onboard` (repo setup) |
| Hook | `harness/hooks/bash-guard.sh` | Blocks destructive shell commands (rm -rf, force-push, DROP TABLE...) |
| Model launchers | `harness/models/bin/` | `claude-or`, `claude-glm`, `claude-gemini`, `claude-deepseek` — OpenRouter switch-ins |
| MCP servers | user scope | context7 (library docs), tavily (web research) |

## Model Lineup

**Default (Anthropic subscription):**
- Main: `claude-sonnet-5` (Sonnet 5)
- Advisor: `opus` — consulted on hard decisions via `/advisor`
- Fallback chain: `claude-opus-5` → `claude-haiku-4-5` on overload
- Agents: architect/security/legal on `opus`; frontend/backend/qa/finance/researcher/content-writer on `sonnet`; data-generator on `haiku`

**OpenRouter switch-ins** (bill OpenRouter credits, not the subscription):

| Launcher | Model |
|----------|-------|
| `claude-or [model]` | any OpenRouter model (default `z-ai/glm-5.3`) |
| `claude-glm` | `z-ai/glm-5.3` |
| `claude-gemini` | `google/gemini-3.7-flash` |
| `claude-deepseek` | `deepseek/deepseek-v4-flash-0731` |

These route Claude Code through OpenRouter's Anthropic-compatible endpoint (`https://openrouter.ai/api`) and map the sonnet/opus/haiku aliases to `~anthropic/claude-*-latest` so subagents still resolve. Switch models mid-session with `/model <openrouter-id>`.

Model assignment history: `harness/models-changelog.md` (maintained by `/model-scout`).

## Prerequisites

- [Claude Code](https://code.claude.com/docs/en/overview) v2.1.236+ (`claude --version`)
- [just](https://github.com/casey/just) — `brew install just`
- [gh](https://cli.github.com) CLI, authenticated (for `/update` and repo ops)
- Node/npx (for MCP servers)

## Setup

```bash
git clone git@github.com:ivan-rivera/claude-setup.git
cd claude-setup
just setup
```

`just setup` = `just backup` + `just link`. The backup copies your existing `~/.claude` to `~/.claude-backup` (skipped if one exists). Linking moves any pre-existing `~/.claude/{CLAUDE.md,settings.json,rules,agents,skills,commands,hooks}` into `~/.claude-backup/linked-originals/` and symlinks the harness in their place. Runtime state (`sessions/`, `projects/`, `plugins/`, `history.jsonl`, etc.) stays in `~/.claude` untouched.

## Environment Variables

Set these in your shell profile (`~/.zshrc`):

| Variable | Purpose |
|----------|---------|
| `OPENROUTER_API_KEY` | OpenRouter models via `claude-or` family (required) |
| `TAVILY_API_KEY` | Tavily web-research MCP (required) |
| `CONTEXT7_API_KEY` | Context7 docs MCP (required) |

Check with `just check-env`.

## Justfile Targets

| Target | Purpose |
|--------|---------|
| `just setup` | Backup existing config + link harness |
| `just backup` | Back up `~/.claude` and `~/.claude.json` to `~/.claude-backup` |
| `just link` | Symlink harness dirs + register MCP servers + link launchers |
| `just unlink` | Remove symlinks, restore originals, unregister MCP servers |
| `just status` | Show symlinks, version, model config, env vars |
| `just test` | Verify structure, linkage, settings, launchers, MCP |
| `just check-env` | Verify required env vars |
| `just mcp` | (Re)register user-scope MCP servers |
| `just help` | List all targets |

## Updating

From within this repo, run `/update` in Claude Code to check for new Claude Code releases and propose harness revisions.

To update model assignments based on benchmarks, run `/model-scout` in any session.

## Notes

- **Why launchers instead of global env vars**: keeping `ANTHROPIC_BASE_URL` unset by default preserves the Anthropic subscription for daily driving; the launchers opt specific sessions into OpenRouter billing.
- **Agent model mapping on OpenRouter**: `claude-or` maps `sonnet`/`opus`/`haiku` aliases to `~anthropic/claude-*-latest` on OpenRouter, so harness agents keep working in OpenRouter sessions.
- **Custom plugin ecosystem**: previously-enabled plugins and marketplaces live in `~/.claude/plugins/` and `~/.claude.json` — untouched by this harness. Re-enable or prune via `/plugin`.
