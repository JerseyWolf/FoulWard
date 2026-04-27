# Foul Ward Gen3D — State Audit Report
Generated: 2026-04-21

## 1. Pipeline File Summaries

**`foulward_gen.py`** — Main CLI orchestrator: loads secrets, defines `STYLE_FOOTER`, faction anchors, animation clip lists, `WEAPON_ASSIGNMENTS`, and `run_pipeline()` which chains Stage 1 (ComfyUI reference sheet → crop front → rembg → alpha clean → optional ComfyUI shutdown / VRAM wait), Stage 2 (`generate_mesh_variants` + `select_candidate`), Stage 3 (`rig_model`), Stage 4 (`merge_animations`), Stage 5 (`drop_to_godot`). Supports `SKIP_STAGE1`, `SKIP_STAGE2` + `SELECTED_GLB`, `AUTO_SELECT_CANDIDATE`, `N_MESH_VARIANTS`, and writes `meta.json` under `art/gen3d_candidates/{slug}/`. Concerns: `SKIP_STAGE2=1` only takes effect when `SELECTED_GLB` is non-empty (otherwise Stage 2 still runs — easy to misconfigure); `TRELLIS_CROP_TO_FRONT` is declared but cropping is implemented in Stage 1 only (name is documentation-only at module level).

**`pipeline/stage1_image.py`** — Builds the ComfyUI workflow JSON from `workflows/<FOULWARD_GEN3D_WORKFLOW>.json`, injects a combined positive prompt (`build_workflow_with_loras`), randomizes seeds, optionally caps LoRA strengths per faction, POSTs to `/prompt`, polls `/history/{prompt_id}`, copies output PNG, and rejects >95% black images. Provides `crop_front_view()` (fixed left third) and `clean_alpha_for_trellis()` (threshold + morphological min-filter on alpha). ComfyUI not running causes `requests` connection errors — not caught as a friendly message. No obvious missing imports.

**`pipeline/stage2_mesh.py`** — Stage 2: `remove_background` (rembg), `decimate_glb` (Open3D quadric decimation + `scipy.cKDTree` UV/color reprojection), `prepare_trellis_input` (square pad, resize to edge, save **RGB**), `image_to_glb` (TRELLIS.2 or bypass modes), `generate_mesh_variants` loop. On TRELLIS `ImportError`, writes a minimal placeholder GLB (`_write_placeholder_glb`) — run continues but mesh is invalid. Concerns: `generate_mesh_variants` passes `tri_budget=None` into `image_to_glb` (the `tri_budget` argument to the outer function is only used for decimation, not for TRELLIS — confusing); installing **diffusers** during this audit session may interact with other stacks — verify TRELLIS runs in your workflow after env changes.

**`pipeline/stage3_rig.py`** — Converts GLB→FBX and FBX→GLB via Blender CLI; for non-buildings, tries `calapy.mixamo.MixamoBot` then `mixamo_bot.MixamoBot`, calls `upload_and_rig`. On missing credentials, missing package, or any failure, copies the **unrigged** GLB to the output path and prints — does not raise. Buildings skip Mixamo and copy through.

**`pipeline/stage4_anim.py`** — Builds a Blender one-liner that imports the rigged GLB and zero or more FBX clips from `anim_library_dir` based on `ANIM_NAME_MAP`, renames actions, exports GLB with animations. If the library is empty or files are missing, `anim_imports` is empty: Blender still runs and exports (likely **no** animation clips beyond whatever was in the rigged GLB). If `"ANIM_DONE"` is missing from stdout, prints a warning but **still returns** `out_path` (file may exist but merge may have failed).

**`pipeline/stage5_drop.py`** — Copies the final GLB to `art/generated/.../{slug}.glb`. Straightforward.

**`generate_all.sh`** — Batch driver: ensures ComfyUI on 8188 (starts with `nohup` if needed), sets `AUTO_SELECT_CANDIDATE` and `N_MESH_VARIANTS`, runs `foulward_gen.py` for a fixed list of weapon buildings. Depends on `$FOULWARD_PYTHON` (default `python3`) and `~/ComfyUI/main.py`.

**`workflows/turnaround_flux.json`** — API-format FLUX graph: UNET/DualCLIP/VAE, three chained LoRAs, CLIPTextEncodeFlux nodes 7 (positive, empty in file — filled at runtime) and 8 (negative text), 1024² latent, KSampler, VAEDecode, SaveImage, 4× upscale, ImageScale to 2048², final SaveImage node 101. LoRA strengths are non-zero in JSON (so faction caps in `build_workflow_with_loras` apply).

