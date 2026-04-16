# Foul Ward — Agent Standing Orders
Last updated: 2026-04-14 (doc sync: SignalBus dialogue signals, **67** signal-count parity across docs, test baseline)

> Read this file FIRST in every Cursor session, before opening any other file.
> This file is the always-loaded foundation. It points to skills for detail.

---

## What

Godot 4.4 GDScript real-time tower defense (inspired by TAUR).
Player IS Florence — a stationary tower aimed manually with the mouse.
50-day main campaign. Each day = one mission (build phase → wave combat).
612 GdUnit4 tests. 17 autoloads. 36 building types. 30 enemy types. **67** SignalBus signals (verified **2026-04-14** against `^signal ` lines in `autoloads/signal_bus.gd`).
When you add or remove a SignalBus signal, bump that total and update every location listed under **Signal count in documentation** in `.cursor/skills/signal-bus/SKILL.md`.
Two weapons: Crossbow (CROSSBOW slot) and Rapid Missile (RAPID_MISSILE slot).
AI ally Arnulf (melee), Sybil (spell support). Hex grid: 24 slots across 3 rings.

---

## Architecture

17 autoloads init in strict order (SignalBus first, EnchantmentManager last).
6 scene-bound managers live under `/root/Main/Managers/` — not autoloads.
All data is resource-driven (.tres files). No magic numbers in .gd scripts.
All cross-system events go through SignalBus — no direct calls between autoloads.
SimBot / AutoTestDriver enables headless simulation without UI nodes.

### Autoload Init Order (DO NOT CHANGE without reading `AGENTS.md` and `docs/FOUL_WARD_MASTER_DOC.md` §3)

1.  SignalBus (`autoloads/signal_bus.gd`) — no deps
2.  NavMeshManager (`scripts/nav_mesh_manager.gd`) — no deps
3.  DamageCalculator (`autoloads/DamageCalculator.cs`) — no deps
4.  AuraManager (`autoloads/aura_manager.gd`) — no deps
5.  EconomyManager (`autoloads/economy_manager.gd`) — depends on SignalBus
6.  CampaignManager (`autoloads/campaign_manager.gd`) — MUST load before GameManager
7.  RelationshipManager (`autoloads/relationship_manager.gd`)
8.  SettingsManager (`autoloads/settings_manager.gd`)
9.  GameManager (`autoloads/game_manager.gd`) — depends on CampaignManager
10. BuildPhaseManager (`autoloads/build_phase_manager.gd`)
11. AllyManager (`autoloads/ally_manager.gd`)
12. CombatStatsTracker (`autoloads/combat_stats_tracker.gd`)
13. SaveManager (`autoloads/save_manager.gd`)
14. DialogueManager (`autoloads/dialogue_manager.gd`)
15. AutoTestDriver (`autoloads/auto_test_driver.gd`)
16. GDAIMCPRuntime — editor only
17. EnchantmentManager (`autoloads/enchantment_manager.gd`)

**Dialogue line events:** `dialogue_line_started` and `dialogue_line_finished` are **declared on `SignalBus`** (`autoloads/signal_bus.gd`). `DialogueManager` emits them via `SignalBus` only — they are not local signals on DialogueManager. UI and tests connect to `SignalBus`.

### Scene-Bound Manager Paths (contracted — never assume)

- `/root/Main/Managers/WaveManager`
- `/root/Main/Managers/SpellManager`
- `/root/Main/Managers/ResearchManager`
- `/root/Main/Managers/ShopManager`
- `/root/Main/Managers/WeaponUpgradeManager`
- `/root/Main/Managers/InputManager`

---

## How to Verify Changes

```bash
dotnet build FoulWard.csproj       # required when .cs files change; before run_gdunit.sh
./tools/run_gdunit_quick.sh        # after every change (~fast)
./tools/run_gdunit_unit.sh         # unit tests only, ~65s
./tools/run_gdunit_parallel.sh     # full suite, 8 parallel, ~2m45s
./tools/run_gdunit.sh              # sequential baseline before declaring done
```

- `.cs` files → run `dotnet build` before `run_gdunit.sh`.
- `FoulWardTypes.cs` = C# enum mirror. `.cs` imports it. `.gd` never does.

NOTE: godot-mcp-pro and gdai-mcp-godot live outside the repo at ../foulward-mcp-servers/ and are not in version control.

| Server (name in `.cursor/mcp.json`) | Path (relative to repo root) |
|-------------------------------------|------------------------------|
| `godot-mcp-pro` | `../foulward-mcp-servers/godot-mcp-pro` |
| `gdai-mcp-godot` | `../foulward-mcp-servers/gdai-mcp-godot` |

MCP verification after every session:
- `get_scene_tree` — validate node paths before any get_node() call
- `get_godot_errors` — check for new errors after changes

---

## Critical Rules (always apply)

