# WOLF Framework — Session Briefing Document
**For: New Perplexity Pro session + Cursor/Opus planning**
**Author:** Jerzy Wolf | **Date:** 2026-04-27 | **Project codename:** WOLF

---

## 1. Who & What

**Developer:** Jerzy Wolf (Kraków, PL). Solo indie dev. Full Cursor Pro + Perplexity Pro stack.
**Flagship game:** *Foul Ward* — real-time tower defense, Godot 4.4, GDScript + C#. Player IS the tower (TAUR-inspired), manually aims with mouse. 50-day main campaign. MVP already working; full game is lower priority until the framework is done.
**Main character:** Florence the Flower Keeper — female plague doctor / monster hunter. Intended as the shared protagonist across all framework games.
**Framework project name:** **WOLF** (working acronym candidates: *Workshop Of Living Fictions* / *Workflow Optimised LLM Foundation* / *Worldbuilding Offline LLM Framework*). Name confirmed available on GitHub/PyPI/npm — no collision in game-dev tooling space.

---

## 2. The Goal

Build a **public open-source Godot 4 + Cursor AI game development framework** that:

1. Lets any developer clone one repo, run `docker-compose up`, and have a fully working LLM-assisted game development environment locally.
2. Ships with working **MVP implementations of multiple game genres** to prove the framework works and serve as templates.
3. Includes a **fully automated, free, local AI art pipeline** (image → 3D mesh → rigged → animated → imported into Godot, single prompt per character).
4. Includes a **fully automated AI audio pipeline** (text prompt → SFX / music stems → .ogg → Godot resource).
5. Includes a **custom domain-specific MCP server** replacing the need for paid tools where possible.
6. Uses a **local RAG + Qwen** for token-cheap tasks (balance analysis, model generation, test running) so expensive LLM calls (Cursor/Claude) are reserved for creative/architectural decisions.
7. Eventually: docs site, community, outreach to Godot core team (Juan Linietsky, Rémi Verschelde — active on Mastodon/Bluesky).

**Motivation:** Self-promotion, community building, learning from contributors, credibility before monetisation.

---

## 3. What Already Exists in Foul Ward (Verified from MASTER_DOC)

### 3.1 Godot Architecture
- 15 autoloads with strict init order
- 77 typed signals in pure `SignalBus.gd` hub (no logic, no state)
- 665 GdUnit4 test cases, 8-way parallel runner (`tools/rungdunit-parallel.sh`)
- C# interop: `DamageCalculator.cs`, `SavePayload.cs`, `FoulWardTypes.cs` (enum mirror), `WaveCompositionHelper.cs`, `ProjectilePhysics.cs`
- Resource-driven data: all stats in `.tres` files, never hardcoded in GDScript
- Strict field name discipline (documented in Section 32 of MASTER_DOC)
- Full anti-patterns catalogue (Section 30, 15 patterns)
- `Types.gd` single source of truth for all enums

### 3.2 MCP Toolchain (`.cursor/mcp.json`)
| Server | Status | Role |
|---|---|---|
| `godot-mcp-pro` | Paid, outside repo (`../foulward-mcp-servers/`) | 163 tools, WebSocket to Godot editor, real-time scene tree, runtime inspection. By Youichi Uda (y1uda). $15 one-time. |
| `gdai-mcp-godot` | Paid, outside repo | Python bridge to editor HTTP API (port 3571). By 3ddelano. Free version on GitHub (MIT): `github.com/3ddelano/gdai-mcp-plugin-godot`. |
| `sequential-thinking` | Free | Step-by-step reasoning chain |
| `filesystem-workspace` | Free | Broader workspace file access |
| `github` | Free | GitHub API (requires PAT, never commit) |
| `foulward-rag` | Free, custom | `queryprojectknowledge`, `getrecentsimbotsummary` — queries local RAG |

