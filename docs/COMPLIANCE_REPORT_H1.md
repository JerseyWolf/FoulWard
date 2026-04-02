# Compliance Report H1 — Conventions, Anti-Patterns, Signal Bus
Date: 2026-03-31

Scope: Audited per Agent Skills `godot-conventions`, `anti-patterns`, and `signal-bus` (plus `signal-bus/references/signal-table.md`). Swept **`autoloads/`**, **`scripts/`**, **`scenes/`** where specified; signal declaration sweep includes **project** `.gd` under those roots plus **`ui/`** for Check 3A (addons such as `gdUnit4/`, `addons/godot_mcp/`, GDAI — excluded from counts unless noted). **Report only — no code fixes applied.**

---

## Skill: godot-conventions

### A. Static typing — **PASS (0 violations)**
- Command used: `grep -rn "^func " … | grep -v -- '->'` initially surfaced multi-line signatures; follow-up search for single-line `func …(…):` without `->` in `autoloads/`, `scripts/`, `scenes/` found **no matches**.
- Multi-line functions checked (`campaign_manager.gd`, `damage_calculator.gd`): parameters and returns are typed on continuation lines.

### B. Magic numbers — **14 representative violations flagged** (heuristic: literals ≥10 / notable tunables in code paths; excludes pure comments/URLs where obvious)
| File:line | Approximate issue |
|-----------|-------------------|
| `autoloads/game_manager.gd:637` | `base_gold_reward: int = 50 * current_mission` — reward formula constant in code. |
| `autoloads/game_manager.gd:645-648` | Mission win grants: `add_building_material(3)`, `add_research_material(2 + extra_rm)` — hardcoded 3 / 2. |
| `autoloads/campaign_manager.gd:474` | Cost curve divisor `300.0` in `_score_offer`. |
| `autoloads/economy_manager.gd:11-12,22` | `DEFAULT_GOLD = 1000`, `DEFAULT_BUILDING_MATERIAL = 50`, `PLAYTEST_STARTING_RESEARCH_MATERIAL = 50` — economy defaults in script (may be intentional bootstrap). |
| `autoloads/dialogue_manager.gd:241` | `max_priority := -999999` — magic sentinel. |
| `autoloads/combat_stats_tracker.gd:234` | `slot_index < 24` — hex slot count as literal (often `types`/const). |
| `scripts/shop_manager.gd:12` | `CONSUMABLE_STACK_CAP: int = 20`. |
| `scripts/input_manager.gd:28` | `_HEX_SLOT_COLLISION_MASK: int = 64`. |
| `scripts/spell_manager.gd:25` | `@export var max_mana: int = 100` — tuning in script/export. |
| `scripts/spell_manager.gd` (shockwave comment / usage) | `100.0` map radius referenced in comments / spell data pattern — verify lives only in `.tres`. |
| `scripts/wave_manager.gd:297,651,687` | Seed arithmetic `1009`, `1315423911`, `7919`, `17` — algorithm constants. |
| `scripts/sim_bot.gd:460,626,1134,1214,1310` | `1000` stride seeds, `max_frames` 1200 / 12000, `* 1000.0` scoring, `7919/104729` seeds. |
| `scripts/wave_composer.gd:29,52,167` | `safety: int = 256`, default budget `40`, `wave_number <= 23`. |
| `scripts/ui/settings_screen.gd:57` | `Vector2(180, 0)` UI dimension literal. |

*Note:* Many `scripts/resources/*.gd` defaults appeared in a broader numeric grep; Check B as written scoped **`autoloads/`**, **`scripts/`**, **`scenes/`** only (not `resources/`).

### C. Autoload caching — **PASS (0 true cache violations)**
- Broad `grep "var.*= EconomyManager|…"` matched **method calls** (e.g. `EconomyManager.get_gold()`), not singleton assignment.
- Targeted search for single-line untyped `func …):` yielded no false baseline; no `var x := EconomyManager` / `= EconomyManager` **singleton reference** lines found in scoped trees.

### D. `_process` vs `_physics_process` — **1 violation**
| File:line | Finding |
|-----------|---------|
| `autoloads/economy_manager.gd:52-69` | `func _process` applies passive gold/material (`add_gold`, `add_building_material`) — **game/economy state mutation**, not visual/UI-only. Rule 14: game logic should use `_physics_process`. |

