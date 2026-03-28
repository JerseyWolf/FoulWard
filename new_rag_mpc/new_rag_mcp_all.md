AGENTS.md

# AGENTS.md — Foul Ward AI Assistant Standing Orders

> **Place this file in the Foul Ward project root (`~/FoulWard/AGENTS.md`).**
> Cursor reads this automatically at the start of every session.

---

## MANDATORY PRE-FLIGHT (Do these BEFORE any work)

### 1. Orient yourself on the current project state

Before making ANY changes, call the `query_project_knowledge` MCP tool:

```
query_project_knowledge(
    question="What is the current state of the project? What systems exist, what was last implemented, and what are the known issues?",
    domain="all"
)
```

Read the response fully. If the answer is incomplete, make follow-up queries targeting specific domains (`code`, `architecture`, `resources`).

### 2. Check SimBot data before balance work

Before ANY task related to game balance, enemy stats, building tuning, economy numbers, wave scaling, or difficulty progression, call:

```
get_recent_simbot_summary(n_runs=3)
```

Ground all balance suggestions in actual simulation data. Never invent numbers.

### 3. Check INDEX_SHORT.md before creating new files

Before creating any new `.gd`, `.tscn`, `.tres`, or test file:

```
query_project_knowledge(
    question="What files exist in the project? Show me INDEX_SHORT.md",
    domain="architecture"
)
```

- Verify the file doesn't already exist.
- Verify the name follows the project naming conventions.
- Verify the directory placement matches the established structure.

### 4. Check CONVENTIONS.md before writing any code

If you haven't already reviewed it this session:

```
query_project_knowledge(
    question="What are the coding conventions for this project?",
    domain="architecture"
)
```

Follow ALL rules in CONVENTIONS.md without exception:
- `snake_case` for files, variables, functions
- `PascalCase` for `class_name` and scene tree nodes
- `UPPER_SNAKE_CASE` for constants and enum values
- All signals through `SignalBus` only
- Explicit types on every parameter and return value
- No magic numbers — everything in `.tres` or named constants
- Test naming: `test_{what}_{condition}_{expected}`

---

## MANDATORY POST-FLIGHT (Do these AFTER completing work)

### 5. Create/update the implementation log

After completing any task, create or update:

```
docs/PROMPT_[N]_IMPLEMENTATION.md
```

Where `[N]` is the next prompt number in sequence. This file must contain:
- What was requested
- What was implemented (every file created or modified)
- What tests were added and their pass/fail status
- Any deviations from the spec (with `# DEVIATION:` explanations)
- Known issues or follow-up items

### 6. Update INDEX files

After ANY file creation or modification:
- Update `INDEX_SHORT.md` with the new file entry (path, class_name, one-sentence description)
- Update `INDEX_FULL.md` with full public API documentation (methods, signals, exports, dependencies)

---

## LOOKUP PATTERNS

Use these queries to find specific information quickly:

| What you need | Query |
|---|---|
| How a system works | `query_project_knowledge("How does [system] work?", "architecture")` |
| A specific function signature | `query_project_knowledge("[function_name] signature parameters", "code")` |
| Resource file values | `query_project_knowledge("[resource_name] stats values", "resources")` |
| Signal flow | `query_project_knowledge("What signals does [system] emit and consume?", "architecture")` |
| Enemy/building stats | `query_project_knowledge("[entity_name] damage hp stats", "resources")` |
| Recent balance data | `get_recent_simbot_summary(n_runs=5)` |
| What was last implemented | `query_project_knowledge("What was implemented in the most recent prompt?", "architecture")` |
| Test patterns | `query_project_knowledge("test conventions GdUnit4", "architecture")` |

---

## DOMAIN GUIDE

When calling `query_project_knowledge`, set the `domain` parameter for better results:

| Domain | Contents | Use when... |
|---|---|---|
| `all` | Everything | General orientation, cross-cutting questions |
| `architecture` | .md docs (CONVENTIONS, ARCHITECTURE, INDEX files, PROMPT logs) | Understanding project structure, conventions, decisions |
| `code` | .gd scripts | Looking up function implementations, class APIs |
| `resources` | .tres files | Checking stat values, resource definitions |
| `simbot_logs` | .json/.csv logs | Analyzing simulation results, balance data |
| `balance` | resources + logs together | Balance analysis needing both data and sim results |

---

## ABSOLUTE RULES (Never violate these)

1. **NEVER hardcode gameplay values in scripts.** All numbers go in `.tres` resource files.
2. **NEVER emit cross-system signals directly.** Everything goes through `SignalBus`.
3. **NEVER create a scene-instantiated node without an `initialize()` method.**
4. **NEVER skip writing tests.** Every new system gets at least one GdUnit4 test file.
5. **NEVER use `get_node()` with string paths for cross-scene references.** Use autoloads, signals, or typed `@onready`.
6. **ALWAYS use `is_instance_valid()` before accessing enemies, projectiles, or allies** that may be freed mid-frame.
7. **ALWAYS use `get_node_or_null()` with `push_warning()` (not `assert`)** for runtime node lookups that may fail in headless/test mode.
8. **ALWAYS run the test suite** before marking any task complete.


==================================

cursor_mcp_config.json

{
  "mcpServers": {
    "foulward-rag": {
      "command": "/home/jerzy-wolf/LLM/rag_env/bin/python",
      "args": ["/home/jerzy-wolf/LLM/rag_mcp_server.py"]
    }
  }
}


