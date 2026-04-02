# Master Compliance Report — Foul Ward Agent Skills

Date: 2026-03-31  
Sessions: H1, H2, H3, H4, H5

Sources: `docs/COMPLIANCE_REPORT_H1.md` through `docs/COMPLIANCE_REPORT_H5.md`. Audits are **report-only** unless otherwise noted.

---

## Executive Summary

Across five compliance sweeps, auditors recorded **on the order of 120–150** discrete line- or file-level findings, with **H1** contributing the largest single share (**61** numeric items, plus qualitative SignalBus coupling). The most common themes are **anti-patterns** (especially `print()` in `AutoTestDriver`, `assert()` in `SimBot`, and **AP-06** `add_child` before `initialize`), **testing-skill** gaps (isolation and `get_node` in tests), and **cross-cutting architecture** (autoload orchestration vs strict SignalBus purity, campaign day ownership). **Overall compliance health: AMBER** — production gameplay is largely consistent with resources and paths, but headless safety, test discipline, and documented “pure bus” rules remain debt.

---

## Violation Counts by Skill

Approximate counts aggregate H1–H5; overlapping items (e.g. AllyData `.get`) are counted once under the primary skill.

| Skill | Violations | Severity |
| --- | ---: | --- |
| godot-conventions | 15 | MED |
| anti-patterns | 47 | HIGH |
| signal-bus | 2 | MED |
| enemy-system | 0 | — |
| building-system | 2 | MED |
| economy-system | 2 | MED |
| campaign-and-progression | 8 | MED |
| testing | 49 | HIGH |
| lifecycle-flows | 0 | — |
| scene-tree-and-physics | 3 | MED |
| spell-and-research-system | 0 | — |
| ally-and-mercenary-system | 1 | LOW |
| mcp-workflow | 1 | LOW |
| add-new-entity | 0 | — |
| save-and-dialogue | 3 | LOW |
| **TOTAL** | **~142** | — |

*Notes:* **anti-patterns** includes H1 AP-04 as architectural debt (not line-counted). **testing** ≈ 2 naming + 38 files lacking `reset_to_defaults`/`before_test` + ~9 files with bare `get_node` (H3). **save-and-dialogue** includes H5 UI character_id extras and H2 save-wiring policy note.

---

## Top 10 Priority Violations

1. **`assert()` in headless SimBot** — `scripts/sim_bot.gd` (~546–548): `WaveManager` / `SpellManager` / `HexGrid` asserts can abort CI. **Rule:** anti-patterns AP-03. **Impact:** failed headless runs.

2. **`add_child` before `initialize` / `initialize_with_economy`** — `scripts/wave_manager.gd` (multiple), `scenes/hex_grid/hex_grid.gd` (~201–228). **Rule:** anti-patterns AP-06; building-system placement flow. **Impact:** ordering bugs at `_ready`, fragile teardown.

3. **`EconomyManager` uses `_process` for passive accrual** — `autoloads/economy_manager.gd` (~52–69). **Rule:** godot-conventions D (gameplay in `_physics_process`). **Impact:** inconsistent tick with physics / determinism.

4. **Phase signals not on SignalBus** — `autoloads/build_phase_manager.gd` (`build_phase_started`, `combat_phase_started`). **Rule:** signal-bus H1 A; add-new-entity signal template. **Impact:** fragmented lifecycle discovery vs `SignalBus`.

5. **Unchecked `spend_*` after afford check** — `scripts/weapon_upgrade_manager.gd` (~71–74). **Rule:** economy-system H2 B. **Impact:** weapon level vs currency desync if spend fails.

6. **`place_building_shop_free` skips `assert_build_phase`** — `scenes/hex_grid/hex_grid.gd` vs `place_building()`. **Rule:** building-system H2 C. **Impact:** shop voucher placement outside build-phase guard.

