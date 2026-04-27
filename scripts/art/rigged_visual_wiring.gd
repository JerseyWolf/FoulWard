## RiggedVisualWiring
## Paths to Blender batch GLBs (see art/generated/generation_log.json) + helpers to mount scenes.
## Visual-only: no gameplay state; used by EnemyBase, BossBase, Arnulf.

class_name RiggedVisualWiring
extends RefCounted

const ANIM_IDLE: StringName = &"idle"
const ANIM_WALK: StringName = &"walk"
const ANIM_DEATH: StringName = &"death"
const ANIM_ATTACK: StringName = &"attack"
const ANIM_HIT_REACT: StringName = &"hit_react"
const ANIM_SPAWN: StringName = &"spawn"
const ANIM_RUN: StringName = &"run"
const ANIM_ATTACK_MELEE: StringName = &"attack_melee"
const ANIM_DOWNED: StringName = &"downed"
const ANIM_RECOVERING: StringName = &"recovering"
const ANIM_SHOOT: StringName = &"shoot"
const ANIM_CAST_SPELL: StringName = &"cast_spell"
const ANIM_VICTORY: StringName = &"victory"
const ANIM_DEFEAT: StringName = &"defeat"
const ANIM_ACTIVE: StringName = &"active"
const ANIM_DESTROYED: StringName = &"destroyed"
const ANIM_PHASE_TRANSITION: StringName = &"phase_transition"

const LOC_BLEND_SEC: float = 0.12
const LOC_VELOCITY_EPSILON: float = 0.12

const ALLY_ARNULF_GLB: String = "res://art/generated/allies/arnulf.glb"

## Maps entity_id → list of [weapon_slug, bone_name] pairs for weapon attachment.
## Called after character GLB instantiation via attach_weapons().
const WEAPON_ASSIGNMENTS: Dictionary = {
	"arnulf":                [["weapon_iron_shovel",      "RightHand"]],
	"florence":              [["weapon_crossbow",          "RightHand"]],
	"sybil":                 [["weapon_stone_staff",       "RightHand"]],
	"orc_grunt":             [["weapon_iron_cleaver",      "RightHand"]],
	"orc_brute":             [["weapon_iron_maul",         "RightHand"]],
	"orc_archer":            [["weapon_bone_recurve_bow",  "RightHand"]],
	"orc_berserker":         [["weapon_dual_axes",         "RightHand"],
	                          ["weapon_dual_axes",         "LeftHand"]],
	"orc_shaman_boar_rider": [["weapon_skull_staff",       "RightHand"]],
	"herald_of_worms":       [["weapon_skull_staff",       "RightHand"]],
}


static func clear_visual_slot(visual_slot: Node3D) -> void:
	if visual_slot == null:
		return
	var kids: Array[Node] = visual_slot.get_children()
	for n: Node in kids:
		n.free()


static func find_animation_player(root: Node) -> AnimationPlayer:
	if root == null:
		return null
	return root.find_child("AnimationPlayer", true, false) as AnimationPlayer


static func enemy_rigged_glb_path(enemy_type: Types.EnemyType) -> String:
	match enemy_type:
		Types.EnemyType.ORC_GRUNT:
			return "res://art/generated/enemies/orc_grunt.glb"
		Types.EnemyType.ORC_BRUTE:
			return "res://art/generated/enemies/orc_brute.glb"
		Types.EnemyType.GOBLIN_FIREBUG:
			return "res://art/generated/enemies/goblin_firebug.glb"
		Types.EnemyType.PLAGUE_ZOMBIE:
			return "res://art/generated/enemies/plague_zombie.glb"
		Types.EnemyType.ORC_ARCHER:
			return "res://art/generated/enemies/orc_archer.glb"
		Types.EnemyType.BAT_SWARM:
			return "res://art/generated/enemies/bat_swarm.glb"
		Types.EnemyType.ORC_SKIRMISHER:
			return "res://art/generated/enemies/orc_skirmisher.glb"
		Types.EnemyType.ORC_RATLING:
			return "res://art/generated/enemies/orc_ratling.glb"
		Types.EnemyType.GOBLIN_RUNTS:
			return "res://art/generated/enemies/goblin_runts.glb"
		Types.EnemyType.HOUND:
			return "res://art/generated/enemies/hound.glb"
		Types.EnemyType.ORC_RAIDER:
			return "res://art/generated/enemies/orc_raider.glb"
		Types.EnemyType.ORC_MARKSMAN:
			return "res://art/generated/enemies/orc_marksman.glb"
		Types.EnemyType.WAR_SHAMAN:
			return "res://art/generated/enemies/war_shaman.glb"
		Types.EnemyType.PLAGUE_SHAMAN:
			return "res://art/generated/enemies/plague_shaman.glb"
		Types.EnemyType.TOTEM_CARRIER:
			return "res://art/generated/enemies/totem_carrier.glb"
		Types.EnemyType.HARPY_SCOUT:
			return "res://art/generated/enemies/harpy_scout.glb"
		Types.EnemyType.ORC_SHIELDBEARER:
			return "res://art/generated/enemies/orc_shieldbearer.glb"
		Types.EnemyType.ORC_BERSERKER:
			return "res://art/generated/enemies/orc_berserker.glb"
		Types.EnemyType.ORC_SABOTEUR:
			return "res://art/generated/enemies/orc_saboteur.glb"
		Types.EnemyType.HEXBREAKER:
			return "res://art/generated/enemies/hexbreaker.glb"
		Types.EnemyType.WYVERN_RIDER:
			return "res://art/generated/enemies/wyvern_rider.glb"
		Types.EnemyType.BROOD_CARRIER:
			return "res://art/generated/enemies/brood_carrier.glb"
		Types.EnemyType.TROLL:
			return "res://art/generated/enemies/troll.glb"
		Types.EnemyType.IRONCLAD_CRUSHER:
			return "res://art/generated/enemies/ironclad_crusher.glb"
		Types.EnemyType.ORC_OGRE:
			return "res://art/generated/enemies/orc_ogre.glb"
		Types.EnemyType.WAR_BOAR:
			return "res://art/generated/enemies/war_boar.glb"
		Types.EnemyType.ORC_SKYTHROWER:
			return "res://art/generated/enemies/orc_skythrower.glb"
		Types.EnemyType.WARLORDS_GUARD:
			return "res://art/generated/enemies/warlords_guard.glb"
		Types.EnemyType.ORCISH_SPIRIT:
			return "res://art/generated/enemies/orcish_spirit.glb"
		Types.EnemyType.PLAGUE_HERALD:
			return "res://art/generated/enemies/plague_herald.glb"
		_:
			return ""