### E. Field name discipline — **PASS (0 violations)**
- `grep` for `build_gold_cost`, `targeting_priority`, `base_damage_min/max`, `rp_cost`, `\\.hp\\b`, `\\.health\\b`, `Types.SpellType`, `Types.SpellID` across `autoloads/`, `scripts/`, `scenes/`, `resources/`: **no matches**.

### F. `class_name` on SaveManager / RelationshipManager — **PASS (0 violations)**
- `grep "class_name"` on `save_manager.gd` / `relationship_manager.gd`: only appears in **comments** documenting the intentional omission.

---

## Skill: anti-patterns

### A. Bare `get_node()` (AP-01) — **PASS (0 violations)**
- `grep "get_node("` excluding `get_node_or_null` / commented lines in `autoloads/`, `scripts/`, `scenes/`: **no hits**.

### B. `is_instance_valid()` before `target_enemy|target_ally|target_projectile` (AP-02) — **PASS (0 hits for requested pattern)**
- `grep "target_enemy\\.\\|target_ally\\.\\|target_projectile\\."` in scoped trees: **no matches** (code may use `_current_target`, `enemy`, etc.). *Sweep was pattern-limited as specified.*

### C. `assert()` in production (AP-03) — **3 violations**
| File:line | Rule |
|-----------|------|
| `scripts/sim_bot.gd:546` | `assert(_wave_manager != null, …)` |
| `scripts/sim_bot.gd:547` | `assert(_spell_manager != null, …)` |
| `scripts/sim_bot.gd:548` | `assert(_hex_grid != null, …)` |

*`tests/` excluded per instructions.*

### D. Direct cross-system calls bypassing SignalBus (AP-04) — **Policy gap (representative examples; pervasive pattern)**
Autoloads frequently call other autoloads inside signal handlers / mission flow instead of chaining only via SignalBus payloads. Examples:

| File:line | Call pattern |
|-----------|----------------|
| `autoloads/economy_manager.gd:73-77` | `_on_enemy_killed` → `GameManager.get_aggregate_flat_gold_per_kill()` then `add_gold`. |
| `autoloads/enchantment_manager.gd:84-86` | Purchase path → `EconomyManager.can_afford` / `spend_gold`. |
| `autoloads/campaign_manager.gd:318-322` | Mercenary purchase → `EconomyManager.spend_*`. |
| `autoloads/dialogue_manager.gd:48-55,291-295` | Condition evaluation → `EconomyManager.get_*` / `GameManager.get_*`. |

*Many such calls are orchestration; strict AP-04 would push more state changes behind bus events or shared query APIs — documented as architectural debt, not a line-by-line enumeration.*

### E. `add_child` before `initialize` / `initialize_*` (AP-06) — **7 violations** (initialize after add)
| File:line | Order observed |
|-----------|----------------|
| `scripts/wave_manager.gd:439-444` | `add_child(enemy)` then `enemy.initialize(tuned)`. |
| `scripts/wave_manager.gd:461-466` | Same pattern (`spawn_enemy_at_position`). |
| `scripts/wave_manager.gd:558-562` | `add_child(boss)` then `boss.initialize_boss_data(boss_data)`. |
| `scripts/wave_manager.gd:574-579` | `add_child(enemy)` then `enemy.initialize(tuned)` (escorts). |
| `scripts/wave_manager.gd:755-760` | `add_child(enemy)` then `enemy.initialize(tuned_enemy_data)` (`_spawn_enemy_from_composed_data`). |
| `scenes/hex_grid/hex_grid.gd:202-205` | `add_child(building)` then `initialize_with_economy(...)`. |
| `scenes/hex_grid/hex_grid.gd:225-228` | Same for free-placement branch. |

### F. stdout / `print()` in AutoTestDriver / GDAI (AP-08) — **34 `print()` statements**
- **All in** `autoloads/auto_test_driver.gd` at lines: **62-64, 100, 114, 137, 148, 154, 160, 183, 189, 210, 219, 226, 234, 240, 248, 252, 258, 269, 274, 278, 286, 290, 299, 311, 314, 324, 327, 339, 344-346** (plus continuation lines inside multi-line `print` args).
- No GDAI bridge scripts under project `autoloads/` were flagged beyond AutoTestDriver in this sweep.