### 3.3 RAG System (EXISTS, partially wired)
- **Stack:** LangChain + ChromaDB + LangGraph (`StateGraph` + `SqliteSaver` at `LLM/rag/memory.db`) + `nomic-embed-text` (768-dim, Apache-2.0, via Ollama) + `qwen2.5:3b` via `ChatOllama`
- **Retrieval:** Hybrid semantic (Chroma) + BM25, weighted merge
- **Collections (current 4):** `docs` (5 root .md files), `code` (.gd scripts), `resources` (.tres files), `simbotlogs` (logs .json/.csv)
- **Query interface:** MCP tool only — `queryprojectknowledge(question, domain=all)` and `getrecentsimbotsummary(n_runs=3)`
- **Update:** Manual `python LLM/index.py --force`, hash-cached incremental
- **Note:** Orphan `new-rag-mpc/rag_mcp_server.py` exists — safe to delete
- **Planned 3-corpus target:** `fw-framework` | `fw-balance` | `fw-design`
- **Missing:** `tools/simbot-index-to-rag.py` (auto-trigger after SimBot batch) — NOT YET IMPLEMENTED

### 3.4 Gen3D Art Pipeline (EXISTS, two known bugs)
All scripts at `tools/gen3d/`:

| Stage | Script | What it does |
|---|---|---|
| Orchestrator | `foulwardgen.py` | CLI: `python -m tools.gen3d.foulwardgen name faction assettype`. Manages VRAM waits. |
| 1 | `pipeline/stage1_turnaround.py` | FLUX.1-dev via ComfyUI (port 8188), 3 LoRAs, outputs reference PNGs |
| 2 | `pipeline/stage2_mesh.py` | TRELLIS.2-image-large-4B → decimated .glb. VRAM guard (min 12 GB free). |
| 3 | `pipeline/stage3_rig.py` | **UniRig first** (primary), Mixamo Selenium fallback, unrigged copy last resort |
| 4 | `pipeline/stage4_anim.py` | Blender CLI merges FBX clips from `animlibrary/` per `ANIMNAMEMAP` |
| 5 | `pipeline/stage5_godot_drop.py` | Copies final GLB to `art/generated/faction/asset/` |

