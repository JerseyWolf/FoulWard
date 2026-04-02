# Foul Ward — Read-Only Codebase Verification Summary

**Purpose:** Consolidated answers from a three-part read-only audit (no code changes during verification).  
**Audit dates:** Findings reflect repository state as verified in-session (reference date **2026-03-31**).  
**Method:** Files read from disk at `res://` paths; some counts verified via `grep`, `glob`, and `main.tscn`. Godot editor MCP `get_godot_errors` was **not** invoked; headless Godot was used once for a smoke check (see §Project health).

**Uncertainties / limits:**

- Paths in questions sometimes differ from actual layout (e.g. `res://autoloads/research_manager.gd` vs actual `res://scripts/research_manager.gd`). This document states **actual paths** where they differ.
- “Approximate line counts” are sensitive to edits; re-verify after large diffs.
- Runtime behaviour (e.g. whether UI calls `rotate_ring`) was verified by **repository search**, not playtesting.
- Godot error console output varies by editor vs CLI; §Q19 reports CLI output only.

---

## Prompt 1 — Files 1–5

### FILE 1: `res://autoloads/game_manager.gd`

| Question | Answer |
|----------|--------|
| **Q1.1** State machine states | **FALSE** for the exact list (BUILD_MODE, COMBAT, PAUSED, GAME_OVER, VICTORY). States live in `Types.GameState` (`res://scripts/types.gd`): MAIN_MENU, MISSION_BRIEFING, COMBAT, BUILD_MODE, WAVE_COUNTDOWN, BETWEEN_MISSIONS, MISSION_WON, MISSION_FAILED, GAME_WON, GAME_OVER, ENDLESS. No PAUSED; no VICTORY (use GAME_WON / MISSION_WON). |
| **Q1.2** BUILD_MODE time scale | **TRUE** — `Engine.time_scale = 0.1` in `enter_build_mode`, restored to `1.0` in `exit_build_mode`. |
| **Q1.3** `assert()` in public methods | **FALSE** — no `assert(` in `game_manager.gd`; uses `push_warning` / early return. |
| **Q1.4** Wave countdown pause in BUILD_MODE | **PARTIAL** — Logic is in **`WaveManager._on_game_state_changed`**, not `GameManager`. Pauses when entering BUILD_MODE if counting down; resumes when leaving BUILD_MODE. Fully implemented. |

### FILE 2: `res://autoloads/signal_bus.gd`

| Question | Answer |
|----------|--------|
| **Q2.1** `wave_completed` / `wave_cleared` | **`wave_completed`:** not present. **`wave_cleared(wave_number)`** and **`all_waves_cleared`** present. |
| **Q2.2** `building_dealt_damage` | **TRUE** |
| **Q2.3** `research_points_changed` | **TRUE** |
| **Q2.4** `damage_dealt`, `enemy_damage_dealt`, `ally_died` | **PARTIAL** — `ally_died` **exists**. `damage_dealt` and `enemy_damage_dealt` **not** declared in `signal_bus.gd`. |

### FILE 3: `res://scenes/tower/tower.gd`

| Question | Answer |
|----------|--------|
| **Q3.1** Left/right fire vs auto-fire | **TRUE** — `InputManager`: left → `fire_crossbow`, right → `fire_rapid_missile` in COMBAT/WAVE_COUNTDOWN. Optional **`auto_fire_enabled`** auto-fires crossbow at nearest enemy. |
| **Q3.2** Soft auto-aim | **TRUE** — Uses `weapon_data.assist_angle_degrees` and `weapon_data.assist_max_distance` (values from `WeaponData`, not literals in script). |
| **Q3.3** `_apply_auto_aim` | **TRUE** — Named function exists. |
| **Q3.4** Per-weapon miss chance | **TRUE** — `weapon_data.base_miss_chance`, `weapon_data.max_miss_angle_degrees`, RNG cone perturbation. |
| **Q3.5** Flying targets | **FALSE** as “AA buildings only” — Gated by **`weapon_data.can_target_flying`** on Florence’s weapons. |

### FILE 4: `res://scenes/hex_grid/hex_grid.gd`

| Question | Answer |
|----------|--------|
| **Q4.1** Slot count | **TRUE** — `TOTAL_SLOTS = 24`. |
| **Q4.2** `rotate_ring` | **PARTIAL** — Method is **`rotate_ring(delta_steps: int)`**. No `.gd` callers found besides definition/docs; no dedicated UI hook found. |
| **Q4.3** `get_tower_type_count()` | **FALSE** — Not implemented on HexGrid. |
| **Q4.4** `duplicate_cost_k` in this file | **FALSE** — Not in `hex_grid.gd` (see `EconomyManager` / `BuildingData`). |
| **Q4.5** `_try_place_building` ~58 lines | **PARTIAL** — Exists; line span was **~85 lines** at audit time (not ~58). **Re-verify after edits.** |

