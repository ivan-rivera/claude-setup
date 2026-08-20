# Claude Code Harness Setup — Tasks

> **Owner:** Ivan Rivera
> **Repo:** `git@github.com:ivan-rivera/claude-setup.git`
> **Purpose:** Version-controlled Claude Code harness modelled on the omp-setup OMP harness. Rules, skills, agents, commands, hooks, and model routing — symlinked into `~/.claude/`.

---

## Task 1: Repo Scaffolding & Justfile

**Status: done**

- [x] Create directory skeleton under `harness/` (rules, agents, skills, commands, hooks, models/bin)
- [x] Create project-level `.claude/` (commands/update.md, rules/harness-dev.md)
- [x] Write `.gitignore`
- [x] Write justfile: `help`, `backup`, `mcp`, `link`, `unlink`, `setup`, `status`, `test`, `check-env`
- [x] `just link`/`just unlink` handle pre-existing dirs (move to `~/.claude-backup/linked-originals/`)
- [x] Model launchers symlinked into `~/.local/bin`

### Notes

- Symlink strategy differs from omp-setup: OMP symlinks the whole `agent/` dir; Claude Code keeps runtime state (`sessions/`, `projects/`, `plugins/`, `history.jsonl`) inside `~/.claude/`, so only config entries are symlinked individually: `CLAUDE.md`, `settings.json`, `rules/`, `agents/`, `skills/`, `commands/`, `hooks/`.
- `link` depends on `mcp` — registering user-scope MCP servers via `claude mcp add -s user` (writes to `~/.claude.json`, not the harness, since Claude Code has no harness-side mcp.json).

---

## Task 2: Global Context (CLAUDE.md) & Settings

**Status: done**

- [x] `harness/CLAUDE.md` — ported from omp AGENTS.md (identity, communication, quality bar) + existing worktree-cleanup protocol
- [x] `harness/settings.json` — model `claude-sonnet-5`, advisorModel `opus`, fallbackModel `[claude-opus-5, claude-haiku-4-5]`, permissionMode `auto`, bash-guard PreToolUse hook, TUI/voice/theme settings preserved from backup

### Notes

- OMP's `disabledProviders` isolation has no Claude Code equivalent — not needed, Claude Code reads only `~/.claude/` + project `.claude/`.
- OMP's `tools.approval: write` maps to `permissions.defaultMode: auto` (existing user choice).
- `advisorModel: "opus"` — advisor tool is Anthropic-API-only; with Sonnet main + Opus advisor it activates automatically. Toggle per-session with `/advisor`.

---

## Task 3: Rules Setup

**Status: done**

- [x] `rules/python-style.md` — path-scoped (`**/*.py`, `**/*.pyi`)
- [x] `rules/typescript-style.md` — path-scoped (`**/*.ts(x)`, `**/*.js(x)`)
- [x] `rules/pr-size-limit.md` — always-on (no `paths` frontmatter)
- [x] `rules/claude-tips.md` — always-on, ported from omp-tips with Claude Code feature set

### Notes

- OMP rule frontmatter (`globs`, `alwaysApply`) maps to Claude Code's `paths` frontmatter; no frontmatter `paths` = loads at session start (equivalent of `alwaysApply: true`).
- claude-tips curated for Claude Code: `/model`, `/effort`, `/advisor`, `/code-review`, `/doctor`, `ultrathink`, `opusplan`, launchers, harness commands/skills/agents.

---

## Task 4-5: Skills, Commands & Agent Roster

**Status: done**

- [x] 10 agents ported with Claude Code frontmatter: `tools` (Capitalised names), `model` (aliases), architect gets `Agent(frontend, backend)`
- [x] Agent model mapping: architect/security/legal → `opus`; frontend/backend/qa/finance/researcher/content-writer → `sonnet`; data-generator → `haiku`
- [x] 5 skills: brainstorming, frontend-design, model-scout (rewritten for Claude Code config surfaces), skill-creator (rewritten for Claude Code format), plugin-creator (ported from extension-creator)
- [x] 2 commands: `/intro`, `/onboard` (both `disable-model-invocation: true` — deliberate invocations)

