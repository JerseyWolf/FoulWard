## test_world_map_ui.gd
## WorldMap presenter reacts to territory_state_changed.

class_name TestWorldMapUi
extends GdUnitTestSuite

# Manual QA checklist (play in editor):
# 1) Start new game, win day 1, open Between Mission → World Map tab; Heartland shows (Held).
# 2) Lose a mission on a new run; territory for that day shows (Lost) and bonuses drop in next win.
# 3) Advance several days in a 50-day campaign build and confirm day label and territory bands.

func test_world_map_updates_ownership_visual_on_state_change() -> void:
	var scene: PackedScene = load("res://ui/world_map.tscn") as PackedScene
	var world_map: WorldMap = scene.instantiate() as WorldMap
	add_child(world_map)

	var tmap: TerritoryMapData = load(
		"res://resources/territories/main_campaign_territories.tres"
	) as TerritoryMapData
	GameManager.territory_map = tmap

	var territory: TerritoryData = tmap.get_territory_by_id("blackwood_forest")
	assert_object(territory).is_not_null()
	territory.is_controlled_by_player = false
	territory.is_permanently_lost = false

	world_map._build_territory_buttons()

	territory.is_controlled_by_player = true
	SignalBus.territory_state_changed.emit("blackwood_forest")
	await get_tree().process_frame

	var found: bool = false
	for child: Node in world_map.territory_buttons_container.get_children():
		if child is Button:
			var b: Button = child as Button
			if b.text.contains("Blackwood") and b.text.contains("(Held)"):
				found = true
				break
	assert_bool(found).is_true()

	world_map.queue_free()
