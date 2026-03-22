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
| **`uv`** | [Recommended by GDAI](https://gdaimcp.com/docs/installation): run the MCP bridge with `uv run …/gdai_mcp_server.py` (`.cursor/mcp.json` uses this). Install via [uv install guide](https://docs.astral.sh/uv/getting-started/installation/) (binary ends up in `~/.local/bin/uv`). |

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

The repo ships **`.cursor/mcp.json`** with **Linux-friendly** absolute paths (example: `/home/you/workspace/FoulWard/...`). After cloning, **replace** those paths with your real **`$REPO`** if your home or folder name differs.

1. Install **Node** (for `godot-mcp-pro` + sequential-thinking) and **`uv`** (for GDAI), then run **`npm install`** in `tools/mcp-support` and `MCPs/godot-mcp-pro-v1.6.1/server` (see §5).
2. Open **Cursor Settings → MCP** — Cursor loads **project** `.cursor/mcp.json` when this folder is the workspace. Use **MCP: Restart Servers** after edits.
3. **GDAI** uses **`uv run`** → `addons/gdai-mcp-plugin-godot/gdai_mcp_server.py` (same pattern as [GDAI docs](https://gdaimcp.com/docs/installation)). Ensure **`~/.local/bin`** is on `PATH` for MCP (the checked-in `env.PATH` includes it).
4. **Godot**: open **`$REPO`** in the editor, enable **GDAI MCP** + **Godot MCP** under **Project → Project Settings → Plugins**, and keep the editor running while using MCP tools that talk to the game.
5. **Filesystem** (`filesystem-workspace`): `npx` runs `@modelcontextprotocol/server-filesystem` with your **workspace parent** as the allowed root (checked-in default: `/home/jerzy-wolf/workspace` — change in `.cursor/mcp.json` to match your machine).
6. **GitHub** (`github`): `npx` runs `@modelcontextprotocol/server-github`. Put your fine-grained PAT in **`~/.cursor/github-mcp.env`** as `GITHUB_PERSONAL_ACCESS_TOKEN=...` (see `.cursor/github-mcp.env.example`). The project `mcp.json` loads that file via **`envFile`** — nothing secret is committed. Then **MCP: Restart Servers**.

Vendor snapshot (no duplicate addon trees): **`MCPs/gdaimcp/addons/gdai-mcp-plugin-godot/`** mirrors **`addons/gdai-mcp-plugin-godot/`** (full plugin including `bin/` + `gdai_mcp_server.py` on `main`).

**Example shape** (paths must match your machine):

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
      "command": "/home/you/.local/bin/uv",
      "args": ["run", "/home/you/FoulWard/addons/gdai-mcp-plugin-godot/gdai_mcp_server.py"],
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

**Security:** Do not commit API keys or PATs into `mcp.json`. The **GitHub** MCP needs **`GITHUB_PERSONAL_ACCESS_TOKEN`** only via environment or Cursor’s secret UI.

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
