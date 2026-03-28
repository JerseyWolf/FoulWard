#!/usr/bin/env bash
# ============================================================
# start_all.sh — Foul Ward RAG Pipeline Launcher
# Starts background services for the RAG pipeline.
#
# Usage:
#   ~/LLM/start_all.sh
# ============================================================
set -uo pipefail

LLM_ROOT="$HOME/LLM"
# Must match LLM_MODEL in rag_mcp_server.py (Ollama pull for local RAG)
LLM_MODEL="qwen2.5:3b"
VENV_DIR="$LLM_ROOT/rag_env"
PID_DIR="$LLM_ROOT/pids"
LOG_DIR="$LLM_ROOT/logs"

mkdir -p "$PID_DIR" "$LOG_DIR"

echo "═══════════════════════════════════════════════════"
echo "  Foul Ward RAG Pipeline — Launcher"
echo "═══════════════════════════════════════════════════"

is_running() {
    local pidfile="$1"
    if [ -f "$pidfile" ]; then
        local pid
        pid=$(cat "$pidfile")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

stop_if_running() {
    local name="$1"
    local pidfile="$PID_DIR/${name}.pid"
    if is_running "$pidfile"; then
        local pid
        pid=$(cat "$pidfile")
        echo "  Stopping existing $name (PID $pid)..."
        kill "$pid" 2>/dev/null || true
        sleep 1
    fi
}

# 1. Ollama
echo ""
echo "[1/2] Checking Ollama..."

if ! command -v ollama &>/dev/null; then
    echo "  ERROR: Ollama not installed. Run install.sh first."
    exit 1
fi

if pgrep -x "ollama" &>/dev/null; then
    echo "  Ollama is already running."
    pgrep -x "ollama" | head -1 > "$PID_DIR/ollama.pid"
else
    echo "  Starting Ollama daemon..."
    ollama serve > "$LOG_DIR/ollama.log" 2>&1 &
    OLLAMA_PID=$!
    echo "$OLLAMA_PID" > "$PID_DIR/ollama.pid"
    sleep 3

    if ! pgrep -x "ollama" &>/dev/null; then
        echo "  ERROR: Ollama failed to start. Check $LOG_DIR/ollama.log"
        exit 1
    fi
    echo "  Ollama started (PID $OLLAMA_PID)."
fi

if ! ollama list 2>/dev/null | grep -q "nomic-embed-text"; then
    echo "  Pulling nomic-embed-text..."
    ollama pull nomic-embed-text
fi

if ! ollama list 2>/dev/null | grep -q "$LLM_MODEL"; then
    echo "  Pulling $LLM_MODEL..."
    ollama pull "$LLM_MODEL" || echo "  Skipped pull for $LLM_MODEL."
fi

# 2. File watcher only; MCP server is spawned by Cursor
echo ""
echo "[2/2] Starting file watcher..."

stop_if_running "watcher"

nohup bash "$LLM_ROOT/watch_and_reindex.sh" \
    > "$LOG_DIR/watcher_stdout.log" 2>&1 &
WATCHER_PID=$!
echo "$WATCHER_PID" > "$PID_DIR/watcher.pid"

sleep 1

if kill -0 "$WATCHER_PID" 2>/dev/null; then
    echo "  File watcher started (PID $WATCHER_PID)."
    echo "  Log: $LLM_ROOT/watch.log"
else
    echo "  WARN: File watcher failed to start."
    echo "  Check: sudo apt install inotify-tools"
fi

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Services launched."
echo ""
echo "  Ollama:       $(pgrep -x ollama &>/dev/null && echo 'running' || echo 'not running')"
echo "  File Watcher: $(is_running "$PID_DIR/watcher.pid" && echo "running (PID $(cat "$PID_DIR/watcher.pid"))" || echo 'not running')"
echo ""
echo "  NOTE: The MCP server uses stdio transport."
echo "  Cursor spawns it directly via cursor_mcp_config.json."
echo "═══════════════════════════════════════════════════"
