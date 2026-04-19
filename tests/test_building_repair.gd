## test_building_repair.gd
## GdUnit4 tests for the building_repair shop item logic:
##   HexGrid.get_lowest_hp_pct_building() targeting and 50%-heal dispatch.

class_name TestBuildingRepair
extends GdUnitTestSuite

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Builds a minimal BuildingBase with a live HealthComponent.
## The building is NOT added to the scene tree or a HexGrid — callers do that.
func _make_building_with_hp(max_hp: int, current_hp: int, targetable: bool = true) -> BuildingBase:
	var bd: BuildingData = BuildingData.new()
	bd.building_type = Types.BuildingType.ARROW_TOWER
	bd.display_name = "TestBuilding"
	bd.gold_cost = 50
	bd.material_cost = 2
	bd.upgrade_gold_cost = 75
	bd.upgrade_material_cost = 3
	bd.damage = 10.0
	bd.upgraded_damage = 20.0
	bd.fire_rate = 0.0
	bd.attack_range = 10.0
	bd.upgraded_range = 12.0
	bd.max_hp = max_hp
	bd.can_be_targeted_by_enemies = targetable

	var b: BuildingBase = BuildingBase.new()
	b._building_data = bd

	var hc: HealthComponent = HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_hp = max_hp
	hc.current_hp = current_hp
	b.add_child(hc)
	b.health_component = hc

	return b


## Builds a minimal HexGrid with _slots pre-populated from the given buildings array.
## Each building occupies a consecutive slot starting at 0.
## The buildings must already have HealthComponents attached.
func _make_hex_with_buildings(buildings: Array[BuildingBase]) -> HexGrid:
	var hex: HexGrid = HexGrid.new()
	var slots: Array[Dictionary] = []
	for i: int in range(buildings.size()):
		var b: BuildingBase = buildings[i]
		slots.append({
			"index": i,
			"world_pos": Vector3.ZERO,
			"building": b,
			"is_occupied": true,
			"soft_blocker_count": 0,
		})
	# Fill remaining slots as empty (get_lowest_hp_pct_building iterates _slots)
	for _j: int in range(42 - buildings.size()):
		slots.append({
			"index": buildings.size() + _j,
			"world_pos": Vector3.ZERO,
			"building": null,
			"is_occupied": false,
			"soft_blocker_count": 0,
		})
	hex._slots = slots
	return hex


var _cleanup_nodes: Array[Node] = []


func after_test() -> void:
	for n: Node in _cleanup_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_cleanup_nodes.clear()
	await get_tree().process_frame


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_repair_targets_lowest_hp_pct_not_lowest_absolute() -> void:
	# A: 300 / 400 = 75 %,  B: 160 / 200 = 80 %,  C: 60 / 100 = 60 %  → expect C
	var a: BuildingBase = _make_building_with_hp(400, 300)
	var b: BuildingBase = _make_building_with_hp(200, 160)
	var c: BuildingBase = _make_building_with_hp(100, 60)
	_cleanup_nodes.append(a)
	_cleanup_nodes.append(b)
	_cleanup_nodes.append(c)

	var buildings: Array[BuildingBase] = [a, b, c]
	var hex: HexGrid = _make_hex_with_buildings(buildings)
	_cleanup_nodes.append(hex)

	var result: BuildingBase = hex.get_lowest_hp_pct_building()
	assert_object(result).is_not_null()
	assert_object(result).is_equal(c)


func test_repair_restores_50_pct() -> void:
	# Building at 25 % HP; after repair it should be at 75 % (25 % + 50 %).
	var building: BuildingBase = _make_building_with_hp(200, 50)  # 25 %
	_cleanup_nodes.append(building)

	var hc: HealthComponent = building.get_node_or_null("HealthComponent") as HealthComponent
	assert_object(hc).is_not_null()

	var heal_amount: int = maxi(1, int(float(hc.max_hp) * 0.5))  # 100
	hc.heal(heal_amount)

	assert_int(hc.current_hp).is_equal(150)  # 50 + 100


func test_repair_blocked_when_no_damaged_building() -> void:
	# All buildings at full HP → get_lowest_hp_pct_building returns null.
	var a: BuildingBase = _make_building_with_hp(100, 100)
	var b_node: BuildingBase = _make_building_with_hp(200, 200)
	_cleanup_nodes.append(a)
	_cleanup_nodes.append(b_node)

	var buildings: Array[BuildingBase] = [a, b_node]
	var hex: HexGrid = _make_hex_with_buildings(buildings)
	_cleanup_nodes.append(hex)

	var result: BuildingBase = hex.get_lowest_hp_pct_building()
	assert_object(result).is_null()


func test_repair_ignores_indestructible_buildings() -> void:
	# Buildings with max_hp = 0 have no HealthComponent → ignored by get_lowest_hp_pct_building.
	var indestructible: BuildingBase = BuildingBase.new()
	var bd: BuildingData = BuildingData.new()
	bd.building_type = Types.BuildingType.ARROW_TOWER
	bd.display_name = "Indestructible"
	bd.max_hp = 0  # no HC added
	indestructible._building_data = bd
	_cleanup_nodes.append(indestructible)

	# Also add a properly damaged building that HAS an HC — it must be chosen
	var damagedBuilding: BuildingBase = _make_building_with_hp(100, 50)
	_cleanup_nodes.append(damagedBuilding)

	var buildings: Array[BuildingBase] = [indestructible, damagedBuilding]
	var hex: HexGrid = _make_hex_with_buildings(buildings)
	_cleanup_nodes.append(hex)

	var result: BuildingBase = hex.get_lowest_hp_pct_building()
	# Should return the damaged building, not the indestructible one
	assert_object(result).is_not_null()
	assert_object(result).is_equal(damagedBuilding)
