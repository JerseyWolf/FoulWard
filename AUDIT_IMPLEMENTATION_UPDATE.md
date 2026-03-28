# AUDIT 5 — Implementation status (verification handoff)

**Purpose:** Paste this into **claude.ai** (or another reviewer) to verify whether **AUDIT 5** tasks from `docs/ALL_AUDITS.md` (section **AUDIT 5**) are implemented in the FOUL WARD repo.

**How to use this with a reviewer**

1. Ask the reviewer to treat **AUDIT 5** in `docs/ALL_AUDITS.md` (starts ~line 816) as the **source of truth** for requirements.
2. Ask them to confirm each row below by **opening the cited files** and/or **running the test command** (paths are relative to repo root).
3. **Status legend:** **Done** = implemented and covered by tests; **Partial** = some coverage or a different interpretation; **Gap** = not implemented or not found in the cited areas; **Prod** = production code change (not only tests).

---

## Reference

- **Audit text:** `docs/ALL_AUDITS.md` → heading `AUDIT 5`
- **Conventions / architecture:** `docs/AUDIT_CONTEXT_SUMMARY.md`
- **Global rules for Audit 5 tests:** headless-safe, `res://` only, GdUnit4 under `res://tests/`

---

## Quick verdict (human summary)

| Area | Summary |
|------|---------|
| Campaign / day flow | Core tests + `CampaignManager` refresh of `current_day_config` after `mission_won` day advance. |
| Boss / territory | Mini-boss territory secure + boss wave composition tests; **`boss_killed` → territory** clears `has_boss_threat` in production. |
| SimBot | Batch smoke + CSV determinism checks; safety test is **static** (no `res://ui/` in SimBot source). |
| Sell / firing / upgrades / enchantments / pathfinding / faction / dialogue / Florence / art | Largely covered in named suites; see detailed table below. |
| **Open gaps** | Some Audit 5 bullets are **optional** or **partial** (e.g. “no `main.tscn`” SimBot run, territory **research cost modifier** for weapon upgrades, synthetic boss-attack **step-through** as specified). |

---

## Section-by-section checklist (AUDIT 5 § numbering)

### 1. Campaign autoload order & day progression

| Requirement (abbrev.) | Status | Evidence / notes |
|------------------------|--------|------------------|
| Suite `test_campaign_autoload_and_day_flow.gd` | **Done** | `res://tests/test_campaign_autoload_and_day_flow.gd` |
| `ConfigFile` + `[autoload]` order: CampaignManager before GameManager | **Done** | `test_autoload_order_campaign_before_game_manager` + `push_error` message on violation |
| `start_new_campaign` initializes state (instance + short campaign) | **Done** | `test_start_new_campaign_initializes_state` |
| `mission_won` advances day when active | **Done** | `test_mission_won_advances_day_when_campaign_active` (uses `GameManager.final_boss_defeated = false` guard + `SignalBus.mission_won.emit(CampaignManager.current_day)`) |
| `mission_won` does not progress without active campaign | **Done** | `test_mission_won_does_not_progress_without_active_campaign` |
| 2-day campaign completes on last `mission_won` | **Done** | `test_campaign_completes_on_last_day_two_day_config` |
| After win, `current_day_config` matches new day | **Done** | **Prod:** `CampaignManager._on_mission_won` sets `current_day_config = GameManager.get_day_config_for_index(current_day)` after incrementing `current_day` |

---

### 2. Boss and Day-50 loop

| Requirement (abbrev.) | Status | Evidence / notes |
|------------------------|--------|------------------|
| Suite for boss/day flow | **Done** | `res://tests/test_boss_day_flow.gd` (+ existing `test_boss_waves.gd`, `test_final_boss_day.gd`) |
| Mini-boss secures territory + clears threat | **Done** | `test_mini_boss_kill_secures_territory_and_clears_threat`; **Prod:** `GameManager._mark_territory_secured` sets `has_boss_threat = false` |
| Mini-boss defection → roster | **Done** | `test_mini_boss_defection_adds_ally_to_roster` |
| Final boss + campaign complete | **Done** | `test_final_boss_day_marks_defeated_and_completes_campaign` |
| Unknown faction → fallback | **Done** | `test_wave_manager_falls_back_when_faction_id_missing` |
| Boss wave: one boss + escorts match `BossData` | **Done** | `test_boss_wave_one_boss_and_escorts_matches_boss_data` (empty faction roster + `base_wave_count = 1` to avoid roster `N×6` grunts) |
| Synthetic boss-attack days insertion/clearing (step CampaignManager days) | **Partial** | **Verify:** `test_final_boss_day.gd` / `GameManager` boss-attack logic may overlap; dedicated “step days + assert before/after” may be missing |

---

### 3. SimBot robustness & headless safety

| Requirement (abbrev.) | Status | Evidence / notes |
|------------------------|--------|------------------|
| Short-campaign `run_batch` smoke | **Done** | `res://tests/test_simbot_basic_run.gd` |
| No UI / safe headless | **Partial** | `test_simbot_safety.gd` asserts SimBot script **does not** reference `res://ui/`; Audit 5 also asked for **no `main.tscn`** — **verify** `test_simbot_basic_run.gd` / `test_simbot_logging.gd` still instantiate `main.tscn` where needed |
| CSV determinism + header | **Done** | `res://tests/test_simbot_logging.gd` (compares seed column / rows as implemented) |

---

### 4. Sell UX (build-mode sell)

| Requirement (abbrev.) | Status | Evidence / notes |
|------------------------|--------|------------------|
| Occupied slot refund + free | **Verify** | `res://tests/test_hex_grid.gd` — confirm tests for sell success + gold |
| Empty slot no-op | **Done** | Covered in hex grid sell tests (audit session) |
| Invalid index safe | **Done** | Same |

