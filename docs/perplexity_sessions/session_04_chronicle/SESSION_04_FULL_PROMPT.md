PROMPT:

# Session 4: Chronicle Meta-Progression System

## Goal
Design the Chronicle of Foul Ward — a cross-run meta-progression system. The master doc confirms it is designed but not yet implemented. This session produces the complete implementation spec: resources, achievement triggers, perk effects, UI, and save integration.

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `florence_data.gd` — FlorenceData resource; protagonist meta-state (run counters, boss attempts, unlock flags)
- `signal_bus.gd` — Central signal hub; lines 90-150 covering game state, campaign, and build mode signals
- `save_manager.gd` — SaveManager autoload; lines 1-60 covering save payload structure
- `types.gd` — Types.gd; lines 1-30 covering enum patterns

## Context Brief
Later in this document, under the heading **`CONTEXT_BRIEF:`**, you will find the relevant excerpts from the project's master documentation. Read that block fully before proceeding.

## Constraints
- Godot 4.4, GDScript primary, C# for performance-critical paths only
- All signals go through SignalBus (autoloads/signal_bus.gd) — never direct connections between managers
- Enums live in types.gd with integer values — C# mirror in FoulWardTypes.cs must stay aligned
- No class_name on autoloads
- Tests use GdUnit4 framework
- See the **CONTEXT_BRIEF:** section in this document for full conventions

## Task
Produce an implementation spec for: the Chronicle meta-progression system.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

DESIGN DECISION: Chronicle perks should be cosmetic micro-buffs (not meaningful power advantages). Examples: +2% gold per kill (flavor), +5 starting mana, unique building skins unlocked.

REQUIREMENTS:
1. Define ChronicleData resource class: chronicle_id (String), entries (Array[ChronicleEntryData]), total_xp (int), current_rank (int).
2. Define ChronicleEntryData resource class: entry_id (String), display_name (String), description (String), trigger_signal (String — SignalBus signal name), trigger_condition (Dictionary — e.g., {"count": 10}), reward_type (String — "perk", "cosmetic", "title"), reward_id (String), is_completed (bool).
3. Define ChroniclePerkData resource class: perk_id (String), display_name (String), description (String), effect_type (String), effect_value (float), is_active (bool).
4. Design 15-20 achievements spanning: combat (kill N enemies), campaign (reach day 25, day 50), bosses (defeat each mini-boss), economy (earn N gold total), building (place N buildings), and meta (complete N runs).
5. Design 8-10 perks as rewards: starting gold +50, starting mana +5, sell refund +2%, research cost -5%, etc. All intentionally small.
6. Chronicle persists across runs in a separate save file: user://chronicle.json (not in the per-attempt save slots).
7. Design the UI: accessible from MAIN_MENU as a "Chronicle" button. Shows achievement list with progress bars and perk unlock status.
8. Integration: a new autoload ChronicleManager listens to SignalBus signals and tracks achievement progress. Perk effects are applied at mission start via existing manager APIs.
9. Define all SignalBus signal connections and the exact listener pattern.
10. Do NOT implement a full XP/leveling system — just achievement -> perk unlocks.

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.

CONTEXT_BRIEF:

# Context Brief — Session 4: Chronicle

## Meta-Progression: The Chronicle of Foul Ward (§14)

DOES NOT EXIST IN CODE. CONFIRMED ADDED TO DESIGN. Must be implemented.

See implementation spec: ChronicleData, ChroniclePerkData, achievement triggers via SignalBus.

## Signal Bus Reference — Game State + Campaign Signals (§24)

### Game State
| Signal | Parameters |
|--------|-----------|
| game_state_changed | old_state: Types.GameState, new_state: Types.GameState |
| mission_started | mission_number: int |
| mission_won | mission_number: int |
| mission_failed | mission_number: int |
| florence_state_changed | (none) |

### Campaign
| Signal | Parameters |
|--------|-----------|
| campaign_started | campaign_id: String |
| day_started | day_index: int |
| day_won | day_index: int |
| day_failed | day_index: int |
| campaign_completed | campaign_id: String |

### Combat (relevant for kill-count achievements)
| Signal | Parameters |
|--------|-----------|
| enemy_killed | enemy_type: Types.EnemyType, position: Vector3, gold_reward: int |
| boss_killed | boss_id: String |

### Buildings (relevant for building-count achievements)
| Signal | Parameters |
|--------|-----------|
| building_placed | slot_index: int, building_type: Types.BuildingType |

### Economy
| Signal | Parameters |
|--------|-----------|
| resource_changed | resource_type: Types.ResourceType, new_amount: int |

## How to Add a New Signal (§28.2)

1. Declare in autoloads/signal_bus.gd with typed parameters.
2. Add @warning_ignore("unused_signal") above the declaration.
3. Use past tense for events (achievement_completed), present for requests.
4. Emit from the relevant system using SignalBus.signal_name.emit(...).
5. Connect in listeners using is_connected guard pattern.
6. Update FoulWardTypes.cs if a new enum is involved.

## Open TBD — Chronicle (§33)
| Item | Question | Who Decides |
|------|----------|-------------|
| Chronicle perk strength | Cosmetic micro-buffs vs meaningful advantage? | Designer/playtester |

