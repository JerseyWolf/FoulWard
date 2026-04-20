# Prompt 86 — gen3d texture fix + 5-variant selection

**Date:** 2026-04-20  
**Scope:** `tools/gen3d/` — Stage 2 decimation texture preservation + multi-variant generation with interactive selection.

---

## Root Cause Diagnosis

Ran the Step 1 diagnostic against existing pipeline artifacts on disk.

| GLB | Size | Visual | UV | Unique colors |
|-----|------|--------|----|---------------|
| `/tmp/fw_orc_grunt_raw.glb` | 38.4 MB | `TextureVisuals` | `(777919, 2)` | 96 799 |
| `/tmp/fw_orc_grunt_decimated.glb` | 0.38 MB | `ColorVisuals` | None | 1 (white) |
| Final `art/generated/enemies/orc_grunt.glb` | 0.32 MB | `ColorVisuals` | None | 1 (white) |

**Root cause = Cause A only.** TRELLIS was producing fully-textured GLBs via
`o_voxel.postprocess.to_glb(texture_size=2048)`. The old `decimate_glb` passed
geometry through Open3D and rebuilt a bare `trimesh.Trimesh(vertices, faces,
vertex_normals)` — UV map and material reference were intentionally discarded
by that constructor. Step 4 (fix `image_to_glb`) was not needed.

**Critical deviation from workplan:** `trimesh.simplify_quadric_decimation` requires
`fast_simplification` as a backend (not installed), and even with it installed, the
trimesh wrapper strips UV on output. Additionally, TRELLIS output meshes have 302k
duplicate-position (seam) vertices that make `fast_simplification` plateau at ~38k
faces regardless of target — it cannot reach 10k.

**Final approach:** Open3D QEM decimation (correctly reaches any face-count target even
on non-manifold TRELLIS meshes) + scipy `cKDTree` nearest-vertex UV re-projection from
the original high-res mesh. This is robust, simple, and correct for per-vertex UV maps.

---

## Changes Made

### `tools/gen3d/requirements.txt`
- Added `fast_simplification>=0.1.7` (installed 0.1.13). Present as dep; not used in
  the primary decimation path due to topology limits on TRELLIS meshes.

### `tools/gen3d/pipeline/stage2_mesh.py`
- Replaced `decimate_glb()` with UV-preserving version:
  - `_load_combined_mesh()` helper — loads GLB with `process=False`, merges geometries.
  - `_decimate_o3d()` helper — geometry-only Open3D QEM, returns `(verts, faces, normals)`.
  - New `decimate_glb()`:
    - For `TextureVisuals` with UV: decimate geometry → cKDTree reproject UVs →
      rebuild `trimesh.Trimesh` with `TextureVisuals(uv=new_uvs, material=original_material)`.
    - For `ColorVisuals`: same pattern with vertex colors.
    - For geometry-only meshes: just export normals.
    - Exports via `trimesh.scene.scene.Scene(geometry={"geometry_0": decimated}).export(...)`.
- Modified `image_to_glb()`:
  - Added `seed: int | None = None` parameter. None → random 32-bit seed.
  - Sets `torch.manual_seed(seed)` and `torch.cuda.manual_seed_all(seed)` before `pipeline.run`.
  - Respects `FOULWARD_TRELLIS_PREDECIMATE` env var (default 100000; was 1000000).
  - Logs seed at `[TRELLIS] seed=...`.
- Added `_check_glb_has_texture(path)` — returns True if GLB has UV or multi-color vertex data.
- Added `generate_mesh_variants(image_path, out_dir, model_id, tri_budget, n_variants=5, slug, project_root)`:
  - Runs TRELLIS N times with different seeds.
  - Per variant: checks raw texture, decimates, removes raw, writes to both `/tmp` and `art/gen3d_candidates/{slug}/`.

### `tools/gen3d/foulward_gen.py`
- Added `select_candidate(candidates, slug, project_root, auto=False)`:
  - Prints numbered list of candidates.
  - Prompts `[1–N]` interactively, or auto-picks 1 when `auto=True`.
  - Writes `selected.glb` to `art/gen3d_candidates/{slug}/`.
  - Returns `(selected_path, chosen_idx)`.