### FILE 5: `res://autoloads/economy_manager.gd`

| Question | Answer |
|----------|--------|
| **Q5.1** Currencies | **TRUE** — `Types.ResourceType`: GOLD, BUILDING_MATERIAL, RESEARCH_MATERIAL. Three separate counters. UI signal `research_points_changed` aligns with research material pool (naming “points” vs `research_material`). |

---

## Prompt 2 — Files 6–11

### FILE 6: `res://scripts/types.gd` (enums; **not** `scripts/resources/types.gd`)

| Question | Answer |
|----------|--------|
| **Q6.1** `EnemyType` count | **30** entries (ORC_GRUNT … PLAGUE_HERALD). |
| **Q6.2** `BuildingType` count | **36** entries (ARROW_TOWER … CITADEL_AURA). |
| **Q6.3** `DamageType` | **TRUE** — PHYSICAL, FIRE, MAGICAL, POISON, TRUE (5th). |
| **Q6.4** `ArmorType` | **TRUE** — UNARMORED, HEAVY_ARMOR, UNDEAD, FLYING. |
| **Q6.5** `AllyClass` | **TRUE** — MELEE, RANGED, SUPPORT. |

### FILE 7: `res://scripts/wave_manager.gd`

| Question | Answer |
|----------|--------|
| **Q7.1** `base_wave_count` | **Per `DayConfig`** via `configure_for_day` → `configured_max_waves = mini(day_config.base_wave_count, max_waves)`. Export **`max_waves` defaults to 5**. Not a single global MVP constant of 3/5/10 in isolation. |
| **Q7.2** Wave count ramp across days | **FALSE** as a single formula in-file — Mission wave cap comes from each day’s `DayConfig`. |
| **Q7.3** `_spawn_wave` ~82 lines | **PARTIAL** — Exists; measured **~75 lines** (628–702 at audit). |
| **Q7.4** Day-based wave budget scaling | **PARTIAL** — `WaveComposer.compose_wave(wave_idx_0, spawn_count_multiplier)`; `spawn_count_multiplier` from day config; seed uses `day_index`. Not the literal formula `base + day_scaling * day + wave_scaling * wave_index`. |
| **Q7.5** `enemy_data_registry.size() == 30` | **TRUE** in `_ready()` (`push_error` if not 30). |

### FILE 8: `BuildingData` + building `.tres`

| Question | Answer |
|----------|--------|
| **Q8.1** Count / path | **`res://resources/buildings/` does not exist.** **36** `.tres` files under **`res://resources/building_data/`** (see repo listing). |
| **Q8.2** Arrow Tower upgrade fields | **PARTIAL** — Uses `upgrade_gold_cost`, `upgrade_material_cost`, `upgraded_damage`, `upgraded_range`; not `cost_level_1`/`cost_level_2`. `BuildingData` also has `upgrade_next`, `upgrade_costs`, etc. |
| **Q8.3** `duplicate_cost_k` on `BuildingData` | **TRUE** (`@export var duplicate_cost_k`). |
| **Q8.4** `summoner_tower.tres` / `aura_tower.tres` / `healer_tower.tres` | **FALSE** those filenames — Per-building resources (e.g. `wolfden.tres`, `warden_shrine.tres`, `field_medic.tres`). No separate `summoner_tower.gd` etc.; shared **`building_base.gd`**. |

### FILE 9: `res://scripts/sim_bot.gd`

| Question | Answer |
|----------|--------|
| **Q9.1** CLI | **`auto_test_driver.gd`:** `--simbot_profile=`, `--simbot_runs=`, `--simbot_seed=`, `--simbot_balance_sweep`. Not `--simbotprofile=balanced`. |
| **Q9.2** `run_balance_sweep()` | **TRUE** |
| **Q9.3** `run_single` / `run_batch` | **TRUE** |
| **Q9.4** StrategyProfile `.tres` | **3** files: `strategy_balanced_default.tres` (BALANCED_DEFAULT), `strategy_greedy_econ.tres` (GREEDY_ECON), `strategy_heavy_fire.tres` (HEAVY_FIRE). |
| **Q9.5** `_choose_build_or_upgrade_action` ~69 lines | **TRUE** — ~69 lines (714–782). |
| **Q9.6** `_wait_for_wave_or_mission_end` | **FALSE** — Not present in codebase. |
| **Q9.7** `place_building_async` | **FALSE** — Uses `_hex_grid.place_building` / `bot_place_building`. |
| **Q9.8** `compute_difficulty_fit()` | **TRUE** |
| **Q9.9** CSV output paths | **PARTIAL** — Default batch log: `user://simbot/logs/simbot_balance_log.csv`. `CombatStatsTracker` uses `user://simbot/runs/{run_id}/` with `run_id` built from mission + label + timestamp. |