Decision for this session: Cosmetic micro-buffs only.

## SaveManager Structure (§3.13)

Save payload is a Dictionary with top-level keys:
- "version", "attempt_id", "campaign", "game", "relationship", "research", "shop", "enchantments"

Chronicle saves separately to user://chronicle.json (cross-run persistence).

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus
- is_instance_valid() before accessing enemies, projectiles, or allies
- push_warning() not assert() in production
- AllyRole enum: MELEE_FRONTLINE=0, RANGED_SUPPORT=1, ANTI_AIR=2, SPELL_SUPPORT=3 (TANK was removed)

FILES:

# Files to Upload for Session 4: Chronicle

**Errata (single-file bundle):** The standalone file `FILES_TO_UPLOAD.md` is **not** attached for Perplexity. This manifest exists for repo maintainers; for Perplexity, its entire contents (this list and the full text of every path below) are merged into `SESSION_04_FULL_PROMPT.md` in this folder.

Listed repository paths:

1. `scripts/florence_data.gd` — FlorenceData resource; protagonist meta-state with run counters and unlock flags (full file, ~80 lines estimated)
2. `autoloads/signal_bus.gd` — Central signal hub; lines 90-150 covering game state, campaign, and build mode signals (~60 lines)
3. `autoloads/save_manager.gd` — SaveManager autoload; lines 1-60 covering save payload structure (~60 lines)
4. `scripts/types.gd` — Types.gd; lines 1-30 covering enum patterns (~30 lines)

Total estimated token load: ~230 lines across 4 files

scripts/florence_data.gd:
## florence_data.gd
## FlorenceData — data-only resource storing Florence meta-state for a single run.
## No Node references; safe to use in headless GdUnit tests.
##
## SOURCE: Roguelike meta-progression design pattern (Hades meta-state approach).
## Pattern: keep run/campaign meta-state in a dedicated Resource owned by managers.

class_name FlorenceData
extends Resource

## Technical label for the meta-state namespace used by dialogue conditions.
@export var florence_id: String = "florence"

## Display name for UI/placeholder debug text.
@export var display_name: String = "Florence"

## Total days advanced in the current run (meta progression, not world time).
## ASSUMPTION: This tracks days in the current run; cross-run tracking can be added later.
@export var total_days_played: int = 0

## Number of full campaign completions (run counter).
## ASSUMPTION: Increment on full campaign completion (`GAME_WON`), not on new game start.
@export var run_count: int = 0

## Total missions resolved (win or failure) in the current run.
## Increments once per mission resolution.
@export var total_missions_played: int = 0

## How many boss encounter attempts happened in the current run.
@export var boss_attempts: int = 0

## How many boss encounter victories happened in the current run.
@export var boss_victories: int = 0

## How many missions failed in the current run.
@export var mission_failures: int = 0

## Flags — technical progression toggles.
@export var has_unlocked_research: bool = false
## POST-MVP: Enchantments unlock hook.
@export var has_unlocked_enchantments: bool = false
## POST-MVP: Mercenary recruitment hook.
@export var has_recruited_any_mercenary: bool = false
## POST-MVP: Mini-boss seen hook.
@export var has_seen_any_mini_boss: bool = false
## POST-MVP: Mini-boss defeated hook.
@export var has_defeated_any_mini_boss: bool = false
## TUNING: Day 25 milestone.
@export var has_reached_day_25: bool = false
## TUNING: Day 50 milestone.
@export var has_reached_day_50: bool = false
## POST-MVP: First boss seen hook.
@export var has_seen_first_boss: bool = false

const TUNING_DAY_25: int = 25
const TUNING_DAY_50: int = 50

## Resets all per-run counters and flags to their initial values.
func reset_for_new_run() -> void:
	# FlorenceData represents run meta-state, so we reset run-scoped counters/flags.
	total_days_played = 0
	total_missions_played = 0
	boss_attempts = 0
	boss_victories = 0
	mission_failures = 0

	has_unlocked_research = false
	has_unlocked_enchantments = false
	has_recruited_any_mercenary = false
	has_seen_any_mini_boss = false
	has_defeated_any_mini_boss = false
	has_reached_day_25 = false
	has_reached_day_50 = false
	has_seen_first_boss = false
	# Note: run_count intentionally persists across runs (GameManager increments on GAME_WON).


## Updates day-threshold boolean flags (early/mid/late game) based on current_day.
func update_day_threshold_flags(current_day: int) -> void:
	# TUNING: Flags reflect whether the meta campaign timeline has reached milestones.
	has_reached_day_25 = current_day >= TUNING_DAY_25
	has_reached_day_50 = current_day >= TUNING_DAY_50


autoloads/signal_bus.gd:
## signal_bus.gd
## Central signal registry for all cross-system communication in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

extends Node