==================================

index.py

#!/usr/bin/env python3
"""
index.py — Foul Ward RAG Indexer
=================================
Scans the Godot project tree, chunks files by domain, and upserts into
four ChromaDB collections with hybrid BM25 + semantic retrieval support.

Usage:
    python index.py              # Full index (skips unchanged files)
    python index.py --force      # Force re-index everything
    python index.py --stats      # Print collection stats and exit

Collections:
    architecture  — .md files from ~/FoulWard/docs/
    code          — .gd files from ~/FoulWard/scripts/
    resources     — .tres files from ~/FoulWard/resources/
    simbot_logs   — .json/.csv from ~/FoulWard/logs/
"""

import argparse
import hashlib
import json
import os
import re
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Optional

import chromadb
from langchain_ollama import OllamaEmbeddings

from langchain_text_splitters import (
    RecursiveCharacterTextSplitter,
    Language,
)

# ════════════════════════════════════════════════════════════
# Configuration
# ════════════════════════════════════════════════════════════

FOULWARD_ROOT = Path.home() / "FoulWard"
LLM_ROOT = Path.home() / "LLM"
CHROMA_PATH = LLM_ROOT / "rag_db"
HASH_CACHE_PATH = LLM_ROOT / "index_hashes.json"

# Domain → (source directory, file extensions, collection name)
DOMAINS = {
    "architecture": {
        "source_dir": FOULWARD_ROOT / "docs",
        "extensions": {".md"},
        "collection": "architecture",
    },
    "code": {
        "source_dir": FOULWARD_ROOT / "scripts",
        "extensions": {".gd"},
        "collection": "code",
    },
    "resources": {
        "source_dir": FOULWARD_ROOT / "resources",
        "extensions": {".tres"},
        "collection": "resources",
    },
    "simbot_logs": {
        "source_dir": FOULWARD_ROOT / "logs",
        "extensions": {".json", ".csv"},
        "collection": "simbot_logs",
    },
}

# Also index key root-level project docs
ROOT_DOCS = [
    "CONVENTIONS.md",
    "ARCHITECTURE.md",
    "INDEX_FULL.md",
    "INDEX_SHORT.md",
    "INDEX_MACHINE.md",
]

# Chunking: use smaller chunks for code/resources, larger for docs
CODE_CHUNK_SIZE = 400        # tokens (approx, via char count * 0.75)
CODE_CHUNK_OVERLAP = 80
DOC_CHUNK_SIZE = 800
DOC_CHUNK_OVERLAP = 100

CODE_CHAR_CHUNK_SIZE = int(CODE_CHUNK_SIZE / 0.75)
CODE_CHAR_CHUNK_OVERLAP = int(CODE_CHUNK_OVERLAP / 0.75)

DOC_CHAR_CHUNK_SIZE = int(DOC_CHUNK_SIZE / 0.75)
DOC_CHAR_CHUNK_OVERLAP = int(DOC_CHUNK_OVERLAP / 0.75)

EMBEDDING_MODEL = "nomic-embed-text"

# ════════════════════════════════════════════════════════════
# Utilities
# ════════════════════════════════════════════════════════════


def file_hash(filepath: Path) -> str:
    """SHA-256 of file contents."""
    h = hashlib.sha256()
    h.update(filepath.read_bytes())
    return h.hexdigest()


def load_hash_cache() -> dict:
    """Load the hash cache from disk."""
    if HASH_CACHE_PATH.exists():
        return json.loads(HASH_CACHE_PATH.read_text())
    return {}


def save_hash_cache(cache: dict) -> None:
    """Persist the hash cache."""
    HASH_CACHE_PATH.write_text(json.dumps(cache, indent=2))


def parse_run_id_from_filename(filename: str) -> str:
    """
    Extract a run_id from SimBot log filenames.
    Expected patterns:
        simbot_run_20260325_143022.json
        simbot_endless_strategy_physical_001.csv
        run_003.json
    Falls back to the stem if no pattern matches.
    """
    stem = Path(filename).stem
    # Try date-stamped pattern
    m = re.search(r"run[_-]?(\d{8}[_-]?\d{6})", stem)
    if m:
        return m.group(0)
    # Try numbered pattern
    m = re.search(r"run[_-]?(\d+)", stem)
    if m:
        return m.group(0)
    # Try strategy pattern
    m = re.search(r"(strategy[_-]\w+[_-]\d+)", stem)
    if m:
        return m.group(0)
    return stem


def extract_gdscript_class_name(content: str) -> Optional[str]:
    """Pull class_name from a GDScript file."""
    m = re.search(r"^class_name\s+(\w+)", content, re.MULTILINE)
    return m.group(1) if m else None


def extract_tres_resource_type(content: str) -> Optional[str]:
    """Pull the resource type from a .tres file header."""
    m = re.search(r"\[gd_resource\s+type=\"(\w+)\"", content)
    return m.group(1) if m else None


# ════════════════════════════════════════════════════════════
# Chunking strategies per domain
# ════════════════════════════════════════════════════════════


