## AutoTestDriver — Headless smoke-test driver that activates only when the --autotest flag is present.
# autoloads/auto_test_driver.gd
# Headless integration-test driver for Foul Ward.
#
# Activation: run Godot with the custom argument --autotest after the double-dash:
#   godot.exe --path <project> --headless -- --autotest
#
# When active this autoload:
#   1. Waits for the scene tree to finish _ready().
#   2. Drives the game through a scripted sequence (start, build, wave, kills…).
#   3. Prints structured [AUTOTEST] PASS / FAIL / TIMEOUT lines to stdout.
#   4. Calls get_tree().quit() when done.
#
# When --autotest is NOT present the class does absolutely nothing.

# PRE_GENERATION_VERIFICATION: Mentally ran checklist for this file
# (CLI-only orchestration, respects existing --autotest behavior, headless-safe).

extends Node

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _pass_count: int = 0
var _fail_count: int = 0

# Cached scene references — resolved after the first process frame.
var _tower: Tower = null
var _hex_grid: HexGrid = null
var _wave_manager: WaveManager = null

# Signal-driven event flags (set in signal handlers, polled by _wait_until).
var _enemy_killed_count: int = 0
var _enemy_killed_types: Array[Types.EnemyType] = []
var _wave_started_received: bool = false
var _wave_number_started: int = 0
var _wave_cleared_received: bool = false

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	if "--simbot_balance_sweep" in OS.get_cmdline_user_args():
		call_deferred("_begin_simbot_balance_sweep")
		return

	var simbot_profile: String = _get_cli_string_arg("--simbot_profile=")
	var simbot_runs: int = _get_cli_int_arg("--simbot_runs=", 1)
	var simbot_seed: int = _get_cli_int_arg("--simbot_seed=", 0)

	if not simbot_profile.strip_edges().is_empty():
		# New Phase 2 CLI integration path.
		# DEVIATION: This autoload can now run SimBot even without --autotest.
		call_deferred("_begin_simbot_batch", simbot_profile, simbot_runs, simbot_seed)
		return

	if "--autotest" not in OS.get_cmdline_user_args():
		return  # Invisible in normal play.

	print("[AUTOTEST] ============================================================")
	print("[AUTOTEST] Foul Ward Integration AutoTest — %s" % Time.get_datetime_string_from_system())
	print("[AUTOTEST] ============================================================")

	SignalBus.enemy_killed.connect(_on_enemy_killed)
	SignalBus.wave_cleared.connect(_on_wave_cleared)
	SignalBus.wave_started.connect(_on_wave_started)

	call_deferred("_begin_tests")

func _get_cli_string_arg(prefix: String) -> String:
	var args: PackedStringArray = OS.get_cmdline_args()
	for arg: String in args:
		if arg.begins_with(prefix):
			return arg.substr(prefix.length())

	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	for arg2: String in user_args:
		if arg2.begins_with(prefix):
			return arg2.substr(prefix.length())
	return ""

func _get_cli_int_arg(prefix: String, default_value: int) -> int:
	var raw: String = _get_cli_string_arg(prefix)
	if raw.is_empty():
		return default_value
	var parsed: int = int(raw)
	return parsed if parsed > 0 else default_value

func _begin_simbot_batch(profile_id: String, runs: int, base_seed: int) -> void:
	# Give the scene tree a few frames to finish _ready() on main.tscn.
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var simbot: SimBot = _find_or_create_simbot()
	if runs == 1:
		var single_result: Dictionary = await simbot.run_single(profile_id, 0, base_seed)
		print("[SimBot] run_single: %s" % str(single_result))
	else:
		await simbot.run_batch(profile_id, runs, base_seed)
		var log: Dictionary = simbot.get_log()
		var entries: Array = log.get("entries", []) as Array
		var wins: int = 0
		var losses: int = 0
		for e: Variant in entries:
			if e is Dictionary:
				var r: String = str((e as Dictionary).get("result", ""))
				if r == "WIN":
					wins += 1
				elif r == "LOSS":
					losses += 1
		print("SimBot batch complete. Runs: %d, Wins: %d, Losses: %d" % [
			int(log.get("runs", runs)), wins, losses
		])

	get_tree().quit(0)

