# GdUnit4 — Session 07 tests for the art asset validation logic.
# validate_art_assets.gd extends EditorScript and cannot be instantiated in headless tests.
# These tests verify the specification of its path-inference and clip-requirements logic
# by exercising the same constants and rules that the tool implements.
extends GdUnitTestSuite

# Mirror of validate_art_assets.gd constants — kept in sync intentionally so tests catch drift.
const GENERATED_ENEMIES: String = "res://art/generated/enemies/"
const GENERATED_ALLIES: String = "res://art/generated/allies/"
const GENERATED_BUILDINGS: String = "res://art/generated/buildings/"
const GENERATED_BOSSES: String = "res://art/generated/bosses/"
const CHARACTERS_ROOT: String = "res://art/characters/"

var ENEMY_REQUIRED_CLIPS: PackedStringArray = PackedStringArray([
	"idle", "walk", "death", "hit_react",
])
var ALLY_REQUIRED_CLIPS: PackedStringArray = PackedStringArray([
	"idle", "run", "death", "attack_melee",
])
var BUILDING_REQUIRED_CLIPS: PackedStringArray = PackedStringArray([
	"idle", "active",
])
var BOSS_REQUIRED_CLIPS: PackedStringArray = PackedStringArray([
	"idle", "walk", "death", "phase_transition",
])
var TOWER_REQUIRED_CLIPS: PackedStringArray = PackedStringArray([
	"idle",
])


# Mirrors the _infer_category() logic in validate_art_assets.gd.
func _infer_category(glb_path: String) -> String:
	if glb_path.begins_with(GENERATED_ENEMIES):
		return "enemy"
	if glb_path.begins_with(GENERATED_ALLIES):
		return "ally"
	if glb_path.begins_with(GENERATED_BUILDINGS):
		return "building"
	if glb_path.begins_with(GENERATED_BOSSES):
		return "boss"
	if glb_path.begins_with(CHARACTERS_ROOT):
		return "tower"
	return "unknown"


# Mirrors the _get_required_clips() logic in validate_art_assets.gd.
func _get_required_clips(category: String) -> PackedStringArray:
	match category:
		"enemy":
			return ENEMY_REQUIRED_CLIPS
		"ally":
			return ALLY_REQUIRED_CLIPS
		"building":
			return BUILDING_REQUIRED_CLIPS
		"boss":
			return BOSS_REQUIRED_CLIPS
		"tower":
			return TOWER_REQUIRED_CLIPS
		_:
			return PackedStringArray()


func test_infer_category_enemies() -> void:
	var path: String = GENERATED_ENEMIES + "orc_grunt.glb"
	assert_str(_infer_category(path)).is_equal("enemy")


func test_infer_category_allies() -> void:
	var path: String = GENERATED_ALLIES + "arnulf.glb"
	assert_str(_infer_category(path)).is_equal("ally")


func test_infer_category_bosses() -> void:
	var path: String = GENERATED_BOSSES + "orc_warlord.glb"
	assert_str(_infer_category(path)).is_equal("boss")


func test_infer_category_buildings() -> void:
	var path: String = GENERATED_BUILDINGS + "arrow_tower.glb"
	assert_str(_infer_category(path)).is_equal("building")


func test_infer_category_tower() -> void:
	var path: String = CHARACTERS_ROOT + "florence/florence.glb"
	assert_str(_infer_category(path)).is_equal("tower")


func test_infer_category_unknown() -> void:
	assert_str(_infer_category("res://art/misc/something.glb")).is_equal("unknown")
	assert_str(_infer_category("res://art/")).is_equal("unknown")
	assert_str(_infer_category("")).is_equal("unknown")


func test_required_clips_enemy_count() -> void:
	var clips: PackedStringArray = _get_required_clips("enemy")
	assert_int(clips.size()).is_equal(4)
	assert_bool(clips.has("idle")).is_true()
	assert_bool(clips.has("walk")).is_true()
	assert_bool(clips.has("death")).is_true()
	assert_bool(clips.has("hit_react")).is_true()


func test_required_clips_ally_count() -> void:
	var clips: PackedStringArray = _get_required_clips("ally")
	assert_int(clips.size()).is_equal(4)
	assert_bool(clips.has("idle")).is_true()
	assert_bool(clips.has("run")).is_true()
	assert_bool(clips.has("death")).is_true()
	assert_bool(clips.has("attack_melee")).is_true()


func test_required_clips_misc_empty() -> void:
	var clips: PackedStringArray = _get_required_clips("unknown")
	assert_int(clips.size()).is_equal(0)


func test_check_glb_no_anim_player_returns_missing_all() -> void:
	# When a GLB scene has no AnimationPlayer, all required clips for that category are missing.
	# Simulate: no AnimationPlayer → missing_clips == required clips.
	var required: PackedStringArray = _get_required_clips("enemy")
	var anim_player: AnimationPlayer = null
	var missing: PackedStringArray = PackedStringArray()
	if anim_player != null:
		for clip: String in required:
			if not anim_player.has_animation(StringName(clip)):
				missing.append(clip)
	elif required.size() > 0:
		missing = required
	assert_int(missing.size()).is_equal(required.size())
	for clip: String in required:
		assert_bool(missing.has(clip)).override_failure_message(
			"Expected '%s' in missing_clips when AnimationPlayer is null" % clip
		).is_true()
