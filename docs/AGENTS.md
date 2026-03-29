# FOUL WARD — Agent Standing Orders
Last updated: 2026-03-28 by Opus 4.6 (Prompt 27)

Read this file FIRST in every Cursor session, before opening any other file.

## 1. Orientation (do at the start of every session)
- Read: `docs/INDEX_SHORT.md`, `docs/CONVENTIONS.md`
- **RAG (`query_project_knowledge`) requires manual start.** Before relying on it, call it once and verify it responds. If it errors, proceed without it and note the limitation in this session's implementation log.
- If task involves tests: read `tools/run_gdunit.sh` and the relevant test files
- If task involves resources: check `docs/PROMPT_26_PRE_RESOURCE_SCAN.txt` for known placeholder fields
- If task involves scene nodes: use Godot MCP `get_scene_tree` to read the scene tree — never assume node paths
- If task involves autoloads: check `project.godot` registration order before assuming load order
- If task involves balance or economy: read `IMPROVEMENTS_TO_BE_DONE.md` Section 6 for stub status

## 2. MCP Tool Rules (non-negotiable)
- ALWAYS use Godot MCP `get_scene_tree` to validate scene tree paths before writing any `get_node()` call
- ALWAYS use Godot MCP `get_godot_errors` after making changes to check for new errors
- If RAG is available (`query_project_knowledge`), call it before writing new code for an existing system
- If RAG is available (`get_recent_simbot_summary`), call it when your task touches balance, economy, or wave scaling
- If any MCP tool fails to respond: note it in your implementation log and continue
- RAG (`foulward-rag`) is NOT always available — it requires a running service from `~/LLM` (Prompt 18). Check for it but do not block on it.

## 3. File Change Rules (non-negotiable)
- EVERY new .gd file must be added to `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`
- EVERY deleted or renamed file must be removed/updated in both index files
- EVERY session must log to `docs/PROMPT_[N]_IMPLEMENTATION.md` (use the next unused N)
- EVERY new autoload must be registered in `project.godot` in the correct load order:
  1. SignalBus (no dependencies)
  2. DamageCalculator (no dependencies)
  3. EconomyManager (depends on SignalBus)
  4. CampaignManager (depends on SignalBus — must load BEFORE GameManager)
  5. RelationshipManager (depends on SignalBus, after CampaignManager)
  6. SettingsManager (depends on SignalBus, after RelationshipManager)
  7. GameManager (depends on SignalBus, EconomyManager, CampaignManager)
  8. CombatStatsTracker (depends on SignalBus, EconomyManager; reads GameManager mission id via signals / optional nodes)
  9. SaveManager (depends on CampaignManager, GameManager, EnchantmentManager)
  10. DialogueManager (depends on SignalBus, GameManager, ResearchManager)
  11. AutoTestDriver (depends on GameManager)
  12. EnchantmentManager (depends on SignalBus)
- EVERY new signal must be declared in `autoloads/signal_bus.gd`, named in past tense snake_case
- EVERY new .tres resource file must be referenced by at least one .gd file or other .tres

## 4. Test Rules (non-negotiable)
- Run `./tools/run_gdunit_quick.sh` after EVERY change. Fix failures before continuing.
- Run `./tools/run_gdunit_unit.sh` for fast feedback (unit tests only, 33 files, ~65s). Use this during iterative development.
- Run `./tools/run_gdunit_parallel.sh` as the pre-completion check (all 58 files, 8 parallel processes, ~2m45s). Replaces `run_gdunit.sh` for faster full-suite validation.
- Run `./tools/run_gdunit.sh` as the definitive sequential baseline before declaring any task complete.
- All new tests go in `res://tests/` as GdUnit4 suites
- All tests must be headless-safe: no UI nodes, no editor APIs, no `@tool`
- Tests that use `await` or timers are Integration tests — keep them out of `run_gdunit_unit.sh`
- New test files must be added to the allowlist in `run_gdunit_quick.sh` if they are lightweight
- GdUnit exit code 101 means warnings only (typically orphan nodes) — treat as pass when failure count is 0
- GdUnit exit code 100 with "0 failures" in the log means GodotGdErrorMonitor counted `push_warning` calls — treat as pass

## 5. Code Conventions (enforced)
1. **Static typing everywhere**: all function parameters, return types, and variable declarations must have explicit types
2. **Signals through SignalBus**: all cross-system events go through `SignalBus` — no direct `.connect()` between unrelated nodes
3. **Autoload access by name**: `EconomyManager.add_gold(50)`, never `var econ = EconomyManager`
4. **No magic numbers**: all gameplay tuning lives in `.tres` resource files or named constants in `types.gd`
5. **`get_node_or_null()` for runtime lookups**: never bare `get_node()` for paths that might not exist in headless/test contexts
6. **`is_instance_valid()` before accessing freed nodes**: enemies, projectiles, and allies can be freed mid-frame
7. **`push_warning()` not `assert()` in production**: `assert()` crashes headless builds; use `push_warning()` + early return
8. **snake_case signals, past tense for events**: `enemy_killed`, `wave_cleared`, `building_placed`
9. **`_physics_process` for game logic**: `_process` is for visual/UI only
10. **Scene instantiation via `initialize()`**: never set properties after `add_child()`; call `initialize()` before or immediately after

