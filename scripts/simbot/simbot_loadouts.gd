## Named tower presets for SimBot balance sweeps (Prompt 51).
## Values are [member BuildingData.building_id] strings, not enum names.
extends Resource

const LOADOUTS: Dictionary = {
	"balanced": [
		{"building_id": "arrow_tower", "count": 4},
		{"building_id": "fire_brazier", "count": 2},
		{"building_id": "magic_obelisk", "count": 2},
		{"building_id": "poison_vat", "count": 1},
		{"building_id": "wolfden", "count": 1},
		{"building_id": "warden_shrine", "count": 1},
	],
	"summoner_heavy": [
		{"building_id": "wolfden", "count": 3},
		{"building_id": "bear_den", "count": 2},
		{"building_id": "barracks_fortress", "count": 1},
		{"building_id": "citadel_aura", "count": 1},
		{"building_id": "field_medic", "count": 1},
		{"building_id": "iron_cleric", "count": 1},
	],
	"artillery_air": [
		{"building_id": "siege_ballista", "count": 2},
		{"building_id": "fortress_cannon", "count": 1},
		{"building_id": "dragon_forge", "count": 1},
		{"building_id": "anti_air_bolt", "count": 2},
		{"building_id": "crow_roost", "count": 2},
		{"building_id": "chain_lightning", "count": 1},
	],
}


static func get_loadout(name: String) -> Array:
	var v: Variant = LOADOUTS.get(name, [])
	return v as Array