7. **`CampaignManager.current_day` mutated from `GameManager`** — **mitigated (I-E):** `GameManager` uses `CampaignManager.force_set_day()` (`advance_to_next_day`, `current_day_index` setter). **Rule:** campaign-and-progression H3 C. **Impact:** (historical) direct assignment; see Session I-E.

8. **AllyData accessed via `.get("role")` / `.get("ally_id")`** — **resolved (I-E):** typed `AllyData` access in `campaign_manager.gd` and `test_ally_data.gd`. **Rule:** campaign-and-progression H3 F; ally-and-mercenary H4 B.

9. **Mass test isolation gap** — **38** test files without `reset_to_defaults()` or `before_test()` (H3). **Rule:** testing SKILL. **Impact:** order-dependent flaky tests.

10. **`SignalBus.nav_mesh_rebake_requested` never emitted** — game code (H4). **Rule:** scene-tree-and-physics / SignalBus workflow. **Impact:** nav rebake path unused after terrain/build changes.

---

## Violations by Category

### TYPE_SAFETY

- AllyData / ally `Resource` dictionary `.get()` — **addressed in I-E** for `campaign_manager.gd` / `test_ally_data.gd` (H3/H4 historical).

### NULL_SAFETY

- (H1 AP-02 pattern sweep found no `target_enemy`/`target_ally`/`target_projectile` hits; not expanded.)

### SIGNAL_DISCIPLINE

- `BuildPhaseManager` parallel phase signals (H1).
- `nav_mesh_rebake_requested` unused (H4).
- AP-04: autoload↔autoload orchestration vs strict SignalBus (H1, qualitative).

### FIELD_NAMES

- H1 field-name discipline: **PASS** (0 wrong legacy names).

### SAVE_SYSTEM

- Autosave invoked from `GameManager` on `mission_won` / `mission_failed`, not from listeners inside `SaveManager` (H2).
- Save payload keys: **complete** per H5 (`campaign`, `game`, `relationship`, `research`, `shop`, `enchantments`).

### CUT_FEATURES

- H3/H4: no implementation of cut features (drunkenness, Time Stop, etc.) — **PASS**.

### TEST_ISOLATION

- 38 files without reset/before_test (H3).
- Bare `get_node` in multiple test files (H3).
- Two short test names (H3).
- SimBot `assert()` (H1).

### OTHER

- Magic numbers / tuning in code (H1 godot-conventions B).
- `print()` in `AutoTestDriver` (H1 AP-08 F).
- `projectile_base.tscn` default collision layer 0 until runtime init (H4).
- Production UI `character_id` literals — **addressed in I-E** (removed non-canonical match keys) (H5 historical).
- `docs/archived/OPUS_ALL_ACTIONS.md` RAG policy — **addressed in I-E** (archived banner) (H5 historical).

---

## Recommended Fix Sessions

| Fix session | Focus | Source skills | Approx. scope |
| --- | --- | --- | --- |
| **I1** | Replace `assert()` in SimBot with guards / `push_warning`; review AutoTestDriver `print()` → `printerr` or gated logging | anti-patterns, testing | `scripts/sim_bot.gd`, `autoloads/auto_test_driver.gd` |
| **I2** | Init order: `WaveManager` / `HexGrid` call `initialize*` before `add_child` where feasible, or document exception | anti-patterns, building-system | `wave_manager.gd`, `hex_grid.gd` |
| **I3** | Economy: check `spend_*` returns in `weapon_upgrade_manager.gd`; move passive accrual to `_physics_process` in `EconomyManager` | economy-system, godot-conventions | `scripts/weapon_upgrade_manager.gd`, `economy_manager.gd` |
| **I4** | SignalBus: emit phase transitions from bus or migrate listeners; emit `nav_mesh_rebake_requested` from terrain/build flows | signal-bus, scene-tree | `build_phase_manager.gd`, terrain/build callers |
| **I5** | Campaign: route day changes through `CampaignManager` APIs; typed `AllyData` fields in `campaign_manager.gd` | campaign-and-progression, ally | `game_manager.gd`, `campaign_manager.gd` |
| **I6** | Tests: add `before_test` / `reset_to_defaults` to high-risk suites; prefer `get_node_or_null` + guards | testing | `tests/**/*.gd` (prioritize autoload-touching) |
| **I7** | Building: `place_building_shop_free` → `assert_build_phase`; align skill doc with intentional post-`add_child` init if kept | building-system | `hex_grid.gd`, `shop_manager.gd` |
| **I8** | Docs/UI: mark RAG optional in archived doc or archive banner; align dialogue `character_id` stubs with master list or document placeholders | mcp-workflow, save-and-dialogue | `docs/archived/`, `ui/ui_manager.gd`, `ui/dialogue_ui.gd` |
| **I9** | Add `CampaignManager.force_set_day(day: int)` public method; replace the two direct `CampaignManager.current_day` assignments in `game_manager.gd` (~line 252 and ~line 306) with calls to it | campaign-and-progression | `game_manager.gd`, `campaign_manager.gd` |

