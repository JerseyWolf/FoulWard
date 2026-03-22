# test_spell_manager.gd
# GdUnit4 test suite for SpellManager.
# Covers: mana regen, signal gating, cast validation, cooldowns, shockwave AoE.
#
# Credit: Foul Ward SYSTEMS_part3.md §9.8 (GdUnit4 test specifications)
# Credit: GdUnit4 documentation — https://mikeschulze.github.io/gdUnit4/ — MIT License

class_name TestSpellManager
extends GdUnitTestSuite

var _spell_manager: SpellManager


func _build_spell_manager() -> SpellManager:
	var sm: SpellManager = SpellManager.new()
	sm.max_mana = 100
	sm.mana_regen_rate = 5.0
	sm.spell_registry = [_build_shockwave_data()]
	add_child(sm)
	return sm


func _build_shockwave_data() -> SpellData:
	var sd: SpellData = SpellData.new()
	sd.spell_id = "shockwave"
	sd.display_name = "Shockwave"
	sd.mana_cost = 50
	sd.cooldown = 60.0
	sd.damage = 30.0
	sd.radius = 100.0
	sd.damage_type = Types.DamageType.MAGICAL
	sd.hits_flying = false
	return sd


func _spawn_enemy(is_flying: bool, armor_type: Types.ArmorType,
		immunities: Array[Types.DamageType] = []) -> EnemyBase:
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var enemy: EnemyBase = enemy_scene.instantiate() as EnemyBase

	var d: EnemyData = EnemyData.new()
	d.enemy_type = Types.EnemyType.ORC_GRUNT
	d.max_hp = 200
	d.move_speed = 1.0
	d.damage = 5
	d.attack_range = 1.5
	d.attack_cooldown = 1.0
	d.armor_type = armor_type
	d.gold_reward = 5
	d.is_flying = is_flying
	d.is_ranged = false
	d.damage_immunities = immunities

	add_child(enemy)
	enemy.initialize(d)
	enemy.add_to_group("enemies")
	return enemy

# ---------------------------------------------------------------------------
# SETUP / TEARDOWN
# ---------------------------------------------------------------------------

func before_each() -> void:
	_spell_manager = _build_spell_manager()


func after_each() -> void:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		node.remove_from_group("enemies")
		if is_instance_valid(node):
			node.queue_free()
	if is_instance_valid(_spell_manager):
		_spell_manager.queue_free()
	await get_tree().process_frame

# ---------------------------------------------------------------------------
# TEST: Cast validation — insufficient mana
# ---------------------------------------------------------------------------

func test_cast_spell_insufficient_mana_returns_false() -> void:
	assert_that(_spell_manager.get_current_mana()).is_equal(0)

	var result: bool = _spell_manager.cast_spell("shockwave")

	assert_that(result).is_false()
	assert_that(_spell_manager.get_current_mana()).is_equal(0)

# ---------------------------------------------------------------------------
# TEST: Cast validation — on cooldown
# ---------------------------------------------------------------------------

func test_cast_spell_on_cooldown_returns_false() -> void:
	_spell_manager.set_mana_to_full()
	var first_cast: bool = _spell_manager.cast_spell("shockwave")
	assert_that(first_cast).is_true()

	_spell_manager.set_mana_to_full()

	var second_cast: bool = _spell_manager.cast_spell("shockwave")

	assert_that(second_cast).is_false()

# ---------------------------------------------------------------------------
# TEST: Cast deducts mana
# ---------------------------------------------------------------------------

func test_cast_spell_deducts_mana() -> void:
	_spell_manager.set_mana_to_full()
	assert_that(_spell_manager.get_current_mana()).is_equal(100)

	_spell_manager.cast_spell("shockwave")

	assert_that(_spell_manager.get_current_mana()).is_equal(50)

# ---------------------------------------------------------------------------
# TEST: Cast starts cooldown
# ---------------------------------------------------------------------------

func test_cast_spell_starts_cooldown() -> void:
	_spell_manager.set_mana_to_full()

	_spell_manager.cast_spell("shockwave")

	assert_float(_spell_manager.get_cooldown_remaining("shockwave")).is_greater(0.0)

# ---------------------------------------------------------------------------
# TEST: Cast emits spell_cast signal
# ---------------------------------------------------------------------------

func test_cast_spell_emits_spell_cast_signal() -> void:
	_spell_manager.set_mana_to_full()
	var monitor := monitor_signals(SignalBus)

	_spell_manager.cast_spell("shockwave")

	assert_signal(monitor).is_emitted(SignalBus, "spell_cast")

# ---------------------------------------------------------------------------
# TEST: Mana regen increases mana over time
# ---------------------------------------------------------------------------

func test_mana_regen_increases_mana_over_time() -> void:
	assert_that(_spell_manager.get_current_mana()).is_equal(0)

	# 5.0 mana/sec × 4 sec = 20 mana.
	_spell_manager._tick_mana_regen(4.0)

	assert_that(_spell_manager.get_current_mana()).is_equal(20)

