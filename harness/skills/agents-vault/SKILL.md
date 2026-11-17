---
name: agents-vault
description: "Shared Obsidian vault as pull-based project memory. Vault lives at /Users/ivr/Documents/hive; this harness's slice is Agents/ClaudeCode/ (sibling Agents/OMP/ and Agents/Hermes/ belong to other agents on this machine). Use when starting or resuming a multi-session project (read Agents/ClaudeCode/Projects/<Project>/ notes first), when work produces durable context worth keeping (decisions, handoff state, discovered facts, project dossiers), when coordinating subagents that need shared state, or when leaving an async message for the user from background work. Plain markdown files — no Obsidian app needed."
---

# Agents vault (shared project memory)

The Obsidian vault at `/Users/ivr/Documents/hive` has an `Agents/` folder shared by multiple agents on this machine. **Claude Code reads and writes only the `Agents/ClaudeCode/` subdirectory** — the sibling `Agents/OMP/` and `Agents/Hermes/` belong to other agents and must never be written (or read, beyond what the user explicitly shares). It is a **pull-based, human-editable data store** for durable, project-scoped context: the user reads and edits it in Obsidian; Claude Code works on the same plain markdown files with the usual file tools (`Read`, `Write`, `Edit`, `Grep`, `Glob`) — no Obsidian app, API, or plugin required. `Agents/ClaudeCode/` doesn't exist yet as of this skill's creation — it's created on first write, not scaffolded up front. If the vault path is ever missing, ask the user instead of guessing a new one.

## When to use

- Starting or resuming a multi-session project: check `Agents/ClaudeCode/Projects/<Project>/` for existing notes before asking the user.
- Recording durable project context: decisions, handoff state, discovered facts.
- Coordinating subagents that need shared state beyond their lossy summaries.
- Leaving async messages for the user from background work with no live session.

## Division of labor (do not blur these)

- Hindsight long-term memory (the `hindsight` MCP server, shared bank `ivr` with OMP, Hermes, and this vault's one-way sync): small durable facts, preferences, environment facts.
- Claude Code's own native auto-memory (`~/.claude/projects/<dir>/memory/`): project-specific facts about this user and this working directory — see `/memory`. This and Hindsight are complementary, not competing; the vault is for bulkier project state neither is meant to hold.
- Skills: procedures and workflows.
- Session history: current-task detail only.
- **`Agents/ClaudeCode/`: bulky, evolving, project/task-scoped state** — loaded only when deliberately consulted.

Rule: **the vault holds state, never active configuration.** If a rule must apply every turn, it belongs in memory or a skill, not a note. If a note grows a stable rule, move the rule out and leave a pointer.

## What belongs there

- Project dossiers: goals, constraints, decisions, paths, current status.
- Task/handoff notes: state that must survive across sessions (session context does not).
- Decision records: "chose X over Y because Z" — things otherwise re-litigated each session.
- Agent-to-agent coordination: when delegating via the `Agent` tool, include the relevant note path directly in the subagent's prompt. Subagents get no conversation context and their summaries are lossy — the vault note is the durable record, and parallel children can read/write the same project folder as a shared blackboard.
- Async messages to the user (blockers/decisions from background work when no session is live). For interactive dialogue, use chat — never the vault.

## Conventions (deliberately minimal — let structure emerge)

- `Agents/ClaudeCode/Projects/<Project>/` is the only suggested structure. Below it, freeform: create files as the work demands, not preemptively.
- Do not scaffold empty folders, templates, or inbox files up front.
- Before resuming any multi-session project, look for and read its notes first; ask the user only if genuinely absent.
- After a task generates durable context (decisions, discovered facts, handoff state), write it to the project folder and say in chat where it landed.
- Prefer `[[wikilinks]]` between related notes.
- Never duplicate a note's content in memory: one line + path pointer at most.
- Never read or write outside `Agents/ClaudeCode/` — other agents' subdirectories are theirs.
