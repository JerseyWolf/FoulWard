# Compliance Report H3 — Campaign/Progression, Testing, Lifecycle Flows

Date: 2026-03-31

This report audits the Foul Ward repo against three Agent Skills (read in full for this session):  
`.cursor/skills/campaign-and-progression/SKILL.md` + `references/game-manager-api.md`,  
`.cursor/skills/testing/SKILL.md`,  
`.cursor/skills/lifecycle-flows/SKILL.md`.

**Scope:** Report only — no code fixes.

---

## Skill: campaign-and-progression

### CHECK A — CampaignManager before GameManager (`project.godot`)

**PASS (0 violations).**

In `[autoload]`, order is: … `EconomyManager` (5) → `CampaignManager` (6) → `RelationshipManager` (7) → `SettingsManager` (8) → `GameManager` (9) → … Counting only gameplay autoloads in the standing-orders list, **CampaignManager is 6th** and **GameManager is 9th**, matching the skill.

### CHECK B — `WAVES_PER_MISSION` and `TOTAL_MISSIONS`

**PASS — validation note.**

- `docs/AGENT_SKILLS_VALIDATION_REPORT.md` **Step 10D** documents **`WAVES_PER_MISSION` expected 5 / actual 5 — PASS.** It does **not** include a separate row for `TOTAL_MISSIONS`.
- Code verification: `autoloads/game_manager.gd` defines `const TOTAL_MISSIONS: int = 5` and `const WAVES_PER_MISSION: int = 5`, consistent skill + `references/game-manager-api.md`.

### CHECK C — Direct day mutation outside `campaign_manager.gd`

**FAIL — multiple findings (production + tests).**

Grep pattern: `current_day\s*+=|current_day\s*=|_day\s*+=` under `autoloads/`, `scripts/`, `scenes/`, excluding `campaign_manager.gd`.

**Production (campaign calendar coupling):**

- `autoloads/game_manager.gd` — `advance_to_next_day()` performs `CampaignManager.current_day += 1` (around line 306).
- `autoloads/game_manager.gd` — property setter `current_day_index` assigns `CampaignManager.current_day = value` (around line 257).

**Note:** The same file also mutates **`GameManager.current_day`** (Florence meta index, documented as separate from `CampaignManager.current_day` in the header comment). Those are **not** the campaign calendar field but still matched the grep; only the `CampaignManager.current_day` assignments above are **calendar** bypasses of `CampaignManager`’s own methods.

**Tests / harness (direct `CampaignManager.current_day` or related):**  
`tests/test_game_manager.gd`, `tests/test_boss_day_flow.gd`, `tests/test_save_manager_slots.gd`, `tests/test_florence.gd`, `tests/test_save_manager.gd`, `tests/test_campaign_autoload_and_day_flow.gd`, `tests/test_ally_spawning.gd`, `tests/test_final_boss_day.gd` — assignments used for fixture setup.

### CHECK D — `game_state_changed` payload types

**PASS (0 violations).**

All **production** `.emit` sites found:

- `autoloads/game_manager.gd` — `emit(old, …)` with `old: Types.GameState` and second arg `Types.GameState` / `resolved`.
- `ui/main_menu.gd` — `var old: Types.GameState = Types.GameState.MAIN_MENU` then `emit(old, GameManager.get_game_state())` (typed return).

**Test-only emits** (`tests/test_wave_manager.gd`, `tests/test_character_hub.gd`) use explicit `Types.GameState` pairs.

### CHECK E — Formally cut features (implementation)

**PASS (0 implementation hits; comments only).**

Grep `-i` across `autoloads/` `scripts/` `scenes/` `ui/` for `drunken|time_stop|hades.*hub|3d.*hub|passive_select`:

- `scripts/resources/character_data.gd` — **comment** (POST-MVP 3D hub).
- `autoloads/dialogue_manager.gd` / `scripts/florence_data.gd` — **comments** referencing Hades-style design; **not** a Hades hub implementation.

No `time_stop`, `drunken`, or `passive_select` implementation surfaced in `.gd` under those paths.

### CHECK F — `AllyData` typed access (no `.get()` on ally resource fields)

**FAIL — multiple findings.**

Expected **zero** hits for dictionary-style access on AllyData-style resources for fields like `ally_id`, `max_hp`, `is_unique`, `role`.

**Production:**

- `autoloads/campaign_manager.gd` — `loaded.get("ally_id")` when building `_ally_registry` (lines ~85–86).
- `autoloads/campaign_manager.gd` — `d.get("role")` where `d` is `get_ally_data()` (`Resource`) in `_pick_best_active` (~448).
- `autoloads/campaign_manager.gd` — `ally_data.get("role")` and `od.get("role")` in `_score_offer` / roster loop (~475, ~481).

*(Same file uses `offer.get("ally_id")` etc. on **offer dictionaries** — not flagged as AllyData field access; skill wording targets AllyData resources.)*

**Tests:**

- `tests/test_ally_data.gd` — extensive `data.get("max_hp")`, `data.get("ally_id")`, etc. on `AllyData` script instances / loaded resources (should use typed fields per skill).