static func boss_rigged_glb_path(boss_id: String) -> String:
	match boss_id:
		"plague_cult_miniboss":
			return "res://art/generated/bosses/plague_cult_miniboss.glb"
		"orc_warlord":
			return "res://art/generated/bosses/orc_warlord.glb"
		"final_boss":
			return "res://art/generated/bosses/final_boss.glb"
		"audit5_territory_mini":
			return "res://art/generated/bosses/audit5_territory_mini.glb"
		_:
			return ""


## Returns path to rigged ally GLB for arnulf and the four mercenary allies, or "" for unknown ids.
static func ally_rigged_glb_path(ally_id: StringName) -> String:
	match ally_id:
		&"arnulf", &"archer", &"knight", &"swordsman", &"barbarian":
			return "res://art/generated/allies/%s.glb" % String(ally_id)
		_:
			return ""


## Returns path to rigged building GLB for all 36 BuildingType values.
static func building_rigged_glb_path(building_type: Types.BuildingType) -> String:
	match building_type:
		Types.BuildingType.ARROW_TOWER:
			return "res://art/generated/buildings/arrow_tower.glb"
		Types.BuildingType.FIRE_BRAZIER:
			return "res://art/generated/buildings/fire_brazier.glb"
		Types.BuildingType.MAGIC_OBELISK:
			return "res://art/generated/buildings/magic_obelisk.glb"
		Types.BuildingType.POISON_VAT:
			return "res://art/generated/buildings/poison_vat.glb"
		Types.BuildingType.BALLISTA:
			return "res://art/generated/buildings/ballista.glb"
		Types.BuildingType.ARCHER_BARRACKS:
			return "res://art/generated/buildings/archer_barracks.glb"
		Types.BuildingType.ANTI_AIR_BOLT:
			return "res://art/generated/buildings/anti_air_bolt.glb"
		Types.BuildingType.SHIELD_GENERATOR:
			return "res://art/generated/buildings/shield_generator.glb"
		Types.BuildingType.SPIKE_SPITTER:
			return "res://art/generated/buildings/spike_spitter.glb"
		Types.BuildingType.EMBER_VENT:
			return "res://art/generated/buildings/ember_vent.glb"
		Types.BuildingType.FROST_PINGER:
			return "res://art/generated/buildings/frost_pinger.glb"
		Types.BuildingType.NETGUN:
			return "res://art/generated/buildings/netgun.glb"
		Types.BuildingType.ACID_DRIPPER:
			return "res://art/generated/buildings/acid_dripper.glb"
		Types.BuildingType.WOLFDEN:
			return "res://art/generated/buildings/wolfden.glb"
		Types.BuildingType.CROW_ROOST:
			return "res://art/generated/buildings/crow_roost.glb"
		Types.BuildingType.ALARM_TOTEMS:
			return "res://art/generated/buildings/alarm_totems.glb"
		Types.BuildingType.CROSSFIRE_NEST:
			return "res://art/generated/buildings/crossfire_nest.glb"
		Types.BuildingType.BOLT_SHRINE:
			return "res://art/generated/buildings/bolt_shrine.glb"
		Types.BuildingType.THORNWALL:
			return "res://art/generated/buildings/thornwall.glb"
		Types.BuildingType.FIELD_MEDIC:
			return "res://art/generated/buildings/field_medic.glb"
		Types.BuildingType.GREATBOW_TURRET:
			return "res://art/generated/buildings/greatbow_turret.glb"
		Types.BuildingType.MOLTEN_CASTER:
			return "res://art/generated/buildings/molten_caster.glb"
		Types.BuildingType.ARCANE_LENS:
			return "res://art/generated/buildings/arcane_lens.glb"
		Types.BuildingType.PLAGUE_MORTAR:
			return "res://art/generated/buildings/plague_mortar.glb"
		Types.BuildingType.BEAR_DEN:
			return "res://art/generated/buildings/bear_den.glb"
		Types.BuildingType.GUST_CANNON:
			return "res://art/generated/buildings/gust_cannon.glb"
		Types.BuildingType.WARDEN_SHRINE:
			return "res://art/generated/buildings/warden_shrine.glb"
		Types.BuildingType.IRON_CLERIC:
			return "res://art/generated/buildings/iron_cleric.glb"
		Types.BuildingType.SIEGE_BALLISTA:
			return "res://art/generated/buildings/siege_ballista.glb"
		Types.BuildingType.CHAIN_LIGHTNING:
			return "res://art/generated/buildings/chain_lightning.glb"
		Types.BuildingType.FORTRESS_CANNON:
			return "res://art/generated/buildings/fortress_cannon.glb"
		Types.BuildingType.DRAGON_FORGE:
			return "res://art/generated/buildings/dragon_forge.glb"
		Types.BuildingType.VOID_OBELISK:
			return "res://art/generated/buildings/void_obelisk.glb"
		Types.BuildingType.PLAGUE_CAULDRON:
			return "res://art/generated/buildings/plague_cauldron.glb"
		Types.BuildingType.BARRACKS_FORTRESS:
			return "res://art/generated/buildings/barracks_fortress.glb"
		Types.BuildingType.CITADEL_AURA:
			return "res://art/generated/buildings/citadel_aura.glb"
		_:
			return ""


