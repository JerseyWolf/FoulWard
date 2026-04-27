# PROMPT 94 — First clean pipeline run (orc_grunt)

**Date:** 2026-04-22  
**Option used:** **A** (full run — ComfyUI was up on :8188)

## Path correction vs prompt Step 0

- Prompt lists `ls tools/gen3d/staging/fw_orc_grunt_*.png` — actual staging is **`local/gen3d/staging/`** (see `foulward_gen.py` / `docs/GEN3D_LOCAL_ARTIFACTS.md`).

## Pipeline outcome

- **Stages 1–2, 4–5:** Completed. **25,000** triangles in `art/generated/enemies/orc_grunt.glb`. All three mesh candidates flagged **[LOW QUALITY]** (non-manifold edge gate); auto-selected candidate 1.
- **Stage 3 (UniRig):** Failed in-session (`skeleton.fbx` missing). Root causes diagnosed afterward:
  1. **`run.py`** imports **`src.data.extract`** → top-level **`import bpy`** failed under conda Python — fixed in **`~/UniRig-repo/src/data/extract.py`** by **lazy-importing `bpy`** only inside Blender-only functions (`load`, `clean_bpy`, `process_mesh`, `process_armature`).
  2. **`get_files()`** used `'.'.join(full_path.split('.')[:-1])` for `--input` **absolute paths**, producing an absolute “stem” so **`os.path.join("tmp", abs_dir)`** dropped `tmp` and wrote **`raw_data.npz` under Foul Ward** `art/gen3d_candidates/orc_grunt/selected/` — fixed by using **`os.path.basename`** before stripping the extension.
  3. **`ModuleNotFoundError: spconv`** — installed **`spconv-cu124`** in **`trellis2`**.
  4. After the above, skeleton **inference** runs but **`exporter._export_fbx`** still does **`import bpy`** inside **conda** Python — **FBX export requires `bpy` in the same process as Lightning**; stock Debian Blender does not provide that. Further work would be a Blender subprocess for export or upstream UniRig change.

## Foul Ward code

- **`tools/gen3d/pipeline/stage3_rig.py`:** If skeleton FBX is missing after step 1, print **stdout/stderr tails** even when bash returns 0 (shell scripts often ignore Python tracebacks for exit code).

## Verification

- `./tools/run_gdunit_quick.sh` (after `stage3_rig` edit).

## Follow-up

- UniRig: split FBX export into **Blender subprocess** or use an environment where **`bpy`** is importable from the same Python as PyTorch (non-trivial).
- Optional: remove stray **`raw_data.npz`** under `art/gen3d_candidates/orc_grunt/selected/` if you do not want UniRig intermediates in the Godot tree (git may track — check).
