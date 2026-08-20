---
name: plugin-creator
description: "Guide building custom Claude Code plugins — self-contained directories bundling skills, agents, hooks, and MCP servers for sharing across projects or teams. Use when the user wants to extend Claude Code beyond single-file configuration, distribute a set of capabilities to others, or asks about the Claude Code plugin format."
---

# Plugin Creator

Guide building Claude Code plugins — self-contained directories that bundle skills, agents, hooks, and MCP servers.

## When to Use Plugins vs Standalone Config

| Mechanism | Use For | Format |
|-----------|---------|--------|
| **Rule** (`rules/*.md`) | Style guides, guardrails, conditional instructions | Markdown + YAML frontmatter |
| **Skill** (`skills/<name>/SKILL.md`) | Multi-step workflows, decision frameworks | Markdown + YAML frontmatter |
| **Command** (`commands/*.md`) | Slash commands with prompt templates | Markdown + YAML frontmatter |
| **Subagent** (`agents/*.md`) | Specialised workers with own context | Markdown + YAML frontmatter |
| **Plugin** | Distributing a bundle of the above; hooks + MCP together | Directory with `.claude-plugin/plugin.json` |

Standalone configuration in `.claude/` is for personal/project use. Convert to a plugin when you want to share with teammates, distribute to the community, or version releases.

## Plugin Structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json        # Manifest — name, description, version
├── skills/                # Skills as <name>/SKILL.md directories
│   └── hello/
│       └── SKILL.md
├── agents/                # Subagent definitions (same frontmatter as harness agents)
│   └── reviewer.md
├── hooks/
│   └── hooks.json         # Event handlers
├── .mcp.json              # MCP servers bundled with the plugin
├── .lsp.json              # LSP servers (optional)
├── bin/                   # Executables added to PATH while enabled
└── settings.json          # Default settings applied when enabled (agent, subagentStatusLine)
```

**Common mistake**: only `plugin.json` goes inside `.claude-plugin/`. All other directories sit at the plugin root.

Plugin skills are namespaced: `my-plugin/skills/hello/SKILL.md` becomes `/my-plugin:hello`.

## Manifest

```json
{
  "name": "my-plugin",
  "description": "What the plugin provides",
  "version": "1.0.0",
  "author": { "name": "Your Name" }
}
```

Optional: `homepage`, `repository`, `license`. Users only receive updates when you bump `version`.

## Process

### 1. Clarify Intent

What should the plugin contain?

| Component | Adds | Example |
|-----------|------|---------|
| Skills | Invocable workflows | A `/deploy` skill with bundled runbooks |
| Agents | Specialised subagents | A `reviewer` agent with restricted tools |
| Hooks | Enforced behaviour | Format files after every edit |
| MCP servers | External tool access | A database or API connection |
| LSP servers | Code intelligence | Language server for an unsupported language |
| Monitors | Background watchers | Tail an error log into the session |

Start standalone in `.claude/`, iterate, then convert to a plugin when the pieces work.

### 2. Scaffold

```bash
mkdir -p my-plugin/.claude-plugin my-plugin/skills/my-skill
# write .claude-plugin/plugin.json, then components
```

A plugin shipping exactly one skill can put `SKILL.md` directly at the plugin root with a `name` field. Use `skills/` if it may grow.

### 3. Port Components

- **Skills**: copy `<name>/SKILL.md` directories under `skills/`. Frontmatter unchanged.
- **Agents**: copy `agents/*.md`. Note: plugin agents ignore the `hooks`, `mcpServers`, and `permissionMode` frontmatter fields — remove or move that logic (e.g. into the plugin's own `hooks/hooks.json`).
- **Hooks**: convert settings.json hook blocks into `hooks/hooks.json` at the plugin root.
- **MCP**: move server definitions into the plugin's `.mcp.json` (note: never place this at `~/.claude/.mcp.json` — the plugin root is the directory with the manifest).

### 4. Test Locally

```bash
claude --plugin-dir ./my-plugin
```

Then invoke `/my-plugin:hello` in the session. Check the `/plugin` Errors tab if a component doesn't load (e.g. LSP executable not found). Run `claude plugin validate ./my-plugin` to lint.

Alternative for always-on development: `claude plugin init my-tool` scaffolds a plugin in `~/.claude/skills/` that auto-loads as `my-tool@skills-dir`.

### 5. Distribute

Three options, in increasing order of setup:
1. **Git repo**: users install with `claude plugin install` from your repo
2. **Marketplace**: publish to a marketplace for discovery
3. **Zip/URL**: `--plugin-url` loads a `.zip` for one-off sessions

For a personal harness like this one, distribution usually means "push to GitHub so another machine can install it".

## Constraints

- Don't build a plugin when a rule, skill, or command in the harness would suffice — plugins are for bundling and sharing
- Plugin agents can't set `hooks`, `mcpServers`, or `permissionMode` — plan around it
- Keep one concern per plugin; a plugin that does formatting AND deployment AND monitoring should be three plugins
- Test with `--plugin-dir` before publishing; verify skills, agents, hooks, and MCP all load without errors
