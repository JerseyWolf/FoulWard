# Perplexity Implementation — Reconciliation Tracker
**Created:** 2026-04-16
**Last reconciliation:** 2026-04-18 (`docs/PROMPT_75_IMPLEMENTATION.md`)
**Purpose:** Cumulative state tracker for the 10-session Perplexity implementation.
All sessions were written against a frozen baseline. This document tracks the running
totals so each implementing chat session uses the correct cumulative values.

---

## Baseline State (verified 2026-04-16)

| Metric | Value |
|---|---|
| SignalBus signals | 67 |
| Core autoloads | 17 (Init 1–17 per AGENTS.md) |
| GdUnit4 tests | 612 across 75 test files |
| GameState last value | ENDLESS = 10 |
| HexGrid TOTAL_SLOTS | 24 |
| Types.gd enum count | existing set (no Chronicle/Difficulty/Graphics enums) |

---

## Signal Count — Cumulative Log

Update the "Actual" column after each group is implemented.

| After Group | Signals Added | Expected Running Total | Actual |
|---|---|---|---|
| Baseline | — | 67 | 67 |
| G1 S01 Campaign Content | 0 | 67 | 67 |
| G2 S10 Graphics Quality | +1 `graphics_quality_changed` | 68 | 68 |
| G3 S09 Building HP | 0 (activates existing `building_destroyed`) | 68 | 68 |
| G4 S08 Star Difficulty | +2 `territory_tier_cleared`, `territory_selected_for_replay` | 70 | 70 |
| G5 S07 Art Pipeline | 0 | 70 | 70 |
| G6 S02 Sybil Passive | +2 `sybil_passive_selected`, `sybil_passives_offered` | 72 | 72 |
| G7 S03 Ring Rotation | +1 `ring_rotated` | 73 | 73 |
| G8 S04 Chronicle | +3 `chronicle_entry_completed`, `chronicle_perk_activated`, `chronicle_progress_updated` | 76 | 76 |
| G9 S05 Dialogue | +1 `combat_dialogue_requested` | 77 | 77 |
| G10 S06 Shop Rotation | 0 | 77 | 77 |
| **Final (2026-04-18)** | — | **77** | **`grep -c '^signal ' autoloads/signal_bus.gd` → 77** |

---

## Autoload Init Order — Target (after all sessions)

| Init # | Autoload | Change |
|---|---|---|
| 1 | SignalBus | unchanged |
| 2 | NavMeshManager | unchanged |
| 3 | DamageCalculator | unchanged |
| 4 | AuraManager | unchanged |
| 5 | EconomyManager | unchanged |
| 6 | CampaignManager | unchanged |
| 7 | RelationshipManager | unchanged |
| 8 | SettingsManager | unchanged |
| 9 | GameManager | unchanged |
| 10 | BuildPhaseManager | unchanged |
| 11 | AllyManager | unchanged |
| 12 | CombatStatsTracker | unchanged |
| 13 | SaveManager | unchanged |
| 14 | **SybilPassiveManager** | **NEW (S02)** |
| 15 | **ChronicleManager** | **NEW (S04)** |
| 16 | DialogueManager | was 14, shifted +2 |
| 17 | AutoTestDriver | was 15, shifted +2 |
| 18 | GDAIMCPRuntime | was 16, shifted +2 |
| 19 | EnchantmentManager | was 17, shifted +2 |

**Verified:** `project.godot` `[autoload]` matches this order (2026-04-18).

---

## GameState Enum Values

| Value | Name | Source | Implemented? |
|---|---|---|---|
| 0 | MAIN_MENU | baseline | yes |
| 1 | MISSION_BRIEFING | baseline | yes |
| 2 | COMBAT | baseline | yes |
| 3 | BUILD_MODE | baseline | yes |
| 4 | WAVE_COUNTDOWN | baseline | yes |
| 5 | BETWEEN_MISSIONS | baseline | yes |
| 6 | MISSION_WON | baseline | yes |
| 7 | MISSION_FAILED | baseline | yes |
| 8 | GAME_WON | baseline | yes |
| 9 | GAME_OVER | baseline | yes |
| 10 | ENDLESS | baseline | yes |
| 11 | PASSIVE_SELECT | S02 | yes (`scripts/types.gd`, `FoulWardTypes.GameState.PassiveSelect`) |
| 12 | RING_ROTATE | S03 | yes (`scripts/types.gd`, `FoulWardTypes.GameState.RingRotate`) |

---

## New Enums in Types.gd

| Enum | Values | Source | Implemented? |
|---|---|---|---|
| GraphicsQuality | LOW=0, MEDIUM=1, HIGH=2, CUSTOM=3 | S10 (G2) | yes |
| DifficultyTier | NORMAL=0, VETERAN=1, NIGHTMARE=2 | S08 (G4) | yes |
| ChronicleRewardType | PERK=0, COSMETIC=1, TITLE=2 | S04 (G8) | yes |
| ChroniclePerkEffectType | STARTING_GOLD=0 .. COSMETIC_SKIN=9 | S04 (G8) | yes |

---

