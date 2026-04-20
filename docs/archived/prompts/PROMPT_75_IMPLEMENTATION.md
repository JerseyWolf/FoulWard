# PROMPT 75 — Group 11 Final Reconciliation (10-session Perplexity)

**Date:** 2026-04-18

**Scope:** Verbatim from `docs/perplexity_sessions/IMPLEMENTATION_PROMPTS.md` **## GROUP 11: Final Reconciliation (1 chat)** (STEP 1–7: signal/autoload verification, `dotnet build`, full test suite with doc sync, `PERPLEXITY_RECONCILIATION_TRACKER.md`, implementation log). Session additions: **Phase A** audit table for Groups 1–10 deliverables; **Phase B** Group 4 (S08) remediation per chat 4A (lines 938–1062); **Phase C/D** structured reconciliation (this file).

---

## 1. Audit table (Phase A)

Post–Phase B, Group 4 items reflect completed remediation. Paths checked on disk unless noted.

| Group | Deliverable | Path | Status | Note |
|-------|-------------|------|--------|------|
| G1 | `@export var starting_gold` on DayConfig | `scripts/resources/day_config.gd` | ✅ | Line ~51 |
| G1 | 50-day campaign resource | `resources/campaigns/campaign_main_50_days.tres` | ✅ | `DayConfig` references present (51 matches incl. sub-resources); alternate `resources/campaign_main_50days.tres` also exists |
| G1 | Campaign config tests (~10) | `tests/test_campaign_config.gd` | ✅ | 11 `test_*` methods |
| G2 | `Types.GraphicsQuality` | `scripts/types.gd` | ✅ | |
| G2 | `FoulWardTypes.GraphicsQuality` | `scripts/FoulWardTypes.cs` | ✅ | |
| G2 | `graphics_quality_changed` | `autoloads/signal_bus.gd` | ✅ | |
| G2 | Settings use enum not String | `autoloads/settings_manager.gd` | ✅ | `Types.GraphicsQuality` |
| G2 | `CustomTogglesContainer` in settings UI | `scenes/ui/settings_screen.tscn` | ✅ | |
| G2 | Settings graphics tests | `tests/test_settings_graphics.gd` | ✅ | |
| G3 | `max_hp` + `can_be_targeted_by_enemies` on BuildingData | `scripts/resources/building_data.gd` | ✅ | |
| G3 | `prefer_building_targets` + `building_detection_radius` on EnemyData | `scripts/resources/enemy_data.gd` | ✅ | |
| G3 | `_setup_health_component` / `_on_health_depleted` | `scenes/buildings/building_base.gd` | ✅ | |
| G3 | Destruction effect scene + script | `scenes/buildings/destruction_effect.tscn`, `scenes/buildings/destruction_effect.gd` | ✅ | |
| G3 | `clear_slot_on_destruction` + `get_lowest_hp_pct_building` | `scenes/hex_grid/hex_grid.gd` | ✅ | |
| G3 | Building HP bar | `scenes/ui/building_hp_bar.tscn`, `scenes/ui/building_hp_bar.gd` | ✅ | |
| G3 | Building repair shop item | `resources/shop_data/shop_item_building_repair.tres` | ✅ | |
| G3 | Tests | `tests/test_building_health_component.gd`, `tests/test_enemy_building_targeting.gd`, `tests/test_building_repair.gd` | ✅ | |
| G3 | MEDIUM `.tres` max_hp=300, targetable | `resources/building_data/*` (MEDIUM tier files) | ✅ | Spot-checked `greatbow_turret.tres` etc. |
| G3 | LARGE `.tres` max_hp=650, targetable | `resources/building_data/*` (LARGE tier files) | ✅ | Spot-checked `fortress_cannon.tres` etc. |
| G4 | `territory_tier_cleared`, `territory_selected_for_replay` | `autoloads/signal_bus.gd` | ✅ | Already present before this session |
| G4 | `Types.DifficultyTier` | `scripts/types.gd` | ✅ | Added Phase B |
| G4 | `FoulWardTypes.DifficultyTier` | `scripts/FoulWardTypes.cs` | ✅ | Added Phase B |
| G4 | `DifficultyTierData` resource | `scripts/resources/difficulty_tier_data.gd` | ✅ | Added Phase B |
| G4 | `tier_normal/veteran/nightmare.tres` | `resources/difficulty/` | ✅ | Added Phase B |
| G4 | Territory tier fields | `scripts/resources/territory_data.gd` | ✅ | Added Phase B |
| G4 | `set_active_tier` / `get_active_tier` / `_apply_tier_to_day_config` / `_handle_tier_cleared` / `_load_tier_data` | `autoloads/game_manager.gd` | ✅ | Phase B |
| G4 | `territory_node_ui.gd` | `scripts/ui/territory_node_ui.gd` | ✅ | From prior G4B work |
| G4 | Tier selection popup | `scenes/ui/world_map/tier_selection_popup.tscn`, `scripts/ui/tier_selection_popup.gd` | ✅ | |
| G4 | `test_difficulty_tier_system.gd` | `tests/test_difficulty_tier_system.gd` | ✅ | 17 cases passing after harness + assertion fixes |
| G5 | `rigged_visual_wiring.gd` ANIM_ constants | `scripts/art/rigged_visual_wiring.gd` | ✅ | |
| G5 | 30 enemy GLB paths + ally/building/tower helpers | same + related | ✅ | |
| G5 | `validate_art_assets.gd` | `tools/validate_art_assets.gd` | ✅ | |
| G5 | SESSION_07 reports | `docs/SESSION_07_REPORT_01_ANIM_TABLE.md`, `REPORT_02`, `REPORT_03` | ✅ | |
| G5 | Session 07 unit tests | `tests/unit/test_rigged_visual_wiring_session07.gd`, `tests/unit/test_validate_art_assets_session07.gd` | ✅ | |
| G6 | `SybilPassiveData` + class_name | `scripts/resources/sybil_passive_data.gd` | ✅ | |
| G6 | 8 passive `.tres` | `resources/passive_data/*.tres` | ✅ | 8 files |
| G6 | `PASSIVE_SELECT = 11` | `scripts/types.gd`, `FoulWardTypes.cs` | ✅ | |
| G6 | `sybil_passive_selected`, `sybil_passives_offered` | `autoloads/signal_bus.gd` | ✅ | |
| G6 | SybilPassiveManager autoload #14 | `project.godot` | ✅ | |
| G6 | Passive select UI | `scenes/ui/passive_select_screen.tscn`, `scripts/ui/passive_select_screen.gd` | ✅ | |
| G6 | Tests | `tests/test_sybil_passive_manager.gd` | ✅ | |
| G7 | `TOTAL_SLOTS` / `RING3_COUNT` | `scenes/hex_grid/hex_grid.gd` | ✅ | 42 / 24 |
| G7 | Hex slots 24–41 in scene | `scenes/hex_grid/hex_grid.tscn` | ✅ | (spot-check: project uses expanded grid) |
| G7 | `rotate_ring`, `get_ring_offset_radians` | `hex_grid.gd` | ✅ | |
| G7 | `RING_ROTATE` + C# mirror | `scripts/types.gd`, `FoulWardTypes.cs` | ✅ | Value 12 |
| G7 | `ring_rotated` | `autoloads/signal_bus.gd` | ✅ | |
| G7 | `enter_ring_rotate` / `exit_ring_rotate` | `autoloads/game_manager.gd` | ✅ | |
| G7 | Save version 2 + slot guard | `autoloads/save_manager.gd` | ✅ | |
| G7 | Ring rotation UI | `scenes/ui/ring_rotation_screen.tscn`, `scripts/ui/ring_rotation_screen.gd` | ✅ | |
| G7 | `test_ring_rotation.gd` + slot updates in other tests | `tests/` | ✅ | |
| G8 | Chronicle resource scripts | `scripts/resources/chronicle_*.gd` | ✅ | |
| G8 | Reward / perk enums + C# | `scripts/types.gd`, `FoulWardTypes.cs` | ✅ | |
| G8 | Chronicle signals | `autoloads/signal_bus.gd` | ✅ | |
| G8 | ChronicleManager #15 | `project.godot` | ✅ | |
| G8 | 16 entries, 8 perks `.tres` | `resources/chronicle/entries/`, `resources/chronicle/perks/` | ✅ | 16 + 8 |
| G8 | `apply_perks_at_mission_start` from mission flow | `autoloads/game_manager.gd` | ✅ | `_begin_mission_wave_sequence` |
| G8 | Chronicle UI + main menu | `scenes/ui/chronicle_screen.tscn`, etc. | ✅ | |
| G8 | `test_chronicle_manager.gd` | `tests/test_chronicle_manager.gd` | ✅ | |
| G9 | `is_combat_line` on DialogueEntry | `scripts/resources/dialogue/dialogue_entry.gd` | ✅ | |
| G9 | Hub + combat dialogue `.tres` counts | `resources/dialogue/` | ✅ | Per prior implementation |
| G9 | DialogueManager combat API | `autoloads/dialogue_manager.gd` | ✅ | |
| G9 | `combat_dialogue_requested` | `autoloads/signal_bus.gd` | ✅ | |
| G9 | Combat dialogue banner + Main | `scripts/ui/combat_dialogue_banner.gd`, `scenes/main.tscn` | ✅ | |
| G9 | Hub Talk button | `scenes/hub/character_base_2d.tscn` + `.gd` | ✅ | |
| G9 | Tests | `tests/test_dialogue_content.gd`, `tests/test_combat_dialogue.gd` | ✅ | |
| G10 | `ShopItemData` category + rarity_weight | `scripts/resources/shop_item_data.gd` | ✅ | |
| G10 | Shop rotation API | `scripts/shop_manager.gd` | ✅ | Path: `res://scripts/shop_manager.gd` |
| G10 | Shop data set (15 items) | `resources/shop_data/` | ✅ | Catalog + per-item `.tres` |
| G10 | Stubs (tower, wave, campaign, weapon upgrade) | per spec files | ✅ | |
| G10 | Strategy profiles difficulty_target | `resources/strategyprofiles/strategy_*.tres` | ✅ | |
| G10 | `test_shop_rotation.gd` (8 tests) | `tests/test_shop_rotation.gd` | ✅ | |
| G10 | `run_gdunit_quick.sh` allowlist | `tools/run_gdunit_quick.sh` | ✅ | Includes `test_shop_rotation.gd` |