def get_splitter_for_domain(domain: str) -> RecursiveCharacterTextSplitter:
    """Return a text splitter tuned to the domain's content type."""
    if domain == "code":
        # GDScript is close enough to Python for the Language splitter
        return RecursiveCharacterTextSplitter.from_language(
            language=Language.PYTHON,
            chunk_size=CODE_CHAR_CHUNK_SIZE,
            chunk_overlap=CODE_CHAR_CHUNK_OVERLAP,
        )
    elif domain == "resources":
        # .tres files are INI-like with [resource] / [sub_resource] sections
        return RecursiveCharacterTextSplitter(
            separators=["\n[", "\n\n", "\n", " "],
            chunk_size=CODE_CHAR_CHUNK_SIZE,
            chunk_overlap=CODE_CHAR_CHUNK_OVERLAP,
        )
    elif domain == "simbot_logs":
        # JSON/CSV: split on record boundaries
        return RecursiveCharacterTextSplitter(
            separators=["\n},\n", "\n}\n", "\n\n", "\n", " "],
            chunk_size=DOC_CHAR_CHUNK_SIZE,
            chunk_overlap=DOC_CHAR_CHUNK_OVERLAP,
        )
    else:
        # Markdown docs: use heading-aware splitting
        return RecursiveCharacterTextSplitter.from_language(
            language=Language.MARKDOWN,
            chunk_size=DOC_CHAR_CHUNK_SIZE,
            chunk_overlap=DOC_CHAR_CHUNK_OVERLAP,
        )


def build_metadata(filepath: Path, domain: str, chunk_index: int) -> dict:
    """Build per-chunk metadata."""
    stat = filepath.stat()
    meta = {
        "source_file": str(filepath),
        "file_name": filepath.name,
        "file_type": filepath.suffix.lstrip("."),
        "domain": domain,
        "chunk_index": chunk_index,
        "last_modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
        "file_size_bytes": stat.st_size,
    }

    if domain == "simbot_logs":
        meta["run_id"] = parse_run_id_from_filename(filepath.name)

    return meta


# ════════════════════════════════════════════════════════════
# Indexing pipeline
# ════════════════════════════════════════════════════════════


def collect_files(domain_config: dict) -> list[Path]:
    """Recursively find all matching files in a source directory."""
    source_dir = domain_config["source_dir"].resolve()
    extensions = domain_config["extensions"]
    if not source_dir.exists():
        return []
    files: list[Path] = []
    for ext in extensions:
        for p in source_dir.rglob(f"*{ext}"):
            try:
                resolved = p.resolve()
            except OSError:
                continue
            # Guard against symlink escape outside the project root
            if source_dir in resolved.parents or resolved.parent == source_dir:
                files.append(p)
    return sorted(files)


def collect_root_docs() -> list[Path]:
    """Collect root-level project docs that go into the architecture collection."""
    files: list[Path] = []
    for name in ROOT_DOCS:
        p = FOULWARD_ROOT / name
        if p.exists():
            files.append(p)
    return files


def index_collection(
    client: chromadb.ClientAPI,
    domain: str,
    files: list[Path],
    hash_cache: dict,
    force: bool = False,
) -> tuple[int, int]:
    """
    Index files into a ChromaDB collection.
    Returns (files_processed, chunks_added).
    """
    config = DOMAINS[domain]
    collection_name = config["collection"]

    # Get or create collection
    collection = client.get_or_create_collection(
        name=collection_name,
        metadata={"hnsw:space": "cosine"},
    )

    splitter = get_splitter_for_domain(domain)
    embeddings = OllamaEmbeddings(model=EMBEDDING_MODEL)

    files_processed = 0
    chunks_added = 0

    for filepath in files:
        file_key = str(filepath)
        current_hash = file_hash(filepath)

        # Skip unchanged files unless forced
        if not force and hash_cache.get(file_key) == current_hash:
            continue

        # Read file content
        try:
            content = filepath.read_text(encoding="utf-8", errors="replace")
        except Exception as e:
            print(f"  WARN: Could not read {filepath}: {e}")
            continue

        if not content.strip():
            continue

        # Delete existing chunks for this file before re-indexing
        try:
            existing = collection.get(where={"source_file": file_key})
            if existing and existing.get("ids"):
                collection.delete(ids=existing["ids"])
        except Exception:
            # Collection might be empty or not support where yet
            pass

        # Build header context for code/resource files
        header = ""
        if domain == "code":
            cls = extract_gdscript_class_name(content)
            if cls:
                header = f"# GDScript class: {cls}\n# File: {filepath.name}\n\n"
        elif domain == "resources":
            rtype = extract_tres_resource_type(content)
            if rtype:
                header = f"# Godot Resource type: {rtype}\n# File: {filepath.name}\n\n"

        # Chunk the content
        chunks = splitter.split_text(content)

        if not chunks:
            continue

        # Prepare batch for ChromaDB
        ids: list[str] = []
        documents: list[str] = []
        metadatas: list[dict] = []

        for i, chunk_text in enumerate(chunks):
            path_hash = hashlib.md5(str(filepath).encode()).hexdigest()[:8]
            doc_id = f"{collection_name}::{path_hash}::{filepath.name}::chunk_{i}"
            meta = build_metadata(filepath, domain, i)

            # Prepend header context to first chunk
            if i == 0 and header:
                chunk_text = header + chunk_text

            ids.append(doc_id)
            documents.append(chunk_text)
            metadatas.append(meta)

        # Embed and upsert in batches of 50
        batch_size = 50
        for batch_start in range(0, len(ids), batch_size):
            batch_end = min(batch_start + batch_size, len(ids))
            batch_docs = documents[batch_start:batch_end]
            batch_ids = ids[batch_start:batch_end]
            batch_meta = metadatas[batch_start:batch_end]

            try:
                batch_embeddings = embeddings.embed_documents(batch_docs)
                collection.upsert(
                    ids=batch_ids,
                    documents=batch_docs,
                    embeddings=batch_embeddings,
                    metadatas=batch_meta,
                )
            except Exception as e:
                print(
                    f"  ERROR embedding/upserting {filepath.name} "
                    f"batch {batch_start}: {e}"
                )
                continue

        # Update hash cache
        hash_cache[file_key] = current_hash
        files_processed += 1
        chunks_added += len(chunks)
        print(f"  Indexed: {filepath.name} → {len(chunks)} chunks")

    return files_processed, chunks_added