**`.cursor/skills/gen3d/SKILL.md`** — Project documentation for paths, ComfyUI stack, pinned `transformers`/torch versions, and pipeline behavior. **Drift:** Stage 2 sampler defaults in the skill (e.g. sparse guidance 7.5, 500 steps) **do not match** current `stage2_mesh.py` defaults (`FOULWARD_TRELLIS_SAMPLER_STEPS` default `8`, sparse `5.0`, slat `2.0`). Update the skill or code to stay aligned.

---

## 2. Filesystem State

### What GLB files exist in `art/` (2026-04-21 scan)

Full `find ... -name "*.glb"` output:

```
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/gen3d_candidates/orc_grunt/candidate_1_decimated.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/gen3d_candidates/orc_grunt/selected.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/allies/arnulf.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/allies/arnulf_the_warrior.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/allies/florence.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/allies/florence_the_plague_doctor.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/allies/sybil_the_witch.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/bosses/audit5_territory_mini.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/bosses/final_boss.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/bosses/orc_warlord.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/bosses/plague_cult_miniboss.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/buildings/anti_air_bolt.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/buildings/archer_barracks.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/buildings/arrow_tower.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/buildings/ballista.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/buildings/fire_brazier.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/buildings/magic_obelisk.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/buildings/poison_vat.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/buildings/shield_generator.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/enemies/bat_swarm.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/enemies/goblin_firebug.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/enemies/herald_of_worms.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/enemies/lora_probe.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/enemies/orc_archer.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/enemies/orc_berserker.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/enemies/orc_brute.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/enemies/orc_grunt.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/enemies/orc_warboss.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/enemies/plague_zombie.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/misc/hex_slot.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/misc/projectile_crossbow.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/misc/projectile_rapid_missile.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/misc/tower_core.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/misc/unknown_mesh.glb
```

### `art/gen3d_candidates` (files)

```
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/gen3d_candidates/.gitkeep
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/gen3d_candidates/orc_grunt/candidate_1_decimated_0.png
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/gen3d_candidates/orc_grunt/candidate_1_decimated_0.png.import
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/gen3d_candidates/orc_grunt/candidate_1_decimated_1.png
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/gen3d_candidates/orc_grunt/candidate_1_decimated_1.png.import
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/gen3d_candidates/orc_grunt/candidate_1_decimated.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/gen3d_candidates/orc_grunt/candidate_1_decimated.glb.import
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/gen3d_candidates/orc_grunt/meta.json
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/gen3d_candidates/orc_grunt/selected_0.png
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/gen3d_candidates/orc_grunt/selected_0.png.import
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/gen3d_candidates/orc_grunt/selected_1.png
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/gen3d_candidates/orc_grunt/selected_1.png.import
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/gen3d_candidates/orc_grunt/selected.glb
/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/gen3d_candidates/orc_grunt/selected.glb.import
```

### `tools/gen3d/anim_library` (files)

```
/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/anim_library/README.md
```

No Mixamo `.fbx` clips are present — Stage 4 will export without merging external animations unless the rigged GLB already contains actions.

---

## 3. Environment State

### Conda environments (`conda env list`)

```
# conda environments:
#
# * -> active
# + -> frozen
base                     /home/jerzy-wolf/miniconda3
trellis2                 /home/jerzy-wolf/miniconda3/envs/trellis2
```

### `conda run -n trellis2 pip list | grep -iE "trellis|triposg|trimesh|open3d|fast.simpl|rembg|torch|transformers|huggingface"`

```
fast_simplification                    0.1.13
huggingface_hub                        0.36.2
open3d                                 0.19.0
rembg                                  2.0.69
torch                                  2.6.0+cu124
torchaudio                             2.6.0+cu124
torchsde                               0.2.6
torchvision                            0.21.0+cu124
transformers                           4.56.0
trimesh                                4.11.5
```

(After TripoSG-related installs, additional packages such as **diffusers**, **peft**, **pymeshlab**, **opencv-python**, **diso**, etc. may appear — run `pip list` again to see the full current set.)

### Blender

```
/usr/bin/blender
```

```
Blender 4.0.2
```

### GPU (`nvidia-smi`)

