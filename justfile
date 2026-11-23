# Claude Code harness setup — modelled on omp-setup
#
# Symlinks harness/ into ~/.claude (config dirs only — runtime state like
# sessions/, projects/, and plugins/ stays in ~/.claude untouched).

claude_dir  := env("HOME") / ".claude"
bin_dir     := env("HOME") / ".local" / "bin"
backup_dir  := env("HOME") / ".claude-backup"
harness_dir := justfile_directory() / "harness"
date_suffix := `date +%Y-%m-%d`

harness_dirs := "rules agents skills commands hooks"
launchers    := "claude-or claude-glm claude-gemini claude-deepseek"
ocr_model    := env_var_or_default("OCR_MODEL", "z-ai/glm-5.3")

# Show all available targets
help:
    @just --list --unsorted

# Back up ~/.claude and ~/.claude.json into ~/.claude-backup (skips if one exists)
backup:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -e "{{ backup_dir }}" ]; then
        echo "Backup already exists at {{ backup_dir }} — skipping."
        echo "Delete it first if you want a fresh backup."
        exit 0
    fi
    echo "Backing up ~/.claude -> {{ backup_dir }} ..."
    ditto "$HOME/.claude" "{{ backup_dir }}"
    cp "$HOME/.claude.json" "{{ backup_dir }}/claude.json"
    [ -f "$HOME/.zshrc" ] && cp "$HOME/.zshrc" "{{ backup_dir }}/zshrc"
    echo "Done ({{ backup_dir }})."

# Install/update the Open Code Review (ocr) CLI and pin its OpenRouter config.
# Global npm install, shared across any harness on this machine — omp-setup
# runs the identical recipe, so this is a no-op if already installed there.
install-ocr:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing/updating Open Code Review (ocr)..."
    npm install -g @alibaba-group/open-code-review@latest
    echo "  Installed: $(ocr --version 2>/dev/null | head -1 || true)"
    ocr config set provider openrouter
    ocr config set model "{{ ocr_model }}"
    if [ -n "${OPENROUTER_API_KEY:-}" ]; then
        ocr llm test
    else
        echo "  Warning: OPENROUTER_API_KEY not set — skipped 'ocr llm test' (key is read from the environment at review time)."
    fi

# Register user-scope MCP servers (Context7, Tavily, Hindsight, AgentsView)
mcp:
    #!/usr/bin/env bash
    set -euo pipefail
    command -v claude >/dev/null 2>&1 || { echo "claude CLI not found in PATH"; exit 1; }
    claude mcp remove -s user context7 >/dev/null 2>&1 || true
    claude mcp remove -s user tavily  >/dev/null 2>&1 || true
    claude mcp add -s user context7 \
        -e CONTEXT7_API_KEY='${CONTEXT7_API_KEY}' \
        -- npx -y @upstash/context7-mcp@latest
    claude mcp add -s user tavily \
        -e TAVILY_API_KEY='${TAVILY_API_KEY}' \
        -- npx -y tavily-mcp@latest
    echo "MCP servers registered (user scope): context7, tavily"
    # Hindsight: shared memory bank 'ivr', same container omp-setup runs via
    # `just hindsight-up` in that repo — this harness only registers the
    # client, it does not own the container's lifecycle.
    if docker ps --format '{{{{.Names}}' 2>/dev/null | grep -qx hindsight; then
        claude mcp remove -s user hindsight >/dev/null 2>&1 || true
        claude mcp add -s user --transport http hindsight http://localhost:8888/mcp/ivr/
        echo "MCP server registered (user scope): hindsight (bank ivr)"
    else
        echo "Hindsight container not running — skipping registration. Start it from omp-setup: (cd ~/Documents/os/harness/omp-setup && just hindsight-up), then rerun 'just mcp'."
    fi
    # AgentsView: read-only session archive, already indexes this harness's
    # sessions from ~/.claude/projects/ alongside OMP/Hermes.
    if command -v agentsview >/dev/null 2>&1; then
        claude mcp remove -s user agentsview >/dev/null 2>&1 || true
        claude mcp add -s user agentsview -- agentsview mcp
        echo "MCP server registered (user scope): agentsview"
    else
        echo "agentsview CLI not found — skipping registration. Install via omp-setup: (cd ~/Documents/os/harness/omp-setup && just install-agentsview)."
    fi