# === COMBAT ===
@warning_ignore("unused_signal")
signal enemy_killed(enemy_type: Types.EnemyType, position: Vector3, gold_reward: int)
## Emitted once per enemy the first time it deals damage to the central tower (leak / reach metric).
@warning_ignore("unused_signal")
signal enemy_reached_tower(enemy_type: Types.EnemyType, damage: int)
@warning_ignore("unused_signal")
signal tower_damaged(current_hp: int, max_hp: int)
@warning_ignore("unused_signal")
signal tower_destroyed()
@warning_ignore("unused_signal")
signal projectile_fired(weapon_slot: Types.WeaponSlot, origin: Vector3, target: Vector3)
@warning_ignore("unused_signal")
signal arnulf_state_changed(new_state: Types.ArnulfState)
@warning_ignore("unused_signal")
signal arnulf_incapacitated()
@warning_ignore("unused_signal")
signal arnulf_recovered()

# === ALLIES ===
## Second arg is empty for roster allies (e.g. Arnulf); set for summoner-tower allies.
@warning_ignore("unused_signal")
signal ally_spawned(ally_id: String, building_instance_id: String)
## Emitted when a summoner ally dies (permanent death, not downed).
@warning_ignore("unused_signal")
signal ally_died(ally_id: String, building_instance_id: String)
## Emitted when the last living ally for a summoner building is removed.
@warning_ignore("unused_signal")
signal ally_squad_wiped(building_instance_id: String)
@warning_ignore("unused_signal")
signal ally_downed(ally_id: String)
@warning_ignore("unused_signal")
signal ally_recovered(ally_id: String)
@warning_ignore("unused_signal")
signal ally_killed(ally_id: String)
## POST-MVP: not yet emitted. Will be emitted from AllyBase._transition_state() when ally state tracking is implemented.
@warning_ignore("unused_signal")
signal ally_state_changed(ally_id: String, new_state: String)

# === BOSSES (Prompt 10) ===
@warning_ignore("unused_signal")
signal boss_spawned(boss_id: String)
@warning_ignore("unused_signal")
signal boss_killed(boss_id: String)
@warning_ignore("unused_signal")
signal campaign_boss_attempted(day_index: int, success: bool)

# === WAVES ===
@warning_ignore("unused_signal")
signal wave_countdown_started(wave_number: int, seconds_remaining: float)
@warning_ignore("unused_signal")
signal wave_started(wave_number: int, enemy_count: int)
## Emitted once per enemy spawned into the mission (Prompt 49 / WaveManager; Prompt 9: type + XZ position).
@warning_ignore("unused_signal")
signal enemy_spawned(enemy_type: Types.EnemyType, position: Vector2)
## Emitted when an enemy with [code]charge[/code] special first crosses its enrage HP threshold.
@warning_ignore("unused_signal")
signal enemy_enraged(enemy_instance_id: String)
@warning_ignore("unused_signal")
signal wave_cleared(wave_number: int)
@warning_ignore("unused_signal")
signal all_waves_cleared()

# === ECONOMY ===
@warning_ignore("unused_signal")
signal resource_changed(resource_type: Types.ResourceType, new_amount: int)

# === TERRITORIES / WORLD MAP ===
@warning_ignore("unused_signal")
signal territory_state_changed(territory_id: String)
@warning_ignore("unused_signal")
signal world_map_updated()

# === TERRAIN (battlefield zones, navmesh) ===
@warning_ignore("unused_signal")
signal enemy_entered_terrain_zone(enemy: Node, speed_multiplier: float)
@warning_ignore("unused_signal")
signal enemy_exited_terrain_zone(enemy: Node, speed_multiplier: float)
## POST-MVP: not yet emitted. Reserved for destructible terrain props.
@warning_ignore("unused_signal")
signal terrain_prop_destroyed(prop: Node, world_position: Vector3)
## POST-MVP: connected in NavMeshManager but never emitted. Will be emitted from terrain/build flows.
@warning_ignore("unused_signal")
signal nav_mesh_rebake_requested()

# === BUILDINGS ===
@warning_ignore("unused_signal")
signal building_placed(slot_index: int, building_type: Types.BuildingType)
@warning_ignore("unused_signal")
signal building_sold(slot_index: int, building_type: Types.BuildingType)
@warning_ignore("unused_signal")
signal building_upgraded(slot_index: int, building_type: Types.BuildingType)
## Building projectile / aura attribution for CombatStatsTracker (placed_instance_id string).
@warning_ignore("unused_signal")
signal building_dealt_damage(instance_id: String, damage: float, enemy_id: String)
## POST-MVP: connected in CombatStatsTracker but not yet emitted from game code. EnemyBase attack flow should emit this.
@warning_ignore("unused_signal")
signal florence_damaged(amount: int, source_enemy_id: String)
## POST-MVP: not yet emitted. Requires building HP/destruction system.
@warning_ignore("unused_signal")
signal building_destroyed(slot_index: int)

# === SPELLS ===
@warning_ignore("unused_signal")
signal spell_cast(spell_id: String)
@warning_ignore("unused_signal")
signal spell_ready(spell_id: String)
@warning_ignore("unused_signal")
signal mana_changed(current_mana: int, max_mana: int)

