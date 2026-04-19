# tests/test_chronicle_manager.gd — Chronicle meta-progression autoload.

class_name TestChronicleManager
extends GdUnitTestSuite


func before_test() -> void:
	var d: DirAccess = DirAccess.open("user://")
	if d != null and d.file_exists("chronicle.json"):
		d.remove("chronicle.json")
	ChronicleManager.reset_for_test()


func test_entries_loaded() -> void:
	assert_bool(ChronicleManager._entries.is_empty()).is_false()


func test_perks_loaded() -> void:
	assert_bool(ChronicleManager._perks.is_empty()).is_false()


func test_increment_counter() -> void:
	SignalBus.enemy_killed.emit(Types.EnemyType.ORC_GRUNT, Vector3.ZERO, 10)
	var st: Dictionary = ChronicleManager.get_entry_state("entry_combat_first_blood")
	assert_int(int(st.get("progress", 0))).is_equal(1)


func test_completion_fires_signal() -> void:
	monitor_signals(SignalBus, false)
	SignalBus.enemy_killed.emit(Types.EnemyType.ORC_GRUNT, Vector3.ZERO, 10)
	await assert_signal(SignalBus).is_emitted("chronicle_entry_completed", ["entry_combat_first_blood"])


func test_perk_activation() -> void:
	SignalBus.enemy_killed.emit(Types.EnemyType.ORC_GRUNT, Vector3.ZERO, 10)
	assert_bool(ChronicleManager._active_perks.has("perk_starting_gold_50")).is_true()


func test_apply_perks_no_crash_when_empty() -> void:
	ChronicleManager.reset_for_test()
	ChronicleManager.apply_perks_at_mission_start()


func test_save_progress_creates_file() -> void:
	ChronicleManager.save_progress()
	assert_bool(FileAccess.file_exists("user://chronicle.json")).is_true()


func test_load_progress_restores_counters() -> void:
	var st: Dictionary = ChronicleManager._entries["entry_combat_first_blood"] as Dictionary
	st["progress"] = 7
	st["completed"] = false
	ChronicleManager._entries["entry_combat_first_blood"] = st
	ChronicleManager.save_progress()
	ChronicleManager.reset_for_test()
	ChronicleManager.load_progress()
	var st2: Dictionary = ChronicleManager.get_entry_state("entry_combat_first_blood")
	assert_int(int(st2.get("progress", 0))).is_equal(7)


func test_load_progress_corrupt_json_no_crash() -> void:
	var f: FileAccess = FileAccess.open("user://chronicle.json", FileAccess.WRITE)
	assert_object(f).is_not_null()
	f.store_string("not json {{{")
	f.close()
	ChronicleManager.load_progress()


func test_reset_for_test_clears_all() -> void:
	SignalBus.enemy_killed.emit(Types.EnemyType.ORC_GRUNT, Vector3.ZERO, 10)
	ChronicleManager.reset_for_test()
	var st: Dictionary = ChronicleManager.get_entry_state("entry_combat_first_blood")
	assert_int(int(st.get("progress", 0))).is_equal(0)
	assert_bool(ChronicleManager._active_perks.is_empty()).is_true()


func test_entry_meta_first_run_does_not_exist() -> void:
	assert_bool(ChronicleManager._entries.has("entry_meta_first_run")).is_false()