**Summary for Skill 7:** **A PASS, B PASS, C FAIL, D PASS, E PASS, F FAIL.**

**Violations (concise list):**

1. `GameManager` directly increments / assigns `CampaignManager.current_day` (`advance_to_next_day`, `current_day_index` setter).
2. Tests assign `CampaignManager.current_day` (and related) for setup — acceptable for tests but strict reading of “only CampaignManager mutates day” is violated.
3. `campaign_manager.gd` + `test_ally_data.gd` use `.get(...)` on ally `Resource` / AllyData fields (`ally_id`, `role`, `max_hp`, …).

---

## Skill: testing

**Sweep directory:** `tests/` only, per instructions.

### CHECK A — Test naming `test_<method>_<condition>_<expected>`

**FAIL — 2 violations** (≤2 underscore-separated segments after `test_`):

- `tests/unit/test_mission_spawn_routing.gd` — `test_validate_mission`
- `tests/unit/test_combat_stats_tracker.gd` — `test_wave_lifecycle`

All other `^func test_` names checked with a segment count heuristic yielded **only these two** short names.

### CHECK B — `reset_to_defaults()` or `before_test()` isolation

**FAIL — 38 test files** contain at least one `func test_*` but **no** occurrence of `reset_to_defaults` **and** no `before_test` in that file.

Files:

`test_ally_base.gd`, `test_building_specials.gd`, `test_building_base.gd`, `test_endless_mode.gd`, `test_simbot_logging.gd`, `test_projectile_system.gd`, `test_damage_calculator.gd`, `test_simbot_profiles.gd`, `test_ally_data.gd`, `test_campaign_territory_mapping.gd`, `test_enemy_dot_system.gd`, `test_simbot_handlers.gd`, `test_simbot_basic_run.gd`, `test_ally_combat.gd`, `test_world_map_ui.gd`, `test_boss_data.gd`, `test_simbot_determinism.gd`, `test_campaign_autoload_and_day_flow.gd`, `unit/test_summoner_runtime.gd`, `unit/test_combat_stats_tracker.gd`, `unit/test_simbot_balance_integration.gd`, `unit/test_aura_healer_runtime.gd`, `unit/test_content_invariants.gd`, `unit/test_td_resource_helpers.gd`, `unit/test_wave_composer.gd`, `unit/test_mission_spawn_routing.gd`, `unit/test_damage_pipeline.gd`, `unit/test_terrain.gd`, `unit/test_enemy_specials.gd`, `test_character_hub.gd`, `test_ally_signals.gd`, `test_territory_data.gd`, `test_faction_data.gd`, `test_boss_base.gd`, `test_simbot_safety.gd`

**Caveat:** Many of these suites may be **pure unit / scene-local** tests that do not touch global autoloads; the skill still asks for `reset_to_defaults` **or** documented `before_test` discipline. Under a strict reading, isolation is **absent** in these files relative to the skill text.

### CHECK C — `assert(` in tests

**PASS — informational.**

`grep` for bare `assert(` under `tests/**/*.gd` returned **no matches** (suite uses GdUnit asserts such as `assert_int`, `assert_bool`, etc.). **Count: 0** for production-style `assert()`.

### CHECK D — UI / fragile `get_node` patterns in tests

**FAIL — multiple findings** (`get_node\(|\$HUD|\$BuildMenu|\$MainMenu`):

| File | Notes |
|------|--------|
| `tests/test_ally_signals.gd` | `ally.get_node("HealthComponent")` |
| `tests/test_ally_base.gd` | `ally.get_node("HealthComponent")` |
| `tests/test_art_placeholders.gd` | `enemy.get_node("EnemyVisual")`, building/tower/arnulf child paths |
| `tests/test_enemy_pathfinding.gd` | `_main.get_node("HexGrid")`, `Managers/WaveManager`, `Tower`, `EnemyContainer` |
| `tests/test_character_hub.gd` | `panel.get_node("SpeakerLabel")`, `TextLabel` |
| `tests/test_florence.gd` | `screen.get_node("FlorenceDebugLabel")` |
| `tests/test_building_base.gd` | `get_node("BuildingCollision")`, `NavigationObstacle` |
| `tests/test_ally_spawning.gd` | `main.get_node("AllyContainer")` |
| `tests/test_boss_base.gd` | `boss.get_node("NavigationAgent3D")` |

No matches for `$HUD`, `$BuildMenu`, or `$MainMenu` in this grep. **Risk:** bare `get_node` can break headless or refactors; skill prefers `get_node_or_null` + guards for runtime.

### CHECK E — SimBot output under `user://simbot/runs/`

**Informational only.**

From the **host shell**, `ls user://simbot/runs/` is not a valid path; it reported nothing useful. **Could not confirm** whether SimBot has been run recently from this environment. Inspect inside Godot’s user data directory if needed.

### CHECK F — Test count sanity

**PASS with clarification.**

