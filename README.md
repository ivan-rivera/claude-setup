# Claude Code Harness

Personal Claude Code harness for a solo full-stack developer exploring multiple business ideas. Version-controlled rules, skills, agents, commands, hooks, and model routing — symlinked into `~/.claude/`. Modelled on the [omp-setup](https://github.com/ivan-rivera/omp-setup) harness built for Oh-My-Pi.

## What's Included

| Component | Location | Purpose |
|-----------|----------|---------|
| Global context | `harness/CLAUDE.md` | Identity, communication style, quality bar |
| Settings | `harness/settings.json` | Sonnet 5 main model, Opus advisor, fallback chain, bash-guard hook, auto permission mode |
| 6 rules | `harness/rules/` | python-style, typescript-style (path-scoped), pr-size-limit, claude-tips, incidental-finds, intercom (always-on) |
| 10 agents | `harness/agents/` | frontend, backend, architect, security, qa, legal, finance, researcher, content-writer, data-generator |
| 9 skills | `harness/skills/` | brainstorming, frontend-design, model-scout, skill-creator, plugin-creator, orca-phase, pr-briefing, agents-vault, ocr-review |
| 4 commands | `harness/commands/` | `/intro` (orientation), `/onboard` (repo setup), `/briefing` (PR explainer), `/merge-prs` (batch PR merge) |
| Hook | `harness/hooks/bash-guard.sh` | Blocks destructive shell commands (rm -rf, force-push, DROP TABLE...) |
| Model launchers | `harness/models/bin/` | `claude-or`, `claude-glm`, `claude-gemini`, `claude-deepseek` — OpenRouter switch-ins |
| MCP servers | user scope | context7 (library docs), tavily (web research), hindsight (shared memory bank, optional — needs the container from `omp-setup`), agentsview (session archive, optional — needs the CLI from `omp-setup`) |

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

Two compatibility fixes are baked into the launchers (both discovered via live testing):

1. **Empty `x-api-key`** — Claude Code attaches the claude.ai managed key as `x-api-key` even with `ANTHROPIC_AUTH_TOKEN` set; OpenRouter reads that as an Anthropic BYOK credential and rejects every non-Anthropic model (`No allowed providers are available`). The launchers pass `--settings '{"apiKeyHelper": "true"}'` so the header stays empty and the bearer token does the routing.
2. **Gemini stream rewrite** — with tools in the request (always, for Claude Code), OpenRouter emits Gemini's thought signature as a thinking block *after* the text block; Claude Code requires thinking-before-text and drops the response text entirely. `claude-gemini` (and any `claude-or <model>` whose ID contains `gemini`) routes through a local proxy (`harness/models/or-stream-fix.py`, port 8791, auto-started) that strips those signature-only blocks. Everything else passes through unbuffered.

Model assignment history: `harness/models-changelog.md` (maintained by `/model-scout`).

## Prerequisites

- [Claude Code](https://code.claude.com/docs/en/overview) v2.1.236+ (`claude --version`)
- [just](https://github.com/casey/just) — `brew install just`
- [gh](https://cli.github.com) CLI, authenticated (for `/update` and repo ops)
- Node/npx (for MCP servers)

## Setup

Lives at `~/Documents/os/harness/claude-setup` (sibling to `omp-setup` under the same `harness/` home).

```bash
git clone git@github.com:ivan-rivera/claude-setup.git ~/Documents/os/harness/claude-setup
cd ~/Documents/os/harness/claude-setup
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
| `just install-ocr` | Install/update the `ocr` CLI, pin its OpenRouter config |

## Compared to omp-setup

This harness was rebuilt in November 2026 to catch up with `omp-setup` after going stale since
August. Ported: Orca phase orchestration (`orca-phase`, on top of the `orca-cli`/`orchestration`
skills Orca itself installs into `harness/skills/` — see `.gitignore`), `pr-briefing`/`/briefing`,
`/merge-prs`, `incidental-finds`, `intercom` (rewritten against Claude Code's native
`SendMessage`/`ListAgents` rather than the `pi-intercom` plugin, which has no Claude Code
equivalent), `agents-vault` (new `Agents/ClaudeCode/` slice in the shared `~/Documents/hive`
vault), and MCP registration for the shared Hindsight memory bank and AgentsView session archive
— both services are owned and run by `omp-setup` (`just hindsight-up`, `just install-agentsview`
over there); this harness only registers the client side and skips gracefully in `just test` if
either isn't running.

Deliberately not ported:
- **Impeccable design plugin** — Claude Code already has native design-plugin skills
  (`design:design-critique`, `design:accessibility-review`, `design:design-system`,
  `design:ux-copy`) covering equivalent ground; installing an OMP marketplace plugin into a
  different host isn't guaranteed to work and would duplicate existing capability.
- **herdr integration** — explicitly optional/independent in `omp-setup` itself; no Claude Code
  equivalent surface exists.
- **PPT Master / brag** — superseded by the native Hyperframes skill family already present here
  (video/slideshow tooling far beyond what either vendored skill does).
- **Composio, Linear** — no porting needed; both are already connected independent of this repo
  (shared CLI/MCP state on this machine).

## Notes

- **Why launchers instead of global env vars**: keeping `ANTHROPIC_BASE_URL` unset by default preserves the Anthropic subscription for daily driving; the launchers opt specific sessions into OpenRouter billing.
- **Agent model mapping on OpenRouter**: `claude-or` maps `sonnet`/`opus`/`haiku` aliases to `~anthropic/claude-*-latest` on OpenRouter, so harness agents keep working in OpenRouter sessions.
- **Gemini thought-signature tradeoff**: the stream-fix proxy drops Gemini's signature-only thinking blocks, so Gemini re-derives reasoning each turn instead of continuing across turns. No visible impact in testing; revisit if agentic quality degrades.
- **Default session caveat**: the main `claude` command requires Anthropic credits/subscription on the account; the launchers use OpenRouter credits instead.
- **Custom plugin ecosystem**: previously-enabled plugins and marketplaces live in `~/.claude/plugins/` and `~/.claude.json` — untouched by this harness. Re-enable or prune via `/plugin`.

## Updating

From within this repo, run `/update` in Claude Code to check for new Claude Code releases and propose harness revisions.

To update model assignments based on benchmarks, run `/model-scout` in any session.