def print_stats(client: chromadb.ClientAPI) -> None:
    """Print summary statistics for all collections."""
    print("\n╔══════════════════════════════════════════════════╗")
    print("║         ChromaDB Collection Statistics           ║")
    print("╠══════════════════════════════════════════════════╣")
    for domain, config in DOMAINS.items():
        name = config["collection"]
        try:
            coll = client.get_collection(name=name)
            count = coll.count()
            print(f"║  {name:<20s}  {count:>6d} chunks          ║")
        except Exception:
            print(f"║  {name:<20s}  (not created yet)       ║")
    print("╚══════════════════════════════════════════════════╝")


# ════════════════════════════════════════════════════════════
# Main
# ════════════════════════════════════════════════════════════


def main():
    parser = argparse.ArgumentParser(description="Foul Ward RAG Indexer")
    parser.add_argument("--force", action="store_true", help="Force re-index all files")
    parser.add_argument("--stats", action="store_true", help="Print stats and exit")
    args = parser.parse_args()

    # Ensure directories exist
    CHROMA_PATH.mkdir(parents=True, exist_ok=True)

    # Initialize ChromaDB
    client = chromadb.PersistentClient(path=str(CHROMA_PATH))

    if args.stats:
        print_stats(client)
        return

    print("═══════════════════════════════════════════════════")
    print("  Foul Ward RAG Indexer")
    print(f"  Project root: {FOULWARD_ROOT}")
    print(f"  ChromaDB:     {CHROMA_PATH}")
    print(f"  Mode:         {'FORCE' if args.force else 'incremental'}")
    print("═══════════════════════════════════════════════════")

    if not FOULWARD_ROOT.exists():
        print(f"\nERROR: Project root not found at {FOULWARD_ROOT}")
        print("  Set FOULWARD_ROOT or create a symlink.")
        sys.exit(1)

    hash_cache = load_hash_cache()
    total_files = 0
    total_chunks = 0
    start = time.time()

    for domain, config in DOMAINS.items():
        print(f"\n[{domain}] Scanning {config['source_dir']}...")
        files = collect_files(config)

        # Add root docs to architecture collection
        if domain == "architecture":
            files.extend(collect_root_docs())

        if not files:
            print("  No files found.")
            continue

        print(f"  Found {len(files)} files.")
        f_count, c_count = index_collection(
            client, domain, files, hash_cache, force=args.force
        )
        total_files += f_count
        total_chunks += c_count

    save_hash_cache(hash_cache)
    elapsed = time.time() - start

    print(f"\n{'═' * 52}")
    print(f"  Done in {elapsed:.1f}s")
    print(f"  Files processed: {total_files}")
    print(f"  Chunks added:    {total_chunks}")

    print_stats(client)


if __name__ == "__main__":
    main()


==================================

install.sh

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


==================================

rag_mcp_server.py

#!/usr/bin/env python3
"""
rag_mcp_server.py — Foul Ward RAG MCP Server
==============================================
Stdio-transport MCP server exposing two tools to Cursor:

    query_project_knowledge(question, domain="all")
        Hybrid BM25 + semantic retrieval over project files,
        with LLM-generated answers citing source files.

    get_recent_simbot_summary(n_runs=3)
        Structured summary of recent SimBot log entries.

Uses LangGraph with SQLite checkpointer for cross-session memory.

Run directly:
    python rag_mcp_server.py

Or via Cursor MCP config (stdio transport).
"""

import json
import logging
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Optional

# ── MCP imports ──────────────────────────────────────────
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.server.lowlevel import NotificationOptions
from mcp.server.models import InitializationOptions
from mcp.types import Tool, TextContent

# ── LangChain / retrieval imports ────────────────────────
import chromadb
from langchain_ollama import OllamaEmbeddings, ChatOllama
from langchain_community.retrievers import BM25Retriever
from langchain_core.documents import Document
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage
from langchain_core.output_parsers import StrOutputParser

# ── LangGraph memory ────────────────────────────────────
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.sqlite import SqliteSaver
from typing import TypedDict, Annotated, Sequence
from langchain_core.messages import BaseMessage
import operator
import sqlite3

# ════════════════════════════════════════════════════════════
# Configuration
# ════════════════════════════════════════════════════════════

LLM_ROOT = Path.home() / "LLM"
CHROMA_PATH = LLM_ROOT / "rag_db"
MEMORY_DB_PATH = LLM_ROOT / "rag_memory.db"

EMBEDDING_MODEL = "nomic-embed-text"
# Use a smaller / faster model for MCP tool calls; keep 30B Qwen for background use
LLM_MODEL = "qwen2.5:3b"

COLLECTION_NAMES = ["architecture", "code", "resources", "simbot_logs"]

