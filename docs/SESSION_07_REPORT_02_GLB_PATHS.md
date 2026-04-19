# Session 07 — Report 02: GLB Path Table

**Generated:** 2026-04-19 (from `scripts/art/rigged_visual_wiring.gd`). All generated asset paths use **`res://art/generated/...`** unless noted.

## Convention

- **Enemies:** `res://art/generated/enemies/<snake_case_enum>.glb` (30 `EnemyType` values — see match in code).
- **Bosses:** `res://art/generated/bosses/<boss_id>.glb` — `plague_cult_miniboss`, `orc_warlord`, `final_boss`, `audit5_territory_mini`.
- **Allies:** `res://art/generated/allies/<ally_id>.glb` — `arnulf`, `archer`, `knight`, `swordsman`, `barbarian`.
- **Buildings:** `res://art/generated/buildings/<token>.glb` — 36 arms (`arrow_tower` … `citadel_aura`).
- **Tower (Florence):** `res://art/characters/florence/florence.glb` (`tower_glb_path()`).

## Hub portraits (2D)

Per art pipeline: `res://art/icons/characters/{character_name}.png` (lowercase file stems as needed).

## Enemy coverage

All 30 `Types.EnemyType` values from `ORC_GRUNT` through `PLAGUE_HERALD` resolve to a non-empty path in `enemy_rigged_glb_path()`; unknown enum values return `""`.

## Sybil / tower

Sybil shares tower/hub rig expectations with Florence for combat lines; primary rig path for the player tower is `tower_glb_path()` above.

## Maintenance

When adding a new `EnemyType` or `BuildingType`, extend the `match` in `rigged_visual_wiring.gd` and re-run `tools/validate_art_assets.gd` in the Godot editor.
