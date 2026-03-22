# Current status — recreate this workspace (Ubuntu / new machine)

Use this checklist to match **Godot + Cursor + optional MCP** setup after cloning. Paths below use **`$REPO`** as the absolute path to your clone (e.g. `/home/you/FoulWard`).

---

## 1. Prerequisites

| Tool | Notes |
|------|--------|
| **Git** | Clone `main` from your remote (e.g. GitHub). |
| **Godot 4.6+** | Project targets **4.6** (`project.godot` → `config/features`). Install [Godot for Linux](https://godotengine.org/download/linux/) or distro package if version matches. |
| **Node.js (LTS)** | For MCP servers that use `node` (Godot MCP Pro build, Sequential Thinking). |
| **Python 3** | For `addons/gdai-mcp-plugin-godot/gdai_mcp_server.py` (GDAI MCP). |

Optional: `rg` (ripgrep) for fast search; same as most dev setups.

---

## 2. Clone and open the project

```bash
git clone <your-remote-url> FoulWard
cd FoulWard
git checkout main
```

Open **`project.godot`** in Godot (or “Import” the folder). First open regenerates **`.godot/`** locally (gitignored).

---

## 3. Editor plugins

`project.godot` → **`[editor_plugins]`** enables:

- `res://addons/godot_mcp/plugin.cfg`
- `res://addons/gdai-mcp-plugin-godot/plugin.cfg`

**GdUnit4** is present under `addons/gdUnit4/`; enable it in **Project → Project Settings → Plugins** if you want the in-editor test UI (tests also run via CLI without enabling).

---

## 4. Run the full test suite (headless)

From **`$REPO`**:

```bash
godot --headless -s "addons/gdUnit4/bin/GdUnitCmdTool.gd" --ignoreHeadlessMode -a "res://tests"
```

- Expect **289** cases, **0** failures in the **Overall Summary** line.
- If the process **crashes after** tests on some OSes, still trust the summary line when it printed.

---

## 5. Optional: MCP support npm dependencies

**Sequential Thinking** (referenced from `.cursor/mcp.json`):

```bash
cd "$REPO/tools/mcp-support"
npm install
```

**Godot MCP Pro** (if you use the `godot-mcp-pro` server): vendor tree lives under `MCPs/godot-mcp-pro-v1.6.1/`. The repo **ignores** `MCPs/godot-mcp-pro-v1.6.1/server/node_modules/`. If documentation for that bundle requires it:

```bash
cd "$REPO/MCPs/godot-mcp-pro-v1.6.1/server"
npm install
```

The **canonical** Godot MCP addon used by the **project** is under **`addons/godot_mcp/`** (already in repo). The `MCPs/` copy is for the **Node MCP server** tooling, not required to run the game.

---

## 6. Cursor: MCP configuration (match “tools access”)

The repo may contain **`.cursor/mcp.json`**. Entries use **absolute Windows paths** from an earlier machine; on Ubuntu you must **rewrite** paths to your clone.

1. Open **Cursor Settings → MCP** (or edit **`.cursor/mcp.json`** in the project).
2. For each server, set:
   - **`command`** — `node`, `python`, or full path if needed.
   - **`args`** — First argument must be the script under **`$REPO/...`** using **Linux paths**.
   - **`cwd`** — Usually **`$REPO`** or `tools/mcp-support` for sequential-thinking.

**Example pattern** (adjust filenames to match your tree):

```json
{
  "mcpServers": {
    "godot-mcp-pro": {
      "command": "node",
      "args": ["/home/you/FoulWard/MCPs/godot-mcp-pro-v1.6.1/server/build/index.js"],
      "cwd": "/home/you/FoulWard",
      "env": { "GODOT_MCP_PORT": "6505" }
    },
    "gdai-mcp-godot": {
      "command": "python3",
      "args": ["/home/you/FoulWard/addons/gdai-mcp-plugin-godot/gdai_mcp_server.py"],
      "cwd": "/home/you/FoulWard",
      "env": { "GDAI_MCP_SERVER_PORT": "3571" }
    },
    "sequential-thinking": {
      "command": "node",
      "args": ["/home/you/FoulWard/tools/mcp-support/node_modules/@modelcontextprotocol/server-sequential-thinking/dist/index.js"],
      "cwd": "/home/you/FoulWard/tools/mcp-support"
    }
  }
}
```

3. Restart Cursor after saving.
4. Godot **editor** may need to be running with the **MCP plugins enabled** for some tools to attach to the running game.

**Security:** Do not commit API keys into `mcp.json`. Keep secrets in environment or Cursor’s user config if a server requires them.

---

## 7. Cursor rules

Project rules may live under **`.cursor/rules/`** (e.g. `mcp-godot-workflow.mdc`). They apply automatically when the folder is present; no extra install.

---

## 8. Git line endings (already configured)

- **`.gitattributes`** forces LF for text and marks common binaries.
- Clone on Ubuntu should give consistent behavior with Windows contributors.

---

## 9. What “same stage” means for gameplay

- **No save system** — single session; state is whatever is in `GameManager` / managers at runtime.
- **Balance** — driven by `resources/**/*.tres`; see **`FULL_PROJECT_SUMMARY.md`** for system map.
- **Latest feature checklist** — **`AUTONOMOUS_SESSION_2.md`**.

---

## 10. Quick verification

1. Open project in Godot → **F5** play (main scene).
2. Run GdUnit command in §4 → **0 failures** in summary.

If both work, your environment matches the intended dev loop for this repo.

---

*Update this file when Godot version, test count, or MCP layout changes.*