# === GAME STATE ===
@warning_ignore("unused_signal")
signal game_state_changed(old_state: Types.GameState, new_state: Types.GameState)
@warning_ignore("unused_signal")
signal mission_started(mission_number: int)
@warning_ignore("unused_signal")
signal mission_won(mission_number: int)
@warning_ignore("unused_signal")
signal mission_failed(mission_number: int)

# Florence / campaign meta-state.
@warning_ignore("unused_signal")
signal florence_state_changed()

# Campaign / day-level signals.
# mission_* signals remain mission-level; in the current short campaign they
# correspond 1:1 to days (one mission per day). CampaignManager wraps them.
@warning_ignore("unused_signal")
signal campaign_started(campaign_id: String)
@warning_ignore("unused_signal")
signal day_started(day_index: int)
@warning_ignore("unused_signal")
signal day_won(day_index: int)
@warning_ignore("unused_signal")
signal day_failed(day_index: int)
@warning_ignore("unused_signal")
signal campaign_completed(campaign_id: String)

# === DIALOGUE ===
@warning_ignore("unused_signal")
signal dialogue_line_started(entry_id: String, character_id: String)
@warning_ignore("unused_signal")
signal dialogue_line_finished(entry_id: String, character_id: String)

# === BUILD MODE ===
@warning_ignore("unused_signal")
signal build_mode_entered()
@warning_ignore("unused_signal")
signal build_mode_exited()
## Emitted when [member BuildPhaseManager.is_build_phase] becomes true (mission build phase / build mode).
@warning_ignore("unused_signal")
signal build_phase_started()
## Emitted when [member BuildPhaseManager.is_build_phase] becomes false (combat / waves).
@warning_ignore("unused_signal")
signal combat_phase_started()

# === RESEARCH ===
@warning_ignore("unused_signal")
signal research_unlocked(node_id: String)
## Prompt 11: alias event for research UI; mirrors [signal research_unlocked].
@warning_ignore("unused_signal")
signal research_node_unlocked(node_id: String)
## Prompt 11: current research material (RP) for in-mission research panel.
@warning_ignore("unused_signal")
signal research_points_changed(points: int)

# === SHOP ===
@warning_ignore("unused_signal")
signal shop_item_purchased(item_id: String)
## Emitted by ShopManager when a mana draught has been consumed by GameManager at mission start.
@warning_ignore("unused_signal")
signal mana_draught_consumed()

# === WEAPONS ===
@warning_ignore("unused_signal")
signal weapon_upgraded(weapon_slot: Types.WeaponSlot, new_level: int)

# === ENCHANTMENTS ===
@warning_ignore("unused_signal")
signal enchantment_applied(weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String)
@warning_ignore("unused_signal")
signal enchantment_removed(weapon_slot: Types.WeaponSlot, slot_type: String)

# === CAMPAIGN / ALLY ROSTER (Prompt 12) ===
@warning_ignore("unused_signal")
signal mercenary_offer_generated(ally_id: String)
@warning_ignore("unused_signal")
signal mercenary_recruited(ally_id: String)
@warning_ignore("unused_signal")
signal ally_roster_changed()

autoloads/save_manager.gd:
## SaveManager — rolling autosaves per campaign/endless attempt (AUDIT 6 §3.5).
## Paths: user://saves/attempt_{attempt_id}/slot_{0..4}.json — slot 0 is most recent.
## Autoload singleton only (no class_name — avoids hiding the autoload).

extends Node

const MAX_SLOTS: int = 5
const SAVES_ROOT: String = "user://saves"

var current_attempt_id: String = ""


func _ready() -> void:
	_ensure_saves_root()


func _ensure_saves_root() -> void:
	if DirAccess.open(SAVES_ROOT) == null:
		DirAccess.make_dir_recursive_absolute(SAVES_ROOT)


func _sanitize_attempt_id(raw: String) -> String:
	return raw.replace(":", "-").replace("/", "-").replace("\\", "-")


func _attempt_dir_path() -> String:
	return "%s/attempt_%s" % [SAVES_ROOT, current_attempt_id]


func _slot_file_name(slot_index: int) -> String:
	return "slot_%d.json" % slot_index


func _slot_path(slot_index: int) -> String:
	return "%s/%s" % [_attempt_dir_path(), _slot_file_name(slot_index)]


## Initializes a new save attempt directory and resets the slot ring.
func start_new_attempt() -> void:
	var raw: String = Time.get_datetime_string_from_system()
	current_attempt_id = _sanitize_attempt_id(raw)
	_ensure_saves_root()
	var attempt_dir: String = _attempt_dir_path()
	if DirAccess.open(attempt_dir) == null:
		DirAccess.make_dir_recursive_absolute(attempt_dir)
	else:
		_clear_attempt_slots(attempt_dir)


func _clear_attempt_slots(attempt_dir: String) -> void:
	var dir: DirAccess = DirAccess.open(attempt_dir)
	if dir == null:
		return
	for i: int in range(MAX_SLOTS):
		var fn: String = _slot_file_name(i)
		if dir.file_exists(fn):
			dir.remove(fn)