DOMAIN_MAP = {
    "all": COLLECTION_NAMES,
    "architecture": ["architecture"],
    "code": ["code"],
    "resources": ["resources"],
    "simbot_logs": ["simbot_logs"],
    # Convenience aliases
    "docs": ["architecture"],
    "scripts": ["code"],
    "balance": ["resources", "simbot_logs"],
    "logs": ["simbot_logs"],
}

SYSTEM_PROMPT = (
    "You are an expert game balance analyst and Godot 4 architect "
    "specializing in the Foul Ward tower defense project. You have deep "
    "knowledge of the project's GDScript codebase, Types.EnemyType and "
    "Types.BuildingType enums, building and enemy data .tres resources, "
    "SimBot simulation logs, wave scaling formulas, and economy balance. "
    "When answering questions always cite the specific source file the "
    "information comes from. When making balance suggestions always "
    "reference the actual numbers from the resource files and simulation "
    "logs, never invent values."
)

# Retrieval tuning
SEMANTIC_TOP_K = 8
BM25_TOP_K = 8
FINAL_TOP_K = 8        # Slightly higher now that chunks are smaller
SEMANTIC_WEIGHT = 0.5  # In ensemble: 0.5 semantic + 0.5 BM25

# ════════════════════════════════════════════════════════════
# Logging
# ════════════════════════════════════════════════════════════

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LLM_ROOT / "mcp_server.log"),
        logging.StreamHandler(sys.stderr),
    ],
)
log = logging.getLogger("foulward_rag")

# ════════════════════════════════════════════════════════════
# ChromaDB + Retrieval Layer
# ════════════════════════════════════════════════════════════


class ProjectRetriever:
    """
    Hybrid retriever over Foul Ward's ChromaDB collections.
    Combines BM25 keyword search with ChromaDB semantic search
    via score-based ensemble ranking.
    """

    def __init__(self):
        self.client = chromadb.PersistentClient(path=str(CHROMA_PATH))
        self.embeddings = OllamaEmbeddings(model=EMBEDDING_MODEL)
        self.collections: dict[str, chromadb.Collection] = {}
        self._bm25_cache: dict[str, BM25Retriever] = {}

        for name in COLLECTION_NAMES:
            try:
                self.collections[name] = self.client.get_collection(name=name)
                count = self.collections[name].count()
                log.info(f"Loaded collection '{name}': {count} chunks")
                self._warm_bm25(name)
            except Exception as e:
                log.warning(f"Collection '{name}' not found: {e}")

    def _warm_bm25(self, coll_name: str) -> None:
        """Pre-load documents and build a BM25 index for a single collection."""
        coll = self.collections.get(coll_name)
        if coll is None or coll.count() == 0:
            return
        try:
            data = coll.get(include=["documents", "metadatas"])
        except Exception as e:
            log.error(f"BM25 warmup failed for '{coll_name}': {e}")
            return

        docs: list[Document] = []
        for i, doc_text in enumerate(data["documents"]):
            meta = data["metadatas"][i] if data["metadatas"] else {}
            docs.append(Document(page_content=doc_text, metadata=meta))

        if docs:
            self._bm25_cache[coll_name] = BM25Retriever.from_documents(
                docs, k=BM25_TOP_K
            )
            log.info(f"BM25 index warmed for '{coll_name}' ({len(docs)} docs)")

    def _semantic_search(
        self, query: str, collection_names: list[str], top_k: int = SEMANTIC_TOP_K
    ) -> list[Document]:
        """Embed query and search ChromaDB collections."""
        query_embedding = self.embeddings.embed_query(query)
        results: list[Document] = []

        for coll_name in collection_names:
            coll = self.collections.get(coll_name)
            if coll is None or coll.count() == 0:
                continue

            k = min(top_k, coll.count())
            try:
                res = coll.query(
                    query_embeddings=[query_embedding],
                    n_results=k,
                    include=["documents", "metadatas", "distances"],
                )
            except Exception as e:
                log.error(f"Semantic search failed on '{coll_name}': {e}")
                continue

            for i, doc_text in enumerate(res["documents"][0]):
                meta = res["metadatas"][0][i] if res["metadatas"] else {}
                distance = res["distances"][0][i] if res["distances"] else 1.0
                meta["_score"] = 1.0 - distance  # Convert distance to similarity
                meta["_source"] = "semantic"
                results.append(Document(page_content=doc_text, metadata=meta))

        return results

    def _bm25_search(
        self, query: str, collection_names: list[str], top_k: int = BM25_TOP_K
    ) -> list[Document]:
        """
        BM25 keyword search using pre-warmed per-collection indices.
        """
        all_results: list[Document] = []

        for coll_name in collection_names:
            retriever = self._bm25_cache.get(coll_name)
            if retriever is None:
                continue

            try:
                retriever.k = top_k
                results = retriever.invoke(query)
                for doc in results:
                    doc.metadata["_source"] = "bm25"
                all_results.extend(results)
            except Exception as e:
                log.error(f"BM25 search failed for '{coll_name}': {e}")

        return all_results

    def hybrid_search(
        self,
        query: str,
        domain: str = "all",
        top_k: int = FINAL_TOP_K,
    ) -> list[Document]:
        """
        Ensemble retrieval: merge semantic + BM25 results,
        deduplicate by source_file+chunk_index, and rank.
        """
        collection_names = DOMAIN_MAP.get(domain, COLLECTION_NAMES)

        semantic_results = self._semantic_search(query, collection_names)
        bm25_results = self._bm25_search(query, collection_names)

        # Merge with weighted scoring
        scored: dict[str, tuple[float, Document]] = {}

        for doc in semantic_results:
            key = f"{doc.metadata.get('source_file', '')}::{doc.metadata.get('chunk_index', 0)}"
            score = doc.metadata.get("_score", 0.5) * SEMANTIC_WEIGHT
            if key in scored:
                old_score, old_doc = scored[key]
                scored[key] = (old_score + score, old_doc)
            else:
                scored[key] = (score, doc)

        for i, doc in enumerate(bm25_results):
            key = f"{doc.metadata.get('source_file', '')}::{doc.metadata.get('chunk_index', 0)}"
            # BM25 rank-based score: higher rank = higher score
            bm25_score = (1.0 - i / max(len(bm25_results), 1)) * (1.0 - SEMANTIC_WEIGHT)
            if key in scored:
                old_score, old_doc = scored[key]
                scored[key] = (old_score + bm25_score, old_doc)
            else:
                scored[key] = (bm25_score, doc)

        # Sort by combined score, take top_k
        ranked = sorted(scored.values(), key=lambda x: x[0], reverse=True)
        return [doc for _, doc in ranked[:top_k]]

    def get_simbot_log_entries(self, n_runs: int = 3) -> list[dict]:
        """
        Retrieve the N most recent SimBot log chunks, grouped by run_id.
        Returns raw chunk data for the summary tool to process.
        """
        coll = self.collections.get("simbot_logs")
        if coll is None or coll.count() == 0:
            return []

        try:
            data = coll.get(include=["documents", "metadatas"])
        except Exception:
            return []

        # Group by run_id, sort by last_modified descending
        runs: dict[str, list[dict]] = {}
        for i, doc_text in enumerate(data["documents"]):
            meta = data["metadatas"][i] if data["metadatas"] else {}
            run_id = meta.get("run_id", "unknown")
            if run_id not in runs:
                runs[run_id] = []
            runs[run_id].append(
                {
                    "text": doc_text,
                    "metadata": meta,
                }
            )

        def run_sort_key(run_chunks: list[dict]) -> str:
            dates = [c["metadata"].get("last_modified", "") for c in run_chunks]
            return max(dates) if dates else ""

        sorted_runs = sorted(
            runs.items(), key=lambda kv: run_sort_key(kv[1]), reverse=True
        )
        return [
            {"run_id": rid, "chunks": chunks}
            for rid, chunks in sorted_runs[:n_runs]
        ]


