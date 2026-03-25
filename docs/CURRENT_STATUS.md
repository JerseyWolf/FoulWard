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

## 4. Run tests (headless)

From **`$REPO`**:

**Full suite** (everything under `res://tests/` — use before merge / milestones):

```bash
./tools/run_gdunit.sh
```

**Quick subset** (allowlist of lighter suites — faster while iterating; edit the list in the script):

```bash
./tools/run_gdunit_quick.sh
```

Both scripts **tee stdout/stderr** to a log under **`reports/`** (gitignored): `gdunit_quick_run.log` and `gdunit_full_run.log`. Override with **`GDUNIT_LOG_FILE`**. For automation or long runs, inspect failures with e.g. `tail -n 100 reports/gdunit_full_run.log` or `rg 'FAIL|ERROR' reports/gdunit_full_run.log`.

If your shell defines `godot` as a wrapper function that forces editor mode (for example appending `-e`), use the direct Godot binary path for CLI tests. Editor-mode wrappers inject `--editor` and break GdUnit CLI parsing.

Recommended CLI form (explicitly no `--editor`):

```bash
godot --headless --path "$REPO" --script addons/gdUnit4/bin/GdUnitCmdTool.gd -- -a "res://tests"
```

- Expect **289** cases, **0** failures in the **Overall Summary** line.
- If the process **crashes after** tests on some OSes, still trust the summary line when it printed.

### Main scene smoke (Phase 2 E2E, headless)

Optional quick check that **`res://scenes/main.tscn`** loads and runs briefly without crashing (separate from GdUnit):

```bash
cd "$REPO"
./tools/smoke_main_scene.sh
```

Or set `GODOT=/path/to/Godot_v4.6.x` if the binary is not in `PATH` or `repo_root/Godot_*.x86_64`. Expect **exit code 0** on Linux. On some Windows setups a similar headless run may still fault; use **editor Run** for validation there.

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
6. **GitHub** (`github`): `npx` runs `@modelcontextprotocol/server-github`. **Cursor has no separate “MCP secrets” form for stdio servers** — use **`env` / `envFile` in `mcp.json`** (see [Cursor MCP](https://cursor.com/docs/mcp)) or **`~/.cursor/mcp.json`** for global tools.

   - **Recommended:** create **`~/.cursor/github-mcp.env`** with `GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...` and `chmod 600` it. The project references **`envFile`: `${userHome}/.cursor/github-mcp.env`**. Template: **`.cursor/github-mcp.env.example`**.
   - **Alternate:** `export GITHUB_PERSONAL_ACCESS_TOKEN=...` before starting Cursor; `mcp.json` also passes **`${env:GITHUB_PERSONAL_ACCESS_TOKEN}`**.

   Then **MCP: Restart Servers**.

**All five MCPs — what each needs:**

| Server | What you need |
|--------|----------------|
| `godot-mcp-pro` | Node, `npm install` under `MCPs/godot-mcp-pro-v1.6.1/server`, **Godot** open, plugin on, **6505** |
| `gdai-mcp-godot` | `uv`, **Godot editor open** on this project, GDAI plugin enabled; HTTP on **3571** is served **by Godot** (not by Cursor). Avoid duplicate GDAI copies under `res://` (only `addons/gdai-mcp-plugin-godot/`). |
| `sequential-thinking` | `npm install` in `tools/mcp-support` |
| `filesystem-workspace` | `npx` (may download first run); `PATH` in `mcp.json` |
| `github` | **`GITHUB_PERSONAL_ACCESS_TOKEN`** via **`~/.cursor/github-mcp.env`** or shell env |

**GDAI vendor:** keep a **single** addon tree at **`addons/gdai-mcp-plugin-godot/`** only. See **`MCPs/gdaimcp/README.md`** (duplicate copies under `MCPs/.../addons/` break the GDExtension and the **3571** bridge).

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

**Security:** Do not commit API keys or PATs into `mcp.json`. The **GitHub** MCP reads the token from **`~/.cursor/github-mcp.env`** and/or **`${env:GITHUB_PERSONAL_ACCESS_TOKEN}`** — never from the repo.

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
