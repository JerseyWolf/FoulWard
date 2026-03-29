INDEX_SHORT.md
==============

FOUL WARD — INDEX_SHORT.md

Compact repository reference. One-liner per file. **Doc layout:** `docs/README.md`. **Consolidated snapshot (Prompt 26+):** `docs/OPUS_ALL_ACTIONS.md` — single file merging improvement backlog, AGENTS standing orders, PROMPT_26 log, INDEX_SHORT, INDEX_FULL (regenerate after editing sources). Updated: 2026-03-29 (**Prompt 38:** `EconomyManager` wave_clear rewards (`get_wave_reward_*`, `grant_wave_clear_reward`, `wave_cleared` autogrant when mission economy set); passive tick unchanged — `docs/PROMPT_38_IMPLEMENTATION.md`). (**Prompt 37:** `EconomyManager` mission economy (`apply_mission_economy`, passive tick, duplicate scaling, `get_refund`), HexGrid `BuildingBase` `paid_*`/`total_invested_*` placement/sell/upgrade, `tests/unit/test_economy_mission_integration.gd` — `docs/PROMPT_37_IMPLEMENTATION.md`). (**Prompt 36:** `WaveManager` mission `MissionData` spawn queue (`DayConfig.mission_data`), `MissionSpawnRouting` + `RoutePathData` bitmask paths, `EnemyBase.assigned_lane_id`/`assigned_path_id`, `tests/unit/test_mission_spawn_routing.gd` — `docs/PROMPT_36_IMPLEMENTATION.md`). (**Prompt 35:** TD data resources — extended `BuildingData`/`AllyData`/`EnemyData`, new `SpawnEntryData`/`WaveData`/`MissionWavesData`/`LaneData`/`PathData`/`MissionRoutingData`/`MissionEconomyData`/`MissionDataValidation`, `Types` TD enums, `mission_spawn_routing` aligned with `spawn_entries`; `docs/PROMPT_35_IMPLEMENTATION.md`). (**Prompt 34:** `CombatStatsTracker` autoload — `user://simbot/runs/{mission_id}_{timestamp}/` wave/building CSVs; `ProjectileBase` attribution; `EnemyBase` emits `enemy_reached_tower`; `docs/PROMPT_34_IMPLEMENTATION.md`). (**Prompt 33:** terrain system — `Types.TerrainType`/`TerrainEffect`, `TerrainZone`, `NavMeshManager` autoload, `CampaignManager._load_terrain`, `terrain_grassland.tscn`/`terrain_swamp.tscn`, `main.tscn` `TerrainContainer`, `tests/unit/test_terrain.gd`, `FUTURE_3D_MODELS_PLAN.md` §5 — `docs/PROMPT_33_IMPLEMENTATION.md`). (**Prompt 32:** modular building kit — `Types.BuildingBaseMesh`/`BuildingTopMesh`, `BuildingData` kit exports, `ArtPlaceholderHelper.get_building_kit_mesh`, `BuildingBase` `BuildingKitAssembly`, `tests/unit/test_building_kit.gd`, `FUTURE_3D_MODELS_PLAN.md` §4 — `docs/PROMPT_32_IMPLEMENTATION.md`). (**Prompt 31:** rigged GLB mount under `EnemyVisual` / `BossVisual` / `ArnulfVisual`; `RiggedVisualWiring` + idle/walk `AnimationPlayer`; `test_art_placeholders` deep mesh find — `docs/PROMPT_31_IMPLEMENTATION.md`). **Prompt 29:** art pipeline audit verification — `FUTURE_3D_MODELS_PLAN.md` Appendix A (scene grep + helper API); Godot MCP `reload_project` + editor error scan; `# TODO(ART)` on `boss_base.tscn` — `docs/PROMPT_29_IMPLEMENTATION.md`). **Prompt 28:** hex pick fallback + slot collider height; Arnulf leash / immobile ignore; build menu min size; `GameManager` save lambda; `DialogueManager` tracking + `WaveManager` BUILD_MODE countdown pause; `test_relationship_manager_tiers.gd` / `test_save_manager_slots.gd`; consumables + ally combat test fixes — `docs/PROMPT_28_IMPLEMENTATION.md`). **Prompt 26:** Full project audit — 55 unindexed files added, AGENTS.md standing orders, IMPROVEMENTS_TO_BE_DONE.md backlog, test classification — `docs/PROMPT_26_IMPLEMENTATION.md`. **Prompt 24:** programmatic PNG icons (`tools/generate_placeholder_icons.gd`, `addons/fw_placeholder_icons`), `ArtPlaceholderHelper` icon textures, `SettingsManager` + `scenes/ui/settings_screen`, UI wiring — `docs/PROMPT_24_IMPLEMENTATION.md`. **Prompt 23:** Endless Run — `Types.GameState.ENDLESS`, `CampaignManager.is_endless_mode` / `start_endless_run`, synthetic day scaling, main menu — `docs/PROMPT_23_IMPLEMENTATION.md`. **Prompt 22:** relationship tiers + affinity autoload, dialogue `relationship_tier` conditions — `docs/PROMPT_22_IMPLEMENTATION.md`. Prompt 19: Blender batch GLBs under `res://art/generated/**`, `generation_log.json`, `FUTURE_3D_MODELS_PLAN.md`, `# TODO(ART)` in combat/hub scenes; see `docs/PROMPT_19_IMPLEMENTATION.md`. **Prompt 18:** local RAG + MCP pipeline under `~/LLM` — `docs/PROMPT_18_IMPLEMENTATION.md`. **Audit 6:** `AUDIT_IMPLEMENTATION_AUDIT_6.md` (multi-spell, structural weapon upgrades, barracks/shield specials, territory aggregates). **Prompt 20:** `docs/obsolete/` archive + INDEX autoload alignment; `docs/PROMPT_20_IMPLEMENTATION.md`.
Source of truth: REPO_DUMP_AFTER_MVP.md; **re-run** `./tools/run_gdunit.sh` after Prompt 12/13 (use `./tools/run_gdunit_quick.sh` for iteration). **Handoff:** `docs/PROBLEM_REPORT.md` lists files and log snippets for GdUnit / `mission_won` / `push_warning` work.
AUTOLOADS (registered in project.godot, in init order)
Autoload Name	Path	What it does
SignalBus	res://autoloads/signal_bus.gd	Central hub for ALL cross-system typed signals. Prompt 10: boss_spawned, boss_killed, campaign_boss_attempted. Prompt 11: ally_spawned, ally_downed, ally_recovered, ally_killed, ally_state_changed (POST-MVP). Prompt 12: mercenary_offer_generated, mercenary_recruited, ally_roster_changed. Prompt 33: enemy_entered_terrain_zone, enemy_exited_terrain_zone, terrain_prop_destroyed, nav_mesh_rebake_requested. No logic, no state.
NavMeshManager	res://scripts/nav_mesh_manager.gd	Prompt 33: registers `NavigationRegion3D`, queues `bake_navigation_mesh` on `nav_mesh_rebake_requested` (rebake queue pattern). Autoload only (no `class_name`).
DamageCalculator	res://autoloads/damage_calculator.gd	Stateless 4×4 damage-type × armor-type matrix. Pure function singleton.
EconomyManager	res://autoloads/economy_manager.gd	Owns gold, building_material, research_material. Emits resource_changed. Prompt 37–38: `get_gold_cost`/`get_material_cost`, `register_purchase`, `get_refund`, `apply_mission_economy`, `get_wave_reward_*`/`grant_wave_clear_reward` (`wave_cleared` when mission economy active), `_process` passive income; HexGrid/build menu/simbot wired.
CampaignManager	res://autoloads/campaign_manager.gd	Day/campaign progress; faction_registry + validate_day_configs; **owned_allies / active_allies_for_next_day**, mercenary catalog + offers, purchase + defection + `auto_select_best_allies` (Prompt 12); **current_ally_roster** sync for spawn (Prompt 11). Prompt 33: `_load_terrain` from `TerritoryData.terrain_type` into `/root/Main/TerrainContainer`. **Init order:** must load **before** GameManager in `project.godot` so `SignalBus.mission_won` runs `_on_mission_won` (day increment) before GameManager hub transition.
RelationshipManager	res://autoloads/relationship_manager.gd	Prompt 22: affinity −100..100 per `character_id`, tiers from `relationship_tier_config.tres`; loads `character_relationship/*.tres` + `relationship_events/*.tres`, applies deltas on SignalBus; `get_tier` / `get_save_data` / `restore_from_save`. **Init order:** after CampaignManager, before GameManager.
SettingsManager	res://autoloads/settings_manager.gd	Prompt 24: `user://settings.cfg` — master/music/SFX linear volumes, graphics quality string, keybind mirror; `AudioServer` Music+SFX buses; `load_settings`/`save_settings`/`set_volume`/`remap_action`. **Init order:** after RelationshipManager, before GameManager.
GameManager	res://autoloads/game_manager.gd	Owns game state, mission index, wave index, territory map runtime; mission rewards + territory bonuses. Prompt 10: final boss state, synthetic boss-attack days, held_territory_ids, prepare_next_campaign_day_if_needed / advance_to_next_day / get_day_config_for_index. Prompt 11: `_spawn_allies_for_current_mission` / `_cleanup_allies` (Main/AllyContainer, AllySpawnPoints). Prompt 12: `notify_mini_boss_defeated` → CampaignManager; `_transition_to` skips duplicate same-state transitions. `_begin_mission_wave_sequence`: Main→Managers→WaveManager via get_node_or_null; `push_warning` if absent (not `push_error` — GdUnit). Subscribes to `mission_won` for BETWEEN_MISSIONS / GAME_WON after CampaignManager (see `PROBLEM_REPORT.md`).
CombatStatsTracker	res://autoloads/combat_stats_tracker.gd	Prompt 34: mission/wave/building combat CSV under `user://simbot/runs/{mission_id}_{timestamp}/` (wave_summary, building_summary, optional event_log); SignalBus adapters + `ProjectileBase`/`EnemyBase` hooks; `SimBot` calls `set_session_seed`. Loads after GameManager in `project.godot`.
SaveManager	res://autoloads/save_manager.gd	Audit 6: rolling autosaves `user://saves/attempt_*/slot_*.json`; autoload singleton only (no `class_name`).
DialogueManager	res://autoloads/dialogue_manager.gd	Prompt 13: loads `DialogueEntry` `.tres` under `res://resources/dialogue/**`; priority, AND conditions, once-only, chain_next_id; signals `dialogue_line_started` / `dialogue_line_finished`; ResearchManager heuristics for `sybil_research_unlocked_any` (`spell` in node_id) and `arnulf_research_unlocked_any` (`arnulf` in node_id). Prompt 28: runtime tracking for gold/research/shop/Arnulf/spell conditions (`get_tracked_gold()`, etc.). See `docs/PROMPT_13_IMPLEMENTATION.md`.
AutoTestDriver	res://autoloads/auto_test_driver.gd	Headless smoke-test driver. Active only when --autotest flag is present.
GDAIMCPRuntime	(uid plugin autoload in project.godot)	GDAI MCP GDExtension bridge — editor HTTP API for MCP when `addons/gdai-mcp-plugin-godot` is enabled.
EnchantmentManager	res://autoloads/enchantment_manager.gd	Phase 4: per-weapon enchantment slots (elemental/power); Tower + BetweenMissionScreen integration.
SCRIPTS (attached to Manager nodes in main.tscn under /root/Main/Managers/)
Class Name	Path	What it does
Types	res://scripts/types.gd	All enums and shared constants. Prompt 11: `AllyClass` (MELEE/RANGED/SUPPORT); `TargetPriority` shared with allies (MVP: CLOSEST). Prompt 14: `HubRole` marks between-mission hub character categories. Prompt 32: `BuildingBaseMesh`, `BuildingTopMesh` (modular kit). Prompt 33: `TerrainType`, `TerrainEffect`. Prompt 35: `BuildingSizeClass`, `UnitSize`, `AllyAiMode`, `SummonSpawnType`, aura enums, `EnemyBodyType`, `MissionBalanceStatus`. Not an autoload; referenced as Types.XXX.
MissionSpawnRouting	res://scripts/mission_spawn_routing.gd	Prompt 35–36: resolves lanes/paths, builds spawn queue from `WaveData.spawn_entries`, bitmask `RoutePathData.body_types_allowed`; validates `MissionData`; `WaveManager` integration Prompt 36.
TerrainZone	res://scripts/terrain_zone.gd	Prompt 33: `Area3D` SLOW zones; emits SignalBus on enemy enter/exit.
terrain_navigation_region.gd	res://scripts/terrain_navigation_region.gd	Prompt 33: `NavigationRegion3D` helper — `create_from_mesh` from sibling `GroundMesh`.
HealthComponent	res://scripts/health_component.gd	Reusable HP tracker. Emits local signals health_depleted, health_changed.
WaveManager	res://scripts/wave_manager.gd	Spawns enemies per wave from FactionData-weighted roster (total N×6), countdown, wave signals. `_enemy_container` / `_spawn_points` via get_node_or_null(/root/Main/...); null-safe spawn. Prompt 10: boss_registry, ensure_boss_registry_loaded, set_day_context, boss wave on configured index + escorts. Prompt 28: pauses inter-wave countdown in `BUILD_MODE` (`is_wave_countdown_paused()`). Prompt 36: optional `DayConfig.mission_data` → timed spawn queue + `MissionSpawnRouting` / `RoutePathData`; `spawn_enemy_on_path`, `build_spawn_queue`, `resolve_path_for_spawn`, `validate_*`.
SpawnQueueRow	res://scripts/spawn_queue_row.gd	Prompt 36: runtime spawn row (`spawn_time_sec`, `enemy_data`, `lane_id`, `path_id`).
SpellManager	res://scripts/spell_manager.gd	Owns mana pool, spell cooldowns. Multi-spell registry + `cast_selected_spell` / hotkeys (Audit 6); effects include shockwave, slow_field, arcane_beam, tower_shield.
ResearchManager	res://scripts/research_manager.gd	Tracks unlocked research nodes. Gates locked buildings.
ShopManager	res://scripts/shop_manager.gd	Processes shop purchases. Applies mission-start consumable effects.
InputManager	res://scripts/input_manager.gd	Translates mouse/keyboard input into public method calls on managers.
SimBot	res://scripts/sim_bot.gd (+ alias `res://scripts/simbot.gd`)	Headless automated simulation bot. Audit 4: `get_log()` → Dictionary; `run_single` / `run_batch` CSV under `user://simbot/logs/`. Prompt 16 Phase 2: `StrategyProfile` resources.
ArtPlaceholderHelper	res://scripts/art/art_placeholder_helper.gd	Stateless utility resolving placeholder meshes, materials, and icons from res://art based on Types enums and string IDs. Handles caching, fallbacks, and generated-asset priority. Prompt 32: `get_building_kit_mesh()` + `res://art/generated/kit/*.glb` (box fallback).
RiggedVisualWiring	res://scripts/art/rigged_visual_wiring.gd	Prompt 31: GLB path map (enemies/bosses/Arnulf), mount/clear visual slots, locomotion idle/walk on `AnimationPlayer` (clips `idle`/`walk`/`death`).
PlaceholderIconGenerator	res://tools/generate_placeholder_icons.gd	Prompt 24: `class_name PlaceholderIconGenerator` — 64×64 PNG placeholders (editor Project menu or `run_generate_placeholder_icons.gd`).
fw_placeholder_icons	res://addons/fw_placeholder_icons/plugin.cfg	Prompt 24: EditorPlugin — Project → Generate Placeholder Icons.
tools/generate_placeholder_glbs_blender.py	res://tools/generate_placeholder_glbs_blender.py	Blender 4.x headless: Rigify/blockout GLBs → `res://art/generated/{enemies,allies,buildings,bosses,misc}/`; writes `art/generated/generation_log.json`. Requires system numpy for glTF exporter.
tools/run_gdunit_unit.sh	tools/run_gdunit_unit.sh	Prompt 27: Runs only pure unit suites (no await/scenes/timers). ~65s wall-clock. Prompt 33: includes `tests/unit/test_terrain.gd`.
tools/run_gdunit_parallel.sh	tools/run_gdunit_parallel.sh	Prompt 27: 8-parallel-process test runner for all 58 test files. ~2m45s wall-clock (37% faster than sequential).
art/generated/generation_log.json	res://art/generated/generation_log.json	Batch export inventory (entity_id, paths, animation_count, has_rig); optional `godot_mcp.reload_project` metadata.
FUTURE_3D_MODELS_PLAN.md	res://FUTURE_3D_MODELS_PLAN.md	Production 3D + hub portrait roadmap; placeholder table from `generation_log.json`; **§4 Modular Building Kit** (Prompt 32); **§5 Terrain System** (Prompt 33); scene art audit appendix (Prompt 29 refresh); PhysicalBone3D + AnimationPlayer wiring notes.
MainRoot	res://scripts/main_root.gd	Applies root window content scale at startup (stretch fix for Godot 4.4+).
SCENES (runtime instantiated or statically placed)
Class Name	Script Path	Scene Path	What it does
Tower	res://scenes/tower/tower.gd	res://scenes/tower/tower.tscn	Player's stationary avatar. Fires crossbow + rapid missile.
Arnulf	res://scenes/arnulf/arnulf.gd	res://scenes/arnulf/arnulf.tscn	AI melee companion. State machine: IDLE/PATROL/CHASE/ATTACK/DOWNED/RECOVERING. Prompt 11: emits generic `ally_*` with id `arnulf` + `ALLY_ID_ARNULF`. Prompt 31: `ArnulfVisual` + `allies/arnulf.glb`, locomotion anims.
AllyBase	res://scenes/allies/ally_base.gd	res://scenes/allies/ally_base.tscn	Prompt 11 + Audit 6: DOWNED/RECOVERING when `uses_downed_recovering`; `can_target_flying` / `preferred_targeting` (CLOSEST, LOWEST_HP, …); ally_spawned / ally_downed / ally_recovered / ally_killed.
HexGrid	res://scenes/hex_grid/hex_grid.gd	res://scenes/hex_grid/hex_grid.tscn	24-slot ring grid. Manages building placement, sell, upgrade. Prompt 37: `EconomyManager` costs/refunds, `record_initial_purchase`/`record_upgrade_cost` on `BuildingBase`.
BuildingBase	res://scenes/buildings/building_base.gd	res://scenes/buildings/building_base.tscn	Base class for all 8 building types. Auto-targets and fires. Prompt 32: non-default `BuildingData` kit enums → `BuildingKitAssembly` child (`ArtPlaceholderHelper.get_building_kit_mesh`). Prompt 37: `paid_gold`/`paid_material`, `total_invested_*`, `get_sell_refund`/`get_upgrade_cost`.
EnemyBase	res://scenes/enemies/enemy_base.gd	res://scenes/enemies/enemy_base.tscn	Base class for all 6 enemy types. Nav, attack, die, reward. Prompt 31: `EnemyVisual` mounts rigged GLB per `EnemyType` (bat: placeholder mesh), idle/walk anims. Prompt 33: terrain zone speed multiplier (min of overlapping zones).
TerrainGrassland	—	res://scenes/terrain/terrain_grassland.tscn	Prompt 33: default battle ground + `NavRegion` (`terrain_navigation_region.gd`).
TerrainSwamp	—	res://scenes/terrain/terrain_swamp.tscn	Prompt 33: grassland + `TerrainZone` (0.55×).
BossBase	res://scenes/bosses/boss_base.gd	res://scenes/bosses/boss_base.tscn	Prompt 10: extends EnemyBase; initialize_boss_data(BossData); emits boss_spawned / boss_killed. Prompt 31: `BossVisual` + boss_id GLB (1.5×) or placeholder box.
ProjectileBase	res://scenes/projectiles/projectile_base.gd	res://scenes/projectiles/projectile_base.tscn	Physics-driven projectile. Hits first valid enemy, self-destructs.
UI SCRIPTS & SCENES
Class Name	Script Path	Scene Path	What it does
UIManager	res://ui/ui_manager.gd	(Control node in main.tscn)	Lightweight state router + hub dialogue router. Shows/hides UI panels on game_state_changed and wires `Hub2DHub` + `DialoguePanel`. Prompt 14: `show_dialogue(display_name, entry)` + `clear_dialogue()`; still supports `show_dialogue_for_character` with queue.
Hub2DHub	res://ui/hub.gd	res://ui/hub.tscn	2D between-mission hub overlay. Instantiates clickable characters from `CharacterCatalog` and routes focus to `BetweenMissionScreen` + dialogue.
DialoguePanel	res://ui/dialogue_panel.gd	res://ui/dialogue_panel.tscn	Global click-to-continue dialogue overlay (SpeakerLabel + TextLabel). Chains via `DialogueEntry.chain_next_id`.
DialogueUI	res://ui/dialogueui.gd	res://ui/dialogueui.tscn	Legacy placeholder hub dialogue panel (Prompt 13). Kept for reference; hub now uses DialoguePanel.
HUD	res://ui/hud.gd	res://ui/hud.tscn	Combat overlay: resources, wave counter, HP bar, spells.
BuildMenu	res://ui/build_menu.gd	res://ui/build_menu.tscn	Radial building placement panel. Opens on hex slot click in BUILDMODE.
BetweenMissionScreen	res://ui/between_mission_screen.gd	res://ui/between_mission_screen.tscn	Post-mission tabs: World Map, Shop, Research, Buildings, Weapons, Mercenaries (Prompt 12). NEXT DAY. Prompt 13: on `BETWEEN_MISSIONS`, `_show_hub_dialogue()` → UIManager for SPELL_RESEARCHER then COMPANION_MELEE (queued).
WorldMap	res://ui/world_map.gd	res://ui/world_map.tscn	Territory list + details (read-only; GameManager state).
MainMenu	res://ui/main_menu.gd	res://ui/main_menu.tscn	Title screen. Start, Settings → `settings_screen.tscn` overlay, Quit.
SettingsScreen	res://scripts/ui/settings_screen.gd	res://scenes/ui/settings_screen.tscn	Prompt 24: audio sliders, graphics quality, keybind remap, Back.
MissionBriefing	res://ui/mission_briefing.gd	(Control node in main.tscn)	Shows mission number. BEGIN button → GameManager.start_wave_countdown.
EndScreen	res://ui/end_screen.gd	(Control node in main.tscn)	Final screen for win/lose. Restart and Quit buttons.
CUSTOM RESOURCE TYPES (script classes, not .tres files)
Class Name	Script Path	Fields summary
EnemyData	res://scripts/resources/enemy_data.gd	enemy_type, display_name, max_hp, move_speed, damage, attack_range, attack_cooldown, armor_type, gold_reward, is_ranged, is_flying, color, damage_immunities[]; Prompt 35: id/description/icon, armor_flat/MR/status resist, body_type, collision/blocker flags, Florence/blocker attack knobs, CC flags, bounty/threat/tags, effective getters
BuildingData	res://scripts/resources/building_data.gd	building_type, display_name, gold_cost, material_cost, upgrade_gold_cost, upgrade_material_cost, damage, upgraded_damage, fire_rate, attack_range, upgraded_range, damage_type, targets_air, targets_ground, is_locked, unlock_research_id, color, dot_enabled, dot_total_damage, dot_tick_interval, dot_duration, dot_effect_type, dot_source_id, dot_in_addition_to_hit; Prompt 32: base_mesh_id, top_mesh_id, accent_color (modular kit); Prompt 35: id/description/icon/scene_path, size_class/ring_index, cost_* overrides, sell_refund_fraction, summoner/aura/healer, upgrade_next chain, meta tags + validation
WeaponData	res://scripts/resources/weapon_data.gd	weapon_slot, display_name, damage, projectile_speed, reload_time, burst_count, burst_interval, can_target_flying, assist_angle_degrees, assist_max_distance, base_miss_chance, max_miss_angle_degrees
SpellData	res://scripts/resources/spell_data.gd	spell_id, display_name, mana_cost, cooldown, damage, radius, damage_type, hits_flying
ResearchNodeData	res://scripts/resources/research_node_data.gd	node_id, display_name, research_cost, prerequisite_ids[], description
ShopItemData	res://scripts/resources/shop_item_data.gd	item_id, display_name, gold_cost, material_cost, description
TerritoryData	res://scripts/resources/territory_data.gd	territory_id, terrain_type (`Types.TerrainType`), ownership, default_faction_id (POST-MVP), is_secured, has_boss_threat, bonus_flat_gold_end_of_day, bonus_percent_gold_end_of_day, POST-MVP bonus hooks
TerritoryMapData	res://scripts/resources/territory_map_data.gd	territories: Array[TerritoryData], get_territory_by_id, has_territory
FactionRosterEntry	res://scripts/resources/faction_roster_entry.gd	enemy_type, base_weight, min_wave_index, max_wave_index, tier
FactionData	res://scripts/resources/faction_data.gd	faction_id, display_name, description, roster[], mini_boss_ids (BossData.boss_id strings), mini_boss_wave_hints, roster_tier, difficulty_offset; get_entries_for_wave, get_effective_weight_for_wave; BUILTIN_FACTION_RESOURCE_PATHS
BossData	res://scripts/resources/boss_data.gd	boss_id, stats, escort_unit_ids, phase_count, is_mini_boss / is_final_boss, boss_scene; build_placeholder_enemy_data(); BUILTIN_BOSS_RESOURCE_PATHS
DayConfig	res://scripts/resources/day_config.gd	day_index, mission_index, territory_id, faction_id (default DEFAULT_MIXED), is_mini_boss_day, is_mini_boss (alias), is_final_boss, boss_id, is_boss_attack_day, display_name, wave/tuning multipliers
CampaignConfig	res://scripts/resources/campaign_config.gd	campaign_id, display_name, day_configs, starting_territory_ids, territory_map_resource_path, short-campaign flags
StrategyProfile	res://scripts/resources/strategyprofile.gd	profile_id, description, build_priorities, placement_preferences, spell_usage, upgrade_behavior, difficulty_target
AllyData	res://scripts/resources/ally_data.gd	Prompt 11: ally_id, ally_class, stats, preferred_targeting (CLOSEST MVP), is_unique. Prompt 12: role, damage_type, attack_damage / patrol / recovery, scene_path, is_starter_ally, is_defected_ally, debug_color; POST-MVP progression fields. Prompt 35: unit_size, armor/MR, fire_rate/splash/DoT, blocker/leash, ai_mode, optional aura/healer, summon lifecycle, tags
SpawnEntryData	res://scripts/resources/spawn_entry_data.gd	Prompt 35: enemy_data, count, start_time_sec, interval_sec, lane_id, path_id, spawn_offset_variance_sec, tags
WaveData	res://scripts/resources/wave_data.gd	Prompt 35: wave_number, spawn_entries[], delays, reward overrides, recommended_tags, simbot_label
MissionWavesData	res://scripts/resources/mission_waves_data.gd	Prompt 35: mission_id, waves[], starting_gold/material, florence_starting_hp, mission_tags, layout_preset
LaneData	res://scripts/resources/lane_data.gd	Prompt 35: id, florence_entry_tag, threat_weight, allowed_path_ids, tags
RoutePathData	res://scripts/resources/path_data.gd	Prompt 35: `class_name RoutePathData` (avoids engine `PathData`); id, lane_id, curve3d_path, body_types_allowed bitmask, total_length_hint, blocker_sensitive, leak_entry_point_tag, tags
MissionRoutingData	res://scripts/resources/mission_routing_data.gd	Prompt 35: mission_id, lanes[], paths[], lookups by id
MissionEconomyData	res://scripts/resources/mission_economy_data.gd	Prompt 35: mission_id, passive income, wave/leak bonuses, sell_refund_global_multiplier, duplicate_cost_k_override, tags
MissionDataValidation	res://scripts/resources/mission_data_validation.gd	Prompt 35: static helpers delegating to `collect_validation_warnings` on mission resources; `validate_mission` / `validate_routing` / `validate_wave` return `PackedStringArray` error lines (non-destructive)
MissionData	res://scripts/resources/mission_data.gd	Optional `DayConfig.mission_data`: routing + waves; `get_wave`/`has_wave_entries` by `wave_number`; Prompt 35: uses `spawn_entries`
ExampleMissionResources	res://scripts/resources/example_mission_resources.gd	Prompt 35+: const paths to `resources/examples/prompt35/*.tres` samples (arrow tower, runner enemy, waves, mission waves, routing, economy)
MercenaryOfferData	res://scripts/resources/mercenary_offer_data.gd	Prompt 12: ally_id, costs, day range, is_defection_offer.
MercenaryCatalog	res://scripts/resources/mercenary_catalog.gd	Prompt 12: offers pool, max_offers_per_day, get_daily_offers.
MiniBossData	res://scripts/resources/mini_boss_data.gd	Prompt 12: defection metadata (defected_ally_id, costs).
DialogueCondition	res://scripts/resources/dialogue/dialogue_condition.gd	key, comparison (==, !=, >, >=, <, <=), value (Variant); optional `condition_type` **relationship_tier** + `character_id` / `required_tier` (Prompt 22); AND only; evaluated by DialogueManager
RelationshipTierConfig	res://scripts/resources/relationship_tier_config.gd	Prompt 22: `tiers` Array[Dictionary] `{ name, min_affinity }` ascending; shared tier names for `RelationshipManager.get_tier`.
CharacterRelationshipData	res://scripts/resources/character_relationship_data.gd	Prompt 22: `character_id`, `starting_affinity`, `display_name` — one `.tres` per character under `res://resources/character_relationship/`.
RelationshipEventData	res://scripts/resources/relationship_event_data.gd	Prompt 22: `signal_name` (SignalBus), `character_deltas` Dictionary id → float.
DialogueEntry	res://scripts/resources/dialogue/dialogue_entry.gd	entry_id, character_id, text, priority, once_only, chain_next_id, conditions[]
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
res://resources/campaign_main_50days.tres	CampaignConfig	50 linear days + territory_map_resource_path (Prompt 8 canonical)
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
test_art_placeholders.gd	Prompt 17: ArtPlaceholderHelper placeholder mesh/material resolution, generated-asset priority, scene wiring, and cache/fallback behavior
tests/unit/test_building_kit.gd	Prompt 32: `get_building_kit_mesh` Node3D + two children, accent on top surface 0, GLB→BoxMesh fallback, BuildingData kit fields
tests/unit/test_terrain.gd	Prompt 33: TerrainZone signals, EnemyBase terrain multiplier, NavMeshManager queue, `TerritoryData.terrain_type`
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
testhexgrid.gd	24 slots, place/sell/upgrade, resource deduction, signals
testbuildingbase.gd	Combat loop, targeting, fire rate, upgrade stats
testprojectilesystem.gd	Init paths, travel, collision, damage matrix, immunity, miss
testsimulationapi.gd	All manager public methods callable without UI
testenemypathfinding.gd	EnemyBase nav, attack, health_depleted → gold signal
test_boss_day_flow.gd	Prompt 21: Boss day progression, territory secure on mini-boss kill
test_campaign_autoload_and_day_flow.gd	Prompt 21: Autoload registration order, campaign start/day progression
test_consumables.gd	Prompt 25: Consumable stacking, effect_tags handling, mission-start application
test_endless_mode.gd	Prompt 23: Endless run start, wave scaling past day 50, hub suppression
test_enemy_dot_system.gd	Prompt 6: DoT burn/poison stacking, tick damage, duration, cleanup
test_florence.gd	Prompt 15: Florence meta-state counters, day advance priority, dialogue conditions
test_relationship_manager.gd	Prompt 22: Affinity add/get, tier lookup, save/restore, event-driven deltas
test_relationship_manager_tiers.gd	Prompt 28: Tier boundary values, multi-signal affinity accumulation, clamping; `SaveManager.start_new_attempt()` before `mission_won` in signal chain tests
test_save_manager.gd	Prompt 25: Save/load round-trip, slot management, payload structure
test_save_manager_slots.gd	Prompt 28: Slot rotation after max saves, attempt directory isolation, RelationshipManager JSON round-trip (timed `start_new_attempt()` for distinct attempt IDs)
test_settings_manager.gd	Prompt 24: Volume set/get, keybind remap, config file persistence
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
scripts/resources/test_strategyprofileconfig.gd	Prompt 16: Test helper resource class for SimBot profile tests
scripts/simbot_logger.gd	Prompt 16: SimBot CSV logging utility — writes batch results to user://simbot/logs/
scripts/weapon_upgrade_manager.gd	Prompt 3: WeaponUpgradeManager — per-weapon level tracking, upgrade cost, stat lookup
scripts/ui/settings_screen.gd	Prompt 24: SettingsScreen — audio sliders, graphics quality, keybind remap, Back button
ui/dialogue_ui.gd	Prompt 13: Legacy DialogueUI placeholder panel (kept for reference; DialoguePanel is active)
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

    - Prompt 27 audit backlog execution (`docs/PROMPT_27_IMPLEMENTATION.md`): RAG pipeline MCP wiring; assert→push_warning in 9 production files; RelationshipManager wired into SaveManager; get_node→get_node_or_null in 4 UI/input files; removed obsolete `wave_failed`/`wave_completed` signals; orphan leak fixes in 4 test files (17→6 orphans); `tools/run_gdunit_unit.sh` (33 unit tests, ~65s); `tools/run_gdunit_parallel.sh` (8-process parallel runner, ~2m45s vs 4m22s baseline); deleted 3 redundant root-level audit docs. Full suite: 522 cases, 0 failures, 6 orphans.