---

### 5. Firing assist / miss perturbation

| Requirement (abbrev.) | Status | Evidence / notes |
|------------------------|--------|------------------|
| Assist beyond max distance | **Done** | `res://tests/test_simulation_api.gd` |
| Miss angle clamp | **Done** | `test_simulation_api.gd` |
| SimBot/autofire bypass assist | **Done** | `test_simulation_api.gd` (`auto_fire_enabled` path) |

---

### 6. Weapon upgrade station

| Requirement (abbrev.) | Status | Evidence / notes |
|------------------------|--------|------------------|
| Beyond max level fails | **Done** | `test_upgrade_beyond_max_level_returns_false` in `test_weapon_upgrade_manager.gd` |
| Insufficient resources + no signal | **Done** | `test_upgrade_insufficient_gold_does_not_emit_weapon_upgraded` |
| Territory / research **cost modifier** on upgrade | **Gap** | **Not** present in `test_weapon_upgrade_manager.gd` — **verify** `WeaponUpgradeManager` + `test_territory_economy_bonuses.gd` or similar for overlap |

---

### 7. Enchantments (mid-mission)

| Requirement (abbrev.) | Status | Evidence / notes |
|------------------------|--------|------------------|
| Remove enchant → next shot physical | **Done** | `test_remove_enchantment_subsequent_shot_uses_physical_damage_type` in `test_tower_enchantments.gd` (reload reset for second shot) |
| Swap A → B affects second batch | **Done** | `test_swap_enchantment_elemental_changes_second_shot_damage_type` |
| In-flight projectiles keep old effect | **Partial** | **Verify** wording vs test: may assert **subsequent** shot stats rather than full collision pipeline |

---

### 8. Pathfinding & obstacles

| Requirement (abbrev.) | Status | Evidence / notes |
|------------------------|--------|------------------|
| Dense layout: ground enemies move | **Done** | `test_ground_enemy_position_changes_over_time_dense_layout` in `test_enemy_pathfinding.gd` |
| Flying ignores obstacles | **Done** | `test_flying_enemy_ignores_building_obstacles` |

---

### 9. Faction data robustness

| Requirement (abbrev.) | Status | Evidence / notes |
|------------------------|--------|------------------|
| Missing `FactionData` / safe fallback | **Done** | `test_wave_manager.gd` + `test_boss_day_flow.gd` (`configure_for_day` fallback) |
| Empty roster | **Done** | `test_empty_faction_roster_configures_without_crash` in `test_faction_data.gd` (requires **6** `enemy_data_registry` entries for WaveManager) |

---

### 10. Dialogue conditions

| Requirement (abbrev.) | Status | Evidence / notes |
|------------------------|--------|------------------|
| Missing research IDs → false | **Done** | `test_research_unlocked_condition_unknown_node_evaluates_false` in `test_dialogue_manager.gd` |
| Broken chain / invalid `next_id` | **Done** | `test_invalid_chain_next_id_does_not_crash` |

---

### 11. Hub / UIManager resilience

| Requirement (abbrev.) | Status | Evidence / notes |
|------------------------|--------|------------------|
| UIManager without Hub/DialoguePanel | **Partial** | `test_character_hub.gd` uses stubs; **verify** explicit “missing Hub/DialoguePanel” calls match Audit 5 |

---

### 12. Florence meta-state

| Requirement (abbrev.) | Status | Evidence / notes |
|------------------------|--------|------------------|
| Higher-priority `DayAdvanceReason` wins | **Done** | `test_higher_priority_day_reason_from_types_wins` in `test_florence.gd` |

---

### 13. Art placeholder overrides

| Requirement (abbrev.) | Status | Evidence / notes |
|------------------------|--------|------------------|
| `res://art/generated/...` preferred | **Done** | `test_art_placeholders.gd` + asset under `res://art/generated/` (e.g. mesh for enemy key) |

---

## Production code changes (Audit 5 follow-through)

| File | Change |
|------|--------|
| `autoloads/game_manager.gd` | `_mark_territory_secured`: set `has_boss_threat = false` |
| `autoloads/campaign_manager.gd` | `_on_mission_won`: after advancing `current_day`, refresh `current_day_config` from `GameManager.get_day_config_for_index` |
| `scripts/resources/boss_data.gd` | `BUILTIN_BOSS_RESOURCE_PATHS` includes audit mini-boss `.tres` |
| `resources/bossdata_audit5_territory_miniboss.tres` | Mini-boss data for tests |
| `art/generated/meshes/...` | Generated mesh asset for placeholder tests |

---

## Tests & verification (commands)

```bash
./tools/run_gdunit_quick.sh
./tools/run_gdunit.sh
```

**Last recorded full run (this implementation pass):** **475** test cases, **0** failures (GdUnit may exit **101** with warnings; treat per `tools/run_gdunit.sh`).

---

## Questions for the reviewer (Claude)

1. Re-read **AUDIT 5** in `docs/ALL_AUDITS.md` and confirm every **numbered subsection** is either **Done**, **Partial**, or **Gap** using the table above.
2. Confirm **Gap** items: **weapon upgrade cost modifiers** from territory/research; **synthetic boss-attack day** step-through; **SimBot without `main.tscn`** if required literally.
3. Confirm **production** changes in `campaign_manager.gd` / `game_manager.gd` match intended game behavior (not only tests).
4. Run `./tools/run_gdunit.sh` locally and confirm **0 failures**.

---

*End of handoff — FOUL WARD, Audit 5 test & related production fixes.*
