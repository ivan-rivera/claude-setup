---
description: "PR briefing — ELI5 explainer, key changes, gotchas, and code anchors for any pull request"
disable-model-invocation: true
---

Produce a PR briefing (explainer, not a review) for `$ARGUMENTS`.

- `$ARGUMENTS` may be a PR number, a GitHub PR URL, or `owner/repo#N` — any repo, any author.
- If empty, use the PR for the current branch (`gh pr view --json number,url`); if that doesn't resolve either, ask which PR to brief.
- Load the `pr-briefing` skill and follow its protocol exactly — it covers target resolution, gathering via the `gh` CLI, the briefing format, and delivery.