# ---------------------------------------------------------------------------
# TEST: Mana capped at max
# ---------------------------------------------------------------------------

func test_mana_capped_at_max() -> void:
	_spell_manager._tick_mana_regen(100.0)

	assert_that(_spell_manager.get_current_mana()).is_equal(100)

# ---------------------------------------------------------------------------
# TEST: mana_changed signal only fires on integer change
# ---------------------------------------------------------------------------

func test_mana_changed_signal_only_on_integer_change() -> void:
	var monitor := monitor_signals(SignalBus)

	# 10 × 0.016 δ × 5 regen = 0.8 mana → int still 0 → NO signal.
	for _i: int in range(10):
		_spell_manager._tick_mana_regen(0.016)

	assert_signal(monitor).is_not_emitted(SignalBus, "mana_changed")

	# 1 full second at 5/sec = +5 mana → integer crosses 0 → signal fires.
	_spell_manager._tick_mana_regen(1.0)

	assert_signal(monitor).is_emitted(SignalBus, "mana_changed")

# ---------------------------------------------------------------------------
# TEST: Cooldown decrements with delta
# ---------------------------------------------------------------------------

func test_cooldown_decrements_with_delta() -> void:
	_spell_manager.set_mana_to_full()
	_spell_manager.cast_spell("shockwave")
	var initial_cd: float = _spell_manager.get_cooldown_remaining("shockwave")
	assert_float(initial_cd).is_greater(0.0)

	_spell_manager._tick_cooldowns(10.0)

	assert_float(_spell_manager.get_cooldown_remaining("shockwave")).is_equal(
		initial_cd - 10.0
	)

# ---------------------------------------------------------------------------
# TEST: spell_ready signal on cooldown expiry
# ---------------------------------------------------------------------------

func test_spell_ready_signal_on_cooldown_expiry() -> void:
	_spell_manager.set_mana_to_full()
	_spell_manager.cast_spell("shockwave")
	var monitor := monitor_signals(SignalBus)

	_spell_manager._tick_cooldowns(61.0)

	assert_signal(monitor).is_emitted(SignalBus, "spell_ready")
	assert_float(_spell_manager.get_cooldown_remaining("shockwave")).is_equal(0.0)

# ---------------------------------------------------------------------------
# TEST: Shockwave hits ground enemies
# ---------------------------------------------------------------------------

func test_shockwave_hits_ground_enemies() -> void:
	# MAGICAL vs UNARMORED = 1.0x → 30 damage. HP: 200 → 170.
	var enemies: Array[EnemyBase] = []
	for _i: int in range(3):
		enemies.append(_spawn_enemy(false, Types.ArmorType.UNARMORED))

	_spell_manager.set_mana_to_full()
	_spell_manager.cast_spell("shockwave")
	await get_tree().process_frame

	for enemy: EnemyBase in enemies:
		if is_instance_valid(enemy):
			assert_that(enemy.health_component.get_current_hp()).is_equal(200 - 30)

# ---------------------------------------------------------------------------
# TEST: Shockwave skips flying enemies
# ---------------------------------------------------------------------------

func test_shockwave_skips_flying_enemies() -> void:
	var flying_enemy: EnemyBase = _spawn_enemy(true, Types.ArmorType.FLYING)
	var initial_hp: int = flying_enemy.health_component.get_current_hp()

	_spell_manager.set_mana_to_full()
	_spell_manager.cast_spell("shockwave")
	await get_tree().process_frame

	assert_that(flying_enemy.health_component.get_current_hp()).is_equal(initial_hp)

# ---------------------------------------------------------------------------
# TEST: Shockwave respects damage immunity
# ---------------------------------------------------------------------------

func test_shockwave_respects_damage_immunity() -> void:
	var immunities: Array[Types.DamageType] = [Types.DamageType.MAGICAL]
	var immune_enemy: EnemyBase = _spawn_enemy(
		false, Types.ArmorType.UNARMORED, immunities
	)
	var initial_hp: int = immune_enemy.health_component.get_current_hp()

	_spell_manager.set_mana_to_full()
	_spell_manager.cast_spell("shockwave")
	await get_tree().process_frame

	assert_that(immune_enemy.health_component.get_current_hp()).is_equal(initial_hp)

# ---------------------------------------------------------------------------
# TEST: set_mana_to_full
# ---------------------------------------------------------------------------

func test_set_mana_to_full_sets_max() -> void:
	assert_that(_spell_manager.get_current_mana()).is_equal(0)
	var monitor := monitor_signals(SignalBus)

	_spell_manager.set_mana_to_full()

	assert_that(_spell_manager.get_current_mana()).is_equal(_spell_manager.max_mana)
	assert_signal(monitor).is_emitted(SignalBus, "mana_changed")