**Known bugs:**
- `turnaround_flux_noloras.json` produces black images (FLUX positive prompt wiring vs `CLIPTextEncodeFlux` node)
- Arnulf GLB has 0 animations (Stage 3/4 hasn't successfully run on him)

**Mixamo migration plan (PLANNED):** New `stage3_rig_mesh2motion.py`, `RIGBACKEND=mesh2motion` env var, Mixamo stays as optional fallback for users with credentials.

### 3.5 SimBot Automated Testing (EXISTS, extensions PLANNED)
- **Core:** `scripts/simbot.gd` (class `SimBot`, resource-driven via `StrategyProfile.tres`)
- **Loadouts:** `scripts/simbot/simbot_loadouts.gd` — 3 presets: `balanced`, `summoner_heavy`, `artillery_air`
- **CLI flags:** `--autotest`, `--simbot-profile-id`, `--simbot-runs N`, `--simbot-seed S`, `--simbot-balance-sweep`
- **Multi-instance swarm:** `tools/simbot_swarm.py` — N parallel headless Godot processes, per-process `XDG_DATA_HOME` isolation, `GODOT_DISABLE_GDAI_MCP=1` per child, aggregate CSV
- **Balance report:** `tools/simbot_balance_report.py` — reads `building_summary.csv`, tags OVERTUNED/UNDERTUNED/BASELINE/UNTESTED
- **Economy optimiser loop (PLANNED):** Rule-based (no LLM), bounded by `balance_guardrails.tres`, converges when all buildings within 25% of median damage-per-gold for 2 consecutive batches, runs on `git checkout -b balance/auto-timestamp`
- **NOT YET IMPLEMENTED:** MCTS dynamic-strategy tester, SimBot→RAG auto-trigger, CI/CD

### 3.6 Custom Foul Ward MCP (SPECCED, not built)
11 tools planned at `tools/foulward-mcp/`:

| # | Tool | Wraps |
|---|---|---|
| 1 | `add_unit(unit_id, role, faction, base_stats)` | `scaffolders/unit.py` |
| 2 | `add_building(building_id, category, slot_size, gold_cost, damage)` | scaffolder |
| 3 | `run_tests(suite, quick/unit/parallel/sequential)` | `tools/rungdunit.sh` |
| 4 | `query_rag(question, corpus=framework/balance/design)` | LangChain in-process |
| 5 | `read_master_doc(section)` | `docs/FOUL_WARD_MASTER_DOC.md` |
| 6 | `validate_signals()` | `validators/signal_check.py` |
| 7 | `get_balance_report(latest=True)` | `tools/output/simbot_balance_report.md` |
| 8 | `run_simbot(profile_id, runs=10, seed, swarm=False)` | `tools/simbot_swarm.py` |
| 9 | `import_3d_asset(glb_path, category, faction, name)` | godot-mcp-pro proxied |
| 10 | `generate_character(name, faction, asset_type, rig_backend)` | `tools/studio.py` (PLANNED) |
| 11 | `generate_sfx(prompt, category, duration=2.0)` | audio Stage 1 (PLANNED) |

Transport: stdio (Cursor compatible). Language: Python + Anthropic MCP SDK (MIT).

### 3.7 Audio Pipeline (SPECCED, not built)
| Stage | Script | Output |
|---|---|---|
| SFX | `audio/stage1_audiocraft_sfx.py` | AudioCraft `audiogen-medium` → 16-bit 44.1 kHz .wav |
| Music | `audio/stage1_audiocraft_music.py` | AudioCraft `musicgen-medium` → separate stem .wavs |
| Encode | `audio/stage2_encode.py` | ffmpeg → Vorbis .ogg |
| Drop | `audio/stage3_godot_drop.py` | Copies to `art/audio/generated/` + emits `.tres` AudioStream |

Runtime adaptive music: Godot 4.3 native `AudioStreamInteractive` + Godot Mixing Desk (kyzfrintin, MIT, `github.com/kyzfrintin/Godot-Mixing-Desk`).

### 3.8 Docker Architecture (SPECCED, not built)

**`foulward-dev`:**
- Base: `mcr.microsoft.com/dotnet/sdk:8.0-jammy` + Godot 4.4 headless binary
- Volumes: `.:/workspace:rw`, `.cache/godot:rw`, `LLM:/llm:rw`
- Commands: `foulward-dev build`, `foulward-dev test`, `foulward-dev simbot`, `foulward-dev rag-index`

**`foulward-art`:**
- Base: `nvidia/cuda:12.4.0-cudnn-devel-ubuntu22.04` + Python 3.11
- GPU: `runtime: nvidia`, `NVIDIA_VISIBLE_DEVICES=all`
- Pinned: `transformers==4.56.0`, `torch 2.4 CUDA 12.4`, ComfyUI git-pinned, TRELLIS.2 git-pinned, AudioCraft git-pinned
- Models: Downloaded at first run via `art-bootstrap` into `foulward-models` volume (~80 GB). Never baked into image.
- Commands: `art-comfyui`, `art-gen name faction assettype --rig-backend`, `art-audio name category --type sfx/music`, `art-bootstrap`

**Key `.env` variables:** `GEN3D_VRAM_BUDGET_GB`, `FLUX_MODEL`, `TRELLIS_MODEL`, `AUDIOCRAFT_SFX_MODEL`, `RAG_EMBED_MODEL`, `RAG_LLM_MODEL`, `RIG_BACKEND`, `COMFYUI_PORT`, `OLLAMA_PORT`, `GDAI_MCP_PORT`, `GODOT_MCP_PRO_PORT`

---

## 4. The WOLF Framework — What Gets Extracted

### 4.1 Architecture Layer (strip from Foul Ward, generalise)
- SignalBus template (~20 canonical strategy-game signals)
- FSM pattern (GDQuest node-based, MIT — `gdquest.com/tutorial/godot/design-patterns/finite-state-machine/`)
- `MASTER_DOC_TEMPLATE.md` with `EXISTS IN CODE` / `PLANNED` schema
- AGENTS.md standing orders format
- `.cursor/skills/` domain skill system (5 starter skills: signal-bus, add-new-unit, add-new-building, wave-system, balance-testing)
- `Types.gd` + `GameTypes.cs` mirror template
- Resource-driven data templates: `UnitData.tres`, `BuildingData.tres`, `WaveData.tres`
- C# interop pattern
- SaveManager with versioned `SavePayload.cs`

### 4.2 Direct-Install Addons (all MIT unless noted)
| Addon | Author | License | Purpose |
|---|---|---|---|
| GDQuest Steering AI Framework | Razoric, Nathan Lovato (GDQuest) | MIT | Unit movement, seek/flee/arrive/pursue/wander |
| Beehave | bitbrain (Miguel Fernández Arce) | MIT | Behavior trees with in-editor debugger |
| Godot Mod Loader | KANA, Darkly77, Ste, otDan | CC0 | Mod system (used in Brotato, Dome Keeper) |
| Dialogue Manager | Nathan Hoad | MIT | Stateless branching dialogue |
| Card Framework | chun92 (chunuiyu) | MIT | Full card/deck system, Kenney CC0 art bundled |
| Quest System | shomykohai (Shomy) | MIT | GdUnit4-tested, CSV localisation |
| Phantom Camera | Ramokz | MIT | Cinemachine equivalent, 2D+3D |
| GodotSteam GDExtension | Gramps (GP Garcia, CoaguCo Industries) | MIT | Steam SDK wrapper |
| GLoot Inventory | Peter Kiš | MIT | Slot/grid/weight inventory |
| Godot Gameplay Systems | OctoD | MIT | Full GAS (attributes, abilities, buffs/debuffs) |
| ModiBuff | Chillu1 | MPL-2.0 | High-perf buff system (use freely; mods to lib = open) |
| Terrain3D | Cory Petkovsek (Tokisan Games) | MIT | C++ clipmap terrain for 3D |
| Sky3D | Cory Petkovsek (Tokisan Games) | MIT | Atmospheric day/night, pairs with Terrain3D |
| Gaea | BenjaTK | MIT | Graph-based procedural generation, TileMap/GridMap |
| Sound Manager | Nathan Hoad | MIT | Pooled audio, crossfades, same author as Dialogue Manager |
| Rollback Netcode | David Snopek (Snopek Games) | MIT | Deterministic multiplayer |
| Mini Map | sumri | MIT | Drop-in minimap node |
| Fluid HTN | Pål Trefall (C#); fnaith (Godot port) | MIT | Hierarchical Task Network AI planner |
| GdUnit4 | Mike Schulze | MIT | Test framework already in Foul Ward |
| Coding-Solo godot-mcp | Coding-Solo | MIT | Free Godot MCP alternative |

### 4.3 Adapt-from-Recipe (not direct install)
| System | Source | Author | Notes |
|---|---|---|---|
| HexGrid math | redblobgames.com | Amit Patel | Cube coords, axial, ring algorithms. Credit in README. |
| RTS Camera | GitHub Gists | artokun (3D), Tam/monxa (2D) | Merge into `RTSCamera.gd` + `RTSCamera3D.gd` |
| Multi-unit select | kidscancode.org | Chris Bradfield | MIT-compatible recipe |
| Unit formations | `rtsSelectionMoveDemo` | LeProfesseurStagiaire | MIT, includes square/circle/triangle shapes + pathfinding |
| Fog of War (2D/small) | godot-open-rts | Pawel Lampe | MIT, 2-channel texture, port directly |
| Fog of War (GPU) | Compute Shader Plus | DevPoodle | MIT, GLSL compute for large maps |
| Province maps | OpenGS Map Tool + Province Map Builder | Thomas Holtvedt + OskarUnn | Pipeline: OpenGS generates → Province Map Builder handles runtime |
| Autobattler base | `godot_autobattler_course` | Adam Gulácsi (guladam) | MIT-compatible educational project |

### 4.4 Build from Scratch (algorithm references only)
| System | Algorithm origin | GPL warning |
|---|---|---|
| Flow economy (TA model) | Cavedog *Total Annihilation* 1997; BAR (GPL-2.0); Zero-K (GPL-2.0) | ⚠️ Cannot copy code, implement from algorithm |
| Contagion/SIR spread | Kermack & McKendrick 1927 (public domain math) | None |
| Faction/relationship system | Community pattern, FactionData Resources | None |
| Tech Tree UI | Godot native `GraphEdit` + `GraphNode` | None |
| Replay recorder + GIF export | Community frame-counter pattern | None |

### 4.5 ⚠️ GPL-Contaminated Reference Engines (study only, zero code copying)
- **Beyond All Reason** (GPL-2.0) — flow economy, large-scale unit simulation
- **Zero-K** (GPL-2.0) — flat tech tree, construction AI
- **OpenRA** (GPL-3.0) — FOW layers, multi-unit selection, traits/components
- **openage** (GPL-2.0) — Age of Empires mechanics

---

## 5. Game Genres — MVP Targets

Each MVP = one map, one faction, 5 units, 3 buildings, one win condition. Mechanically complete, aesthetically usable via shared CC0 character pool.

**Shared asset pool:** Knights, orcs, archers, plague doctor, mage. Generated via WOLF art pipeline → Mesh2Motion rigged → Quaternius CC0 animation library. All CC0/MIT output.

| Genre | Key mechanic differentiator | Primary new systems needed |
|---|---|---|
| Tower Defense (Foul Ward) | Player IS the tower, manual aim | Already exists — needs completion |
| RTS | Unit production, free movement, base building | godot-open-rts reference (Pawel Lampe, MIT), Steering AI, formations |
| Card Roguelite | Run-based deck building, procedural rooms | Card Framework (chun92), Gaea procedural, Beehave |
| Grand Strategy | Province ownership, diplomacy, long-term campaigns | Province Map Builder, Faction System, TimeTick calendar |
| Autobattler | Drag-place units, watch them fight | guladam autobattler reference, Godot GAS, bench/board UI |
| Dungeon Keeper–style | Underground digging, creature management, base invasion | Procedural voxel terrain, HTN AI planner, flow economy |

---

## 6. File Hosting Strategy (Zero Cost)

| Asset type | Host | Why |
|---|---|---|
| Framework code | GitHub (monorepo) | Free, versioned |
| Docker images | GitHub Container Registry (GHCR) | Free for public images, no size ceiling |
| Model weights | HuggingFace (existing repos) | Developer doesn't host — `art-bootstrap` downloads |
| Pre-generated asset packs (GLB, audio) | HuggingFace Hub Dataset repo | Free public, Git LFS, CDN, up to ~300 GB |
| Game releases | itch.io | Free, up to 1 GB/file, huge indie audience |
| Raw source backup | pCloud 500 GB (already paid) | Personal backup only, not public distribution |

---

## 7. AI Tooling Tiers

### Free Tier (fully local, zero ongoing cost)
- **Code agent:** Cline (Apache-2.0, VSCode) + Ollama (local Qwen2.5:3b or DeepSeek)
- **Godot MCP:** Coding-Solo/godot-mcp (MIT, free) + 3ddelano/gdai-mcp-plugin-godot (MIT, free GitHub version)
- **Image gen:** FLUX.1 [schnell] (Apache-2.0) via ComfyUI
- **3D gen:** TRELLIS.2 (MIT, Microsoft) — 12-16 GB VRAM locally, or free via trellis2.com web
- **Rigging/animation:** Mesh2Motion (MIT, `mesh2motion.org`) — Mixamo alternative, humanoid + quadruped + avian, CC0 Quaternius animation library bundled. Also has a ComfyUI node (`jtydhr88/ComfyUI-mesh2motion`).
- **Audio:** AudioCraft by Meta (MIT) — MusicGen (music) + AudioGen (SFX), fully local
- **LLM for RAG/tests:** Ollama + Qwen2.5:3b, local, no API cost
- **Caveat:** Local models significantly weaker at MCP tool-calling than Claude 3.5/3.7

### Recommended Tier
- **Code agent:** Cursor Pro ($20/month)
- **Godot MCP:** Godot MCP Pro by Youichi Uda / y1uda ($15 one-time) — 163 tools, real-time runtime inspection
- **LLM:** Claude 3.7 Sonnet (daily work) + Claude Opus 4.5 (planning sessions)

### Model Licensing Notes
- **FLUX.1 [dev]:** Non-commercial only. Use **schnell** (Apache 2.0) for anything commercial.
- **TRELLIS.2 code:** MIT. Output assets: yours commercially. Rendering submodules (`nvdiffrast`) have commercial restrictions — use TRELLIS.2 4B on HuggingFace which is clean.
- **HuggingFace model weights:** Never bake into Docker image. Always volume-mount + first-run download script.

---

## 8. NOT YET IMPLEMENTED (Confirmed Gaps)

1. `tools/studio.py` — single-command orchestrator for full art pipeline
2. `tools/foulward-mcp/` — custom MCP server (11 tools specced in MASTER_DOC §31.7)
3. `tools/simbot-index-to-rag.py` — SimBot→RAG auto-trigger after batch
4. MCTS dynamic-strategy AI tester (§31.5.3)
5. `resources/balance_guardrails.tres` — economy optimiser bounds
6. CI/CD — no `.github/`, no workflow files
7. Mesh2Motion stage swap (§31.3.3) — `stage3_rig_mesh2motion.py` not yet written
8. Audio pipeline scripts (§31.3.5) — 4 stages specced, none written
9. Docker `foulward-dev` and `foulward-art` — specced in §31.6, not built
10. Two open art bugs: FLUX black images, Arnulf 0 animations

---

## 9. Build Order (Topological)

```
Phase 1 — Foundation (3-4 weeks)
├── Fix two open art bugs (FLUX black images, Arnulf animations)
├── Docker skeleton (dev + art containers, volume mounts, .env template)
├── Mesh2Motion stage swap (replace Mixamo default in stage3)
├── studio.py orchestrator (single-command art pipeline)
├── Custom MCP v0 (5 tools: read_master_doc, add_unit, run_tests, query_rag, validate_signals)
└── SimBot→RAG auto-trigger (simbot-index-to-rag.py)

Phase 2 — Audio + Extended MCP (2-3 weeks)
├── AudioCraft pipeline (4 stages, sfx + music stems)
├── Godot Mixing Desk integration + AudioStreamInteractive wiring
├── Extend custom MCP to full 11 tools
└── RAG 3-corpus migration (fw-framework / fw-balance / fw-design)

Phase 3 — Framework Extraction (4-6 weeks)
├── Install all direct-install addons (Beehave, GAS, Steering AI, Card Framework, etc.)
├── Adapt HexGrid, RTS Camera, multi-unit select, FOW recipes
├── Build Tech Tree UI (GraphEdit), Faction System, Replay Recorder
├── MCTS dynamic tester
├── CI/CD (GdUnit4 + SimBot on every PR via GitHub Actions)
└── Economy optimiser loop + balance_guardrails.tres

Phase 4 — MVP Games (1-3 days each with full framework)
├── Tower Defense (Foul Ward lite — most done)
├── RTS (godot-open-rts fork + Steering AI + formations)
├── Card Roguelite (Card Framework + Gaea)
├── Grand Strategy (Province Map Builder + Faction System)
├── Autobattler (guladam base + GAS)
└── Dungeon Keeper–style (procedural voxel + HTN)

Phase 5 — Public Launch
├── Docs site (Astro Starlight, ~1 day)
├── HuggingFace Dataset for asset packs
├── GHCR Docker image publishing
├── 90-second demo video (replay system → FFMPEG → GIF/video)
└── Godot community outreach (Mastodon: Juan Linietsky, Rémi Verschelde)
```

---

## 10. Key People & Credits (for CREDITS.md and README)

| Person / Org | Contribution | License |
|---|---|---|
| Nathan Lovato / GDQuest | SignalBus pattern, FSM pattern, Steering AI framework, Sound Manager | MIT |
| Razoric (GDQuest) | Steering AI Framework co-author | MIT |
| bitbrain (Miguel Fernández Arce) | Beehave behavior trees | MIT |
| KANA, Darkly77, Ste, otDan | Godot Mod Loader | CC0 |
| Nathan Hoad | Dialogue Manager, Sound Manager | MIT |
| chun92 (chunuiyu) | Card Framework | MIT |
| shomykohai (Shomy) | Quest System | MIT |
| Ramokz | Phantom Camera | MIT |
| Gramps (GP Garcia, CoaguCo Industries) | GodotSteam | MIT |
| Peter Kiš | GLoot Inventory | MIT |
| OctoD | Godot Gameplay Systems (GAS) | MIT |
| Chillu1 | ModiBuff | MPL-2.0 |
| Cory Petkovsek (Tokisan Games) | Terrain3D + Sky3D | MIT |
| BenjaTK | Gaea procedural generation | MIT |
| Pawel Lampe (Lampe Games) | godot-open-rts (MIT RTS template) | MIT |
| David Snopek (Snopek Games) | Rollback Netcode | MIT |
| Youichi Uda (y1uda) | Godot MCP Pro ($15 one-time) | Proprietary |
| Pål Trefall | Fluid HTN (C# original) | MIT |
| fnaith | Fluid HTN Godot port | MIT |
| Amit Patel (Red Blob Games) | HexGrid mathematics reference | Permissive |
| Adam Gulácsi (guladam) | Autobattler course project | MIT-compatible |
| Chris Bradfield (KidsCanCode) | Pathfinding + multi-unit select recipes | MIT-compatible |
| LeProfesseurStagiaire | RTS selection + formation demo | MIT |
| DevPoodle | Compute Shader Plus (GPU FOW) | MIT |
| Thomas Holtvedt | OpenGS Map Tool (province generation) | Free/open |
| OskarUnn | Province Map Builder | MIT |
| eisclimber | DynamicDayNightCycles | MIT |
| shoyguer | TimeTick calendar system | MIT |
| Mike Schulze | GdUnit4 test framework | MIT |
| sumri | Mini Map addon | MIT |
| kyzfrintin | Godot Mixing Desk | MIT |
| R3X-G1L6AME5H | Godot Dynamic Music Framework | MIT |
| Meta AI | AudioCraft (MusicGen + AudioGen) | MIT |
| Microsoft | TRELLIS.2 3D generation | MIT (see rendering caveat) |
| Black Forest Labs | FLUX.1 [schnell] | Apache 2.0 |
| Mesh2Motion team | Mesh2Motion auto-rig/animate | MIT |
| Kenney Vleugels (Kenney.nl) | 60,000+ CC0 game assets | CC0 |
| Quaternius | CC0 animation library (bundled in Mesh2Motion) | CC0 |
| Anthropic | MCP specification + Python SDK | MIT |

---

## 11. What to Plan in the New Session

The following have NOT been decided and need planning:

1. **Monorepo structure** — folder layout for games/ framework/ mcp/ docker/ assets/
2. **WOLF framework extraction scope** — exact list of what's Foul Ward–specific vs. generic
3. **MVP game mechanical designs** — one-paragraph brief per genre (the *what* not the *how*)
4. **Docs site structure** — pages, sections, getting-started flow
5. **Community contribution model** — issue templates, PR workflow, skill submission format
6. **Licensing decision** — MIT for framework? Source-available for games? Affects bundled assets.
7. **Phase 1 Cursor/Opus prompt** — the actual implementation kickoff prompt

