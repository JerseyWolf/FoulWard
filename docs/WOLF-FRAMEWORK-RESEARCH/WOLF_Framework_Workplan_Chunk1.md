# WOLF Framework — Master Workplan
## Chunk 1 of 5: Foundations, Decisions & Phase 0–1 Sessions S01–S07

**Document version:** 1.0 | **Author:** Jerzy Wolf + Perplexity planning session | **Date:** 2026-04-27
**Status:** Living document — update after every session completes.

---

## Part A — Final Confirmed Decisions

These decisions are locked. Every session, every prompt, and every folder name in this document
derives from them. Do not revisit without updating the entire plan.

### Naming

| Thing | Name | Notes |
|---|---|---|
| GitHub org / root identity | `wolf-framework` | No "godot-" prefix — Godot specificity is self-evident from content |
| Core framework repo | `wolf-framework` | Godot 4 addons, templates, framework GDScript |
| MCP server repo | `wolf-mcp` | Python, pip-installable, stdio transport |
| Demo games repo | `wolf-games` | All 16 demo MVPs live here |
| Docs site repo | `wolf-docs` | Astro Starlight |
| Meta/umbrella repo | `wolf` | Git submodules pointing to all four; what users clone if they want everything |
| pip package name | `wolf-framework` | `pip install wolf-framework` → installs CLI |
| CLI command | `wolf` | `wolf new`, `wolf install`, `wolf art`, `wolf test`, `wolf simbot` |
| Local install default path | `~/wolf-framework` | User overrides with `wolf install --path /wherever` |

### Repository Split

```
GitHub: github.com/wolf-framework/
├── wolf              ← meta-repo (submodules to all four below)
├── wolf-framework    ← Phase 1 target: the complete framework
├── wolf-mcp          ← Phase 1 target: MCP server (pip package)
├── wolf-games        ← Phase 2 target: all 16 demo games
└── wolf-docs         ← Phase 3 target: Astro Starlight docs site
```

### Docker Split

| Image | Name | Base | GPU? | Contains |
|---|---|---|---|---|
| Dev container | `wolf-dev` | `mcr.microsoft.com/dotnet/sdk:8.0-jammy` + Godot 4.4 headless | No | Godot headless, .NET 8 SDK, GdUnit4, SimBot runner, RAG service (Ollama + ChromaDB), wolf-mcp |
| Art container | `wolf-art` | `nvidia/cuda:12.4.0-cudnn-devel-ubuntu22.04` + Python 3.11 | Yes (RTX 4090) | ComfyUI, FLUX.1-schnell, TRELLIS.2-4B, Mesh2Motion, Blender CLI, AudioCraft |

Both images are published to GHCR (`ghcr.io/wolf-framework/wolf-dev`, `ghcr.io/wolf-framework/wolf-art`).
Windows users run both via Docker Desktop + WSL2. Linux users run natively.

### RAG Architecture

- One shared `wolf-dev` container runs the RAG service
- Per-game config files at `config/rag/games/<game-name>.yaml`
- Master template at `config/rag/default.yaml` (all options documented, user copies + edits)
- Active game selected via `WOLF_ACTIVE_GAME` environment variable
- Godot docs: optional separate corpus, off by default, enabled via `godot_docs_corpus: true` in config

### Foul Ward

- **Frozen as-is.** Copied to `wolf-games/foul-ward/` at the start of Phase 0.
- The two open art bugs (FLUX black images, Arnulf 0 animations) are fixed **inside the WOLF
  art pipeline work** (Session S03), not inside the frozen Foul Ward repo.
- Foul Ward development resumes only after the framework is fully complete and shipped.

### Per-Session Workflow

```
Perplexity planning session
  → produces: session spec note + N Cursor prompts (copy-paste ready)
Cursor (Claude 3.7 Sonnet, daily work)
  → executes prompts
  → produces: code, files, session result report
Perplexity audit session
  → reads: result report + session spec
  → produces: audit note (pass / issues / fixes needed)
  → appended to: running SESSION_LOG.md

When all phases complete:
  → All session notes fed to Cursor Opus for full audit
  → Then to GPT for independent audit
  → Issues resolved → v1.0 tag
```

---

## Part B — Overall Phase Map

