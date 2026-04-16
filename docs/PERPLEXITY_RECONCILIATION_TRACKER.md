# Perplexity Implementation — Reconciliation Tracker
**Created:** 2026-04-16
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
| G1 S01 Campaign Content | 0 | 67 | |
| G2 S10 Graphics Quality | +1 `graphics_quality_changed` | 68 | |
| G3 S09 Building HP | 0 (activates existing `building_destroyed`) | 68 | |
| G4 S08 Star Difficulty | +2 `territory_tier_cleared`, `territory_selected_for_replay` | 70 | |
| G5 S07 Art Pipeline | 0 | 70 | |
| G6 S02 Sybil Passive | +2 `sybil_passive_selected`, `sybil_passives_offered` | 72 | |
| G7 S03 Ring Rotation | +1 `ring_rotated` | 73 | |
| G8 S04 Chronicle | +3 `chronicle_entry_completed`, `chronicle_perk_activated`, `chronicle_progress_updated` | 76 | |
| G9 S05 Dialogue | +1–2 `combat_dialogue_requested`; `enemy_spawned` if missing | 77–78 | |
| G10 S06 Shop Rotation | 0 | 77–78 | |

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
| 11 | PASSIVE_SELECT | S02 | |
| 12 | RING_ROTATE | S03 | |

---

## New Enums in Types.gd

| Enum | Values | Source | Implemented? |
|---|---|---|---|
| GraphicsQuality | LOW=0, MEDIUM=1, HIGH=2, CUSTOM=3 | S10 (G2) | |
| DifficultyTier | NORMAL=0, VETERAN=1, NIGHTMARE=2 | S08 (G4) | |
| ChronicleRewardType | PERK=0, COSMETIC=1, TITLE=2 | S04 (G8) | |
| ChroniclePerkEffectType | STARTING_GOLD=0 .. COSMETIC_SKIN=9 | S04 (G8) | |

---

## FoulWardTypes.cs Mirror Checklist

Each GDScript enum must be mirrored with identical integer values. Run `dotnet build` after each addition.

| Enum | Mirrored? |
|---|---|
| GameState + PASSIVE_SELECT(11), RING_ROTATE(12) | |
| GraphicsQuality | |
| DifficultyTier | |
| ChronicleRewardType | |
| ChroniclePerkEffectType | |

---

## Spec Corrections Checklist

| Fix # | Description | Applied? |
|---|---|---|
| 1 | SybilPassiveData gets `class_name` (S02 P1 inverted the rule) | |
| 2 | Remove/fix `get_effective_multiplier()` no-op (S08 P3) | |
| 3 | Merge `entry_meta_first_run` into `entry_campaign_day_50` (S04 P5) | |
| 4 | Fold CombatDialogueManager into DialogueManager (S05 T10) | |
| 5 | Signal counts use cumulative totals, not frozen 67 baseline | |
| 6 | ChronicleManager at Init #15, not #14 (S04 P4) | |

---

## Test Count — Cumulative Log

| After Group | Tests Added (approx) | Expected Running Total | Actual |
|---|---|---|---|
| Baseline | — | 612 | 612 |
| G1 S01 | ~10 | ~622 | |
| G2 S10 | ~8 | ~630 | |
| G3 S09 | ~15 | ~645 | |
| G4 S08 | ~17 | ~662 | |
| G5 S07 | ~19 | ~681 | |
| G6 S02 | ~11 | ~692 | |
| G7 S03 | ~13 | ~705 | |
| G8 S04 | ~11 | ~716 | |
| G9 S05 | ~12 | ~728 | |
| G10 S06 | ~8 | ~736 | |

---

## Implementation Progress

| Group | Session | Status | Chat Sessions | Notes |
|---|---|---|---|---|
| G1 | S01 Campaign Content | NOT STARTED | 1A, 1B | |
| G2 | S10 Graphics Quality | NOT STARTED | 2A, 2B | |
| G3 | S09 Building HP | NOT STARTED | 3A, 3B, 3C | |
| G4 | S08 Star Difficulty | NOT STARTED | 4A, 4B | |
| G5 | S07 Art Pipeline | NOT STARTED | 5A, 5B, 5C | |
| G6 | S02 Sybil Passive | NOT STARTED | 6A, 6B, 6C | |
| G7 | S03 Ring Rotation | NOT STARTED | 7A, 7B, 7C | |
| G8 | S04 Chronicle | NOT STARTED | 8A, 8B, 8C | |
| G9 | S05 Dialogue | NOT STARTED | 9A, 9B, 9C | |
| G10 | S06 Shop Rotation | NOT STARTED | 10A, 10B | |
| G11 | Reconciliation | NOT STARTED | 11A | |
