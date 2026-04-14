#!/usr/bin/env bash
# =============================================================================
# run-all.sh  —  Full MCP purge pipeline via Cursor CLI
# Run from the repo root: bash scripts/mcp-purge/run-all.sh
# Requires: export CURSOR_API_KEY=your_key_here
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()  { echo -e "${RED}[FAIL]${NC} $*"; exit 1; }

# ---------------------------------------------------------------------------
# Step 0 — Install Cursor CLI if missing
# ---------------------------------------------------------------------------
log "Checking Cursor CLI..."
if ! command -v cursor-agent &>/dev/null; then
    warn "cursor-agent not found. Installing..."
    curl https://cursor.com/install -fsS | bash
    export PATH="$HOME/.local/bin:$PATH"
    command -v cursor-agent &>/dev/null \
        || die "Install succeeded but cursor-agent not on PATH.\nAdd ~/.local/bin to your PATH and re-run."
    ok "cursor-agent installed: $(cursor-agent --version)"
else
    ok "cursor-agent already installed: $(cursor-agent --version)"
fi

if [[ -z "${CURSOR_API_KEY:-}" ]]; then
    die "CURSOR_API_KEY is not set.\nExport it first: export CURSOR_API_KEY=your_key\nGet it at https://cursor.com/settings"
fi

# ---------------------------------------------------------------------------
# Helper — run one prompt file as a fresh cursor-agent chat, wait to finish
# ---------------------------------------------------------------------------
run_prompt() {
    local step="$1"
    local prompt_file="$2"
    local logfile="$LOG_DIR/step${step}.log"

    log "================================================================"
    log "STEP $step — $(basename "$prompt_file")"
    log "Prompt : $prompt_file"
    log "Log    : $logfile"
    log "Dir    : $REPO_ROOT"
    log "================================================================"

    # --print  = non-interactive headless mode (exits when done)
    # --force  = allow file edits without confirmation prompts
    # -f       = read prompt from file
    # -d       = working directory (repo root)
    cursor-agent \
        --print \
        --force \
        -f "$prompt_file" \
        -d "$REPO_ROOT" \
        2>&1 | tee "$logfile"

    local exit_code="${PIPESTATUS[0]}"
    [[ $exit_code -eq 0 ]] || die "Step $step FAILED (exit $exit_code). See $logfile"
    ok "Step $step complete."
    echo ""
}

# ---------------------------------------------------------------------------
# Run all four steps sequentially — each waits for the previous to finish
# ---------------------------------------------------------------------------
run_prompt 1 "$SCRIPT_DIR/prompt1-move-mcps.txt"
run_prompt 2 "$SCRIPT_DIR/prompt2-purge-history.txt"
run_prompt 3 "$SCRIPT_DIR/prompt3-verify.txt"
run_prompt 4 "$SCRIPT_DIR/prompt4-update-docs.txt"

ok "ALL STEPS COMPLETE. Logs saved to $LOG_DIR/"