```
PHASE 0  Pre-work (manual, no Perplexity sessions)
  └── Freeze Foul Ward, create repos, scaffold folders

PHASE 1  Framework Complete  (~20 sessions, S01–S20)
  ├── Infra layer:     S01 Repos · S02 Docker · S17 CLI
  ├── Art pipeline:    S03 Fix bugs + Mesh2Motion · S04 studio.py + bootstrap
  ├── Audio pipeline:  S05 AudioCraft
  ├── Intelligence:    S06 RAG · S07 wolf-mcp v0 · S08 wolf-mcp complete
  ├── Core framework:  S09 Extraction · S10 Addons batch 1 · S11 Addons batch 2
  ├── Systems built:   S12 Map systems · S13 Economy+Spread · S14 Remaining systems
  ├── Testing:         S15 SimBot · S16 CI/CD
  └── Docs layer:      S18 Cursor skills · S19 MASTER_DOC template · S20 Integration test

PHASE 2  Demo Games  (~18 sessions, S21–S38)
  ├── Tower Defense family  (6 games, S21–S26)
  ├── Survival / Roguelite  (4 games, S27–S30)
  ├── Strategy / Management (5 games, S31–S35)
  └── Turn-based            (2 games, S36–S37, S38 shared)

PHASE 3  Ship to Community  (~5 sessions, S39–S43)
  └── Docs · CONTRIBUTING · Asset packs · Demo video · Final audit prep
```

**Total planned sessions: ~43**
**Critical path (non-parallelisable): ~32 sessions**
**Estimated wall-clock time at async pace: 10–14 weeks**

---

## Part C — Phase 0: Pre-Work (Manual, No Sessions)

Complete these steps **before** opening any Perplexity session.
Estimated time: 2–3 hours.

### C.1 — Freeze Foul Ward

```bash
# In your current Foul Ward repo root
git checkout main
git tag v0.1.0-freeze -m "Foul Ward freeze — WOLF Framework Phase 0"
git push origin v0.1.0-freeze
```

Then copy the entire Foul Ward project into the games repo:
```
wolf-games/
└── foul-ward/     ← full copy of Foul Ward at freeze tag
    └── FROZEN.md  ← add this file (content below)
```

**FROZEN.md content:**
```markdown
# Foul Ward — Frozen

This game is on hiatus while the WOLF Framework is under construction.
Do not modify any file in this folder.
Development resumes after wolf-framework v1.0 is tagged and shipped.
Last active commit: v0.1.0-freeze (2026-04-27)
Open bugs at freeze: FLUX black images (stage1), Arnulf 0 animations (stage3/4).
These are fixed inside the WOLF art pipeline, not here.
```

### C.2 — Create GitHub Repos

Create all five repos under the `wolf-framework` GitHub organization:
- `wolf` — Public, MIT, add README: "Meta-repo. Clone this for the full environment."
- `wolf-framework` — Public, MIT
- `wolf-mcp` — Public, MIT, check "Add .gitignore: Python"
- `wolf-games` — Public, MIT
- `wolf-docs` — Public, MIT

### C.3 — Scaffold the Core Folder Structure

```
wolf-framework/               ← github.com/wolf-framework/wolf-framework
│
├── README.md
├── SETUP.md                  ← Step-by-step install guide (written in S01)
├── LICENSE                   ← MIT
├── CONTRIBUTING.md           ← Stub (completed in S39)
├── .env.template             ← All config/secrets (written in S01)
├── docker-compose.yml        ← (written in S02)
│
├── framework/
│   ├── addons/               ← All direct-install Godot addons (S10, S11)
│   ├── templates/            ← SignalBus, Types, Resources (S09)
│   ├── skills/               ← .cursor/skills/ domain packs (S18)
│   └── scenes/               ← WOLFCharacterBase.tscn, shared scenes (S03)
│
├── config/
│   ├── rag/
│   │   ├── default.yaml      ← Master RAG config template (S06)
│   │   └── games/            ← Per-game RAG configs (populated per game)
│   └── mcp/
│       └── mcp.json.template ← Reference .cursor/mcp.json (S07)
│
├── pipelines/
│   ├── art/                  ← Gen3D stages 1–5 (S03, S04)
│   ├── audio/                ← AudioCraft stages 1–3 (S05)
│   └── rag/                  ← LangChain + ChromaDB server (S06)
│
├── docker/
│   ├── dev/
│   │   └── Dockerfile        ← wolf-dev image (S02)
│   └── art/
│       └── Dockerfile        ← wolf-art image (S02)
│
├── models/                   ← Downloaded weights — gitignored (~80 GB)
│   └── .gitkeep
│
├── assets/
│   ├── generated/            ← Output of art pipeline
│   └── cc0/                  ← Quaternius animations, Kenney packs
│
└── tools/
    ├── bootstrap.sh          ← Downloads models on first run (S04)
    ├── simbot/               ← SimBot scripts extracted from Foul Ward (S15)
    └── ci/                   ← Scripts mirrored in GitHub Actions (S16)

wolf-mcp/                     ← github.com/wolf-framework/wolf-mcp
├── pyproject.toml            ← pip package definition (S07)
├── wolf_mcp/
│   ├── __init__.py
│   ├── server.py             ← MCP server entry point
│   └── tools/                ← One file per tool group
└── README.md

wolf-games/                   ← github.com/wolf-framework/wolf-games
├── foul-ward/                ← Frozen (Phase 0)
└── .gitkeep                  ← Other games added in Phase 2

wolf-docs/                    ← github.com/wolf-framework/wolf-docs
└── .gitkeep                  ← Built in S39

wolf/ (meta-repo)             ← github.com/wolf-framework/wolf
├── README.md
├── SETUP.md                  ← Points to wolf-framework/SETUP.md
└── .gitmodules               ← Submodules to all four repos
```

