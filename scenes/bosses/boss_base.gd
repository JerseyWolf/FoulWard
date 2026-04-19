## boss_base.gd
## Boss controller extending EnemyBase — reuses nav, damage, and wave integration.

class_name BossBase
extends EnemyBase

var boss_data: BossData = null
var current_phase_index: int = 0


func initialize_boss_data(data: BossData) -> void:
	if data == null:
		push_error("BossBase.initialize_boss_data: BossData is null")
		return
	boss_data = data
	var placeholder: EnemyData = data.build_placeholder_enemy_data()
	initialize(placeholder)
	_apply_boss_stats()
	_configure_visuals()
	SignalBus.boss_spawned.emit(boss_data.boss_id)


func _apply_boss_stats() -> void:
	if boss_data == null:
		return
	# SOURCE: stat application pattern adapted from resource-driven modular enemies (GameDev with Drew, https://www.youtube.com/watch?v=NXvhYdLqrhA)
	var ed: EnemyData = get_enemy_data()
	if ed == null:
		return
	ed.max_hp = boss_data.max_hp
	ed.move_speed = boss_data.move_speed
	ed.damage = boss_data.damage
	ed.attack_range = boss_data.attack_range
	ed.attack_cooldown = boss_data.attack_cooldown
	ed.armor_type = boss_data.armor_type
	ed.gold_reward = boss_data.gold_reward
	ed.is_ranged = boss_data.is_ranged
	ed.is_flying = boss_data.is_flying
	ed.damage_immunities = boss_data.damage_immunities.duplicate()

	health_component.max_hp = boss_data.max_hp
	health_component.reset_to_max()


func _configure_visuals() -> void:
	# Production wiring: asset = RiggedVisualWiring.boss_rigged_glb_path(boss_id)
	# → res://art/generated/bosses/<boss_id>.glb; phase/ability clips on same AnimationPlayer.
	if boss_data == null:
		return
	var slot: Node3D = get_node_or_null("BossVisual") as Node3D
	if slot == null:
		return
	slot.scale = Vector3.ONE
	var glb_path: String = RiggedVisualWiring.boss_rigged_glb_path(boss_data.boss_id)
	if not glb_path.is_empty() and ResourceLoader.exists(glb_path):
		var ap: AnimationPlayer = RiggedVisualWiring.mount_glb_scene(slot, glb_path)
		slot.scale = Vector3(1.5, 1.5, 1.5)
		assign_locomotion_animation_player(ap)
	else:
		RiggedVisualWiring.mount_boss_placeholder_mesh(slot)
		assign_locomotion_animation_player(null)

	var label: Label3D = get_node_or_null("BossLabel") as Label3D
	if label != null:
		label.text = boss_data.display_name


func _on_health_depleted() -> void:
	if boss_data != null:
		SignalBus.boss_killed.emit(boss_data.boss_id)
	super._on_health_depleted()


func advance_phase() -> void:
	if boss_data == null:
		return
	if boss_data.phase_count <= 1:
		return
	current_phase_index = clampi(current_phase_index + 1, 0, boss_data.phase_count - 1)
	# SOURCE: simple phase index tracking inspired by multi-phase boss tutorials (Ludonauta Hollow Knight-style boss, https://ludonauta.itch.io/platformer-essentials/devlog/1089921/hollow-knight-inspired-boss-fight-in-godot-4)
	# POST-MVP: per-phase stat scaling and SignalBus.boss_phase_changed.