func _find_or_create_simbot() -> SimBot:
	var root: Node = get_tree().get_root()
	for child: Node in root.get_children():
		var sb: SimBot = child as SimBot
		if sb != null:
			return sb
	var new_sb: SimBot = SimBot.new()
	root.add_child(new_sb)
	return new_sb


func _begin_simbot_balance_sweep() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var simbot: SimBot = _find_or_create_simbot()
	await simbot.run_balance_sweep()
	print("[SimBot] balance sweep complete.")
	get_tree().quit(0)


# ---------------------------------------------------------------------------
# Signal handlers (set flags — never do logic here)
# ---------------------------------------------------------------------------

func _on_enemy_killed(enemy_type: Types.EnemyType, _pos: Vector3, gold: int) -> void:
	_enemy_killed_count += 1
	_enemy_killed_types.append(enemy_type)
	print("[AUTOTEST] event enemy_killed #%d: %s  gold_reward=%d" % [
		_enemy_killed_count, Types.EnemyType.keys()[enemy_type], gold
	])


func _on_wave_started(wave_number: int, enemy_count: int) -> void:
	print("[AUTOTEST] event wave_started: wave=%d enemies=%d" % [wave_number, enemy_count])
	_wave_started_received = true
	_wave_number_started = wave_number


func _on_wave_cleared(wave_number: int) -> void:
	print("[AUTOTEST] event wave_cleared: wave=%d" % wave_number)
	_wave_cleared_received = true


# ---------------------------------------------------------------------------
# Test orchestration
# ---------------------------------------------------------------------------

func _begin_tests() -> void:
	# Give all scene nodes three frames to finish _ready().
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	_tower = get_node_or_null("/root/Main/Tower") as Tower
	_hex_grid = get_node_or_null("/root/Main/HexGrid") as HexGrid
	_wave_manager = get_node_or_null("/root/Main/Managers/WaveManager") as WaveManager

	_check("scene: Tower node found", _tower != null)
	_check("scene: HexGrid node found", _hex_grid != null)
	_check("scene: WaveManager node found", _wave_manager != null)

	if _tower == null or _hex_grid == null or _wave_manager == null:
		print("[AUTOTEST] FATAL: critical nodes missing — cannot continue")
		_finish()
		return

	# Enable auto-fire so the tower kills enemies without simulated mouse input.
	_tower.auto_fire_enabled = true
	print("[AUTOTEST] Tower auto_fire_enabled = true")

	await _test_start_game()
	await _test_place_arrow_tower()
	await _test_place_anti_air_tower()
	await _test_slot_occupied()
	await _test_wave_starts()
	await _test_enemies_spawn()
	await _test_first_kill()
	await _test_flying_enemy_killed()
	await _test_wave_cleared()
	await _test_economy_reward()

	_finish()


# ---------------------------------------------------------------------------
# Individual tests
# ---------------------------------------------------------------------------

func _test_start_game() -> void:
	print("[AUTOTEST] --- start_new_game ---")
	var gold_before: int = EconomyManager.get_gold()
	GameManager.start_new_game()
	await get_tree().process_frame

	_check("start_new_game: state is COMBAT",
		GameManager.get_game_state() == Types.GameState.COMBAT)
	_check("start_new_game: gold > 0",
		EconomyManager.get_gold() > 0)
	print("[AUTOTEST] gold after reset: %d  mat: %d" % [
		EconomyManager.get_gold(), EconomyManager.get_building_material()
	])
	gold_before = gold_before  # suppress unused warning


func _test_place_arrow_tower() -> void:
	print("[AUTOTEST] --- place_building: Arrow Tower (slot 0) ---")
	var gold_before: int = EconomyManager.get_gold()
	var mat_before: int = EconomyManager.get_building_material()
	var ok: bool = _hex_grid.place_building(0, Types.BuildingType.ARROW_TOWER)
	await get_tree().process_frame
	_check("place_building: Arrow Tower returned true", ok)
	_check("place_building: gold decreased after Arrow Tower",
		EconomyManager.get_gold() < gold_before)
	print("[AUTOTEST] gold: %d→%d  mat: %d→%d" % [
		gold_before, EconomyManager.get_gold(), mat_before, EconomyManager.get_building_material()
	])