---

## Clean Areas

| Area | Evidence |
| --- | --- |
| **add-new-entity (H5)** | BuildingType append-only in recent history; all `building_id` ↔ `.tres` stems match; research data has no bare `id`; INDEX_SHORT basename coverage 100% for `autoloads/`+`scripts/`+`scenes/` `.gd`. |
| **enemy-system (H2)** | Field names, DamageCalculator signatures, flying/nav split, Brood Carrier spawn path — **PASS**. |
| **spell-and-research-system (H4)** | SpellManager paths, `slow_field.tres`, no Time Stop, `research_cost` only, Enchantment save wired — **PASS**. |
| **lifecycle-flows (H3)** | `Engine.time_scale` build mode, `wave_cleared` rewards, `all_waves_cleared` → `mission_won`, enemy `queue_free` — **PASS** (visual `.free()` caveat only). |
| **Save payload keys (H5)** | All six top-level keys present; every `get_save_data()` implementation included. |
| **SaveManager / RelationshipManager `class_name` (H5)** | **PASS** (comments only). |
| **scene-tree manager paths (H4)** | Contracted `Managers/*` resolution — **PASS**. |
| **SignalBus** — logic-free | H1 AP-13 **PASS**. |
| **Cross-system `signal` declaration** | H1: only `build_phase_manager` + local ally signal flagged. |

---

## Session cross-reference index

| H-session | Primary skills | Report file |
| --- | --- | --- |
| H1 | godot-conventions, anti-patterns, signal-bus | `docs/COMPLIANCE_REPORT_H1.md` |
| H2 | enemy-system, building-system, economy-system | `docs/COMPLIANCE_REPORT_H2.md` |
| H3 | campaign-and-progression, testing, lifecycle-flows | `docs/COMPLIANCE_REPORT_H3.md` |
| H4 | scene-tree-and-physics, spell-and-research-system, ally-and-mercenary-system | `docs/COMPLIANCE_REPORT_H4.md` |
| H5 | mcp-workflow, add-new-entity, save-and-dialogue | `docs/COMPLIANCE_REPORT_H5.md` |

---

## Session I-E action items (2026-03-31)

| Item | Status | Notes |
| --- | --- | --- |
| **I2** | Open | Not addressed in I-E |
| **I3** | Open | Not addressed in I-E |
| **I5** | **RESOLVED** | AllyData typed fields in `campaign_manager.gd`; `test_ally_data.gd` |
| **I7** | Open | Not addressed in I-E |
| **I8** | **RESOLVED** | Archived RAG banner; UI dialogue display-name match uses canonical IDs only |
| **I9** | **RESOLVED** | `CampaignManager.force_set_day()`; `GameManager` routes calendar writes through it |
| **DIAG-1 docs** | **RESOLVED** | AGENTS.md gotcha 7 + campaign skill Init Order note |

*End of Master Compliance Report.*
