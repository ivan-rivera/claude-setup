#!/usr/bin/env bash
# bash-guard.sh — PreToolUse hook for Bash
#
# Intercepts destructive shell commands before Claude executes them.
# Safe commands exit 0 silently. Flagged commands exit 0 with a PreToolUse
# "ask" decision, so the user must approve them, including in bypass mode.
# Runs with no one to answer (claude -p) treat "ask" as a denial.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

# Nothing to check
[ -z "$COMMAND" ] && exit 0

REASONS=()

# ── Recursive force-delete ────────────────────────────────────────────────────
# Matches rm with any combination of -r/-R and -f flags (rm -rf, rm -fr, rm -Rf, etc.)
if echo "$COMMAND" | grep -qE '\brm\b.+(-[a-zA-Z]*[rR][a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*[rR]|-r\b.*-f\b|-f\b.*-r\b)'; then
  # Escalate if targeting root, home, or common system directories
  if echo "$COMMAND" | grep -qE '\brm\b.+(/\s*$|~\s*$|\$HOME\s*$|/(etc|usr|var|home|opt|bin|sbin|lib|boot|sys|proc))'; then
    REASONS+=("🚨 CATASTROPHIC: recursive force-delete of a system or home directory — will destroy the machine")
  else
    REASONS+=("⚠️  recursive force-delete (rm -rf) — permanent, no recycle bin")
  fi
fi

# ── Git force-push ────────────────────────────────────────────────────────────
# Checked per shell segment. --force-with-lease to an explicitly named,
# non-protected branch passes because Orca phase workers restack PRs with it.
# A +refspec is a force-push with no flag, and it overrides any lease.
FORCE_PUSH='\bgit\b.+\bpush\b.*[[:space:]](--force(-with-lease(=[^[:space:]]*)?|-if-includes)?|-[a-zA-Z]*f[a-zA-Z]*|\+[^[:space:]]+)([[:space:]]|$)'
PROTECTED_REF='(^|[^[:alnum:]_-])(main|master|production|prod|release|develop)($|[^[:alnum:]_-])'
NAMED_REF='\bgit\b.*\bpush\b([[:space:]]+(-u|--set-upstream|-q|--quiet|-v|--verbose|--no-verify|--atomic))*[[:space:]]+[^-[:space:]]+[[:space:]]+[^-[:space:]]+'
HEAD_REF='(^|[[:space:]:+])HEAD($|[[:space:]:])'

while IFS= read -r SEGMENT; do
  echo "$SEGMENT" | grep -qE "$FORCE_PUSH" || continue
  if echo "$SEGMENT" | grep -qE "$PROTECTED_REF"; then
    REASONS+=("🚨 force-push to a protected branch — rewrites shared history, breaks teammates' clones")
    continue
  fi
  WITHOUT_LEASE=$(echo "$SEGMENT" | sed -E 's/--force-with-lease(=[^[:space:]]+)?//g; s/--force-if-includes//g')
  if ! echo "$WITHOUT_LEASE" | grep -qE "$FORCE_PUSH" \
    && echo "$WITHOUT_LEASE" | grep -qE "$NAMED_REF" \
    && ! echo "$WITHOUT_LEASE" | grep -qE "$HEAD_REF"; then
    continue
  fi
  REASONS+=("⚠️  force-push — rewrites remote history; confirm this branch has no other contributors")
done < <(printf '%s\n' "$COMMAND" | tr -d "\"'" | tr ';&|' '\n')

# ── Git hard reset ────────────────────────────────────────────────────────────
if echo "$COMMAND" | grep -qE '\bgit\b.+reset\b.+--hard\b'; then
  REASONS+=("⚠️  git reset --hard — permanently discards all uncommitted changes")
fi

# ── Git discard all working tree changes ─────────────────────────────────────
if echo "$COMMAND" | grep -qE '\bgit\b.+(checkout|restore)\b.+--\s*\.'; then
  REASONS+=("⚠️  discards all unstaged working tree changes — cannot be undone")
fi

# ── Drop database / schema ────────────────────────────────────────────────────
if echo "$COMMAND" | grep -qiE '\bDROP\s+(DATABASE|SCHEMA)\b'; then
  REASONS+=("🚨 CATASTROPHIC: DROP DATABASE/SCHEMA — destroys an entire database and all its data")
fi

# ── Drop table ────────────────────────────────────────────────────────────────
if echo "$COMMAND" | grep -qiE '\bDROP\s+TABLE\b'; then
  REASONS+=("⚠️  DROP TABLE — destroys a table and all its data; ensure a backup exists")
fi

# ── Disk-level writes and formatting ─────────────────────────────────────────
if echo "$COMMAND" | grep -qE '\bmkfs\b|\bdd\b.+of=/dev/'; then
  REASONS+=("🚨 CATASTROPHIC: disk formatting or raw device write — will wipe a drive")
fi

# ── World-writable permissions ────────────────────────────────────────────────
if echo "$COMMAND" | grep -qE '\bchmod\b.+777'; then
  REASONS+=("⚠️  chmod 777 — world-writable permissions create a security vulnerability")
fi

# ── Mass process kill ─────────────────────────────────────────────────────────
if echo "$COMMAND" | grep -qE '\bkillall\b|\bpkill\b.+-9'; then
  REASONS+=("⚠️  mass process termination — may destabilise the system or kill your editor")
fi

# ── All clear ────────────────────────────────────────────────────────────────
[ ${#REASONS[@]} -eq 0 ] && exit 0

# ── Require confirmation ──────────────────────────────────────────────────────
GUARD_REASON="🛑 Bash Guard: potentially destructive command intercepted."
GUARD_REASON+=$'\n\n'"  Command: $(echo "$COMMAND" | head -1)$([ "$(echo "$COMMAND" | wc -l)" -gt 1 ] && echo " [...]" || echo "")"$'\n'
for reason in "${REASONS[@]}"; do
  GUARD_REASON+=$'\n'"  • $reason"
done
export GUARD_REASON

# If the decision cannot be emitted, block instead of letting the command run.
python3 -c 'import json, os; print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": os.environ["GUARD_REASON"]}}))' \
  || { echo "$GUARD_REASON" >&2; exit 2; }
exit 0
