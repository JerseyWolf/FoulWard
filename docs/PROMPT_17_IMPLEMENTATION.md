## Prompt 17 — Art Placeholder Pipeline Scaffolding (implementation log)

### 2026-03-25 (work so far)

Implemented Prompt 17 scaffolding:

1. **Canonical `res://art/` hierarchy + pipeline READMEs**
   - Created `res://art/meshes/{enemies,buildings,allies,misc}/`
   - Created `res://art/materials/{factions,types}/`
   - Created `res://art/icons/{buildings,enemies,allies}/`
   - Created `res://art/generated/{meshes,icons}/`
   - Added `README_ART_PIPELINE.md` files to every leaf folder to document
     naming conventions, fallbacks, and art-source tooling expectations.

2. **`ArtPlaceholderHelper` (convention-based art resolver)**
   - Added `res://scripts/art/art_placeholder_helper.gd` as `ArtPlaceholderHelper`
   - Provides cached resolution of placeholder `Mesh` and `Material` assets
   - Prefers `res://art/generated/` overrides (POST-MVP drop zone)
   - Falls back to `unknown_mesh.tres` and neutral faction material on missing assets
   - ICON methods are present but POST-MVP stubbed (return `null`)

3. **Primitive placeholder `.tres` resources**
   - Added required mesh primitives under `res://art/meshes/` (enemy/building/ally/misc)
   - Added required faction `StandardMaterial3D` materials under `res://art/materials/factions/`
   - Left `res://art/materials/types/` empty for later type-specific overrides

4. **Scene + runtime script wiring**
   - Updated scenes to reference `res://art/...` resources:
     - `res://scenes/enemies/enemy_base.tscn`
     - `res://scenes/tower/tower.tscn`
     - `res://scenes/arnulf/arnulf.tscn`
     - `res://scenes/buildings/building_base.tscn`
     - `res://scenes/projectiles/projectile_base.tscn`
     - `res://scenes/hex_grid/hex_grid.tscn`
   - Updated scripts to override visuals at runtime via `ArtPlaceholderHelper`:
     - `res://scenes/enemies/enemy_base.gd`
     - `res://scenes/buildings/building_base.gd`
     - `res://scenes/tower/tower.gd`
     - `res://scenes/arnulf/arnulf.gd`

5. **GdUnit4 test suite + quick runner allowlist**
   - Added `res://tests/test_art_placeholders.gd`
   - Updated `./tools/run_gdunit_quick.sh` to include the new suite

### Verification notes

- Fixed Godot primitive `.tres` serialization parsing:
  - Wrapped placeholder primitive properties in the required `[resource]` section for all `res://art/meshes/**/*.tres` and `res://art/materials/factions/*.tres`.
  - Matched Godot’s `StandardMaterial3D` serialization order (`shading_mode` then `albedo_color`).
  - Result: removed the “Parse Error: Unexpected end of file” messages for art placeholder resources during GdUnit discovery/runs.

- Made the art test suite headless/GdUnit-compatible:
  - `tests/test_art_placeholders.gd` now `preload()`s `res://scripts/art/art_placeholder_helper.gd` instead of relying on `class_name` global resolution.
  - Corrected invalid enum casting in fallback test (`Types.EnemyType = 999`) so the suite compiles under headless parsing.

- Verified:
  - `./tools/run_gdunit_quick.sh`: `257 tests cases | 0 errors | 0 failures | 0 orphans`.
  - `./tools/run_gdunit.sh`: `440 tests cases | 0 errors | 0 failures` (with some unrelated orphans from other suites, but no failures).