## FoulWardTypes.cs Mirror Checklist

Each GDScript enum must be mirrored with identical integer values. Run `dotnet build` after each addition.

| Enum | Mirrored? |
|---|---|
| GameState + PASSIVE_SELECT(11), RING_ROTATE(12) | yes (`scripts/FoulWardTypes.cs`) |
| GraphicsQuality | yes |
| DifficultyTier | yes |
| ChronicleRewardType | yes |
| ChroniclePerkEffectType | yes |

---

## Spec Corrections Checklist

| Fix # | Description | Applied? |
|---|---|---|
| 1 | SybilPassiveData gets `class_name` (S02 P1 inverted the rule) | Applied — `scripts/resources/sybil_passive_data.gd` has `class_name SybilPassiveData` |
| 2 | Remove/fix `get_effective_multiplier()` no-op (S08 P3) | Applied — not present on `GameManager` (`tests/test_difficulty_tier_system.gd` guard) |
| 3 | Merge `entry_meta_first_run` into `entry_campaign_day_50` (S04 P5) | Applied — single `entry_campaign_day_50.tres` in `resources/chronicle/entries/` (no separate `entry_meta_first_run.tres`) |
| 4 | Fold CombatDialogueManager into DialogueManager (S05 T10) | Applied — combat APIs on `autoloads/dialogue_manager.gd`; no `CombatDialogueManager` autoload |
| 5 | Signal counts use cumulative totals, not frozen 67 baseline | Applied — docs + `AGENTS.md` use **77** (2026-04-18) |
| 6 | ChronicleManager at Init #15, not #14 (S04 P4) | Applied — `project.godot` ChronicleManager position 15 |

---

## Test Count — Cumulative Log

| After Group | Tests Added (approx) | Expected Running Total | Actual |
|---|---|---|---|
| Baseline | — | 612 | 612 |
| G1 S01 | ~10 | ~622 | 623 (`test_campaign_config.gd` 11 tests) |
| G2 S10 | ~8 | ~630 | +9 (`test_settings_graphics.gd`) |
| G3 S09 | ~15 | ~645 | +22 (building HP + targeting + repair suites) |
| G4 S08 | ~17 | ~662 | +17 (`test_difficulty_tier_system.gd`) |
| G5 S07 | ~19 | ~681 | +2 session07 unit suites |
| G6 S02 | ~11 | ~692 | +11 (`test_sybil_passive_manager.gd`) |
| G7 S03 | ~13 | ~705 | +13 (`test_ring_rotation.gd`) |
| G8 S04 | ~11 | ~716 | +11 (`test_chronicle_manager.gd`) |
| G9 S05 | ~12 | ~728 | +12 (`test_dialogue_content` + `test_combat_dialogue`) |
| G10 S06 | ~8 | ~736 | +8 (`test_shop_rotation.gd`) |
| **Full parallel aggregate (2026-04-19)** | — | — | **665 cases / 88 files** (`./tools/run_gdunit_parallel.sh`; **0 failures** — see `docs/PROMPT_76_IMPLEMENTATION.md`) |

---

## Implementation Progress

| Group | Session | Status | Chat Sessions | Notes |
|---|---|---|---|---|
| G1 | S01 Campaign Content | DONE | 1A, 1B | `DayConfig.starting_gold`; `resources/campaigns/campaign_main_50_days.tres`; `tests/test_campaign_config.gd` (11 tests) |
| G2 | S10 Graphics Quality | DONE | 2A, 2B | `Types.GraphicsQuality`, `graphics_quality_changed`, settings + UI; `tests/test_settings_graphics.gd` |
| G3 | S09 Building HP | DONE | 3A, 3B, 3C | Building/enemy data, HC, repair, destruction; tests per G3 spec |
| G4 | S08 Star Difficulty | DONE | 4A, 4B | Enum + `DifficultyTierData` + tier `.tres`; `TerritoryData` fields; `GameManager` tier + save; UI `territory_node_ui`, `tier_selection_popup`; `tests/test_difficulty_tier_system.gd` |
| G5 | S07 Art Pipeline | DONE | 5A, 5B, 5C | `rigged_visual_wiring.gd`, `validate_art_assets.gd`, SESSION_07 reports, unit tests |
| G6 | S02 Sybil Passive | DONE | 6A, 6B, 6C | `SybilPassiveManager`, passive `.tres`, `PASSIVE_SELECT`, UI + tests |
| G7 | S03 Ring Rotation | DONE | 7A, 7B, 7C | Hex 42 slots, `RING_ROTATE`, save v2, `ring_rotation_screen`, tests |
| G8 | S04 Chronicle | DONE | 8A, 8B, 8C | Resources + perks + manager + UI + tests |
| G9 | S05 Dialogue | DONE | 9A, 9B, 9C | Combat/hub dialogue, banner, tests |
| G10 | S06 Shop Rotation | DONE | 10A, 10B | `ShopItemData` category/rarity, rotation, stubs, `test_shop_rotation.gd` |
| G11 | Reconciliation | DONE | 11A | `docs/PROMPT_75_IMPLEMENTATION.md` |
