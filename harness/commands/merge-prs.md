---
description: "Merge all open PRs sequentially — review, order, resolve conflicts, verify, then update main and the live harness"
disable-model-invocation: true
---

Merge this repository's open PRs one at a time, resolving every conflict along the way, then bring `main` and the live harness up to date. `$ARGUMENTS` optionally lists specific PR numbers; empty means all open PRs.

## Non-negotiables

- Never force-push `main`; never push a merge you have not verified.
- If this is the `claude-setup` repo, its `harness/` is symlinked to `~/.claude/` and is **live** — never switch the main checkout off `main` mid-run. Do all conflict resolution in a git worktree (`git worktree add .claude/worktrees/<slug> <branch>` from the main checkout, per this harness's worktree-cleanup convention; reuse an existing worktree for the branch if it is clean and current).
- Resolve conflicts as the **union** of both intents when both are wanted, or keep the side that reflects current reality when the other is stale — the PR descriptions usually say which. Never invent third content; never resolve by "take mine".
- Default to merge commits, not rebase/squash, so history stays traceable per-PR — especially once PRs start coming from Orca-supervised phase lanes. Override only if the user says otherwise for this repo.

## 1. Inventory and review

1. List open PRs: `gh pr list --json number,title,url,headRefName,baseRefName --limit 50`.
2. Read every PR in full (`gh pr view <N> --json number,title,body,url,additions,deletions`): purpose, files, verification, and especially any **merge-dependency notes** — suggested order, union tables, known-stale references. They are instructions from the author; follow them.
3. `git fetch origin`; note how far local `main` trails.

## 2. Order the merges

- Dry-run every PR against **current** `origin/main`:
  `git merge-tree --write-tree --name-only origin/main origin/<head>` — exit 0 = clean, 1 = conflicts.
- For sibling PRs touching the same files: clean ones first; land wholesale rewrites (e.g. a README sync / drift-check PR) **last** so its final state reflects everything else.
- Announce the order with one line of justification per PR.

## 3. Merge loop

Repeat per PR; **re-dry-run at the top of every iteration** — `main` moves after each merge and yesterday's conflict can be today's clean merge.

**Clean PR:**

```bash
gh pr merge <N> --merge --subject "Merge pull request #<N> from <owner>/<head>"
```

If GitHub reports conflicts on a merge you know is clean right after a push, its async mergeability check is lagging: wait ~5s, check `gh pr view <N> --json mergeable`, retry once.

**Conflicting PR:** resolve on the branch, then merge.

1. In the worktree: `git merge origin/main` (not rebase).
2. Resolve each conflict per the union rule. Where a PR's notes name things that have since been renamed or moved, reconcile to the **current tree**, not the note's snapshot.
3. Verify hermetically — against the branch's harness, never the live one. For `claude-setup`, the worktree's `harness/skills/` is missing anything this repo gitignores (externally-managed skill content — see `.gitignore`), so fill those in from the main checkout before testing:

   ```bash
   TMP=$(mktemp -d)
   mkdir -p "$TMP/.claude" "$TMP/.local/bin"
   for f in CLAUDE.md settings.json rules agents skills commands hooks; do
     ln -s "<worktree>/harness/$f" "$TMP/.claude/$f"
   done
   ln -s "$HOME/.claude/plugins" "$TMP/.claude/plugins"
   for s in <main-checkout>/harness/skills/*/; do
     name=$(basename "$s")
     [ -e "<worktree>/harness/skills/$name" ] || ln -s "$s" "<worktree>/harness/skills/$name"
   done
   (cd <worktree> && HOME="$TMP" just test) && rm -rf "$TMP"
   ```

   Stage only the files you resolved — the skill symlinks above are throwaway scaffolding for the test run, not meant to be committed.
4. Commit with a message stating the resolution, push the branch, then `gh pr merge <N> --merge` (same async-check caveat).
5. `git fetch origin` before the next PR.

`just test` failing after resolution → stop and re-examine; escalate if the fix is not obvious.

## 4. Update main and the live harness

1. Reconcile dirty files in the main checkout against `origin/main`: a locally-modified live file (e.g. `settings.json`) that is semantically identical to main's new version — key order aside — can be discarded; anything meaningfully different goes to the user first.
2. `git pull --ff-only`; the working tree must end clean.
3. `just test` (live, real `HOME`) must pass. Run `just status`; if a PR changed something `just link` manages, rerun `just link`. `just setup` is for from-scratch machines, not updates.
4. Machine-side state not in git (MCP registrations, env vars, external service logins) is not reconciled by `just test` alone — check the merged PRs' notes for steps like a new `claude mcp add` or a CLI login and run what applies.

## 5. Report

One line per PR: number, title, how it merged (clean, or conflicts resolved + what the union kept). Then the harness-update result and the live `just test` verdict.

## Escalate to the user when

- A conflict's correct resolution is genuinely ambiguous — competing intents, no guidance in any PR description.
- `just test` still fails after a reasoned resolution.
- A PR is draft, blocked, or its description contradicts its diff.
- Anything destructive: deleting branches, rewriting history, discarding local work that is not provably redundant.
- The set cannot be ordered safely (circular or mutually stale dependency notes).
