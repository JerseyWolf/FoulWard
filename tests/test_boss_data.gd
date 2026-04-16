# test_boss_data.gd
# GdUnit4: BossData resources and FactionData mini_boss_ids integrity (Prompt 10).

class_name TestBossData
extends GdUnitTestSuite


func test_boss_data_resources_load_and_have_valid_scene() -> void:
	var paths: Array[String] = [
		"res://resources/bossdata_plague_cult_miniboss.tres",
		"res://resources/bossdata_final_boss.tres",
	]
	for path: String in paths:
		var res: Resource = load(path)
		assert_object(res).is_not_null()
		var boss: BossData = res as BossData
		assert_object(boss).is_not_null()
		assert_that(boss.boss_scene).is_not_null()
		var inst: Node = boss.boss_scene.instantiate()
		assert_object(inst).is_not_null()
		var bb: BossBase = inst as BossBase
		assert_object(bb).is_not_null()
		inst.free()


func test_faction_data_mini_boss_ids_reference_existing_boss_ids() -> void:
	var boss_ids: Dictionary = {}
	for path: String in BossData.BUILTIN_BOSS_RESOURCE_PATHS:
		var b: BossData = load(path) as BossData
		assert_object(b).is_not_null()
		assert_that(b.boss_id).is_not_empty()
		boss_ids[b.boss_id] = true

	for fpath: String in FactionData.BUILTIN_FACTION_RESOURCE_PATHS:
		var faction: FactionData = load(fpath) as FactionData
		assert_object(faction).is_not_null()
		for mid: String in faction.mini_boss_ids:
			assert_bool(boss_ids.has(mid)).is_true()