### C.4 — Prepare SESSION_LOG.md

Create `~/SESSION_LOG.md` locally (not committed to any repo — this is your personal tracking file).

```markdown
# WOLF Framework — Session Log

| Session | Title | Date | Status | Notes |
|---------|-------|------|--------|-------|
| S01 | Repo init & folder structure | | ⏳ | |
| S02 | Docker skeleton | | ⏳ | |
...
```

### C.5 — Create .env.template

This file lives at `wolf-framework/.env.template`. It is the single source of truth
for all configuration. Every Docker service, every pipeline script, and the MCP server
reads from the `.env` file the user creates by copying this template.

```dotenv
# =============================================================================
# WOLF FRAMEWORK — Environment Configuration Template
# Copy this file to .env and fill in your values.
# Lines starting with # are comments. Never commit your .env file.
# =============================================================================

# --- Install path ---
WOLF_PATH=~/wolf-framework       # Absolute path to your wolf-framework clone

# --- Active game ---
WOLF_ACTIVE_GAME=foul-ward       # Folder name inside wolf-games/

# --- GPU / VRAM ---
GEN3D_VRAM_BUDGET_GB=20          # Safe VRAM limit before pipeline waits (RTX 4090 = 24 GB)

# --- Art pipeline model selection ---
FLUX_MODEL=flux1-schnell         # Options: flux1-schnell (Apache 2.0) | flux1-dev (non-commercial)
TRELLIS_MODEL=trellis2-4b        # Use 4B — avoids nvdiffrast commercial restriction
RIG_BACKEND=mesh2motion          # Options: mesh2motion (default, free) | mixamo (needs account)

# --- Audio pipeline ---
AUDIOCRAFT_SFX_MODEL=audiogen-medium
AUDIOCRAFT_MUSIC_MODEL=musicgen-medium

# --- RAG / LLM ---
RAG_EMBED_MODEL=nomic-embed-text
RAG_LLM_MODEL=qwen2.5:3b
OLLAMA_PORT=11434

# --- Services / ports ---
COMFYUI_PORT=8188
GDAI_MCP_PORT=3571
GODOT_MCP_PRO_PORT=6505          # Only needed if you own Godot MCP Pro ($15 one-time)

# --- Third-party MCP tokens (optional) ---
# GITHUB_PERSONAL_ACCESS_TOKEN=  # github.com → Settings → Developer settings → Tokens

# --- Rigging fallback (only needed if RIG_BACKEND=mixamo) ---
# MIXAMO_EMAIL=
# MIXAMO_PASSWORD=
```

---

## Part D — Phase 1 Sessions: S01–S07

Each session entry contains:
- **Goal** — one sentence
- **Perplexity context to load** — exact files/docs to attach or paste
- **Key questions** — what this session needs to answer
- **Cursor prompts to generate** — how many and their purpose
- **Deliverables** — exact files that must exist when the session is done
- **Unlocks** — which sessions cannot start until this one is complete

---

### S01 — Repo Initialization & Developer Experience

**Goal:** Every repo exists on GitHub with correct structure, LICENSE, README, and the SETUP.md
document that takes a brand-new user from zero to `docker-compose up` running.

