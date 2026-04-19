# SKILL: gen3d — Automatic 3D asset generation (local pipeline)

## Stage 1 Environment (Resolved — do not change)

- ComfyUI: v0.19.3 at http://127.0.0.1:8188
- Start command: `nohup $FOULWARD_PYTHON ~/ComfyUI/main.py --listen 127.0.0.1 --port 8188 > /tmp/comfyui.log 2>&1 &`
- `FOULWARD_PYTHON`: `/home/jerzy-wolf/miniconda3/envs/trellis2/bin/python3`
- UNET: `~/ComfyUI/models/unet/flux1-dev.safetensors` (23.80GB, `weight_dtype`: default)
- CLIP: `~/ComfyUI/models/clip/clip_l.safetensors` (~246MB)
- T5: `~/ComfyUI/models/clip/t5xxl_fp8_e4m3fn.safetensors` (~4.6GB)
- VAE: `~/ComfyUI/models/vae/flux_ae.safetensors`
- LoRA strengths validated: turnaround=0.4, baroque=0.5, velvet=0.4
- Minimal test baseline: mean RGB (228.6, 201.9, 197.3), 0.0% black

Invoke gen3d with: `$FOULWARD_PYTHON tools/gen3d/foulward_gen.py "Unit Name" faction asset_type`

## Previously broken (fixed — do not revert)

- Old `flux_t5_1` / `flux_t5_2` were sharded HF diffusers T5 (only shard 1 of 2 loaded) → "Long clip missing" → NaN → black PNG. Fixed by downloading `comfyanonymous/flux_text_encoders` `t5xxl_fp8_e4m3fn.safetensors`.
- Old UNETLoader pointed at `diffusion_pytorch_model-00001-of-00003.safetensors` (shard 1 of 3) → NaN. Fixed by downloading single-file `flux1-dev.safetensors`.
- ComfyUI must be started with **trellis2** conda env Python, not base miniconda Python 3.13.

## Purpose

Load this skill when generating **placeholder or batch 3D assets** for Foul Ward: enemies, allies, bosses, buildings. The Python orchestrator lives in **`tools/gen3d/`** in this repo; it drives local tools on the developer machine (ComfyUI + FLUX.1 dev, TRELLIS.2, Blender, optional Mixamo automation). Output is **`.glb`** under `res://art/generated/...` with the same **flat naming** as existing placeholders (`rigged_visual_wiring.gd`, `FUTURE_3D_MODELS_PLAN.md`).

## When to use

- "Create a 3D model for [unit]" / "Generate a GLB for [enemy/building]"
- "Run the gen3d pipeline" / "Batch placeholder meshes"
- "Add a new character to Foul Ward and generate its model"
- Anything involving **local** ComfyUI → mesh → rig → animation → Godot drop

## Canonical paths (this workspace)

| Item | Absolute path |
|------|-----------------|
| **Workplan (install steps)** | `/home/jerzy-wolf/workspace/foul-ward/FoulWard/docs/gen3d_workplan.md` |
| **Scripts (in-repo)** | `/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/` |
| **Per-unit description bank** | `/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/pipeline/unit_descriptions.py` |
| **Character manifest (source of descriptions)** | `/home/jerzy-wolf/.cursor/plans/characters.md` |
| **Godot project** | `/home/jerzy-wolf/workspace/foul-ward/FoulWard` |
| **Godot path resolver (per `entity_id`)** | `scripts/art/rigged_visual_wiring.gd` |
| **Roster doc** | `FUTURE_3D_MODELS_PLAN.md` |

## Pipeline (5 stages)

1. **2D reference** — ComfyUI + **FLUX.1 [dev]** + three CivitAI LoRAs.  
   Prompt is built from: `description (from unit_descriptions.py or unit_name)` + `FACTION_ANCHORS[faction]` + `STYLE_FOOTER` (LoRA triggers baked in).
2. **Image → mesh** — TRELLIS.2 (`conda` env `trellis2`).
3. **Rig** — Blender GLB↔FBX; humanoids via **Mixamo** automation when `MIXAMO_EMAIL`/`MIXAMO_PASSWORD` env vars are set; buildings skip rig; falls back to unrigged GLB silently if Mixamo fails.
4. **Animation** — Blender merges FBX clips from `anim_library/`; see `ANIM_NAME_MAP` in `stage4_anim.py`.
5. **Drop** — Copy `{slug}.glb` to `art/generated/{enemies|allies|buildings|bosses}/`.

## How to run (single unit)

