## Editor / CLI: generates 64×64 placeholder PNGs for buildings, enemies, and allies.
## Run from Project → Generate Placeholder Icons (EditorPlugin) or:
##   godot --headless --path . -s res://tools/run_generate_placeholder_icons.gd
@tool
class_name PlaceholderIconGenerator
extends RefCounted

const BG_BUILDINGS: Color = Color(0.3, 0.5, 0.8)
const BG_ENEMIES: Color = Color(0.8, 0.3, 0.3)
const BG_ALLIES: Color = Color(0.3, 0.8, 0.4)

const ICON_SIZE: Vector2i = Vector2i(64, 64)


func generate_all_icons(root: Node) -> void:
	var tree: SceneTree = root.get_tree()
	if tree == null:
		push_error("PlaceholderIconGenerator: root has no SceneTree")
		return
	# Buildings
	for i: int in range(Types.BuildingType.size()):
		var key: String = Types.BuildingType.keys()[i]
		var label_text: String = key.substr(0, mini(6, key.length()))
		var token: String = _building_token(i as Types.BuildingType)
		var img: Image = await _render_icon(tree, label_text, BG_BUILDINGS)
		var err: Error = _save_png(img, "res://art/icons/buildings/%s.png" % token)
		if err != OK:
			push_error("PlaceholderIconGenerator: failed to save building icon %s" % token)
	# Enemies
	for i: int in range(Types.EnemyType.size()):
		var key_e: String = Types.EnemyType.keys()[i]
		var label_e: String = key_e.substr(0, mini(6, key_e.length()))
		var etoken: String = _enemy_token(i as Types.EnemyType)
		var img_e: Image = await _render_icon(tree, label_e, BG_ENEMIES)
		var err_e: Error = _save_png(img_e, "res://art/icons/enemies/%s.png" % etoken)
		if err_e != OK:
			push_error("PlaceholderIconGenerator: failed to save enemy icon %s" % etoken)
	# Allies — scan ally_data resources
	var ally_ids: PackedStringArray = _collect_ally_ids()
	for ally_id: String in ally_ids:
		var atoken: String = String(ally_id).to_lower()
		var label_a: String = ally_id.substr(0, mini(6, ally_id.length()))
		var img_a: Image = await _render_icon(tree, label_a, BG_ALLIES)
		var err_a: Error = _save_png(img_a, "res://art/icons/allies/%s.png" % atoken)
		if err_a != OK:
			push_error("PlaceholderIconGenerator: failed to save ally icon %s" % atoken)
	print("PlaceholderIconGenerator: done.")


func _collect_ally_ids() -> PackedStringArray:
	var result: PackedStringArray = []
	var dir: DirAccess = DirAccess.open("res://resources/ally_data/")
	if dir == null:
		return result
	dir.list_dir_begin()
	var fn: String = dir.get_next()
	while fn != "":
		if not dir.current_is_dir() and fn.ends_with(".tres"):
			var res: Resource = load("res://resources/ally_data/%s" % fn)
			if res != null and res.get("ally_id") != null:
				result.append(str(res.get("ally_id")))
		fn = dir.get_next()
	dir.list_dir_end()
	return result


func _save_png(img: Image, path: String) -> Error:
	var base_dir: String = path.get_base_dir()
	var rel: String = base_dir.trim_prefix("res://")
	if not rel.is_empty():
		var d: DirAccess = DirAccess.open("res://")
		if d != null:
			var mk: Error = d.make_dir_recursive(rel)
			if mk != OK and mk != ERR_ALREADY_EXISTS:
				push_warning("PlaceholderIconGenerator: make_dir_recursive %s err %s" % [rel, mk])
	return img.save_png(path)


func _render_icon(tree: SceneTree, label_text: String, bg: Color) -> Image:
	var vp := SubViewport.new()
	vp.size = ICON_SIZE
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var panel := Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp.add_child(panel)
	var bg_rect := ColorRect.new()
	bg_rect.color = bg
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(bg_rect)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_font_size_override("font_size", 12)
	panel.add_child(lbl)
	tree.root.add_child(vp)
	await tree.process_frame
	await tree.process_frame
	var tex: Texture2D = vp.get_texture()
	var img: Image
	if tex != null:
		img = tex.get_image()
	if img == null:
		img = Image.create(ICON_SIZE.x, ICON_SIZE.y, false, Image.FORMAT_RGBA8)
		img.fill(bg)
	tree.root.remove_child(vp)
	vp.queue_free()
	return img


## Mirrors ArtPlaceholderHelper token rules for filenames.
func _enemy_token(enemy_type: Types.EnemyType) -> String:
	match enemy_type:
		Types.EnemyType.ORC_GRUNT:
			return "orc_grunt"
		Types.EnemyType.ORC_BRUTE:
			return "orc_brute"
		Types.EnemyType.GOBLIN_FIREBUG:
			return "goblin_firebug"
		Types.EnemyType.PLAGUE_ZOMBIE:
			return "plague_zombie"
		Types.EnemyType.ORC_ARCHER:
			return "orc_archer"
		Types.EnemyType.BAT_SWARM:
			return "bat_swarm"
		_:
			return "unknown"


func _building_token(building_type: Types.BuildingType) -> String:
	match building_type:
		Types.BuildingType.ARROW_TOWER:
			return "arrow_tower"
		Types.BuildingType.FIRE_BRAZIER:
			return "fire_brazier"
		Types.BuildingType.MAGIC_OBELISK:
			return "magic_obelisk"
		Types.BuildingType.POISON_VAT:
			return "poison_vat"
		Types.BuildingType.BALLISTA:
			return "ballista"
		Types.BuildingType.ARCHER_BARRACKS:
			return "archer_barracks"
		Types.BuildingType.ANTI_AIR_BOLT:
			return "anti_air_bolt"
		Types.BuildingType.SHIELD_GENERATOR:
			return "shield_generator"
		_:
			return "unknown"