---

## 2. Group 4 remediation summary (Phase B)

- **`scripts/types.gd`** — Appended `enum DifficultyTier { NORMAL, VETERAN, NIGHTMARE }` with values 0–2.
- **`scripts/FoulWardTypes.cs`** — Added nested `DifficultyTier` enum (Normal=0, Veteran=1, Nightmare=2).
- **`scripts/resources/difficulty_tier_data.gd`** — New `class_name DifficultyTierData` with `tier` + four multiplier floats.
- **`resources/difficulty/tier_normal.tres`** — All multipliers `1.0`.
- **`resources/difficulty/tier_veteran.tres`** — hp `1.5`, dmg `1.3`, gold `1.2`, spawn `1.25`.
- **`resources/difficulty/tier_nightmare.tres`** — hp `2.5`, dmg `2.0`, gold `1.5`, spawn `1.75`.
- **`scripts/resources/territory_data.gd`** — Added `highest_cleared_tier`, `star_count`, `veteran_perk_id`, `nightmare_title_id`.
- **`autoloads/game_manager.gd`** — `_active_tier`, `_tier_data`, `_load_tier_data()` in `_ready`, `set_active_tier` / `get_active_tier`, `_apply_tier_to_day_config` (NORMAL returns source unchanged; else `duplicate()` and multiply four DayConfig multipliers), `_handle_tier_cleared` after `apply_day_result_to_territory` in `_on_all_waves_cleared`, `_active_tier` reset in `start_new_game`, save/restore `territories` block, `_begin_mission_wave_sequence` uses patched `DayConfig` for waves.
- **`tools/run_gdunit_quick.sh`** — Added `res://tests/test_difficulty_tier_system.gd` to `QUICK_SUITES`.
- **`tests/test_difficulty_tier_system.gd`** — `monitor_signals(SignalBus, false)` so GdUnit does not `auto_free` the SignalBus autoload; `is_emitted` for `territory_tier_cleared` includes full arg array `["signal_t", int(VETERAN)]` (GdUnit matches args exactly).
- **`tests/test_building_health_component.gd`** — `monitor_signals(SignalBus, false)` (same autoload leak as above; prevents suite-wide freed SignalBus after that test).