```bash
cd /home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d
# Optional: ~/.foulward_secrets with export MIXAMO_* and export HF_TOKEN=hf_... (see docs/gen3d_workplan.md Part 2)
python foulward_gen.py "UNIT NAME" FACTION ASSET_TYPE
```

`foulward_gen.py` loads **`~/.foulward_secrets`** automatically (same as `launch.sh`); **`HF_TOKEN`** is forwarded into the TRELLIS `conda run` step for Hugging Face downloads (DINOv3 + other weights). **Default `FOULWARD_TRELLIS_PUBLIC_REMBG=1`** rewrites the cached TRELLIS `pipeline.json` to use public **`ZhengPeng7/BiRefNet`** instead of gated **`briaai/RMBG-2.0`** (see `tools/gen3d/workflows/README_COMFYUI.md`).

**Without TRELLIS (skip mesh gen):** set **`FOULWARD_GEN3D_STAGE2_MODE=input_file`** and **`FOULWARD_GEN3D_STAGE2_INPUT_GLB=/path/to/file.glb`**, or **`FOULWARD_GEN3D_STAGE2_MODE=placeholder`** for a box mesh — see `tools/gen3d/workflows/README_COMFYUI.md` (Stage 2 bypass).

- **FACTION:** `orc_raiders` | `plague_cult` | `allies` | `buildings`
- **ASSET_TYPE:** `enemy` | `ally` | `building` | `boss`
- **UNIT NAME:** matches a slug in `unit_descriptions.py` (preferred) or any free text. Lowercase + `_` for spaces.

Examples (slugs already in `unit_descriptions.py`):

```bash
python foulward_gen.py "arnulf" allies ally
python foulward_gen.py "florence" allies ally
python foulward_gen.py "sybil" allies ally
python foulward_gen.py "orc_grunt" orc_raiders enemy
python foulward_gen.py "herald_of_worms" plague_cult enemy
python foulward_gen.py "arrow_tower" buildings building
```

Start **ComfyUI** first (`~/ComfyUI`, port **8188**). After downloading **FLUX.1-dev** into `~/ComfyUI/models/checkpoints/flux1-dev/`, run **`tools/gen3d/setup_comfyui_flux_symlinks.sh`** once so UNET/CLIP/VAE paths resolve (see `tools/gen3d/workflows/README_COMFYUI.md`). **Default** `turnaround_flux.json` includes **three LoRAs** under `~/ComfyUI/models/loras/` with fixed filenames (`turnaround_sheet`, `baroque_fantasy_realism`, `velvet_mythic_flux`). **Source links, API URLs, optional Hugging Face mirror for LoRA 1, and `~/Downloads` copy examples:** `tools/gen3d/workflows/README_COMFYUI.md`. **`STYLE_FOOTER` in `foulward_gen.py` must stay aligned with those LoRAs’ trigger words.** If LoRAs are not installed yet, run with `export FOULWARD_GEN3D_WORKFLOW=turnaround_flux_no_loras.json` or use that file as `turnaround_flux.json`.

## Adding a new character — exact step-by-step

### Step 1 — Decide the slug, faction, and asset type

Pick a **lowercase slug with underscores**: e.g. `frost_wolf`. Pick a `FACTION` and `ASSET_TYPE` from the lists above. Bosses can use `enemy` (drops to `art/generated/enemies/`) or `boss` (drops to `art/generated/bosses/`); match what `scripts/art/rigged_visual_wiring.gd` expects for that ID.

### Step 2 — Write the description and add it to the bank

Edit `/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/pipeline/unit_descriptions.py` and add an entry following the existing pattern (one paragraph, T-pose, silhouette/proportions, palette, weapon, telling detail). Keep `FACTION_ANCHORS` alone — it auto-appends. Do not edit `STYLE_FOOTER` here (global LoRA triggers in `foulward_gen.py`).

```python
UNIT_DESCRIPTIONS["frost_wolf"] = (
    "Frost wolf beast unit, 1.4m at shoulder, ..."
)
```

### Step 3 — Make sure the GLB will be found by the game

If the new unit needs to render in-game, add the `entity_id → res://art/generated/.../<slug>.glb` mapping in `scripts/art/rigged_visual_wiring.gd` and (where relevant) the corresponding `*.tres` in `res://resources/{enemy_data,ally_data,building_data,boss_data}/`. See `add-new-entity` skill for the full data-side checklist (`SignalBus`, `Types`, indexes).

### Step 4 — Run the pipeline

```bash
cd /home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d
python foulward_gen.py "frost_wolf" plague_cult enemy
```

