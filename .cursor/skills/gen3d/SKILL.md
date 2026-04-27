# SKILL: gen3d — Automatic 3D asset generation (local pipeline)

## Local artifact root (norm — 2026-04-21)

- **Bulk gen3d output** (reference PNG scratch, TRELLIS working dirs, A/B experiment GLBs, ComfyUI logs) must live under **`local/gen3d/`** at the repository root — **not** `/tmp/`.
- That tree is listed in **`.gitignore`** and **`.cursorignore`** so it is **not committed to GitHub** and **not indexed by Cursor** (saves capacity and keeps AI context small).
- **Policy doc:** `docs/GEN3D_LOCAL_ARTIFACTS.md`.
- **`foulward_gen.py`** writes intermediates to **`local/gen3d/staging/`** (e.g. `fw_<slug>_ref.png`, `fw_<slug>_candidates/`, rig/final GLB scratch).
- **Game drops and previews** (`art/generated/`, `art/gen3d_previews/`, `art/gen3d_candidates/`) are **local-only** — gitignored and cursorignored until production assets are frozen (see `docs/GEN3D_LOCAL_ARTIFACTS.md`). Only empty dirs + `.gitkeep` ship in the repo.
- **A/B harness scripts (tracked):** `tools/gen3d/scripts/ab_test_batch.py`, `tools/gen3d/scripts/prepare_trellis_ab_variants.py` — outputs default to **`local/gen3d/ab_test/`**.

## Stage 1 Environment (Resolved — do not change)

- ComfyUI: v0.19.3 at http://127.0.0.1:8188
- Start command (log under repo): append to `local/gen3d/logs/comfyui.log` — see `generate_all.sh` or: `mkdir -p local/gen3d/logs && nohup $FOULWARD_PYTHON ~/ComfyUI/main.py --listen 127.0.0.1 --port 8188 >> local/gen3d/logs/comfyui.log 2>&1 &`
- `FOULWARD_PYTHON`: `/home/jerzy-wolf/miniconda3/envs/trellis2/bin/python3`
- UNET: `~/ComfyUI/models/unet/flux1-dev.safetensors` (23.80GB, `weight_dtype`: default)
- CLIP: `~/ComfyUI/models/clip/clip_l.safetensors` (~246MB)
- T5: `~/ComfyUI/models/clip/t5xxl_fp8_e4m3fn.safetensors` (~4.6GB)
- VAE: `~/ComfyUI/models/vae/flux_ae.safetensors`
- LoRA strengths validated: turnaround=0.4, baroque=0.5, velvet=0.4
- Minimal test baseline: mean RGB (228.6, 201.9, 197.3), 0.0% black

## Pinned dependency versions (Stage 2 / `trellis2` conda — do not upgrade without testing)