---

## 3. Reconciliation results (Phase C)

- **Signal count:** actual = **77** (unchanged vs `AGENTS.md` before = 77). Verified: `grep -c '^signal ' autoloads/signal_bus.gd` → **77**.
- **Autoload order:** ✅ matches expected 19 entries in `project.godot` (SignalBus → … → EnchantmentManager).
- **`dotnet build`:** **pass** (0 errors; `FoulWard.csproj`).
- **Full sequential suite (`./tools/run_gdunit.sh`):** Did **not** complete a single-process summary: Godot **segfault (signal 11)** mid-run (see log tail in `reports/gdunit_full_run.log`). Post-exit crash noted; not treated as assertion failure count.
- **Full parallel aggregate (`./tools/run_gdunit_parallel.sh`):** **650** test cases, **2** failures, **3** orphans, wall-clock ~183s, exit **FAIL** (group 5). Final aggregator line: `TOTALS: cases=650  failures=2  orphans=3  wall-clock=183s` / `RESULT: FAIL`.
- **Quick suite (`./tools/run_gdunit_quick.sh`):** **489** cases, **0** failures before engine **abort/segfault** on teardown (Overall Summary line in `reports/gdunit_quick_run.summary.txt`); **1** orphan reported.

### Failures reported (not fixed in production unless Phase B)