# ════════════════════════════════════════════════════════════
# LangGraph Memory + RAG Chain
# ════════════════════════════════════════════════════════════


class AgentState(TypedDict):
    messages: Annotated[Sequence[BaseMessage], operator.add]
    context: str
    question: str
    domain: str


def build_rag_graph(retriever: ProjectRetriever) -> tuple[Any, SqliteSaver]:
    """
    Build a LangGraph RAG chain with SQLite-backed memory.
    The graph: retrieve_context → maybe_summarize → generate_answer
    """
    llm = ChatOllama(model=LLM_MODEL, temperature=0.1)

    # ── SQLite checkpointer for cross-session memory ─────
    conn = sqlite3.connect(str(MEMORY_DB_PATH), check_same_thread=False)
    checkpointer = SqliteSaver(conn)
    checkpointer.setup()

    # ── Prompt template ──────────────────────────────────
    prompt = ChatPromptTemplate.from_messages(
        [
            ("system", SYSTEM_PROMPT),
            MessagesPlaceholder(variable_name="history"),
            (
                "human",
                """Answer the following question using the retrieved context.
Cite source files when referencing specific information.
If the context doesn't contain enough information, say so clearly.

Context:
{context}

Question: {question}""",
            ),
        ]
    )

    # ── Graph nodes ──────────────────────────────────────

    def retrieve_node(state: AgentState) -> dict:
        """Retrieve relevant context for the question."""
        question = state["question"]
        domain = state.get("domain", "all")
        docs = retriever.hybrid_search(question, domain=domain, top_k=FINAL_TOP_K)

        context_parts = []
        for doc in docs:
            fname = doc.metadata.get("file_name", "unknown")
            context_parts.append(f"[Source: {fname}]\n{doc.page_content}")

        context = (
            "\n\n---\n\n".join(context_parts)
            if context_parts
            else "No relevant context found."
        )
        return {"context": context}

    def maybe_summarize_node(state: AgentState) -> dict:
        """
        Optional summarization/prune step to keep history bounded.
        Summarize when more than 10 messages are stored.
        """
        messages = list(state.get("messages", []))
        if len(messages) <= 10:
            return {}

        # Use last 4 messages as recent context, summarize the rest.
        recent = messages[-4:]
        to_summarize = messages[:-4]

        summary_prompt = ChatPromptTemplate.from_messages(
            [
                (
                    "system",
                    "Summarize the following conversation so far into a concise "
                    "system message that captures key decisions and facts.",
                ),
                MessagesPlaceholder(variable_name="history"),
            ]
        )
        chain = summary_prompt | llm | StrOutputParser()
        summary_text = chain.invoke({"history": to_summarize})
        summary_msg = SystemMessage(content=f"Conversation summary: {summary_text}")

        return {"messages": [summary_msg] + recent}

    def generate_node(state: AgentState) -> dict:
        """Generate an answer using LLM with context and history."""
        history = list(state.get("messages", []))[-20:]

        chain = prompt | llm | StrOutputParser()
        answer = chain.invoke(
            {
                "history": history,
                "context": state["context"],
                "question": state["question"],
            }
        )

        return {
            "messages": [
                HumanMessage(content=state["question"]),
                AIMessage(content=answer),
            ]
        }

    # ── Build graph ──────────────────────────────────────
    graph = StateGraph(AgentState)
    graph.add_node("retrieve", retrieve_node)
    graph.add_node("maybe_summarize", maybe_summarize_node)
    graph.add_node("generate", generate_node)
    graph.add_edge(START, "retrieve")
    graph.add_edge("retrieve", "maybe_summarize")
    graph.add_edge("maybe_summarize", "generate")
    graph.add_edge("generate", END)

    compiled = graph.compile(checkpointer=checkpointer, durability="sync")
    return compiled, checkpointer


