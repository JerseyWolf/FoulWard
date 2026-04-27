# PROMPT 97 — First full UniRig rig pass (real orc mesh)

## Root cause when merge “succeeded” but GLB had 0 skins

1. **`merge.sh`** ran `python -m src.inference.merge` in the **background** (`&`) and always exited **0**, so Foul Ward never saw merge failures.
2. **`merge.py`** imports **`bpy`** at module load — **conda** Python cannot import it, so merge never actually ran; the output GLB stayed the **unrigged** copy (~2.39 MB).

## Fixes (UniRig only)

| Change | Purpose |
|--------|---------|
| **`launch/inference/blender_merge_launcher.py`** (new) | Same pattern as `blender_extract_launcher.py`: `runpy.run_module("src.inference.merge", …)` inside **Blender** so `bpy` / `mathutils` exist. |
| **`launch/inference/merge.sh`** | Call `$BLENDER_BIN --background --python blender_merge_launcher.py -- …`; **remove** background `&`; **`exit` with merge status**. |
| **`src/inference/merge.py`** | Drop unused **`import open3d`** (Blender’s Python does not ship `open3d`; the symbol was unused). |

Skin voxel backend **`open3d`** in `configs/transform/inference_skin_transform.yaml` (Prompt 97 continuation) avoids **`pyrender`** in headless conda.

## Verification

- **Isolation:** `/tmp/orc_grunt_rigged_p97.glb` — **25,000** tris, **Skins: 1**, **Joints: 28**.
- **Full run:** `foulward_gen.py orc_grunt …` with `SKIP_STAGE1=1` — `art/generated/enemies/orc_grunt.glb` — **Skins: 1**, **Joints: 28**, **Animations: 0** (no Mixamo clips in `anim_library/`; expected).

## Note on “Blender crashed”

Do not `pip install` into the system **Blender** interpreter (PEP 668 / wrong `python`); use **conda** for Trellis/UniRig GPU steps and **launchers** for anything that needs `bpy`.