## Collects state from all managers and writes a new save slot JSON file.
func save_current_state() -> void:
	if current_attempt_id.is_empty():
		push_warning("SaveManager.save_current_state: current_attempt_id is empty; call start_new_attempt() first.")
		return
	_ensure_saves_root()
	var attempt_dir: String = _attempt_dir_path()
	if DirAccess.open(attempt_dir) == null:
		DirAccess.make_dir_recursive_absolute(attempt_dir)
	_shift_slots(attempt_dir)
	var payload: Dictionary = _build_save_payload()
	var json_text: String = JSON.stringify(payload)
	var path: String = "%s/%s" % [attempt_dir, _slot_file_name(0)]
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: failed to write %s" % path)
		return
	f.store_string(json_text)
	f.close()


func _shift_slots(attempt_dir: String) -> void:
	var dir: DirAccess = DirAccess.open(attempt_dir)
	if dir == null:
		return
	var last: int = MAX_SLOTS - 1
	var last_fn: String = _slot_file_name(last)
	if dir.file_exists(last_fn):
		dir.remove(last_fn)
	for i: int in range(last - 1, -1, -1):
		var fn: String = _slot_file_name(i)
		if dir.file_exists(fn):
			var err: Error = dir.rename(fn, _slot_file_name(i + 1))
			if err != OK:
				push_error("SaveManager._shift_slots: rename failed %s" % str(err))


func _build_save_payload() -> Dictionary:
	return {
		"version": 1,
		"attempt_id": current_attempt_id,
		"campaign": CampaignManager.get_save_data(),
		"game": GameManager.get_save_data(),
		"relationship": RelationshipManager.get_save_data(),
		"research": _get_research_save(),
		"shop": _get_shop_save(),
		"enchantments": EnchantmentManager.get_save_data(),
	}


func _get_research_save() -> Dictionary:
	var rm: ResearchManager = _get_research_manager()
	if rm == null:
		return {"unlocked_node_ids": [] as Array[String]}
	return rm.get_save_data()


func _get_shop_save() -> Dictionary:
	var sm: ShopManager = _get_shop_manager()
	if sm == null:
		return {}
	return sm.get_save_data()


func _get_research_manager() -> ResearchManager:
	return get_node_or_null("/root/Main/Managers/ResearchManager") as ResearchManager


func _get_shop_manager() -> ShopManager:
	return get_node_or_null("/root/Main/Managers/ShopManager") as ShopManager


## Restores all manager state from the save slot at the given index.
func load_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return false
	var attempt_dir: String = ""
	if current_attempt_id.is_empty():
		attempt_dir = _find_attempt_dir_with_slot(slot_index)
		if attempt_dir.is_empty():
			return false
		var folder_name: String = attempt_dir.get_file()
		current_attempt_id = folder_name.trim_prefix("attempt_")
	else:
		attempt_dir = _attempt_dir_path()
	var path: String = "%s/%s" % [attempt_dir, _slot_file_name(slot_index)]
	if not FileAccess.file_exists(path):
		return false
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager.load_slot: JSON parse error")
		return false
	var d: Dictionary = parsed as Dictionary
	var aid: Variant = d.get("attempt_id", "")
	if aid is String and not (aid as String).is_empty():
		current_attempt_id = aid as String
	_apply_save_payload(d)
	_discard_newer_slots(attempt_dir, slot_index)
	return true


func _find_attempt_dir_with_slot(slot_index: int) -> String:
	var root: DirAccess = DirAccess.open(SAVES_ROOT)
	if root == null:
		return ""
	var best_dir: String = ""
	var best_mtime: int = 0
	root.list_dir_begin()
	var entry: String = root.get_next()
	while entry != "":
		if root.current_is_dir() and entry.begins_with("attempt_"):
			var sub: String = "%s/%s" % [SAVES_ROOT, entry]
			var sp: String = "%s/%s" % [sub, _slot_file_name(slot_index)]
			if FileAccess.file_exists(sp):
				var mt: int = FileAccess.get_modified_time(sp)
				if mt >= best_mtime:
					best_mtime = mt
					best_dir = sub
		entry = root.get_next()
	root.list_dir_end()
	return best_dir


func _apply_save_payload(d: Dictionary) -> void:
	var camp: Variant = d.get("campaign", {})
	if camp is Dictionary:
		CampaignManager.restore_from_save(camp as Dictionary)
	var game: Variant = d.get("game", {})
	if game is Dictionary:
		GameManager.restore_from_save(game as Dictionary)
	var rel: Variant = d.get("relationship", {})
	if rel is Dictionary:
		RelationshipManager.restore_from_save(rel as Dictionary)
	var res: Variant = d.get("research", {})
	if res is Dictionary:
		var rm: ResearchManager = _get_research_manager()
		if rm != null:
			rm.restore_from_save(res as Dictionary)
	var shop: Variant = d.get("shop", {})
	if shop is Dictionary:
		var sm: ShopManager = _get_shop_manager()
		if sm != null:
			sm.restore_from_save(shop as Dictionary)
	var ench: Variant = d.get("enchantments", {})
	if ench is Dictionary:
		EnchantmentManager.restore_from_save(ench as Dictionary)