**Perplexity context to load:**
- This workplan document (Chunk 1)
- `WOLF_Framework_Session_Summary.md` (for background)
- The confirmed `.env.template` from Phase 0

**Key questions for this session:**
1. What is the minimum SETUP.md structure that covers Windows (WSL2) and Linux (Ubuntu/Fedora)?
2. What should the `wolf` CLI `install` command do step by step?
3. What goes in the top-level README vs. SETUP.md?
4. Should the meta-repo `wolf` use git submodules or subtrees? (Recommendation: submodules —
   simpler to update independently.)

**Cursor prompts to generate (4 prompts):**
1. Write `wolf-framework/README.md` — project identity, one-paragraph description, badges
   (MIT license, Godot 4.4, Python 3.11), quick-start (3 commands), link to SETUP.md
2. Write `wolf-framework/SETUP.md` — full linear checklist: prerequisites (Docker Desktop /
   Docker Engine, Cursor, Git), clone step, copy .env.template, configure .env (which lines,
   where to get values), `docker-compose up wolf-dev`, verify RAG is running, first `wolf new
   my-game` scaffold
3. Write `wolf-mcp/README.md` and `wolf-mcp/pyproject.toml` — pip package skeleton,
   `wolf-framework` as package name, entry point `wolf_mcp.server:main`, MIT license,
   Python 3.11+, dependencies placeholder (Anthropic MCP SDK)
4. Write `wolf/README.md` and `wolf/.gitmodules` — meta-repo with submodule entries for
   all four child repos, brief explanation of the split

**Deliverables:**
- [ ] `wolf-framework/README.md`
- [ ] `wolf-framework/SETUP.md`
- [ ] `wolf-framework/LICENSE` (MIT text)
- [ ] `wolf-mcp/README.md`
- [ ] `wolf-mcp/pyproject.toml`
- [ ] `wolf/README.md`
- [ ] `wolf/.gitmodules`
- [ ] All five GitHub repos created and initialized

**Unlocks:** S02, S17 (can start in parallel after S01)

---

### S02 — Docker Skeleton

**Goal:** Both Docker containers build successfully, `docker-compose up` starts both services,
and a new user on a clean Ubuntu or Windows WSL2 machine can reach the dev container shell
and the art container shell.

**Perplexity context to load:**
- This workplan (Chunk 1)
- `wolf-framework/.env.template` (from Phase 0)
- MASTER_DOC §31.6 (Docker architecture spec, two containers)
- Session Summary §3.8 (Docker spec)

**Key questions for this session:**
1. What is the exact multi-stage Dockerfile for `wolf-dev` that keeps image size minimal?
2. How do we handle the Godot headless binary download (version-pinned, not baked into image)?
3. How do we make `wolf-art` work on both Linux native and Windows WSL2 with CUDA passthrough?
4. What health checks and named volumes should the compose file define?
5. How does the user specify a custom install path and have Docker volumes reflect it?

**Cursor prompts to generate (5 prompts):**
1. Write `docker/dev/Dockerfile` — `mcr.microsoft.com/dotnet/sdk:8.0-jammy` base,
   install Godot 4.4 headless binary (version-pinned URL), Python 3.11, pip install
   wolf-framework CLI, expose ports for GDAI MCP and Ollama, non-root user
2. Write `docker/art/Dockerfile` — `nvidia/cuda:12.4.0-cudnn-devel-ubuntu22.04` base,
   Python 3.11, pip install torch 2.4 cu124 pinned, ComfyUI git-pinned, TRELLIS.2 git-pinned,
   AudioCraft git-pinned, Mesh2Motion, Blender CLI; note: models NOT baked in (volume-mounted)
3. Write `docker-compose.yml` — services: wolf-dev, wolf-art; named volumes: wolf-models,
   wolf-assets, wolf-games; env_file: .env; health checks; GPU runtime conditional on env var
4. Write `tools/bootstrap.sh` — downloads all model weights into `wolf-models` volume on
   first run; checks for existing files before downloading; shows progress; ~80 GB total;
   downloads: FLUX.1-schnell, TRELLIS.2-4B, nomic-embed-text, qwen2.5:3b, Mesh2Motion weights,
   audiogen-medium, musicgen-medium
5. Write platform-compatibility notes into SETUP.md section "Windows Users (WSL2)" and
   "Linux Users" — Docker Desktop setup, NVIDIA Container Toolkit install command,
   WSL2 GPU passthrough confirmation step

