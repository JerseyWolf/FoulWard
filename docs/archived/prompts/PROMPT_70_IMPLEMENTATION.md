# PROMPT 70 — Implementation Log

**Date:** 2026-04-18
**Scope:** Chat 5C — TODO(ART) Resolution + Tests + Docs (GROUP 5: S07 Art Pipeline Integration)
**Model:** Sonnet 4.6

---

## Summary

Completed Chat 5C of the art pipeline integration (Group 5). All three steps from the spec were executed.

---

## STEP 1 — TODO(ART) Markers Replaced

Replaced 5 TODO(ART) markers in `.gd` files with production-wiring comments (no implementation — comments only):

| File | Old TODO(ART) text | New production-wiring comment |
|---|---|---|
| `scenes/allies/ally_base.gd` | Apply ArtPlaceholderHelper.get_ally_mesh(ally_id)... | `asset = RiggedVisualWiring.ally_rigged_glb_path(ally_id)` |
| `scenes/arnulf/arnulf.gd` | Add attack/death clips; drive from ArnulfState... | `asset = RiggedVisualWiring.ALLY_ARNULF_GLB → "res://art/generated/allies/arnulf.glb"` |
| `scenes/tower/tower.gd` | Replace tower MeshInstance3D with tower_core.glb... | `asset = RiggedVisualWiring.tower_glb_path() → "res://art/characters/florence/florence.glb"` |
| `scenes/bosses/boss_base.gd` | Production boss — phase/ability clips... | `asset = RiggedVisualWiring.boss_rigged_glb_path(boss_id)` |
| `ui/hub.gd` | Hub characters use ColorRect placeholders... | Portrait 2D art (512×512 Texture2D), not GLB — no RiggedVisualWiring |

Note: 3 TODO(ART) markers remain in `.tscn` scene files (`ally_base.tscn`, `tower.tscn`, `hub.tscn`). These are in the Godot scene binary/text format, not GDScript, and were not in scope for Chat 5C.

---

## STEP 2 — drunk_idle Removed from Pipeline Docs

- `docs/FOUL WARD 3D ART PIPELINE.txt` — removed `drunk_idle (swaying variation) — Arnulf only` from ALLIES clip list; updated Arnulf animation call list to remove `drunk_idle`; added removal notice comments citing AGENTS.md Formally Cut Features.
- `FUTURE_3D_MODELS_PLAN.md` — no `drunk_idle` references found (already absent).

---

## STEP 3 — New Test Files

### `tests/unit/test_rigged_visual_wiring_session07.gd` (9 methods)

| Test | Description |
|---|---|
| `test_all_30_enemy_types_return_non_empty_path` | All 30 EnemyType values return non-empty GLB path |
| `test_enemy_paths_use_correct_prefix` | All enemy paths start with `res://art/generated/enemies/` |
| `test_ally_known_ids_return_paths` | arnulf, archer, knight, swordsman, barbarian return correct paths |
| `test_ally_unknown_id_returns_empty` | Unknown ally_id returns `""` |
| `test_building_all_36_types_return_paths` | All 36 BuildingType values return non-empty paths; count verified == 36 |
| `test_building_paths_use_correct_prefix` | All building paths start with `res://art/generated/buildings/` |
| `test_tower_glb_path_correct` | Returns exactly `"res://art/characters/florence/florence.glb"` |
| `test_anim_constants_no_drunk_idle` | No `"drunk_idle"` in ANIM constant values |
| `test_anim_constants_all_present` | All 17 ANIM_ StringName constants have correct values |

### `tests/unit/test_validate_art_assets_session07.gd` (10 methods)

| Test | Description |
|---|---|
| `test_infer_category_enemies` | Path under `generated/enemies/` → `"enemy"` |
| `test_infer_category_allies` | Path under `generated/allies/` → `"ally"` |
| `test_infer_category_bosses` | Path under `generated/bosses/` → `"boss"` |
| `test_infer_category_buildings` | Path under `generated/buildings/` → `"building"` |
| `test_infer_category_tower` | Path under `art/characters/` → `"tower"` |
| `test_infer_category_unknown` | Unrecognized paths → `"unknown"` |
| `test_required_clips_enemy_count` | Enemy clips == 4: idle, walk, death, hit_react |
| `test_required_clips_ally_count` | Ally clips == 4: idle, walk, death, attack_melee |
| `test_required_clips_misc_empty` | `"unknown"` category → empty PackedStringArray |
| `test_check_glb_no_anim_player_returns_missing_all` | Null AnimationPlayer → missing_clips == required clips |

Note: `validate_art_assets.gd` extends `EditorScript` and cannot be instantiated in headless GdUnit4 tests. The test file mirrors the constants and logic inline to verify the specification.

---

## Files Modified

- `scenes/allies/ally_base.gd` — replaced TODO(ART) comment
- `scenes/arnulf/arnulf.gd` — replaced TODO(ART) comment
- `scenes/tower/tower.gd` — replaced TODO(ART) comment
- `scenes/bosses/boss_base.gd` — replaced TODO(ART) comment
- `ui/hub.gd` — replaced TODO(ART) comment
- `docs/FOUL WARD 3D ART PIPELINE.txt` — removed drunk_idle entries
- `tools/run_gdunit_quick.sh` — added 2 new session07 test files to QUICK_SUITES allowlist
- `docs/INDEX_SHORT.md` — added 2 new test file entries

## Files Created

- `tests/unit/test_rigged_visual_wiring_session07.gd` — 9 tests
- `tests/unit/test_validate_art_assets_session07.gd` — 10 tests
- `docs/PROMPT_70_IMPLEMENTATION.md` — this file

---

## Verification

- 19 new tests run and pass (exit code 0, 0 failures)
- No new signals, no enum changes, no autoload changes this session
- Signal count unchanged at 70
