# Project Index Build Tasks

This file breaks index generation into small, verifiable tasks so updates stay accurate.

## Task 1: Inventory scope and source of truth
- Confirm first-party scope: `autoloads/`, `scripts/`, `scenes/`, `ui/`.
- Exclude `addons/`, `MCPs/`, and `tests/` from per-script API sections.
- Use `project.godot` as source of truth for autoload registrations.

## Task 2: Build compact index (`INDEX_SHORT.md`)
- List autoloads (name -> path).
- List first-party script files.
- List scene files.
- List resource class scripts.
- List resource instances grouped by folder.

## Task 3: Build full index (`INDEX_FULL.md`)
- Add SignalBus registry with payload signatures.
- For each first-party script include:
  - path, class name, purpose,
  - public methods (non-underscore) with signatures and plain-English behavior,
  - exported variables and what they are used for,
  - signals emitted and emission conditions,
  - major dependencies.
- Add resource class field reference for all resource scripts under `scripts/resources/`.

## Task 4: Consistency pass
- Ensure every listed file still exists.
- Ensure method/signature names match current code.
- Ensure all autoload entries in `project.godot` are represented in `INDEX_SHORT.md`.

## Task 5: Ongoing maintenance rule
- Update `INDEX_SHORT.md` and `INDEX_FULL.md` whenever:
  - a new first-party script/scene/resource is added,
  - a public method is added/removed/renamed,
  - an `@export` variable is added/removed/renamed,
  - a SignalBus signal is added/removed/renamed,
  - autoload registration changes.

## Task Update Log (2026-03-24)
- Added `docs/PROMPT_1_IMPLEMENTATION.md` with concrete implementation notes.
- Updated indexes for new BuildMenu sell-mode API and BuildMode input routing changes:
  - `InputManager` now routes hex-slot clicks by occupancy.
  - `BuildMenu` now supports placement mode + sell mode entrypoints.
  - `HexGrid` slot click callback no longer opens menu directly.
- Added HexGrid sell-flow test cases and reflected them in index notes.
- Added `docs/PROMPT_2_IMPLEMENTATION.md` with Phase 2 firing-system implementation notes.
- Indexed new `WeaponData` assist/miss fields and Tower manual-shot aim resolution behavior.
- Recorded new tests covering manual assist cone snap, miss perturbation, and autofire bypass.
- Added `docs/PROMPT_3_IMPLEMENTATION.md` with deterministic weapon-upgrade station integration notes.
- Added new indexed artifacts for Phase 3:
  - `res://scripts/resources/weapon_level_data.gd`
  - `res://scripts/weapon_upgrade_manager.gd`
  - `res://resources/weapon_level_data/*.tres` (6 level files)
  - `SignalBus.weapon_upgraded(...)`
  - `BetweenMissionScreen` Weapons tab
  - `res://tests/test_weapon_upgrade_manager.gd`
- Added Phase 4 indexed artifacts:
  - `res://autoloads/enchantment_manager.gd` (new autoload)
  - `res://scripts/resources/enchantment_data.gd` (new resource class)
  - `res://resources/enchantments/*.tres` (new enchantment data instances)
  - `SignalBus.enchantment_applied(...)`, `SignalBus.enchantment_removed(...)`
  - `Tower` projectile enchantment composition path updates
  - `BetweenMissionScreen` enchantment apply/remove controls in `WeaponsTab`
  - `res://tests/test_enchantment_manager.gd`
  - `res://tests/test_tower_enchantments.gd`
  - new regression in `res://tests/test_projectile_system.gd`
- Added Phase 5 indexed artifacts:
  - `DamageCalculator.calculate_dot_tick(...)` now implemented.
  - `EnemyBase.apply_dot_effect(effect_data: Dictionary)` added.
  - `BuildingData` DoT exports added (`dot_*` fields).
  - `ProjectileBase.initialize_from_building(...)` signature expanded for DoT parameters.
  - Added `res://tests/test_enemy_dot_system.gd`.
  - Updated `res://tests/test_projectile_system.gd` with fire/poison DoT integration checks.
- Added Phase 6 indexed artifacts:
  - `res://scenes/buildings/building_base.tscn` now includes `BuildingCollision` and `NavigationObstacle`.
  - `res://scenes/buildings/building_base.gd` now exposes base-area obstacle tuning constants + setup helpers.
  - `res://scenes/enemies/enemy_base.gd` now includes ground/flying split process and stuck-prevention helpers.
  - `res://tests/test_enemy_pathfinding.gd` now includes integration pathing scenarios.
  - `res://tests/test_building_base.gd` now verifies collision/obstacle node presence and layer/mask values.