- `grep -c '^func test_' tests/**/*.gd` (aggregate): **615** test functions.
- Skill / validation history cites **525** as a passing-suite baseline; **615 ≥ 525** on a **function-count** basis.
- `docs/AGENT_SKILLS_VALIDATION_REPORT.md` §9 quotes **389 cases** from a **quick** run — different metric (cases vs functions vs full suite). **No finding** that the repo is “far below 525” on function count; **actual passing count** was not re-run for H3.

**Summary for Skill 8:** **A FAIL (2), B FAIL (38 files), C PASS, D FAIL, E informational, F PASS (615 functions; passing not re-executed).**

---

## Skill: lifecycle-flows

### CHECK A — `SaveManager.save_current_state()` only in correct places

**By reference + spot check.**

Prior report **`docs/COMPLIANCE_REPORT_H2.md`** was **not found** in the workspace; H2 cannot be cited verbatim.

**H3 spot check:** `autoloads/game_manager.gd` `_ready()` connects anonymous callables on `SignalBus.mission_won` and `mission_failed` that call `SaveManager.save_current_state()` (when the method exists). Aligns with skill expectation (“automatic on mission end”; no extra ad-hoc saves audited here).

### CHECK B — `initialize()` before `add_child()`

**By reference.**

Prior **`COMPLIANCE_REPORT_H1.md`** / “H1 AP-06” **not present** in the workspace. **Not re-swept** in H3.

### CHECK C — Build mode `Engine.time_scale`

**PASS for production gameplay paths (informational for tests/add-ons).**

- `autoloads/game_manager.gd` — `enter_build_mode`: `Engine.time_scale = 0.1`; `exit_build_mode`: `Engine.time_scale = 1.0`. Matches skill.
- Other `time_scale` hits: **tests** reset to `1.0` / assert build-mode values; **comments** in `wave_manager.gd`, `hud.gd`, `arnulf.gd`, `spell_manager.gd`; **addon** `addons/gdUnit4/...` uses `Engine.set_time_scale` for scene runner — **not** gameplay build mode.

**No other production autoload/script** assigns a different scale for build mode in the grep result set.

### CHECK D — `wave_cleared` triggers reward

**PASS.**

`autoloads/economy_manager.gd` connects `SignalBus.wave_cleared` to `_on_wave_cleared`, which calls `grant_wave_clear_reward(wave_number, _mission_economy)`.

### CHECK E — `all_waves_cleared` → `mission_won`

**PASS.**

- `autoloads/game_manager.gd` — `SignalBus.all_waves_cleared.connect(_on_all_waves_cleared)`; handler ends with `SignalBus.mission_won.emit(CampaignManager.get_current_day())` (after economy rewards and Florence advance hooks).
- `scripts/wave_manager.gd` emits `all_waves_cleared` when the wave loop completes.

### CHECK F — `queue_free` vs `.free()` on enemies

**PASS for `scenes/enemies/`; one related script note.**

- `scenes/enemies/enemy_base.gd` uses `queue_free()` for enemy teardown (grep).
- **No** `.free()` under `scenes/enemies/`.
- `scripts/art/rigged_visual_wiring.gd` — `clear_visual_slot` uses **`n.free()`** on **children** of a visual slot (imported GLB riggings). Documented as visual-only; **not** the main `EnemyBase` lifetime path. **Low concern** relative to “enemy node” wording; listed for completeness.

**Summary for Skill 9:** **A PASS/BY VERIFICATION (no H2 file), B NOT RE-AUDITED (no H1 file), C PASS (production), D PASS, E PASS, F PASS** (with rigged visual caveat).

---

## Priority Violations

Top five **across all three skills** (severity / breadth):

1. **`CampaignManager.current_day` mutated from `GameManager`** (`advance_to_next_day`, `current_day_index` setter) — breaks “calendar owned by CampaignManager” discipline from campaign-and-progression.
2. **AllyData / ally `Resource` accessed via `.get("role")`, `.get("ally_id")`** in `autoloads/campaign_manager.gd` (and `tests/test_ally_data.gd`) — violates typed AllyData access rule.
3. **38 test files** lack any `reset_to_defaults()` or `before_test()` hook — highest-volume testing-skill gap vs isolation rule.
4. **Bare `get_node` in tests** (multiple integration-style suites) — headless / refactor fragility vs testing skill and `get_node_or_null` convention.
5. **`GameManager` / Florence vs campaign `current_day` split** plus **test harness assignments** — easy to misuse; strict “only CampaignManager mutates campaign day” is already violated in production (see item 1).

---

## Total Violation Count

| Skill | Approx. violation count | Notes |
|--------|-------------------------|--------|
| campaign-and-progression | **2** code patterns (C) + **6+** AllyData `.get` sites (F) + **8+** test files (C) | Tests counted separately from production. |
| testing | **2** naming + **38** isolation files + **9** files with `get_node` (D) | D is file-level; multiple lines in some files. |
| lifecycle-flows | **0** blocking | Optional note: `rigged_visual_wiring.gd` `.free()` on visuals. |

**Grand total (strict, deduplicated themes):** **6 major theme buckets** (calendar mutation; AllyData `.get`; test isolation mass; test `get_node`; short test names; rigged visual `.free()` note) — not all are equal severity.

---

*End of Compliance Report H3.*
