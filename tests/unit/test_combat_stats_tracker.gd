# GdUnit4 — CombatStatsTracker CSV + wave/building rows.
extends GdUnitTestSuite


func before_test() -> void:
	EconomyManager.reset_to_defaults()


func test_register_and_flush() -> void:
	CombatStatsTracker.begin_mission("m_unit_flush", 999, 0.0)
	CombatStatsTracker.register_building(
			"tower_inst_a",
			"arrow_tower",
			"SMALL",
			1,
			3,
			50,
			0
	)
	CombatStatsTracker._on_building_dealt_damage("tower_inst_a", 12.5, "orc_1")
	CombatStatsTracker.flush_to_disk()
	var run_id: String = CombatStatsTracker._run_id
	var path: String = "user://simbot/runs/%s/building_summary.csv" % run_id
	assert_bool(FileAccess.file_exists(path)).is_true()


func test_wave_lifecycle_records_spawns_and_leak_rate() -> void:
	CombatStatsTracker.begin_mission("m_wave", 1, 0.0)
	CombatStatsTracker._on_wave_started(1, 100)
	CombatStatsTracker._on_enemy_spawned(Types.EnemyType.ORC_GRUNT, Vector2.ZERO)
	CombatStatsTracker._on_enemy_spawned(Types.EnemyType.ORC_GRUNT, Vector2.ZERO)
	CombatStatsTracker._on_enemy_spawned(Types.EnemyType.ORC_GRUNT, Vector2.ZERO)
	CombatStatsTracker._on_wave_ended(1, 80, 1)
	var rows: Array = CombatStatsTracker._wave_rows
	assert_int(rows.size()).is_equal(1)
	var row: Dictionary = rows[0] as Dictionary
	assert_int(int(row.get("enemies_spawned", -1))).is_equal(3)
	assert_float(float(row.get("leak_rate", 0.0))).is_equal_approx(1.0 / 3.0, 0.0001)
	assert_int(int(row.get("florence_damage_taken", -1))).is_equal(0)


func test_status_effect_stack_mode_refresh() -> void:
	var bd: BuildingData = BuildingData.new()
	bd.building_type = Types.BuildingType.ARROW_TOWER
	bd.damage = 10.0
	bd.fire_rate = 1.0
	bd.attack_range = 12.0
	var building: BuildingBase = BuildingBase.new()
	add_child(building)
	building._building_data = bd
	building._rebuild_base_stats()
	building.recompute_all_stats()
	var e1: Dictionary = {
		"effect_type": "debuff",
		"stack_key": "test_slow",
		"stack_mode": "REFRESH",
		"stat": "damage",
		"modifier_type": "MULTIPLY",
		"modifier_value": 0.9,
		"duration_remaining": 5.0,
		"tags": PackedStringArray(),
	}
	var e2: Dictionary = e1.duplicate()
	e2["duration_remaining"] = 8.0
	building.add_status_effect(e1)
	building.add_status_effect(e2)
	assert_int(building.active_status_effects.size()).is_equal(1)
	assert_float(float(building.active_status_effects[0].get("duration_remaining", 0.0))).is_equal(8.0)
	building.queue_free()


func test_aura_strongest_wins() -> void:
	var bd: BuildingData = BuildingData.new()
	bd.building_type = Types.BuildingType.ARROW_TOWER
	bd.damage = 10.0
	bd.fire_rate = 1.0
	bd.attack_range = 12.0
	var building: BuildingBase = BuildingBase.new()
	building._building_data = bd
	building._rebuild_base_stats()
	building.incoming_auras = [
		{
			"source_instance_id": "a1",
			"aura_category": "support",
			"aura_stat": "damage",
			"modifier_type": "MULTIPLY",
			"modifier_value": 1.1,
		},
		{
			"source_instance_id": "a2",
			"aura_category": "support",
			"aura_stat": "damage",
			"modifier_type": "MULTIPLY",
			"modifier_value": 1.2,
		},
	]
	building.recompute_all_stats()
	assert_int(building.resolved_auras.size()).is_equal(1)
	var winner: Dictionary = building.resolved_auras["support"] as Dictionary
	assert_float(float(winner.get("modifier_value", 0.0))).is_equal(1.2)
	building.queue_free()
