INDEX_SHORT.md
==============

FOUL WARD — INDEX_SHORT.md

Compact repository reference. One-liner per file. **Master doc:** `docs/FOUL_WARD_MASTER_DOC.md` — living comprehensive reference for developers and LLM agents (APIs, lifecycle, anti-patterns, SimBot vs GdUnit). **Doc layout:** `docs/README.md`. **Audit aggregate:** `docs/SUMMARY_VERIFICATION.md`. **Session logs:** the 10 most recent `PROMPT_N_IMPLEMENTATION.md` files live in `docs/` (rolling window); full history is under `docs/archived/prompts/`. Historical prompt-by-feature notes in the long paragraph below were superseded by that folder layout (2026-04-20 cleanup). **Source of truth for behaviour:** the repo (`.gd`/`.cs`/`.tres`/tests), not deleted REPO_DUMP exports. **Verify changes:** `./tools/run_gdunit_quick.sh` (iterate) or `./tools/run_gdunit_parallel.sh` (full).

AGENT STANDING ORDERS & CURSOR SKILLS (read `AGENTS.md` first)
`README.md` (repo root) — GitHub default landing page: project summary, quick build/test, one teaser Mermaid diagram, links to `HOW_IT_WORKS.md`, `INTERVIEW_CHEATSHEET.md`, and `AGENTS.md`.
`AGENTS.md` (repo root) — Lean standing orders for every session; symlinked as `.cursorrules`; skills table + deep systems reference in `docs/FOUL_WARD_MASTER_DOC.md`.
`HOW_IT_WORKS.md` (repo root) — Comprehensive walkthrough of Foul Ward's AI-governance layer (AGENTS.md, 14 skills, MCPs), `foulward-rag` MCP (hybrid BM25 + semantic retrieval over 4 ChromaDB collections with LangGraph + SQLite memory), four-tier GdUnit4 pipeline + exit-code taxonomy, `AutoTestDriver` / SimBot balance loop, 19-autoload architecture-as-policy, C#/GDScript boundary (`FoulWardTypes.cs`), and gen3d pipeline; layered (TL;DR → executive summary → deep dives → trade-offs → numbers table → file map), Mermaid diagrams, current metrics (19 autoloads / 77 signals / 665 tests; prompt logs: **`PROMPT_80`…`PROMPT_89`** rolling window in `docs/`, full history in `docs/archived/prompts/`). Written to supplement CV as interview reference.
`INTERVIEW_CHEATSHEET.md` (repo root) — One-page talking-points companion to `HOW_IT_WORKS.md`: 30-second pitch, numbers-to-remember table, one-liner-per-subsystem, six STAR answers, three honest trade-offs, recommended words to use / avoid, 8-step repo tour for an interviewer reading the code live.
`docs/archived/prompts/` — full `PROMPT_N_IMPLEMENTATION.md` history (Perplexity batch planning artefacts removed 2026-04-20; see logs PROMPT_68–69 there).
`.cursor/skills/add-new-entity/SKILL.md` — Templates for new buildings, enemies, spells, research nodes, and SignalBus signals (`types.gd`, `signal_bus.gd`, `.tres` authoring).
`.cursor/skills/ally-and-mercenary-system/SKILL.md` — Allies, Arnulf, Sybil, mercenaries, roster, summoner squads (`AllyManager`, `AllyData`, ally scenes).
`.cursor/skills/anti-patterns/SKILL.md` — Fourteen project failure modes with WRONG/RIGHT examples (SignalBus, null guards, headless safety).
`.cursor/skills/building-system/SKILL.md` — Hex grid, placement, `BuildingBase`/`BuildingData`, auras, summoners, build phase (`HexGrid`, `BuildPhaseManager`, `AuraManager`).
`.cursor/skills/campaign-and-progression/SKILL.md` — Days, missions, territories, world map, campaign config (`CampaignManager`, `GameManager`, `DayConfig`).
`.cursor/skills/economy-system/SKILL.md` — Gold, materials, costs, refunds, mission economy (`EconomyManager`, duplicate scaling, wave rewards).
`.cursor/skills/enemy-system/SKILL.md` — Enemies, spawning, damage matrix, factions, bosses (`EnemyBase`, `EnemyData`, `WaveManager`, `DamageCalculator`).
`.cursor/skills/godot-conventions/SKILL.md` — Naming, static typing, signals, field discipline, process rules, sixteen agent rules (`types.gd`, `CONVENTIONS.md` alignment).
`.cursor/skills/lifecycle-flows/SKILL.md` — Startup, mission loop, waves, win/fail, build vs combat (`GameManager`, `BuildPhaseManager`, SignalBus lifecycle).
`.cursor/skills/mcp-workflow/SKILL.md` — Godot MCP Pro (`../foulward-mcp-servers/godot-mcp-pro`), GDAI bridge (`../foulward-mcp-servers/gdai-mcp-godot`, paid — outside repo), sequential-thinking, RAG, ports, `get_scene_tree` / `get_godot_errors` habits (`.cursor/mcp.json`).
`.cursor/skills/save-and-dialogue/SKILL.md` — Save slots, autosave, dialogue, relationships (`SaveManager`, `DialogueManager`, `RelationshipManager`).
`.cursor/skills/scene-tree-and-physics/SKILL.md` — `main.tscn` manager paths, layers/masks, input map, coordinates (`InputManager`, physics layers).
`.cursor/skills/signal-bus/SKILL.md` — Declaring, emitting, connecting cross-system signals (`autoloads/signal_bus.gd`, payload typing).
`.cursor/skills/spell-and-research-system/SKILL.md` — Spells, mana, research, enchantments, weapon upgrades (`SpellManager`, `ResearchManager`, `EnchantmentManager`, `WeaponUpgradeManager`).
`.cursor/skills/testing/SKILL.md` — GdUnit4, SimBot, headless runs, test isolation (`AutoTestDriver`, `tools/run_gdunit*.sh`).
`.cursor/skills/signal-bus/references/signal-table.md` — Full typed signal table for all **77** SignalBus signals (as of **2026-04-18**), organised by category (includes `dialogue_line_started` / `dialogue_line_finished` / `combat_dialogue_requested`; source of truth: `autoloads/signal_bus.gd`)
`.cursor/skills/enemy-system/references/enemy-types.md` — EnemyType (30), ArmorType, EnemyBodyType, DamageType enum tables with integer values
`.cursor/skills/building-system/references/building-types.md` — BuildingType (36) and BuildingSizeClass enum tables with integer values
`.cursor/skills/campaign-and-progression/references/game-manager-api.md` — Full GameManager public method table (30+ methods) and key constants