### FILE 10: Factions + bosses + ally

| Question | Answer |
|----------|--------|
| **Q10.1** Faction `.tres` | **3** under `res://resources/`: `faction_data_default_mixed.tres` → **DEFAULT_MIXED**; `faction_data_orc_raiders.tres` → **ORC_RAIDERS**; `faction_data_plague_cult.tres` → **PLAGUE_CULT**. (**Not** a `resources/factions/` folder in the tree.) |
| **Q10.2** Boss files | **PARTIAL filenames** — Built-in: `bossdata_plague_cult_miniboss.tres`, `bossdata_orc_warlord_miniboss.tres`, `bossdata_final_boss.tres`. Boss stats use **`damage`**, not `attack_damage`. Sample: plague mini **450** HP / **35** dmg / **120** gold / phase **1**; orc warlord **400** / **32** / **110** (phase omitted → default 1); final **5000** / **80** / **2000** / phase **3**. |
| **Q10.3** `defected_orc_captain` | **TRUE** — `res://resources/ally_data/defected_orc_captain.tres` (**not** `resources/allies/`). **max_hp = 140**, **`basic_attack_damage = 18.0`** (no field named `attack_damage`). |

### FILE 11: `res://scenes/arnulf/arnulf.gd`

| Question | Answer |
|----------|--------|
| **Q11.1** `patrol_radius` | **55.0** in script `@export`. |
| **Q11.2** Kill counter / frenzy | **TRUE** — `_kill_counter` incremented on `enemy_killed`; comment: no frenzy activation in MVP. |
| **Q11.3** Drunkenness | **FALSE** — Not present. |
| **Q11.4** DOWNED → RECOVERING | **TRUE** — Timer `_recovery_timer` / `recovery_time`; recovery uses **`health_component.reset_to_max()`** (full HP, not 50%). |

---

## Prompt 3 — Files 12–17, Q18–20

### FILE 12: `res://scripts/research_manager.gd` (manager node under `Main/Managers`, not `autoloads/`)

| Question | Answer |
|----------|--------|
| **Q12.1** Node count | **24** research nodes wired in **`scenes/main.tscn`** (`p50_rn_00` … `p50_rn_23`). **Not 6 MVP-only.** |
| **Q12.2** `dev_unlock_anti_air_only` | **TRUE** |
| **Q12.3** Branch categories | **FALSE / N/A** — `ResearchNodeData` has no branch/category field; no explicit category list in code. |
| **Q12.4** `assert()` in unlock flow | **FALSE** |

### FILE 13: `res://scripts/shop_manager.gd`

| Question | Answer |
|----------|--------|
| **Q13.1** Purchase flow | **TRUE** — Full `purchase_item`, effects, signals. |
| **Q13.2** Default catalog | **4** items in `main.tscn`; `.tres` under `res://resources/shop_data/` (tower repair, mana draught, building repair, arrow tower voucher). |
| **Q13.3** Inventory rotation every 2–3 missions | **FALSE** — Not implemented in `shop_manager.gd`. |

### FILE 14: `res://autoloads/campaign_manager.gd`

| Question | Answer |
|----------|--------|
| **Q14.1** `max_active_allies_per_day` | **TRUE** — **2** |
| **Q14.2** `auto_select_best_allies` ~59 lines | **PARTIAL** — **~66 lines** (374–439). |
| **Q14.3** `notify_mini_boss_defeated` | **TRUE** |
| **Q14.4** 50-day campaign | **TRUE** — `res://resources/campaigns/campaign_main_50_days.tres` embeds **50** DayConfigs. Folder also has `campaign_short_5_days.tres`. |
| **Q14.5** Five territory IDs | **TRUE** — `res://resources/territories/main_campaign_territories.tres`: heartland_plains, blackwood_forest, ashen_swamp, iron_ridge, outer_city — each with `terrain_type` (0–4) and bonus fields (see audit). |
| **Q14.6** `restore_from_save` ~52 lines | **PARTIAL** — **~54 lines** (730–783). |

### FILE 15: `res://autoloads/dialogue_manager.gd`

