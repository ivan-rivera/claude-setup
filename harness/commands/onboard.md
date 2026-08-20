---
description: "Onboard a new repository — analyse codebase and propose project-level Claude Code config"
disable-model-invocation: true
---

Analyse the current repository and propose a project-level `.claude/` setup tailored to its tech stack.

## Steps

### 1. Analyse the Repository

Scan the codebase to understand:
- **Languages and frameworks** — package.json, requirements.txt, go.mod, Cargo.toml, etc.
- **Project structure** — monorepo vs single package, directory layout
- **Existing configs** — CI/CD, linting, formatting, testing setup
- **README** — exists? comprehensive or sparse?
- **Existing agent configs** — `.claude/`, `.cursor/`, `.omp/` directories

### 2. Propose Configs

Based on the analysis, propose project-level configs. Present as a summary table with rationale:

**CLAUDE.md** — if missing or sparse, draft one covering: what the project is, build/test/lint commands, architecture overview, conventions. Keep under ~200 lines.

**Agents** (`.claude/agents/*.md`) — suggest project-specific agents based on the stack. Examples:
- Django project → `migrations` agent for schema management
- Monorepo → `workspace-nav` agent for cross-package coordination
- API project → `api-design` agent for endpoint contracts

**Skills** (`.claude/skills/*/SKILL.md`) — suggest project-specific skills. Examples:
- "deploy" skill with the project's deploy workflow
- "run-recipe" skill recording how to build and launch the app

**Commands** (`.claude/commands/*.md`) — suggest project-specific commands. Examples:
- `/deploy` — run the deploy pipeline
- `/test` — run the test suite with appropriate flags
- `/lint` — run linting and formatting
- `/db` — common database operations

**Rules** (`.claude/rules/*.md`) — suggest project-specific rules. Examples:
- Framework conventions (e.g., Next.js App Router patterns)
- Import ordering specific to the project
- Naming conventions from the codebase

**Settings** (`.claude/settings.json`) — project permissions (allow/deny rules for the project's commands) and a project default model if it differs from the global harness.

### 3. Present and Approve

Show all proposals in a structured summary. For each item:
- What it is
- Why it's useful for this project
- Estimated complexity (simple config vs needs thought)

Ask the user to approve, modify, or reject each proposal. Accept partial approval.

### 4. Create

On approval:
1. Create `.claude/` directory structure
2. Write all approved config files
3. Generate or update CLAUDE.md if approved
4. Show a summary of what was created

### 5. Optionally Commit

Ask if the user wants to commit the `.claude/` setup. If yes, create a commit with a descriptive message.

## Constraints

- Do NOT create anything without user approval. Propose first, act second.
- Do NOT overwrite existing `.claude/` configs without explicit permission.
- Keep proposals practical — don't suggest 15 agents for a 3-file project.
- Project-level configs should complement, not duplicate, the global harness in `~/.claude/`.