func _discard_newer_slots(attempt_dir: String, loaded_slot_index: int) -> void:
	var dir: DirAccess = DirAccess.open(attempt_dir)
	if dir == null:
		return
	for i: int in range(0, loaded_slot_index):
		var fn: String = _slot_file_name(i)
		if dir.file_exists(fn):
			dir.remove(fn)


## Returns the list of slot indices that have saved data in the current attempt.
func get_available_slots() -> Array[int]:
	var result: Array[int] = []
	if current_attempt_id.is_empty():
		return result
	var attempt_dir: String = _attempt_dir_path()
	var dir: DirAccess = DirAccess.open(attempt_dir)
	if dir == null:
		return result
	for i: int in range(MAX_SLOTS):
		if dir.file_exists(_slot_file_name(i)):
			result.append(i)
	return result


## Returns true if at least one save slot exists in the current attempt directory.
func has_resumable_attempt() -> bool:
	_ensure_saves_root()
	var root: DirAccess = DirAccess.open(SAVES_ROOT)
	if root == null:
		return false
	root.list_dir_begin()
	var entry: String = root.get_next()
	while entry != "":
		if root.current_is_dir() and entry.begins_with("attempt_"):
			var sub: String = "%s/%s" % [SAVES_ROOT, entry]
			var dir2: DirAccess = DirAccess.open(sub)
			if dir2 != null:
				for i: int in range(MAX_SLOTS):
					if dir2.file_exists(_slot_file_name(i)):
						root.list_dir_end()
						return true
		entry = root.get_next()
	root.list_dir_end()
	return false


## Test helper: removes all attempt_* folders under user://saves (headless tests only).
func clear_all_saves_for_test() -> void:
	var root: DirAccess = DirAccess.open(SAVES_ROOT)
	if root == null:
		return
	var to_remove: PackedStringArray = PackedStringArray()
	root.list_dir_begin()
	var entry: String = root.get_next()
	while entry != "":
		if root.current_is_dir() and entry.begins_with("attempt_"):
			to_remove.append(entry)
		entry = root.get_next()
	root.list_dir_end()
	for name: String in to_remove:
		var sub: String = "%s/%s" % [SAVES_ROOT, name]
		var inner: DirAccess = DirAccess.open(sub)
		if inner != null:
			for i: int in range(MAX_SLOTS):
				var fn: String = _slot_file_name(i)
				if inner.file_exists(fn):
					inner.remove(fn)
		var rr: DirAccess = DirAccess.open(SAVES_ROOT)
		if rr != null:
			rr.remove(name)

scripts/types.gd:
## types.gd
## Global enums and constants for FOUL WARD. Accessed via Types.GameState, Types.DamageType, etc.
## Simulation API: all public methods callable without UI nodes present.

class_name Types

enum GameState {
	MAIN_MENU,
	MISSION_BRIEFING,
	COMBAT,
	BUILD_MODE,
	WAVE_COUNTDOWN,
	BETWEEN_MISSIONS,
	MISSION_WON,
	MISSION_FAILED,
	GAME_WON,
	## Terminal failure / game over (SimBot, meta-flow); distinct from per-mission MISSION_FAILED.
	GAME_OVER,
	## Between-mission hub while in Endless Run (same UI as BETWEEN_MISSIONS; no campaign cap).
	ENDLESS,
}

enum DamageType {
	PHYSICAL,
	FIRE,
	MAGICAL,
	POISON,
	## Ignores armor flat / shield ordering in [method EnemyBase.receive_damage] (Prompt 49).
	TRUE,
}

enum ArmorType {
	UNARMORED,
	HEAVY_ARMOR,
	UNDEAD,
	FLYING,
}

enum BuildingType {
	ARROW_TOWER,
	FIRE_BRAZIER,
	MAGIC_OBELISK,
	POISON_VAT,
	BALLISTA,
	ARCHER_BARRACKS,
	ANTI_AIR_BOLT,
	SHIELD_GENERATOR,
	# ─── SMALL TOWERS (indices 8–19) ───
	SPIKE_SPITTER, # 8   SMALL, PHYSICAL, ground
	EMBER_VENT, # 9   SMALL, FIRE, ground, DoT
	FROST_PINGER, # 10  SMALL, MAGICAL, ground, slow
	NETGUN, # 11  SMALL, PHYSICAL, ground, stop-on-hit
	ACID_DRIPPER, # 12  SMALL, POISON, ground, DoT
	WOLFDEN, # 13  SMALL, SUMMONER, 2 wolf summons
	CROW_ROOST, # 14  SMALL, AA, flying
	ALARM_TOTEMS, # 15  SMALL, AURA, speed debuff aura on enemies
	CROSSFIRE_NEST, # 16  SMALL, PHYSICAL, targets air+ground
	BOLT_SHRINE, # 17  SMALL, MAGICAL, area pulse every 3s
	THORNWALL, # 18  SMALL, PHYSICAL, passive damage to melee attackers
	FIELD_MEDIC, # 19  SMALL, HEALER, heals allies in radius
	# ─── MEDIUM TOWERS (indices 20–29) ───
	GREATBOW_TURRET, # 20  MEDIUM, PHYSICAL, high range
	MOLTEN_CASTER, # 21  MEDIUM, FIRE, splash AoE
	ARCANE_LENS, # 22  MEDIUM, MAGICAL, chains to 2 targets
	PLAGUE_MORTAR, # 23  MEDIUM, POISON, lobs to random ground pos
	BEAR_DEN, # 24  MEDIUM, SUMMONER, 1 bear + 1 wolf
	GUST_CANNON, # 25  MEDIUM, PHYSICAL, AA + knockback
	WARDEN_SHRINE, # 26  MEDIUM, AURA, +15% damage to all buildings in radius
	IRON_CLERIC, # 27  MEDIUM, HEALER, repairs damaged buildings
	SIEGE_BALLISTA, # 28  MEDIUM, PHYSICAL, piercing (hits up to 3 enemies)
	CHAIN_LIGHTNING, # 29  MEDIUM, MAGICAL, priority FLYING
	# ─── LARGE TOWERS (indices 30–35) ───
	FORTRESS_CANNON, # 30  LARGE, PHYSICAL, highest single-hit damage
	DRAGON_FORGE, # 31  LARGE, FIRE, wide AoE splash
	VOID_OBELISK, # 32  LARGE, MAGICAL, debuffs enemy armor on hit
	PLAGUE_CAULDRON, # 33  LARGE, POISON, persistent AoE cloud
	BARRACKS_FORTRESS, # 34  LARGE, SUMMONER, 2 knights + 2 archers
	CITADEL_AURA, # 35  LARGE, AURA, +20% damage + +10% fire rate to all buildings
}

