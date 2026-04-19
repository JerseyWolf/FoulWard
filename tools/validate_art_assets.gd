## validate_art_assets.gd
## @tool EditorScript — report-only preflight for res://art/ GLBs.
## Run via: Tools → Execute Script in the Godot editor.
##
## Scans res://art/ recursively, loads each GLB via ResourceLoader,
## checks required animation clips per category, and prints a report.
## Does NOT modify any assets. Uses DirAccess (not EditorFileSystem).
## Uses ResourceLoader.load() to avoid silent track drops from GLTFDocument.
@tool
extends EditorScript

const ART_ROOT: String = "res://art/"
const GENERATED_ENEMIES: String = "res://art/generated/enemies/"
const GENERATED_ALLIES: String = "res://art/generated/allies/"
const GENERATED_BUILDINGS: String = "res://art/generated/buildings/"
const GENERATED_BOSSES: String = "res://art/generated/bosses/"
const CHARACTERS_ROOT: String = "res://art/characters/"

# Required animation clip names per category.
const ENEMY_REQUIRED_CLIPS: PackedStringArray = PackedStringArray([
	"idle", "walk", "death", "hit_react",
])
const ALLY_REQUIRED_CLIPS: PackedStringArray = PackedStringArray([
	"idle", "run", "death", "attack_melee",
])
const BUILDING_REQUIRED_CLIPS: PackedStringArray = PackedStringArray([
	"idle", "active",
])
const BOSS_REQUIRED_CLIPS: PackedStringArray = PackedStringArray([
	"idle", "walk", "death", "phase_transition",
])
const TOWER_REQUIRED_CLIPS: PackedStringArray = PackedStringArray([
	"idle",
])

class GlbReport:
	var path: String = ""
	var category: String = ""
	var loaded: bool = false
	var missing_clips: PackedStringArray = PackedStringArray()
	var error_message: String = ""


var _reports: Array[GlbReport] = []


func _run() -> void:
	print("=== validate_art_assets.gd — ART PREFLIGHT ===")
	_reports.clear()
	_scan_directory(ART_ROOT)
	_report()


func _scan_directory(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		push_warning("validate_art_assets: Cannot open directory: %s" % dir_path)
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue
		var full_path: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			_scan_directory(full_path)
		elif entry.ends_with(".glb"):
			var report: GlbReport = GlbReport.new()
			report.path = full_path
			report.category = _infer_category(full_path)
			_check_glb(report)
			_reports.append(report)
		entry = dir.get_next()
	dir.list_dir_end()


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


func _check_glb(report: GlbReport) -> void:
	if not ResourceLoader.exists(report.path):
		report.loaded = false
		report.error_message = "File not found by ResourceLoader"
		return

	var resource: Resource = ResourceLoader.load(report.path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if resource == null:
		report.loaded = false
		report.error_message = "ResourceLoader.load() returned null"
		return

	if not (resource is PackedScene):
		report.loaded = false
		report.error_message = "Resource is not a PackedScene (type: %s)" % resource.get_class()
		return

	report.loaded = true
	var scene_instance: Node = (resource as PackedScene).instantiate()
	var anim_player: AnimationPlayer = _find_animation_player(scene_instance)

	var required: PackedStringArray = _get_required_clips(report.category)
	var missing: PackedStringArray = PackedStringArray()
	if anim_player != null:
		for clip: String in required:
			if not anim_player.has_animation(StringName(clip)):
				missing.append(clip)
	elif required.size() > 0:
		missing = required

	report.missing_clips = missing
	scene_instance.free()


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root == null:
		return null
	return root.find_child("AnimationPlayer", true, false) as AnimationPlayer


func _report() -> void:
	var ok_count: int = 0
	var warn_count: int = 0
	var err_count: int = 0

	print("\n--- GLB RESULTS ---")
	for report: GlbReport in _reports:
		if not report.loaded:
			err_count += 1
			print("[ERROR] %s | %s | %s" % [report.category, report.path, report.error_message])
		elif report.missing_clips.size() > 0:
			warn_count += 1
			print("[WARN]  %s | %s | missing clips: %s" % [
				report.category, report.path, ", ".join(Array(report.missing_clips))
			])
		else:
			ok_count += 1
			print("[OK]    %s | %s" % [report.category, report.path])

	print("\n--- SUMMARY ---")
	print("Total GLBs scanned : %d" % _reports.size())
	print("OK                 : %d" % ok_count)
	print("Missing clips (warn): %d" % warn_count)
	print("Load errors        : %d" % err_count)
	print("=== validate_art_assets.gd — DONE ===")
