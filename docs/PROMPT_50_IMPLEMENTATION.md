# PROMPT 50 — TD content authoring pass

**Date:** 2026-03-30  
**Scope:** Data-heavy content: `BuildingData` / `EnemyData` schema, `Types` enums, 36 building + 30 enemy `.tres`, 5 `AllyData` stubs, 18 new research nodes, registry wiring, parametric unit tests.

## Files changed (summary)

| Path | Change |
|------|--------|
| `scripts/types.gd` | Appended `BuildingType` 8–35, `EnemyType` 6–29 |
| `scripts/resources/building_data.gd` | `size_class` → `footprint_size_class` (enum); `aura_category` → `String`; `heal_targets` flags → `heal_target_flags`; `balance_status` → `String`; new authoring block (`size_class`, `role_tags`, summoner paths, `heal_per_tick`, `aura_effect_*`, upgrade arrays, `duplicate_cost_k`) |
| `scripts/resources/enemy_data.gd` | `point_cost`, `wave_tags`, `tier`, `special_tags`, `special_values`, `balance_status` |
| `scenes/hex_grid/hex_grid.gd` | Registry size 36; combat stats uses string `BuildingData.size_class` |
| `autoloads/combat_stats_tracker.gd` | `bd.size_class` string for building row |
| `scripts/wave_manager.gd` | Registry size **30** (one per `EnemyType`) |
| `scripts/art/art_placeholder_helper.gd` | `_get_building_token` / `_get_enemy_token` from enum keys |
| `scenes/main.tscn` | `p50_bd_*` / `p50_en_*` / `p50_rn_*` ext resources; full `building_data_registry`, `enemy_data_registry`, `research_nodes` |
| `scenes/buildings/building_base.gd` | Header comment (tower count) |
| `tests/test_wave_manager.gd` etc. | `_build_full_enemy_data()` loops all `EnemyType` |
| `tests/test_art_placeholders.gd` | Dynamic `res://.../{enum}.tres` load paths |
| `tests/unit/test_content_invariants.gd` | **New** — parametric `.tres` checks |
| `tools/run_gdunit_unit.sh` | Allowlist `test_content_invariants.gd` |
| `tools/gen_prompt50_assets.py` | One-off generator for 28 new buildings (optional retain) |
| `tools/gen_prompt50_enemies_allies_research.py` | One-off generator for enemies/allies/research |
| `resources/building_data/*.tres` | 8 updated + 28 new |
| `resources/enemy_data/*.tres` | 6 updated + 24 new |
| `resources/ally_data/*.tres` | 5 new stubs |
| `resources/research_data/*.tres` | 18 new nodes |

## Enum additions

- **BuildingType:** indices 8–35 (`SPIKE_SPITTER` … `CITADEL_AURA`) — **28** new values after `SHIELD_GENERATOR`.
- **EnemyType:** indices 6–29 (`ORC_SKIRMISHER` … `PLAGUE_HERALD`) — **24** new values after `BAT_SWARM`. **Total `EnemyType` size = 30** (not 36).

## New `.tres` counts

| Kind | New | Notes |
|------|-----|--------|
| Buildings | 28 | + 8 updated |
| Enemies | 24 | + 6 updated |
| Allies | 5 | `wolf_alpha`, `wolf_pup`, `bear_alpha`, `knight_captain`, `militia_archer` |
| Research | 18 | **24** total nodes on `ResearchManager` (6 legacy + 18 new) |

## `ResearchManager.research_nodes`

`main.tscn` lists **24** `ResearchNodeData` resources in this order:  
`base_structures_tree`, `unlock_anti_air`, `arrow_tower_plus_damage`, `unlock_shield_generator`, `fire_brazier_plus_range`, `unlock_archer_barracks`, then the 18 new `unlock_*.tres` files from Step 6.

## Test suite

- **`./tools/run_gdunit_unit.sh`:** **324** test cases, **0** failures (prior run before this doc: **320** cases — **+4** from `test_content_invariants.gd`).
- Exit **101** (warnings/orphans) treated as pass per project scripts.

## Fields already present vs added

- **BuildingData:** Existing summoner/aura/healer blocks kept; renamed `size_class`→`footprint_size_class`, `heal_targets`→`heal_target_flags`, `aura_category` enum→`String`, `balance_status` enum→`String`. Added Prompt 50 block (`role_tags`, string `size_class`, path-based summon fields, `heal_per_tick`, upgrade arrays, etc.).
- **EnemyData:** New block appended; no prior `point_cost`/`wave_tags`/`tier`.

## Assumptions / TODOs

- **Summoner runtime:** Data paths (`summon_*_data_path`) and `summon_squad_size` are authored; full spawn pipeline hook-up is a future prompt.
- **Enemy registry size:** Prompt text said “36” for enemies; **actual `EnemyType` count is 30** — `WaveManager` and tests use **30**.
- **`building_id`:** `CombatStatsTracker` already prefers `building_id` for analytics; existing/new towers set `building_id` where applicable.
- **Generators:** `tools/gen_prompt50_*.py` can be removed after review; kept for reproducibility.

## Path corrections

- `ember_vent.tres`: `unlock_research_id` left empty (not gated by frost pinger).
- Research-gated buildings: `is_locked = true` when `unlock_research_id` is non-empty (batch fix).