func _test_place_anti_air_tower() -> void:
	print("[AUTOTEST] --- place_building: Anti-Air Bolt (slot 1) ---")
	var gold_before: int = EconomyManager.get_gold()
	var ok: bool = _hex_grid.place_building(1, Types.BuildingType.ANTI_AIR_BOLT)
	await get_tree().process_frame
	if ok:
		_check("place_building: Anti-Air Bolt placed (gold decreased)",
			EconomyManager.get_gold() < gold_before)
	else:
		print("[AUTOTEST] INFO: Anti-Air Bolt not placed (likely locked or too expensive) — skipping")


func _test_slot_occupied() -> void:
	print("[AUTOTEST] --- place_building on already-occupied slot 0 ---")
	var ok: bool = _hex_grid.place_building(0, Types.BuildingType.ARROW_TOWER)
	_check("slot_occupied: place_building returns false", not ok)


func _test_wave_starts() -> void:
	print("[AUTOTEST] --- wave 1 countdown + start (timeout 15 s) ---")
	var ok: bool = await _wait_until(
		func() -> bool: return _wave_started_received,
		15.0, "wave_started signal"
	)
	_check("wave_started: fires within 15 s", ok)
	if ok:
		_check("wave_started: wave number is 1", _wave_number_started == 1)


func _test_enemies_spawn() -> void:
	print("[AUTOTEST] --- enemies in scene after wave start ---")
	# Give spawner a moment to add all enemy nodes.
	await get_tree().create_timer(0.5).timeout
	var count: int = _wave_manager.get_living_enemy_count()
	_check("enemies_spawn: at least 1 enemy alive", count > 0)
	print("[AUTOTEST] living enemies after spawn: %d" % count)


func _test_first_kill() -> void:
	print("[AUTOTEST] --- first enemy kill via auto-fire (timeout 60 s) ---")
	var kills_before: int = _enemy_killed_count
	var ok: bool = await _wait_until(
		func() -> bool: return _enemy_killed_count > kills_before,
		60.0, "first enemy kill"
	)
	_check("first_kill: auto-fire kills at least one enemy within 60 s", ok)
	if ok:
		print("[AUTOTEST] first kill confirmed, total kills: %d" % _enemy_killed_count)


func _test_flying_enemy_killed() -> void:
	print("[AUTOTEST] --- Bat Swarm (flying) killed (timeout 120 s) ---")
	var ok: bool = await _wait_until(
		func() -> bool: return Types.EnemyType.BAT_SWARM in _enemy_killed_types,
		120.0, "Bat Swarm killed"
	)
	_check("flying_enemy_killed: Bat Swarm dies within 120 s", ok)


func _test_wave_cleared() -> void:
	print("[AUTOTEST] --- wave_cleared signal (timeout 180 s) ---")
	var ok: bool = await _wait_until(
		func() -> bool: return _wave_cleared_received,
		180.0, "wave_cleared signal"
	)
	_check("wave_cleared: all enemies dead, signal received", ok)
	if ok:
		_check("wave_cleared: no enemies remain in group",
			_wave_manager.get_living_enemy_count() == 0)


func _test_economy_reward() -> void:
	print("[AUTOTEST] --- economy reward after kills ---")
	var gold: int = EconomyManager.get_gold()
	_check("economy: gold > 0 after kills", gold > 0)
	print("[AUTOTEST] final gold: %d  final kills: %d" % [gold, _enemy_killed_count])


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _check(label: String, condition: bool) -> void:
	if condition:
		_pass_count += 1
		print("[AUTOTEST] PASS: %s" % label)
	else:
		_fail_count += 1
		print("[AUTOTEST] FAIL: %s" % label)


## Polls [param condition] every 0.25 s until it returns true or [param timeout] elapses.
## Returns true if condition became true in time.
func _wait_until(condition: Callable, timeout: float, label: String) -> bool:
	var elapsed: float = 0.0
	while elapsed < timeout:
		if condition.call():
			return true
		await get_tree().create_timer(0.25).timeout
		elapsed += 0.25
	print("[AUTOTEST] TIMEOUT: '%s' did not occur within %.0f s" % [label, timeout])
	return false


func _finish() -> void:
	print("[AUTOTEST] ============================================================")
	print("[AUTOTEST] RESULTS  PASS: %d   FAIL: %d" % [_pass_count, _fail_count])
	print("[AUTOTEST] ============================================================")
	get_tree().quit(0 if _fail_count == 0 else 1)