**Deliverables:**
- [ ] `docker/dev/Dockerfile`
- [ ] `docker/art/Dockerfile`
- [ ] `docker-compose.yml`
- [ ] `tools/bootstrap.sh`
- [ ] Updated `SETUP.md` with platform-specific Docker sections
- [ ] Both images build without error on dev machine (verified)
- [ ] `docker-compose up` starts both services (verified)

**Unlocks:** S03, S04, S05, S06 (all pipeline work requires containers)

---

### S03 — Art Pipeline: Bug Fixes + Mesh2Motion Swap

**Goal:** The full Gen3D pipeline (FLUX.1-schnell → TRELLIS.2 → Mesh2Motion → Blender →
Godot drop) runs end-to-end without errors, proven by successfully generating one complete
rigged animated character (Arnulf, re-run from scratch inside wolf-framework).

**Perplexity context to load:**
- This workplan (Chunk 1)
- MASTER_DOC §22 (Art pipeline)
- Session Summary §3.4 (Gen3D pipeline, known bugs)
- Session Summary §3.4 known bugs: FLUX black images, Arnulf 0 animations
- Session Summary §8 item 7 (Mesh2Motion stage swap)

**Key questions for this session:**
1. What is the exact ComfyUI node wiring fix for `CLIPTextEncodeFlux` that causes black images?
   (The `turnaround_flux_noloras.json` positive prompt wiring is broken.)
2. What does Mesh2Motion's ComfyUI node API look like vs. the Mixamo Selenium fallback?
   How do we wire `stage3_rig_mesh2motion.py`?
3. What Blender CLI command correctly merges FBX animation clips from `animlibrary/` and
   exports a final GLB? (Stage 4 failure cause for Arnulf.)
4. How do we structure `pipelines/art/` so that `RIG_BACKEND` env var cleanly switches
   between Mesh2Motion (default) and Mixamo (fallback)?

**Cursor prompts to generate (6 prompts):**
1. Fix `pipelines/art/pipeline/stage1_turnaround.py` — correct CLIPTextEncodeFlux node
   wiring in `turnaround_flux_schnell.json` (Apache 2.0 safe version); verify positive
   prompt text reaches the FLUX conditioning node correctly; add a test that runs one
   generation and asserts output PNG is non-black
2. Write `pipelines/art/pipeline/stage3_rig_mesh2motion.py` — primary rigging backend;
   calls Mesh2Motion API (local or via ComfyUI node `jtydhr88/ComfyUI-mesh2motion`);
   accepts GLB input, outputs rigged GLB; include `RIGBACKEND=mesh2motion` env guard
3. Fix `pipelines/art/pipeline/stage3_rig.py` — update to call mesh2motion as primary,
   Mixamo Selenium as fallback (only if `RIG_BACKEND=mixamo` and credentials present),
   unrigged copy as last resort
4. Debug and fix `pipelines/art/pipeline/stage4_anim.py` — trace why Arnulf's FBX clips
   from `animlibrary/` produce 0 animations; fix Blender CLI GLB merge command;
   verify `ANIMNAMEMAP` entries match actual clip names in Quaternius animation library
5. Write `pipelines/art/pipeline/stage5_godot_drop.py` — copy final GLB to
   `wolf-framework/assets/generated/{faction}/{asset_type}/`; emit a `.tres` import
   resource for the GLB; register in `assets/generated/manifest.json`
6. Run full pipeline end-to-end on Arnulf: `python -m pipelines.art.foulwardgen arnulf
   undead humanoid` — verify output GLB has >0 animations, correct bone names for
   Quaternius retargeting, correct import in Godot

**Deliverables:**
- [ ] `pipelines/art/pipeline/stage1_turnaround.py` — fixed, no black images
- [ ] `pipelines/art/pipeline/stage3_rig_mesh2motion.py` — Mesh2Motion backend
- [ ] `pipelines/art/pipeline/stage3_rig.py` — updated with backend switching
- [ ] `pipelines/art/pipeline/stage4_anim.py` — fixed, Arnulf has animations
- [ ] `pipelines/art/pipeline/stage5_godot_drop.py` — drops to correct path
- [ ] `assets/generated/manifest.json` — Arnulf entry present
- [ ] Arnulf GLB in `assets/generated/undead/humanoid/arnulf.glb` with >0 animations
- [ ] End-to-end pipeline test passes (documented in session result report)

**Unlocks:** S04 (studio.py needs working stages), S09 character pool work