- **transformers: 4.56.0** — `transformers` **5.5.x** breaks TRELLIS.2’s DINOv3 path: `AttributeError: 'DINOv3ViTModel' object has no attribute 'layer'`. **`transformers==4.46.3` is not usable** here: that release has no `DINOv3ViTModel` (`ImportError` on import). **4.56.0** matches the working downgrade in [microsoft/TRELLIS.2#147](https://github.com/microsoft/TRELLIS.2/issues/147). Install with full dependency resolution, e.g. `pip install "transformers==4.56.0" --force-reinstall` (avoid `--no-deps` unless you also align `tokenizers` / `huggingface-hub`).
- **torch: 2.6.0+cu124**
- **torchaudio: 2.6.0+cu124**
- **timm: 1.0.26** (do not change without re-testing Stage 2)
- **Python: 3.10** (`trellis2` conda env)

### DINOv3 / transformers quick reference

| Symptom | Fix |
|--------|-----|
| `'DINOv3ViTModel' object has no attribute 'layer'` | Pin **transformers 4.56.0** (you are likely on 5.5.x). |
| `cannot import name 'DINOv3ViTModel' from 'transformers'` | Transformers too old; use **4.56.0**, not **4.46.3**. |

Further discussion: [microsoft/TRELLIS.2#147](https://github.com/microsoft/TRELLIS.2/issues/147), [visualbruno/ComfyUI-Trellis2#144](https://github.com/visualbruno/ComfyUI-Trellis2/issues/144).

## Stage 1 Image Generation Settings (validated)

- Resolution: 1024×1024 (FLUX sharpness sweet spot — do NOT go higher, FLUX blurs above 1MP)
- Steps: 28, cfg: 3.5, sampler: euler, scheduler: beta
- LoRA strengths: turnaround=0.4, baroque=0.5 (orc)/0.3 (allies), velvet=0.4/0.3 (buildings)
- Upscale pass: 4× NMKD-Superscale → lanczos down to 2048×2048 for reference sheet
- Output node: 101 (`foulward_turnaround_hires_*.png` at 2048×2048)

## Stage 2 TRELLIS Settings (validated)

- **VRAM:** After Stage 1, `foulward_gen.py` **always** stops ComfyUI (`pkill` + optional `/api/quit`) and **polls `nvidia-smi`** until used VRAM &lt; 12 GB (or timeout) before loading TRELLIS — FLUX.1-dev (~16+ GB resident) and TRELLIS.2-4B cannot coexist on 24 GB. To skip shutdown (only safe with a **small** image model, e.g. FLUX.1-schnell fp8): `export SKIP_COMFYUI_SHUTDOWN=1`.
- **Stage 2 (multi-variant):** `generate_mesh_variants(n_variants=N)` runs TRELLIS N times with different random seeds and decimates each. Default `N_MESH_VARIANTS=5`. The user is prompted to pick one; batch runs auto-select candidate 1 (`AUTO_SELECT_CANDIDATE=1`). Candidates are stored in both **`local/gen3d/staging/fw_{slug}_candidates/`** (large scratch; gitignored) and `art/gen3d_candidates/{slug}/` (permanent review copies). `meta.json` sidecar tracks the selection.
- **Stage 2b (decimation):** `decimate_glb` preserves UV/PBR textures. Strategy: Open3D QEM decimation (correctly targets face count even on non-manifold TRELLIS meshes), then scipy `cKDTree` nearest-vertex UV re-projection from the original high-res mesh. Output includes `TextureVisuals` + embedded `PBRMaterial` baseColorTexture. **Do NOT revert to plain Open3D decimation** — it stripped all UV data.
- **Pre-decimation:** `o_voxel.postprocess.to_glb` runs with `decimation_target=100000` (env: `FOULWARD_TRELLIS_PREDECIMATE`, default 100000). This reduces the raw TRELLIS GLB from ~38 MB to ~4 MB before the `decimate_glb` step. Increase to 1000000 for maximum source detail.
- **Seed:** `image_to_glb` accepts `seed: int | None`. `None` → random 32-bit seed. Seed is passed to TRELLIS and logged (`[TRELLIS] seed=...`). Same image + same seed → same geometry.
- Input: crop left-third of turnaround sheet (front view) → pad square on white → resize to **768** px edge (A/B 2026-04-20; env ``FOULWARD_TRELLIS_INPUT_EDGE`` overrides default 768).
- Prefer **single front panel** for clean humanoids; full multi-view sheets can score similar on edge-count proxies but often hallucinate extra bodies in the mesh.
- Model is trained around ~518 px; 768 is the project default after A/B (was 770 community sweet spot).
- sparse_structure steps: 500, **guidance_strength** 7.5 (TRELLIS.2 sampler API — not `cfg_strength`)
- slat steps: 500, **guidance_strength** 3.0
- texture_resolution: 2048 (``o_voxel.postprocess.to_glb`` → ``texture_size``)
- nviews: 120 (community default for multiview texture quality; bake path is fixed in ``o_voxel``)
- Expected GLB size after decimation: ~10–20 MB (includes embedded 2048px WebP/PNG baseColorTexture); triangle count ~8k–12k (enemies/allies), 8k (buildings), ~20k (bosses)

### Variant selection env vars

| Variable | Default | Meaning |
|---|---|---|
| `N_MESH_VARIANTS` | `5` | Number of TRELLIS runs per asset |
| `AUTO_SELECT_CANDIDATE` | `0` (interactive) | `1` = auto-select candidate 1 without prompt (set by `generate_all.sh`) |
| `FOULWARD_TRELLIS_PREDECIMATE` | `100000` | Pre-decimation target inside `o_voxel.to_glb` |

### Re-selecting a variant after a batch run

```bash
cd tools/gen3d
# Re-promote candidate 3 for orc_grunt and re-run stages 3–5:
$FOULWARD_PYTHON promote_candidate.py orc_grunt 3
```

Candidates live at `art/gen3d_candidates/{slug}/candidate_{N}_decimated.glb`.
`selected.glb` in the same dir is what stages 3–5 consume.

### Skip-stage env vars (for promote_candidate.py / CI)

| Variable | Meaning |
|---|---|
| `SKIP_STAGE1=1` | Skip ComfyUI image generation; uses `fw_{slug}_front_clean.png` if it exists, else falls back to `fw_{slug}_front_nobg.png` with a warning |
| `SKIP_STAGE2=1` | Skip TRELLIS mesh generation; requires `SELECTED_GLB=<path>` |
| `SELECTED_GLB=<path>` | Absolute path to the already-decimated GLB to feed into stage 3 |

Invoke gen3d with: `$FOULWARD_PYTHON tools/gen3d/foulward_gen.py "Unit Name" faction asset_type`

### Rigging env vars

| Variable | Default | Meaning |
|---|---|---|
| `FOULWARD_RIG_BACKEND` | unset (priority order) | `unirig` = force UniRig only; `mixamo` = force Mixamo only; unset = UniRig → Mixamo → unrigged copy |
| `UNIRIG_REPO` | required for UniRig | Absolute path to the `~/UniRig-repo` checkout (set in `~/.foulwardsecrets`) |
| `UNIRIG_WEIGHTS` | required for UniRig | Absolute path to `~/UniRig` weights dir (set in `~/.foulwardsecrets`) |

#### UniRig pipeline (run from `UNIRIG_REPO` as CWD)

UniRig is a **3-step shell script pipeline** — all three must succeed for the rig to be accepted:

```bash
# Step 1 — predict bone positions
conda run -n trellis2 bash launch/inference/generate_skeleton.sh \
  --input <glb> --output <tmp_skeleton.fbx>

# Step 2 — predict skinning weights
conda run -n trellis2 bash launch/inference/generate_skin.sh \
  --input <tmp_skeleton.fbx> --output <tmp_skin.fbx>

# Step 3 — merge back onto source GLB
conda run -n trellis2 bash launch/inference/merge.sh \
  --source <tmp_skin.fbx> --target <glb> --output <out_path>
```

**Pre-flight (run once after cloning UniRig):**
```bash
# Patch extract.sh to use Blender's bundled Python
BLENDER_PY=$(blender --background --python-expr "import sys; print(sys.executable)" -- 2>/dev/null \
  | grep -v "^Blender\|^Fra\|^Al\|found\|Warning\|Error" | tail -1)
sed -i "s|python -m src.data.extract|$BLENDER_PY -m src.data.extract|g" \
  ~/UniRig-repo/launch/inference/extract.sh

# Verify smoke test passes on bundled giraffe first
cd ~/UniRig-repo
conda run -n trellis2 bash launch/inference/generate_skeleton.sh \
  --input examples/giraffe.glb --output results/giraffe_skeleton.fbx
```

### Mesh quality gate env vars

| Variable | Default | Meaning |
|---|---|---|
| `FOULWARD_MESH_QUALITY_GATE` | `5000` | Non-manifold edge count above which a variant is labelled `[LOW QUALITY]` in the selection prompt. Does not hard-reject. |

### Weapon generation gate

**Weapons must NOT be generated via TRELLIS.** TRELLIS produces poor results for thin
elongated geometry (swords, staves, bows, axes). Author weapons in **Blender** or via
**Tripo3D**, then place the GLB directly at `art/generated/weapons/<slug>.glb`.

`WEAPON_SLUGS` is derived from `WEAPON_ASSIGNMENTS` in `foulward_gen.py`. Running
`foulward_gen.py` for a weapon slug without `FOULWARD_WEAPON_TRELLIS=1` prints a warning
and exits early. The `generate_all.sh` weapon `run` lines are commented out.

## Previously broken (fixed — do not revert)

- Old `flux_t5_1` / `flux_t5_2` were sharded HF diffusers T5 (only shard 1 of 2 loaded) → "Long clip missing" → NaN → black PNG. Fixed by downloading `comfyanonymous/flux_text_encoders` `t5xxl_fp8_e4m3fn.safetensors`.
- Old UNETLoader pointed at `diffusion_pytorch_model-00001-of-00003.safetensors` (shard 1 of 3) → NaN. Fixed by downloading single-file `flux1-dev.safetensors`.
- ComfyUI must be started with **trellis2** conda env Python, not base miniconda Python 3.13.

## Purpose

Load this skill when generating **placeholder or batch 3D assets** for Foul Ward: enemies, allies, bosses, buildings. The Python orchestrator lives in **`tools/gen3d/`** in this repo; it drives local tools on the developer machine (ComfyUI + FLUX.1 dev, TRELLIS.2, Blender, optional Mixamo automation). Output is **`.glb`** under `res://art/generated/...` with the same **flat naming** as existing placeholders (`rigged_visual_wiring.gd`, `docs/FUTURE_3D_MODELS_PLAN.md`).

## When to use

- "Create a 3D model for [unit]" / "Generate a GLB for [enemy/building]"
- "Run the gen3d pipeline" / "Batch placeholder meshes"
- "Add a new character to Foul Ward and generate its model"
- Anything involving **local** ComfyUI → mesh → rig → animation → Godot drop

## Canonical paths (this workspace)

| Item | Absolute path |
|------|-----------------|
| **Install / workflows** | `tools/gen3d/workflows/README_COMFYUI.md` (ComfyUI + FLUX); this SKILL § Pipeline + How to run |
| **Scripts (in-repo)** | `/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/` |
| **Per-unit description bank** | `/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/pipeline/unit_descriptions.py` |
| **Character manifest (source of descriptions)** | `/home/jerzy-wolf/.cursor/plans/characters.md` |
| **Godot project** | `/home/jerzy-wolf/workspace/foul-ward/FoulWard` |
| **Godot path resolver (per `entity_id`)** | `scripts/art/rigged_visual_wiring.gd` |
| **Roster doc** | `docs/FUTURE_3D_MODELS_PLAN.md` |

## Pipeline (5 stages)

1. **2D reference** — ComfyUI + **FLUX.1 [dev]** + three CivitAI LoRAs.  
   Prompt is built from: `description (from unit_descriptions.py or unit_name)` + `FACTION_ANCHORS[faction]` + `STYLE_FOOTER` (LoRA triggers baked in).
2. **Image → mesh** — TRELLIS.2 (`conda` env `trellis2`). Returns `(candidates, quality_labels)` tuple; `quality_labels` annotates `[LOW QUALITY]` entries above `MESH_QUALITY_GATE`.
3. **Rig** — **UniRig** (primary, always attempted first); Mixamo Selenium bot (secondary, only if UniRig fails and credentials are set); unrigged GLB copy (always last resort). Buildings skip rig. See `FOULWARD_RIG_BACKEND` below.
4. **Animation** — Blender merges FBX clips from `anim_library/`; see `ANIM_NAME_MAP` in `stage4_anim.py`. Stage 4 degrades gracefully: if zero clips are found in `anim_library/`, Blender is skipped and the rigged GLB is copied unchanged.
5. **Drop** — Copy `{slug}.glb` to `art/generated/{enemies|allies|buildings|bosses}/`.

## How to run (single unit)

```bash
cd /home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d
# Optional: ~/.foulward_secrets with export MIXAMO_* and export HF_TOKEN=hf_... (see tools/gen3d/workflows/README_COMFYUI.md)
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
- `res://art/generated/weapons/{slug}.glb`  ← manually authored, not TRELLIS-generated

After export, **reload the Godot project** so `.import` updates.

## Weapon attachment (Godot)

`scripts/art/weapon_attachment.gd` (`class_name WeaponAttachment`) provides:

```gdscript
# Loads weapon GLB and attaches it to the correct bone via BoneAttachment3D
WeaponAttachment.attach(character_root: Node3D, weapon_slug: String, bone_name: String) -> Node3D
```

`scripts/art/rigged_visual_wiring.gd` exposes:

```gdscript
const WEAPON_ASSIGNMENTS: Dictionary   # entity_id → [[weapon_slug, bone_name], ...]
static func attach_weapons(entity_id: String, character_root: Node3D) -> void
```

Call `RiggedVisualWiring.attach_weapons(entity_id, character_root)` after
`mount_glb_scene()` to wire all weapons for an entity. Silently no-ops for unknown IDs
and missing GLBs.

## Architecture / planning docs

| Doc | Purpose |
|-----|---------|
| `docs/gen3d/ARCHER_IK_PLAN.md` | orc_archer bow IK: node tree, SkeletonIK3D config, string morph target, deferred implementation checklist |
| `docs/gen3d/BUILDING_ANIM_PLAN.md` | Building animation approach: idle (synthesised), active (manual FBX), destroyed (morph target), Stage 4 changes required |

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
| TRELLIS fails (DINOv3 / HF) | `HF_TOKEN` set; accept **DINOv3** on Hugging Face. Pin **`transformers==4.56.0`** in `trellis2` if you see **`DINOv3ViTModel` / `.layer`** errors (see **Pinned dependency versions** above). If **RMBG-2.0** is 403, keep **`FOULWARD_TRELLIS_PUBLIC_REMBG=1`** (default) so stage 2 uses public BiRefNet — see `tools/gen3d/workflows/README_COMFYUI.md`. |
| Stage 2 **`cfg_strength`** / sampler API | Current TRELLIS expects **`guidance_strength`** in sampler params (not `cfg_strength`). |
| Stage 2 **CUDA OOM** with ComfyUI up | Default: `foulward_gen.py` stops ComfyUI after Stage 1 to free VRAM; or stop ComfyUI manually before TRELLIS. |
| **White mesh / untextured GLB** | Root cause was Open3D stripping UV on rebuild. Fixed (Prompt 86): `decimate_glb` now uses Open3D + cKDTree UV re-projection. If it recurs, run `_check_glb_has_texture(raw_glb)` on the TRELLIS output first. |
| Decimated GLB white but raw is textured | Verify `pipeline/stage2_mesh.py` `decimate_glb` exports via `trimesh.Scene(geometry={...}).export(out, file_type="glb")` — not `mesh.export(out)` which loses materials. |
| UniRig fails on a box/placeholder mesh | Acceptable; pipeline falls through to unrigged copy. Verify giraffe smoke test passes before filing a bug. |
| UniRig: `UNIRIG_REPO` not set | Add `export UNIRIG_REPO=$HOME/UniRig-repo` to `~/.foulwardsecrets` |
| UniRig: `extract.sh` uses bare `python` | Patch: `sed -i "s|python -m src.data.extract|<blender_py> -m src.data.extract|g" launch/inference/extract.sh` |
| Mixamo fails (UI change / login) | Env vars set; bot may break — pipeline silently falls back to UniRig then unrigged copy |
| No animations | Populate `anim_library/` with Mixamo FBX files using the names in `ANIM_NAME_MAP`; Stage 4 skips Blender and copies the rigged GLB unchanged if zero clips are found |
| Stage 4 prints "0 found, N missing" | `anim_library/` is empty; download FBX clips from Mixamo (FBX for Unity, T-pose, 30fps) |
| Godot doesn't pick up the GLB | `Project → Reload Current Project` or focus editor; ensure `rigged_visual_wiring.gd` maps the `entity_id` to the new path |
| Humanoid arms look mangled | Add `T-pose, arms extended horizontally` to the description in `unit_descriptions.py` and re-run |

## Quality

**Placeholder-grade** for gameplay iteration. Production art follows the manual steps in `docs/FUTURE_3D_MODELS_PLAN.md`.

## Related docs (in repo)

- [docs/FUTURE_3D_MODELS_PLAN.md](../../../docs/FUTURE_3D_MODELS_PLAN.md) — roster, `res://` paths, rig wiring
- `add-new-entity` skill — data-side checklist (`Types`, `SignalBus`, `*.tres`, indexes)