## Returns path to Florence's rigged GLB.
static func tower_glb_path() -> String:
	return "res://art/characters/florence/florence.glb"


## Instances GLB PackedScene under slot; returns first AnimationPlayer in subtree, or null.
static func mount_glb_scene(visual_slot: Node3D, glb_path: String) -> AnimationPlayer:
	if visual_slot == null:
		return null
	clear_visual_slot(visual_slot)
	if glb_path.is_empty() or not ResourceLoader.exists(glb_path):
		return null
	var packed: PackedScene = load(glb_path) as PackedScene
	if packed == null:
		return null
	var inst: Node = packed.instantiate()
	visual_slot.add_child(inst)
	return find_animation_player(inst)


## Primitive MeshInstance3D fallback (e.g. bat swarm — no skeleton in batch log).
static func mount_enemy_placeholder_mesh(visual_slot: Node3D, enemy_data: EnemyData) -> void:
	if visual_slot == null or enemy_data == null:
		return
	clear_visual_slot(visual_slot)
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "PlaceholderMesh"
	mi.mesh = ArtPlaceholderHelper.get_enemy_mesh(enemy_data.enemy_type)
	mi.material_override = ArtPlaceholderHelper.get_enemy_material(enemy_data.enemy_type)
	visual_slot.add_child(mi)


static func mount_boss_placeholder_mesh(visual_slot: Node3D) -> void:
	if visual_slot == null:
		return
	clear_visual_slot(visual_slot)
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "BossPlaceholderMesh"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(1.1, 1.1, 1.1)
	mi.mesh = box
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.15, 0.65)
	mi.material_override = mat
	visual_slot.add_child(mi)


static func update_locomotion_animation(
	animation_player: AnimationPlayer,
	horizontal_speed: float,
	current_anim: StringName
) -> StringName:
	if animation_player == null:
		return current_anim
	var want: StringName = ANIM_IDLE
	if horizontal_speed > LOC_VELOCITY_EPSILON:
		if animation_player.has_animation(ANIM_WALK):
			want = ANIM_WALK
		elif animation_player.has_animation(ANIM_RUN):
			want = ANIM_RUN
		else:
			return current_anim
	else:
		want = ANIM_IDLE
	if want == current_anim:
		return current_anim
	if not animation_player.has_animation(want):
		return current_anim
	animation_player.play(want, LOC_BLEND_SEC)
	return want


## Attach all weapons defined in WEAPON_ASSIGNMENTS for the given entity_id.
## Call this after character GLB instantiation via mount_glb_scene().
## Silently skips unknown entity_ids or missing weapon GLBs (push_warning inside WeaponAttachment).
static func attach_weapons(entity_id: String, character_root: Node3D) -> void:
	if not WEAPON_ASSIGNMENTS.has(entity_id):
		return
	var pairs: Array = WEAPON_ASSIGNMENTS[entity_id]
	for pair: Array in pairs:
		var weapon_slug: String = pair[0]
		var bone_name: String = pair[1]
		WeaponAttachment.attach(character_root, weapon_slug, bone_name)
