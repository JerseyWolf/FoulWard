# PROMPT 6 IMPLEMENTATION

Date: 2026-03-24

## Scope completed

- Implemented solid building footprint + navigation obstacle for ground-enemy routing.
- Preserved flying-enemy direct steering behavior that ignores ground obstacles.
- Added pathing regression tests in `res://tests/test_enemy_pathfinding.gd`.
- Added building-scene structure assertion in `res://tests/test_building_base.gd`.

## Files changed

- `res://scenes/buildings/building_base.tscn`
  - Added `BuildingCollision` (`StaticBody3D`) with `CollisionShape3D` using `BoxShape3D`.
  - Added `NavigationObstacle` (`NavigationObstacle3D`) with avoidance enabled and no navmesh baking.
- `res://scenes/buildings/building_base.gd`
  - Added centralized footprint/obstacle tuning constants.
  - Added `_configure_base_area()`, `_enable_collision_and_obstacle()`, `_disable_collision_and_obstacle()`.
  - `_ready()` now configures footprint and enables obstacle/collision.
- `res://scenes/hex_grid/hex_grid.gd`
  - Added `_activate_building_obstacle(building: BuildingBase) -> void` hook.
  - Placement flow now calls `_activate_building_obstacle(...)` after adding a building.
- `res://scenes/enemies/enemy_base.tscn`
  - Updated enemy collision mask to include Tower + Arnulf + Buildings + Ground.
  - Updated `NavigationAgent3D` defaults for target and avoidance tuning.
- `res://scenes/enemies/enemy_base.gd`
  - Split movement into `_physics_process_ground()` and `_physics_process_flying()`.
  - Added stuck-prevention progress tracking constants + helpers.
  - Ground enemies now rely on `NavigationAgent3D` path-following and periodic re-target for stuck recovery.
  - Flying enemies still move on direct vector steering toward tower flight height.
- `res://tests/test_enemy_pathfinding.gd`
  - Replaced with scenario tests validating:
    - Ground enemies reach tower with full inner ring.
    - Baseline no-building behavior remains intact.
    - Flying enemies still reach tower and move tower-ward in XZ.
    - Selling/clearing re-opens routes.
    - Alternating ring obstacles do not cause indefinite stuck behavior.
- `res://tests/test_building_base.gd`
  - Added test that scene contains `BuildingCollision` + `NavigationObstacle` with expected layer/mask setup.

## PRE_GENERATION verification checkpoints (explicit)

- Physics layers/masks:
  - Buildings are on layer 4 (`collision_layer = 8` bitmask).
  - Enemy mask now includes tower/buildings/arnulf and keeps ground (`45` bitmask).
  - Hex slots remain `Area3D` on layer 7 (`64` bitmask) in `hex_grid.tscn`.
  - Projectile collision rules were not changed.
- Navigation system:
  - No new `NavigationRegion3D` was added.
  - Existing `Ground/NavigationRegion3D` remains the sole navmesh region in `main.tscn`.
  - No runtime navmesh rebake was added.
  - Buildings contribute dynamic avoidance via `NavigationObstacle3D`.
- SignalBus + manager APIs:
  - No new SignalBus signals were introduced.
  - Existing `building_placed/sold/upgraded` semantics in `HexGrid` remain unchanged.

## Tuning assumptions

- Building footprint: `2.5 x 3.0 x 2.5` via `BoxShape3D`.
- Obstacle radius: `2.0`.
- Enemy stuck heuristics:
  - `STUCK_TIME_THRESHOLD = 1.5`
  - `STUCK_VELOCITY_EPSILON = 0.1`
  - `PROGRESS_EPSILON = 0.05`