# Symlink harness/ entries into ~/.claude and model launchers into ~/.local/bin
link: mcp
    #!/usr/bin/env bash
    set -euo pipefail
    staging="{{ backup_dir }}/linked-originals"
    mkdir -p "$staging"

    link_one() {
        local target="$1" source="$2"
        if [ -L "$target" ]; then
            local current
            current=$(readlink "$target")
            if [ "$current" = "$source" ]; then
                echo "  already linked: $target"
                return 0
            fi
            echo "  replacing symlink: $target (was -> $current)"
            rm "$target"
        elif [ -e "$target" ]; then
            local dest="$staging/$(basename "$target").{{ date_suffix }}"
            echo "  moving existing $(basename "$target") -> $dest"
            mv "$target" "$dest"
        fi
        ln -s "$source" "$target"
        echo "  linked: $target -> $source"
    }

    link_one "{{ claude_dir }}/CLAUDE.md"     "{{ harness_dir }}/CLAUDE.md"
    link_one "{{ claude_dir }}/settings.json" "{{ harness_dir }}/settings.json"
    for d in {{ harness_dirs }}; do
        link_one "{{ claude_dir }}/$d" "{{ harness_dir }}/$d"
    done

    mkdir -p "{{ bin_dir }}"
    for s in {{ launchers }}; do
        link_one "{{ bin_dir }}/$s" "{{ harness_dir }}/models/bin/$s"
    done
    echo "Linked. Run 'just status' to verify."

# Full setup: back up existing config, then link the harness
setup: backup link

# Remove harness symlinks, restore originals from backup, unregister MCP servers
unlink:
    #!/usr/bin/env bash
    set -euo pipefail
    restore_one() {
        local target="$1"
        if [ ! -L "$target" ]; then
            echo "  not a harness symlink: $target"
            return 0
        fi
        rm "$target"
        local name latest
        name=$(basename "$target")
        latest=$(ls -dt "{{ backup_dir }}/linked-originals/$name".* 2>/dev/null | head -1 || true)
        if [ -n "$latest" ]; then
            mv "$latest" "$target"
            echo "  restored: $target"
        else
            echo "  removed: $target (no original to restore)"
        fi
    }
    for d in {{ harness_dirs }}; do
        restore_one "{{ claude_dir }}/$d"
    done
    restore_one "{{ claude_dir }}/CLAUDE.md"
    restore_one "{{ claude_dir }}/settings.json"
    for s in {{ launchers }}; do
        restore_one "{{ bin_dir }}/$s"
    done
    claude mcp remove -s user context7 >/dev/null 2>&1 || true
    claude mcp remove -s user tavily  >/dev/null 2>&1 || true
    echo "Unlinked. Originals (if any) restored from {{ backup_dir }}/linked-originals."

# Show current state: symlinks, claude version, main model, env vars
status:
    #!/usr/bin/env bash
    echo "=== Claude Code ==="
    command -v claude >/dev/null 2>&1 \
        && echo "  version: $(claude --version 2>/dev/null)" \
        || echo "  NOT INSTALLED"
    echo ""
    echo "=== Symlinks (~/.claude) ==="
    for t in CLAUDE.md settings.json {{ harness_dirs }}; do
        target="{{ claude_dir }}/$t"
        if [ -L "$target" ]; then
            echo "  $t -> $(readlink "$target")"
        elif [ -e "$target" ]; then
            echo "  $t: NOT LINKED (real file/dir)"
        else
            echo "  $t: MISSING"
        fi
    done
    echo ""
    echo "=== Model launchers (~/.local/bin) ==="
    for s in {{ launchers }}; do
        if [ -L "{{ bin_dir }}/$s" ]; then
            echo "  $s -> $(readlink "{{ bin_dir }}/$s")"
        else
            echo "  $s: NOT LINKED"
        fi
    done
    echo ""
    echo "=== Main model ==="
    python3 -c "import json; d=json.load(open('{{ harness_dir }}/settings.json')); print('  model:', d.get('model', '(not set)')); print('  advisor:', d.get('advisorModel', '(not set)')); print('  fallback:', d.get('fallbackModel', '(not set)'))" 2>/dev/null \
        || echo "  (settings.json unreadable)"
    echo ""
    echo "=== Environment ==="
    for var in OPENROUTER_API_KEY TAVILY_API_KEY CONTEXT7_API_KEY; do
        if [ -n "${!var:-}" ]; then echo "  $var: set"; else echo "  $var: NOT SET"; fi
    done