```
NVIDIA GeForce RTX 4090, 24564 MiB, 20983 MiB
```

### ComfyUI (`curl` check)

```
ComfyUI not running
```

### Hugging Face cache — configs mentioning “TRELLIS”

Command used:

`find ~/.cache/huggingface -name "config.json" 2>/dev/null | xargs grep -l "TRELLIS" 2>/dev/null | head -10`

Result: **no matches** (exit code 123 from `xargs` when no inputs / no grep hits). The snapshot folder `~/.cache/huggingface/hub/models--microsoft--TRELLIS.2-4B` **exists** (blobs/refs/snapshots present).

### `~/TRELLIS.2` (sample)

```
/home/jerzy-wolf/TRELLIS.2/trellis2/__init__.py
/home/jerzy-wolf/TRELLIS.2/data_toolkit/download.py
/home/jerzy-wolf/TRELLIS.2/data_toolkit/dump_mesh.py
/home/jerzy-wolf/TRELLIS.2/data_toolkit/encode_shape_latent.py
/home/jerzy-wolf/TRELLIS.2/data_toolkit/build_metadata.py
/home/jerzy-wolf/TRELLIS.2/data_toolkit/encode_ss_latent.py
/home/jerzy-wolf/TRELLIS.2/data_toolkit/voxelize_pbr.py
/home/jerzy-wolf/TRELLIS.2/data_toolkit/dump_pbr.py
/home/jerzy-wolf/TRELLIS.2/data_toolkit/asset_stats.py
/home/jerzy-wolf/TRELLIS.2/data_toolkit/utils.py
```

### TripoSG presence (before manual PYTHONPATH)

`find ~ -maxdepth 4 -name "triposg" -o -name "TripoSG"` → **no output** (beyond clone path after install — see §7).

`conda run -n trellis2 python -c "from triposg.pipelines import TripoPipeline; ..."` → **TripoSG NOT in trellis2** (ModuleNotFoundError: No module named `triposg`).

---

## 4. Code Audit Answers

### `foulward_gen.py`

1. **`STYLE_FOOTER` (exact value)**

```110:120:tools/gen3d/foulward_gen.py
STYLE_FOOTER: str = (
    "Game character concept art. Clean simple silhouette. "
    "Flat color regions with minimal surface detail. "
    "No engravings, no surface patterns, no fine texture. "
    "Strong readable shape from a distance. "
    "White background. Front view only, full body, T-pose, "
    "arms slightly extended from body. No cast shadows. "
    "Style: simplified Warhammer Fantasy, chunky proportions, "
    "dark humor tone. Matte colors. "
    "DO NOT show multiple views. Single front-facing character only."
)
```

2. **`TRELLIS_INPUT_SIZE`, `TRELLIS_INPUT_MODE`, `TRELLIS_CROP_TO_FRONT`**

```98:101:tools/gen3d/foulward_gen.py
_trellis_edge: int = int(os.environ.get("FOULWARD_TRELLIS_INPUT_EDGE", "768"))
TRELLIS_INPUT_SIZE: tuple[int, int] = (_trellis_edge, _trellis_edge)
TRELLIS_INPUT_MODE: str = "RGB"  # tensor fed to TRELLIS after prepare_trellis_input
TRELLIS_CROP_TO_FRONT: bool = True  # crop_front_view: left third of turnaround sheet
```

3. **`prepare_trellis_input()`** — Defined in **`pipeline/stage2_mesh.py`**, not in `foulward_gen.py`. It opens the image as RGBA, pads to a square on **white**, resizes to `TRELLIS_INPUT_SIZE` (from env `FOULWARD_TRELLIS_INPUT_EDGE`, default 768), then saves with **`.convert("RGB")`** — i.e. **drops alpha** for the file passed into TRELLIS sampling (crop happens in Stage 1 via `crop_front_view`, not inside `prepare_trellis_input`).

```347:359:tools/gen3d/pipeline/stage2_mesh.py
def prepare_trellis_input(image_path: str, out_path: str) -> str:
    from PIL import Image, ImageOps

    img = Image.open(image_path).convert("RGBA")
    # Pad to square using white background, keep subject centered
    w, h = img.size
    size = max(w, h)
    padded = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    padded.paste(img, ((size - w) // 2, (size - h) // 2))
    edge: int = int(TRELLIS_INPUT_SIZE)
    padded = padded.resize((edge, edge), Image.LANCZOS)
    padded.convert("RGB").save(out_path)
    return out_path
```

