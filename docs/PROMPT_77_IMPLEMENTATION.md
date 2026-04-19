# PROMPT 77 — Gen3D pipeline workplan + skill

**Date:** 2026-04-19  
**Scope:** Implement the Gen3D automated asset pipeline **outside** the git repo, add `.cursor/skills/gen3d/SKILL.md`, and register the skill in `AGENTS.md`.

## Delivered

### Outside repo (`/home/jerzy-wolf/workspace/foul-ward/`)

- **`gen3d_workplan.md`** — Install checklist, paths, run instructions, secrets handling (no credentials in files).
- **`gen3d/`** — Python orchestrator and stages:
  - `foulward_gen.py`
  - `pipeline/stage1_image.py` … `stage5_drop.py`
  - `workflows/README_COMFYUI.md`, placeholder `turnaround_flux.json` (replace with ComfyUI API export)
  - `anim_library/README.md`
  - `requirements.txt`

### Inside repo

- **`.cursor/skills/gen3d/SKILL.md`** — Agent-facing skill (links to workplan + absolute paths).
- **`AGENTS.md`** — New row under “Available Skills” for gen3d (`.cursorrules` is a symlink → same content).

## Paths

- `GODOT_ROOT`: `/home/jerzy-wolf/workspace/foul-ward/FoulWard`
- `GEN3D_ROOT`: `/home/jerzy-wolf/workspace/foul-ward/gen3d`
- GLB output: `art/generated/{enemies,allies,buildings,bosses}/{slug}.glb` (flat)

## Verification

- No `.gd` / `.cs` changes — GdUnit not required for this documentation/tooling-only change.
- Operators must install ComfyUI, TRELLIS.2, Blender per `gen3d_workplan.md` and export ComfyUI workflow JSON before Stage 1 succeeds.

## Notes

- Mixamo credentials: **environment variables only** (`MIXAMO_EMAIL`, `MIXAMO_PASSWORD`).
- TRELLIS.2 and Mixamo automation APIs may require small edits after upstream changes (`stage2_mesh.py`, `stage3_rig.py`).

## Follow-up audit (same session)

- **Bug:** `pipeline/stage3_rig.py` referenced an undefined `{fb_s}` instead of `{fbx_s}` in the GLB→FBX Blender script — would have raised `NameError` on the first humanoid run. **Fixed.**
- **Bug:** `pipeline/stage2_mesh.py` and `pipeline/stage4_anim.py` used `\\n` in error/warning f-strings (literal `\n`, not a newline). **Fixed.**
- **Cleanup:** Removed unused `import sys` from `stage4_anim.py`.
- **Robustness:** `pipeline/stage1_image.py` now randomizes seeds for both `seed` (KSampler) and `noise_seed` (FLUX `RandomNoise`) inputs across all nodes; previous code only handled KSampler.
- **New:** `pipeline/unit_descriptions.py` mirrors `~/.cursor/plans/characters.md` — 32 slugs (Arnulf/Florence/Sybil, mercs, full Orc Raiders + Plague Cult MVP roster, all 8 buildings). `run_pipeline` injects the long description automatically when the slug matches; falls back to the bare slug otherwise.
- **Docs:** `.cursor/skills/gen3d/SKILL.md` now contains the exact "add a new character" procedure and a copy-paste Cursor prompt template.