# ════════════════════════════════════════════════════════════
# Tool implementations
# ════════════════════════════════════════════════════════════


def format_sources(docs: list[Document]) -> list[dict]:
    """Format source documents for the tool response."""
    sources: list[dict] = []
    seen = set()
    for doc in docs:
        fname = doc.metadata.get("file_name", "unknown")
        if fname in seen:
            continue
        seen.add(fname)
        sources.append(
            {
                "file": fname,
                "path": doc.metadata.get("source_file", ""),
                "domain": doc.metadata.get("domain", ""),
                "preview": (
                    doc.page_content[:200] + "..."
                    if len(doc.page_content) > 200
                    else doc.page_content
                ),
            }
        )
    return sources


def format_simbot_summary(run_data: list[dict]) -> str:
    """
    Parse SimBot log chunks and produce a structured summary.
    Handles both JSON and CSV log formats.
    """
    if not run_data:
        return json.dumps(
            {
                "status": "no_data",
                "message": (
                    "No SimBot logs found in the index. "
                    "Run SimBot first, then re-index."
                ),
            },
            indent=2,
        )

    summaries = []
    for run in run_data:
        run_id = run["run_id"]
        combined_text = "\n".join(c["text"] for c in run["chunks"])
        last_mod = max(
            (c["metadata"].get("last_modified", "") for c in run["chunks"]),
            default="unknown",
        )

        metrics: dict[str, Any] = {
            "run_id": run_id,
            "last_modified": last_mod,
            "chunk_count": len(run["chunks"]),
        }

        # Try JSON parsing for structured metrics
        try:
            data = json.loads(combined_text)
            if isinstance(data, dict):
                for key in [
                    "waves_survived",
                    "total_gold_earned",
                    "total_gold_spent",
                    "enemies_killed",
                    "buildings_placed",
                    "buildings_destroyed",
                    "tower_hp_remaining",
                    "strategy_profile",
                    "total_days",
                ]:
                    if key in data:
                        metrics[key] = data[key]
            elif isinstance(data, list):
                metrics["record_count"] = len(data)
                if data and isinstance(data[0], dict):
                    metrics["sample_keys"] = list(data[0].keys())[:10]
        except (json.JSONDecodeError, TypeError):
            pass

        # Regex extraction for common metric patterns in any text format
        patterns = {
            "waves_survived": r"waves?[_\s]*survived[:\s]*(\d+)",
            "gold_earned": r"gold[_\s]*earned[:\s]*(\d+)",
            "gold_spent": r"gold[_\s]*spent[:\s]*(\d+)",
            "enemies_killed_total": r"(?:total[_\s]*)?enemies[_\s]*killed[:\s]*(\d+)",
            "buildings_placed": r"buildings?[_\s]*placed[:\s]*(\d+)",
            "tower_hp_remaining": r"tower[_\s]*hp[_\s]*(?:remaining)?[:\s]*(\d+)",
        }
        for metric_name, pattern in patterns.items():
            if metric_name not in metrics:
                m = re.search(pattern, combined_text, re.IGNORECASE)
                if m:
                    metrics[metric_name] = int(m.group(1))

        # Include raw text preview if no structured data found
        if len(metrics) <= 3:  # Only run_id, last_modified, chunk_count
            metrics["raw_preview"] = combined_text[:500]

        summaries.append(metrics)

    return json.dumps(
        {
            "status": "ok",
            "runs_found": len(summaries),
            "summaries": summaries,
        },
        indent=2,
    )


# ════════════════════════════════════════════════════════════
# MCP Server
# ════════════════════════════════════════════════════════════


def _check_ollama_alive() -> bool:
    import urllib.request

    try:
        urllib.request.urlopen("http://localhost:11434/api/tags", timeout=3)
        return True
    except Exception:
        return False


