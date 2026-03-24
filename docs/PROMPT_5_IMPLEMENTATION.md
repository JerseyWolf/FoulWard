# PROMPT 5 IMPLEMENTATION

Date: 2026-03-24

## Implemented

- Implemented data-driven DoT support for building projectiles:
  - Added `calculate_dot_tick(...)` to `res://autoloads/damage_calculator.gd`.
  - Added DoT exports to `res://scripts/resources/building_data.gd`:
    - `dot_enabled`, `dot_total_damage`, `dot_tick_interval`, `dot_duration`
    - `dot_effect_type`, `dot_source_id`, `dot_in_addition_to_hit`
- Added enemy-local DoT system in `res://scenes/enemies/enemy_base.gd`:
  - `active_status_effects` state list on each enemy (no new autoload).
  - Public API `apply_dot_effect(effect_data: Dictionary)`.
  - Burn stacking: one per `source_id`, refresh duration, keep max `dot_total_damage`.
  - Poison stacking: additive, capped by `MAX_POISON_STACKS`.
  - Tick update driven from `EnemyBase._physics_process(delta)`.
- Updated `res://scenes/projectiles/projectile_base.gd`:
  - `initialize_from_building(...)` now receives DoT parameters at the end.
  - Fire/poison projectiles can apply instant-hit plus DoT (or DoT-only via flag).
- Updated `res://scenes/buildings/building_base.gd` to pass DoT fields from `BuildingData`.
- Tuned building resources with conservative defaults:
  - `res://resources/building_data/fire_brazier.tres`
  - `res://resources/building_data/poison_vat.tres`
  - Using numeric values equivalent to approximately 75% of one base hit over full DoT duration.
- Added/updated tests:
  - `res://tests/test_damage_calculator.gd` (DoT tick behavior).
  - `res://tests/test_enemy_dot_system.gd` (tick damage, immunities, burn refresh, poison cap).
  - `res://tests/test_projectile_system.gd` (DoT integration + expanded initialize signature coverage).

## Verification Notes

- Full suite summary reached green at the test-case level:
  - `329 tests cases | 0 errors | 0 failures`
- CLI process can still return non-zero (`101`) due GdUnit warning exit when orphan nodes are present; this is independent from Prompt 5 gameplay logic correctness.