## Modular building kit: base piece under `res://art/generated/kit/*.glb` (see FUTURE_3D_MODELS_PLAN.md §4).
enum BuildingBaseMesh {
	STONE_ROUND,
	STONE_SQUARE,
	WOOD_ROUND,
	RUINS_BASE,
}

## Modular building kit: top piece under `res://art/generated/kit/*.glb` (see FUTURE_3D_MODELS_PLAN.md §4).
enum BuildingTopMesh {
	ROOF_CONE,
	ROOF_FLAT,
	GLASS_DOME,
	FIRE_BOWL,
	POISON_TANK,
	BALLISTA_FRAME,
	EMBRASURE,
}

enum ArnulfState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	DOWNED,
	RECOVERING,
}

enum ResourceType {
	GOLD,
	BUILDING_MATERIAL,
	RESEARCH_MATERIAL,
}

enum EnemyType {
	ORC_GRUNT,
	ORC_BRUTE,
	GOBLIN_FIREBUG,
	PLAGUE_ZOMBIE,
	ORC_ARCHER,
	BAT_SWARM,
	# ─── TIER 1 FODDER (indices 6–9) ───
	ORC_SKIRMISHER, # 6   T1, fast melee, RUSH
	ORC_RATLING, # 7   T1, tiny, spawns from Brood Carrier death
	GOBLIN_RUNTS, # 8   T1, 3-pack spawn, very low HP
	HOUND, # 9   T1, fast, high-speed RUSH
	# ─── TIER 2 STANDARD (indices 10–15) ───
	ORC_RAIDER, # 10  T2, standard melee
	ORC_MARKSMAN, # 11  T2, ranged physical
	WAR_SHAMAN, # 12  T2, SUPPORT: buffs nearby orc damage +20%
	PLAGUE_SHAMAN, # 13  T2, SUPPORT: heals nearby orcs 5 HP/s
	TOTEM_CARRIER, # 14  T2, SUPPORT: HP regen aura
	HARPY_SCOUT, # 15  T2, FLYING, fast flyer
	# ─── TIER 3 ELITE (indices 16–21) ───
	ORC_SHIELDBEARER, # 16  T3, HEAVY, physical shield absorbs first 80 dmg
	ORC_BERSERKER, # 17  T3, RUSH, enrages below 50% HP (+50% speed)
	ORC_SABOTEUR, # 18  T3, disables a building for 4s on reach
	HEXBREAKER, # 19  T3, dispels one player aura on hit
	WYVERN_RIDER, # 20  T3, FLYING, ranged fire attack
	BROOD_CARRIER, # 21  T3, spawns 3 ORC_RATLING on death
	# ─── TIER 4 HEAVY (indices 22–26) ───
	TROLL, # 22  T4, HEAVY, HP regen 8/s, slow
	IRONCLAD_CRUSHER, # 23  T4, HEAVY, high armor
	ORC_OGRE, # 24  T4, HEAVY, AoE melee smash
	WAR_BOAR, # 25  T4, RUSH+HEAVY, charge dash on approach
	ORC_SKYTHROWER, # 26  T4, RANGED, anti-air javelin priority
	# ─── TIER 5 BOSS-TIER (indices 27–29) ───
	WARLORDS_GUARD, # 27  T5, mini-elite escort
	ORCISH_SPIRIT, # 28  T5, FLYING, magic immune
	PLAGUE_HERALD, # 29  T5, SUPPORT+HEAVY, combines shaman aura + troll HP
}

enum AllyClass {
	MELEE,
	RANGED,
	SUPPORT,
}

enum WeaponSlot {
	CROSSBOW,
	RAPID_MISSILE,
}