### Notes

- OMP `advisor: true` on architect/security/legal has no per-agent Claude Code equivalent — advisor is session-wide. Model choice compensates: those agents run on `opus`.
- OMP `spawns:` maps to `tools: Agent(frontend, backend)` allowlist syntax.
- OMP `autoloadSkills:` maps to subagent `skills:` frontmatter (frontend → frontend-design, architect → brainstorming).
- extension-creator → plugin-creator: OMP runtime extensions have no Claude Code equivalent; Claude Code's extension mechanism is plugins (skills+agents+hooks+MCP bundles).

---

## Task 6: Provider & Model Routing

**Status: done**

- [x] Main model: `claude-sonnet-5` on Anthropic subscription (default `claude` command)
- [x] Advisor: `opus`; fallback chain: `claude-opus-5` → `claude-haiku-4-5`
- [x] OpenRouter switch-ins via launchers: `claude-or` (default `z-ai/glm-5.3`), `claude-glm`, `claude-gemini`, `claude-deepseek`
- [x] Launchers map sonnet/opus/haiku aliases to `~anthropic/claude-*-latest` on OpenRouter so harness agents resolve
- [x] `harness/models-changelog.md` initialised

### Notes

- Model routing differs fundamentally from OMP: no `models.yml`/`modelRoles`. Claude Code config = settings.json keys + env vars. OpenRouter routing uses the Anthropic-compatible endpoint (`https://openrouter.ai/api`) with `ANTHROPIC_AUTH_TOKEN=$OPENROUTER_API_KEY` and `ANTHROPIC_API_KEY=""`.
- Launchers instead of global env vars: preserves the subscription for default sessions; OpenRouter billing is opt-in per session. `/model <id>` switches mid-session within an OpenRouter session.
- Old zshrc `claude-or()` function superseded by the launcher (removed from `.zshrc`).

---

## Task 7: Memory

**Status: done (native)**

- [x] Claude Code native auto-memory (`~/.claude/projects/<dir>/memory/MEMORY.md`) — on by default, no config needed
- [x] Global + project CLAUDE.md for persistent instructions

### Notes

- OMP's mnemopi backend (retain/recall/reflect) has no Claude Code equivalent; auto-memory + `/memory` covers the need. Nothing to configure.

---

## Task 8: MCP & CLI Integration

**Status: done**

- [x] Context7 MCP (user scope, `@upstash/context7-mcp@latest`)
- [x] Tavily MCP (user scope, `tavily-mcp@latest`)
- [x] `just mcp` target registers both; `just check-env` verifies keys

### Notes

- Registered via `claude mcp add -s user` — config lives in `~/.claude.json` (Claude Code has no harness-side MCP config; `~/.claude/.mcp.json` is not read).
- GitHub MCP dropped as in omp-setup — `gh` CLI used directly.

---

## Task 9: Project-Level Self-Update Config

**Status: done**

- [x] `.claude/commands/update.md` — `/update` checks installed version vs `gh api repos/anthropics/claude-code/releases`, analyses changelog, proposes harness revisions, logs to `harness/update-log.md`
- [x] `.claude/rules/harness-dev.md` — path-scoped to `harness/**`, documents valid frontmatter fields for agents/rules/skills/commands/settings/launchers

---

## Task 10: Symlink & Final Integration

**Status: done**

- [x] `just setup` — backup + link
- [x] `just test` — 40+ automated checks (files, symlinks, settings validity, launcher syntax/models, MCP registration)
- [x] `just status` — state inspection
- [x] README.md with setup instructions, env vars, model lineup
- [x] Live smoke tests: default session (Sonnet 5), `claude-glm`, `claude-gemini`, `claude-deepseek` OpenRouter sessions
- [x] Final commit and push

### Notes

- Initial verification found Claude Code v2.1.236 supports all required features (`advisorModel`, `fallbackModel` array, `claude-sonnet-5`).
- Live smoke test evidence recorded in final session notes.
