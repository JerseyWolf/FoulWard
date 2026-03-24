# PROMPT 2 IMPLEMENTATION

Date: 2026-03-24

## Prompt Inspiration Summary

This Phase 2 implementation was directly shaped by a prior design/research prompt that defined the firing-extension rules before coding started. That upstream prompt established the core boundaries used here: keep `InputManager` logic-free, keep Tower public firing APIs and `ProjectileBase.initialize_from_weapon(...)` unchanged, place assist/miss behavior inside Tower only, gate all assist/miss to manual fire only, and preserve deterministic autofire/SimBot behavior. It also drove the data-model approach (new `WeaponData` fields with safe `0.0` defaults), the initial crossbow tuning targets, and the specific test expectations around assist cone selection, miss perturbation, and autofire bypass.

## Implemented

- `res://scripts/resources/weapon_data.gd`
  - Added new tuning fields:
    - `assist_angle_degrees: float = 0.0`
    - `assist_max_distance: float = 0.0`
    - `base_miss_chance: float = 0.0`
    - `max_miss_angle_degrees: float = 0.0`
  - Added design constraint comment that `0.0` disables assist/miss and restores MVP behavior.

- `res://resources/weapon_data/crossbow.tres`
  - Set starting tuning defaults:
    - `assist_angle_degrees = 7.5`
    - `assist_max_distance = 0.0`
    - `base_miss_chance = 0.05`
    - `max_miss_angle_degrees = 2.0`

- `res://resources/weapon_data/rapid_missile.tres`
  - Explicitly left all new assist/miss fields at `0.0` to preserve deterministic MVP behavior.

- `res://scenes/tower/tower.gd`
  - Added private helper:
    - `_resolve_manual_aim_target(weapon_data: WeaponData, raw_target: Vector3) -> Vector3`
  - Applied helper in:
    - `fire_crossbow(target_position: Vector3)`
    - `fire_rapid_missile(target_position: Vector3)`
  - Kept public signatures unchanged.
  - Kept `ProjectileBase.initialize_from_weapon(...)` contract unchanged.
  - `SignalBus.projectile_fired` now emits the final adjusted target so observers/tests match projectile behavior.

- `res://tests/test_simulation_api.gd`
  - Added coverage for:
    - new `WeaponData` field defaults (`0.0`)
    - crossbow `.tres` Phase 2 defaults load check
    - no-assist/no-miss raw target passthrough
    - assist cone snap to nearest valid enemy
    - guaranteed miss perturbation (`base_miss_chance = 1.0`)
    - `auto_fire_enabled == true` bypasses assist/miss logic

## Phase 2 Behavior Notes

### Auto-aim helper

- Runs only in manual shot path (`auto_fire_enabled == false`).
- Searches enemies from `get_tree().get_nodes_in_group("enemies")`.
- Filters candidates by:
  - instance validity
  - alive status (`health_component.is_alive()`)
  - weapon targeting rules (`can_target_flying` vs `enemy_data.is_flying`)
  - assist cone (`raw_dir.angle_to(to_enemy)` compared against `assist_angle_degrees`)
  - optional max distance (`assist_max_distance > 0.0`)
- Chooses nearest valid enemy inside cone and snaps target to that enemy position.

### Miss perturbation helper

- Runs after assist, only in manual shot path.
- Miss logic enabled only when:
  - `base_miss_chance > 0.0`
  - `max_miss_angle_degrees > 0.0`
- Rolls miss chance, then perturbs aim direction with a bounded angular rotation and converts direction back into a target position.
- Includes inline `# SOURCE` note for Godot Vector3/Basis rotation pattern.

Use a project-approved deterministic RNG source (for example, a Tower-owned `RandomNumberGenerator` or a shared game RNG) instead of global `randf()`. This RNG must be seedable so automated tests and SimBot can reproduce shot patterns when they set a known seed.

## Configuration and rollback

- All assist/miss tuning is data-driven via `WeaponData` fields in `.tres`.
- To fully restore crossbow MVP behavior, set these four fields back to `0.0` in `res://resources/weapon_data/crossbow.tres`:
  - `assist_angle_degrees`
  - `assist_max_distance`
  - `base_miss_chance`
  - `max_miss_angle_degrees`
- The `7.5 / 0.05 / 2.0` values are starting defaults for play-feel and are expected to be tuned in balancing passes.

## Testing notes

- Existing Tower/SimBot tests remain valid because:
  - auto-fire path bypasses assist/miss
  - all new fields default to `0.0` in code
  - rapid missile `.tres` remains deterministic by default
- Added targeted tests using in-memory `WeaponData.new()` tuning overrides for deterministic setup.

For miss-related tests, set a known RNG seed (via the same deterministic RNG used in Tower) when you need exact projectile directions to be reproducible; otherwise, assert only that directions are within the allowed angular bounds and differ from the raw aim.