LATEST CHANGES (2026-03-25)

    - Prompt 15 Florence meta-state: `FlorenceData` resource, `Types.DayAdvanceReason`, `SignalBus.florence_state_changed`, `GameManager` day/counter wiring, hub debug label, dialogue condition keys, and `tests/test_florence.gd` (parse-safety fixes: enum cast + type inference).

    - Prompt 13 hub dialogue (`docs/PROMPT_13_IMPLEMENTATION.md`): `DialogueManager` autoload; `DialogueEntry` / `DialogueCondition`; `res://resources/dialogue/**` pools; `dialogue_ui.tscn`; `UIManager.show_dialogue_for_character` + queue; `BetweenMissionScreen` hub lines for Sybil + Arnulf; `test_dialogue_manager.gd` + `run_gdunit_quick.sh` allowlist.

    - Prompt 12 mercenary roster + offers (`docs/PROMPT_12_IMPLEMENTATION.md`): `MercenaryOfferData`, `MercenaryCatalog`, `MiniBossData`, `res://resources/mercenary_catalog.tres` + offers; `CampaignManager` purchase/preview/defection/auto-select; `SignalBus` mercenary + roster signals; `BetweenMissionScreen` Mercenaries tab; `SimBot` strategy + `decide_mercenaries`; GdUnit suites in `run_gdunit_quick.sh` allowlist; `GameManager._transition_to` idempotent for same state.

