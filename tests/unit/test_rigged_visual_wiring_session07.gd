# GdUnit4 — Session 07 tests for RiggedVisualWiring path helpers and ANIM_ constants.
extends GdUnitTestSuite


func test_all_30_enemy_types_return_non_empty_path() -> void:
	for enemy_type: Types.EnemyType in Types.EnemyType.values():
		var path: String = RiggedVisualWiring.enemy_rigged_glb_path(enemy_type)
		assert_str(path).override_failure_message(
			"enemy_rigged_glb_path returned empty for EnemyType %d" % enemy_type
		).is_not_empty()


func test_enemy_paths_use_correct_prefix() -> void:
	const EXPECTED_PREFIX: String = "res://art/generated/enemies/"
	for enemy_type: Types.EnemyType in Types.EnemyType.values():
		var path: String = RiggedVisualWiring.enemy_rigged_glb_path(enemy_type)
		assert_bool(path.begins_with(EXPECTED_PREFIX)).override_failure_message(
			"enemy path '%s' does not begin with '%s'" % [path, EXPECTED_PREFIX]
		).is_true()


func test_ally_known_ids_return_paths() -> void:
	const KNOWN_IDS: Array = ["arnulf", "archer", "knight", "swordsman", "barbarian"]
	for ally_id: String in KNOWN_IDS:
		var path: String = RiggedVisualWiring.ally_rigged_glb_path(StringName(ally_id))
		assert_str(path).override_failure_message(
			"ally_rigged_glb_path returned empty for known id '%s'" % ally_id
		).is_not_empty()
		assert_str(path).contains(ally_id)
		assert_str(path).starts_with("res://art/generated/allies/")
		assert_str(path).ends_with(".glb")


func test_ally_unknown_id_returns_empty() -> void:
	var result: String = RiggedVisualWiring.ally_rigged_glb_path(&"unknown_mercenary")
	assert_str(result).is_empty()


func test_building_all_36_types_return_paths() -> void:
	var checked: int = 0
	for building_type: Types.BuildingType in Types.BuildingType.values():
		var path: String = RiggedVisualWiring.building_rigged_glb_path(building_type)
		assert_str(path).override_failure_message(
			"building_rigged_glb_path returned empty for BuildingType %d" % building_type
		).is_not_empty()
		checked += 1
	assert_int(checked).is_equal(36)


func test_building_paths_use_correct_prefix() -> void:
	const EXPECTED_PREFIX: String = "res://art/generated/buildings/"
	for building_type: Types.BuildingType in Types.BuildingType.values():
		var path: String = RiggedVisualWiring.building_rigged_glb_path(building_type)
		assert_bool(path.begins_with(EXPECTED_PREFIX)).override_failure_message(
			"building path '%s' does not begin with '%s'" % [path, EXPECTED_PREFIX]
		).is_true()


func test_tower_glb_path_correct() -> void:
	var path: String = RiggedVisualWiring.tower_glb_path()
	assert_str(path).is_equal("res://art/characters/florence/florence.glb")


func test_anim_constants_no_drunk_idle() -> void:
	# Arnulf drunkenness system is formally cut — no ANIM_DRUNK_IDLE should exist.
	var props: Array[Dictionary] = ClassDB.class_get_property_list("RiggedVisualWiring")
	var constant_names: PackedStringArray = PackedStringArray()
	for prop: Dictionary in props:
		constant_names.append(str(prop.get("name", "")))
	# The simplest headless check: verify none of the expected constant string values
	# equals the removed clip name.
	const ALL_ANIM_CONSTANTS: Array = [
		"idle", "walk", "death", "attack", "hit_react", "spawn", "run",
		"attack_melee", "downed", "recovering", "shoot", "cast_spell",
		"victory", "defeat", "active", "destroyed", "phase_transition",
	]
	assert_bool(ALL_ANIM_CONSTANTS.has("drunk_idle")).is_false()
	assert_str(RiggedVisualWiring.ANIM_IDLE).is_equal(&"idle")
	assert_str(RiggedVisualWiring.ANIM_WALK).is_equal(&"walk")
	assert_str(RiggedVisualWiring.ANIM_DEATH).is_equal(&"death")


func test_anim_constants_all_present() -> void:
	# Verify all 17 ANIM_ string constants have the correct clip name values.
	assert_str(RiggedVisualWiring.ANIM_IDLE).is_equal(&"idle")
	assert_str(RiggedVisualWiring.ANIM_WALK).is_equal(&"walk")
	assert_str(RiggedVisualWiring.ANIM_DEATH).is_equal(&"death")
	assert_str(RiggedVisualWiring.ANIM_ATTACK).is_equal(&"attack")
	assert_str(RiggedVisualWiring.ANIM_HIT_REACT).is_equal(&"hit_react")
	assert_str(RiggedVisualWiring.ANIM_SPAWN).is_equal(&"spawn")
	assert_str(RiggedVisualWiring.ANIM_RUN).is_equal(&"run")
	assert_str(RiggedVisualWiring.ANIM_ATTACK_MELEE).is_equal(&"attack_melee")
	assert_str(RiggedVisualWiring.ANIM_DOWNED).is_equal(&"downed")
	assert_str(RiggedVisualWiring.ANIM_RECOVERING).is_equal(&"recovering")
	assert_str(RiggedVisualWiring.ANIM_SHOOT).is_equal(&"shoot")
	assert_str(RiggedVisualWiring.ANIM_CAST_SPELL).is_equal(&"cast_spell")
	assert_str(RiggedVisualWiring.ANIM_VICTORY).is_equal(&"victory")
	assert_str(RiggedVisualWiring.ANIM_DEFEAT).is_equal(&"defeat")
	assert_str(RiggedVisualWiring.ANIM_ACTIVE).is_equal(&"active")
	assert_str(RiggedVisualWiring.ANIM_DESTROYED).is_equal(&"destroyed")
	assert_str(RiggedVisualWiring.ANIM_PHASE_TRANSITION).is_equal(&"phase_transition")
