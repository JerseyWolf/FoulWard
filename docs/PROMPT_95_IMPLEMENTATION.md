# PROMPT 95 — UniRig FBX via Blender subprocess

## Summary

- **UniRig** (`~/UniRig-repo`): Added `launch/inference/blender_fbx_export_launcher.py` (scene FBX re-export from `.glb`/`.gltf`/`.fbx`, plus `--export-bundle` + `--output` for numpy payloads). Added `src/data/blender_fbx_subprocess.py` to invoke the launcher from CPython.
- **Skeleton FBX** (`src/system/ar.py`): Replaced `raw_data.export_fbx()` (conda `import bpy`) with a temp `.npz` bundle + Blender subprocess (`has_skin=0`, `bundle_kind=1`, exporter bone options match prior defaults).
- **Skin FBX** (`src/system/skin.py`): Same pattern for skinned meshes (`has_skin=1`, `bundle_kind=0`).
- **Foul Ward** (`tools/gen3d/pipeline/stage3_rig.py`): `BLENDER_BIN` default `/usr/bin/blender`; expanded stdout/stderr tails (3000) when skeleton, skin, or merge output is missing or zero-sized despite exit code 0.
- **Cleanup**: Removed ignored `art/gen3d_candidates/orc_grunt/selected/raw_data.npz`; added `UniRig-repo/tmp/` to `.gitignore`.

## Verification

- Blender launcher `--input` / `--output` path tested: FBX round-trip from `/tmp/fw_sk_orc.fbx` succeeded.
- Full Stage 3 on this agent host: step 1 (skeleton) succeeds; step 2 (skin) fails earlier in `run.py` with PyTorch `weights_only` / `box.box.Box` checkpoint load (environment / Lightning + torch 2.6), not the FBX subprocess.

## Follow-ups

- If skin checkpoint load fails locally, adjust UniRig `run.py` / Lightning to load trusted checkpoints with `weights_only=False` or safe globals (outside this prompt’s scope unless requested).