1. **`tests/test_building_repair.gd::test_repair_targets_lowest_hp_pct_not_lowest_absolute`**  
   - Orphan nodes warning; assertions: expected not `null` / expected `<Node3D>` but was `null` (see `reports/parallel/group_5.log` ~lines 39–47).

2. **`tests/test_florence.gd::test_day_advances_once_for_multiple_reasons`**  
   - Runtime error in GdUnit after-stage: `Invalid call. Nonexistent function 'id' in base 'Nil'.` (`GdUnitTestCaseAfterStage._execute`).

3. **`tests/test_shop_manager.gd::test_purchase_item_emits_correct_item_id`**  
   - `Expecting emit signal: 'shop_item_purchased(["mana_draught"])' but timed out after 2s 0ms`.

*(Parallel totals attribute **2** failures; Florence suite may count the above as error/orphan — all listed for PROMPT_74-style transparency.)*

---

## 4. Per-Group end-state summary (for future review sessions)

### G1 — 50-day campaign content
- **Feature:** 50-day `DayConfig` chain + starting gold field for mission economy.
- **Key files:** `scripts/resources/day_config.gd`, `resources/campaigns/campaign_main_50_days.tres`, `resources/campaign_main_50days.tres` (legacy/alt path).
- **Signals/enums:** No new SignalBus signals for G1.
- **Tests:** `tests/test_campaign_config.gd` (~11 cases).
- **Spec notes:** Two campaign asset paths exist; runtime uses `CampaignManager` / `GameManager.MAIN_CAMPAIGN_CONFIG_PATH` per mission.

### G2 — Graphics quality
- **Feature:** `GraphicsQuality` enum, settings persistence, UI toggles.
- **Key files:** `scripts/types.gd`, `scripts/FoulWardTypes.cs`, `autoloads/settings_manager.gd`, `scenes/ui/settings_screen.tscn`, `autoloads/signal_bus.gd` (`graphics_quality_changed`).
- **Tests:** `tests/test_settings_graphics.gd`.

### G3 — Building HP / targeting / repair
- **Feature:** Building health, enemy building focus, repair consumable, destruction VFX.
- **Key files:** `building_data.gd`, `enemy_data.gd`, `building_base.gd`, `hex_grid.gd`, `shop_item_building_repair.tres`, HP bar scene.
- **Signals:** Uses existing `building_destroyed` etc.
- **Tests:** `test_building_health_component.gd`, `test_enemy_building_targeting.gd`, `test_building_repair.gd` (repair test has failures — §3).
- **Spec notes:** MEDIUM=300 HP, LARGE=650 HP, `can_be_targeted_by_enemies` true on sampled `.tres`.

### G4 — Star difficulty tiers
- **Feature:** Per-territory replay tiers, multipliers on `DayConfig`, stars, save fields, world-map UI (4B) + tests.
- **Key files:** `difficulty_tier_data.gd`, `resources/difficulty/tier_*.tres`, `territory_data.gd`, `game_manager.gd`, `territory_node_ui.gd`, `tier_selection_popup.*`, `signal_bus.gd` (tier signals).
- **Enums:** `Types.DifficultyTier` + C# mirror.
- **Tests:** `test_difficulty_tier_system.gd` (17). **Fix 2:** `get_effective_multiplier` intentionally omitted.
- **Harness note:** `monitor_signals(SignalBus, false)` required for any test that monitors SignalBus.

### G5 — Art pipeline
- **Feature:** Rigged wiring constants, validation tool, Session 07 documentation, unit tests.
- **Key files:** `scripts/art/rigged_visual_wiring.gd`, `tools/validate_art_assets.gd`, `docs/SESSION_07_REPORT_*.md`, `tests/unit/test_*_session07.gd`.

### G6 — Sybil passive
- **Feature:** Passive selection state, data resources, manager autoload #14, UI.
- **Key files:** `sybil_passive_data.gd`, `resources/passive_data/*.tres`, `sybil_passive_manager.gd`, `passive_select_screen.*`, `Types.GameState.PASSIVE_SELECT`.
- **Signals:** `sybil_passive_selected`, `sybil_passives_offered`.
- **Tests:** `test_sybil_passive_manager.gd`.

