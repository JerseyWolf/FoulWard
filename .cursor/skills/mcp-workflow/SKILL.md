---
name: mcp-workflow
description: >-
  Activate at the start of any Cursor session working on Foul Ward, or when
  working with MCP tools, Godot editor integration, scene tree validation,
  or error checking. Use when: MCP, Godot MCP, GDAI, cursor agent, editor
  integration, get_scene_tree, get_godot_errors, MCP server, port, WebSocket,
  toolchain, RAG, foulward-rag, sequential-thinking, no tools recovery.
compatibility: Godot 4.4, Cursor Pro, MCP servers listed below.
---

# MCP Workflow — Foul Ward

---

## MCP Servers

| Server name (in `.cursor/mcp.json`) | Role | Port / Notes |
|---|---|---|
| `godot-mcp-pro` | Editor integration via WebSocket | Port **6505**; needs Godot open with Godot MCP Pro plugin enabled |
| `gdai-mcp-godot` | Python bridge to editor HTTP API | Port **3571**; needs Godot open with GDAI MCP plugin enabled |
| `sequential-thinking` | Step-by-step reasoning | Needs `node` + `npm install` under `tools/mcp-support` |
| `filesystem-workspace` | Broader workspace filesystem access | — |
| `github` | GitHub API | Requires `GITHUB_PERSONAL_ACCESS_TOKEN` — never commit |
| `foulward-rag` | Project RAG (`query_project_knowledge`, etc.) | **Optional** — requires RAG service running from `~/LLM`; agents must NOT block if down |

---

## Mandatory Calls Every Session

    get_scene_tree — validate node paths BEFORE writing any get_node() call

    get_godot_errors — check for new errors AFTER making changes


Never write a `get_node()` call without first confirming the path exists in `get_scene_tree` output.

---

## RAG Server Rules

- `foulward-rag` is NOT always available — it requires the service under `~/LLM` to be running
- If available: call `query_project_knowledge` before writing new code for an existing system
- If available: call `get_recent_simbot_summary` when task touches balance, economy, or wave scaling
- If unavailable: note it in the implementation log and continue — never block on it

---

## GDAI stdout/stderr Rule

In any MCP bridge script (GDAI plugin code):
- **stdout**: JSON-RPC messages ONLY
- **stderr**: all debug logs
- `print()` to stdout will corrupt the JSON-RPC protocol

```gdscript
# WRONG in GDAI scripts
print("Debug: scene loaded")

# RIGHT
printerr("Debug: scene loaded")
```

---

## "No Tools" Recovery Procedure

If MCP tools fail to respond during a session:

1. Note the failure in `docs/PROMPT_[N]_IMPLEMENTATION.md`
2. Fall back to reading scene files directly via `filesystem-workspace`
3. Use known contracted node paths from `AGENTS.md` §Architecture
4. Do NOT assume node paths — use only contracted paths or read the .tscn file
5. Continue the session; do not block

Full detail: `AGENTS.md` and `.cursor/rules/mcp-godot-workflow.mdc`

---

## Session Start Checklist

[] Read AGENTS.md
[] Read docs/INDEX_SHORT.md
[] Call get_scene_tree (if task involves nodes)
[] Check get_godot_errors baseline
[] Check if foulward-rag is available (one test call)
[] Identify the relevant skill(s) for this session's task