# Used by buildings and allies for target selection preferences.
# AllyBase: CLOSEST / LOWEST_HP / HIGHEST_HP / FLYING_FIRST (see AllyData.preferred_targeting).
enum TargetPriority {
	CLOSEST,
	HIGHEST_HP,
	FLYING_FIRST,
	LOWEST_HP,
}

# NEW enums for ally roles and SimBot strategy profiles (Prompt 12).
enum AllyRole {
	MELEE_FRONTLINE,
	RANGED_SUPPORT,
	ANTI_AIR,
	SPELL_SUPPORT,
}

## Combat role for [AllyData] tower-defense data (Prompt 42). Distinct from [enum AllyRole] (mercenary / SimBot legacy).
enum AllyCombatRole {
	MELEE,
	RANGED,
	HEALER,
	BOMBER,
	AURA,
}

enum StrategyProfile {
	BALANCED,
	ALLY_HEAVY_PHYSICAL,
	ANTI_AIR_FOCUS,
	SPELL_FOCUS,
	BUILDING_FOCUS,
}

## Battle terrain preset for CampaignManager terrain scene selection (see FUTURE_3D_MODELS_PLAN.md §5).
enum TerrainType {
	GRASSLAND,
	FOREST,
	SWAMP,
	RUINS,
	TUNDRA,
}

## Modifier kind for TerrainZone; IMPASSABLE is documented for NavigationObstacle3D, not Area3D zones.
enum TerrainEffect {
	NONE,
	SLOW,
	IMPASSABLE,
}

# ASSUMPTION: HubRole enum is appended to keep existing enum numeric ordering stable.
# POST-MVP: Extend with FLORENCE, CAMPAIGN_SPECIFIC, etc. narrative requires.
enum HubRole {
	SHOP,
	RESEARCH,
	ENCHANT,
	MERCENARY,
	ALLY,
	FLAVOR_ONLY,
}

# Meta-state timeline advance reasons for Florence and between-mission narratives.
# Higher priority means "more important" to keep within the same advance window.
enum DayAdvanceReason {
	MISSION_COMPLETED,
	ACHIEVEMENT_EARNED,
	MAJOR_STORY_EVENT,
}

# --- Tower defense / mission data (Prompt 34) — must appear before any methods. ---

## Footprint category for data-driven building placement (hex rings, multi-slot).
enum BuildingSizeClass {
	SINGLE_SLOT,
	DOUBLE_WIDE,
	TRIPLE_CLUSTER,
	## Ring footprint tiers (Prompt 42); orthogonal to SINGLE_SLOT / DOUBLE_WIDE slot geometry.
	SMALL,
	MEDIUM,
	LARGE,
}

## Rough unit footprint for allies / summons (balance + pathing hints).
enum UnitSize {
	SMALL,
	MEDIUM,
	LARGE,
	HUGE,
}

## High-level ally behaviour mode (runtime AI may map multiple modes to one state machine).
enum AllyAiMode {
	DEFAULT,
	HOLD_POSITION,
	AGGRESSIVE,
	ESCORT,
	FOLLOW_LEADER,
}

## Summoned unit lifetime category (buildings + allies; Prompt 42).
enum SummonLifetimeType {
	NONE,
	MORTAL,
	RECURRING,
	IMMORTAL,
}

## Aura stacking / modification style for support towers and allies (legacy / extended tuning).
enum AuraModifierKind {
	ADD_FLAT,
	ADD_PERCENT,
	MULTIPLY,
}

## Simplified aura math mode for data resources (Prompt 42): additive vs multiplicative.
enum AuraModifierOp {
	ADD,
	MULTIPLY,
}

## Broad aura channel for UI filtering and exclusive rules.
enum AuraCategory {
	OFFENSE,
	DEFENSE,
	UTILITY,
	CONTROL,
}

## Stat column modified by an aura (data-driven; gameplay interprets).
enum AuraStat {
	DAMAGE,
	FIRE_RATE,
	RANGE,
	ARMOR,
	MAGIC_RESIST,
	MOVE_SPEED,
}

## Enemy locomotion / pathing class (distinct from ArmorType). Append-only: preserve existing ordinals.
enum EnemyBodyType {
	GROUND,
	FLYING,
	HOVER,
	BOSS,
	STRUCTURE,
	LARGE_GROUND,
	SIEGE,
	ETHEREAL,
}

## Content pipeline status for mission JSON / exports.
enum MissionBalanceStatus {
	UNSET,
	DRAFT,
	REVIEW,
	SHIPPED,
}

# SOURCE: Day/week advancement priority table pattern from management/roguelite design.
# TUNING: Adjust priorities as needed.
static func get_day_advance_priority(reason: DayAdvanceReason) -> int:
	match reason:
		DayAdvanceReason.MISSION_COMPLETED:
			# Baseline: still advances time, but is superseded by higher narrative drivers.
			return 0
		DayAdvanceReason.ACHIEVEMENT_EARNED:
			return 1
		DayAdvanceReason.MAJOR_STORY_EVENT:
			return 2
		_:
			return 0

# ASSUMPTION: Types uses enums + static helpers as a shared registry across systems.