4. **`run_pipeline()` early-exit / skip behavior** — Not silent “skip everything”: `SKIP_STAGE1` skips ComfyUI but still expects existing paths for later stages (uses `mesh_image_path` variables set in the non-skip branch — **if `SKIP_STAGE1=1` without pre-existing staging images, Stage 2 may break**). `SKIP_STAGE2=1` only uses `SELECTED_GLB` when **both** are set; otherwise Stage 2 runs. TRELLIS import failure is handled inside `image_to_glb` via placeholder GLB (**undesirable but logged**).

### `stage1_image.py`

5. **`crop_front_view()`** — Takes the **left third** of the image width (`0, 0, w // 3, h`). **No** subject detection; pure layout assumption (three-panel sheet).

```269:274:tools/gen3d/pipeline/stage1_image.py
    img = Image.open(sheet_path)
    w, h = img.size
    # Front view is the leftmost third of the sheet
    front = img.crop((0, 0, w // 3, h))
    front.save(out_path)
```

6. **`clean_alpha_for_trellis()`** — Load RGBA → numpy array → threshold alpha at 128 (≥ → 255, else 0) → 3×3 **min filter** (erode) on the alpha mask → save RGBA.

7. **ComfyUI workflow and failure handling** — Workflow file from `tools/gen3d/workflows/<FOULWARD_GEN3D_WORKFLOW>` (default `turnaround_flux.json`). Prompt injection via `build_workflow_with_loras` (node `7` for FLUX dual text). If ComfyUI is **not** running, `requests.post` to `/prompt` raises (e.g. `ConnectionError`) — **not** converted to a user-friendly message. Successful HTTP errors use `raise_for_status()`.

### `stage2_mesh.py`

8. **`decimate_glb()`** — Uses **Open3D** `TriangleMesh.simplify_quadric_decimation(target_number_of_triangles=...)` inside `_decimate_o3d`. UVs are **not** preserved by Open3D; the code **re-projects** UVs (or vertex colors) from the original trimesh onto decimated vertices using **`scipy.spatial.cKDTree`** nearest-neighbor on vertex positions.

```115:145:tools/gen3d/pipeline/stage2_mesh.py
def _decimate_o3d(
    vertices: Any,
    faces: Any,
    target_faces: int,
) -> tuple[Any, Any, Any]:
    ...
    decimated: o3d.geometry.TriangleMesh = o3d_mesh.simplify_quadric_decimation(
        target_number_of_triangles=int(target_faces)
    )
```

9. **`image_to_glb()` and `prepare_trellis_input()`** — Yes. `image_to_glb` calls `prepare_trellis_input` before loading the result as RGB for `pipeline.run` (see lines 439–442). Preprocessing: **pad to square**, **resize**, **RGB** output (alpha stripped in saved `_trellis_input.png`). **Crop** is **not** in `prepare_trellis_input`; it is done in Stage 1.

10. **Defaults for `TRELLIS_SAMPLER_STEPS`, `TRELLIS_SPARSE_GUIDANCE`, `TRELLIS_SLAT_GUIDANCE`**

```255:261:tools/gen3d/pipeline/stage2_mesh.py
TRELLIS_INPUT_SIZE: int = int(os.environ.get("FOULWARD_TRELLIS_INPUT_EDGE", "768"))
...
TRELLIS_SAMPLER_STEPS: int = int(os.environ.get("FOULWARD_TRELLIS_SAMPLER_STEPS", "8"))
TRELLIS_SPARSE_GUIDANCE: float = float(os.environ.get("FOULWARD_TRELLIS_SPARSE_GUIDANCE", "5.0"))
TRELLIS_SLAT_GUIDANCE: float = float(os.environ.get("FOULWARD_TRELLIS_SLAT_GUIDANCE", "2.0"))
```

### `stage3_rig.py`

11. **Imports for rigging** — Tries **`calapy.mixamo.MixamoBot`**, then **`mixamo_bot.MixamoBot`** (optional third-party automation packages).

```147:158:tools/gen3d/pipeline/stage3_rig.py
            try:
                from calapy.mixamo import MixamoBot  # type: ignore[import-not-found]

                bot = MixamoBot(email=mixamo_email, password=mixamo_password)
            except ImportError:
                try:
                    from mixamo_bot import MixamoBot  # type: ignore[import-not-found]

                    bot = MixamoBot(email=mixamo_email, password=mixamo_password)
                except ImportError:
                    bot = None
```