| Question | Answer |
|----------|--------|
| **Q15.1** `request_entry_for_character` | **TRUE** (optional `tags` array). |
| **Q15.2** `resolve_state_value` | **TRUE** — See `_resolve_state_value` and relationship tier branch; keys include mission counts, game state, resources, `florence.*`, `campaign.*`, `research_unlocked_*`, `shop_item_purchased_*`, `arnulf_is_downed`, etc. |
| **Q15.3** `chain_next_id` | **TRUE** — Set on `mark_entry_played`; next `request_entry_for_character` follows chain. |
| **Q15.4** Mid-battle “first enemy type” / “tower HP critically low” | **FALSE** in this script — No such condition keys or `tower_damaged` wiring here. |

### FILE 16: `res://autoloads/relationship_manager.gd`

| Question | Answer |
|----------|--------|
| **Q16.1** Affinity range | **TRUE** — −100..100 |
| **Q16.2** Named tiers | **TRUE** — `relationship_tier_config.tres`: Hostile −100, Cold −50, Neutral 0, Friendly 31, Allied 71. |
| **Q16.3** Save/restore | **TRUE** — `SaveManager` payload includes `relationship` snapshot. |

### FILE 17: `res://autoloads/save_manager.gd`

| Question | Answer |
|----------|--------|
| **Q17.1** Save slots | **TRUE** — **5** (`MAX_SLOTS`). |
| **Q17.2** `attempt_1` … `attempt_N` | **PARTIAL** — **`user://saves/attempt_{timestamp}/slot_{0..4}.json`**; not `attempt_1` as filename. |
| **Q17.3** Restore order | **PARTIAL** — `_apply_save_payload`: CampaignManager → GameManager → RelationshipManager → ResearchManager → ShopManager → EnchantmentManager. |

### Spot-check Q18 — Unimplemented / alternate architecture

| Question | Answer |
|----------|--------|
| **Q18.1** `summoner_tower.gd` | **FALSE** — Use **`building_base.gd`** + **`AllyManager`** (summoner squads). |
| **Q18.2** `aura_tower.gd` | **FALSE** — **`AuraManager`** + **`BuildingBase`**. |
| **Q18.3** `healer_tower.gd` | **FALSE** — Same pattern. |
| **Q18.4** Ring rotation UI / pre-battle screen | **FALSE** — Only **`HexGrid.rotate_ring`** + comments; no dedicated `.tscn` found. |
| **Q18.5** `EnchantmentManager` stub | **FALSE** — `try_apply_enchantment` assigns slots and spends gold. |
| **Q18.6** Mercenary hire | **TRUE** — **`CampaignManager.purchase_mercenary_offer`** deducts resources. |

### Q19 — Godot errors

**PARTIAL.** One-off headless run: **WARNING** lines (GdUnit plugin skipped, scan thread aborted, ObjectDB leaks at exit); **no ERROR** in captured snippet. **Not** equivalent to editor MCP `get_godot_errors` after live editing.

### Q20 — `docs/INDEX_SHORT.md`

**TRUE** — Exists. **Updated:** **2026-03-30** (per file header). Documents autoload table and many systems through Prompt 51.

---

## Master Audit Table (by system)

| System | Representative claims | Result | Notes |
|--------|------------------------|--------|--------|
| Player & Tower | GameState enum; tower input; aim/miss | Mixed | See Q1.1, Q3 |
| Signal Bus | Wave/building/research signals | Mostly TRUE | Q2.4 partial |
| Hex & Buildings | 24 slots; rotate_ring; no `get_tower_type_count` | Mixed | Q4 |
| Economy | Three currencies | TRUE | Q5 |
| Enemy & Faction Data | 30/36 enums; factions; bosses | TRUE | Q6, Q10 |
| Wave | DayConfig-driven; composer | PARTIAL | Q7 |
| SimBot | CLI, runs, CSV paths | Mixed | Q9 |
| Arnulf | Patrol, recovery | TRUE | Q11 |
| Research & Shop | 24 nodes; 4 shop items | TRUE | Q12–13 |
| Campaign & Territories | 2 allies/day; 50-day; 5 territories | TRUE | Q14 |
| Dialogue & Relationships | Chains; tiers; save | Mixed | Q15.4 FALSE |
| Save | 5 slots; payload order | PARTIAL | Q17 |
| Unimplemented (split scripts) | Separate tower scripts | FALSE | Q18 |
| Project health | INDEX_SHORT; headless warnings | PARTIAL | Q19–20 |

---

## Maintenance

- After major refactors, re-run line-count and “exists?” checks for functions called out as approximate.
- If you add `docs/SUMMARY_VERIFICATION.md` to the project index, point one line in `INDEX_SHORT.md` here.
