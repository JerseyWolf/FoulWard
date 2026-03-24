PROMPT A:

You are researching Godot 4 implementation patterns for a hex grid build
system with click detection in an isometric 3D view. Godot version: 4.2+.

This research task will be used for producing an open source game, so for each research source that you will reference please add a comment about your source of knowledge so that we can properly credit the creators of the solution. 

Before you start, please make sure you have access to the following files:

Dependencies this space assumes are already done (OUTPUT_PHASE_1, OUTPUT_PHASE_2, OUTPUT_PHASE_3)

From Foundation:

    Types, SignalBus, EconomyManager, DamageCalculator

    scripts/resources/building_data.gd

    scripts/resources/research_node_data.gd

    scripts/resources/shop_item_data.gd

From Enemy+Projectile:

    scenes/projectiles/projectile_base.gd

    scenes/projectiles/projectile_base.tscn

    scenes/enemies/enemy_base.gd (for BuildingBase targeting)

    resources/enemy_data/*.tres

Upload to this space:

    Global docs:

        CONVENTIONS.md

        ARCHITECTURE.md

        PRE_GENERATION_VERIFICATION.md

    SYSTEMS:

        SYSTEMS_part2.md (HexGrid + BuildingBase)

    Foundation code:

        scripts/types.gd

        autoloads/signal_bus.gd

        autoloads/damage_calculator.gd

        autoloads/economy_manager.gd

        scripts/health_component.gd

        scripts/resources/building_data.gd

        scripts/resources/research_node_data.gd

        scripts/resources/shop_item_data.gd

    Enemy+Projectile code:

        scenes/projectiles/projectile_base.gd

        scenes/projectiles/projectile_base.tscn

        scenes/enemies/enemy_base.gd

        resources/enemy_data/*.tres


From Enemy+Projectile (OUTPUT_PHASE_2):

    scenes/enemies/enemy_base.gd

    scenes/enemies/enemy_base.tscn

    resources/enemy_data/*.tres

    Global docs:

        CONVENTIONS.md

        ARCHITECTURE.md

        PRE_GENERATION_VERIFICATION.md

    SYSTEMS:

        SYSTEMS_part1.md

        SYSTEMS_part3.md

    Foundation code:

        scripts/types.gd

        autoloads/signal_bus.gd

        autoloads/damage_calculator.gd

        autoloads/economy_manager.gd

        autoloads/game_manager.gd

        scripts/health_component.gd

        scripts/resources/enemy_data.gd

        scripts/resources/spell_data.gd

    Enemy+Projectile code:

        scenes/enemies/enemy_base.gd

        scenes/enemies/enemy_base.tscn

        resources/enemy_data/*.tres (all six enemies)

Please produce your output files in plain text as a response in this chat so that it is available in both browser and app, as attached documents would only be available in this session.

Ask any clarification questions you might have before starting your work.

Please produce your output files in plain text as a response in this chat so that it is available in both browser and app, as attached documents would only be available in this session.

RESEARCH QUESTIONS — answer all with working GDScript 4 code examples:

1. Hex grid slot layout in 3D space:
   - How to compute world-space Vector3 positions for N slots arranged
     in a ring at radius R, evenly spaced by angle = TAU / N
   - How to place Area3D nodes at computed positions to serve as
     clickable hex slots in the 3D scene

2. Mouse click detection in orthographic isometric camera in Godot 4:
   - The camera is Camera3D with projection = PROJECTION_ORTHOGRAPHIC,
     rotation_degrees = (-35.264, 45, 0), size = 40.0
   - How to raycast from mouse position to detect which Area3D hex slot
     was clicked: using get_world_3d().direct_space_state with
     PhysicsRayQueryParameters3D
   - How to set collision_layer on Area3D nodes (layer 7) and mask on
     the raycast query to only detect hex slots
   - How to get the clicked Area3D node from the raycast result

3. Area3D click detection vs Viewport input events:
   - Which approach is more reliable for orthographic 3D cameras:
     physics raycasting via InputEventMouseButton in _unhandled_input,
     or Area3D input_event signals?
   - Recommended approach with example

4. Showing/hiding mesh children of Area3D nodes:
   - How to iterate children of a node and toggle MeshInstance3D.visible
   - How to find a named child: get_node_or_null("SlotMesh")

OUTPUT FORMAT:
For each question: concise explanation + minimal GDScript 4 code example
+ Godot 4.2+ gotchas. No basics. Assume the reader knows GDScript.



PROMPT B:

Please continue your work based on the following prompt.

You are a Godot 4 GDScript code generator. Produce the HexGrid, BuildingBase,
ResearchManager, and ShopManager for FOUL WARD.

This coding task will be used for producing an open source game, so for each research source that you will reference from the previous task (research) please add a comment about your source of knowledge in the place where such info will be used so that we can properly credit the creators of the solution.

Please produce your output files in plain text as a response in this chat so that it is available in both browser and app, as attached documents would only be available in this session.

════════════════════════════════════════════
FILES TO PRODUCE (14 files)
════════════════════════════════════════════
scenes/hex_grid/hex_grid.gd
scenes/hex_grid/hex_grid.tscn
scenes/buildings/building_base.gd
scenes/buildings/building_base.tscn
scripts/research_manager.gd
scripts/shop_manager.gd
resources/building_data/arrow_tower.tres
resources/building_data/fire_brazier.tres
resources/building_data/magic_obelisk.tres
resources/building_data/poison_vat.tres
resources/building_data/ballista.tres
resources/building_data/archer_barracks.tres
resources/building_data/anti_air_bolt.tres
resources/building_data/shield_generator.tres
resources/research_data/base_structures_tree.tres
resources/shop_data/shop_catalog.tres
tests/test_hex_grid.gd
tests/test_building_base.gd
tests/test_research_manager.gd
tests/test_shop_manager.gd

════════════════════════════════════════════
DEPENDENCIES
════════════════════════════════════════════
Foundation + Enemy + Projectile modules must be complete first.
  Types, SignalBus, EconomyManager, DamageCalculator
  BuildingData, ResearchNodeData, ShopItemData (resource classes)
  ProjectileBase (class_name, scenes/projectiles/projectile_base.tscn)
  EnemyBase (class_name)

════════════════════════════════════════════
SCENE TREE CONTEXT
════════════════════════════════════════════
hex_grid.tscn:
  HexGrid (Node3D) — hex_grid.gd
  ├── HexSlot_00 (Area3D) — collision_layer = 7, one per slot
  │   ├── SlotCollision (CollisionShape3D) — BoxShape3D flat hex
  │   └── SlotMesh (MeshInstance3D) — hex outline, hidden by default
  ├── HexSlot_01 ... through HexSlot_23 (24 total)

building_base.tscn:
  BuildingBase (Node3D) — building_base.gd
  ├── BuildingMesh (MeshInstance3D) — colored cube MVP placeholder
  ├── BuildingLabel (Label3D) — shows display_name
  └── HealthComponent (Node) — health_component.gd instance

Physics layers:
  Layer 2 = Enemies | Layer 5 = Projectiles | Layer 7 = HexSlots

Scene references HexGrid uses:
  /root/Main/BuildingContainer (Node3D)
  /root/Main/ProjectileContainer (Node3D)
  /root/Main/Managers/ResearchManager (Node)  # ASSUMPTION

════════════════════════════════════════════
HEX GRID IMPLEMENTATION SPEC
════════════════════════════════════════════
class_name HexGrid, extends Node3D

@export var building_data_registry: Array[BuildingData] = []
  # Must have exactly 8 entries, one per Types.BuildingType

const BuildingScene: PackedScene = preload("res://scenes/buildings/building_base.tscn")
const RING1_COUNT: int = 6
const RING1_RADIUS: float = 6.0
const RING2_COUNT: int = 12
const RING2_RADIUS: float = 12.0
const RING3_COUNT: int = 6
const RING3_RADIUS: float = 18.0
const TOTAL_SLOTS: int = 24

var _slots: Array[Dictionary] = []
  # Each: { index: int, world_pos: Vector3, building: BuildingBase|null,
  #         is_occupied: bool }

@onready var _building_container: Node3D = get_node("/root/Main/BuildingContainer")
var _research_manager = null  # set in _ready via get_node_or_null
  # ASSUMPTION: if null (unit test), all buildings treated as unlocked

_ready():
  SignalBus.build_mode_entered.connect(_on_build_mode_entered)
  SignalBus.build_mode_exited.connect(_on_build_mode_exited)
  SignalBus.research_unlocked.connect(_on_research_unlocked)
  _research_manager = get_node_or_null("/root/Main/Managers/ResearchManager")
  assert(building_data_registry.size() == 8)
  _initialize_slots()
  _set_slots_visible(false)

Ring layout: compute positions using angle = TAU / count * i + angle_offset_rad
  Ring 1: 6 slots, radius 6.0, offset 0°
  Ring 2: 12 slots, radius 12.0, offset 0°
  Ring 3: 6 slots, radius 18.0, offset 30°
All slots at y = 0.0.
Position each HexSlot_XX Area3D child to match computed position.

Public methods (exact names — other modules depend on these):
  func place_building(slot_index: int, building_type: Types.BuildingType) -> bool
  func sell_building(slot_index: int) -> bool
  func upgrade_building(slot_index: int) -> bool
  func get_slot_data(slot_index: int) -> Dictionary
  func get_all_occupied_slots() -> Array[int]
  func get_empty_slots() -> Array[int]
  func clear_all_buildings() -> void
  func get_building_data(building_type: Types.BuildingType) -> BuildingData
  func is_building_unlocked(building_type: Types.BuildingType) -> bool
  func get_slot_position(slot_index: int) -> Vector3

place_building steps:
  1. Validate: slot_index in range, not occupied
  2. Get BuildingData from registry
  3. Check is_building_unlocked()
  4. Check EconomyManager.can_afford(gold_cost, material_cost)
  5. Spend resources (both)
  6. Instantiate BuildingScene, initialize(building_data)
  7. Set building.global_position = slot world_pos
  8. Add to _building_container, add to group "buildings"
  9. Update slot: building = instance, is_occupied = true
  10. Emit SignalBus.building_placed(slot_index, building_type)

sell_building steps:
  1. Validate: occupied
  2. Full refund: add_gold + add_building_material (base costs)
  3. If building.is_upgraded: also refund upgrade costs
  4. building.remove_from_group("buildings"), building.queue_free()
  5. Update slot: building = null, is_occupied = false
  6. Emit SignalBus.building_sold(slot_index, building_type)

is_building_unlocked:
  if not building_data.is_locked: return true
  if _research_manager == null: return true  # test context
  return _research_manager.is_unlocked(building_data.unlock_research_id)

════════════════════════════════════════════
BUILDING BASE IMPLEMENTATION SPEC
════════════════════════════════════════════
class_name BuildingBase, extends Node3D

var _building_data: BuildingData = null
var _is_upgraded: bool = false
var _attack_timer: float = 0.0
var _current_target: EnemyBase = null

const ProjectileScene: PackedScene = preload("res://scenes/projectiles/projectile_base.tscn")
@onready var _mesh: MeshInstance3D = $BuildingMesh
@onready var _label: Label3D = $BuildingLabel
@onready var _health_component: HealthComponent = $HealthComponent
@onready var _projectile_container: Node3D = get_node("/root/Main/ProjectileContainer")
  # ASSUMPTION: path matches ARCHITECTURE.md scene tree

Public methods:
  func initialize(data: BuildingData) -> void
  func upgrade() -> void
  func get_building_data() -> BuildingData
  func get_effective_damage() -> float
    # returns upgraded_damage if is_upgraded else damage
  func get_effective_range() -> float
    # returns upgraded_range if is_upgraded else attack_range

_physics_process(delta): calls _combat_process(delta)

_combat_process(delta):
  if _building_data == null: return
  if _building_data.fire_rate <= 0.0: return  # Shield Generator guard
  _attack_timer -= delta
  if _current_target == null or not is_instance_valid(_current_target):
    _current_target = _find_target()
  if _current_target == null: return
  if global_position.distance_to(_current_target.global_position) > get_effective_range():
    _current_target = _find_target()
    if _current_target == null: return
  if _attack_timer <= 0.0:
    _fire_at_target()
    _attack_timer = 1.0 / _building_data.fire_rate

_find_target():
  iterate get_tree().get_nodes_in_group("enemies")
  filter: is_instance_valid, health_component.is_alive()
  filter: respect targets_air / targets_ground flags
  return closest within get_effective_range() (CLOSEST priority for MVP)

_fire_at_target():
  var proj = ProjectileScene.instantiate() as ProjectileBase
  proj.initialize_from_building(
    get_effective_damage(),
    _building_data.damage_type,
    _building_data.fire_rate * 15.0,  # speed proxy
    global_position,
    _current_target.global_position,
    _building_data.targets_air)
  _projectile_container.add_child(proj)
  proj.add_to_group("projectiles")

Note on Archer Barracks:
  # POST-MVP: Archer Barracks spawns archer units instead of projectiles.
  # MVP stub: occupies the slot, has no combat behavior. fire_rate = 0 guard
  # prevents any firing attempt.

Note on Shield Generator:
  # POST-MVP: Shield Generator buffs adjacent buildings.
  # MVP stub: fire_rate = 0, no combat process fires. Slot occupied, no behavior.

════════════════════════════════════════════
RESEARCH MANAGER SPEC
════════════════════════════════════════════
class_name ResearchManager, extends Node

Owns which research nodes are unlocked.

@export var research_nodes: Array[ResearchNodeData] = []
  # loaded from base_structures_tree.tres

var _unlocked_nodes: Array[String] = []

Public methods:
  func unlock_node(node_id: String) -> bool
    # 1. Find node in research_nodes
    # 2. Check all prerequisite_ids are in _unlocked_nodes
    # 3. Check EconomyManager.can_afford(0, node.research_cost)
    #    (research costs research_material, not gold)
    #    → Actually: check EconomyManager.get_research_material() >= research_cost
    #    → Spend: EconomyManager.spend_research_material(research_cost)
    # 4. Add node_id to _unlocked_nodes
    # 5. Emit SignalBus.research_unlocked(node_id)
    # Return false on any validation failure
  func is_unlocked(node_id: String) -> bool
  func get_available_nodes() -> Array[ResearchNodeData]
    # Returns nodes where prereqs are met and not yet unlocked
  func reset_to_defaults() -> void
    # Clears _unlocked_nodes

base_structures_tree.tres:
  A single ResearchNodeData with:
    node_id="unlock_ballista", display_name="Ballista", research_cost=2,
    prerequisite_ids=[], description="Unlock the Ballista building"

════════════════════════════════════════════
SHOP MANAGER SPEC
════════════════════════════════════════════
class_name ShopManager, extends Node

@export var shop_catalog: Array[ShopItemData] = []

Public methods:
  func purchase_item(item_id: String) -> bool
  func get_available_items() -> Array[ShopItemData]
  func can_purchase(item_id: String) -> bool

purchase_item:
  1. Find item in shop_catalog
  2. Check EconomyManager.can_afford(item.gold_cost, item.material_cost)
  3. Spend resources
  4. Apply effect based on item_id:
    - "tower_repair": get_node("/root/Main/Tower").repair_to_full()
      # ASSUMPTION: Tower has repair_to_full() public method
    - "mana_draught": set a _mana_draught_pending flag = true
      # GameManager reads this flag when starting next mission and calls
      # SpellManager.set_mana_to_full(). Post-MVP make this cleaner.
  5. Emit SignalBus.shop_item_purchased(item_id)
  6. Return true

shop_catalog.tres includes two ShopItemData entries:
  item_id="tower_repair", display_name="Tower Repair Kit", gold_cost=75,
    material_cost=0, description="Restore tower to full HP"
  item_id="mana_draught", display_name="Mana Draught", gold_cost=50,
    material_cost=0, description="Start next mission at full mana"

════════════════════════════════════════════
BUILDING DATA .tres FILES
════════════════════════════════════════════
arrow_tower.tres: building_type=ARROW_TOWER, display_name="Arrow Tower",
  gold_cost=50, material_cost=2, upgrade_gold_cost=75, upgrade_material_cost=3,
  damage=20.0, upgraded_damage=35.0, fire_rate=1.0, attack_range=15.0,
  upgraded_range=18.0, damage_type=PHYSICAL, targets_air=false, targets_ground=true,
  is_locked=false, color=Color(0.7,0.5,0.2)

fire_brazier.tres: building_type=FIRE_BRAZIER, display_name="Fire Brazier",
  gold_cost=60, material_cost=3, upgrade_gold_cost=90, upgrade_material_cost=4,
  damage=15.0, upgraded_damage=28.0, fire_rate=0.8, attack_range=12.0,
  upgraded_range=14.0, damage_type=FIRE, targets_air=false, targets_ground=true,
  is_locked=false, color=Color(0.9,0.3,0.0)

magic_obelisk.tres: building_type=MAGIC_OBELISK, display_name="Magic Obelisk",
  gold_cost=80, material_cost=4, upgrade_gold_cost=120, upgrade_material_cost=5,
  damage=25.0, upgraded_damage=45.0, fire_rate=0.6, attack_range=18.0,
  upgraded_range=22.0, damage_type=MAGICAL, targets_air=false, targets_ground=true,
  is_locked=false, color=Color(0.5,0.0,0.8)

poison_vat.tres: building_type=POISON_VAT, display_name="Poison Vat",
  gold_cost=55, material_cost=2, upgrade_gold_cost=80, upgrade_material_cost=3,
  damage=10.0, upgraded_damage=18.0, fire_rate=1.5, attack_range=10.0,
  upgraded_range=12.0, damage_type=POISON, targets_air=false, targets_ground=true,
  is_locked=false, color=Color(0.2,0.7,0.1)

ballista.tres: building_type=BALLISTA, display_name="Ballista",
  gold_cost=100, material_cost=5, upgrade_gold_cost=150, upgrade_material_cost=6,
  damage=60.0, upgraded_damage=100.0, fire_rate=0.4, attack_range=25.0,
  upgraded_range=30.0, damage_type=PHYSICAL, targets_air=false, targets_ground=true,
  is_locked=true, unlock_research_id="unlock_ballista", color=Color(0.6,0.4,0.1)

archer_barracks.tres: building_type=ARCHER_BARRACKS, display_name="Archer Barracks",
  gold_cost=90, material_cost=4, fire_rate=0.0,  # POST-MVP stub, no firing
  damage=0.0, attack_range=0.0, damage_type=PHYSICAL,
  is_locked=false, color=Color(0.8,0.7,0.3)

anti_air_bolt.tres: building_type=ANTI_AIR_BOLT, display_name="Anti-Air Bolt",
  gold_cost=70, material_cost=3, upgrade_gold_cost=100, upgrade_material_cost=4,
  damage=30.0, upgraded_damage=50.0, fire_rate=1.2, attack_range=20.0,
  upgraded_range=24.0, damage_type=PHYSICAL, targets_air=true, targets_ground=false,
  is_locked=false, color=Color(0.2,0.5,0.9)

shield_generator.tres: building_type=SHIELD_GENERATOR, display_name="Shield Generator",
  gold_cost=120, material_cost=6, fire_rate=0.0,  # POST-MVP stub
  damage=0.0, attack_range=0.0, targets_air=false, targets_ground=false,
  is_locked=false, color=Color(0.0,0.8,0.8)

════════════════════════════════════════════
SIGNAL CONTRACT
════════════════════════════════════════════
EMITS:
  SignalBus.building_placed(slot_index, building_type)
  SignalBus.building_sold(slot_index, building_type)
  SignalBus.building_upgraded(slot_index, building_type)
  SignalBus.research_unlocked(node_id)
  SignalBus.shop_item_purchased(item_id)

RECEIVES:
  SignalBus.build_mode_entered → HexGrid show slot meshes
  SignalBus.build_mode_exited → HexGrid hide slot meshes
  SignalBus.research_unlocked → HexGrid refresh building availability cache

════════════════════════════════════════════
INTEGRATION ASSUMPTIONS
════════════════════════════════════════════
# ASSUMPTION: ProjectileBase instantiable at res://scenes/projectiles/projectile_base.tscn
#   with initialize_from_building(damage, damage_type, speed, origin, target, air_only).
# ASSUMPTION: BuildingContainer at /root/Main/BuildingContainer.
# ASSUMPTION: ProjectileContainer at /root/Main/ProjectileContainer.
# ASSUMPTION: EnemyBase has get_enemy_data() -> EnemyData and
#   _health_component: HealthComponent.
# ASSUMPTION: ResearchManager at /root/Main/Managers/ResearchManager.
#   If null (unit tests), all buildings treated as unlocked.
# ASSUMPTION: Tower has repair_to_full() for shop Tower Repair Kit.
# ASSUMPTION: SpellManager has set_mana_to_full() for Mana Draught.

════════════════════════════════════════════
CODING CONVENTIONS (MANDATORY)
════════════════════════════════════════════
- Files: snake_case.gd | class_name: PascalCase | vars/funcs: snake_case
- Constants: UPPER_SNAKE_CASE | private: prefix with _
- ALL cross-system signals through SignalBus ONLY
- Never cache autoloads
- assert() for programmer errors | null-check runtime references
- is_instance_valid() for enemies that may be freed mid-frame
- Tags: # ASSUMPTION | # DEVIATION | # POST-MVP

════════════════════════════════════════════
GdUnit4 TESTS — EXHAUSTIVE (key cases)
════════════════════════════════════════════
HexGrid:
  test_initialize_creates_24_slots
  test_all_slots_start_unoccupied
  test_slot_ring1_at_correct_radius (distance ≈ 6.0)
  test_slot_ring2_at_correct_radius (distance ≈ 12.0)
  test_slot_ring3_at_correct_radius (distance ≈ 18.0)
  test_place_building_on_empty_slot_succeeds
  test_place_building_deducts_resources
  test_place_building_emits_building_placed
  test_place_building_on_occupied_slot_fails
  test_place_building_insufficient_gold_fails
  test_place_locked_building_without_research_fails
  test_sell_building_full_refund
  test_sell_upgraded_building_refunds_both_costs
  test_sell_empty_slot_fails
  test_upgrade_building_succeeds
  test_upgrade_already_upgraded_fails
  test_upgrade_emits_building_upgraded

BuildingBase:
  test_initialize_sets_data
  test_find_target_returns_closest_in_range
  test_find_target_skips_flying_for_ground_building
  test_find_target_returns_null_when_no_enemies
  test_combat_process_fires_after_cooldown
  test_combat_process_skips_when_fire_rate_zero (Shield Generator guard)
  test_upgrade_sets_is_upgraded_true
  test_get_effective_damage_returns_upgraded_when_upgraded
  test_get_effective_range_returns_upgraded_when_upgraded
  test_anti_air_bolt_only_targets_flying

ResearchManager:
  test_unlock_node_spends_research_material
  test_unlock_node_emits_research_unlocked
  test_unlock_node_fails_when_prereq_not_met
  test_unlock_node_fails_insufficient_material
  test_is_unlocked_returns_false_before_unlock
  test_is_unlocked_returns_true_after_unlock
  test_get_available_nodes_excludes_already_unlocked
  test_reset_clears_all_unlocks

ShopManager:
  test_purchase_item_deducts_gold
  test_purchase_item_insufficient_gold_fails
  test_purchase_item_emits_shop_item_purchased
  test_purchase_tower_repair_calls_repair_to_full
  test_purchase_mana_draught_sets_pending_flag
  test_can_purchase_returns_false_when_insufficient_gold

════════════════════════════════════════════
OUTPUT FORMAT
════════════════════════════════════════════
Produce each file as a complete, runnable GDScript block labeled with its path.
Produce all 20 files. Do not truncate any file.




THIS IS WHAT CLAUDE USED FOR THIS:


I am building a game called Foul Ward — a medieval fantasy tower defense game in
Godot 4 using GDScript. I have attached two documents:

- FoulWard_GameDesignDocument.md — full game design reference
- FoulWard_MVP_Specification.md — the MVP technical specification for the first
  playable prototype

Your job in this session is to produce a complete planning package that will drive
all subsequent development. Please read both documents fully before producing anything.

---

WHAT I NEED YOU TO PRODUCE

OUTPUT 1 — Three Architecture Documents

Produce the following three documents. These will be fed as system context to every
AI coding session that follows, so they must be precise, unambiguous, and complete.

ARCHITECTURE.md:
- Full Godot 4 scene tree with every node, its type, and its parent
- Class responsibilities for every script (one paragraph per class)
- Complete signal flow diagram in text form: which node emits which signal,
  which node receives it, and what it triggers
- Data flow for every system listed in the MVP spec under "Key Systems to Architect"
- All @export variable names with their types and default values
- All resource types (custom Resources) needed
- Any autoload singletons and their global access names
- A dedicated section: "Simulation Testing Design" — documenting which public methods
  each manager exposes for headless bot access, and flagging any design that would
  prevent a bot from driving the game loop without UI or input handling

CONVENTIONS.md:
This document will be prepended to every Perplexity Pro code generation prompt
and every Cursor session. It must be strict and specific enough that two separate
AI instances starting independently will produce code that integrates without
naming conflicts. Include:
- Exact naming conventions: classes, variables, signals, constants, file names
- ALL shared variable names and types that cross module boundaries
  (e.g., the exact variable name EconomyManager uses for gold so every module
  that touches gold uses the same name)
- Signal naming conventions and payload structures
- How to handle null checks and error states
- Scene instantiation patterns (preload vs load, when to use each)
- How nodes reference each other (never string paths — only typed variables)
- Autoload access patterns
- GdUnit4 test file naming and structure conventions
- Comment style requirements
- How @export variables must be documented inline
- Credit comment format for any code adapted from external sources:
    # ============================================================
    # Credit: [Project Name]
    # Source: [Full URL]
    # License: [License type]
    # Adapted by: Foul Ward team
    # What was used: [Brief description of what was taken/adapted]
    # ============================================================

SYSTEMS.md:
Detailed pseudocode specification for each of the key systems from the MVP spec.
For each system include:
- Full method signatures with parameter names, types, and return types
- All signals emitted by the system with payload types
- All signals consumed by the system
- Step-by-step pseudocode in GDScript style (not runnable, but close to it)
- Edge cases and how to handle them
- GdUnit4 test case specifications: test name, setup, action, assertion, teardown
  Include as many tests as you can think of, even seemingly trivial ones.
  More coverage is always better. Maximum observability is the goal.

---

OUTPUT 2 — Parallel Code Generation Workstreams

Split the entire MVP codebase into as many independent modules as makes sense so
that multiple Perplexity Pro instances can generate code in parallel without
blocking each other. Use your own judgment — if you see a better split than what
the spec implies, override it and explain why.

Deciding whether a module needs a Research Phase:

For each module, decide independently:
- If it involves a known complex problem with established community solutions
  (pathfinding, hex grids, state machines, projectile physics, radial UI, etc.)
  produce TWO prompts: Prompt A (Deep Research) + Prompt B (Code Generation)
- If it is straightforward arithmetic, signal wiring, or simple state management
  produce ONE prompt only, with a one-line note explaining why research was skipped

For modules that get TWO prompts:

Prompt A — Perplexity Deep Research:
- Instructs Perplexity to use Deep Research mode
- Asks it to find existing open-source Godot 4 GDScript implementations that solve
  this specific problem — prioritize confirmed-working, community-validated solutions
- Asks it to document: what it found, what it does, what needs adapting for Foul Ward,
  and any known issues or limitations
- If a solution can be mostly or entirely copied with minimal adaptation, Perplexity
  must prepare the full attribution block to paste at the top of the generated file:
    # ============================================================
    # Credit: [Project Name]
    # Source: [Full URL]
    # License: [License type]
    # Adapted by: Foul Ward team
    # What was used: [Brief description of what was taken/adapted]
    # ============================================================
- Ends with: "Paste your complete research findings as the first message in your
  next Perplexity Pro chat, then paste Prompt B below it."

Prompt B — Perplexity Code Generation:
- Opens with: "Your first message contains research findings. Use them as your
  primary reference. If the research found a usable existing solution, build from
  it rather than writing from scratch. Include the credit block at the top of any
  file where external code was used or substantially adapted."
- CONVENTIONS.md pasted in full — Perplexity must treat it as law
- Only the SYSTEMS.md sections relevant to this module
- Only the ARCHITECTURE.md sections relevant to this module
- Exact filenames this module must produce
- The integration contract: signals/variables this module emits that others depend on
- Signals/variables this module receives from other modules
- Instructions to write GdUnit4 tests for every method, including trivial ones
- Instructions to add inline comments explaining WHY, not just what
- Instructions to flag every assumption about another module:
  # ASSUMPTION: [what it assumes] — so Cursor can verify during integration
- Ends with: "If you have ideas that improve on this specification, implement your
  improvement but leave a comment # DEVIATION: [reason] so the team can review it"

For single-prompt modules:
- Same structure as Prompt B, minus the research reference opening
- Credit comment format still included via CONVENTIONS.md