def create_server() -> Server:
    """Create and configure the MCP server."""
    if not _check_ollama_alive():
        log.error(
            "Ollama is not reachable at http://localhost:11434 — "
            "embedding and LLM calls will fail. "
            "Start Ollama with `ollama serve` first."
        )

    server = Server("foulward-rag")
    retriever = ProjectRetriever()

    # Warm up LLM and embeddings with a dummy call to reduce first-call latency
    try:
        _ = retriever.embeddings.embed_query("warmup")
    except Exception as e:
        log.warning(f"Embedding warmup failed: {e}")

    rag_graph, _checkpointer = build_rag_graph(retriever)

    # ── Tool definitions ─────────────────────────────────
    TOOLS = [
        Tool(
            name="query_project_knowledge",
            description=(
                "Search the Foul Ward project knowledge base using hybrid "
                "BM25 + semantic retrieval. Returns an LLM-generated answer "
                "with source file citations. Use this to look up architecture "
                "decisions, GDScript code patterns, resource file values, "
                "signal flows, or any project-specific information. "
                "Set domain to narrow the search: 'all', 'architecture' (docs), "
                "'code' (GDScript), 'resources' (.tres files), 'simbot_logs', "
                "or 'balance' (resources + logs together)."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "question": {
                        "type": "string",
                        "description": "The question to answer about the Foul Ward project.",
                    },
                    "domain": {
                        "type": "string",
                        "description": (
                            "Which domain to search. Options: all, architecture, "
                            "code, resources, simbot_logs, balance, docs, scripts, logs."
                        ),
                        "default": "all",
                        "enum": [
                            "all",
                            "architecture",
                            "code",
                            "resources",
                            "simbot_logs",
                            "balance",
                            "docs",
                            "scripts",
                            "logs",
                        ],
                    },
                },
                "required": ["question"],
            },
        ),
        Tool(
            name="get_recent_simbot_summary",
            description=(
                "Get a structured summary of the most recent SimBot simulation "
                "runs. Returns key metrics per run: waves survived, gold earned/"
                "spent, enemies killed by type, buildings placed/destroyed, and "
                "tower HP remaining. Use this before any balance-related work to "
                "ground your analysis in actual simulation data."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "n_runs": {
                        "type": "integer",
                        "description": "Number of recent runs to summarize (default: 3).",
                        "default": 3,
                        "minimum": 1,
                        "maximum": 20,
                    },
                },
                "required": [],
            },
        ),
    ]

    # ── MCP handlers ─────────────────────────────────────

    @server.list_tools()
    async def list_tools() -> list[Tool]:
        return TOOLS

    @server.call_tool()
    async def call_tool(name: str, arguments: dict) -> list[TextContent]:
        log.info(f"Tool call: {name}({arguments})")

        if name == "query_project_knowledge":
            question = arguments.get("question", "")
            domain = arguments.get("domain", "all")

            if not question.strip():
                return [
                    TextContent(
                        type="text",
                        text=json.dumps({"error": "Empty question provided."}),
                    )
                ]

            # Run hybrid retrieval
            docs = retriever.hybrid_search(question, domain=domain)
            sources = format_sources(docs)

            # Run through LangGraph RAG chain with memory
            try:
                config = {"configurable": {"thread_id": f"foulward_{domain}"}}
                result = rag_graph.invoke(
                    {
                        "messages": [],
                        "context": "",
                        "question": question,
                        "domain": domain,
                    },
                    config=config,
                )

                # Extract the last AI message as the answer
                answer = ""
                for msg in reversed(result.get("messages", [])):
                    if isinstance(msg, AIMessage):
                        answer = msg.content
                        break

                if not answer:
                    answer = "Could not generate an answer from the retrieved context."

            except Exception as e:
                log.error(f"RAG chain error: {e}")
                # Fallback: return raw context without LLM synthesis
                context_text = "\n\n".join(
                    f"[{d.metadata.get('file_name', '?')}] {d.page_content[:300]}"
                    for d in docs
                )
                answer = f"(LLM unavailable — raw retrieval results)\n\n{context_text}"

            response = {
                "answer": answer,
                "sources": sources,
                "domain_searched": domain,
                "chunks_retrieved": len(docs),
            }
            return [TextContent(type="text", text=json.dumps(response, indent=2))]

        elif name == "get_recent_simbot_summary":
            n_runs = arguments.get("n_runs", 3)
            run_data = retriever.get_simbot_log_entries(n_runs=n_runs)
            summary = format_simbot_summary(run_data)
            return [TextContent(type="text", text=summary)]

        else:
            return [
                TextContent(
                    type="text",
                    text=json.dumps({"error": f"Unknown tool: {name}"}),
                )
            ]

    return server


# ════════════════════════════════════════════════════════════
# Entry point
# ════════════════════════════════════════════════════════════


async def main():
    log.info("Starting Foul Ward RAG MCP Server...")
    log.info(f"ChromaDB: {CHROMA_PATH}")
    log.info(f"Memory DB: {MEMORY_DB_PATH}")

    server = create_server()

    async with stdio_server() as (read_stream, write_stream):
        log.info("MCP server running on stdio transport.")
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="foulward-rag",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                ),
            ),
        )


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())


==================================

requirements.txt

# Foul Ward RAG + MCP Pipeline
# Python 3.10+ required

# --- LLM & Embeddings ---
langchain==0.3.25
langchain-community==0.3.24
langchain-ollama==0.3.3
langchain-chroma==0.2.4
langchain-core==0.3.59

# --- LangGraph (memory / agent orchestration) ---
langgraph==0.4.7
langgraph-checkpoint-sqlite==2.0.6

# --- Vector store ---
chromadb==1.0.12

# --- Retrieval ---
rank-bm25==0.2.2

# --- MCP server ---
mcp==1.9.3

# --- File watching (Python-side hash checks) ---
watchdog==6.0.0

# --- Document parsing ---
tiktoken==0.9.0

# --- Utilities ---
aiosqlite==0.21.0
pydantic==2.11.3


==================================

start_all.sh

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


==================================

watch_and_reindex.sh

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


==================================

