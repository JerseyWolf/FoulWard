# Gen3D and generated art — local-only trees

**Norm (2026-04-21):** Bulky or experimental **2D and 3D** pipeline output stays **out of Git** and **out of Cursor indexing** until production assets are chosen. Tracked policy and scripts live in-repo; binaries and Godot imports do not.

## What is gitignored / cursorignored

| Path | Contents |
|------|----------|
| **`local/gen3d/`** | Comfy/TRELLIS scratch: `staging/`, `logs/`, optional `ab_test/` (A/B harness) |
| **`art/generated/`** | Godot drop zone: `{enemies,allies,buildings,bosses,misc,meshes,icons}/` — `.glb`, textures, `.import`, `generation_log.json` |
| **`art/gen3d_previews/`** | Reference PNGs from batch gen3d (`fw_<unit>_ref.png`, etc.) |
| **`art/gen3d_candidates/`** | Per-slug mesh variants (`candidate_*_decimated.glb`, `selected.glb`, `meta.json`) |

Each of those directories has a **tracked `.gitkeep`** so the folder exists on fresh clones; populate locally with `foulward_gen.py` or manual drops.

Listed in **`.gitignore`** and **`.cursorignore`**.

## Layout (`local/gen3d/`)

| Subpath | Purpose |
|---------|---------|
| `staging/` | Pipeline scratch from `foulward_gen.py`: `fw_<slug>_ref.png`, front/clean PNGs, `fw_<slug>_candidates/`, rig/final GLB scratch |
| `logs/` | e.g. `comfyui.log` from `generate_all.sh` |
| `ab_test/` | Optional TRELLIS input-format experiments (CSV, `FINAL_REPORT.md`, per-slug variants) |

## Drop-zone semantics (from former `art/generated/` READMEs)

**`res://art/generated/icons/`** — Drop zone for AI-generated or scripted icon `.png` files. Files follow icon naming convention. Priority: checked first before `res://art/icons/` by the helper. No code changes needed when adding files.

**`res://art/generated/meshes/`** — Drop zone for AI-generated or procedurally generated mesh files that override manual placeholders. Files: `.glb` or `.tres` Mesh resources, same naming as `res://art/meshes/`. `ArtPlaceholderHelper` checks this folder first before `res://art/meshes/`. Populate via Blender scripts (`tools/generate_meshes.py`), API scripts, or trimesh generators as documented in tooling.

## Agent / operator rules

1. **Do not** commit large PNG/GLB under `art/generated/`, `art/gen3d_previews/`, `art/gen3d_candidates/`, or `local/gen3d/` — regenerate locally after clone.
2. **Do not** remove these paths from `.gitignore` / `.cursorignore` without a maintainer decision (e.g. Git LFS).
3. **Do not** use `/tmp/` for Foul Ward gen3d bulk output — use `local/gen3d/` (see `.cursor/skills/gen3d/SKILL.md`).
4. **`foulward_gen.py`** still **drops** final `{slug}.glb` into `art/generated/...` at runtime; that path is simply **not versioned**.

## Related

- `.cursor/skills/gen3d/SKILL.md` — full pipeline
- `tools/gen3d/foulward_gen.py` — orchestrator; uses `local/gen3d/staging/` for intermediates
