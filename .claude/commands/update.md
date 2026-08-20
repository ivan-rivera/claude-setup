---
description: "Check for Claude Code updates and propose harness revisions"
disable-model-invocation: true
---

Check for Claude Code updates and analyse what changes affect this harness.

## Steps

### 1. Check Current Version

Run `claude --version` to get the installed version.

### 2. Fetch Latest Releases

```bash
gh api 'repos/anthropics/claude-code/releases?per_page=10' --jq '.[] | "v\(.tag_name) (\(.published_at[:10]))"'
```

Compare the installed version against the latest release. If already current, report that and stop (unless the user wants a deeper review).

### 3. Analyse Changelog

For each release newer than the installed version, read the release body:

```bash
gh api 'repos/anthropics/claude-code/releases/tags/v<VERSION>' --jq '.body'
```

Look for changes that affect this harness:

| Change Type | Impact | Example |
|-------------|--------|---------|
| New subagent frontmatter fields | Agent definitions may benefit | New `effort`-adjacent fields |
| New skill frontmatter fields | Skills may benefit | New invocation-control options |
| New settings keys | `harness/settings.json` may benefit | New advisor/model options |
| New model aliases or env vars | Model routing may benefit | New `ANTHROPIC_DEFAULT_*_MODEL` variable |
| New built-in commands | Update `claude-tips.md` reference list | New `/something` command |
| Breaking config changes | Must update before upgrading | Renamed settings keys |
| Hook changes | `hooks/bash-guard.sh` or settings hooks may need updates | New event types |
| Deprecations | Remove usage before upgrade | Deprecated env vars |

### 4. Propose Revisions

For each relevant change, propose a concrete action:

```
## Proposed Revisions

1. **[settings]** New `xyz` setting available — consider adding for better defaults.
   - File: `harness/settings.json`
   - Change: Add `"xyz": ...`

2. **[tips]** New `/foo` command added in v2.1.X — add to claude-tips reference list.
   - File: `harness/rules/claude-tips.md`
   - Change: Add row to built-in commands table

3. **[agents]** Subagent frontmatter gained a new field — consider applying to `data-generator`.
   - File: `harness/agents/data-generator.md`
   - Change: Add field to frontmatter
```

Present all proposals and wait for approval. Accept partial approval.

### 5. Apply and Log

On approval:
1. Apply the approved revisions to harness files
2. Append a dated entry to `harness/update-log.md`:

```markdown
## YYYY-MM-DD — Claude Code vX.Y.Z → vA.B.C

- Updated `claude-tips.md`: added `/foo` to built-in commands table
- Updated `settings.json`: added `xyz`
- Skipped: (deferred items)
```

3. If `update-log.md` doesn't exist, create it with a header

### 6. Optionally Upgrade Claude Code

Ask if the user wants to upgrade Claude Code itself:

```bash
claude update
```

Only run on explicit approval. Report the new version after upgrade.

## Constraints

- Never auto-apply changes. Propose, explain, wait for approval.
- Never downgrade Claude Code.
- If the changelog mentions breaking changes, warn prominently before any upgrade.
- This command only works in the claude-setup repository (it reads harness files at relative paths).
