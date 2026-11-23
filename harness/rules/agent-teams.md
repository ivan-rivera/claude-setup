---
description: When to recommend a Claude Code agent team, and how a team fits inside Orca work.
---

# Agent Teams

Teams are opt-in. When one would clearly help, recommend it in one line with the roles and the reason, then wait for a yes. Do not repeat the offer after a no on the same task.

## Pick the smallest tool

| Tool | Use for |
|------|---------|
| Single session | Sequential work or edits to the same files |
| Subagents | Independent lookups, research, or reviews that only return a result |
| Agent team | One piece of work where agents must challenge or coordinate with each other |
| Orca lanes | Work that splits into separate PRs, branches, or worktrees |

## Recommend a team when

- A bug has several plausible root causes worth testing against each other.
- One PR spans layers with separate files, and their shared interface is still moving.
- A risky design or plan would benefit from agents actively arguing against it.

Do not recommend one for routine work, or when separate PRs would do. Use 2 or 3 teammates.

## Inside Orca

- Propose a team during planning with the PR's `Team:` field. Approving the plan approves that team.
- A worker with no approved team asks its supervisor through Orca before starting one. The supervisor relays the request to the user.
- The worker stays the lead and the only agent that uses Orca commands. Teammates never call `ask`, `worker_done`, or other orchestration commands.
- Teammates share the lane's worktree and PR branch, so give each one separate files.
- Bring teammates to a safe stop before an Orca `ask`. Shut the team down and verify the combined result before opening the PR or sending `worker_done`.
- Teammates do not survive a resume. After a restart, inspect the worktree and continue alone unless the supervisor approves a new team.

## Mechanics

While `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is on, a named subagent launches as a teammate. Omit `name` on ordinary subagents.