1. Static typing on ALL parameters, returns, and variable declarations
2. ALL cross-system events through SignalBus — no direct connects between unrelated nodes
3. Access autoloads by name: `EconomyManager.add_gold(50)` — never cache in a var
4. No magic numbers — all tuning in .tres resources or named constants in types.gd
5. `get_node_or_null()` for runtime lookups — never bare `get_node()` in headless contexts
6. `is_instance_valid()` before accessing enemies, projectiles, or allies (freed mid-frame)
7. `push_warning()` not `assert()` in production — assert() crashes headless builds
8. Signals: past tense for events (`enemy_killed`), present for requests (`build_requested`)
9. `_physics_process` for game logic — `_process` for visual/UI only — NEVER mix
10. Scene instantiation: call `initialize()` before or immediately after `add_child()`
11. ALL cross-system events use SignalBus — no direct method calls between autoloads for events
12. ALL node path lookups use `get_node_or_null()` with null guard
13. `SaveManager.save_current_state()` auto-called on mission_won/failed — no extra save calls
14. EVERY new .gd file → add to `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`
15. EVERY session → log to `docs/PROMPT_[N]_IMPLEMENTATION.md` (next unused N)
16. EVERY new signal declared in `autoloads/signal_bus.gd`, past tense snake_case

---

## Field Name Discipline (wrong → correct)

| ❌ Wrong | ✅ Correct | Where |
|---|---|---|
| `build_gold_cost` | `gold_cost` | BuildingData |
| `targeting_priority` | `target_priority` | BuildingData |
| `base_damage_min` / `base_damage_max` | `damage` (single float) | WeaponData |
| `rp_cost` | `research_cost` | ResearchNodeData |
| `hp` / `health` | `max_hp` | EnemyData, AllyData |
| `spell_type` | spell_id is a String | SpellData |
| `Types.SpellType` | does NOT exist | Types.gd |
| `Types.SpellID` | does NOT exist | Types.gd |

---

## Formally Cut Features — NEVER Implement

- **Arnulf drunkenness system** — cut, do not implement
- **Time Stop spell** — cut, do not implement
- **Hades-style 3D hub** — cut, do not implement
- **Sybil passive selection system** — PLANNED, not in code yet; stubs only
- **Affinity XP system (EnchantmentManager)** — POST-MVP, all methods inert

---

## Available Skills — Load Before Working on That System

| When working on... | Load this skill |
|---|---|
| Naming, typing, style, field names | `.cursor/skills/godot-conventions/` |
| Code review, bugs, wrong patterns | `.cursor/skills/anti-patterns/` |
| Signals, SignalBus, connect/emit | `.cursor/skills/signal-bus/` |
| Enemies, damage, armor, bosses | `.cursor/skills/enemy-system/` |
| Buildings, hex grid, placement | `.cursor/skills/building-system/` |
| Gold, resources, costs, refunds | `.cursor/skills/economy-system/` |
| Campaign, days, territories, GameManager | `.cursor/skills/campaign-and-progression/` |
| GdUnit4 tests, SimBot, headless | `.cursor/skills/testing/` |
| Adding new building/signal/spell/research | `.cursor/skills/add-new-entity/` |
| MCP servers, Godot MCP, GDAI | `.cursor/skills/mcp-workflow/` |
| Scene tree, physics layers, input | `.cursor/skills/scene-tree-and-physics/` |
| Spells, mana, research, enchantments | `.cursor/skills/spell-and-research-system/` |
| Allies, Arnulf, mercenaries | `.cursor/skills/ally-and-mercenary-system/` |
| Mission flow, game loop, startup | `.cursor/skills/lifecycle-flows/` |
| Save/load, dialogue, relationships | `.cursor/skills/save-and-dialogue/` |

---

## Key Documents

| File | Purpose |
|---|---|
| `docs/FOUL_WARD_MASTER_DOC.md` | Human-readable encyclopedia — all systems |
| `AGENTS.md` (repo root, this file) | Lean standing orders — read first; symlinked as `.cursorrules` |
| `docs/CONVENTIONS.md` | Naming, typing, style law |
| `docs/ARCHITECTURE.md` | Scene tree, class responsibilities, signal flow |
| `docs/INDEX_SHORT.md` | One-liner per file index |
| `docs/INDEX_FULL.md` | Full public API reference |
| `docs/SUMMARY_VERIFICATION.md` | Read-only audit results |

---

## Known Gotchas (top 7 — see `docs/FOUL_WARD_MASTER_DOC.md` for full gotchas and agent rules)

1. **AllyData is a Resource** — use typed field access (`ally_data.ally_id`), not `.get(key, default)`
2. **CampaignManager MUST load before GameManager** — day increment must fire before hub transition
3. **WaveManager is a scene node, not an autoload** — GameManager silently skips if absent (headless safe)
4. **SaveManager / RelationshipManager have no `class_name`** — intentional; do not add one
5. **`slow_field.tres` has `damage = 0.0`** — intentional control spell; do not fix
6. **`mission_won` listener order is load-order-dependent** — `CampaignManager` increments `current_day` in its `_on_mission_won` listener. `GameManager`'s hub transition listener runs after because `CampaignManager` is autoload #6 and `GameManager` is autoload #9. Never reorder these autoloads and never connect to `mission_won` in a way that fires before `CampaignManager`.
7. **`GameManager.advance_to_next_day()` and `current_day_index` setter** — route calendar updates through `CampaignManager.force_set_day(day: int)` (DIAG-1 mitigation). Do not assign to `CampaignManager.current_day` directly elsewhere; do not replicate the old pattern.
8. **Dialogue line signals live on SignalBus** — connect `SignalBus.dialogue_line_started` / `dialogue_line_finished`, not `DialogueManager` local signals (none exist).
