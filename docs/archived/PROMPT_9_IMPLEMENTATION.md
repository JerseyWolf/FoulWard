# PROMPT_9_IMPLEMENTATION — Faction system + weighted waves + mini-boss hooks

Updated: 2026-03-24.

## Phase 0 (verification)

- **CONVENTIONS.md / ARCHITECTURE.md**: followed for naming (`snake_case` files, `FactionData` class_name, simulation API).
- **Pre-generation docs**: **`docs/PRE_GENERATION_VERIFICATION.md`** (short checklist) and **`docs/PRE_GENERATION_SPECIFICATION.md`** (full reference tables and stubs).
- **Autoload order** (`project.godot`): `SignalBus`, `CampaignManager`, `GameManager`, `EconomyManager`, `DamageCalculator`, … — matches architecture (CampaignManager before GameManager).
- **GdUnit**: full suite via `./tools/run_gdunit.sh` — **349 cases, 0 failures**, **24** suites (2026-03-24 polish run; `run_gdunit.sh` may exit **101** with warnings treated as pass).

## Phase 1 — Prior wave behavior (summary)

WaveManager previously spawned **exactly `wave_number` of each of the six `EnemyData` entries** (total **`wave_number × 6`**), at random `SpawnPoints`, with per-day stat multipliers from `configure_for_day`. Public API and SignalBus payloads were unchanged by Prompt 9 except for **internal composition** (weighted split, same totals).

## FactionData design

- **Script**: `res://scripts/resources/faction_data.gd` (`class_name FactionData`).
- **Roster row script**: `res://scripts/resources/faction_roster_entry.gd` (`class_name FactionRosterEntry`).
  - **DEVIATION**: Prompt 9 text nested the roster class inside `FactionData`; a **separate Resource script** is required so `.tres` sub-resources serialize reliably in Godot 4.x.
- **Fields**: `faction_id`, `display_name`, `description`, `roster[]`, `mini_boss_ids[]`, `mini_boss_wave_hints[]`, `roster_tier`, `difficulty_offset`.
- **Helpers**: `get_entries_for_wave(wave_index)`, `get_effective_weight_for_wave(entry, wave_index)` (tier ramp + optional offset; see **SOURCE** comments in script).
- **Registry constant**: `FactionData.BUILTIN_FACTION_RESOURCE_PATHS` lists the three shipped `.tres` paths.

## Faction `.tres` instances

| `faction_id`     | File |
|------------------|------|
| `DEFAULT_MIXED`  | `res://resources/faction_data_default_mixed.tres` |
| `ORC_RAIDERS`    | `res://resources/faction_data_orc_raiders.tres` |
| `PLAGUE_CULT`    | `res://resources/faction_data_plague_cult.tres` |

Numeric weights and copy are **# PLACEHOLDER / # TUNING** as marked in data.

## DayConfig / TerritoryData

- **DayConfig** (`res://scripts/resources/day_config.gd`): `faction_id` default **`DEFAULT_MIXED`**; **`is_mini_boss`** renamed to **`is_mini_boss_day`** (all campaign `.tres` updated).
- **TerritoryData**: added **`default_faction_id`** (POST-MVP hook when day omits faction).
- **No duplicate** `dayconfig.gd` / `territorydata.gd` files — existing snake_case paths kept per **CONVENTIONS.md**.

## CampaignManager

- **`faction_registry`**: `Dictionary` (`String` → `FactionData`), filled in `_ready()` from `BUILTIN_FACTION_RESOURCE_PATHS`.
- **`validate_day_configs(day_configs: Array[DayConfig]) -> void`**: asserts each day resolves to a **non-empty** `faction_id` (empty → `DEFAULT_MIXED`) and that id exists in `faction_registry`.
- **DEVIATION**: `CampaignManager` and `WaveManager` use **`const FactionDataType = preload(".../faction_data.gd")`** for typings because **autoload scripts parse before global `class_name` registration**, which caused parse errors on raw `FactionData` annotations.

## WaveManager (Option B)

- Loads the same three faction resources; **`resolve_current_faction()`** uses override → else **`DEFAULT_MIXED`**.
- **`configure_for_day`**: applies wave cap + multipliers + **`is_mini_boss_day`** + resolves faction from `day_config.faction_id` (unknown id → error + fallback).
- **`_spawn_wave`**: total count **`round(wave_index × 6 × difficulty multiplier)`** (multiplier only if `difficulty_offset != 0`); splits counts across active roster entries with **largest-remainder** proportional rounding (**SOURCE** comment in code).
- **`set_faction_data_override(faction_data)`**: test / sim hook.
- **`get_mini_boss_info_for_wave(wave_index) -> Dictionary`**: returns `mini_boss_id` / `wave_index` / `faction_id` when hints match and roster has ids; **gameplay** requires **`is_mini_boss_day`** unless a **faction override** is set (so unit tests can query without a full day setup).
- **Backward compatibility**: **total enemies per wave remain `N×6`** (unless `difficulty_offset` non-zero); per-type counts are **approximate**.

## GameManager

- **`configure_for_day`** is invoked **after** `reset_for_new_mission()` inside **`_begin_mission_wave_sequence()`** so per-day wave cap and faction are not cleared by reset (Prompt 7 + 9 alignment).

## Tests

- **`res://tests/test_faction_data.gd`**: roster → `EnemyData` mapping for all three factions; `validate_day_configs` on short campaign.
- **`res://tests/test_wave_manager.gd`**: Prompt 9 cases (roster-only types, elite share growth, `N×6` totals, mini-boss hook, default mixed coverage). **# DEVIATION** comments where assertions relaxed vs strict “N per type”.

## CLI

```bash
./tools/run_gdunit.sh
# or:
godot --headless --path "$REPO" --script addons/gdUnit4/bin/GdUnitCmdTool.gd -- -a "res://tests"
```

## Polish (post-audit, 2026-03-24)

- **`docs/INDEX_FULL.md`**: Added **FactionRosterEntry** and **FactionData** field tables under **CUSTOM RESOURCE TYPES** (parallel to other resource docs).
- **`scripts/resources/territory_data.gd`**: **`# DEVIATION`** on `terrain_type` — Prompt 9 text used a string; the repo keeps **`TerrainType` enum** (Prompt 8 / world map).
