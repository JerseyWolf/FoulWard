## RingRotationScreen — Pre-combat UI to rotate each hex ring before build/combat.
extends Control

const ANGLE_STEP_RAD: float = PI / 6.0
const HEX_GRID_SCENE: PackedScene = preload("res://scenes/hex_grid/hex_grid.tscn")

@onready var _preview_viewport: SubViewport = $Panel/VBoxContainer/SubViewportContainer/SubViewport
@onready var _ring1_left: Button = $Panel/VBoxContainer/RingControlsPanel/Ring1Row/Ring1LeftBtn
@onready var _ring1_right: Button = $Panel/VBoxContainer/RingControlsPanel/Ring1Row/Ring1RightBtn
@onready var _ring2_left: Button = $Panel/VBoxContainer/RingControlsPanel/Ring2Row/Ring2LeftBtn
@onready var _ring2_right: Button = $Panel/VBoxContainer/RingControlsPanel/Ring2Row/Ring2RightBtn
@onready var _ring3_left: Button = $Panel/VBoxContainer/RingControlsPanel/Ring3Row/Ring3LeftBtn
@onready var _ring3_right: Button = $Panel/VBoxContainer/RingControlsPanel/Ring3Row/Ring3RightBtn
@onready var _confirm: Button = $Panel/VBoxContainer/ConfirmButton

var _preview_hex: HexGrid = null


func _ready() -> void:
	hide()
	_ring1_left.pressed.connect(_on_ring_rotate_left.bind(0))
	_ring1_right.pressed.connect(_on_ring_rotate_right.bind(0))
	_ring2_left.pressed.connect(_on_ring_rotate_left.bind(1))
	_ring2_right.pressed.connect(_on_ring_rotate_right.bind(1))
	_ring3_left.pressed.connect(_on_ring_rotate_left.bind(2))
	_ring3_right.pressed.connect(_on_ring_rotate_right.bind(2))
	_confirm.pressed.connect(_on_confirm_pressed)
	call_deferred("_setup_hex_preview")


func _get_hex_grid() -> HexGrid:
	var hg: Node = get_node_or_null("/root/Main/HexGrid")
	return hg as HexGrid


func _setup_hex_preview() -> void:
	if _preview_viewport == null:
		return
	if _preview_viewport.get_node_or_null("HexGridPreview") != null:
		return
	var main_hg: HexGrid = _get_hex_grid()
	if main_hg == null:
		return
	if main_hg.building_data_registry.size() != 36:
		push_warning("RingRotationScreen: Main HexGrid registry size != 36; preview skipped.")
		return
	var pv: HexGrid = HEX_GRID_SCENE.instantiate() as HexGrid
	if pv == null:
		return
	pv.name = "HexGridPreview"
	pv.building_data_registry = main_hg.building_data_registry.duplicate(true)
	_preview_viewport.add_child(pv)
	_preview_hex = pv
	for ring_i: int in range(3):
		var delta: float = main_hg.get_ring_offset_radians(ring_i) - pv.get_ring_offset_radians(ring_i)
		if absf(delta) > 0.0001:
			pv.apply_ring_rotation_silent(ring_i, delta)
	var cam: Camera3D = Camera3D.new()
	cam.name = "PreviewCamera"
	cam.position = Vector3(0.0, 55.0, 0.1)
	cam.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 45.0
	_preview_viewport.add_child(cam)
	cam.current = true
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.name = "PreviewLight"
	light.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
	_preview_viewport.add_child(light)


func _sync_preview_ring(ring_index: int, delta_rad: float) -> void:
	if _preview_hex != null and is_instance_valid(_preview_hex):
		_preview_hex.apply_ring_rotation_silent(ring_index, delta_rad)


func _on_ring_rotate_left(ring_index: int) -> void:
	var hex_grid: HexGrid = _get_hex_grid()
	if hex_grid == null:
		return
	hex_grid.rotate_ring(ring_index, -ANGLE_STEP_RAD)
	_sync_preview_ring(ring_index, -ANGLE_STEP_RAD)


func _on_ring_rotate_right(ring_index: int) -> void:
	var hex_grid: HexGrid = _get_hex_grid()
	if hex_grid == null:
		return
	hex_grid.rotate_ring(ring_index, ANGLE_STEP_RAD)
	_sync_preview_ring(ring_index, ANGLE_STEP_RAD)


func _on_confirm_pressed() -> void:
	GameManager.exit_ring_rotate()
