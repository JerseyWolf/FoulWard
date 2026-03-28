#!/usr/bin/env bash
# ============================================================
# watch_and_reindex.sh — Foul Ward incremental re-indexer
# Watches project source folders for changes and triggers
# an incremental index.py run on any file modification.
#
# Uses inotifywait (from inotify-tools package).
# Install: sudo apt install inotify-tools
#
# Usage:
#   ./watch_and_reindex.sh          # Foreground
#   ./watch_and_reindex.sh &        # Background
#   nohup ./watch_and_reindex.sh &  # Survives terminal close
# ============================================================
set -uo pipefail

LLM_ROOT="$HOME/LLM"
VENV_DIR="$LLM_ROOT/rag_env"
INDEX_SCRIPT="$LLM_ROOT/index.py"
LOG_FILE="$LLM_ROOT/watch.log"
FOULWARD_ROOT="$HOME/FoulWard"

# Directories to watch
WATCH_DIRS=(
    "$FOULWARD_ROOT/docs"
    "$FOULWARD_ROOT/scripts"
    "$FOULWARD_ROOT/resources"
    "$FOULWARD_ROOT/logs"
)

# Also watch root-level docs (handled via exact path filtering)
WATCH_FILES=(
    "$FOULWARD_ROOT/CONVENTIONS.md"
    "$FOULWARD_ROOT/ARCHITECTURE.md"
    "$FOULWARD_ROOT/INDEX_FULL.md"
    "$FOULWARD_ROOT/INDEX_SHORT.md"
)

# Debounce: minimum seconds between re-index runs
DEBOUNCE_SECONDS=10

# ── Preflight checks ────────────────────────────────────
if ! command -v inotifywait &>/dev/null; then
    echo "ERROR: inotifywait not found. Install with:"
    echo "  sudo apt install inotify-tools"
    exit 1
fi

if [ ! -f "$INDEX_SCRIPT" ]; then
    echo "ERROR: index.py not found at $INDEX_SCRIPT"
    echo "  Run install.sh first."
    exit 1
fi

if [ ! -d "$VENV_DIR" ]; then
    echo "ERROR: virtualenv not found at $VENV_DIR"
    echo "  Run install.sh first."
    exit 1
fi

# ── Build the watch path list ────────────────────────────
EXISTING_DIRS=()
for dir in "${WATCH_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        EXISTING_DIRS+=("$dir")
    else
        echo "WARN: Watch directory not found (will skip): $dir" | tee -a "$LOG_FILE"
    fi
done

if [ ${#EXISTING_DIRS[@]} -eq 0 ]; then
    echo "ERROR: No watch directories found. Is $FOULWARD_ROOT correct?"
    exit 1
fi

# ── Logging helper ───────────────────────────────────────
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

# ── Main watch loop ──────────────────────────────────────
log "═══ Foul Ward file watcher started ═══"
log "Watching: ${EXISTING_DIRS[*]}"
log "Debounce: ${DEBOUNCE_SECONDS}s"
log "Log file: $LOG_FILE"

LAST_RUN_FILE="/tmp/foulward_last_reindex"
echo "0" > "$LAST_RUN_FILE"

inotifywait \
    --monitor \
    --recursive \
    --format '%w%f %e' \
    --event modify,create,delete,move \
    "${EXISTING_DIRS[@]}" 2>/dev/null |
grep --line-buffered -E '\.(md|gd|tres|json|csv) ' |
while IFS=' ' read -r changed_path event; do
    NOW=$(date +%s)
    LAST_RUN=$(cat "$LAST_RUN_FILE" 2>/dev/null || echo 0)
    ELAPSED=$((NOW - LAST_RUN))

    if [ "$ELAPSED" -lt "$DEBOUNCE_SECONDS" ]; then
        continue
    fi

    echo "$NOW" > "$LAST_RUN_FILE"

    directory="$(dirname "$changed_path")/"
    filename="$(basename "$changed_path")"

    log "Change detected: $directory$filename ($event)"
    log "Running incremental re-index..."

    (
        source "$VENV_DIR/bin/activate"
        python "$INDEX_SCRIPT" 2>&1 | while read -r line; do
            log "  [index] $line"
        done
    )

    log "Re-index complete."
done