# Verify harness structure, linkage, and configuration
test:
    #!/usr/bin/env bash
    set -euo pipefail
    ok=true
    fail() { echo "  FAIL: $1"; ok=false; }
    pass() { echo "  OK: $1"; }
    warn() { echo "  SKIP: $1"; }

    echo "=== Config files ==="
    for f in CLAUDE.md settings.json models-changelog.md; do
        [ -f "{{ harness_dir }}/$f" ] && pass "$f" || fail "$f missing"
    done

    echo ""
    echo "=== Symlinks ==="
    for t in CLAUDE.md settings.json {{ harness_dirs }}; do
        [ -L "{{ claude_dir }}/$t" ] && pass "~/.claude/$t" || fail "~/.claude/$t not linked"
    done
    for s in {{ launchers }}; do
        [ -L "{{ bin_dir }}/$s" ] && pass "$s launcher" || fail "$s launcher not linked"
    done

    echo ""
    echo "=== Agents (10) ==="
    for a in frontend backend architect security qa legal finance researcher content-writer data-generator; do
        [ -f "{{ harness_dir }}/agents/$a.md" ] && pass "$a" || fail "$a missing"
    done

    echo ""
    echo "=== Skills (9) ==="
    for s in brainstorming frontend-design model-scout skill-creator plugin-creator orca-phase pr-briefing agents-vault ocr-review; do
        [ -f "{{ harness_dir }}/skills/$s/SKILL.md" ] && pass "$s" || fail "$s missing"
    done

    echo ""
    echo "=== Commands (4) ==="
    for c in intro onboard briefing merge-prs; do
        [ -f "{{ harness_dir }}/commands/$c.md" ] && pass "$c" || fail "$c missing"
    done

    echo ""
    echo "=== Rules (7) ==="
    for r in python-style typescript-style pr-size-limit claude-tips incidental-finds intercom agent-teams; do
        [ -f "{{ harness_dir }}/rules/$r.md" ] && pass "$r" || fail "$r missing"
    done

    echo ""
    echo "=== Settings ==="
    python3 -c 'import json; d = json.load(open("{{ harness_dir }}/settings.json")); assert d["model"] == "claude-sonnet-5", d.get("model"); assert "advisorModel" in d and "fallbackModel" in d' \
        && pass "settings.json valid, model pinned" \
        || fail "settings.json invalid or model wrong"
    grep -q 'bash-guard.sh' "{{ harness_dir }}/settings.json" && pass "bash-guard hook wired" || fail "bash-guard hook missing"
    [ -x "{{ harness_dir }}/hooks/bash-guard.sh" ] && pass "bash-guard executable" || fail "bash-guard not executable"

    echo ""
    echo "=== Model launchers ==="
    for s in {{ launchers }}; do
        f="{{ harness_dir }}/models/bin/$s"
        if [ -x "$f" ] && bash -n "$f"; then pass "$s"; else fail "$s missing or invalid"; fi
    done
    grep -q 'openrouter.ai/api' "{{ harness_dir }}/models/bin/claude-or" && pass "OpenRouter base URL" || fail "OpenRouter base URL missing"
    grep -q 'z-ai/glm-5.3' "{{ harness_dir }}/models/bin/claude-glm" && pass "glm launcher model" || fail "glm launcher model missing"
    grep -q 'google/gemini-3.7-flash' "{{ harness_dir }}/models/bin/claude-gemini" && pass "gemini launcher model" || fail "gemini launcher model missing"
    grep -q 'apiKeyHelper' "{{ harness_dir }}/models/bin/claude-or" && pass "apiKeyHelper fix" || fail "apiKeyHelper fix missing"
    [ -f "{{ harness_dir }}/models/or-stream-fix.py" ] && pass "or-stream-fix proxy file" || fail "or-stream-fix proxy missing"
    python3 -c "import ast; ast.parse(open('{{ harness_dir }}/models/or-stream-fix.py').read())" \
        && pass "or-stream-fix syntax" || fail "or-stream-fix syntax invalid"
    grep -q 'via-proxy' "{{ harness_dir }}/models/bin/claude-gemini" && pass "gemini proxy routing" || fail "gemini proxy routing missing"

    echo ""
    echo "=== MCP servers ==="
    claude mcp list 2>/dev/null | grep -q context7 && pass "context7 registered" || fail "context7 not registered"
    claude mcp list 2>/dev/null | grep -q tavily && pass "tavily registered" || fail "tavily not registered"
    if docker ps --format '{{{{.Names}}' 2>/dev/null | grep -qx hindsight; then
        claude mcp list 2>/dev/null | grep -q hindsight && pass "hindsight registered" || fail "hindsight container is up but MCP not registered (run 'just mcp')"
    else
        warn "hindsight container not running (shared with omp-setup — optional here)"
    fi
    if command -v agentsview >/dev/null 2>&1; then
        claude mcp list 2>/dev/null | grep -q agentsview && pass "agentsview registered" || fail "agentsview installed but MCP not registered (run 'just mcp')"
    else
        warn "agentsview CLI not installed (shared with omp-setup — optional here)"
    fi

    echo ""
    echo "=== OCR review CLI ==="
    if command -v ocr >/dev/null 2>&1; then
        pass "ocr CLI installed ($(ocr --version 2>/dev/null | head -1))"
    else
        warn "ocr CLI not installed (run 'just install-ocr')"
    fi

    echo ""
    if $ok; then echo "All checks passed."; else echo "Some checks failed."; exit 1; fi

# Check required environment variables
check-env:
    #!/usr/bin/env bash
    ok=true
    for var in OPENROUTER_API_KEY TAVILY_API_KEY CONTEXT7_API_KEY; do
        if [ -z "${!var:-}" ]; then
            echo "MISSING: $var"
            ok=false
        else
            echo "OK: $var"
        fi
    done
    $ok || { echo ""; echo "Set missing vars in your shell profile (~/.zshrc)."; exit 1; }