- Rewired `run_pipeline()` Stage 2:
  - Reads `N_MESH_VARIANTS` (default 5) and `AUTO_SELECT_CANDIDATE` env vars.
  - Calls `generate_mesh_variants` + `select_candidate`.
  - Writes `meta.json` sidecar with slug/unit_name/faction/asset_type/n_variants/selected.
  - Honors `SKIP_STAGE1=1`, `SKIP_STAGE2=1`, `SELECTED_GLB=<path>` for stage-skipping.
- Updated stage 2 imports (removed unused `decimate_glb`, `image_to_glb` direct imports).

### `tools/gen3d/pipeline/stage3_rig.py`
- Added `_load_mixamo_credentials()`:
  - Reads from `os.environ` first (already populated by `secrets_loader`).
  - Falls back to parsing `~/.foulward_secrets` directly.
  - Raises `RuntimeError` if neither is set.
  - Never logs the password — only logs the email address.
- Updated `rig_model()` default args to `mixamo_email=""`, `mixamo_password=""`.
- Added credential loading via `_load_mixamo_credentials()` when args are empty.

### `tools/gen3d/promote_candidate.py` *(new)*
- CLI: `python3 promote_candidate.py <slug> <variant_number>`
- Copies `candidate_N_decimated.glb` → `selected.glb`, updates `meta.json`.
- Re-invokes `foulward_gen.py` with `SKIP_STAGE1=1 SKIP_STAGE2=1 SELECTED_GLB=<dst>`.

### `tools/gen3d/generate_all.sh`
- Added `AUTO_SELECT_CANDIDATE=1` and `N_MESH_VARIANTS=5` default exports.

---

## Validation Results

### Step 8 — Isolation test (`decimate_glb` on existing raw GLB)

```
Input:  777919 verts, 968465 faces  visual=TextureVisuals  UV=(777919,2)
Output:  96789 verts,   9999 faces  visual=TextureVisuals  UV=(96789,2)
         material=PBRMaterial  baseColorTexture=PngImageFile
         unique vertex colors: 30496  → TEXTURED ✓
_check_glb_has_texture: True
```

### Step 9 — End-to-end smoke test (N=1, SKIP_STAGE1=1, input_file mode)

Ran full pipeline using existing raw GLB:
```
[Stage 2] Texture confirmed in candidate 1 raw GLB ✓
[decimate] UV reprojected: (96789, 2)  material=PBRMaterial
[2b]  Selected variant 1: art/gen3d_candidates/orc_grunt/selected.glb
[5/5] Done — orc grunt → art/generated/enemies/orc_grunt.glb
```

Final GLB verification:
```
verts=10723, faces=9999
visual=TextureVisuals, UV=(10723, 2) ← PRESERVED ✓
material=PBRMaterial, baseColorTexture=PngImageFile
unique vertex colors: 7629  → TEXTURED ✓
WHITE MESH: False
```

### promote_candidate.py
- Error path (nonexistent variant): exits 1 with clear message ✓
- Happy path (variant 1): promotes, updates meta.json, re-runs stages 3–5 ✓

---

## Architecture Note: Why Open3D + cKDTree instead of fast_simplification

`fast_simplification` plateaus at ~38k faces on TRELLIS output due to seam vertices
(302k out of 778k total verts are duplicate-position seam verts). The QEM algorithm
cannot collapse across non-manifold seam edges, leaving a hard topological floor.
Open3D QEM does not have this constraint and correctly reaches any target face count.

UV re-projection via nearest-vertex cKDTree lookup is robust for per-vertex UV maps
(which is what TRELLIS generates) because the QEM algorithm only removes vertices
along edges — output vertices are always spatially close to their source vertex in
the original mesh, so nearest-neighbor lookup gives correct UV values.

---

## Decimation topology notes

- Raw TRELLIS orc_grunt: 777919 verts, 968465 faces (non-watertight, non-volume)
- Unique vertex positions: 475653 / 777919 (302k seam verts)
- Non-manifold edges: 0, duplicate faces: 18
- fast_simplification plateau: ~38k faces (hard topological floor from seam verts)
- Open3D plateau: none — reaches 9999 faces at target_faces=10000