---

### S04 — Art Pipeline: studio.py Orchestrator + Character Pool

**Goal:** A single `wolf art generate <name> <faction> <type>` command produces a fully
animated, Godot-ready GLB for any character. The 8-character shared placeholder pool
is fully generated and placed in `assets/cc0/characters/`.

**Perplexity context to load:**
- This workplan (Chunk 1)
- Session Summary §3.4 (foulwardgen.py orchestrator spec)
- The 8-character pool list from earlier planning (Soldier, Orc/Brute, Archer, Mage,
  Worker, Plague Doctor, Creature/Monster, Flying Unit)

**Key questions for this session:**
1. What is the exact CLI interface for `wolf art generate`? Flags needed?
2. How does `studio.py` manage VRAM — polling ComfyUI status vs. fixed waits?
3. What prompts produce the best FLUX turnaround sheets for each of the 8 archetypes?
4. How do we produce a `WOLFCharacterBase.tscn` that all 16 demo games can use?

**Cursor prompts to generate (5 prompts):**
1. Write `pipelines/art/studio.py` — single-command orchestrator; accepts `name faction
   asset_type` args; manages VRAM polling between stages; calls stages 1–5 in sequence;
   logs progress to stdout; writes to `assets/generated/manifest.json`; this is what
   `wolf art generate` calls
2. Write FLUX prompt templates for all 8 character archetypes (stored in
   `pipelines/art/prompts/archetypes/`) — each is a JSON with positive/negative
   prompt, style tags, LoRA weights appropriate for FLUX.1-schnell; designed for
   turnaround sheets (front/back/side views on white background)
3. Run generation for all 8 characters: Soldier, Orc-Brute, Archer, Mage, Worker,
   Plague-Doctor, Creature-Monster, Flying-Unit — batch via studio.py; report any
   failures and fix
4. Write `framework/scenes/WOLFCharacterBase.tscn` — base Godot 4.4 scene with:
   AnimationTree pre-configured for idle/walk/attack/death clips; placeholder mesh
   node (swap this per game); exported `character_data: CharacterData` resource slot;
   signal `animation_finished(anim_name: String)` emitted via SignalBus
5. Write `framework/templates/CharacterData.tres` template — fields: display_name,
   faction_id, movement_speed, base_hp, mesh_path; matches WOLFCharacterBase.tscn

**Deliverables:**
- [ ] `pipelines/art/studio.py` — working, called by `wolf art generate`
- [ ] `pipelines/art/prompts/archetypes/` — 8 archetype JSON prompt files
- [ ] All 8 character GLBs in `assets/generated/` with animations
- [ ] `framework/scenes/WOLFCharacterBase.tscn`
- [ ] `framework/templates/CharacterData.tres`
- [ ] `assets/generated/manifest.json` — all 8 entries

**Unlocks:** S20 integration test, all Phase 2 demo games

---

### S05 — Audio Pipeline

**Goal:** `wolf audio sfx "goblin death scream" --duration 2.0` and
`wolf audio music "dark fortress ambient" --stems` both produce correct `.ogg` files
dropped into `assets/generated/audio/` with auto-generated `.tres` AudioStream resources.

**Perplexity context to load:**
- This workplan (Chunk 1)
- Session Summary §3.7 (audio pipeline spec: 4 stages)
- Session Summary §3.5 (Godot Mixing Desk integration)

**Key questions for this session:**
1. What is the exact AudioCraft API for `audiogen-medium` (SFX) and `musicgen-medium`
   (music with stems)? Any version-pinning issues with the installed version?
2. How does Godot 4.3's `AudioStreamInteractive` work for adaptive music?
3. What `.tres` format does Godot expect for an `AudioStreamOggVorbis` resource?
4. Should music stems be separate `.ogg` files or a single multi-track file?

**Cursor prompts to generate (5 prompts):**
1. Write `pipelines/audio/stage1_audiocraft_sfx.py` — AudioCraft `audiogen-medium`;
   accepts text prompt + duration; outputs 16-bit 44.1 kHz WAV to `tmp/audio/`
2. Write `pipelines/audio/stage1_audiocraft_music.py` — AudioCraft `musicgen-medium`;
   accepts text prompt; outputs separate stem WAVs (drums, bass, melody, other) via
   stem separation; outputs to `tmp/audio/`
3. Write `pipelines/audio/stage2_encode.py` — ffmpeg; converts WAV(s) to Vorbis .ogg
   at 44100 Hz 192kbps; handles both single-file SFX and multi-stem music
