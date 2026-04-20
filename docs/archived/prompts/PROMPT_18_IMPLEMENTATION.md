## Prompt 18 — Foul Ward RAG + MCP Pipeline (implementation log)

### 2026-03-28

Installed and configured the local RAG + MCP stack under `~/LLM/` per project instructions:

1. **Directories:** `~/LLM/rag_db`, `~/LLM/logs`, `~/LLM/pids`
2. **Artifacts:** `requirements.txt`, `install.sh`, `index.py`, `rag_mcp_server.py`, `watch_and_reindex.sh`, `start_all.sh`, `cursor_mcp_config.json`
3. **Installer:** Ran `bash ~/LLM/install.sh` (recreated venv with `y` when prompted). Pulled `nomic-embed-text` and `qwen2.5:3b` via Ollama.
4. **Project root for indexer:** `index.py` expects `~/FoulWard`. A previous minimal `~/FoulWard` directory was moved to `~/FoulWard.bak_minimal_20260328` and replaced with a symlink to this repo (`~/workspace/foul-ward/FoulWard`) so `docs/`, `scripts/`, `resources/`, and root markdown files are indexed.
5. **Initial index:** `python ~/LLM/index.py` completed (ChromaDB: architecture, code, resources; `simbot_logs` empty until log files exist).
6. **Background:** `~/LLM/start_all.sh` ran; Ollama was already running. File watcher **did not** start: `inotify-tools` not installed (`sudo` password required in this environment). Run `sudo apt install inotify-tools` then re-run `start_all.sh`.
7. **Compatibility fix:** `rag_mcp_server.py` used `graph.compile(..., durability="sync")`, which LangGraph 0.4.10 rejects. Removed the `durability` argument so the MCP server starts and reaches “MCP server running.”

**Cursor:** Merge `~/LLM/cursor_mcp_config.json` into Cursor MCP settings (or add as a server), restart Cursor, confirm `foulward-rag` tools.