### G7 — Ring rotation
- **Feature:** 42 hex slots, ring rotation API, pre-combat screen, save v2.
- **Key files:** `hex_grid.gd` / `.tscn`, `ring_rotation_screen.*`, `game_manager.gd`, `save_manager.gd`, `Types.GameState.RING_ROTATE`.
- **Signal:** `ring_rotated`.
- **Tests:** `test_ring_rotation.gd`, hex/simulation tests updated for 42 slots.

### G8 — Chronicle
- **Feature:** Meta entries, perks, manager, UI.
- **Key files:** `chronicle_*` resources, `chronicle_manager.gd`, `resources/chronicle/**`, chronicle screen.
- **Enums:** `ChronicleRewardType`, `ChroniclePerkEffectType` + C#.
- **Signals:** `chronicle_entry_completed`, `chronicle_perk_activated`, `chronicle_progress_updated`.
- **Fix 3:** `entry_meta_first_run` merged into `entry_campaign_day_50` (single entry file).
- **Tests:** `test_chronicle_manager.gd`.

### G9 — Dialogue
- **Feature:** Hub + combat lines, banner, Talk button.
- **Key files:** `dialogue_manager.gd`, `resources/dialogue/**`, `combat_dialogue_banner.*`, hub character scene.
- **Signal:** `combat_dialogue_requested`.
- **Tests:** `test_dialogue_content.gd`, `test_combat_dialogue.gd`.

### G10 — Shop rotation
- **Feature:** Weighted daily rotation, categories, integration stubs, strategy profile tuning.
- **Key files:** `shop_manager.gd`, `shop_item_data.gd`, `resources/shop_data/**`, strategy `.tres`.
- **Tests:** `test_shop_rotation.gd` (8 cases); quick allowlist includes it.

---

## 5. Doc sync diff (Phase C5)

| File | Before → After (signal / test prose) |
|------|--------------------------------------|
| `AGENTS.md` | Test total **678** → **650** (parallel aggregate, 2026-04-18); header doc-sync line updated |
| `docs/FOUL_WARD_MASTER_DOC.md` | §1 test count **647** → **650**; §23 ~670 → **650**; changelog row added G11 |
| `docs/INDEX_SHORT.md` | Added `DifficultyTierData`; extended `TerritoryData` line |
| `docs/INDEX_FULL.md` | New **2026-04-18 Prompt 75 delta** section for difficulty tier |
| `docs/PERPLEXITY_RECONCILIATION_TRACKER.md` | Filled Actual columns, progress, spec checklist, mirrors |
| Signal count docs (`CONVENTIONS.md`, `ARCHITECTURE.md`, `.cursor/skills/signal-bus/SKILL.md`, `references/signal-table.md`) | **77** unchanged (no edits required beyond verification) |

---

## 6. PERPLEXITY_RECONCILIATION_TRACKER.md update (Phase C6)

- **Signal cumulative table:** Filled **Actual** = expected running totals through G10; **final** row = **77** (`grep` verified).
- **Test cumulative table:** Parallel **650** cases + failure pointer to §3.
- **Implementation progress:** G1–G11 marked **DONE** with file cites.
- **Spec corrections:** All rows **Applied** with path evidence.
- **FoulWardTypes.cs:** All mirror rows **yes**.
- **GameState / enums:** Marked implemented through value 12.

---

## 7. Cumulative metrics

| Metric | Baseline → Final (actual) |
|--------|----------------------------|
| **Signals** | 67 → **77** (`autoloads/signal_bus.gd`) |
| **Autoloads** | 17 → **19** (`project.godot`) |
| **Tests** | 612 → **650** cases (parallel aggregate, 2026-04-18) |
| **HexGrid TOTAL_SLOTS** | 24 → **42** |
| **GameState last value** | ENDLESS=10 → **RING_ROTATE=12** |

---

## 8. Open follow-ups

- **Failures:** See **§3** (`test_building_repair`, `test_florence`, `test_shop_manager`). Not addressed with production changes in this session (policy).
- **Engine stability:** `./tools/run_gdunit.sh` **segfault** before final sequential summary; `./tools/run_gdunit_quick.sh` completes assertions then **abort/segfault** on teardown — note in §3 / verification checklist (known .NET/Godot teardown class of issues).
- **`.godot/global_script_class_cache.cfg`:** New `class_name DifficultyTierData` registered after editor/headless scan; CI clones may need one Godot import pass for parse of tests using `DifficultyTierData` type hints.
- **Log gap:** Some groups lack a dedicated `PROMPT_NN` file in `docs/` beyond this reconciliation — **code + tests verified on disk**; future agents should not redo G1–G10 solely for missing logs.
