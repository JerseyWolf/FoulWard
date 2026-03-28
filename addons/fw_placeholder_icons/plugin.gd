@tool
extends EditorPlugin

const _PlaceholderIconGenerator = preload("res://tools/generate_placeholder_icons.gd")


func _enter_tree() -> void:
	add_tool_menu_item("Generate Placeholder Icons", _on_generate_icons)


func _exit_tree() -> void:
	remove_tool_menu_item("Generate Placeholder Icons")


func _on_generate_icons() -> void:
	var root: Control = get_editor_interface().get_base_control()
	var gen: RefCounted = _PlaceholderIconGenerator.new()
	await gen.generate_all_icons(root)
	var fs: EditorFileSystem = get_editor_interface().get_resource_filesystem()
	fs.scan()