LATEST CHANGES (2026-03-24)

    - Prompt 10 fixes (`docs/PROMPT_10_FIXES.md`): WaveManager `get_node_or_null` for EnemyContainer/SpawnPoints; `test_wave_manager` / `test_boss_waves` add SpawnPoints to tree before Marker3D `global_position`; `WeaponLevelData` `.tres` `script_class` header; `test_campaign_manager` GdUnit `assert_that().is_not_null()`; `GameManager` `push_warning` + `mission_won` hub (`project.godot` CampaignManager before GameManager); `docs/PROBLEM_REPORT.md` for errors/snippets.
- Prompt 10 mini-boss + campaign boss (`docs/PROMPT_10_IMPLEMENTATION.md`):
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

- Prompt 9 factions + weighted waves (`docs/PROMPT_9_IMPLEMENTATION.md`):
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
- Implementation notes recorded in `docs/PROMPT_1_IMPLEMENTATION.md`.
- Phase 2 firing changes added:
  - `WeaponData` now includes assist/miss tuning fields (all default to `0.0`).
  - `Tower` manual shots now pass through private aim helper for cone assist + miss perturbation.
  - `crossbow.tres` has initial tuning defaults (`7.5`, `0.05`, `2.0`), `rapid_missile.tres` remains `0.0`.
  - Added simulation API tests covering assist, miss, and autofire bypass behavior.
- Implementation notes recorded in `docs/PROMPT_2_IMPLEMENTATION.md`.
- Phase 3 weapon-upgrade system added:
  - `WeaponLevelData` resource class (`res://scripts/resources/weapon_level_data.gd`)
  - `WeaponUpgradeManager` scene-bound manager (`/root/Main/Managers/WeaponUpgradeManager`)
  - New level resources in `res://resources/weapon_level_data/` (crossbow + rapid missile, levels 1-3)
  - `SignalBus.weapon_upgraded(weapon_slot, new_level)`
  - `BetweenMissionScreen` now includes a Weapons tab with upgrade controls
  - `Tower` now resolves effective damage/speed/reload/burst via manager with null-guard fallback
  - `docs/PROMPT_3_IMPLEMENTATION.md` records implementation details
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
