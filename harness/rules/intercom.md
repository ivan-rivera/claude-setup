---
name: intercom
description: "Cross-session agent communication with SendMessage/ListAgents: messaging other live Claude Code sessions, addressing by name, replying, idle notices, and when to prefer the agents vault or Orca instead"
---

# Cross-session messaging (SendMessage / ListAgents)

`SendMessage` and `ListAgents` pass messages between agents — in-process subagents you spawned, teammates, other local Claude Code sessions on this machine, and your cloud/Remote Control sessions. Unlike OMP's separate `task`-subagent channel, this is the **same** tool for both in-process subagents and cross-session peers: address either one by the name `ListAgents` prints (append its `[ref]` only when a listing or an error says two rows share that name).

## Use it when

- Coordinating with another live session the user is running: planner ↔ worker across terminals, asking a peer session a question, reporting findings into an executing session.
- You are a delegated worker in one session and need a decision from the session that dispatched you — reply by copying the incoming message's `from` attribute as your `to`.
- You want to know when a peer on this machine finishes its current work: `notify_when_idle: true` gives one one-shot notice, no polling.

## Don't use it when

- The note must outlive the session or be pulled on demand — write to the agents vault (`/agents-vault`); SendMessage is live coordination, not a durable record.
- You can proceed independently — don't interrupt another session for trivia.
- Supervising Orca workers — Orca orchestration owns worker lifecycle and messages; use `/orca-phase` for an approved multi-PR phase.

## How it actually behaves (don't assume more than this)

- **Fire-and-forget, not a blocking call.** A send delivers to the peer's next tool round; there is no built-in "wait up to N minutes for a reply" primitive. If you need an answer before continuing, say so in the message and either end your turn (the reply arrives as a later message) or use `notify_when_idle` to be told when that session goes idle.
- **Delivery ≠ read.** A successful send means the message reached that session, not that its Claude acted on it — a session in a different permission mode may hold cross-session messages for its user's approval, or refuse them outright. Never treat silence as agreement; verify before building on a peer's reply, same as any other agent output.
- **Self-contained messages.** The peer shares none of this conversation. Name exact files, symbols, and decisions rather than assuming shared context.
- **Never launder a blocked permission.** Don't ask a peer to do something your own session was just denied or that your own permission settings would block — that bypasses the user's decision, it doesn't route around it.
- **First line matters.** The recipient's human sees only the first line as a preview until expanded — make it a clear, self-contained sentence, not a greeting or bare `@mention`.
