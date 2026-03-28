# AUDIT 6 — Implementation log (2026-03-28)

## Workflow

1. Read `docs/ALL_AUDITS.md` §AUDIT 6 and `docs/AUDIT_CONTEXT_SUMMARY.md`.
2. Implemented features in order of dependency risk (spells → weapon structure → buildings → economy/territory).
3. After each batch: `./tools/run_gdunit_quick.sh` (expanded allowlist) and fixes.
4. Final: `./tools/run_gdunit.sh` — **485 test cases, 0 failures** (exit code 101 = warnings/orphans; script treats as pass per repo convention).

## Checklist by feature group

### Group 1 — Multi-spell system (§1.1) — **Done**

- [x] New `SpellData` resources: `slow_field.tres`, `arcane_beam.tres`, `tower_shield.tres` (+ existing `shockwave.tres`).
- [x] `SpellManager`: `_apply_slow_field`, `_apply_arcane_beam`, `_apply_tower_shield`; `cast_selected_spell`, `cycle_selected_spell`, `set_selected_spell_index`, `get_selected_spell_id`.
- [x] `EnemyBase`: slow status + `get_move_speed_slow_multiplier()`.
- [x] `Tower`: `add_spell_shield()` + shield absorption in `take_damage()`; `ProjectileContainer` via `get_node_or_null` for headless tests.
- [x] Input: `cast_selected_spell`, `spell_cycle_next` / `spell_cycle_prev`, `spell_slot_1`–`4`; `InputManager` casts selected spell (Space); legacy `cast_shockwave` still mapped.
- [x] `main.tscn` spell registry lists all four spells.
- [x] Tests: `tests/test_spell_manager.gd` extended.

### Group 2 — Structural weapon upgrades (§1.2) — **Done**

- [x] `WeaponLevelData`: `pierce_count_bonus`, `projectile_count_bonus`, `spread_angle_degrees_bonus`, `splash_radius_bonus`.
- [x] `WeaponUpgradeManager`: effective getters for pierce, projectile count, spread, splash.
- [x] `ProjectileBase`: pierce travel extension, splash AoE, closest-enemy-along-ray resolution for deterministic hits.
- [x] `Tower`: `fan_aim_points()`, multi-shot crossbow, passes pierce/splash into `initialize_from_weapon`.
- [x] Tests: `tests/test_weapon_structural.gd`.

### Group 3 — Archer Barracks & Shield Generator (§1.3) — **Done**

- [x] `BuildingData`: `special_pulse_interval`, `barracks_*`, `shield_*` fields.
- [x] `BuildingBase`: `_tick_archer_barracks`, `_tick_shield_generator` (null-`SceneTree` safe for bare-node tests).
- [x] `AllyBase`: `add_to_group("allies")`, barracks strike bonus + consumption on attack.
- [x] Updated `.tres` for barracks / shield generator.
- [x] Tests: `tests/test_building_specials.gd`.

### Group 4 — Generic ally combat (§2.1–2.3) — **Not completed**

- Planned: support auras, ranged `ProjectileBase`, DOWNED/RECOVERING, targeting flags, `starting_level` / `level_scaling_factor` tests. Only **barracks strike bonus** (support-style buff) was added as part of Group 3.

### Group 5 — Territory bonuses (§3.1–3.2) — **Partially done**

- [x] `GameManager`: `get_aggregate_flat_gold_per_kill`, `get_aggregate_*_cost_multiplier`, `get_aggregate_bonus_research_per_day`, `get_effective_faction_id_for_territory`.
- [x] `EconomyManager`: per-kill gold includes territory flat bonus.
- [x] `ResearchManager.unlock_node`: research cost × aggregate multiplier.
- [x] `EnchantmentManager.try_apply_enchantment`: gold × enchanting multiplier.
- [x] `WeaponUpgradeManager.upgrade_weapon`: gold × weapon-upgrade multiplier.
- [x] `GameManager._on_all_waves_cleared`: extra research material from territories.
- [x] `WaveManager._apply_faction_from_day_config`: empty `faction_id` → territory `default_faction_id` → `DEFAULT_MIXED`.
- [ ] Dedicated GdUnit cases for every multiplier vs `is_active_for_bonuses()` (extend `test_territory_economy_bonuses.gd` in a follow-up).

### Group 6 — Endless mode (§3.4) — **Not completed**

- Requires: new `GameState`, `GameManager` flow, `WaveManager` scaling, main menu entry, SimBot test.

### Group 7 — Save/load (§3.5) — **Not completed**

- Requires: `SaveManager` autoload, `Profile` resource, JSON round-trip tests.

### Group 8 — Generalized consumables (§4.1) — **Not completed**

- `_mana_draught_pending` / shop flow unchanged beyond economy hooks already present.

### Group 9 — Relationship system (§5.1) — **Not completed**

### Group 10 — SimBot handlers & difficulty (§6.1–6.2) — **Not completed**

### Group 11 — Art icons & Settings (§7.1–7.2) — **Not completed**

## Observations

- **Projectile hit order**: Sorting overlapping enemies by ray projection fixed splash/pierce determinism when multiple bodies overlap one step.
- **Shield / barracks without scene tree**: Special building ticks must return before using `get_tree()` so `test_building_base.gd` bare `BuildingBase` instances do not crash.
- **Full suite**: 485 cases; exit **101** from GdUnit (orphan-node / resource warnings) is treated as **pass** by `./tools/run_gdunit.sh`.

## Summary

| Metric | Value |
|--------|--------|
| Full suite result | **485 tests, 0 failures** (warnings only, exit 101 → pass) |
| New / materially extended test files this session | `test_spell_manager.gd`, `test_weapon_structural.gd`, `test_building_specials.gd` |
| Approx. new test cases added | **~11** (5 spell + 4 weapon structural + 2 building specials) |

Groups **1–3** and **part of 5** are implemented in code with tests; groups **4, 6–11** remain for a follow-up pass against the same AUDIT 6 checklist.

## Index / docs

- `tools/run_gdunit_quick.sh`: allowlist includes `test_spell_manager.gd`, `test_weapon_structural.gd`, `test_building_specials.gd`.
- Update `docs/INDEX_FULL.md` / `docs/INDEX_SHORT.md` in the same commit as this file if merging to main.
