# PROMPT 93 — Gen3D first real pipeline run (orc_grunt)

**Date:** 2026-04-22  
**Scope:** Pre-flight UniRig + ComfyUI, attempted `foulward_gen.py` for `orc_grunt`, path/name corrections, small Stage 1 UX fix.

## Path / naming corrections vs prompt

| Prompt assumption | Actual / recommendation |
|-------------------|-------------------------|
| `~/.foulwardsecrets` | File did not exist; created with `UNIRIG_REPO` / `UNIRIG_WEIGHTS`. (Repo docs sometimes mention `~/.foulward_secrets` for Mixamo — different file.) |
| `conda run ... "orc grunt"` | **Quoting got lost** under `conda run`; use **`orc_grunt`** as one token (same `canonical_slug` as `"orc grunt"`) or call env Python directly: `.../envs/trellis2/bin/python foulward_gen.py ...` |
| Log via `tee` + `conda run` | **Buffered / empty log** until process end; use **`trellis2/bin/python -u`** and redirect for live logs. |
| Patch `extract.sh` with `blender --python-expr` → `sys.executable` | On Blender **4.0.2** (Debian), `sys.executable` is **`/usr/bin/python3.12` without `bpy`**. Wrong approach. |
| `examples/giraffe.glb` smoke test | File is a **Git LFS pointer** (132 B ASCII), not a mesh — needs `git lfs pull` or another GLB. |

## UniRig fixes (outside FoulWard tree: `~/UniRig-repo`)

1. **`launch/inference/blender_extract_launcher.py`** (new): runs `runpy.run_module("src.data.extract", ...)` inside Blender so `bpy` is available; forwards argv after `--`.
2. **`launch/inference/extract.sh`**: calls `blender --background --python …/blender_extract_launcher.py --` instead of bare `python -m …`.
3. **System Python 3.12** (Blender’s `sys.prefix` is `/usr` here): installed extract deps with `python3.12 -m pip install --break-system-packages` (`tqdm`, `trimesh`, `numpy`, `scipy`, `pyyaml`, `python-box`, `fast_simplification`).
4. **`src/data/asset.py`**: `Dict[str, ...]` → `Dict[str, Any]` for **Python 3.10** (`conda run -n trellis2`).
5. **`trellis2`**: `pip install lightning` for `run.py`.

## FoulWard code change

- **`tools/gen3d/pipeline/stage1_image.py`**: wrap first ComfyUI `POST /prompt` in `try/except requests.exceptions.ConnectionError` and raise **`RuntimeError`** with actionable text (start ComfyUI or `SKIP_STAGE1=1`).

## Pipeline run outcome (this session)

- **ComfyUI** responded at session start; later **`127.0.0.1:8188` connection refused** — full end-to-end run could not be completed from this agent without a running ComfyUI.
- **Staging** already contains `fw_orc_grunt_*` images and tiny **~1.5 KB** candidate GLBs from earlier runs (not a useful mesh for production).

## Follow-ups for a real end-to-end run

1. Start ComfyUI on **8188**, then run from `tools/gen3d`:  
   `FOULWARD_RIG_BACKEND=unirig N_MESH_VARIANTS=3 AUTO_SELECT_CANDIDATE=1 …/trellis2/bin/python -u foulward_gen.py orc_grunt orc_raiders enemy`
2. For UniRig smoke test without LFS: use any **binary** `.glb` (e.g. first TRELLIS output) instead of `giraffe.glb`.