---

## Skill: signal-bus

### A. Cross-system `signal` outside `signal_bus.gd` — **2 violations (autoload bus overlap)**
| File | Signals | Assessment |
|------|---------|------------|
| `autoloads/build_phase_manager.gd:12-13` | `build_phase_started`, `combat_phase_started` | **Autoload** emitting phase lifecycle; consumers cross subsystems — skill text expects such **cross-system** events on `SignalBus` (alongside existing `build_mode_entered` / `build_mode_exited`). |
| *(informational)* `scenes/allies/ally_base.gd:28` | `ally_died` (no args) | **Local** node signal; acceptable. Name overlaps conceptually with `SignalBus.ally_died` (different payload) — **naming collision risk**, not a bus placement violation. |

Other `^signal` hits in `ui/`, `dialogue_manager.gd`, `health_component.gd`, hub scenes — treated as **local/UI** unless consumed as global bus (not escalated).

### B. `is_connected` guard on `SignalBus.*.connect` — **PASS (0 high-risk findings)**
- `CombatStatsTracker._connect_signals()` and `GameManager._connect_mission_won_transition_to_hub()` use **guards**.
- `SimBot.activate()` early-returns when already active (`scripts/sim_bot.gd:79-80`), preventing duplicate connects without explicit `is_connected` on every line.
- Many `_ready()` connects are unguarded but **single-shot** for singletons/scene roots — low risk per audit instructions.

### C. Logic / state in `signal_bus.gd` (AP-13) — **PASS (intent)**
- File contains **`extends Node`**, **`@warning_ignore("unused_signal")`**, comments, and **`signal` declarations only** — **no `var`, `func`, or executable logic.**

### D. Signal naming (past vs present) — **PASS (0 clear future-tense violations)**
- Reviewed `^signal` lines in `autoloads/signal_bus.gd`: names use past participle / noun-phrase events (e.g. `wave_cleared`, `mission_started` as common game-industry convention) or **requests** in present-ish form (`build_mode_entered` — treated as completed transition event). No `will_*` / future-tense names found.

### E. Untyped signal payloads on SignalBus — **PASS (0 violations)**
- Every `signal` in `autoloads/signal_bus.gd` either has **fully typed parameters** or **no parameters**. No bare `Variant` / untyped parameter lists observed.

---

## Priority Violations
Ranked by likely **runtime / headless / architecture** impact:

1. **AP-06** — `WaveManager` + `HexGrid` call `add_child` **before** `initialize` / `initialize_with_economy` / `initialize_boss_data`. Violates Prompt 11 / AP-06 ordering; can cause `_ready`-time defaults and ordering bugs.
2. **godot-conventions D** — `EconomyManager._process` runs economy accrual; should be `_physics_process` per project LAW for gameplay logic.
3. **AP-03** — `assert()` in `SimBot.run_single` can abort **headless** / CI where managers are intentionally absent or lazy-loaded.
4. **AP-04 gap** — Tight **autoload↔autoload** coupling (e.g. `EconomyManager` ↔ `GameManager` on `enemy_killed`) complicates testing and strict SignalBus purity.
5. **signal-bus A** — **`BuildPhaseManager`** exposes parallel phase signals not on `SignalBus`, fragmenting the same concern as `build_mode_*` on the bus.

---

## Total Violation Count

| Skill / Check | Count |
|---------------|------:|
| **godot-conventions A** | 0 |
| **godot-conventions B** | 14 (sampled representative) |
| **godot-conventions C** | 0 |
| **godot-conventions D** | 1 |
| **godot-conventions E** | 0 |
| **godot-conventions F** | 0 |
| **anti-patterns A** | 0 |
| **anti-patterns B** | 0 |
| **anti-patterns C** | 3 |
| **anti-patterns D** | *qualitative (pervasive + 4 examples listed)* |
| **anti-patterns E** | 7 |
| **anti-patterns F** | 34 |
| **signal-bus A** | 2 |
| **signal-bus B** | 0 |
| **signal-bus C** | 0 |
| **signal-bus D** | 0 |
| **signal-bus E** | 0 |
| **Grand total (numeric only)** | **61** + AP-04 (not numerically capped) |

---

*End of Compliance Report H1.*
