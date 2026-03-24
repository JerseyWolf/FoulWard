# test_ally_signals.gd — SignalBus ally_* and Arnulf generic mirror signals.

class_name TestAllySignals
extends GdUnitTestSuite

const ALLY_DATA_SCRIPT: GDScript = preload("res://scripts/resources/ally_data.gd")


func test_ally_spawned_signal_emitted_on_spawn() -> void:
	var monitor := monitor_signals(SignalBus, false)
	var ally_scene: PackedScene = load("res://scenes/allies/ally_base.tscn")
	var ally: Node = ally_scene.instantiate()
	add_child(ally)
	var data: Resource = ALLY_DATA_SCRIPT.new()
	data.set("ally_id", "test_ally")
	data.set("max_hp", 10)
	data.set("attack_cooldown", 1.0)
	ally.call("initialize_ally_data", data)
	await get_tree().process_frame
	await assert_signal(monitor).is_emitted("ally_spawned", ["test_ally"])
	ally.queue_free()
	await get_tree().process_frame


func test_ally_killed_signal_emitted_on_death() -> void:
	var monitor := monitor_signals(SignalBus, false)
	var ally_scene: PackedScene = load("res://scenes/allies/ally_base.tscn")
	var ally: Node = ally_scene.instantiate()
	add_child(ally)
	var data: Resource = ALLY_DATA_SCRIPT.new()
	data.set("ally_id", "test_ally_killed")
	data.set("max_hp", 10)
	data.set("attack_cooldown", 1.0)
	ally.call("initialize_ally_data", data)
	ally.get_node("HealthComponent").call("take_damage", float(10))
	await get_tree().process_frame
	await assert_signal(monitor).is_emitted("ally_killed", ["test_ally_killed"])


func test_arnulf_emits_generic_ally_signals() -> void:
	var scene: PackedScene = load("res://scenes/arnulf/arnulf.tscn")
	var arnulf: Arnulf = scene.instantiate() as Arnulf
	add_child(arnulf)

	var m_down = monitor_signals(SignalBus, false)
	arnulf.health_component.take_damage(float(arnulf.max_hp))
	await assert_signal(m_down).is_emitted("arnulf_incapacitated")
	await assert_signal(m_down).is_emitted("ally_downed", ["arnulf"])

	var m_up = monitor_signals(SignalBus, false)
	arnulf._transition_to_state(Types.ArnulfState.RECOVERING)
	arnulf._process_recovering()
	await assert_signal(m_up).is_emitted("arnulf_recovered")
	await assert_signal(m_up).is_emitted("ally_recovered", ["arnulf"])

	arnulf.queue_free()
	await get_tree().process_frame


func test_arnulf_reset_emits_ally_spawned() -> void:
	var scene: PackedScene = load("res://scenes/arnulf/arnulf.tscn")
	var arnulf: Arnulf = scene.instantiate() as Arnulf
	add_child(arnulf)
	var monitor := monitor_signals(SignalBus, false)
	arnulf.reset_for_new_mission()
	await get_tree().process_frame
	await assert_signal(monitor).is_emitted("ally_spawned", ["arnulf"])
	arnulf.queue_free()
	await get_tree().process_frame