## 6. Architecture Rules (enforced)
- ALL cross-system events go through SignalBus — no direct method calls between autoloads for events
- ALL node path lookups use `get_node_or_null()` with a null guard — never bare `get_node()`
- ALL scene node access is gated: `if not is_instance_valid(node): return`
- Autoload singletons are accessed by name (`CampaignManager.x`), never cached in `var _cm = CampaignManager`
- `SaveManager.save_current_state()` is called automatically on `mission_won` and `mission_failed` — do not add extra save calls
- RelationshipManager events are driven by `RelationshipEventData` .tres resources — do not hardcode deltas in .gd files
- Manager node paths are contracted (see ARCHITECTURE.md §2 "Manager node path contracts"):
  - `/root/Main/Managers/WaveManager`
  - `/root/Main/Managers/ResearchManager`
  - `/root/Main/Managers/WeaponUpgradeManager`
  - `/root/Main/Managers/ShopManager`
  - `/root/Main/Managers/SpellManager`
  - `/root/Main/Managers/InputManager`

## 7. Prohibited Actions (never do these)
- Never add UI node references to SimBot, autoloads, or headless-capable scripts
- Never call DialogueManager or FlorenceManager inside `if CampaignManager.is_endless_mode`
- Never change the autoload registration order in `project.godot` without reading this document first
- Never use `assert()` in production code — use `push_warning()` or `push_error()`
- Never write a `get_save_data()` or `restore_from_save()` method without also wiring it into SaveManager's `_build_save_payload()` / `_apply_save_payload()`
- Never emit a SignalBus signal from a test using the real autoload without resetting state in `after_test()`
- Never add a `class_name` to `SaveManager` or `RelationshipManager` — they are autoload-only singletons (avoids GdUnit shadowing)
- Never `print()` to stdout in MCP bridge scripts (GDAI) — only JSON-RPC may use stdout; debug logs go to stderr

## 8. Before Declaring a Task Complete
- [ ] All new/modified files are in `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`
- [ ] `docs/PROMPT_[N]_IMPLEMENTATION.md` exists and lists all files created/modified
- [ ] `./tools/run_gdunit.sh` (or parallel equivalent) passes with 0 failures
- [ ] Godot MCP `get_godot_errors` shows no new errors introduced by this session
- [ ] Any new .tres resources have all required fields populated (no empty IDs, no zero costs where non-zero is required)
- [ ] AGENTS.md updated if any new standing order was established this session

## 9. Known Gotchas
1. **AllyData is a Resource** — do not call `.get(key, default)` with two arguments; use typed field access instead (e.g., `ally_data.ally_id`, not `ally_data.get("ally_id", "")`)
2. **`run_gdunit_quick.sh` exits 101 for orphan/warning noise** — treat as pass when failure count is 0. The script already handles this.
3. **SaveManager has no `class_name`** — this is intentional to avoid shadowing the autoload singleton in GdUnit tests. Same for RelationshipManager. Do not add `class_name` to either.
4. **CampaignManager MUST load before GameManager in `project.godot`** — `mission_won` signal listeners run in autoload registration order; CampaignManager's day increment must fire before GameManager's hub transition.
5. **EnchantmentManager loads AFTER GameManager in `project.godot`** — `GameManager.start_new_game()` calls `EnchantmentManager.reset_enchantments()`; this works because both are in the tree by `_ready()` time, but registration order means EnchantmentManager's `_ready()` runs after GameManager's.
6. **WaveManager is a scene node, not an autoload** — it lives at `/root/Main/Managers/WaveManager`. GameManager resolves it via `get_node_or_null()` and silently skips wave spawning if absent (allows headless testing without `main.tscn`).
7. **`DialogueManager.dialogue_line_finished` bypasses SignalBus** — UIManager connects directly to this signal on the DialogueManager autoload. This is a known convention violation; future work should add this signal to SignalBus.
8. **GdUnit exit code 100 vs 101** — 100 means GodotGdErrorMonitor counted errors (often from expected `push_warning()` calls); 101 means orphan nodes detected. Both are treated as pass by `run_gdunit_quick.sh` when the log shows 0 test failures.
9. **`slow_field.tres` has `damage = 0.0`** — this is intentional (control spell). Do not "fix" it.
10. **`SettingsManager.set_graphics_quality()` stores a string but does not call RenderingServer** — graphics quality is persistence-only in MVP; actual rendering API calls are POST-MVP.
11. **50-day campaign DayConfigs all have empty `faction_id`** — this is placeholder; WaveManager falls back to `DEFAULT_MIXED` faction when `faction_id` is empty.
12. **SimBot's `compute_difficulty_fit()` difficulty-based early exit is effectively unreachable** — it requires prior batch log data that is empty during interactive `activate()` runs. Mission completion still ends runs via `all_waves_cleared`.