12. **Fallback when rigging fails** — **Copies the unrigged GLB** to `out_path` and returns that path (prints error). Does not re-raise for automation failure after credentials are present.

### `stage4_anim.py`

13. **`merge_animations()` when `anim_library_dir` has no usable FBX files** — Does **not** raise. The loop produces an empty `anim_imports` string; Blender still imports the rigged GLB and exports. A warning may print if `"ANIM_DONE"` is absent from stdout.

14. **FBX filenames looked up** (values of `ANIM_NAME_MAP`):

| Clip key        | Filename                          |
|----------------|-----------------------------------|
| idle           | Idle.fbx                          |
| walk           | Walking.fbx                       |
| run            | Running.fbx                       |
| attack         | Punching.fbx                      |
| attack_melee   | Sword And Shield Slash.fbx        |
| hit_react      | Receiving Damage.fbx              |
| death          | Dying.fbx                         |
| downed         | Falling Back Death.fbx            |
| recovering     | Getting Up.fbx                    |
| active         | Idle.fbx                          |
| destroyed      | Falling Back Death.fbx            |

Unknown clip keys fall back to **`Idle.fbx`** via `.get(clip_name, "Idle.fbx")`.

### `turnaround_flux.json`

15. **Positive prompt text in the JSON file** — Node `7` has **empty** `clip_l` / `t5xxl` in the committed file; the **runtime** positive prompt is built in `generate_reference_sheet`:

```189:192:tools/gen3d/pipeline/stage1_image.py
    full_prompt: str = (
        f"Character design turnaround sheet, front view, right side view, back view, "
        f"isolated on white background.\n{unit_name}.\n{faction_block}\n{style_footer}"
    )
```

16. **Negative prompt text (node 8, both `clip_l` and `t5xxl`)** — Exact string:

`multiple views, turnaround sheet, side view, back view, detailed engravings, surface patterns, fine texture, photorealistic, subsurface scattering, specular highlights, complex shading, busy background`

17. **Output resolution** — Latent **1024×1024** (`EmptyLatentImage` node 9). Final preferred output from node **101** after upscale chain: **2048×2048** (`ImageScale` node 100).

18. **LoRA nodes and strengths (committed JSON)** — Nodes `4`, `5`, `6` are `LoraLoader`s:

- Node 4: `strength_model` **0.4**, `strength_clip` **0.4**
- Node 5: **0.5** / **0.5**
- Node 6: **0.4** / **0.4**

`build_workflow_with_loras` may **cap** these by faction tables when not in the “all LoRAs zero” workaround mode.

---

## 5. STYLE_FOOTER and Workflow State

- **`STYLE_FOOTER`**: see §4 block quote (`foulward_gen.py` lines 110–120).
- **Runtime positive prompt**: prefix + `unit_name` + `faction_block` + `style_footer` (see `stage1_image.py` 189–192).
- **Negative prompt**: node 8 string in §4.16.
- **Resolution**: 1024² sample → 2048² final (nodes 9 and 100/101).
- **LoRA strengths**: 0.4/0.4, 0.5/0.5, 0.4/0.4 in `turnaround_flux.json` (subject to `build_workflow_with_loras`).

---

## 6. Known Bugs Found

| Location | Issue | Expected / note |
|----------|--------|-----------------|
| `foulward_gen.py` ~315–348 vs skip | `SKIP_STAGE1=1` skips generation but `nobg_path` / `clean_path` are only set inside the non-skip branch — **staging files must already exist** or Stage 2 breaks. | Document or set defaults when skipping. |
| `stage2_mesh.py` ~583 | `image_to_glb(..., tri_budget=None, ...)` — **`tri_budget` parameter to `generate_mesh_variants` is not passed through** to TRELLIS (always `None` for `image_to_glb`). | Confusing API; either wire or remove parameter. |
| `stage2_mesh.py` ~413–421 | TRELLIS `ImportError` → **`_write_placeholder_glb`** — pipeline continues with a **toy GLB**. | Silent downstream failure risk if logs ignored. |
| `.cursor/skills/gen3d/SKILL.md` Stage 2 | Documents **500 steps** and **7.5 / 3.0** guidance vs code defaults **8** steps and **5.0 / 2.0**. | Documentation drift — align skill with `stage2_mesh.py` or vice versa. |
| TripoSG upstream | No `pyproject.toml` / `setup.py` at repo root — **`pip install git+...` fails**. | Use README install path (`pip install -r requirements.txt` in clone). |
| Verification snippet (user prompt) | Imports **`TripoPipeline`** — upstream class is **`TripoSGPipeline`** in `pipeline_triposg.py`. | Use correct class name / path. |
| `diso` after manual install | **`ImportError` undefined symbol** in `_C.so` when importing `TripoSGPipeline`. | ABI / CUDA extension mismatch — needs rebuild or env fix (see §7). |

