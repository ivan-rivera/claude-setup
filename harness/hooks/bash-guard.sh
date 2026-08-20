#!/usr/bin/env bash
# bash-guard.sh — PreToolUse hook for Bash
#
# Intercepts destructive shell commands before Claude executes them.
# Exits 0 (allow) or 1 (block) — when blocked, Claude sees the output
# and surfaces it to the user for explicit confirmation before retrying.

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
if echo "$COMMAND" | grep -qE '\bgit\b.+push\b.+(--force\b|-f\b)'; then
  if echo "$COMMAND" | grep -qE '(main|master|production|prod|release|develop)'; then
    REASONS+=("🚨 force-push to a protected branch — rewrites shared history, breaks teammates' clones")
  else
    REASONS+=("⚠️  force-push — rewrites remote history; confirm this branch has no other contributors")
  fi
fi

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

# ── Block and explain ─────────────────────────────────────────────────────────
echo "🛑 Bash Guard: potentially destructive command intercepted."
echo ""
echo "  Command: $(echo "$COMMAND" | head -1)$([ "$(echo "$COMMAND" | wc -l)" -gt 1 ] && echo " [...]" || echo "")"
echo ""
for reason in "${REASONS[@]}"; do
  echo "  • $reason"
done
echo ""
echo "Ask the user to confirm before retrying this command."
exit 1