AUTOLOADS (registered in project.godot, in init order)
Autoload Name	Path	What it does
SignalBus	res://autoloads/signal_bus.gd	Central hub for ALL cross-system typed signals. Prompt 10: boss_spawned, boss_killed, campaign_boss_attempted. Prompt 11 (research UI): research_node_unlocked, research_points_changed. Prompt 11 (allies): ally_downed, ally_recovered, ally_killed, ally_state_changed (POST-MVP). Prompt 07: ally_spawned(ally_id, building_instance_id), ally_died, ally_squad_wiped. Prompt 12: mercenary_offer_generated, mercenary_recruited, ally_roster_changed. Prompt 33: enemy_entered_terrain_zone, enemy_exited_terrain_zone, terrain_prop_destroyed, nav_mesh_rebake_requested. **2026-04-14:** `dialogue_line_started` / `dialogue_line_finished` declared here (DialogueManager emits via SignalBus only). Group 9: `combat_dialogue_requested(entry)`. No logic, no state.
NavMeshManager	res://scripts/nav_mesh_manager.gd	Prompt 33: registers `NavigationRegion3D`, queues `bake_navigation_mesh` on `nav_mesh_rebake_requested` (rebake queue pattern). Autoload only (no `class_name`).
DamageCalculator (C#)	res://autoloads/DamageCalculator.cs	C# static damage type/armor type matrix lookup. Replaces damage_calculator.gd.
SavePayload	res://autoloads/SavePayload.cs	C# RefCounted typed container mirroring SaveManager's save payload structure. Includes System.Text.Json helpers.
AuraManager	res://autoloads/aura_manager.gd	Prompt 08: registers `is_aura` towers; `get_damage_pct_bonus` / `get_enemy_speed_modifier`; recomputes buildings in radius on register/deregister. Prompt 09: `_enemy_emitters` + `register_enemy_aura` / `get_enemy_damage_bonus` / `get_enemy_heal_per_sec` for enemy-side auras.
EconomyManager	res://autoloads/economy_manager.gd	Owns gold, building_material, research_material. Emits resource_changed. Prompt 37–38 + 41 + 47: `duplicate_cost_k`, `_built_counts`, `sell_refund_fraction`×`sell_refund_global_multiplier`, `get_gold_cost`/`get_material_cost` (`ceili`, dup scaling via `building_id`/`id`), `can_afford_building` (internal wallet), `register_purchase` (spends + receipt dict), `get_refund` → Dictionary, `reset_for_mission`, `apply_mission_economy`, `grant_wave_clear_reward` (+ `passive_gold_per_wave`), `_process` passive income; HexGrid/build menu/simbot wired.
CampaignManager	res://autoloads/campaign_manager.gd	Day/campaign progress; faction_registry + validate_day_configs; **owned_allies / active_allies_for_next_day**, mercenary catalog + offers, purchase + defection + `auto_select_best_allies` (Prompt 12); **current_ally_roster** sync for spawn (Prompt 11). Prompt 33: `_load_terrain` from `TerritoryData.terrain_type` into `/root/Main/TerrainContainer`. **Init order:** must load **before** GameManager in `project.godot` so `SignalBus.mission_won` runs `_on_mission_won` (day increment) before GameManager hub transition.
RelationshipManager	res://autoloads/relationship_manager.gd	Prompt 22: affinity −100..100 per `character_id`, tiers from `relationship_tier_config.tres`; loads `character_relationship/*.tres` + `relationship_events/*.tres`, applies deltas on SignalBus; `get_tier` / `get_save_data` / `restore_from_save`. **Init order:** after CampaignManager, before GameManager.
SettingsManager	res://autoloads/settings_manager.gd	Prompt 24: `user://settings.cfg` — master/music/SFX linear volumes, graphics quality string, keybind mirror; `AudioServer` Music+SFX buses; `load_settings`/`save_settings`/`set_volume`/`remap_action`. **Init order:** after RelationshipManager, before GameManager.
GameManager	res://autoloads/game_manager.gd	Owns game state, mission index, wave index, territory map runtime; mission rewards + territory bonuses. Prompt 10: final boss state, synthetic boss-attack days, held_territory_ids, prepare_next_campaign_day_if_needed / advance_to_next_day / get_day_config_for_index. Prompt 11: `_spawn_allies_for_current_mission` / `_cleanup_allies` (Main/AllyContainer, AllySpawnPoints). Prompt 12: `notify_mini_boss_defeated` → CampaignManager; `_transition_to` skips duplicate same-state transitions. `_begin_mission_wave_sequence`: Main→Managers→WaveManager via get_node_or_null; `push_warning` if absent (not `push_error` — GdUnit). Subscribes to `mission_won` for BETWEEN_MISSIONS / GAME_WON after CampaignManager (autoload order: CampaignManager before GameManager).
BuildPhaseManager	res://autoloads/build_phase_manager.gd	Prompt 49 + 11 + I-D: `is_build_phase` + `assert_build_phase`; `SignalBus.build_phase_started`/`combat_phase_started`; `set_build_phase_active` (wired from `GameManager` mission start + build mode).
AllyManager	res://autoloads/ally_manager.gd	Prompt 07: summoner `BuildingData` → spawn `AllyBase` squad from paths; `_squads` by `placed_instance_id`; `spawn_squad`/`despawn_squad`; connects `ally_died` → SignalBus. After BuildPhaseManager in `project.godot`.
CombatStatsTracker	res://autoloads/combat_stats_tracker.gd	Prompt 34 + 48–49 + 07 + 51: `begin_mission`/`begin_run`/`register_building`/`flush_to_disk`/`end_run` → `user://simbot/runs/{mission_id}_{timestamp}/` or `{mission_id}_{loadout}_{timestamp}/` (wave_summary, building_summary, optional event_log); `run_label` column; String `placed_instance_id` rows; `ally_deaths` column; SignalBus + `ProjectileBase` hook; `SimBot` `begin_mission` + `flush_to_disk` + `run_batch` `debug_batch`. Loads after AllyManager in `project.godot`.
combat_dialogue_banner.gd	res://scripts/ui/combat_dialogue_banner.gd	Group 9: timed combat quip banner; connects `SignalBus.combat_dialogue_requested`.
combat_dialogue_banner.tscn	res://scenes/ui/combat_dialogue_banner.tscn	Instanced under `Main/UI/UIManager` in `main.tscn`.
SaveManager	res://autoloads/save_manager.gd	Audit 6: rolling autosaves `user://saves/attempt_*/slot_*.json`; autoload singleton only (no `class_name`).
SybilPassiveManager	res://autoloads/sybil_passive_manager.gd	Loads `res://resources/passive_data/*.tres`, offers random passives, applies modifiers; save key `sybil`.
ChronicleManager	res://autoloads/chronicle_manager.gd	Meta-progression achievements + perks; loads `res://resources/chronicle/entries|perks/`; `user://chronicle.json`; SignalBus `chronicle_*`; `apply_perks_at_mission_start` after mission economy.
ChronicleData	res://scripts/resources/chronicle_data.gd	`class_name` optional container for chronicle entries + perks.
ChronicleEntryData	res://scripts/resources/chronicle_entry_data.gd	`class_name` achievement definition (tracking_signal, target_count, reward_id).
ChroniclePerkData	res://scripts/resources/chronicle_perk_data.gd	`class_name` perk effect (`Types.ChroniclePerkEffectType`).
SybilPassiveData	res://scripts/resources/sybil_passive_data.gd	`class_name` resource: passive_id, effect_type, effect_value, category.
PassiveSelectScreen	res://scenes/ui/passive_select_screen.tscn	UI: Sybil passive pick after briefing (`Types.GameState.PASSIVE_SELECT`).
passive_select_screen.gd	res://scripts/ui/passive_select_screen.gd	Logic: offered passives from SybilPassiveManager; select → `exit_passive_select`.
RingRotationScreen	res://scenes/ui/ring_rotation_screen.tscn	UI: per-ring rotation before combat (`Types.GameState.RING_ROTATE`); SubViewport mirrors main HexGrid via `HexGridPreview` + `apply_ring_rotation_silent`.
tier_selection_popup.tscn	res://scenes/ui/world_map/tier_selection_popup.tscn	World map: Normal / Veteran / Nightmare replay tier picker.
tier_selection_popup.gd	res://scripts/ui/tier_selection_popup.gd	Listens to `SignalBus.territory_selected_for_replay`; gates Nightmare until Veteran cleared.
territory_node_ui.gd	res://scripts/ui/territory_node_ui.gd	Per-territory hub control; stars + `territory_selected_for_replay` on press.
ChronicleScreen	res://scenes/ui/chronicle_screen.tscn	UI: Chronicle achievement list (main menu).
chronicle_screen.gd	res://scripts/ui/chronicle_screen.gd	Chronicle overlay logic; listens to `chronicle_progress_updated` / `chronicle_entry_completed`.
achievement_row_entry.tscn	res://scenes/ui/achievement_row_entry.tscn	UI: single chronicle row (name, progress bar, reward).
achievement_row_entry.gd	res://scripts/ui/achievement_row_entry.gd	Row `setup(entry_data, progress, completed)`.
DialogueManager	res://autoloads/dialogue_manager.gd	Prompt 13: loads `DialogueEntry` `.tres` under `res://resources/dialogue/**`; priority, AND conditions, once-only, chain_next_id; **emits** `dialogue_line_started` / `dialogue_line_finished` **through SignalBus** (not local signals). Group 9: `peek_entry_for_character` (no line_started emit), `request_combat_line`, per-mission combat condition keys (`first_blood`, `wave_number_gte`, …), `combat_dialogue_requested` when a combat line is selected. ResearchManager heuristics for `sybil_research_unlocked_any` (`spell` in node_id) and `arnulf_research_unlocked_any` (`arnulf` in node_id). Prompt 28: runtime tracking for gold/research/shop/Arnulf/spell conditions (`get_tracked_gold()`, etc.). See `docs/archived/prompts/PROMPT_13_IMPLEMENTATION.md`.
AutoTestDriver	res://autoloads/auto_test_driver.gd	Headless smoke-test driver. Active when `--autotest` or `--simbot_profile` or `--simbot_balance_sweep` (Prompt 51) is present.
GDAIMCPRuntime	(uid plugin autoload in project.godot)	GDAI MCP GDExtension bridge — editor HTTP API for MCP when `addons/gdai-mcp-plugin-godot` is enabled.
EnchantmentManager	res://autoloads/enchantment_manager.gd	Phase 4: per-weapon enchantment slots (elemental/power); Tower + BetweenMissionScreen integration.
SCRIPTS (attached to Manager nodes in main.tscn under /root/Main/Managers/)
Class Name	Path	What it does
Types	res://scripts/types.gd	All enums and shared constants. Prompt 11: `AllyClass` (MELEE/RANGED/SUPPORT); `TargetPriority` shared with allies (MVP: CLOSEST). Prompt 14: `HubRole` marks between-mission hub character categories. Prompt 32: `BuildingBaseMesh`, `BuildingTopMesh` (modular kit). Prompt 33: `TerrainType`, `TerrainEffect`. Prompt 35–42: `BuildingSizeClass` (+ SMALL/MEDIUM/LARGE), `UnitSize`, `AllyAiMode`, `SummonLifetimeType`, `AuraModifierOp`, aura enums, `EnemyBodyType` (+ SIEGE/ETHEREAL), `AllyCombatRole`, `MissionBalanceStatus`; legacy `AllyRole` (**four values:** MELEE_FRONTLINE, RANGED_SUPPORT, ANTI_AIR, SPELL_SUPPORT — TANK removed), `AuraModifierKind`. Prompt 50: `BuildingType` 8–35, `EnemyType` 6–29 (30 total). Not an autoload; referenced as Types.XXX.
FoulWardTypes	res://scripts/FoulWardTypes.cs	C# enum mirrors of Types.* — same integer values. For use in .cs files only. types.gd is source of truth.
WaveCompositionHelper	res://scripts/WaveCompositionHelper.cs	C# RefCounted helper. Builds wave enemy roster from faction data. Called from wave_manager.gd spawn_wave().
ProjectilePhysics	res://scripts/ProjectilePhysics.cs	C# Node child handling _PhysicsProcess for projectile base. Reads/writes parent via .Get()/.Call().
MissionSpawnRouting	res://scripts/mission_spawn_routing.gd	Prompt 35–36: resolves lanes/paths, builds spawn queue from `WaveData.spawn_entries`, bitmask `RoutePathData.body_types_allowed`; validates `MissionData`; `WaveManager` integration Prompt 36. Prompt 40: typed `MissionRoutingData` lookup, deterministic spawn jitter (`spawn_offset_variance_sec`), `validate_wave`/`WaveData` typing. Prompt 43: `build_spawn_queue` → sorted `Array[Dictionary]` (`spawn_time_sec`, `enemy_data`, `lane_id`, `path_id`); `resolve_path_for_spawn` → `RoutePathData`; `validate_routing`/`validate_wave` → `Array[String]`.
TerrainZone	res://scripts/terrain_zone.gd	Prompt 33: `Area3D` SLOW zones; emits SignalBus on enemy enter/exit.
terrain_navigation_region.gd	res://scripts/terrain_navigation_region.gd	Prompt 33: `NavigationRegion3D` helper — `create_from_mesh` from sibling `GroundMesh`.
HealthComponent	res://scripts/health_component.gd	Reusable HP tracker. Emits local signals health_depleted, health_changed.
ShieldComponent	res://scripts/components/shield_component.gd	Prompt 9: pre-HP shield absorb for Orc Shieldbearer (`EnemyData` `shield` special_values).
WaveManager	res://scripts/wave_manager.gd	Regular waves: `WaveComposer` + `wave_pattern` (`WavePatternData` .tres) from `enemy_data_registry` point budgets / `wave_tags` / tier; staggered spawn in `_physics_process`; `has_pending_composed_spawns()`; `clear_all_enemies` clears composed + mission spawn queues. Boss / mission-queue / path spawns unchanged. Prompt 10: boss_registry, `wave_pattern` default load, `set_day_context`, boss wave + escorts. Prompt 28: BUILD_MODE countdown pause. Prompt 36–43: mission `MissionData` queue, `MissionSpawnRouting`, `spawn_enemy_on_path`, validators. Prompt 09: `spawn_enemy_at_position`, `get_enemy_data_by_type`, `SignalBus.enemy_spawned`.
WaveComposer	res://scripts/wave_composer.gd	`class_name` `RefCounted`; `compose_wave(wave_index, budget_scale)`; pools by primary tag + modifiers; tier cap + weighted pick; pattern fields read via `Object.get()` for headless-safe loads.
SpawnQueueRow	res://scripts/spawn_queue_row.gd	Prompt 36: legacy `RefCounted` row; Prompt 43: `MissionSpawnRouting` uses `Dictionary` with same keys.
SpellManager	res://scripts/spell_manager.gd	Owns mana pool, spell cooldowns. Multi-spell registry + `cast_selected_spell` / hotkeys (Audit 6); effects include shockwave, slow_field, arcane_beam, tower_shield.
ResearchManager	res://scripts/research_manager.gd	Prompt 11: `can_unlock`, `get_research_points`, `add_research_points`, `show_research_panel_for`, `_unlock_building_for_node` (clears `BuildingData.is_locked` on `hex_grid` group); still spends `EconomyManager` research material. Gates locked buildings.
ShopManager	res://scripts/shop_manager.gd	Processes shop purchases; `get_daily_items(day_index)` rotation (4–6 items, RNG seed = day); mission-start consumable effects.
InputManager	res://scripts/input_manager.gd	Translates mouse/keyboard input into public method calls on managers.
SimBot	res://scripts/sim_bot.gd (+ alias `res://scripts/simbot.gd`)	Headless automated simulation bot. Audit 4: `get_log()` → Dictionary; `run_single` / `run_batch` CSV under `user://simbot/logs/`. Prompt 16 Phase 2: `StrategyProfile` resources. Prompt 51: `run_balance_sweep` + loadout presets (`scripts/simbot/simbot_loadouts.gd`).
SimBot loadouts	res://scripts/simbot/simbot_loadouts.gd	Prompt 51: `LOADOUTS` presets (`balanced`, `summoner_heavy`, `artillery_air`) + `get_loadout()` for balance sweeps.
tools/simbot_balance_report.py	res://tools/simbot_balance_report.py	Prompt 51: aggregates `building_summary.csv` under a root dir; writes `tools/output/simbot_balance_report.md` + `simbot_balance_status.csv` (median thresholds 1.35 / 0.65, gold floor 200).
tools/apply_balance_status.gd	res://tools/apply_balance_status.gd	Prompt 51: `EditorScript` `BalanceStatusApplier` — applies `simbot_balance_status.csv` → `BuildingData.balance_status` on `res://resources/building_data/*.tres`.
ArtPlaceholderHelper	res://scripts/art/art_placeholder_helper.gd	Stateless utility resolving placeholder meshes, materials, and icons from res://art based on Types enums and string IDs. Handles caching, fallbacks, and generated-asset priority. Prompt 32: `get_building_kit_mesh()` + `res://art/generated/kit/*.glb` (box fallback).
RiggedVisualWiring	res://scripts/art/rigged_visual_wiring.gd	Prompt 31: GLB path map (enemies/bosses/Arnulf), mount/clear visual slots, locomotion idle/walk on `AnimationPlayer`. Chat 5B: all 30 enemy paths, ally/building/tower GLB path methods, 14 ANIM_ constants.
tools/validate_art_assets.gd	res://tools/validate_art_assets.gd	Chat 5B: `@tool EditorScript` — report-only preflight; scans `res://art/` GLBs via `DirAccess`, checks required animation clips per category, prints summary. Run via Tools → Execute Script.
PlaceholderIconGenerator	res://tools/generate_placeholder_icons.gd	Prompt 24: `class_name PlaceholderIconGenerator` — 64×64 PNG placeholders (editor Project menu or `run_generate_placeholder_icons.gd`).
fw_placeholder_icons	res://addons/fw_placeholder_icons/plugin.cfg	Prompt 24: EditorPlugin — Project → Generate Placeholder Icons.
tools/generate_placeholder_glbs_blender.py	res://tools/generate_placeholder_glbs_blender.py	Blender 4.x headless: Rigify/blockout GLBs → `res://art/generated/{enemies,allies,buildings,bosses,misc}/`; writes `art/generated/generation_log.json`. Requires system numpy for glTF exporter.
tools/run_gdunit_unit.sh	tools/run_gdunit_unit.sh	Prompt 27: Runs only pure unit suites (no await/scenes/timers). ~70s wall-clock. Prompt 33: includes `tests/unit/test_terrain.gd`. Prompt 50: `test_content_invariants.gd`. Prompt 11: `test_research_and_build_menu.gd`. Prompt 51: `test_simbot_balance_integration.gd`.
tools/run_gdunit_parallel.sh	tools/run_gdunit_parallel.sh	Prompt 27: 8-parallel-process test runner for all 88 test files. ~2m45s wall-clock (37% faster than sequential).
tools/complete_comfyui_assets.sh	tools/complete_comfyui_assets.sh	Prompt 78: after ComfyUI at `~/ComfyUI`, downloads gated FLUX.1-dev (`HF_TOKEN`) + CivitAI LoRAs (optional `CIVITAI_TOKEN`); see `.cursor/skills/gen3d/SKILL.md`.
tools/gen3d/foulward_gen.py	tools/gen3d/foulward_gen.py	Prompt 86: orchestrator for the 5-stage gen3d pipeline (Stage1 ComfyUI→Stage2 TRELLIS variants→Stage3 rig→Stage4 anim→Stage5 drop). Exposes `run_pipeline`, `select_candidate`, `canonical_slug`.
tools/gen3d/pipeline/stage2_mesh.py	tools/gen3d/pipeline/stage2_mesh.py	Prompt 86: TRELLIS.2 image→GLB. `image_to_glb` (seed arg, predecimate env), `decimate_glb` (O3D+cKDTree UV re-projection, texture-preserving), `generate_mesh_variants` (N-seed loop, two-location write), `_check_glb_has_texture`.
tools/gen3d/pipeline/stage3_rig.py	tools/gen3d/pipeline/stage3_rig.py	Prompt 86: GLB→FBX→Mixamo rig→GLB. `rig_model`, `_load_mixamo_credentials` (reads ~/.foulward_secrets as belt-and-suspenders).
tools/gen3d/promote_candidate.py	tools/gen3d/promote_candidate.py	Prompt 86: re-select a mesh variant post-batch and re-run stages 3–5 only. Usage: `python3 promote_candidate.py <slug> <variant_N>`.
tools/gen3d/pipeline/stage1_image.py	tools/gen3d/pipeline/stage1_image.py	Prompt 89: ComfyUI HTTP — FLUX.1-dev turnaround sheet; per-faction LoRA strength caps; `build_workflow_with_loras`.
tools/gen3d/pipeline/stage4_anim.py	tools/gen3d/pipeline/stage4_anim.py	Prompt 89: Blender — merge Mixamo FBX clips from `anim_library/` map; export one GLB with embedded actions.
tools/gen3d/pipeline/stage5_drop.py	tools/gen3d/pipeline/stage5_drop.py	Prompt 89: `drop_to_godot` — copy final `{slug}.glb` into `art/generated/<category>/`.
tools/gen3d/pipeline/secrets_loader.py	tools/gen3d/pipeline/secrets_loader.py	Prompt 89: `load_foulward_secrets()` — parse `~/.foulward_secrets`; mirrors `HF_TOKEN` → `HUGGING_FACE_HUB_TOKEN` when needed.
tools/gen3d/scripts/trellis2_input_ab_variant.py	tools/gen3d/scripts/trellis2_input_ab_variant.py	Prompt 89: CLI subprocess helper for TRELLIS input A/B (pad image → raw + decimated GLB + JSON report).
tools/gen3d/scripts/ab_test_batch.py	tools/gen3d/scripts/ab_test_batch.py	TRELLIS input-format A/B batch: 5 variants × 5 seeds → `local/gen3d/ab_test/` CSV + GLBs (uses `pipeline.stage2_mesh`).
tools/gen3d/scripts/prepare_trellis_ab_variants.py	tools/gen3d/scripts/prepare_trellis_ab_variants.py	Builds five PNG variants (V1–V5) from one cleaned RGBA source for A/B harnesses.
docs/GEN3D_LOCAL_ARTIFACTS.md	docs/GEN3D_LOCAL_ARTIFACTS.md	Policy: bulk gen3d PNG/GLB/log output under `local/gen3d/` (gitignored, cursorignored); staging + optional `ab_test/`.
art/gen3d_candidates/	art/gen3d_candidates/	Per-slug mesh variants — **gitignored** (local only); see `docs/GEN3D_LOCAL_ARTIFACTS.md`. Large TRELLIS scratch also in `local/gen3d/staging/`.
art/gen3d_previews/	art/gen3d_previews/	Reference PNGs (`fw_<unit>_ref.png`) — **gitignored** (local only); see `docs/GEN3D_LOCAL_ARTIFACTS.md`.
art/generated/	art/generated/	Godot drop zone for `{slug}.glb` etc. — **gitignored** (local only); `foulward_gen.py` still writes here at runtime.
art/generated/generation_log.json	res://art/generated/generation_log.json	Batch export inventory (written by tooling) — **gitignored** like other `art/generated/` files; see `docs/GEN3D_LOCAL_ARTIFACTS.md`.
FUTURE_3D_MODELS_PLAN.md	docs/FUTURE_3D_MODELS_PLAN.md	Production 3D + hub portrait roadmap; placeholder table from `generation_log.json`; **§4 Modular Building Kit** (Prompt 32); **§5 Terrain System** (Prompt 33); scene art audit appendix (Prompt 29 refresh); PhysicalBone3D + AnimationPlayer wiring notes.
MainRoot	res://scripts/main_root.gd	Applies root window content scale at startup (stretch fix for Godot 4.4+).
SCENES (runtime instantiated or statically placed)
Class Name	Script Path	Scene Path	What it does
Tower	res://scenes/tower/tower.gd	res://scenes/tower/tower.tscn	Player's stationary avatar. Fires crossbow + rapid missile.
Arnulf	res://scenes/arnulf/arnulf.gd	res://scenes/arnulf/arnulf.tscn	AI melee companion. State machine: IDLE/PATROL/CHASE/ATTACK/DOWNED/RECOVERING. Prompt 11: emits generic `ally_*` with id `arnulf` + `ALLY_ID_ARNULF`. Prompt 31: `ArnulfVisual` + `allies/arnulf.glb`, locomotion anims.
AllyBase	res://scenes/allies/ally_base.gd	res://scenes/allies/ally_base.tscn	Prompt 11 + Audit 6: DOWNED/RECOVERING when `uses_downed_recovering`; `can_target_flying` / `preferred_targeting` (CLOSEST, LOWEST_HP, …); `SignalBus.ally_spawned(ally_id, building_instance_id)` / ally_downed / ally_recovered / ally_killed. Prompt 07: `patrol_anchor`, `owning_building_instance_id`, local `ally_died`, `HexGrid` soft-blocker register near anchor.
HexGrid	res://scenes/hex_grid/hex_grid.gd	res://scenes/hex_grid/hex_grid.tscn	42-slot hex grid (3 rings). Manages building placement, sell, upgrade. Prompt 11: `add_to_group("hex_grid")` for research unlock mutations. Prompt 37 + 47: `register_purchase` receipt, `initialize_with_economy`, sell via `get_sell_refund`, upgrade spends + `apply_upgrade`/`record_upgrade_cost` (legacy). Prompt 07: `soft_blocker_count` per slot, `world_to_hex`/`register_soft_blocker`/`unregister_soft_blocker`/`has_soft_blocker`; sell calls `AllyManager.despawn_squad`.
BuildingBase	res://scenes/buildings/building_base.gd	res://scenes/buildings/building_base.tscn	Base class for **36** `BuildingType` variants (data-driven). Auto-targets and fires. Prompt 32: kit → `BuildingKitAssembly`. Prompt 37 + 41–42 + 47: `paid_*`/`total_invested_*`, `initialize_with_economy`, `get_upgrade_cost`/`get_sell_refund` Dictionary, `can_upgrade`/`apply_upgrade` (chain + invested totals), placement `slot_id`/`ring_index`/`placed_instance_id` (string), projectile `PackedScene` resolve. Prompt 08: `AuraManager` aura damage + healer `Timer`/`receive_heal`. Prompt 07: `is_summoner` → `AllyManager.spawn_squad`, mortal/recurring respawn `Timer`, `_exit_tree` cleanup. Prompt 44: `_find_target` → `EnemyData.matches_tower_air_ground_filter`. Prompt 09: `set_disabled` + `_disabled` skips `_combat_process` (Orc Saboteur).
EnemyBase	res://scenes/enemies/enemy_base.gd	res://scenes/enemies/enemy_base.tscn	Base class for **30** `EnemyType` variants (data-driven). Nav, attack, die, reward. Prompt 08: `AuraManager.get_enemy_speed_modifier` (periodic refresh). Prompt 31: `EnemyVisual` mounts rigged GLB per `EnemyType` (bat: placeholder mesh), idle/walk anims. Prompt 33: terrain zone speed multiplier (min of overlapping zones). Prompt 09: `special_tags` behaviours (`ShieldComponent`, charge/dash, enemy auras, on_death_spawn, saboteur `set_disabled`, anti-air ranged, regen).
TerrainGrassland	—	res://scenes/terrain/terrain_grassland.tscn	Prompt 33: default battle ground + `NavRegion` (`terrain_navigation_region.gd`).
TerrainSwamp	—	res://scenes/terrain/terrain_swamp.tscn	Prompt 33: grassland + `TerrainZone` (0.55×).
BossBase	res://scenes/bosses/boss_base.gd	res://scenes/bosses/boss_base.tscn	Prompt 10: extends EnemyBase; initialize_boss_data(BossData); emits boss_spawned / boss_killed. Prompt 31: `BossVisual` + boss_id GLB (1.5×) or placeholder box.
ProjectileBase	res://scenes/projectiles/projectile_base.gd	res://scenes/projectiles/projectile_base.tscn	Physics-driven projectile. Hits first valid enemy, self-destructs.
UI SCRIPTS & SCENES
Class Name	Script Path	Scene Path	What it does
UIManager	res://ui/ui_manager.gd	(Control node in main.tscn)	Lightweight state router + hub dialogue router. Shows/hides UI panels on game_state_changed and wires `Hub2DHub` + `DialoguePanel`. Prompt 14: `show_dialogue(display_name, entry)` + `clear_dialogue()`; still supports `show_dialogue_for_character` with queue.
Hub2DHub	res://ui/hub.gd	res://ui/hub.tscn	2D between-mission hub overlay. Instantiates clickable characters from `CharacterCatalog` and routes focus to `BetweenMissionScreen` + dialogue.
DialoguePanel	res://ui/dialogue_panel.gd	res://ui/dialogue_panel.tscn	Global click-to-continue dialogue overlay (SpeakerLabel + TextLabel). Chains via `DialogueEntry.chain_next_id`.
HUD	res://ui/hud.gd	res://ui/hud.tscn	Combat overlay: resources, wave counter, HP bar, spells. Prompt 11: Research button (build mode only) opens `ResearchPanel`.
BuildMenu	res://ui/build_menu.gd	res://ui/build_menu.tscn	Prompt 11: scrollable grid of `BuildMenuButton` from full `building_data_registry` (sorted SMALL/MEDIUM/LARGE + name); refresh on research unlock. Opens on hex slot click in BUILDMODE.
BuildMenuButton	res://ui/build_menu_button.gd	res://ui/build_menu_button.tscn	Prompt 11: per-tower row; lock overlay; locked click → `ResearchManager.show_research_panel_for`.
ResearchPanel	res://ui/research_panel.gd	res://ui/research_panel.tscn	Prompt 11: in-mission research overlay (`research_panel` group); `scroll_to_node`.
ResearchNodeRow	res://ui/research_node_row.gd	res://ui/research_node_row.tscn	Prompt 11: single research node row + Unlock.
BetweenMissionScreen	res://ui/between_mission_screen.gd	res://ui/between_mission_screen.tscn	Post-mission tabs: World Map, Shop, Research, Buildings, Weapons, Mercenaries (Prompt 12). NEXT DAY. Prompt 13: on `BETWEEN_MISSIONS`, `_show_hub_dialogue()` → UIManager for SPELL_RESEARCHER then COMPANION_MELEE (queued).
WorldMap	res://ui/world_map.gd	res://ui/world_map.tscn	Territory list + details (read-only; GameManager state).
MainMenu	res://ui/main_menu.gd	res://ui/main_menu.tscn	Title screen. Start, Settings → `settings_screen.tscn` overlay, Quit.
SettingsScreen	res://scripts/ui/settings_screen.gd	res://scenes/ui/settings_screen.tscn	Prompt 24: audio sliders, graphics quality, keybind remap, Back.
MissionBriefing	res://ui/mission_briefing.gd	(Control node in main.tscn)	Shows mission number. BEGIN button → GameManager.enter_passive_select.
EndScreen	res://ui/end_screen.gd	(Control node in main.tscn)	Final screen for win/lose. Restart and Quit buttons.
CUSTOM RESOURCE TYPES (script classes, not .tres files)
Class Name	Script Path	Fields summary
EnemyData	res://scripts/resources/enemy_data.gd	enemy_type, display_name, max_hp, move_speed, damage, attack_range, attack_cooldown, armor_type, gold_reward, is_ranged, is_flying, color, damage_immunities[]; Prompt 35: id/description/icon, armor_flat/MR/status resist, body_type, collision/blocker flags, Florence/blocker attack knobs, CC flags, bounty/threat/tags, effective getters; Prompt 39: get_identity(); Prompt 42: scene_path, SIEGE/ETHEREAL body types + target bits; Prompt 44: matches_tower_air_ground_filter; Prompt 50: point_cost, wave_tags, tier, special_tags, special_values, balance_status string
WavePatternData	res://scripts/resources/wave_pattern_data.gd	`class_name` Resource; id, display_name, base_point_budget, budget_per_wave, max_waves, wave_primary_tags[], wave_modifiers[] (each element: array of modifier strings for that wave index)
BuildingData	res://scripts/resources/building_data.gd	building_type, building_id (dup scaling key), display_name, gold_cost, material_cost, upgrade_gold_cost, upgrade_material_cost, damage, upgraded_damage, fire_rate, attack_range, upgraded_range, damage_type, targets_air, targets_ground, is_locked, unlock_research_id, color, dot_enabled, dot_total_damage, dot_tick_interval, dot_duration, dot_effect_type, dot_source_id, dot_in_addition_to_hit; Prompt 32: base_mesh_id, top_mesh_id, accent_color (modular kit); Prompt 35: id/description/icon/scene_path, footprint_size_class (was size_class)/ring_index, cost_* overrides, sell_refund_fraction, summoner/aura/healer, upgrade_next + upgrade_next_gold_cost/upgrade_next_material_cost, meta tags + validation; Prompt 39: get_range() (spec alias for attack_range); Prompt 42: `PackedScene` projectile, `SummonLifetimeType`, `AuraModifierOp`, `BuildingSizeClass` SMALL/MEDIUM/LARGE; Prompt 50: string `size_class` (SMALL/MEDIUM/LARGE), `role_tags`, `balance_status` string, summoner paths/heal tick/aura_effect_*, upgrade arrays, `duplicate_cost_k`, `aura_category` string, `heal_target_flags` + `heal_targets` string
WeaponData	res://scripts/resources/weapon_data.gd	weapon_slot, display_name, damage, projectile_speed, reload_time, burst_count, burst_interval, can_target_flying, assist_angle_degrees, assist_max_distance, base_miss_chance, max_miss_angle_degrees
SpellData	res://scripts/resources/spell_data.gd	spell_id, display_name, mana_cost, cooldown, damage, radius, damage_type, hits_flying
ResearchNodeData	res://scripts/resources/research_node_data.gd	node_id, display_name, research_cost, prerequisite_ids[], description
ShopItemData	res://scripts/resources/shop_item_data.gd	item_id, display_name, gold_cost, material_cost, description, category (consumable/equipment/voucher), rarity_weight, effect_tags, value, duration
TerritoryData	res://scripts/resources/territory_data.gd	territory_id, terrain_type (`Types.TerrainType`), ownership, default_faction_id (POST-MVP), is_secured, has_boss_threat, bonus_flat_gold_end_of_day, bonus_percent_gold_end_of_day, POST-MVP bonus hooks; G4: `highest_cleared_tier`, `star_count`, `veteran_perk_id`, `nightmare_title_id`
DifficultyTierData	res://scripts/resources/difficulty_tier_data.gd	`class_name`; `Types.DifficultyTier` + enemy_hp/damage/gold_reward/spawn multipliers (replay star tiers)
TerritoryMapData	res://scripts/resources/territory_map_data.gd	territories: Array[TerritoryData], get_territory_by_id, has_territory
FactionRosterEntry	res://scripts/resources/faction_roster_entry.gd	enemy_type, base_weight, min_wave_index, max_wave_index, tier
FactionData	res://scripts/resources/faction_data.gd	faction_id, display_name, description, roster[], mini_boss_ids (BossData.boss_id strings), mini_boss_wave_hints, roster_tier, difficulty_offset; get_entries_for_wave, get_effective_weight_for_wave; BUILTIN_FACTION_RESOURCE_PATHS
BossData	res://scripts/resources/boss_data.gd	boss_id, stats, escort_unit_ids, phase_count, is_mini_boss / is_final_boss, boss_scene; build_placeholder_enemy_data(); BUILTIN_BOSS_RESOURCE_PATHS
DayConfig	res://scripts/resources/day_config.gd	day_index, mission_index, territory_id, faction_id (default DEFAULT_MIXED), is_mini_boss_day, is_mini_boss (alias), is_final_boss, boss_id, is_boss_attack_day, display_name, wave/tuning multipliers; Prompt 47: optional `mission_economy`
CampaignConfig	res://scripts/resources/campaign_config.gd	campaign_id, display_name, day_configs, starting_territory_ids, territory_map_resource_path, short-campaign flags
StrategyProfile	res://scripts/resources/strategyprofile.gd	profile_id, description, build_priorities, placement_preferences, spell_usage, upgrade_behavior, difficulty_target
AllyData	res://scripts/resources/ally_data.gd	Prompt 11: ally_id, ally_class, stats, preferred_targeting (CLOSEST MVP), is_unique. Prompt 12: damage_type, attack_damage / patrol / recovery, scene_path, is_starter_ally, is_defected_ally, debug_color; POST-MVP progression fields. Prompt 35: unit_size, armor/MR, fire_rate/splash/DoT, blocker/leash, ai_mode, optional aura/healer, summon lifecycle, tags; Prompt 39: identity, max_lifetime_sec, get_identity(); Prompt 42: `id`, `damage`, `target_flags`, `role: AllyCombatRole`, `SummonLifetimeType`, `AuraModifierOp`, `get_range()`
SpawnEntryData	res://scripts/resources/spawn_entry_data.gd	Prompt 35: enemy_data, count, start_time_sec, interval_sec, lane_id, path_id, spawn_offset_variance_sec, tags; Prompt 39: enemy_id (authoring when data resolved later)
WaveData	res://scripts/resources/wave_data.gd	Prompt 35: wave_number, spawn_entries[], delays, reward overrides, recommended_tags, simbot_label
MissionWavesData	res://scripts/resources/mission_waves_data.gd	Prompt 35: mission_id, waves[], starting_gold/material, florence_starting_hp, mission_tags, layout_preset
LaneData	res://scripts/resources/lane_data.gd	Prompt 35: id, florence_entry_tag, threat_weight, allowed_path_ids, tags
RoutePathData	res://scripts/resources/path_data.gd	Prompt 35: `class_name RoutePathData` (avoids engine `PathData`); id, lane_id, curve3d_path, body_types_allowed bitmask, total_length_hint, blocker_sensitive, leak_entry_point_tag, tags; Prompt 39: spec calls this PathData in prose; Prompt 42: `curve3d_path: NodePath`, siege/ethereal flags
MissionRoutingData	res://scripts/resources/mission_routing_data.gd	Prompt 35: mission_id, lanes[], paths[], lookups by id; Prompt 39: path lane_id must exist in lanes (collect_validation_warnings)
MissionEconomyData	res://scripts/resources/mission_economy_data.gd	Prompt 35: mission_id, passive income, wave/leak bonuses, sell_refund_global_multiplier, duplicate_cost_k_override, tags; Prompt 39: doc note vs MissionWavesData starting_* overlap; Prompt 42: `-1.0` duplicate k = no override; Prompt 47: `sell_refund_fraction` (≥0 overrides, `-1` skip), `passive_gold_per_wave`
MissionDataValidation	res://scripts/resources/mission_data_validation.gd	Prompt 35: static helpers delegating to `collect_validation_warnings` on mission resources; `validate_mission` / `validate_routing` / `validate_wave` return `PackedStringArray` error lines (non-destructive); Prompt 39: validate_wave allows enemy_id without enemy_data
MissionData	res://scripts/resources/mission_data.gd	Optional `DayConfig.mission_data`: routing + waves; `get_wave`/`has_wave_entries` by `wave_number`; Prompt 35: uses `spawn_entries`
ExampleMissionResources	res://scripts/resources/example_mission_resources.gd	Prompt 35+: const paths to `resources/examples/prompt35/*.tres` samples (arrow tower, runner enemy, waves, mission waves, routing, economy)
MercenaryOfferData	res://scripts/resources/mercenary_offer_data.gd	Prompt 12: ally_id, costs, day range, is_defection_offer.
MercenaryCatalog	res://scripts/resources/mercenary_catalog.gd	Prompt 12: offers pool, max_offers_per_day, get_daily_offers.
MiniBossData	res://scripts/resources/mini_boss_data.gd	Prompt 12: defection metadata (defected_ally_id, costs).
DialogueCondition	res://scripts/resources/dialogue/dialogue_condition.gd	key, comparison (==, !=, >, >=, <, <=), value (Variant); optional `condition_type` **relationship_tier** + `character_id` / `required_tier` (Prompt 22); AND only; evaluated by DialogueManager
RelationshipTierConfig	res://scripts/resources/relationship_tier_config.gd	Prompt 22: `tiers` Array[Dictionary] `{ name, min_affinity }` ascending; shared tier names for `RelationshipManager.get_tier`.
CharacterRelationshipData	res://scripts/resources/character_relationship_data.gd	Prompt 22: `character_id`, `starting_affinity`, `display_name` — one `.tres` per character under `res://resources/character_relationship/`.
RelationshipEventData	res://scripts/resources/relationship_event_data.gd	Prompt 22: `signal_name` (SignalBus), `character_deltas` Dictionary id → float.
DialogueEntry	res://scripts/resources/dialogue/dialogue_entry.gd	entry_id, character_id, text, priority, once_only, chain_next_id, conditions[], is_combat_line (Group 9 combat banners)
CharacterData	res://scripts/resources/character_data.gd	data resource for a single between-mission hub character (id, display_name, HubRole, dialogue tags, 2D placement).
CharacterCatalog	res://scripts/resources/character_catalog.gd	resource holding the hub character set loaded by `Hub2DHub`.
RESOURCE FILES (.tres — actual data)
Ally data (Prompt 11)
File	ally_id	Notes
res://resources/ally_data/ally_melee_generic.tres	ally_melee_generic	Placeholder melee merc
res://resources/ally_data/ally_ranged_generic.tres	ally_ranged_generic	Placeholder ranged merc
res://resources/ally_data/ally_support_generic.tres	ally_support_generic	Optional; not in static roster by default
Mercenary data (Prompt 12)
File	Notes
res://resources/mercenary_catalog.tres	Default offer pool; referenced by CampaignManager
res://resources/mercenary_offers/*.tres	Per-offer rows (subset; catalog may embed sub-resources)
res://resources/miniboss_data/*.tres	Mini-boss defection metadata
Dialogue pools (Prompt 13)
Folder	Notes
res://resources/dialogue/florence/	FLORENCE lines (placeholder TODO)
res://resources/dialogue/companion_melee/	COMPANION_MELEE (Arnulf) — intro, arnulf research hook, generic
res://resources/dialogue/spell_researcher/	SPELL_RESEARCHER (Sybil) — intro, spell-unlock hook, generic
res://resources/dialogue/weapons_engineer/	WEAPONS_ENGINEER placeholder pool
res://resources/dialogue/enchanter/	ENCHANTER placeholder pool
res://resources/dialogue/merchant/	MERCHANT placeholder pool
res://resources/dialogue/mercenary_commander/	MERCENARY_COMMANDER placeholder pool
res://resources/dialogue/campaign_character_template/	CAMPAIGN_CHARACTER_X template pool
res://resources/dialogue/example_character/	EXAMPLE_CHARACTER — conditional + chain demo entries
Character hub cast (Prompt 14)
File	Notes
res://resources/character_data/merchant.tres	MERCHANT (HubRole.SHOP)
res://resources/character_data/researcher.tres	SPELL_RESEARCHER (HubRole.RESEARCH)
res://resources/character_data/enchantress.tres	ENCHANTER (HubRole.ENCHANT)
res://resources/character_data/mercenary_captain.tres	MERCENARY_COMMANDER (HubRole.MERCENARY)
res://resources/character_data/arnulf_hub.tres	COMPANION_MELEE (HubRole.ALLY)
res://resources/character_data/flavor_npc_01.tres	EXAMPLE_CHARACTER (HubRole.FLAVOR_ONLY)
res://resources/character_catalog.tres	CharacterCatalog containing all hub cast entries.
Enemy Data
File	enemy_type	armor_type	Notes
res://resources/enemy_data/orc_grunt.tres	ORCGRUNT	UNARMORED	Basic melee runner
res://resources/enemy_data/orc_brute.tres	ORCBRUTE	HEAVYARMOR	Slow, high HP, melee
res://resources/enemy_data/goblin_firebug.tres	GOBLINFIREBUG	UNARMORED	Fast melee, fire immune
res://resources/enemy_data/plague_zombie.tres	PLAGUEZOMBIE	UNARMORED	Slow tank, poison immune
res://resources/enemy_data/orc_archer.tres	ORCARCHER	UNARMORED	Stops at range, fires
res://resources/enemy_data/bat_swarm.tres	BATSWARM	FLYING	Flying, anti-air only
Building Data
File	building_type	is_locked	unlock_research_id
res://resources/building_data/arrow_tower.tres	ARROWTOWER	false	—
res://resources/building_data/fire_brazier.tres	FIREBRAZIER	false	—
res://resources/building_data/magic_obelisk.tres	MAGICOBELISK	false	—
res://resources/building_data/poison_vat.tres	POISONVAT	false	—
res://resources/building_data/ballista.tres	BALLISTA	true	unlock_ballista
res://resources/building_data/archer_barracks.tres	ARCHERBARRACKS	true	(POST-MVP stub)
res://resources/building_data/anti_air_bolt.tres	ANTIAIRBOLT	false	—
res://resources/building_data/shield_generator.tres	SHIELDGENERATOR	true	(POST-MVP stub)
Weapon Data
File	weapon_slot	burst_count
res://resources/weapon_data/crossbow.tres	CROSSBOW	1
res://resources/weapon_data/rapid_missile.tres	RAPIDMISSILE	10
Spell / Research / Shop Data
File	Class	Notes
res://resources/spell_data/shockwave.tres	SpellData	Shockwave AoE, 50 mana, 60s cooldown
res://resources/research_data/base_structures_tree.tres	ResearchNodeData	6 nodes: unlock_ballista, unlock_antiair, arrow_tower_dmg, unlock_shield_gen, fire_brazier_range, unlock_archer_barracks
res://resources/shop_data/shop_catalog.tres	ShopItemData[]	4 items: tower_repair, building_repair, arrow_tower (voucher), mana_draught
res://resources/territories/main_campaign_territories.tres	TerritoryMapData	Five placeholder territories for main campaign
res://resources/campaigns/campaign_main_50_days.tres	CampaignConfig	50 linear days + territory_map_resource_path (canonical; `GameManager.MAIN_CAMPAIGN_CONFIG_PATH`)
res://resources/campaigns/campaign_short_5_days.tres	CampaignConfig	Default MVP 5-day short campaign (mission_index 1–5)
Faction data
File	faction_id	Notes
res://resources/faction_data_default_mixed.tres	DEFAULT_MIXED	Equal-weight six-type MVP mix
res://resources/faction_data_orc_raiders.tres	ORC_RAIDERS	Orc-heavy roster + placeholder mini-boss id
res://resources/faction_data_plague_cult.tres	PLAGUE_CULT	Undead/fire/flyer mix + mini-boss id (BossData)
Boss data (Prompt 10)
File	boss_id	Notes
res://resources/bossdata_plague_cult_miniboss.tres	plague_cult_miniboss	Shared boss_base.tscn
res://resources/bossdata_orc_warlord_miniboss.tres	orc_warlord	Shared boss_base.tscn
res://resources/bossdata_final_boss.tres	final_boss	Day 50 / campaign boss
SimBot strategy profiles (Prompt 16 Phase 2)
File	profile_id	Notes
res://resources/strategyprofiles/strategy_balanced_default.tres	BALANCED_DEFAULT	Balanced profile: mix of tower types + moderate shockwave
res://resources/strategyprofiles/strategy_greedy_econ.tres	GREEDY_ECON	Greedy econ: prioritize cheap/early towers, fewer upgrades/spells
res://resources/strategyprofiles/strategy_heavy_fire.tres	HEAVY_FIRE	Heavy fire/DPS: FireBrazier/Ballista/MagicObelisk bias + aggressive shockwave
Art resources
Art root: res://art/
- Meshes: res://art/meshes/{buildings,enemies,allies,misc}/ — primitive Mesh .tres, named by convention
- Materials: res://art/materials/{factions,types}/ — StandardMaterial3D .tres, named by convention
- Icons: res://art/icons/{buildings,enemies,allies}/ — Texture2D .png/.tres, POST-MVP
- Generated: res://art/generated/{meshes,icons}/ — drop zone for Blender/AI outputs, takes priority over placeholders
TEST FILES (res://tests/, GdUnit4 framework; full run see PROMPT_9_IMPLEMENTATION.md / PROMPT_10_IMPLEMENTATION.md / PROMPT_12_IMPLEMENTATION.md / PROMPT_13_IMPLEMENTATION.md)
File	What it covers
testmercenaryoffers.gd	Prompt 12: offer generation / preview
testmercenarypurchase.gd	Prompt 12: purchase + economy
testcampaignallyroster.gd	Prompt 12: owned/active roster APIs
testminibossdefection.gd	Prompt 12: defection offer injection
testsimbotmercenaries.gd	Prompt 12: SimBot mercenary API
test_simbot_profiles.gd	Prompt 16 Phase 2: `StrategyProfile` `.tres` loading + basic structure validation
test_simbot_basic_run.gd	Prompt 16 Phase 2: headless `SimBot.run_single()` places buildings without UI dependencies
test_simbot_logging.gd	Prompt 16 Phase 2: `run_batch()` CSV header + append behavior
test_simbot_determinism.gd	Prompt 16 Phase 2: determinism for a fixed seed
test_simbot_safety.gd	Prompt 16 Phase 2: safety check (no `res://ui/` references)
test_dialogue_manager.gd	Prompt 13: DialogueManager conditions, priority, once-only, chain fallback, resource load
test_dialogue_content.gd	Group 9: hub `.tres` entry_id / chain / GENERIC repeatability / combat `is_combat_line`
test_combat_dialogue.gd	Group 9: `request_combat_line`, combat state, `combat_dialogue_requested` headless emit
test_art_placeholders.gd	Prompt 17: ArtPlaceholderHelper placeholder mesh/material resolution, generated-asset priority, scene wiring, and cache/fallback behavior
tests/unit/test_building_kit.gd	Prompt 32: `get_building_kit_mesh` Node3D + two children, accent on top surface 0, GLB→BoxMesh fallback, BuildingData kit fields
tests/unit/test_terrain.gd	Prompt 33: TerrainZone signals, EnemyBase terrain multiplier, NavMeshManager queue, `TerritoryData.terrain_type`
tests/unit/test_td_resource_helpers.gd	Prompt 39: `get_range`/`get_identity`, spawn `enemy_id` authoring validation, routing path→lane warning
tests/unit/test_content_invariants.gd	Prompt 50: parametric `BuildingData`/`EnemyData` `.tres` invariants + enum size coverage (36 buildings, 30 enemies)
tests/unit/test_rigged_visual_wiring_session07.gd	Prompt 70 (Chat 5C): RiggedVisualWiring path helpers — all 30 enemies, 36 buildings, ally known/unknown ids, tower path, 17 ANIM_ constants, no drunk_idle
tests/unit/test_validate_art_assets_session07.gd	Prompt 70 (Chat 5C): validate_art_assets.gd spec — _infer_category (6 variants), _get_required_clips counts, no-anim-player missing-all logic
tests/support/counting_navigation_region.gd	Prompt 33: test double counting `bake_navigation_mesh` calls
test_character_hub.gd	Prompt 14: CharacterData/Catalog loading, Hub click focus behavior, DialoguePanel display + chaining, and UIManager hub open/close integration.
testeconomymanager.gd	gold/material add/spend/reset, signal emission, transactions
testdamagecalculator.gd	Full 4×4 matrix, boundary values, DoT stub
testwavemanager.gd	Wave scaling, countdown, spawn count, faction-weighted composition, mini-boss hook, Prompt 10: regular day spawns no bosses
testbossdata.gd	BossData load, BUILTIN paths, placeholder EnemyData build
testbossbase.gd	BossBase init, nav present, kill → boss_killed
testbosswaves.gd	Boss wave index + escorts + wave_cleared to max
testfinalbossday.gd	Final-boss day / GameManager campaign hooks (see test file)
testfactiondata.gd	Faction .tres load + roster→EnemyData; validate_day_configs on short campaign
testspellmanager.gd	Mana regen, deduct, cooldown, shockwave AoE damage
testarnulfstatemachine.gd	All state transitions, downed/recover cycle
testallydata.gd	AllyData defaults + all res://resources/ally_data/*.tres loads
testallybase.gd	AllyBase find_target, attack in range, ally_killed on HP depletion
testallycombat.gd	Downed→recover timer; skip flying when `can_target_flying` false; LOWEST_HP targeting
testallysignals.gd	ally_spawned, ally_killed, Arnulf generic ally_* + reset ally_spawned
testallyspawning.gd	Campaign roster count under AllyContainer; cleanup on waves cleared / new game
testhealthcomponent.gd	take_damage, heal, reset, health_depleted signal
testresearchmanager.gd	unlock, prereq gating, insufficient material, reset
testshopmanager.gd	purchase flow, affordability, effect application, signal
testgamemanager.gd	State transitions, mission progression, win/fail paths, campaign/territory integration
testterritorydata.gd	Main territory map load and IDs
testcampaignterritorymapping.gd	50-day DayConfig → territory_id validity
testcampaignterritoryupdates.gd	apply_day_result_to_territory + SignalBus
testterritoryeconomybonuses.gd	Gold modifier aggregation
testworldmapui.gd	WorldMap button labels on territory_state_changed
testhexgrid.gd	42 slots, place/sell/upgrade, resource deduction, signals
test_ring_rotation.gd	42-slot counts, rotate_ring + ring_rotated, RING_ROTATE state, save v1 load + slot-index guard
testbuildingbase.gd	Combat loop, targeting, fire rate, upgrade stats
testprojectilesystem.gd	Init paths, travel, collision, damage matrix, immunity, miss
testsimulationapi.gd	All manager public methods callable without UI
testenemypathfinding.gd	EnemyBase nav, attack, health_depleted → gold signal
test_boss_day_flow.gd	Prompt 21: Boss day progression, territory secure on mini-boss kill
test_campaign_autoload_and_day_flow.gd	Prompt 21: Autoload registration order, campaign start/day progression
test_consumables.gd	Prompt 25: Consumable stacking, effect_tags handling, mission-start application
test_shop_rotation.gd	Group 10: `get_daily_items` rotation + SimBot `difficulty_target` on strategy profiles
test_endless_mode.gd	Prompt 23: Endless run start, wave scaling past day 50, hub suppression
test_enemy_dot_system.gd	Prompt 6: DoT burn/poison stacking, tick damage, duration, cleanup
test_florence.gd	Prompt 15: Florence meta-state counters, day advance priority, dialogue conditions
test_relationship_manager.gd	Prompt 22: Affinity add/get, tier lookup, save/restore, event-driven deltas
test_relationship_manager_tiers.gd	Prompt 28: Tier boundary values, multi-signal affinity accumulation, clamping; `SaveManager.start_new_attempt()` before `mission_won` in signal chain tests
test_save_manager.gd	Prompt 25: Save/load round-trip, slot management, payload structure
test_save_manager_slots.gd	Prompt 28: Slot rotation after max saves, attempt directory isolation, RelationshipManager JSON round-trip (timed `start_new_attempt()` for distinct attempt IDs)
test_settings_manager.gd	Prompt 24: Volume set/get, keybind remap, config file persistence
test_sybil_passive_manager.gd	Sybil passive load/offer/modifier/save tests (`SybilPassiveManager`)
test_chronicle_manager.gd	Chronicle entries/perks, progress, save/load, signals (`ChronicleManager`)
test_simbot_handlers.gd	Prompt 25: SimBot signal handlers, wave/mission counters, metrics
test_tower_enchantments.gd	Prompt 4: Tower enchantment composition, projectile damage/type override
test_weapon_structural.gd	Audit 6: WeaponLevelData structural fields validation
test_building_specials.gd	Audit 6: Archer Barracks/Shield Generator special behavior validation
test_weapon_upgrade_manager.gd	Prompt 3: Weapon level progression, cost checks, stat lookup, reset
ADDITIONAL SCRIPTS (not previously indexed)
File	What it does
scenes/hub/character_base_2d.gd	Prompt 14: Clickable hub character node — exports CharacterData, emits character_interacted
scripts/florence_data.gd	Prompt 15: FlorenceData resource class — run meta-state (counters, unlock flags)
scripts/resources/strategyprofileconfig.gd	Prompt 16: StrategyProfileConfig wrapper for SimBot profile loading
scripts/weapon_upgrade_manager.gd	Prompt 3: WeaponUpgradeManager — per-weapon level tracking, upgrade cost, stat lookup
scripts/ui/settings_screen.gd	Prompt 24: SettingsScreen — audio sliders, graphics quality, keybind remap, Back button
KNOWN OPEN ISSUES (as of Autonomous Session 3)

    Sell UX is now wired in build mode: InputManager routes slot clicks to BuildMenu placement/sell mode.

    Phase 6 playtest rows 5 (sell), 6 (Sybil shockwave full verify), 7 (Arnulf full verify), 10 (between-mission full loop) not fully confirmed.

    WAVES_PER_MISSION = 3 in GameManager (dev cap; final value is 10).

    dev_unlock_all_research = true in main.tscn (dev flag; must be set false for release).

    SimBot: strategy `activate`, `decide_mercenaries`, `get_log` (Prompt 12); building/spell/wave bot_* helpers remain.

    Windows headless main.tscn run may SIGSEGV; use editor F5 for full loop on Windows.

    `GDAIMCPRuntime` is registered in `project.godot` for the GDAI MCP plugin; requires the plugin enabled in the editor for full behavior.

PHYSICS LAYERS
Layer	Assigned to
1	Tower (StaticBody3D)
2	Enemies
5	Projectiles
7	HexGrid slots (Area3D)
INPUT ACTIONS (defined in project.godot Input Map)
Action Name	Default Binding	Purpose
fire_primary	Left Mouse	Florence crossbow
fire_secondary	Right Mouse	Florence rapid missile
cast_shockwave	Space	Sybil's Shockwave spell
toggle_build_mode	B or Tab	Enter/exit build mode
cancel	Escape	Exit build mode / close menu
SCENE TREE OVERVIEW (main.tscn)

/root/Main (Node3D)
├── Camera3D
├── DirectionalLight3D
├── TerrainContainer (Node3D) — Prompt 33: `CampaignManager._load_terrain` instances `terrain_*.tscn` here
├── Tower (StaticBody3D) [tower.tscn]
│ ├── TowerMesh (MeshInstance3D)
│ ├── TowerCollision (CollisionShape3D)
│ ├── HealthComponent (Node)
│ └── TowerLabel (Label3D)
├── HexGrid (Node3D) [hex_grid.tscn]
│ └── HexSlot00..HexSlot23 (Area3D ×24)
├── Arnulf (CharacterBody3D) [arnulf.tscn]
├── BuildingContainer (Node3D)
├── ProjectileContainer (Node3D)
├── EnemyContainer (Node3D)
├── Managers (Node)
│ ├── WaveManager (Node)
│ ├── SpellManager (Node)
│ ├── ResearchManager (Node)
│ ├── ShopManager (Node)
│ └── InputManager (Node)
└── UI (CanvasLayer)
  ├── UIManager (Control)
  ├── HUD [hud.tscn]
  ├── BuildMenu [build_menu.tscn]
  ├── BetweenMissionScreen [between_mission_screen.tscn]
  ├── MainMenu [main_menu.tscn]
  ├── MissionBriefing (Control)
  └── EndScreen (Control)

LATEST CHANGES (2026-03-28 Prompt 27)

    - Prompt 27 audit backlog execution (`docs/archived/prompts/PROMPT_27_IMPLEMENTATION.md`): RAG pipeline MCP wiring; assert→push_warning in 9 production files; RelationshipManager wired into SaveManager; get_node→get_node_or_null in 4 UI/input files; removed obsolete `wave_failed`/`wave_completed` signals; orphan leak fixes in 4 test files (17→6 orphans); `tools/run_gdunit_unit.sh` (33 unit tests, ~65s); `tools/run_gdunit_parallel.sh` (8-process parallel runner, ~2m45s vs 4m22s baseline); deleted 3 redundant root-level audit docs. Full suite: 522 cases, 0 failures, 6 orphans.

LATEST CHANGES (2026-03-25)

    - Prompt 15 Florence meta-state: `FlorenceData` resource, `Types.DayAdvanceReason`, `SignalBus.florence_state_changed`, `GameManager` day/counter wiring, hub debug label, dialogue condition keys, and `tests/test_florence.gd` (parse-safety fixes: enum cast + type inference).

    - Prompt 13 hub dialogue (`docs/archived/prompts/PROMPT_13_IMPLEMENTATION.md`): `DialogueManager` autoload; `DialogueEntry` / `DialogueCondition`; `res://resources/dialogue/**` pools; `dialogue_ui.tscn`; `UIManager.show_dialogue_for_character` + queue; `BetweenMissionScreen` hub lines for Sybil + Arnulf; `test_dialogue_manager.gd` + `run_gdunit_quick.sh` allowlist.

    - Prompt 12 mercenary roster + offers (`docs/archived/prompts/PROMPT_12_IMPLEMENTATION.md`): `MercenaryOfferData`, `MercenaryCatalog`, `MiniBossData`, `res://resources/mercenary_catalog.tres` + offers; `CampaignManager` purchase/preview/defection/auto-select; `SignalBus` mercenary + roster signals; `BetweenMissionScreen` Mercenaries tab; `SimBot` strategy + `decide_mercenaries`; GdUnit suites in `run_gdunit_quick.sh` allowlist; `GameManager._transition_to` idempotent for same state.

LATEST CHANGES (2026-03-24)

    - Prompt 10 fixes (see `docs/archived/prompts/PROMPT_10_IMPLEMENTATION.md`; `PROMPT_10_FIXES.md` removed 2026-04-20): WaveManager `get_node_or_null` for EnemyContainer/SpawnPoints; `test_wave_manager` / `test_boss_waves` add SpawnPoints to tree before Marker3D `global_position`; `WeaponLevelData` `.tres` `script_class` header; `test_campaign_manager` GdUnit `assert_that().is_not_null()`; `GameManager` `push_warning` + `mission_won` hub (`project.godot` CampaignManager before GameManager).
- Prompt 10 mini-boss + campaign boss (`docs/archived/prompts/PROMPT_10_IMPLEMENTATION.md`):
  - `BossData` (`res://scripts/resources/boss_data.gd`), `.tres` bosses under `res://resources/bossdata_*.tres`.
  - `BossBase` (`res://scenes/bosses/boss_base.{gd,tscn}`).
  - `SignalBus`: `boss_spawned`, `boss_killed`, `campaign_boss_attempted`.
  - `GameManager` / `CampaignManager`: Day 50 + synthetic boss-attack day flow; `get_day_config_for_index`; territory secure on mini-boss kill.
  - `WaveManager`: `boss_registry`, `set_day_context`, `ensure_boss_registry_loaded`, boss wave + escorts (`Types.EnemyType.keys()` string match).
  - `DayConfig`: `boss_id`, `is_mini_boss`, `is_boss_attack_day`; `CampaignConfig.starting_territory_ids`; `TerritoryData.is_secured`, `has_boss_threat`.
  - Tests: `test_boss_data.gd`, `test_boss_base.gd`, `test_boss_waves.gd`, `test_final_boss_day.gd`; additions in `test_wave_manager.gd`.

- Prompt 7 campaign/day layer added:
  - New autoload: `CampaignManager` (`res://autoloads/campaign_manager.gd`).
  - New resource classes:
    - `CampaignConfig` (`res://scripts/resources/campaign_config.gd`)
    - `DayConfig` (`res://scripts/resources/day_config.gd`)
  - New campaign resources:
    - `res://resources/campaigns/campaign_short_5_days.tres`
    - `res://resources/campaigns/campaign_main_50_days.tres`
  - `SignalBus` added campaign/day lifecycle signals:
    - `campaign_started`, `day_started`, `day_won`, `day_failed`, `campaign_completed`
  - `GameManager` now exposes `start_mission_for_day(day_index, day_config)` and delegates day progression to `CampaignManager`.
  - `WaveManager` now supports day config fields:
    - `configured_max_waves`, `enemy_hp_multiplier`, `enemy_damage_multiplier`, `gold_reward_multiplier`
  - `BetweenMissionScreen` now displays day info and routes next progression via `CampaignManager.start_next_day()`.
  - Added tests:
    - `res://tests/test_campaign_manager.gd`
    - Prompt 7 additions in `res://tests/test_wave_manager.gd`
    - Prompt 7 additions in `res://tests/test_game_manager.gd`

- Prompt 9 factions + weighted waves (`docs/archived/prompts/PROMPT_9_IMPLEMENTATION.md`):
  - `FactionData`, `FactionRosterEntry`; `.tres` factions `DEFAULT_MIXED`, `ORC_RAIDERS`, `PLAGUE_CULT`.
  - `WaveManager` roster-weighted spawns (total `N×6`), `set_faction_data_override`, `get_mini_boss_info_for_wave`, `faction_registry`.
  - `CampaignManager.faction_registry`, `validate_day_configs`.
  - `DayConfig.faction_id` default `DEFAULT_MIXED`; `is_mini_boss_day`; `TerritoryData.default_faction_id`.
  - `GameManager` applies `WaveManager.configure_for_day` after `reset_for_new_mission`.
  - Tests: `res://tests/test_faction_data.gd`, Prompt 9 cases in `res://tests/test_wave_manager.gd`.

- InputManager build-mode click now raycasts hex slots on layer 7 and routes menu mode by occupancy.
- BuildMenu now supports `open_for_sell_slot(slot_index, slot_data)` and a sell panel with Sell/Cancel actions.
- HexGrid slot click callback now only updates highlight in build mode (menu opening is centralized in InputManager).
- Added concrete HexGrid sell-flow tests for slot clearing, refund correctness, and `building_sold` signal emission.
- Implementation notes recorded in `docs/archived/prompts/PROMPT_1_IMPLEMENTATION.md`.
- Phase 2 firing changes added:
  - `WeaponData` now includes assist/miss tuning fields (all default to `0.0`).
  - `Tower` manual shots now pass through private aim helper for cone assist + miss perturbation.
  - `crossbow.tres` has initial tuning defaults (`7.5`, `0.05`, `2.0`), `rapid_missile.tres` remains `0.0`.
  - Added simulation API tests covering assist, miss, and autofire bypass behavior.
- Implementation notes recorded in `docs/archived/prompts/PROMPT_2_IMPLEMENTATION.md`.
- Phase 3 weapon-upgrade system added:
  - `WeaponLevelData` resource class (`res://scripts/resources/weapon_level_data.gd`)
  - `WeaponUpgradeManager` scene-bound manager (`/root/Main/Managers/WeaponUpgradeManager`)
  - New level resources in `res://resources/weapon_level_data/` (crossbow + rapid missile, levels 1-3)
  - `SignalBus.weapon_upgraded(weapon_slot, new_level)`
  - `BetweenMissionScreen` now includes a Weapons tab with upgrade controls
  - `Tower` now resolves effective damage/speed/reload/burst via manager with null-guard fallback
  - `docs/archived/prompts/PROMPT_3_IMPLEMENTATION.md` records implementation details
- Phase 4 two-slot enchantment system added:
  - New autoload: `EnchantmentManager` (`res://autoloads/enchantment_manager.gd`)
  - New resource class: `EnchantmentData` (`res://scripts/resources/enchantment_data.gd`)
  - New resources: `res://resources/enchantments/{scorching_bolts,sharpened_mechanism,toxic_payload,arcane_focus}.tres`
  - New SignalBus signals: `enchantment_applied(...)`, `enchantment_removed(...)`
  - `Tower` now composes projectile damage + damage type using `"elemental"` and `"power"` enchantment slots
  - `ProjectileBase.initialize_from_weapon(...)` now supports optional custom damage and damage type
  - `GameManager.start_new_game()` resets enchantment state
  - `BetweenMissionScreen` now includes enchantment apply/remove controls in Weapons tab
  - Added tests: `res://tests/test_enchantment_manager.gd`, `res://tests/test_tower_enchantments.gd`
  - Added projectile regression: `test_initialize_from_weapon_without_custom_values_uses_physical`
- Phase 5 DoT system added:
  - `DamageCalculator.calculate_dot_tick(...)` now returns live per-tick DoT values (no stub).
  - `EnemyBase` now stores `active_status_effects` and exposes `apply_dot_effect(effect_data: Dictionary)`.
  - Burn: one stack per source with duration refresh + max total damage retention.
  - Poison: additive stacks capped by `MAX_POISON_STACKS`.
  - `ProjectileBase.initialize_from_building(...)` now accepts DoT fields and applies DoT on hit for fire/poison.
  - Fire Brazier / Poison Vat `.tres` now include conservative DoT defaults.
  - Added tests: `res://tests/test_enemy_dot_system.gd`; DoT integration coverage in `res://tests/test_projectile_system.gd`.
- Phase 6 solid-building navigation added:
  - `BuildingBase` scene now includes `BuildingCollision` (`StaticBody3D`) + `NavigationObstacle3D`.
  - `BuildingBase` script now centralizes footprint/obstacle tuning constants and setup.
  - `EnemyBase` ground pathing now tracks progress and applies stuck recovery retargeting.
  - `EnemyBase` flying pathing remains direct steering and ignores ground obstacles.
  - `HexGrid` placement now calls `_activate_building_obstacle(...)` hook.
  - Added pathing integration scenarios in `res://tests/test_enemy_pathfinding.gd`.
  - Added building collision/obstacle scene assertion in `res://tests/test_building_base.gd`.
- Building HP & Destruction system (Chat 3A/3B/3C):
  - `BuildingData.max_hp` / `BuildingData.can_be_targeted_by_enemies` — destructible building data fields.
  - `EnemyData.prefer_building_targets` / `EnemyData.building_detection_radius` — enemy building-targeting data fields.
  - `BuildingBase._setup_health_component()` — conditionally adds `HealthComponent` + `BuildingHpBar` when `max_hp > 0`.
  - `BuildingBase._on_health_depleted()` — emits `SignalBus.building_destroyed`, despawns summons/aura, calls `HexGrid.clear_slot_on_destruction`.
  - `scenes/buildings/destruction_effect.tscn` + `scenes/buildings/destruction_effect.gd` — shrink-and-free visual effect (`DestructionEffect`).
  - `scenes/ui/building_hp_bar.tscn` + `scenes/ui/building_hp_bar.gd` — billboard HP bar driven by `HealthComponent.health_changed` (`BuildingHpBar`).
  - `HexGrid.clear_slot_on_destruction(slot_index)` — clears slot, disables obstacle, frees building node.
  - `HexGrid.get_lowest_hp_pct_building()` — returns building with lowest HP percentage among alive destructible buildings.
  - `EnemyBase._try_building_target_attack` / `_find_building_target` / `_attack_building` — enemy building-targeting loop.
  - `ShopManager._apply_effect("building_repair")` — heals 50 % of max HP on the lowest-HP-pct building via `get_lowest_hp_pct_building()`.
  - MEDIUM .tres files: `max_hp = 300`, `can_be_targeted_by_enemies = true` (13 buildings).
  - LARGE .tres files: `max_hp = 650`, `can_be_targeted_by_enemies = true` (6 buildings).
  - `resources/shop_data/shop_item_building_repair.tres` — building repair shop item.
  - `autoloads/save_manager.gd` — architecture comment: building HP is mission-ephemeral and not persisted.
  - Added tests: `res://tests/test_building_health_component.gd`, `res://tests/test_enemy_building_targeting.gd`, `res://tests/test_building_repair.gd`.