---

## 7. TripoSG Installation Result

### Attempt 1 — `pip install git+https://github.com/VAST-AI-Research/TripoSG.git`

**Failed.** PyPI/pip reports: neither `setup.py` nor `pyproject.toml` at repo root.

```
ERROR: git+https://github.com/VAST-AI-Research/TripoSG.git does not appear to be a Python project: neither 'setup.py' nor 'pyproject.toml' found.
```

### Attempt 2 — `pip install -e .` in clone

**Failed** — same reason (no setuptools project metadata at root).

```
ERROR: file:///home/jerzy-wolf/TripoSG does not appear to be a Python project: neither 'setup.py' nor 'pyproject.toml' found.
```

### Attempt 3 — Dependencies from `requirements.txt`

- **`pip install -r requirements.txt`** initially **failed** on **`diso`** (isolated build env without `torch`).
- **`diso`** installed successfully with:  
  `/home/jerzy-wolf/miniconda3/envs/trellis2/bin/pip install --no-build-isolation diso`
- Remaining packages installed **without** pinning `numpy==1.22.3` (would conflict with current NumPy 2.x stack):  
  `diffusers`, `omegaconf`, `opencv-python`, `peft`, `jaxtyping`, `typeguard`, `pymeshlab`, etc.

**Clone location:** `/home/jerzy-wolf/TripoSG` (add to `PYTHONPATH` or run from that tree; there is still **no** installable `triposg` package on `sys.path` without path hacking).

### Verification commands

**Requested:** `from triposg.pipelines import TripoPipeline` — **fails** (`TripoPipeline` does not exist; `triposg` is not an installed package).

**Correct import path (upstream):** `from triposg.pipelines.pipeline_triposg import TripoSGPipeline` with `sys.path` including the repo root.

**Actual result after deps install:**

```
ImportError: .../diso/_C.so: undefined symbol: _ZN8cudualmc8CUDualMCIdiE7forwardEPKdPKNS_6VertexIdEEiiidi
```

So **TripoSG pipeline import is not OK** in `trellis2` until **`diso`** (or CUDA/toolchain) is fixed for this torch/CUDA combo.

### Model weights

Per **TripoSG `README.md`**, weights are **downloaded automatically** when running inference (e.g. to `pretrained_weights/TripoSG`, RMBG, etc.) — first run will pull from Hugging Face (`VAST-AI/TripoSG` and related repos listed in README).

---

## 8. Blockers Summary

1. **ComfyUI not running** — Stage 1 cannot execute until ComfyUI is up on port **8188** (or `SKIP_STAGE1=1` with valid existing staging PNGs).
2. **`anim_library/` has no `.fbx` files** — Stage 4 will not merge Mixamo clips; exported GLB may lack the expected animation set for Godot.
3. **Mixamo automation** — Optional packages (`calapy` / `mixamo_bot`) and credentials; otherwise Stage 3 passes **unrigged** meshes through (by design).
4. **TripoSG** — Not installable via pip-from-Git alone; manual dependency install hit **`diso` native extension** import failure — **TripoSG is not usable** in this env until that is resolved. **Additionally**, new packages (**diffusers**, **peft**, **accelerate**, etc.) were added to `trellis2` during this session — **verify TRELLIS.2 workflows** still behave as expected (smoke test: `PYTHONPATH=~/TRELLIS.2` import `Trellis2ImageTo3DPipeline` succeeded after changes).
5. **Documentation drift** — `.cursor/skills/gen3d/SKILL.md` Stage 2 numbers vs `stage2_mesh.py` defaults may mislead tuning.

---

⛔ **STOP — Phase A complete.** Await explicit approval before Phase B.