4. Write `pipelines/audio/stage3_godot_drop.py` — copies .ogg(s) to
   `assets/generated/audio/{category}/{name}/`; writes `.tres` file:
   `AudioStreamOggVorbis` resource with correct `resource_path`; for music stems,
   writes an `AudioStreamInteractive` resource wiring all stems as layers
5. Write `wolf audio` CLI subcommand (added to wolf-mcp CLI layer) — `wolf audio sfx
   <prompt> --duration` and `wolf audio music <prompt> --stems` — orchestrates
   stages 1–3; reports output paths

**Deliverables:**
- [ ] `pipelines/audio/stage1_audiocraft_sfx.py`
- [ ] `pipelines/audio/stage1_audiocraft_music.py`
- [ ] `pipelines/audio/stage2_encode.py`
- [ ] `pipelines/audio/stage3_godot_drop.py`
- [ ] `wolf audio sfx` command working (verified with one test SFX)
- [ ] `wolf audio music` command working (verified with one test music track, 4 stems)
- [ ] Example `.tres` files in `assets/generated/audio/`

**Unlocks:** S08 wolf-mcp audio tool, all Phase 2 demo games (audio placeholder assets)

---

### S06 — RAG System: 3-Corpus Architecture + Per-Game Config

**Goal:** The RAG service inside `wolf-dev` runs with the 3-corpus model
(`fw-framework` / `fw-balance` / `fw-design`), accepts per-game config files,
indexes a test game correctly, and responds accurately to queries via both the
MCP tool and the `wolf rag query` CLI command.

**Perplexity context to load:**
- This workplan (Chunk 1)
- Session Summary §3.3 (RAG system spec — current 4 collections, planned 3-corpus)
- The RAG config architecture from Part A of this document

**Key questions for this session:**
1. What is the exact LangGraph `StateGraph` + `SqliteSaver` wiring for conversation memory?
2. How do we cleanly migrate from the current 4-collection model (docs/code/resources/
   simbotlogs) to the 3-corpus model (fw-framework/fw-balance/fw-design) without
   breaking existing Foul Ward queries?
3. How does the `WOLF_ACTIVE_GAME` env var route queries to the correct per-game corpus?
4. What is the exact YAML schema for `config/rag/default.yaml`?

**Cursor prompts to generate (5 prompts):**
1. Write `config/rag/default.yaml` — master template with all options documented;
   includes: corpus definitions (name, description, source_dirs, file_patterns),
   embedding model, LLM model, hybrid search weights, chunk size, top-k,
   godot_docs_corpus: false by default
2. Write `config/rag/games/foul-ward.yaml` — maps Foul Ward's folder structure to
   the 3 corpora: fw-framework indexes `framework/`, fw-balance indexes
   `tools/simbot/output/`, fw-design indexes `docs/` + MASTER_DOC
3. Migrate `pipelines/rag/index.py` — update from 4-collection to 3-corpus model;
   reads active game config from `WOLF_ACTIVE_GAME`; hash-cached incremental indexing;
   accepts `--corpus` flag to rebuild only one corpus
4. Update `pipelines/rag/server.py` — MCP tools: `query_project_knowledge(question,
   corpus=all)` and `get_recent_simbot_summary(n_runs=3)`; route corpus param to
   correct ChromaDB collection; add `list_corpora()` tool
5. Write `wolf rag` CLI subcommands: `wolf rag index [--corpus name] [--force]`,
   `wolf rag query "<question>" [--corpus name]`, `wolf rag status` (shows last
   indexed timestamp and document count per corpus)

**Deliverables:**
- [ ] `config/rag/default.yaml` — fully documented master template
- [ ] `config/rag/games/foul-ward.yaml`
- [ ] `pipelines/rag/index.py` — 3-corpus model, per-game config
- [ ] `pipelines/rag/server.py` — updated MCP tools + `list_corpora()`
- [ ] `wolf rag` CLI commands (index, query, status)
- [ ] RAG running inside wolf-dev container (verified)
- [ ] Test: `wolf rag query "what signals does BuildPhaseManager emit?"` returns
      correct answer from fw-framework corpus (verified)

**Unlocks:** S07, S08 (wolf-mcp query_rag tool), S15 (SimBot→RAG auto-trigger)

---

### S07 — wolf-mcp Server v0 (Core 5 Tools)

