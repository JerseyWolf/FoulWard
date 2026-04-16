# GdUnit4 — Enemy special_tags / ShieldComponent (Prompt 9).
extends GdUnitTestSuite

const ShieldComponentType = preload("res://scripts/components/shield_component.gd")


func test_shield_absorbs_damage() -> void:
	var shield: ShieldComponentType = ShieldComponentType.new() as ShieldComponentType
	shield.initialise({"shield_hp": 80})
	var leftover: float = shield.absorb(50.0)
	assert_float(leftover).is_equal(0.0)
	assert_float(shield.shield_hp).is_equal(30.0)
	leftover = shield.absorb(50.0)
	assert_float(leftover).is_equal(20.0)
	assert_float(shield.shield_hp).is_equal(0.0)
	assert_bool(shield.is_active()).is_false()


func test_brood_carrier_has_on_death_spawn() -> void:
	var ed: EnemyData = load("res://resources/enemy_data/brood_carrier.tres") as EnemyData
	assert_bool("on_death_spawn" in ed.special_tags).is_true()
	var params: Dictionary = ed.special_values.get("on_death_spawn", {}) as Dictionary
	assert_str(str(params.get("spawn_type", ""))).is_equal("ORC_RATLING")
	assert_int(int(params.get("spawn_count", 0))).is_equal(3)


func test_orc_berserker_charge_params() -> void:
	var ed: EnemyData = load("res://resources/enemy_data/orc_berserker.tres") as EnemyData
	assert_bool("charge" in ed.special_tags).is_true()
	var p: Dictionary = ed.special_values.get("charge", {}) as Dictionary
	assert_float(float(p.get("enrage_hp_pct", 0))).is_equal(0.5)
	assert_float(float(p.get("speed_bonus", 0))).is_equal(0.5)


func test_troll_regen_params() -> void:
	var ed: EnemyData = load("res://resources/enemy_data/troll.tres") as EnemyData
	assert_bool("regen" in ed.special_tags).is_true()
	var p: Dictionary = ed.special_values.get("regen", {}) as Dictionary
	assert_float(float(p.get("hp_per_sec", 0))).is_equal(8.0)


func test_orc_saboteur_disable_params() -> void:
	var ed: EnemyData = load("res://resources/enemy_data/orc_saboteur.tres") as EnemyData
	assert_bool("disable_building" in ed.special_tags).is_true()
	var p: Dictionary = ed.special_values.get("disable_building", {}) as Dictionary
	assert_float(float(p.get("disable_duration", 0))).is_equal(4.0)


func test_war_shaman_aura_buff_params() -> void:
	var ed: EnemyData = load("res://resources/enemy_data/war_shaman.tres") as EnemyData
	assert_bool("aura_buff" in ed.special_tags).is_true()
	var p: Dictionary = ed.special_values.get("aura_buff", {}) as Dictionary
	assert_float(float(p.get("damage_pct", 0))).is_equal(0.20)


func test_all_special_tag_values_match_known_tags() -> void:
	var known: Array[String] = [
		"charge",
		"shield",
		"aura_buff",
		"aura_heal",
		"on_death_spawn",
		"ranged_long",
		"disable_building",
		"anti_air",
		"regen",
	]
	var dir := DirAccess.open("res://resources/enemy_data/")
	assert_object(dir).is_not_null()
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var ed: EnemyData = load("res://resources/enemy_data/" + fname) as EnemyData
			if ed != null:
				for tag: String in ed.special_tags:
					assert_bool(tag in known).is_true()
		fname = dir.get_next()