Output lands at `FoulWard/art/generated/enemies/frost_wolf.glb`. The Godot editor will reimport on next focus / `Project → Reload Current Project`.

### Step 5 — Verify

- `ls -lh /home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/enemies/frost_wolf.glb`
- Open the scene that uses it (or the .glb directly) in Godot and check `Skeleton3D` + `AnimationPlayer` clip names against `ANIM_NAME_MAP` if it's a humanoid.
- Update `FUTURE_3D_MODELS_PLAN.md` roster table.

## How to prompt Cursor's agent to generate a new character

Paste a prompt of this shape into chat (Cursor will read this skill automatically when it sees terms like "3D model", "gen3d", "GLB"):

```
Generate a new Foul Ward 3D placeholder for a unit named "<SLUG>".
Faction: <orc_raiders|plague_cult|allies|buildings>
Asset type: <enemy|ally|building|boss>
Description (paste in or describe):
<one paragraph: silhouette, height, proportions, palette, weapon,
T-pose, one telling detail>

Steps:
1. Add an entry to /home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/pipeline/unit_descriptions.py
   following the existing format.
2. If this unit needs to render in-game, also add the GLB path mapping in
   FoulWard/scripts/art/rigged_visual_wiring.gd and the matching *.tres under
   FoulWard/resources/<category>_data/. Use the add-new-entity skill.
3. Confirm ComfyUI is up at http://127.0.0.1:8188; if not, start it and wait.
4. Run:
     cd /home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d
     python foulward_gen.py "<SLUG>" <FACTION> <ASSET_TYPE>
5. Show me the resulting paths under FoulWard/art/generated/.
```

Minimal prompt for an existing slug already in `unit_descriptions.py`:

```
Run gen3d for "arnulf" allies ally and report the output GLB path.
```

Batch-all-existing prompt (uses `characters.md` as the source of truth):

```
Run the full gen3d batch from characters.md (allies, orc_raiders, plague_cult,
buildings sections — leave SECTION 5–9 future factions commented out). Stop on
the first error and print the failing unit's stage and stderr.
```

## Output layout (Godot)

Flat files (matches `rigged_visual_wiring.gd` and `generation_log.json`):

- `res://art/generated/enemies/{slug}.glb`
- `res://art/generated/allies/{slug}.glb`
- `res://art/generated/buildings/{slug}.glb`
- `res://art/generated/bosses/{slug}.glb`

After export, **reload the Godot project** so `.import` updates.

## Animation clip names

Set per asset type in `foulward_gen.py`:

- enemies: `idle, walk, attack, hit_react, death`
- allies: `idle, run, attack_melee, hit_react, death, downed, recovering`
- buildings: `idle, active, destroyed`
- bosses: `idle, walk, attack, hit_react, death`

Align Mixamo filenames in `tools/gen3d/anim_library/` with `ANIM_NAME_MAP` in `stage4_anim.py`.

## Troubleshooting

| Issue | Check |
|--------|--------|
| ComfyUI dead | `curl http://127.0.0.1:8188/system_stats` |
| Empty workflow error | Export API JSON to `turnaround_flux.json` (see `workflows/README_COMFYUI.md`) |
| TRELLIS fails (DINOv3 / HF) | `HF_TOKEN` set; accept **DINOv3** on Hugging Face. If **RMBG-2.0** is 403, keep **`FOULWARD_TRELLIS_PUBLIC_REMBG=1`** (default) so stage 2 uses public BiRefNet — see `tools/gen3d/workflows/README_COMFYUI.md`. |
| Mixamo fails (UI change / login) | Env vars set; bot may break — pipeline silently writes the unrigged GLB so the run still completes |
| No animations | Populate `anim_library/` with Mixamo FBX files using the names in `ANIM_NAME_MAP` |
| Godot doesn't pick up the GLB | `Project → Reload Current Project` or focus editor; ensure `rigged_visual_wiring.gd` maps the `entity_id` to the new path |
| Humanoid arms look mangled | Add `T-pose, arms extended horizontally` to the description in `unit_descriptions.py` and re-run |

## Quality

**Placeholder-grade** for gameplay iteration. Production art follows the manual steps in `FUTURE_3D_MODELS_PLAN.md` and `FOUL WARD 3D ART PIPELINE.txt` (parent folder).

## Related docs (in repo)

- [FUTURE_3D_MODELS_PLAN.md](../../../FUTURE_3D_MODELS_PLAN.md) — roster, `res://` paths, rig wiring
- `add-new-entity` skill — data-side checklist (`Types`, `SignalBus`, `*.tres`, indexes)