**Goal:** `wolf-mcp` is pip-installable, connects to Cursor as an MCP server via stdio,
and exposes the 5 highest-value tools: `read_master_doc`, `add_unit`, `run_tests`,
`query_rag`, `validate_signals`.

**Perplexity context to load:**
- This workplan (Chunk 1)
- Session Summary §3.6 (Custom MCP spec — 11 tools)
- `wolf-mcp/pyproject.toml` (from S01)
- Anthropic MCP Python SDK documentation (paste relevant sections)

**Key questions for this session:**
1. What is the exact `pyproject.toml` configuration to make `pip install wolf-framework`
   install the CLI command `wolf`?
2. How does the Anthropic MCP Python SDK stdio transport work for Cursor integration?
3. What is the Cursor `.cursor/mcp.json` entry format for a pip-installed MCP server?
4. How should `add_unit` scaffold a new unit — what files does it create?

**Cursor prompts to generate (6 prompts):**
1. Finalize `wolf-mcp/pyproject.toml` — `wolf-framework` PyPI name; entry points:
   `wolf = wolf_mcp.cli:main` (CLI) and `wolf-mcp = wolf_mcp.server:main` (MCP server);
   dependencies: `anthropic-mcp>=1.0`, `click`, `pyyaml`, `langchain`, `chromadb`;
   Python 3.11+ requirement
2. Write `wolf_mcp/server.py` — Anthropic MCP SDK stdio server; imports and registers
   all tool modules; entry point `main()` function; tool list announced on startup
3. Write `wolf_mcp/tools/docs.py` — `read_master_doc(section: str) -> str` tool;
   reads `docs/MASTER_DOC.md` (per-game, pointed to by active game config),
   returns requested section by heading match; returns full TOC if section not found
4. Write `wolf_mcp/tools/scaffolders.py` — `add_unit(unit_id, role, faction,
   base_stats: dict) -> str` tool; creates `resources/units/{unit_id}.tres` from
   template; creates `scripts/units/{unit_id}.gd` stub with correct class name;
   emits SignalBus wire instructions in return message
5. Write `wolf_mcp/tools/testing.py` — `run_tests(suite="quick") -> str` tool;
   calls `tools/rungdunit.sh` (or parallel variant) inside wolf-dev container via
   subprocess; returns pass/fail summary + any error lines
6. Write `config/mcp/mcp.json.template` — reference `.cursor/mcp.json` with entries
   for wolf-mcp (pip-installed), godot-mcp-pro (optional, commented), gdai-mcp-godot
   (optional, commented), sequential-thinking, filesystem-workspace, github;
   every entry has a comment explaining what it does and whether it's required

**Deliverables:**
- [ ] `wolf-mcp/pyproject.toml` — finalized, pip-installable
- [ ] `wolf_mcp/server.py` — MCP server entry point
- [ ] `wolf_mcp/tools/docs.py` — `read_master_doc` tool
- [ ] `wolf_mcp/tools/scaffolders.py` — `add_unit` tool
- [ ] `wolf_mcp/tools/testing.py` — `run_tests` tool
- [ ] `config/mcp/mcp.json.template`
- [ ] `pip install -e wolf-mcp/` works (verified)
- [ ] Cursor connects to wolf-mcp via mcp.json and lists tools (verified)
- [ ] `read_master_doc("autoloads")` returns correct section from Foul Ward MASTER_DOC (verified)

**Unlocks:** S08 (remaining 6 tools), all Phase 2 sessions (need wolf-mcp for game scaffolding)

---

## Part E — Session Status Tracker (Phase 1, S01–S07)

| Session | Title | Depends on | Status |
|---------|-------|-----------|--------|
| Phase 0 | Pre-work (manual) | — | ⏳ Not started |
| S01 | Repo init & DX | Phase 0 | ⏳ |
| S02 | Docker skeleton | S01 | ⏳ |
| S03 | Art pipeline fixes + Mesh2Motion | S02 | ⏳ |
| S04 | studio.py + character pool | S03 | ⏳ |
| S05 | Audio pipeline | S02 | ⏳ |
| S06 | RAG 3-corpus + per-game config | S02 | ⏳ |
| S07 | wolf-mcp v0 (5 tools) | S01, S06 | ⏳ |

---

*End of Chunk 1. Chunk 2 covers Phase 1 sessions S08–S14 (MCP completion, framework
core extraction, all addon installations, and all build-from-scratch systems).*
