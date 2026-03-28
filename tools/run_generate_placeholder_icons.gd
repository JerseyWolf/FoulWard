## Headless one-shot: generates PNGs under res://art/icons/** (see PlaceholderIconGenerator).
extends SceneTree

const _PlaceholderIconGenerator = preload("res://tools/generate_placeholder_icons.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var holder: Node = Node.new()
	root.add_child(holder)
	var gen: RefCounted = _PlaceholderIconGenerator.new()
	await gen.generate_all_icons(holder)
	holder.queue_free()
	quit(0)
