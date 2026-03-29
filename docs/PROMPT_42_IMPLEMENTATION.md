# Prompt 42 — TD core Resource definitions + projectile PackedScene

## Summary (2026-03-29 — data resources)

Extended and aligned core `Resource` scripts with the tower-defense data spec: typed exports, new `Types` enums (`AllyCombatRole`, `SummonLifetimeType`, `AuraModifierOp`, `BuildingSizeClass` SMALL/MEDIUM/LARGE, `EnemyBodyType` SIEGE/ETHEREAL), `BuildingData.projectile_scene` as `PackedScene`, `RoutePathData.curve3d_path` as `NodePath`, `MissionEconomyData.duplicate_cost_k_override` default `-1.0`, and `AllyData` `id` / `damage` / `target_flags` / `role: AllyCombatRole`. Wired minimal compile-safe consumers (`BuildingBase`, `EconomyManager`, `CampaignManager`, `WaveManager`, example `.tres`, unit tests).

## Earlier sub-topic — Arrow Tower projectile validation

Runtime hardening: `_get_validated_default_projectile_packed_scene()` and `can_instantiate()` checks before `PackedScene.instantiate()`. `arrow_tower.tres` now references the projectile via `ExtResource` `PackedScene`.

## Files changed (resource session)

- `scripts/types.gd` — enums as above; retain `AllyRole` / `AuraModifierKind` for legacy references.
- `scripts/resources/building_data.gd` — `projectile_scene: PackedScene`, `summon_type: SummonLifetimeType`, `aura_modifier_type: AuraModifierOp`.
- `scripts/resources/ally_data.gd` — `id`, `damage`, `target_flags`, `role: AllyCombatRole`, `summon_type`, `aura_modifier_type`, `get_range()`, `get_identity()` order.
- `scripts/resources/enemy_data.gd` — `scene_path`, `get_target_flag_bits()` for SIEGE/ETHEREAL.
- `scripts/resources/path_data.gd` — `curve3d_path: NodePath`, extended `body_types_allowed` flags.
- `scripts/resources/mission_economy_data.gd` — `duplicate_cost_k_override` default `-1.0`, validation.
- `scripts/mission_spawn_routing.gd` — doc comment for bitmask ordinals.
- `scenes/buildings/building_base.gd` — resolve `PackedScene` override directly.
- `autoloads/economy_manager.gd` — duplicate k override when `>= 0.0`.
- `autoloads/campaign_manager.gd` — `_role_alignment_score` uses `AllyCombatRole`.
- `scripts/wave_manager.gd` — `str(curve3d_path)` for `NodePath`.
- `resources/building_data/arrow_tower.tres` — `load_steps` + `ExtResource` projectile.
- `resources/ally_data/anti_air_scout.tres` — `role = 1` (RANGED) under `AllyCombatRole`.
- `resources/examples/prompt35/mission_routing_example.tres` — `NodePath` curve paths.
- `tests/unit/test_td_resource_helpers.gd` — `NodePath`, identity/range tests.

## Assumptions

- `RoutePathData` remains the registered `class_name` (Godot built-in `PathData` conflict).
- `attack_range` on buildings/allies is the authoring stand-in for the reserved keyword `range`; `get_range()` is provided where useful.
- `BuildingSizeClass` retains legacy `SINGLE_SLOT` / `DOUBLE_WIDE` / `TRIPLE_CLUSTER` and appends SMALL/MEDIUM/LARGE for ring tiers.
- Ethereal enemies are classified as “air” for `target_flags` bit matching until gameplay defines a dedicated bit.

## TODOs

- Gameplay: consume `AllyData.damage`, `target_flags`, `EnemyData.scene_path`, aura `AuraModifierOp`, and summon `SummonLifetimeType` in combat/AI.
- Migrate any remaining `.tres` that stored `projectile_scene` as a string (only `arrow_tower.tres` was updated in-repo).
- Revisit `CampaignManager` strategy scoring for `BOMBER` / `AURA` vs old `AllyRole` semantics if SimBot tuning requires it.
