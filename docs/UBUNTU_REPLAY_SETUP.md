# Ubuntu device setup — replay checklist (from Cursor session)

Use this on a **fresh Ubuntu** machine to approximate the same environment we set up for **FoulWard**. Adjust paths (`$HOME`, clone location) to match yours.

---

## 1. Base system (optional but useful)

```bash
sudo apt-get update && sudo apt-get install -y \
  ca-certificates curl wget git build-essential \
  python3-pip python3-venv python3-dev unzip tar pkg-config libssl-dev
```

Or use the script in the repo: `../scripts/apt-first-launch.sh` from workspace root (if present).

---

## 2. Clone and SSH to GitHub

```bash
mkdir -p ~/workspace && cd ~/workspace
git clone git@github.com:JerseyWolf/FoulWard.git
cd FoulWard
git checkout main
```

**SSH key (no HTTPS token for `git push`):**

```bash
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/id_ed25519
eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub   # add to GitHub → Settings → SSH keys
ssh-keyscan -t ed25519,rsa github.com >> ~/.ssh/known_hosts
ssh -T git@github.com
git remote set-url origin git@github.com:JerseyWolf/FoulWard.git
```

---

## 3. Godot 4.6.x (editor binary outside repo)

Download **Godot 4.6.x stable** for Linux x86_64 from [godotengine.org](https://godotengine.org/download/linux/), extract e.g.:

`~/workspace/tools/godot/Godot_v4.6.1-stable_linux.x86_64`

Optional launcher (adapt paths):

`~/workspace/scripts/run-godot.sh` — should use `-e --path` to your **FoulWard** clone.

---

## 4. Node.js 20+ (for MCP / `npx`)

Ubuntu’s default `nodejs` may be too old. Options:

- **Tarball** under `~/workspace/tools/node-v20/` (add `.../bin` to `PATH`), or  
- **nvm** / **NodeSource** — your choice.

Then:

```bash
cd tools/mcp-support && npm install
cd MCPs/godot-mcp-pro-v1.6.1/server && npm install
```

---

## 5. `uv` (GDAI MCP Python bridge)

Per [GDAI docs](https://gdaimcp.com/docs/installation):

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
# ensure ~/.local/bin on PATH; verify: uv --version
```

---

## 6. GDAI addon (in repo)

On `main`, the full addon lives only under **`addons/gdai-mcp-plugin-godot/`** (including `bin/` and `gdai_mcp_server.py`). **Do not** duplicate another copy under `res://MCPs/.../addons/` — it breaks GDExtension and the **HTTP bridge on port 3571**.

---

## 7. Cursor MCP

Project file: **`.cursor/mcp.json`** (Linux paths; update to your home if different).

Servers: **godot-mcp-pro**, **gdai-mcp-godot** (`uv run` …), **sequential-thinking**, **filesystem-workspace**, **github**.

**GitHub token (not committed):**

1. Create a **fine-grained PAT** on GitHub (repo-scoped).
2. `mkdir -p ~/.cursor && chmod 700 ~/.cursor`
3. Create **`~/.cursor/github-mcp.env`**:

   `GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...`

4. `chmod 600 ~/.cursor/github-mcp.env`
5. **Cursor → MCP: Restart Servers**

See **`.cursor/github-mcp.env.example`** and **`CURRENT_STATUS.md`** §6.

**Note:** Cursor resolves MCP server IDs like `project-0-FoulWard-github` in tooling; short names in `mcp.json` are the logical names.

---

## 8. VMware / display (if applicable)

VMware guests use **`vmwgfx`** + **`open-vm-tools-desktop`**. For smoother 3D, enable **3D acceleration** and enough video RAM in the VM settings. Expect **llvmpipe** if 3D is off.

---

## 9. Tests (headless GdUnit)

From repo root:

```bash
/path/to/Godot --headless --path . \
  -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
  --ignoreHeadlessMode -a "res://tests"
```

First-time or clean clones may need **one editor import** (or synced `.godot`) so global classes resolve — see **`CURRENT_STATUS.md`**.

---

## 10. What we fixed in the repo (historical)

- Single clone path (**FoulWard**); removed duplicate **`foul-ward`** clone.
- **MCP** paths switched from Windows to Linux; added **filesystem** + **github** MCP entries.
- **Removed duplicate GDAI** trees (`MCPs/144326_...`, later **`MCPs/gdaimcp/addons/...`**) so only **`addons/gdai-mcp-plugin-godot/`** remains under `res://`.
- **Git**: HTTPS → **SSH** remote; **`known_hosts`** for GitHub.
- **Docs**: **`CURRENT_STATUS.md`**, **`.cursor/rules/mcp-godot-workflow.mdc`**, **`MCPs/gdaimcp/README.md`**, **`MCPs/sync_gdai_addon_into_project.sh`**.

---

## 11. GDAI + Godot MCP expectations

- **`gdai_mcp_server.py`** proxies MCP to **`http://localhost:3571`** served **inside the Godot editor**. Open the project, enable **GDAI MCP**, then restart MCP in Cursor.
- **Godot MCP Pro** uses WebSocket ports **6505–6509**; editor must be running with its plugin enabled.

---

## 12. Editor plugins (your current `project.godot`)

Plugins enabled include **GdUnit4**, **GDAI MCP**, and **Godot MCP** (order may vary). Autoloads may include **GDAIMCPRuntime**; Godot MCP autoload lines may differ from older commits — re-enable in **Project Settings** if MCP features are missing.

---

*Last aligned with repo state at session end; re-read `CURRENT_STATUS.md` if Godot or MCP versions change.*
