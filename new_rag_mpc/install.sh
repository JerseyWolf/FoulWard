#!/usr/bin/env bash
# ============================================================
# Foul Ward RAG + MCP Pipeline — Installer
# Run once: bash install.sh
# ============================================================
set -euo pipefail

LLM_ROOT="$HOME/LLM"
VENV_DIR="$LLM_ROOT/rag_env"
DB_DIR="$LLM_ROOT/rag_db"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "═══════════════════════════════════════════════════"
echo "  Foul Ward RAG Pipeline — Install"
echo "═══════════════════════════════════════════════════"

# ── 1. Create directory structure ────────────────────────
echo "[1/5] Creating directories..."
mkdir -p "$LLM_ROOT"
mkdir -p "$DB_DIR"
mkdir -p "$LLM_ROOT/logs"

# ── 2. Create Python virtualenv ──────────────────────────
echo "[2/5] Creating Python 3.10+ virtualenv at $VENV_DIR..."

PYTHON_BIN=""
for candidate in python3.12 python3.11 python3.10 python3; do
    if command -v "$candidate" &>/dev/null; then
        ver=$("$candidate" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        major=$(echo "$ver" | cut -d. -f1)
        minor=$(echo "$ver" | cut -d. -f2)
        if [ "$major" -ge 3 ] && [ "$minor" -ge 10 ]; then
            PYTHON_BIN="$candidate"
            break
        fi
    fi
done

if [ -z "$PYTHON_BIN" ]; then
    echo "ERROR: Python 3.10+ not found. Install it first."
    exit 1
fi

echo "  Using: $PYTHON_BIN ($($PYTHON_BIN --version))"
"$PYTHON_BIN" -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

# ── 3. Install pip dependencies ──────────────────────────
echo "[3/5] Installing pip dependencies..."
pip install --upgrade pip wheel setuptools -q
pip install -r "$SCRIPT_DIR/requirements.txt" -q

# ── 4. Check / install Ollama + pull embedding model ─────
echo "[4/5] Pulling nomic-embed-text via Ollama..."

if ! command -v ollama &>/dev/null; then
    echo "  Ollama not found. Installing..."
    curl -fsSL https://ollama.com/install.sh | sh
fi

# Start Ollama if not running
if ! pgrep -x "ollama" &>/dev/null; then
    echo "  Starting Ollama daemon..."
    ollama serve &>/dev/null &
    sleep 3
fi

ollama pull nomic-embed-text

# Also pull a local LLM for RAG generation (must match rag_mcp_server.py LLM_MODEL)
echo "  (Optional) pulling qwen2.5:3b for local RAG generation..."
ollama pull qwen2.5:3b || echo "  Skipped qwen2.5:3b pull — you can do this later."

# ── 5. Copy pipeline scripts ────────────────────────────
echo "[5/5] Deploying pipeline scripts to $LLM_ROOT..."

cp "$SCRIPT_DIR/index.py"              "$LLM_ROOT/index.py"
cp "$SCRIPT_DIR/rag_mcp_server.py"     "$LLM_ROOT/rag_mcp_server.py"
cp "$SCRIPT_DIR/watch_and_reindex.sh"  "$LLM_ROOT/watch_and_reindex.sh"
cp "$SCRIPT_DIR/start_all.sh"          "$LLM_ROOT/start_all.sh"
cp "$SCRIPT_DIR/requirements.txt"      "$LLM_ROOT/requirements.txt"

chmod +x "$LLM_ROOT/watch_and_reindex.sh"
chmod +x "$LLM_ROOT/start_all.sh"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Install complete."
echo ""
echo "  Next steps:"
echo "    1. Run the initial index:"
echo "       source ~/LLM/rag_env/bin/activate"
echo "       python ~/LLM/index.py"
echo ""
echo "    2. Start all services:"
echo "       ~/LLM/start_all.sh"
echo ""
echo "    3. Add MCP config to Cursor:"
echo "       See cursor_mcp_config.json"
echo ""
echo "    4. Place AGENTS.md in your Foul Ward project root"
echo "═══════════════════════════════════════════════════"
