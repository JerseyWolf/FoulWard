# Foul Ward — Implementation Prompt Package

**Generated:** 2026-04-16
**Source plan:** `perplexity_sessions_implementation_bf787700.plan.md`
**Perplexity source:** `docs/perplexity_sessions/MASTER_PERPLEXITY_OUTPUT.txt`

## How to Use This Document

Each numbered section below is a **ready-to-paste prompt** for a separate Cursor chat session. Open a new Cursor Agent chat, paste the prompt, and let the agent work.

### Ordering Rules

- Groups must be executed **in numerical order** (GROUP 4 before GROUP 5, etc.)
- Chat sessions within a group (e.g. 4A, 4B) must be executed **sequentially**
- Do NOT skip groups — cumulative signal counts and autoload order depend on prior groups

### Pre-Session Checklist (for every chat)

1. Ensure the previous group's changes are committed or at least saved
2. Run `./tools/run_gdunit_quick.sh` to confirm no regressions from prior session

### Recommended Models

| Chat Type | Recommended Model |
|---|---|
| Enum + signal + small edits (2A, 4A, 6A, 8A) | Sonnet 4.6 |
| Manager/autoload implementation (6B, 7B, 8B) | Opus 4.6 |
| UI scene creation (2B, 4B, 7C, 8C) | Sonnet 4.6 |
| Data-heavy .tres authoring (1A, 3C) | Opus 4.6 |
| Destruction / enemy logic (3B) | Opus 4.6 |
| Art pipeline reports (5A) | Sonnet 4.6 |
| Dialogue content (9A) | Sonnet 4.6 |
| Tests (test-heavy chats: 1B, 3C, 5C, 6C, 7C, 8C, 9C, 10B) | Sonnet 4.6 |
| Reconciliation (11A) | Opus 4.6 |

### Baseline State (before GROUP 1)

- SignalBus signals: **67**
- Autoloads: **17** (per AGENTS.md Init order)
- GdUnit4 tests: **612** across 75 test files
- GameState last value: `ENDLESS = 10`
- HexGrid `TOTAL_SLOTS` = 24
- No `GraphicsQuality`, `DifficultyTier`, `ChronicleRewardType`, or `ChroniclePerkEffectType` enums
- No `starting_gold` on DayConfig, no `max_hp` on BuildingData, no `highest_cleared_tier` on TerritoryData
- `graphics_quality` is a `String` in SettingsManager, not an enum

### Note on Groups 1-3 Prior Work

Groups 1-3 were **partially implemented in an earlier agent session** before the prompt package was produced. Run the prompts below in their own chats as if from scratch — the agents should:
1. Detect work already on disk and diff it against the spec
2. Complete anything missing
3. Fix anything that deviates
4. Run tests and verify the cumulative state

If a file is already correct, the agent should confirm it and move on. This is the standard agent behaviour for any re-run.

---
---

## GROUP 1: S01 — 50-Day Campaign Content (2 chats)

---

### CHAT 1A — DayConfig field + 50-day table

```
@AGENTS.md @.cursor/skills/campaign-and-progression/SKILL.md @.cursor/skills/add-new-entity/SKILL.md

You are implementing the 50-day campaign content for Foul Ward.

CUMULATIVE STATE:
- SignalBus: 67 signals (unchanged this chat)
- 17 autoloads (unchanged)
- No new signals, no new enums, no new autoloads this session

TASK OVERVIEW:
Add a starting_gold field to DayConfig, then replace all 50 DayConfig sub-resources in the campaign .tres with the full authored table.

Sources of truth:
- Per-day table with faction, territory, mini-boss, boss_id, wave count, and all multipliers is in docs/perplexity_sessions/MASTER_PERPLEXITY_OUTPUT.txt, Session 1 (lines ~73-127).
- Sample sub-resource blocks for days 1, 10, 25, 40, 50 are in the same file (lines ~130-222).

---

STEP 1 — Add starting_gold field to DayConfig
File: scripts/resources/day_config.gd

Add field after spawn_count_multiplier:
  ## TUNING: gold player starts this mission with. Linear 1000→1500 over 50 days.
  ## NOTE: if MissionEconomyData.starting_gold exists, defer to that, remove this.
  @export var starting_gold: int = 1000

Constraints:
- Static typing. No magic numbers.
- Do NOT modify any other field or method.
- Do NOT change class_name, extends, or any existing field.

Verify: field appears in Godot inspector on a DayConfig resource.

---

STEP 2 — Replace all 50 DayConfig sub-resources
File: resources/campaigns/campaign_main_50_days.tres

Replace every [sub_resource type="Resource" id="DayConfig_N"] block (days 1-50) with values from the Session 1 table.

Rules:
- Every DayConfig block MUST include all fields shown in the sample blocks (Session 1, lines ~130-222).
- display_name = "Day N" (N = day_index).
- description = "Placeholder briefing."
- is_mini_boss = same value as is_mini_boss_day (both fields must match).
- boss_id = "" when no boss, exact string from table when boss present.
- Float values: 4 decimal places max.
- Keep ext_resource declarations and [resource] footer unchanged.
- Keep existing id format: id="DayConfig_N".

Mini-boss / final-boss days (from table):
- Day 10: is_mini_boss_day=true, boss_id="orc_warlord"
- Day 20: is_mini_boss_day=true, boss_id="plague_cult_miniboss"
- Day 30: is_mini_boss_day=true, boss_id="orc_warlord"
- Day 40: is_mini_boss_day=true, boss_id="plague_cult_miniboss"
- Day 50: is_mini_boss_day=false, is_final_boss=true, boss_id="final_boss"

Scaling formulas (for spot-checking):
  t = (day_index - 1) / 49.0
  enemy_hp_multiplier = enemy_damage_multiplier = 1.0 + 2.0 * smoothstep(t)   (smoothstep = t*t*(3-2t))
  gold_reward_multiplier = 1.0 + 0.5 * t
  spawn_count_multiplier = 1.0 + 1.5 * t
  starting_gold = 1000 + floor((day-1) * 500 / 49)
  base_wave_count = 3 for days 1-10, 4 for days 11-30, 5 for days 31-50

Faction rotation rule: from day 11 onward, no single faction may run >5 consecutive days. Days 1-10 all use DEFAULT_MIXED by design.

---

VERIFICATION:
- Godot editor loads the campaign .tres without errors
- ./tools/run_gdunit_quick.sh passes (existing tests only — new tests come in Chat 1B)
```

---

### CHAT 1B — Tests + doc sync

```
@AGENTS.md @.cursor/skills/testing/SKILL.md @.cursor/skills/campaign-and-progression/SKILL.md

You are writing validation tests for the 50-day campaign content.

PREREQUISITE: Chat 1A changes must be present (DayConfig.starting_gold field + updated campaign_main_50_days.tres).

CUMULATIVE STATE:
- SignalBus: 67 signals (unchanged)
- 17 autoloads (unchanged)

---

STEP 1 — Test suite
Create tests/test_campaign_config.gd (GdUnit4, extends GdUnitTestSuite):

Load the campaign resource once in before_test() / via const:
  const CAMPAIGN_PATH: String = "res://resources/campaigns/campaign_main_50_days.tres"
  var _days: Array  # 50 DayConfig resources

Tests to implement:

  test_campaign_loads_successfully
    → resource not null, _days.size() == 50

  test_all_days_have_faction_id
    → for every day, faction_id != ""

  test_all_days_have_territory_id
    → for every day, territory_id != ""

  test_mini_boss_days
    → days 10, 20, 30, 40 (array index 9, 19, 29, 39) have is_mini_boss_day == true
    → all other days have is_mini_boss_day == false
    → is_mini_boss == is_mini_boss_day for every day

  test_boss_ids
    → day 10 boss_id == "orc_warlord"
    → day 20 boss_id == "plague_cult_miniboss"
    → day 30 boss_id == "orc_warlord"
    → day 40 boss_id == "plague_cult_miniboss"
    → day 50 boss_id == "final_boss"
    → days without a boss have boss_id == ""

  test_final_boss_day
    → day 50 is_final_boss == true
    → all other days is_final_boss == false

  test_wave_counts
    → days 1-10: base_wave_count == 3
    → days 11-30: base_wave_count == 4
    → days 31-50: base_wave_count == 5

  test_multiplier_endpoints
    → day 1:  enemy_hp_multiplier ≈ 1.0,  gold_reward_multiplier ≈ 1.0,  spawn_count_multiplier ≈ 1.0
    → day 50: enemy_hp_multiplier ≈ 3.0,  gold_reward_multiplier ≈ 1.5,  spawn_count_multiplier ≈ 2.5
    (use an epsilon-based float comparison, e.g. 1e-3)

  test_starting_gold_range
    → day 1 starting_gold == 1000
    → day 50 starting_gold == 1500

  test_starting_gold_monotonic
    → for i in 1..49: starting_gold[i] >= starting_gold[i-1]

  test_no_faction_run_exceeds_5
    → Iterate from day 11 (array index 10) to day 50
    → Track current faction run length
    → Assert max run ≤ 5
    → (Days 1-10 intentionally use DEFAULT_MIXED for 10 consecutive days — exclude from this check.)

---

STEP 2 — Doc sync
Update test count in:
  - AGENTS.md: "612 GdUnit4 tests" → new number
  - docs/FOUL_WARD_MASTER_DOC.md §1 if it tracks test count
  - docs/PERPLEXITY_RECONCILIATION_TRACKER.md "Test Count — Cumulative Log" G1 row: fill in Actual

---

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes OR the new test suite runs directly via Godot binary if the quick runner uses an allowlist
- All ~10 new tests pass
- Signal count unchanged (67)
```

---
---

## GROUP 2: S10 — Graphics Quality Wiring (2 chats)

---

### CHAT 2A — Enum + Signal + SettingsManager core

```
@AGENTS.md @.cursor/skills/signal-bus/SKILL.md @.cursor/skills/godot-conventions/SKILL.md

You are implementing the Graphics Quality wiring for Foul Ward.

CUMULATIVE STATE:
- SignalBus: 67 signals. After this chat: 68.
- 17 autoloads (unchanged)
- No GraphicsQuality enum yet
- SettingsManager.graphics_quality is currently a String — will become an enum

---

STEP 1 — GraphicsQuality enum + C# mirror
In scripts/types.gd, append at end:
  ## Rendering quality preset for SettingsManager.
  enum GraphicsQuality {
      LOW = 0,
      MEDIUM = 1,
      HIGH = 2,
      CUSTOM = 3,
  }

In scripts/FoulWardTypes.cs, mirror:
  public enum GraphicsQuality { Low = 0, Medium = 1, High = 2, Custom = 3 }

Search codebase for pre-existing GraphicsQuality references — note any found, do not fix in this chat.

Run: dotnet build FoulWard.csproj

---

STEP 2 — SignalBus: graphics_quality_changed
File: autoloads/signal_bus.gd

Add (with @warning_ignore("unused_signal")):
  ## Emitted when graphics quality preset changes.
  signal graphics_quality_changed(quality: int)

Signal count: 67 → 68.

---

STEP 3 — SettingsManager rewrite
File: autoloads/settings_manager.gd (autoload, no class_name)

Add constants at top:
  const SHADOW_RES_OFF: int = 0
  const SHADOW_RES_MEDIUM: int = 2048
  const SHADOW_RES_HIGH: int = 4096

Change graphics_quality field type from String to Types.GraphicsQuality.
Default: Types.GraphicsQuality.MEDIUM.

Add per-toggle fields (Custom preset):
  var shadows_enabled: bool = true
  var msaa_enabled: bool = false
  var ssao_enabled: bool = false
  var glow_enabled: bool = true

Add private helpers:

  func _find_world_environment() -> WorldEnvironment:
      ## THEORYCRAFT: no WorldEnvironment node in repo at S10; path assumed.
      return get_node_or_null("/root/Main/WorldEnvironment") as WorldEnvironment

  func _apply_quality_preset(quality: Types.GraphicsQuality) -> void:
      if get_viewport() == null or not is_inside_tree():
          return
      match quality:
          Types.GraphicsQuality.LOW:
              # Shadows off: set atlas size to 0 AND zero directional light angular distance
              # (workaround for Godot Proposals #6612 — atlas size=0 alone unreliable)
              RenderingServer.directional_shadow_atlas_set_size(SHADOW_RES_OFF, false)
              get_viewport().positional_shadow_atlas_size = SHADOW_RES_OFF
              for light in get_tree().get_nodes_in_group("directional_lights"):
                  if light is DirectionalLight3D:
                      (light as DirectionalLight3D).light_angular_distance = 0.0
              get_viewport().msaa_3d = Viewport.MSAA_DISABLED
              var we: WorldEnvironment = _find_world_environment()
              if we != null and we.environment != null:
                  we.environment.ssao_enabled = false
                  we.environment.sdfgi_enabled = false
                  we.environment.glow_enabled = false
                  we.environment.volumetric_fog_enabled = false
          Types.GraphicsQuality.MEDIUM:
              RenderingServer.directional_shadow_atlas_set_size(SHADOW_RES_MEDIUM, true)
              get_viewport().positional_shadow_atlas_size = SHADOW_RES_MEDIUM
              for light in get_tree().get_nodes_in_group("directional_lights"):
                  if light is DirectionalLight3D:
                      (light as DirectionalLight3D).light_angular_distance = 0.5
              get_viewport().msaa_3d = Viewport.MSAA_2X
              var we: WorldEnvironment = _find_world_environment()
              if we != null and we.environment != null:
                  we.environment.ssao_enabled = false
                  we.environment.sdfgi_enabled = false
                  we.environment.glow_enabled = true
                  we.environment.volumetric_fog_enabled = false
          Types.GraphicsQuality.HIGH:
              RenderingServer.directional_shadow_atlas_set_size(SHADOW_RES_HIGH, true)
              get_viewport().positional_shadow_atlas_size = SHADOW_RES_HIGH
              for light in get_tree().get_nodes_in_group("directional_lights"):
                  if light is DirectionalLight3D:
                      (light as DirectionalLight3D).light_angular_distance = 0.5
              get_viewport().msaa_3d = Viewport.MSAA_4X
              var we: WorldEnvironment = _find_world_environment()
              if we != null and we.environment != null:
                  we.environment.ssao_enabled = true
                  we.environment.sdfgi_enabled = false
                  we.environment.glow_enabled = true
                  we.environment.volumetric_fog_enabled = true
          Types.GraphicsQuality.CUSTOM:
              _apply_custom_toggles()

  func _apply_custom_toggles() -> void:
      if get_viewport() == null or not is_inside_tree():
          return
      get_viewport().msaa_3d = Viewport.MSAA_2X if msaa_enabled else Viewport.MSAA_DISABLED
      var shadow_res: int = SHADOW_RES_MEDIUM if shadows_enabled else SHADOW_RES_OFF
      RenderingServer.directional_shadow_atlas_set_size(shadow_res, shadows_enabled)
      get_viewport().positional_shadow_atlas_size = shadow_res
      var we: WorldEnvironment = _find_world_environment()
      if we != null and we.environment != null:
          we.environment.ssao_enabled = ssao_enabled
          we.environment.glow_enabled = glow_enabled

Update set_graphics_quality():
  func set_graphics_quality(quality: Types.GraphicsQuality) -> void:
      graphics_quality = quality
      _apply_quality_preset(quality)
      SignalBus.graphics_quality_changed.emit(int(quality))
      save_settings()

Update load_settings(): load quality as int, cast to enum. Load all 4 toggle bools from [graphics] section with defaults. Call _apply_quality_preset(graphics_quality) at end.

Update save_settings(): save int(graphics_quality) and the 4 toggle bools under [graphics].

Update _ready() default assignment: Types.GraphicsQuality.MEDIUM (not string).

CRITICAL: all render-touching code must be guarded by the headless check:
  if get_viewport() == null or not is_inside_tree():
      return

---

VERIFICATION:
- dotnet build passes
- ./tools/run_gdunit_quick.sh passes
- Signal count = 68 in signal_bus.gd
```

---

### CHAT 2B — Settings screen UI + tests

```
@AGENTS.md @.cursor/skills/testing/SKILL.md

You are implementing the settings screen UI and tests for the Graphics Quality feature.

CUMULATIVE STATE:
- SignalBus: 68 signals
- 17 autoloads
- GraphicsQuality enum, graphics_quality_changed signal, SettingsManager core all done (Chat 2A)

---

STEP 1 — Scene changes
File: scenes/ui/settings_screen.tscn

Under the existing QualityOption node, add a VBoxContainer:
  Name: CustomTogglesContainer
  unique_name_in_owner: true
  visible: false
  layout_mode: 2

Inside, add 4 HBoxContainer children (each with a Label + CheckBox, each CheckBox unique_name_in_owner=true):
  ShadowsRow → Label "Shadows" + ShadowsCheck
  MsaaRow    → Label "MSAA"    + MsaaCheck
  SsaoRow    → Label "SSAO"    + SsaoCheck
  GlowRow    → Label "Glow"    + GlowCheck

---

STEP 2 — Settings screen script
File: scripts/ui/settings_screen.gd

Add @onready vars:
  @onready var _custom_toggles: VBoxContainer = %CustomTogglesContainer
  @onready var _shadows_check: CheckBox = %ShadowsCheck
  @onready var _msaa_check: CheckBox = %MsaaCheck
  @onready var _ssao_check: CheckBox = %SsaoCheck
  @onready var _glow_check: CheckBox = %GlowCheck

Update _populate_from_settings():
  - Add "Custom" as 4th item in the quality OptionButton (after High)
  - Map SettingsManager.graphics_quality enum → index (LOW=0, MEDIUM=1, HIGH=2, CUSTOM=3)
  - Populate checkbox states via set_pressed_no_signal() from SettingsManager
  - _custom_toggles.visible = (SettingsManager.graphics_quality == Types.GraphicsQuality.CUSTOM)

Update _on_quality_selected(index: int):
  - Map index → Types.GraphicsQuality enum value
  - Call SettingsManager.set_graphics_quality(enum_value)
  - Show/hide _custom_toggles based on whether CUSTOM was selected

Add toggle handlers (connect .toggled signal in _ready()):
  _on_shadows_toggled(pressed), _on_msaa_toggled(pressed), _on_ssao_toggled(pressed), _on_glow_toggled(pressed)
Each handler: set SettingsManager.<toggle>_enabled = pressed, then call SettingsManager.set_graphics_quality(Types.GraphicsQuality.CUSTOM).

Use .toggled (not .value_changed) for CheckBox.

---

STEP 3 — Tests
Create tests/test_settings_graphics.gd (GdUnit4):

  test_enum_low_value    → Types.GraphicsQuality.LOW == 0
  test_enum_medium_value → Types.GraphicsQuality.MEDIUM == 1
  test_enum_high_value   → Types.GraphicsQuality.HIGH == 2
  test_enum_custom_value → Types.GraphicsQuality.CUSTOM == 3

  test_set_graphics_quality_stores_enum
    → set_graphics_quality(LOW); assert graphics_quality == LOW

  test_set_graphics_quality_emits_signal
    → Use Array[int] = [-1] to capture value (GDScript closures capture arrays by reference)
    → Connect SignalBus.graphics_quality_changed to a callable that writes received[0]
    → set_graphics_quality(HIGH)
    → assert received[0] == int(HIGH)
    → disconnect in after_test

  test_load_settings_applies_preset_headless
    → save HIGH, change in memory to LOW, load, assert graphics_quality == HIGH

  test_custom_preset_preserves_toggles
    → set toggles to known values, save, dirty state, load, assert toggles restored

  test_apply_quality_preset_headless_no_crash
    → Call _apply_quality_preset() for all 4 enum values in headless; no crash

  after_test
    → Reset SettingsManager to MEDIUM + default toggles

---

STEP 4 — Doc sync
Update in all tracked locations:
  - Signal count: 67 → 68 (AGENTS.md, docs/FOUL_WARD_MASTER_DOC.md §3.1 and §24, docs/CONVENTIONS.md, docs/ARCHITECTURE.md, docs/INDEX_SHORT.md, docs/INDEX_FULL.md, .cursor/skills/signal-bus/references/signal-table.md, .cursor/skills/signal-bus/SKILL.md)
  - Add Types.GraphicsQuality to §5 enum table in FOUL_WARD_MASTER_DOC.md
  - Add graphics_quality_changed to §24 under a Settings subsection
  - Add TBD item in §33: WorldEnvironment path is theorycrafted
  - Update PERPLEXITY_RECONCILIATION_TRACKER.md G2 row

---

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes
- All ~9 new tests pass
- Signal count 68 visible in all tracked docs
```

---
---

## GROUP 3: S09 — Building HP & Destruction System (3 chats)

---

### CHAT 3A — Data fields + HealthComponent

```
@AGENTS.md @.cursor/skills/building-system/SKILL.md @.cursor/skills/enemy-system/SKILL.md

You are implementing the data layer and HealthComponent wiring for the Building HP & Destruction system in Foul Ward.

CUMULATIVE STATE:
- SignalBus: 68 signals (no new signals this session — activates existing building_destroyed)
- 17 autoloads (unchanged)

---

STEP 1 — Extend BuildingData
File: scripts/resources/building_data.gd

Add two exported fields:
  ## Hit points for destructible buildings. 0 = indestructible (backward-compat default).
  @export var max_hp: int = 0
  ## When true, enemies with prefer_building_targets may attack this building.
  @export var can_be_targeted_by_enemies: bool = false

Fields only. No logic. No other changes.

---

STEP 2 — Extend EnemyData
File: scripts/resources/enemy_data.gd

Add two exported fields:
  ## When true, enemy scans for targetable buildings in detection radius before pathing to tower.
  @export var prefer_building_targets: bool = false
  ## Scan radius for targetable buildings (separate from attack_range).
  @export var building_detection_radius: float = 8.0

Fields only. Confirm defaults don't break existing enemy .tres files.

---

STEP 3 — HealthComponent conditional init in BuildingBase
File: scenes/buildings/building_base.gd

Context: BuildingBase may already have an @onready health_component reference for Tower/EnemyBase reuse. For buildings, HealthComponent must be ADDED DYNAMICALLY only when BuildingData.max_hp > 0.

Add method:
  func _setup_health_component() -> void:
      if _building_data == null or _building_data.max_hp <= 0:
          return
      if health_component != null and is_instance_valid(health_component):
          # Already set up (e.g. editor-placed node); just configure
          health_component.max_hp = _building_data.max_hp
          health_component.current_hp = _building_data.max_hp
          if not health_component.health_depleted.is_connected(_on_health_depleted):
              health_component.health_depleted.connect(_on_health_depleted)
          return
      var hc: HealthComponent = HealthComponent.new()
      hc.max_hp = _building_data.max_hp
      hc.current_hp = _building_data.max_hp
      add_child(hc)
      health_component = hc
      hc.health_depleted.connect(_on_health_depleted)

Add stub (full logic in Chat 3B):
  func _on_health_depleted() -> void:
      pass

Call _setup_health_component() at the END of initialize() (after _apply_data_stats or equivalent).

Use is_instance_valid() guards. Static typing everywhere.

---

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes
- dotnet build not required (no .cs changes)
- BuildingData + EnemyData .tres files load without errors
```

---

### CHAT 3B — Destruction flow + Enemy targeting + HP bar

```
@AGENTS.md @.cursor/skills/building-system/SKILL.md @.cursor/skills/enemy-system/SKILL.md @.cursor/skills/scene-tree-and-physics/SKILL.md

You are wiring up the destruction pipeline, enemy building-targeting, and building HP bar for Foul Ward.

PREREQUISITE: Chat 3A changes must exist.

CUMULATIVE STATE:
- SignalBus: 68 signals. No new signals this chat — activates existing building_destroyed signal.
- 17 autoloads (unchanged)

---

STEP 1 — DestructionEffect scene + script
Create scenes/buildings/destruction_effect.tscn:
  Root: Node3D (name: DestructionEffect)
  Script: scenes/buildings/destruction_effect.gd

Create scenes/buildings/destruction_effect.gd:
  class_name DestructionEffect
  extends Node3D

  const SHRINK_DURATION: float = 0.5

  func play(world_pos: Vector3, _source_mesh: Mesh = null) -> void:
      global_position = world_pos
      var tw: Tween = create_tween()
      tw.tween_property(self, "scale", Vector3.ZERO, SHRINK_DURATION)
      tw.tween_callback(queue_free)

---

STEP 2 — BuildingBase destruction flow
File: scenes/buildings/building_base.gd

Implement _on_health_depleted():
  func _on_health_depleted() -> void:
      if slot_id >= 0:
          SignalBus.building_destroyed.emit(slot_id)
      if _building_data != null and _building_data.is_summoner:
          AllyManager.despawn_squad(placed_instance_id)
      if _building_data != null and _building_data.is_aura:
          AuraManager.deregister_aura(placed_instance_id)
      _spawn_destruction_effect()
      var hex: Node = get_node_or_null("/root/Main/HexGrid")
      if hex != null and hex.has_method("clear_slot_on_destruction"):
          hex.clear_slot_on_destruction(slot_id)
      else:
          push_warning("BuildingBase._on_health_depleted: HexGrid not found")
          _disable_collision_and_obstacle()  # or whatever existing helper is named
          queue_free()

Add helper:
  func _spawn_destruction_effect() -> void:
      var fx_container: Node = get_node_or_null("/root/Main/FX")
      if fx_container == null:
          fx_container = get_parent()
      if fx_container == null:
          return
      var effect_scene: PackedScene = load("res://scenes/buildings/destruction_effect.tscn") as PackedScene
      if effect_scene == null or not effect_scene.can_instantiate():
          return
      var fx: Node3D = effect_scene.instantiate() as Node3D
      if fx == null:
          return
      fx_container.add_child(fx)
      fx.global_position = global_position
      if fx.has_method("play"):
          var mesh_ref: Mesh = null
          if is_instance_valid(mesh) and mesh.mesh != null:
              mesh_ref = mesh.mesh
          fx.call("play", global_position, mesh_ref)

---

STEP 3 — HexGrid helpers
File: scenes/hex_grid/hex_grid.gd

Add clear_slot_on_destruction(slot_index: int) -> void:
  - Validate slot_index, push_warning on invalid or unoccupied
  - Get slot dict, remove building from "buildings" group, call _disable_building_obstacle(), queue_free() the building
  - Set slot["building"] = null, slot["is_occupied"] = false

Add _disable_building_obstacle(building: BuildingBase) -> void (helper):
  - Get NavigationObstacle3D child, set_deferred("enabled", false)
  - Get collision CollisionShape3D child, set_deferred("disabled", true)

---

STEP 4 — Enemy building-targeting
File: scenes/enemies/enemy_base.gd

IMPORTANT: Verify exact method/var names for enemy attack logic BEFORE editing. Specifically confirm the method name used for effective damage — earlier attempts used a wrong name. The correct method is _get_effective_damage_int() (returns int), NOT _get_effective_damage().

Add state var:
  var _current_building_target: BuildingBase = null

Add private methods:
  func _try_building_target_attack(delta: float) -> bool:
      if _enemy_data == null or not _enemy_data.prefer_building_targets:
          return false
      _current_building_target = _find_building_target()
      if not is_instance_valid(_current_building_target):
          _current_building_target = null
          return false
      _attack_building(_current_building_target, delta)
      return true

  func _find_building_target() -> BuildingBase:
      var ed: EnemyData = _enemy_data
      if ed == null or not ed.prefer_building_targets:
          return null
      var tree: SceneTree = get_tree()
      if tree == null:
          return null
      var best: BuildingBase = null
      var best_dist: float = INF
      var radius: float = ed.building_detection_radius
      for node: Node in tree.get_nodes_in_group("buildings"):
          var b: BuildingBase = node as BuildingBase
          if b == null or not is_instance_valid(b):
              continue
          var bd: BuildingData = b.get_building_data()
          if bd == null or not bd.can_be_targeted_by_enemies:
              continue
          var hc: HealthComponent = b.get_node_or_null("HealthComponent") as HealthComponent
          if hc == null or not hc.is_alive():
              continue
          var d: float = global_position.distance_to(b.global_position)
          if d > radius:
              continue
          if d < best_dist:
              best_dist = d
              best = b
      return best

  func _attack_building(target: BuildingBase, delta: float) -> void:
      if not is_instance_valid(target):
          _current_building_target = null
          return
      var hc: HealthComponent = target.get_node_or_null("HealthComponent") as HealthComponent
      if hc == null or not hc.is_alive():
          _current_building_target = null
          return
      _is_attacking = true
      velocity = Vector3.ZERO
      _attack_timer += delta
      if _attack_timer >= _enemy_data.attack_cooldown:
          _attack_timer = 0.0
          hc.take_damage(_get_effective_damage_int())   # not _get_effective_damage()

Hook into existing _physics_process_ground (or equivalent combat tick), AFTER the existing saboteur check, BEFORE the normal tower-path navigation:
  if _try_building_target_attack(delta):
      _sync_locomotion_animation()
      return

---

STEP 5 — BuildingHpBar scene + script
Create scenes/ui/building_hp_bar.tscn:
  Node3D (root)
  ├── SubViewport (transparent_bg=true, size=Vector2i(128, 16), render_target_update_mode=4)
  │   └── HpBar: ProgressBar (offset_right=128, offset_bottom=16, max_value=100, value=100, show_percentage=false)
  └── Sprite3D (pixel_size=0.005, billboard=1, position=Vector3(0, 2.5, 0))

Create scenes/ui/building_hp_bar.gd:
  class_name BuildingHpBar
  extends Node3D

  @onready var _hp_bar: ProgressBar = $SubViewport/HpBar
  @onready var _sprite: Sprite3D = $Sprite3D

  func setup(health_comp: HealthComponent) -> void:
      if health_comp == null:
          push_warning("BuildingHpBar.setup: null HealthComponent")
          return
      _hp_bar.max_value = health_comp.max_hp
      _hp_bar.value = health_comp.current_hp
      if not health_comp.health_changed.is_connected(_on_health_changed):
          health_comp.health_changed.connect(_on_health_changed)
      visible = false

  func _on_health_changed(current_hp: int, max_hp: int) -> void:
      _hp_bar.max_value = max_hp
      _hp_bar.value = current_hp
      visible = current_hp < max_hp

Wire into BuildingBase._setup_health_component() — after add_child(hc), instantiate the HP bar scene as a child of the building and call hp_bar.setup(hc).

---

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes — IMPORTANT: check for Parse Errors in the log; if enemy_base.gd fails to parse, confirm _get_effective_damage_int() is the method name used (not _get_effective_damage)
- No crash when a building takes damage in-game
```

---

### CHAT 3C — .tres updates + shop item + tests

```
@AGENTS.md @.cursor/skills/testing/SKILL.md @.cursor/skills/building-system/SKILL.md @.cursor/skills/economy-system/SKILL.md

You are setting per-size HP values, adding the building_repair shop item, and writing tests for the Building HP system.

PREREQUISITE: Chats 3A + 3B must be complete.

CUMULATIVE STATE:
- SignalBus: 68 signals (unchanged)
- 17 autoloads (unchanged)

---

STEP 1 — Set max_hp on MEDIUM building .tres files
Path: resources/building_data/

Target: every .tres where size_class == "MEDIUM" (BuildingSizeClass enum value 4).
Enumerate and print the list first for review.

For each MEDIUM building .tres, append:
  max_hp = 300
  can_be_targeted_by_enemies = true

Do NOT touch SMALL/LARGE/SINGLE_SLOT/DOUBLE_WIDE/TRIPLE_CLUSTER files.
Do NOT change any other field.

---

STEP 2 — Set max_hp on LARGE building .tres files
Target: every .tres where size_class == "LARGE" (enum value 5).

For each LARGE building .tres, append:
  max_hp = 650
  can_be_targeted_by_enemies = true

Do NOT touch non-LARGE files.

---

STEP 3 — building_repair shop item

Step 3a: Create resources/shop_items/building_repair.tres (mirror tower_repair fields):
  item_id = "building_repair"
  display_name = "Building Repair"
  gold_cost = same as tower_repair
  effect_type / handler_key = "building_repair"

Step 3b: Add HexGrid query method
File: scenes/hex_grid/hex_grid.gd

  ## Returns building with lowest HP percentage among alive buildings with HealthComponent.
  ## Returns null if none found or all at full HP.
  func get_lowest_hp_pct_building() -> BuildingBase:
      var best: BuildingBase = null
      var best_pct: float = 1.0
      for slot: Dictionary in _slots:
          if not slot["is_occupied"]:
              continue
          var b: BuildingBase = slot["building"] as BuildingBase
          if not is_instance_valid(b):
              continue
          var hc: HealthComponent = b.get_node_or_null("HealthComponent") as HealthComponent
          if hc == null or not hc.is_alive():
              continue
          var pct: float = float(hc.current_hp) / float(hc.max_hp)
          if pct < best_pct:
              best_pct = pct
              best = b
      return best

Step 3c: Handle in shop_manager.gd
In purchase_item() / effect dispatch, add "building_repair" case:
  - Get /root/Main/HexGrid, guard null
  - Call hex.get_lowest_hp_pct_building(); return false if null
  - Get its HealthComponent; return false if null
  - heal_amount = maxi(1, int(float(hc.max_hp) * 0.5))
  - hc.heal(heal_amount); return true

Also add can_purchase() guard: return false for "building_repair" if get_lowest_hp_pct_building() returns null.

---

STEP 4 — Mission-scoped HP persistence audit
File: autoloads/save_manager.gd

Audit: confirm save payload does NOT serialize building HP. Buildings re-instantiate at full HP each mission (via HexGrid.clear_all_buildings()). If any building HP is being serialized, remove it.

Add architecture comment: "Building HP is mission-ephemeral. HealthComponent.current_hp is not persisted. Buildings re-instantiate at full HP each day."

---

STEP 5 — Tests

Create tests/test_building_health_component.gd (GdUnit4):
  test_no_health_component_when_max_hp_zero
  test_health_component_added_when_max_hp_positive
  test_health_component_initialized_with_correct_max_hp
  test_building_destroyed_signal_emitted_on_depletion
  test_hex_slot_cleared_on_destruction
  test_building_freed_on_destruction
  test_summoner_despawn_called_on_destruction
  test_aura_deregistered_on_destruction
  test_hp_bar_hidden_at_full_health
  test_hp_bar_visible_after_damage
  test_hp_bar_value_matches_current_hp
  test_building_hp_not_in_save_payload
  test_building_hp_resets_on_new_mission

Create tests/test_enemy_building_targeting.gd:
  test_enemy_ignores_buildings_when_flag_false
  test_enemy_finds_building_when_flag_true
  test_enemy_ignores_non_targetable_building
  test_enemy_ignores_dead_building
  test_enemy_ignores_building_outside_radius

Create tests/test_building_repair.gd:
  test_repair_targets_lowest_hp_pct_not_lowest_absolute
    (A: 400/300=75%, B: 200/160=80%, C: 100/60=60% → returns C)
  test_repair_restores_50_pct
  test_repair_blocked_when_no_damaged_building
  test_repair_ignores_indestructible_buildings

---

STEP 6 — Doc sync
Update PERPLEXITY_RECONCILIATION_TRACKER.md:
  - G3 signals added: 0 (activates existing building_destroyed)
  - G3 test count actual
Add new files to docs/INDEX_SHORT.md and docs/INDEX_FULL.md.

---

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes
- All new tests pass
- Signal count unchanged (68)
- MEDIUM buildings all show max_hp=300 in inspector
- LARGE buildings all show max_hp=650 in inspector
```

---
---

## GROUP 4: S08 — Star Difficulty Tier System (2 chats)

---

### CHAT 4A — Enum + Resources + GameManager + Signals

```
@AGENTS.md @.cursor/skills/signal-bus/SKILL.md @.cursor/skills/campaign-and-progression/SKILL.md

You are implementing the Star Difficulty Tier System for Foul Ward.

CUMULATIVE STATE:
- SignalBus currently has 68 signals. After this chat: 70.
- 17 autoloads (unchanged).
- GraphicsQuality enum already exists in types.gd and FoulWardTypes.cs.

TASK OVERVIEW:
Add DifficultyTier enum, DifficultyTierData resource, territory tier fields, 2 new signals, and GameManager tier logic.

---

STEP 1 — DifficultyTier enum
Files: scripts/types.gd, scripts/FoulWardTypes.cs

In types.gd, append after existing enums:
  ## Replay difficulty tier for per-territory star system.
  enum DifficultyTier {
      NORMAL    = 0,
      VETERAN   = 1,
      NIGHTMARE = 2,
  }

In FoulWardTypes.cs, add matching C# enum:
  public enum DifficultyTier { Normal = 0, Veteran = 1, Nightmare = 2 }

Run: dotnet build FoulWard.csproj

---

STEP 2 — DifficultyTierData resource + 3 .tres files

Create scripts/resources/difficulty_tier_data.gd:
  class_name DifficultyTierData
  extends Resource
  @export var tier: Types.DifficultyTier = Types.DifficultyTier.NORMAL
  @export var enemy_hp_multiplier: float = 1.0
  @export var enemy_damage_multiplier: float = 1.0
  @export var gold_reward_multiplier: float = 1.0
  @export var spawn_count_multiplier: float = 1.0

Create resources/difficulty/ folder with:
  tier_normal.tres: all multipliers = 1.0
  tier_veteran.tres: hp=1.5, dmg=1.3, gold=1.2, spawn=1.25
  tier_nightmare.tres: hp=2.5, dmg=2.0, gold=1.5, spawn=1.75

---

STEP 3 — TerritoryData fields
File: scripts/resources/territory_data.gd

Append these @export fields (declaration-only defaults, NO _init() assignment):
  @export var highest_cleared_tier: Types.DifficultyTier = Types.DifficultyTier.NORMAL
  @export var star_count: int = 0
  @export var veteran_perk_id: String = ""
  @export var nightmare_title_id: String = ""

---

STEP 4 — SignalBus: 2 new signals
File: autoloads/signal_bus.gd

Add (with @warning_ignore("unused_signal")):
  signal territory_tier_cleared(territory_id: String, tier: int)
  signal territory_selected_for_replay(territory_id: String)

Update signal count: 68 → 70.

---

STEP 5 — GameManager tier logic
File: autoloads/game_manager.gd

Add state vars:
  var _active_tier: Types.DifficultyTier = Types.DifficultyTier.NORMAL
  var _tier_data: Dictionary = {}

Add _load_tier_data() called from _ready() — loads all 3 .tres into _tier_data keyed by int(tier).

Add public methods:
  func set_active_tier(tier: Types.DifficultyTier) -> void
  func get_active_tier() -> Types.DifficultyTier

Add _apply_tier_to_day_config(source: DayConfig) -> DayConfig:
  - If NORMAL, return source unchanged.
  - Otherwise, duplicate source, multiply all 4 fields by tier multipliers, return patched copy.
  - NEVER mutate the original DayConfig resource.

FIX REQUIRED: The Perplexity spec includes a get_effective_multiplier(base, tier) method that is a NO-OP (returns base unconditionally). DO NOT add this method. The real logic lives in _apply_tier_to_day_config(). If the spec references get_effective_multiplier, skip it.

In start_mission_for_day(): apply tier patch before passing config to wave:
  day_config = _apply_tier_to_day_config(day_config)

Add _handle_tier_cleared(day_config: DayConfig) -> void:
  - Only upgrade if _active_tier > territory.highest_cleared_tier
  - Update highest_cleared_tier and star_count = int(_active_tier) + 1
  - Emit territory_tier_cleared signal
  - First-ever clear (star_count == 0) always grants star_count = 1

Call _handle_tier_cleared() from _on_all_waves_cleared() after apply_day_result_to_territory().

Reset _active_tier to NORMAL in start_new_game().

---

STEP 6 — Save integration
File: autoloads/game_manager.gd (save section)

In get_save_data(): serialize highest_cleared_tier, star_count, veteran_perk_id, nightmare_title_id per territory.

In restore_from_save(): deserialize with .get(key, default) for backward compat:
  highest_cleared_tier defaults to 0, star_count to 0, perk/title ids to "".

---

VERIFICATION:
- dotnet build passes
- ./tools/run_gdunit_quick.sh passes
- Signal count in signal_bus.gd = 70
```

---

### CHAT 4B — World Map UI + Tests

```
@AGENTS.md @.cursor/skills/testing/SKILL.md

You are implementing the World Map tier selection UI and tests for the Star Difficulty Tier System.

CUMULATIVE STATE:
- SignalBus: 70 signals
- DifficultyTier enum, DifficultyTierData resource, and GameManager tier logic already implemented (Chat 4A)
- territory_tier_cleared and territory_selected_for_replay signals already declared

PREREQUISITE: Verify that Chat 4A changes exist (types.gd has DifficultyTier, signal_bus.gd has territory_tier_cleared).

---

STEP 1 — TerritoryNodeUI script
Create scripts/ui/territory_node_ui.gd (no class_name):
  extends Control
  @export var territory_id: String = ""
  - Connect to SignalBus.territory_state_changed and world_map_updated in _ready()
  - _refresh(): reads GameManager.get_territory_data(territory_id), updates star display (0-3) and lock state
  - On button press: if territory is controlled, emit SignalBus.territory_selected_for_replay(territory_id)

---

STEP 2 — TierSelectionPopup scene + script
Create scenes/ui/world_map/tier_selection_popup.tscn:
  Control root with Panel background, TitleLabel, NormalButton, VeteranButton, NightmareButton, CloseButton.

Create scripts/ui/tier_selection_popup.gd:
  - Connects to SignalBus.territory_selected_for_replay in _ready(), starts hidden
  - On territory selected: show popup, disable NightmareButton if highest_cleared_tier < VETERAN
  - Button handlers call GameManager.set_active_tier(tier) then hide popup
  - Nightmare double-guarded: check tier gate before launching

---

STEP 3 — Tests
Create tests/test_difficulty_tier_system.gd (GdUnit4):

17 test methods:
  test_enum_values — NORMAL=0, VETERAN=1, NIGHTMARE=2
  test_tier_data_normal_all_ones — load tier_normal.tres, all multipliers == 1.0
  test_tier_data_veteran_multipliers — hp=1.5, dmg=1.3, gold=1.2, spawn=1.25
  test_tier_data_nightmare_multipliers — hp=2.5, dmg=2.0, gold=1.5, spawn=1.75
  test_apply_tier_normal_does_not_mutate — patched == source values, source unchanged
  test_apply_tier_veteran_scales_correctly — 1.0 base → correct tier values
  test_apply_tier_nightmare_scales_correctly
  test_apply_tier_stacks_on_nonunit_base — DayConfig hp=2.0 + VETERAN → 3.0
  test_handle_tier_cleared_upgrades_star_count — NORMAL→VETERAN upgrades
  test_handle_tier_cleared_no_downgrade — NIGHTMARE stays if NORMAL replayed
  test_nightmare_locked_until_veteran_cleared — gate condition test
  test_nightmare_unlocked_after_veteran_cleared
  test_save_restore_highest_cleared_tier
  test_save_restore_backward_compat_missing_keys — old saves default correctly
  test_territory_tier_cleared_signal_emitted — signal spy
  test_active_tier_reset_on_new_game
  test_get_effective_multiplier_does_not_exist — assert GameManager does NOT have this method (it was a spec no-op, removed per Fix 2)

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes
- All 17 new tests pass
```

---
---

## GROUP 5: S07 — Art Pipeline Integration (3 chats)

---

### CHAT 5A — Reports (animation table + GLB paths)

```
@AGENTS.md

You are producing art pipeline reference reports for Foul Ward. These are REPORT-ONLY — no code changes.

TASK 1 — Animation Clip Name Table
Produce docs/SESSION_07_REPORT_01_ANIM_TABLE.md containing:
  a. Full animation clip name table — one row per entity category.
     Columns: entity_category | required_clips | optional_clips | notes
     Categories:
       enemies (all 30 — uniform 6-clip set): idle, walk, attack, hit_react, death, spawn (optional)
       allies (arnulf + archer/knight/swordsman/barbarian placeholders): idle, run, attack_melee, hit_react, death, downed, recovering
       florence/sybil (tower): idle, shoot, hit_react, cast_spell, victory, defeat
       buildings (all 36): idle, active, destroyed
       bosses (plague_cult_miniboss, orc_warlord, final_boss): idle, walk, attack, death, phase_transition (optional)
  b. GDScript StringName constants block to add to rigged_visual_wiring.gd:
     const ANIM_IDLE: StringName = &"idle"  (etc.)
  c. Explicit note: drunk_idle REMOVED — Arnulf drunkenness FORMALLY CUT.

TASK 2 — GLB Drop Zone Path Table
Produce docs/SESSION_07_REPORT_02_GLB_PATHS.md containing:
  a. Complete GLB path table. Columns: entity_category | entity_id | glb_path | notes
     Cover all 30 enemies, all allies, all 4 bosses, all 36 buildings, florence/sybil, misc.
     Use lowercase enum-name-derived filenames.
  b. Hub portrait path table (2D): res://art/icons/characters/{character_name}.png
  c. List of 25 missing entries in enemy_rigged_glb_path() that need adding.

Read scripts/art/rigged_visual_wiring.gd and scripts/art/art_placeholder_helper.gd for existing patterns before writing the reports.
Read scripts/types.gd for all EnemyType and BuildingType enum values.

No code changes. Reports only.
```

---

### CHAT 5B — RiggedVisualWiring + ArtPlaceholderHelper + Validator

```
@AGENTS.md @docs/SESSION_07_REPORT_01_ANIM_TABLE.md @docs/SESSION_07_REPORT_02_GLB_PATHS.md

You are extending the art pipeline wiring code and creating a validation tool for Foul Ward.

PREREQUISITE: Reports from Chat 5A must exist on disk.

STEP 1 — Extend rigged_visual_wiring.gd
File: scripts/art/rigged_visual_wiring.gd

Add 14 new ANIM_ StringName constants from REPORT_01:
  ANIM_ATTACK, ANIM_HIT_REACT, ANIM_SPAWN, ANIM_RUN, ANIM_ATTACK_MELEE,
  ANIM_DOWNED, ANIM_RECOVERING, ANIM_SHOOT, ANIM_CAST_SPELL,
  ANIM_VICTORY, ANIM_DEFEAT, ANIM_ACTIVE, ANIM_DESTROYED,
  ANIM_PHASE_TRANSITION
All as StringName using &"" syntax. No drunk_idle.

Extend enemy_rigged_glb_path(): add all 25 missing EnemyType cases from REPORT_02.

Add ally_rigged_glb_path(ally_id: StringName) -> String:
  Returns res://art/generated/allies/{ally_id}.glb for arnulf + 4 mercs.
  Returns "" for unknown ids.

Add building_rigged_glb_path(building_type: Types.BuildingType) -> String:
  Returns res://art/generated/buildings/{token}.glb for all 36 types.

Add tower_glb_path() -> String:
  Returns "res://art/characters/florence/florence.glb".

STEP 2 — Extend art_placeholder_helper.gd
Extend _get_ally_token() match block: add archer, knight, swordsman, barbarian.

STEP 3 — Create tools/validate_art_assets.gd
@tool extends EditorScript
Report-only preflight: scans res://art/ GLBs, checks required clips.
Methods: _run(), _scan_directory(), _infer_category(), _get_required_clips(), _check_glb(), _report()
Use ResourceLoader.load() NOT GLTFDocument.generate_scene() (silent track drop gotcha).
Use DirAccess recursive scan, not EditorFileSystem.

Produce docs/SESSION_07_REPORT_03_WIRING.md listing every method/constant added.

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes
- No signals or enums changed
```

---

check 
---

## GROUP 6: S02 — Sybil Passive System (3 chats)

---

### CHAT 6A — Resource + Data + Enum + Signals

```
@AGENTS.md @.cursor/skills/signal-bus/SKILL.md @.cursor/skills/add-new-entity/SKILL.md

You are implementing the Sybil Passive System data layer for Foul Ward.

CUMULATIVE STATE:
- SignalBus: 70 signals. After this chat: 72.
- 17 autoloads (no new autoload this chat).
- GameState last value: ENDLESS = 10.

---

STEP 1 — SybilPassiveData resource
Create scripts/resources/sybil_passive_data.gd:
  extends Resource
  class_name SybilPassiveData

FIX: The Perplexity spec says "No class_name" — this is WRONG. Resource classes SHOULD have class_name. Only autoloads omit it. Add class_name SybilPassiveData.

Fields (all @export, static typing):
  passive_id: String = ""
  display_name: String = ""
  description: String = ""
  icon_id: String = ""
  category: String = ""   # "offense" | "defense" | "utility"
  effect_type: String = ""   # see table below
  effect_value: float = 0.0
  is_unlocked: bool = true
  prerequisite_ids: Array = []

effect_type values (document as comment):
  "spell_damage_pct", "mana_regen_pct", "max_mana_flat", "cooldown_pct",
  "mana_cost_pct", "max_hp_pct", "resource_income_pct", "heal_effectiveness_pct"

---

STEP 2 — Eight passive .tres files
Create folder resources/passive_data/ with 8 .tres files:
  iron_vow.tres: passive_iron_vow, offense, spell_damage_pct, 0.15
  ember_vigil.tres: passive_ember_vigil, utility, max_mana_flat, 20.0
  still_water.tres: passive_still_water, defense, max_hp_pct, 0.20
  fracture_song.tres: passive_fracture_song, offense, spell_damage_pct, 0.10
  cold_margin.tres: passive_cold_margin, offense, cooldown_pct, 0.15
  root_memory.tres: passive_root_memory, utility, resource_income_pct, 0.25
  void_tithe.tres: passive_void_tithe, utility, mana_regen_pct, 0.20
  bright_covenant.tres: passive_bright_covenant, defense, heal_effectiveness_pct, 0.30

Write 1-sentence flavour text per passive matching the Foul Ward medieval plague-doctor tone.
icon_id: leave as "".

---

STEP 3 — GameState enum update
In types.gd: append PASSIVE_SELECT = 11 to GameState enum. NEVER reorder existing values.
In FoulWardTypes.cs: mirror PASSIVE_SELECT = 11.
Run: dotnet build FoulWard.csproj

---

STEP 4 — SignalBus: 2 new signals
File: autoloads/signal_bus.gd

Add (with @warning_ignore):
  signal sybil_passive_selected(passive_id: String)
  signal sybil_passives_offered(passive_ids: Array)

Update signal count: 70 → 72.

---

VERIFICATION:
- dotnet build passes
- ./tools/run_gdunit_quick.sh passes
- Signal count = 72
- 8 .tres files load without error
```

---

### CHAT 6B — Autoload + GameManager + UI + SpellManager

```
@AGENTS.md @.cursor/skills/spell-and-research-system/SKILL.md @.cursor/skills/lifecycle-flows/SKILL.md

You are implementing the SybilPassiveManager autoload and wiring for Foul Ward.

CUMULATIVE STATE:
- SignalBus: 72 signals
- SybilPassiveData resource + 8 .tres + PASSIVE_SELECT enum + 2 signals already exist (Chat 6A)
- SybilPassiveManager will be autoload Init #14

---

STEP 1 — SybilPassiveManager autoload
Create autoloads/sybil_passive_manager.gd (note: autoloads go in autoloads/ folder, not scripts/):
  No class_name (autoload convention).

Constants:
  PASSIVE_DATA_DIR = "res://resources/passive_data/"
  OFFER_COUNT = 4

State vars:
  _all_passives: Array = []     # loaded on _ready
  _active_passive_id: String = ""
  _active_passive: Resource = null

Methods:
  _ready(): load all .tres from PASSIVE_DATA_DIR into _all_passives
  get_offered_passives() -> Array: picks OFFER_COUNT random unlocked passives, emits sybil_passives_offered
  select_passive(passive_id: String) -> void: sets _active_passive_id, caches resource, emits sybil_passive_selected
  get_active_passive() -> Resource: returns cached resource or null
  get_modifier(effect_type: String) -> float: returns effect_value of active passive if matching, else 0.0
  clear_passive() -> void: resets active passive
  get_save_data() -> Dictionary: returns {"active_passive_id": _active_passive_id}
  restore_from_save_data(data: Dictionary) -> void: restores active passive from saved id

Register as autoload Init #14 in project.godot. Shift DialogueManager → 15, AutoTestDriver → 16, GDAIMCPRuntime → 17, EnchantmentManager → 18.

---

STEP 2 — GameManager PASSIVE_SELECT state transition
File: autoloads/game_manager.gd

Wire PASSIVE_SELECT state: after MISSION_BRIEFING, transition to PASSIVE_SELECT before COMBAT.
Flow: MISSION_BRIEFING → PASSIVE_SELECT → BUILD_MODE (or COMBAT depending on existing flow)

Add enter_passive_select() and exit_passive_select() methods.
On exit: SybilPassiveManager.select_passive(chosen_id) must have been called.

---

STEP 3 — Passive Select UI
Create scenes/ui/passive_select_screen.tscn + scripts/ui/passive_select_screen.gd:
  Panel overlay with HBoxContainer of 3-4 passive cards.
  Each card: Panel with VBoxContainer containing name Label, description Label, select Button.
  On state PASSIVE_SELECT: populate from SybilPassiveManager.get_offered_passives(), show screen.
  On card button press: call SybilPassiveManager.select_passive(passive_id), then transition to next state.

---

STEP 4 — SpellManager integration
File: scripts/spell_manager.gd (find actual location first)

In relevant calculation methods, query SybilPassiveManager.get_modifier() for:
  "spell_damage_pct" → multiply spell damage
  "mana_regen_pct" → multiply mana regen rate
  "max_mana_flat" → add to max mana
  "cooldown_pct" → multiply cooldowns by (1 - value)
  "mana_cost_pct" → multiply mana costs by (1 - value)

Use has_method/get_modifier pattern with null guard in case SybilPassiveManager not loaded.

---

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes
- project.godot shows SybilPassiveManager at correct init position
- Autoload order: 14=SybilPassiveManager, 15=DialogueManager, 16=AutoTestDriver, 17=GDAIMCPRuntime, 18=EnchantmentManager
```

---

### CHAT 6C — Save/Load + Tests + Docs

```
@AGENTS.md @.cursor/skills/testing/SKILL.md @.cursor/skills/save-and-dialogue/SKILL.md

You are implementing save/load integration and tests for the Sybil Passive System.

CUMULATIVE STATE:
- SignalBus: 72 signals
- 18 autoloads (17 baseline + SybilPassiveManager at #14)
- SybilPassiveManager, UI, SpellManager integration done (Chats 6A + 6B)

---

STEP 1 — Save/Load integration
File: autoloads/save_manager.gd or autoloads/game_manager.gd (wherever save payload is assembled)

Add "sybil" key to save payload:
  "sybil": SybilPassiveManager.get_save_data()

On restore:
  SybilPassiveManager.restore_from_save_data(data.get("sybil", {}))

---

STEP 2 — Tests
Create tests/test_sybil_passive_manager.gd (GdUnit4, ~11 methods):

  test_load_all_passives_from_directory — _all_passives.size() == 8
  test_get_offered_passives_returns_offer_count — result.size() == OFFER_COUNT
  test_get_offered_passives_all_unlocked — every offered passive has is_unlocked == true
  test_select_passive_sets_active — select, then get_active_passive() != null
  test_select_passive_emits_signal — spy on sybil_passive_selected
  test_get_modifier_returns_value_for_matching_type — select iron_vow, query spell_damage_pct → 0.15
  test_get_modifier_returns_zero_for_non_matching — select iron_vow, query mana_regen_pct → 0.0
  test_clear_passive_resets_state — after clear, get_active_passive() == null
  test_save_restore_preserves_selection — save, clear, restore, assert active == original
  test_save_restore_empty_data_no_crash — restore from {} succeeds
  test_offered_passives_signal_emitted — spy on sybil_passives_offered

---

STEP 3 — Doc updates
Update signal count to 72 in ALL tracked locations:
  AGENTS.md, docs/FOUL_WARD_MASTER_DOC.md, docs/CONVENTIONS.md, docs/ARCHITECTURE.md,
  docs/INDEX_SHORT.md, docs/INDEX_FULL.md, .cursor/skills/signal-bus/ files

Update autoload table in AGENTS.md and docs to reflect new order (18 autoloads).
Add new files to INDEX_SHORT.md and INDEX_FULL.md.

---

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes
- All ~11 new tests pass
- Signal count in docs matches 72
```

---
---

## GROUP 7: S03 — Ring Rotation Pre-Battle UI (3 chats)

---

### CHAT 7A — Ring Layout Refactor + Per-Ring Rotation

```
@AGENTS.md @.cursor/skills/building-system/SKILL.md @.cursor/skills/scene-tree-and-physics/SKILL.md

You are refactoring the hex grid layout for ring rotation support in Foul Ward.

CUMULATIVE STATE:
- SignalBus: 72 signals (unchanged this chat)
- 18 autoloads
- TOTAL_SLOTS currently = 24, will become 42

---

STEP 1 — Ring layout constants
File: scenes/hex_grid/hex_grid.gd

Change constants:
  RING3_COUNT: 6 → 24
  RING3_RADIUS: 18.0 → 24.0
  TOTAL_SLOTS: 24 → 42

Update _compute_ring_positions() if needed for new ring 3 count.
Add per-ring rotation offset arrays:
  var _ring_offsets: Array[float] = [0.0, 0.0, 0.0]  # radians, one per ring

---

STEP 2 — Per-ring independent rotation
Refactor rotate_ring() to accept ring_index and angle:
  func rotate_ring(ring_index: int, angle_rad: float) -> void

Apply rotation offset: _ring_offsets[ring_index] += angle_rad
Recompute positions for that ring only.
Move buildings in affected slots.

Add credit comment:
  # Ring position formula adapted from Red Blob Games (redblobgames.com/grids/hexagons/)
  # via romlok/godot-gdhexgrid (github.com/romlok/godot-gdhexgrid)

---

STEP 3 — Update CombatStatsTracker
File: autoloads/combat_stats_tracker.gd

Update slot-to-ring mapping for new 42-slot layout:
  Ring 1: slots 0-5 (6 slots)
  Ring 2: slots 6-17 (12 slots)
  Ring 3: slots 18-41 (24 slots)

---

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes
- TOTAL_SLOTS == 42 in hex_grid.gd
```

---

### CHAT 7B — GameState Enum + Signal + GameManager + Save Migration

```
@AGENTS.md @.cursor/skills/signal-bus/SKILL.md @.cursor/skills/campaign-and-progression/SKILL.md

You are adding the RING_ROTATE game state and save migration for ring rotation.

CUMULATIVE STATE:
- SignalBus: 72 signals. After this chat: 73.
- 18 autoloads
- GameState: PASSIVE_SELECT = 11 already exists
- TOTAL_SLOTS = 42 (from Chat 7A)

---

STEP 1 — GameState RING_ROTATE
In types.gd: append RING_ROTATE = 12 to GameState enum.
In FoulWardTypes.cs: mirror.
Run: dotnet build FoulWard.csproj

---

STEP 2 — ring_rotated signal
File: autoloads/signal_bus.gd
Add:
  @warning_ignore("unused_signal")
  signal ring_rotated(ring_index: int, angle_rad: float)

Signal count: 72 → 73.

---

STEP 3 — GameManager ring rotation state
File: autoloads/game_manager.gd

Add methods:
  func enter_ring_rotate() -> void — transitions to RING_ROTATE state
  func exit_ring_rotate() -> void — transitions to next state (BUILD_MODE or COMBAT)

Wire into mission flow: after PASSIVE_SELECT (or MISSION_BRIEFING if no passive), enter RING_ROTATE before BUILD_MODE.

---

STEP 4 — Save migration v1 → v2
In save payload: add "save_version": 2
On load: if save_version < 2, remap slot indices for old 24-slot layout:
  Slots 0-5: unchanged (Ring 1)
  Slots 6-17: unchanged (Ring 2)
  Slots 18-23 (old Ring 3): remap to 18-23 of new 42-slot range
  Slots 24-41: empty (new Ring 3 expansion)

Guard all slot references: if slot_index >= TOTAL_SLOTS, skip with push_warning.

---

VERIFICATION:
- dotnet build passes
- ./tools/run_gdunit_quick.sh passes
- Signal count = 73
```

---

### CHAT 7C — Ring Rotation UI + Tests + Docs

```
@AGENTS.md @.cursor/skills/testing/SKILL.md

You are creating the Ring Rotation UI screen and tests for Foul Ward.

CUMULATIVE STATE:
- SignalBus: 73 signals
- 18 autoloads
- RING_ROTATE = 12 in GameState, ring_rotated signal, 42-slot hex grid (Chats 7A + 7B)

---

STEP 1 — Ring Rotation Screen
Create scenes/ui/ring_rotation_screen.tscn + scripts/ui/ring_rotation_screen.gd:

Scene hierarchy:
  Control (root)
  ├── SubViewportContainer
  │   └── SubViewport (top-down camera showing hex grid)
  ├── RingControlsPanel (VBoxContainer)
  │   ├── Ring1Row (HBoxContainer: Label + RotateLeftBtn + RotateRightBtn)
  │   ├── Ring2Row
  │   └── Ring3Row
  └── ConfirmButton

Script:
  On RING_ROTATE state: show screen, populate SubViewport with hex grid preview
  Rotation buttons: call HexGrid.rotate_ring(ring_index, ±angle_step)
  ConfirmButton: call GameManager.exit_ring_rotate()
  Use SubViewport for read-only 3D preview (reference: Godot SubViewport docs)

Add RingRotationScreen node to main scene UI layer.

---

STEP 2 — Tests
Create tests/test_ring_rotation.gd (GdUnit4, ~13 methods):
  test_total_slots_42 — HexGrid.TOTAL_SLOTS == 42
  test_ring1_slot_count — 6 slots
  test_ring2_slot_count — 12 slots
  test_ring3_slot_count — 24 slots
  test_rotate_ring_changes_offset — rotate ring 0 by PI/6, verify offset changed
  test_rotate_ring_moves_building_positions — place building, rotate, verify position changed
  test_ring_rotated_signal_emitted — spy on ring_rotated signal
  test_rotation_preserves_building_count — same number of buildings before/after
  test_game_state_ring_rotate_value — RING_ROTATE == 12
  test_enter_ring_rotate_sets_state
  test_exit_ring_rotate_transitions_state
  test_save_migration_old_24_slots — create v1 save, load, verify buildings in correct slots
  test_save_migration_guard_invalid_slot — slot >= 42 skipped

---

STEP 3 — Doc updates
Update in all tracked doc locations:
  - TOTAL_SLOTS: 24 → 42 (AGENTS.md line "24 slots across 3 rings" → "42 slots across 3 rings")
  - Signal count: 73
  - GameState values: add RING_ROTATE = 12
  - New files to INDEX_SHORT.md and INDEX_FULL.md
  - Autoload count unchanged (still 18)

---

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes
- All ~13 new tests pass
- Docs reflect 42 slots, 73 signals
```

---
---

## GROUP 8: S04 — Chronicle Meta-Progression (3 chats)

---

### CHAT 8A — Resources + Enums + Signals

```
@AGENTS.md @.cursor/skills/signal-bus/SKILL.md @.cursor/skills/add-new-entity/SKILL.md

You are implementing the Chronicle meta-progression data layer for Foul Ward.

CUMULATIVE STATE:
- SignalBus: 73 signals. After this chat: 76.
- 18 autoloads (ChronicleManager not added yet — that's Chat 8B)

---

STEP 1 — Resource classes
Create 3 new resource scripts (all with class_name):

scripts/resources/chronicle_data.gd — class_name ChronicleData
  Top-level container wrapping all chronicle content.
  @export var entries: Array = []  # Array[ChronicleEntryData]
  @export var perks: Array = []    # Array[ChroniclePerkData]

scripts/resources/chronicle_entry_data.gd — class_name ChronicleEntryData
  @export var entry_id: String = ""
  @export var display_name: String = ""
  @export var description: String = ""
  @export var icon_id: String = ""
  @export var tracking_signal: String = ""  # SignalBus signal name to listen for
  @export var tracking_field: String = ""   # field from signal payload to accumulate
  @export var target_count: int = 1
  @export var reward_type: Types.ChronicleRewardType = Types.ChronicleRewardType.PERK
  @export var reward_id: String = ""

scripts/resources/chronicle_perk_data.gd — class_name ChroniclePerkData
  @export var perk_id: String = ""
  @export var display_name: String = ""
  @export var description: String = ""
  @export var effect_type: Types.ChroniclePerkEffectType = Types.ChroniclePerkEffectType.STARTING_GOLD
  @export var effect_value: float = 0.0

---

STEP 2 — Types.gd new enums
In types.gd, append:
  enum ChronicleRewardType { PERK = 0, COSMETIC = 1, TITLE = 2 }
  enum ChroniclePerkEffectType {
      STARTING_GOLD = 0, STARTING_MANA = 1, SELL_REFUND_PCT = 2,
      RESEARCH_COST_PCT = 3, GOLD_PER_KILL_PCT = 4,
      BUILDING_MATERIAL_START = 5, ENCHANTING_COST_PCT = 6,
      WAVE_REWARD_GOLD = 7, XP_GAIN_PCT = 8, COSMETIC_SKIN = 9,
  }

In FoulWardTypes.cs: mirror both enums with matching integer values.
Run: dotnet build FoulWard.csproj

---

STEP 3 — SignalBus: 3 new signals
File: autoloads/signal_bus.gd

Add:
  @warning_ignore("unused_signal")
  signal chronicle_entry_completed(entry_id: String)
  @warning_ignore("unused_signal")
  signal chronicle_perk_activated(perk_id: String)
  @warning_ignore("unused_signal")
  signal chronicle_progress_updated(entry_id: String, current: int, target: int)

Signal count: 73 → 76.

---

VERIFICATION:
- dotnet build passes
- ./tools/run_gdunit_quick.sh passes
- Signal count = 76
```

---

### CHAT 8B — ChronicleManager Autoload + Achievement/Perk .tres Data

```
@AGENTS.md @.cursor/skills/campaign-and-progression/SKILL.md

You are implementing the ChronicleManager autoload and achievement/perk data for Foul Ward.

CUMULATIVE STATE:
- SignalBus: 76 signals
- 18 autoloads. After this chat: 19 (ChronicleManager at Init #15).
- ChronicleEntryData, ChroniclePerkData resources + enums + signals exist (Chat 8A)

FIX REQUIRED (from plan):
- ChronicleManager goes at Init #15, NOT #14 (SybilPassiveManager is at #14).
- Remove entry_meta_first_run.tres — merge into entry_campaign_day_50 with description "Complete your first campaign."

---

STEP 1 — ChronicleManager autoload
Create autoloads/chronicle_manager.gd:
  No class_name (autoload convention).

  State:
    _entries: Dictionary = {}  # entry_id → {data, progress, completed}
    _perks: Dictionary = {}    # perk_id → ChroniclePerkData
    _active_perks: Array[String] = []
    _progress_file: String = "user://chronicle.json"

  _ready():
    Load all ChronicleEntryData .tres from resources/chronicle/entries/
    Load all ChroniclePerkData .tres from resources/chronicle/perks/
    Load progress from chronicle.json
    Connect to relevant SignalBus signals (enemy_killed, mission_won, building_placed, etc.)

  Key methods:
    _on_tracked_signal(...) — increment relevant entry counters, emit chronicle_progress_updated, check completion
    _check_completion(entry_id) — if counter >= target_count and not completed, mark complete, emit chronicle_entry_completed, grant reward
    _grant_reward(entry: ChronicleEntryData) — activate perk, emit chronicle_perk_activated
    apply_perks_at_mission_start() — called by GameManager, applies all active perks
    save_progress() — write chronicle.json with version key
    load_progress() — read chronicle.json, handle parse failure gracefully
    reset_for_test() — clear all progress (test utility)

Register as autoload Init #15 in project.godot.
Updated autoload order: ...13=SaveManager, 14=SybilPassiveManager, 15=ChronicleManager, 16=DialogueManager, 17=AutoTestDriver, 18=GDAIMCPRuntime, 19=EnchantmentManager.

---

STEP 2 — Achievement .tres files (17 entries — NOT 18, due to Fix 3)
Create resources/chronicle/entries/ folder.

Create these .tres files (entry_meta_first_run is MERGED into entry_campaign_day_50):
  entry_combat_first_blood.tres — tracking: enemy_killed, target: 1
  entry_combat_slayer_100.tres — tracking: enemy_killed, target: 100
  entry_combat_slayer_1000.tres — tracking: enemy_killed, target: 1000
  entry_combat_flying_hunter.tres — tracking: enemy_killed (flying only), target: 50
  entry_campaign_day_25.tres — tracking: mission_won, target: 25
  entry_campaign_day_50.tres — "Complete your first campaign" (FIX 3: merged), tracking: campaign_completed, target: 1
  entry_campaign_three_runs.tres — tracking: campaign_completed, target: 3
  entry_boss_first.tres — tracking: boss_killed, target: 1
  entry_boss_five.tres — tracking: boss_killed, target: 5
  entry_boss_all_types.tres — tracking: boss_killed (all unique types), target: placeholder
  entry_economy_gold_1000.tres — tracking: gold_earned, target: 1000
  entry_economy_gold_10000.tres — tracking: gold_earned, target: 10000
  entry_economy_research.tres — tracking: research_completed, target: 10
  entry_building_placed_25.tres — tracking: building_placed, target: 25
  entry_building_placed_100.tres — tracking: building_placed, target: 100
  entry_meta_ten_runs.tres — tracking: campaign_completed, target: 10
  (NO entry_meta_first_run.tres — merged per Fix 3)

---

STEP 3 — Perk .tres files (8 perks)
Create resources/chronicle/perks/ folder:
  perk_starting_gold_50.tres — STARTING_GOLD, value: 50
  perk_starting_mana_5.tres — STARTING_MANA, value: 5
  perk_sell_refund_2pct.tres — SELL_REFUND_PCT, value: 0.02
  perk_research_cost_5pct.tres — RESEARCH_COST_PCT, value: 0.05
  perk_gold_per_kill_2pct.tres — GOLD_PER_KILL_PCT, value: 0.02
  perk_building_material_start_5.tres — BUILDING_MATERIAL_START, value: 5
  perk_enchanting_cost_5pct.tres — ENCHANTING_COST_PCT, value: 0.05
  perk_wave_reward_gold_5.tres — WAVE_REWARD_GOLD, value: 5

---

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes
- project.godot shows ChronicleManager at Init #15
- 19 autoloads total
- 17 entry .tres + 8 perk .tres files exist
```

---

### CHAT 8C — Chronicle UI + Tests + Docs

```
@AGENTS.md @.cursor/skills/testing/SKILL.md

You are implementing the Chronicle UI, tests, and doc updates for Foul Ward.

CUMULATIVE STATE:
- SignalBus: 76 signals
- 19 autoloads (ChronicleManager at #15)
- ChronicleManager, entries, perks all implemented (Chats 8A + 8B)

---

STEP 1 — Chronicle UI
Create scenes/ui/chronicle_screen.tscn + scripts/ui/chronicle_screen.gd:
  Panel overlay with ScrollContainer → VBoxContainer of achievement rows.

Create scenes/ui/achievement_row_entry.tscn + scripts/ui/achievement_row_entry.gd:
  HBoxContainer: NameLabel, ProgressBar, RewardLabel
  setup(entry_data, progress, completed) → populate labels and bar

Chronicle screen: on show, iterate ChronicleManager entries, instantiate rows.
Connect to chronicle_progress_updated and chronicle_entry_completed for live updates.

Add "Chronicle" button to main menu (find main menu scene first — search codebase).

---

STEP 2 — GameManager apply_perks hook
File: autoloads/game_manager.gd

In start_mission_for_day() (or mission start flow), call:
  ChronicleManager.apply_perks_at_mission_start()
  (before wave sequence begins, after tier patch)

---

STEP 3 — Tests
Create tests/test_chronicle_manager.gd (GdUnit4, ~11 methods):
  test_entries_loaded — _entries not empty
  test_perks_loaded — _perks not empty
  test_increment_counter — manually trigger signal, verify counter increases
  test_completion_fires_signal — reach target, assert chronicle_entry_completed emitted
  test_perk_activation — complete entry with PERK reward, verify perk in active list
  test_apply_perks_no_crash_when_empty — apply with no active perks
  test_save_progress_creates_file — save, verify file exists
  test_load_progress_restores_counters — save, reset, load, verify
  test_load_progress_corrupt_json_no_crash — write invalid JSON, load, no crash
  test_reset_for_test_clears_all — reset, all counters 0
  test_entry_meta_first_run_does_not_exist — verify no entry with id "entry_meta_first_run" (Fix 3)

---

STEP 4 — Doc updates
Update in all tracked locations:
  - Signal count: 76
  - Autoload table: 19 autoloads, renumber from #14 onward
  - New files to INDEX_SHORT.md and INDEX_FULL.md
  - Update FOUL_WARD_MASTER_DOC.md §14 (Chronicle): planned → exists

---

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes
- All ~11 new tests pass
- Docs reflect 76 signals, 19 autoloads
```

---
---

## GROUP 9: S05 — Dialogue Content & Combat Lines (3 chats)

---

### CHAT 9A — Hub Talk Button + NPC Dialogue Content

```
@AGENTS.md @.cursor/skills/save-and-dialogue/SKILL.md

You are implementing hub dialogue content for Foul Ward.

CUMULATIVE STATE:
- SignalBus: 76 signals (unchanged this chat)
- 19 autoloads

---

STEP 1 — Hub "Talk" button visibility
Find the hub NPC UI scene (search for hub.tscn or between_mission_screen.tscn).

Add _refresh_talk_button() method to hub NPC UI script:
  func _refresh_talk_button() -> void:
    var entry = DialogueManager.request_entry_for_character(_character_id)
    talk_button.visible = (entry != null)

Call on: _ready(), SignalBus.dialogue_line_finished, SignalBus.mission_started.
Do NOT call mark_entry_played on visibility check — peek only.

---

STEP 2 — Dialogue .tres content (30 entries, 6 NPCs × 5 entries each)

For each NPC, create 5 DialogueEntry .tres files in resources/dialogue/{npc_folder}/:

COMPANION_MELEE (Arnulf) — gruff, dark humor, short sentences:
  INTRO_01 (priority=100, once_only=true, chain→INTRO_02): "Still alive, then. Good. I've buried worse men than you. Most of them deserved it."
  INTRO_02 (priority=100, once_only=true): "Name's Arnulf. Don't make me say it twice."
  RESEARCH_01 (priority=50, once_only=true, condition: sybil_research_unlocked_any): "Sybil's been muttering over those tomes again. Last time that happened something caught fire. Wasn't the tome."
  GENERIC_01 (priority=1, once_only=false): "I had a good shovel once. Buried three men with it. Miss that shovel."
  GENERIC_02 (priority=1, once_only=false): "Used to drink to forget. Now I just forget. Cheaper."

SPELL_RESEARCHER (Sybil) — scholarly, condescending, dry wit:
  INTRO_01 (chain→INTRO_02): "Ah. You've found your way to the research alcove. Surprising, given the general standard of navigation I've observed."
  INTRO_02: "I am Sybil. I study things that would unravel lesser minds. You may ask me questions. I will decide which ones merit answers."
  RESEARCH_01 (condition: sybil_research_unlocked_any): "The first node is unlocked. A humble beginning — like lighting a candle in a collapsing mine."
  GENERIC_01: "The ward's resonance frequency has shifted again. I've made notes. You wouldn't understand them."
  GENERIC_02: "Every spell is a hypothesis. The enemies are the peer review. So far, the methodology holds."

MERCHANT — pragmatic, friendly, profit-driven:
  INTRO_01 (chain→INTRO_02): "Welcome, welcome! Don't touch anything you can't afford to bleed on."
  INTRO_02: "Everything's priced fairly. For a given value of fair."
  RESEARCH_01 (condition: sybil_research_unlocked_any): "Heard Sybil cracked something open. Good for business — desperate people buy more."
  GENERIC_01: "Supply and demand. Supply goes down when things die. Demand goes up because things die."
  GENERIC_02: "I once sold a man his own boot back. He thanked me. Twice."

WEAPONS_ENGINEER — meticulous, technical:
  INTRO_01 (chain→INTRO_02): "Calibrated to three decimal places. Your weapon. Not you — you're not calibrated at all."
  INTRO_02: "I'm the reason your bolts go where you point. You're welcome."
  RESEARCH_01 (condition: sybil_research_unlocked_any): "Sybil's research changes the harmonic frequency of the ward's ley lines. Might need to recalibrate."
  GENERIC_01: "There are two types of problems: the ones I can fix, and the ones that will kill you first."
  GENERIC_02: "I've improved your weapon again. By which I mean I've undone the damage you've done to it."

ENCHANTER — mystical, slightly unhinged:
  INTRO_01 (chain→INTRO_02): "Oh, a visitor. The runes said someone would come. They also said something about fire. Best not dwell."
  INTRO_02: "I bind magic to metal. Don't ask how. The answer involves screaming."
  RESEARCH_01 (condition: sybil_research_unlocked_any): "Sybil thinks she understands the fundamentals. Adorable. The fundamentals screamed at me last Tuesday."
  GENERIC_01: "Every enchantment is a conversation with something that doesn't want to talk."
  GENERIC_02: "I touched a cursed gemstone once. Lost three days. Gained an appreciation for silence."

MERCENARY_COMMANDER — cynical veteran:
  INTRO_01 (chain→INTRO_02): "Gold up front. Half now, half when we're done. If we're done."
  INTRO_02: "My soldiers fight for coin. Yours fight for... whatever it is you've told them. Sounds cheaper."
  RESEARCH_01 (condition: sybil_research_unlocked_any): "Your mage learned something new? Great. My scouts say something new learned about us, too. From the swamp."
  GENERIC_01: "War's just commerce with worse margins."
  GENERIC_02: "Every battle plan survives until someone opens their mouth."

entry_id = filename stem uppercased. character_id = folder name constant.

---

STEP 3 — Add is_combat_line field
File: scripts/resources/dialogue_entry.gd (find actual path)
Add: @export var is_combat_line: bool = false
All hub entries above: is_combat_line = false (default).

---

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes
- 30 .tres files created
- is_combat_line field exists on DialogueEntry
```

---

### CHAT 9B — Combat Conditions + Banner UI + Combat .tres

```
@AGENTS.md @.cursor/skills/save-and-dialogue/SKILL.md @.cursor/skills/signal-bus/SKILL.md

You are implementing combat dialogue conditions and the combat banner UI for Foul Ward.

CUMULATIVE STATE:
- SignalBus: 76 signals. After this chat: 77-78 (depends on signals needing to be added).
- 19 autoloads (NO new autoload — combat dialogue folded into DialogueManager per Fix 4)
- Hub dialogue content + is_combat_line field done (Chat 9A)

FIX REQUIRED: Do NOT create a separate CombatDialogueManager autoload. Fold all combat dialogue logic into the existing DialogueManager.

---

STEP 1 — Combat condition keys in DialogueManager
File: autoloads/dialogue_manager.gd

Add per-mission state tracking variables:
  var _combat_kills_this_mission: int = 0
  var _combat_wave_number: int = 0
  var _combat_boss_seen: bool = false
  var _combat_first_blood: bool = false
  var _combat_florence_damaged: bool = false
  var _seen_combat_lines: Dictionary = {}  # per-mission first-seen tracking

Add _resolve_state_value() cases for combat condition keys:
  "wave_number_gte" → _combat_wave_number >= value
  "kills_this_mission_gte" → _combat_kills_this_mission >= value
  "boss_active" → _combat_boss_seen
  "first_blood" → _combat_first_blood
  "florence_damaged" → _combat_florence_damaged

Connect to relevant signals in _ready() (with is_connected guard):
  SignalBus.enemy_killed → increment _combat_kills_this_mission, set _combat_first_blood
  SignalBus.wave_started → update _combat_wave_number
  SignalBus.mission_started → reset all per-mission combat state
  SignalBus.florence_damaged (if exists) → set _combat_florence_damaged

CHECK: Verify enemy_spawned and florence_damaged signals exist on SignalBus. If florence_damaged is missing, add it (update signal count accordingly). If enemy_spawned is missing, add it.

Add method:
  func request_combat_line() -> DialogueEntry:
    Filter all entries where is_combat_line == true and conditions met and not in _seen_combat_lines.
    Return highest priority match, or null.

---

STEP 2 — CombatDialogueBanner UI
Create scenes/ui/combat_dialogue_banner.tscn + scripts/ui/combat_dialogue_banner.gd:
  Panel at top of screen with Label for text, auto-dismiss after duration.
  Queue system: if new line arrives while showing, reset timer.
  Dedup: don't show same line twice per mission (use _seen_combat_lines).

Connect to a new signal or have DialogueManager periodically check for eligible lines:
  signal combat_dialogue_requested(entry: DialogueEntry)
  (Add to SignalBus if needed — update signal count)

Banner script: connect to combat_dialogue_requested, show text, auto-hide after ~4 seconds.

---

STEP 3 — Combat dialogue .tres (10 entries)
Create 10 combat dialogue .tres files in resources/dialogue/combat/:
  All with is_combat_line = true. Write dramatic mid-battle lines appropriate for each trigger.
  Example entries:
    combat_first_blood — condition: first_blood, Florence: "First blood. Keep them coming."
    combat_wave_3 — condition: wave_number_gte=3, Sybil: "Third wave. The pattern is escalating."
    combat_boss_appears — condition: boss_active, Arnulf: "Big one's here. Finally."
    combat_florence_hit — condition: florence_damaged, Florence: "They're getting through!"
    combat_kill_50 — condition: kills_this_mission_gte=50, Arnulf: "Fifty down. Not bad."
    (Write 5 more in similar style)

---

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes
- No new autoload created (all in DialogueManager)
- Update signal count if new signals added
```

---

### CHAT 9C — Signal Audit + Tests + Docs

```
@AGENTS.md @.cursor/skills/testing/SKILL.md @.cursor/skills/signal-bus/SKILL.md

You are auditing signals and writing tests for the dialogue system changes.

CUMULATIVE STATE:
- SignalBus: 77-78 signals (verify by counting ^signal lines)
- 19 autoloads
- Hub dialogue, combat conditions, combat banner all implemented (Chats 9A + 9B)

---

STEP 1 — Signal audit
Count all ^signal lines in autoloads/signal_bus.gd. Record the exact count.
Verify all signals used by DialogueManager combat logic exist.
If any are missing (e.g. florence_damaged, combat_dialogue_requested), add them.

---

STEP 2 — Tests
Create tests/test_dialogue_content.gd (GdUnit4):
  test_all_30_hub_entries_load — load all 30 .tres, none null
  test_all_entries_have_character_id — every entry has non-empty character_id
  test_intro_entries_are_once_only — all INTRO entries have once_only == true
  test_generic_entries_are_repeatable — all GENERIC entries have once_only == false
  test_chain_next_ids_valid — if chain_next_id != "", that entry exists
  test_combat_entries_have_is_combat_line — all combat .tres have is_combat_line == true

Create tests/test_combat_dialogue.gd (GdUnit4):
  test_request_combat_line_returns_null_initially — no conditions met
  test_first_blood_triggers_line — simulate enemy kill, request line
  test_wave_number_condition — set wave to 3, verify wave_number_gte=3 entries eligible
  test_seen_lines_not_repeated — request same line twice, second returns null
  test_mission_reset_clears_seen — reset, previously seen line available again
  test_combat_banner_no_crash_headless — banner shows/hides without UI nodes

---

STEP 3 — Doc updates
Update signal count to actual value in all tracked locations.
Add 40+ new .tres files to INDEX_SHORT.md and INDEX_FULL.md.

---

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes
- All new tests pass
- Signal count in docs matches actual count in signal_bus.gd
```

---
---

## GROUP 10: S06 — Shop Rotation & Economy Tuning (2 chats)

---

### CHAT 10A — ShopItemData Schema + Rotation Logic + New Items

```
@AGENTS.md @.cursor/skills/economy-system/SKILL.md

You are implementing the shop rotation system for Foul Ward.

CUMULATIVE STATE:
- SignalBus: ~77-78 signals (unchanged this chat)
- 19 autoloads

---

STEP 1 — ShopItemData schema update
File: scripts/resources/shop_item_data.gd

- Remove @export var item_type: String = ""
- Add @export var category: String = ""  # "consumable" | "equipment" | "voucher"
- Add @export var rarity_weight: float = 1.0

---

STEP 2 — ShopManager rotation logic
File: scripts/shop_manager.gd (find actual location)

Add constants:
  const DAILY_ITEMS_MIN: int = 4
  const DAILY_ITEMS_MAX: int = 6

Add _get_rng_for_day(day_index: int) -> RandomNumberGenerator:
  Isolated RNG with seed = day_index. Never use randf() or global RNG.

Add get_daily_items(day_index: int) -> Array[ShopItemData]:
  Algorithm:
  1. Build candidate pool = catalog items NOT excluded (consumable at stack cap excluded)
  2. Partition into consumables, equipment, vouchers
  3. If consumables or equipment bucket empty → push_warning, return []
  4. Pick 1 guaranteed consumable (weighted by rarity_weight using rng.rand_weighted())
  5. Pick 1 guaranteed equipment (weighted)
  6. Fill remaining slots (total 4-6) from full remaining pool, weighted, no replacement
  7. Return final array

---

STEP 3 — New shop items in catalog
File: resources/shop_data/shop_catalog.tres

Update existing 4 items: replace item_type with category, add rarity_weight = 1.0.

Add 11 new ShopItemData sub-resources:
  building_material_pack: equipment, gold=60, value=10
  research_boost: equipment, gold=80, value=3, weight=0.8
  tower_armor_plate: equipment, gold=100, value=50, weight=0.7
  fire_oil_flask: consumable, gold=70, value=5, tags=["fire_oil"]
  scout_report: equipment, gold=50, weight=1.1
  mercenary_discount: equipment, gold=40, value=20, weight=0.9
  emergency_repair: consumable, gold=90, value=25, tags=["emergency_repair"], weight=0.9
  shield_charm: consumable, gold=110, value=80, duration=10.0, tags=["shield"], weight=0.7
  gold_cache: consumable, gold=30, value=75, tags=["gold_bonus"], weight=1.2
  arrow_tower_voucher_2: voucher, gold=120, weight=0.6
  mana_elixir: consumable, gold=55, value=50, tags=["mana_restore"]

---

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes
- shop_catalog.tres has 15 total items
- get_daily_items() returns 4-6 items deterministically
```

---

### CHAT 10B — Effect Dispatch + Stubs + SimBot + Tests

```
@AGENTS.md @.cursor/skills/testing/SKILL.md @.cursor/skills/economy-system/SKILL.md

You are implementing shop effect dispatch, stubs, and tests for Foul Ward.

CUMULATIVE STATE:
- SignalBus: ~77-78 signals
- 19 autoloads
- ShopItemData schema + rotation + 15 items done (Chat 10A)

---

STEP 1 — Extend ShopManager effect dispatch
File: scripts/shop_manager.gd

Add match cases in _apply_effect() for new items:
  building_material_pack → EconomyManager.add_building_material(value)
  research_boost → EconomyManager.add_research_material(value)
  tower_armor_plate → Tower.add_max_hp_bonus(value) with null guard
  scout_report → WaveManager.reveal_next_wave_composition() with null guard
  mercenary_discount → CampaignManager.set_next_mercenary_discount(value/100.0) with null guard
  arrow_tower_voucher_2 → _arrow_tower_shop_pending = true

Add consumable effect tag cases:
  fire_oil → WeaponUpgradeManager.add_fire_oil_charges(value) with null guard
  emergency_repair → Tower.heal_percent_max_hp(value/100.0) with null guard

All method calls use has_method() guard + push_warning on failure.

---

STEP 2 — Stub methods on target nodes
Tower (find script path first):
  func add_max_hp_bonus(amount: int) -> void: push_warning("not yet fully implemented")
  func heal_percent_max_hp(fraction: float) -> void: push_warning("not yet fully implemented")

WaveManager (scripts/wave_manager.gd):
  func reveal_next_wave_composition() -> void: push_warning("not yet fully implemented")

CampaignManager (autoloads/campaign_manager.gd):
  func set_next_mercenary_discount(fraction: float) -> void: push_warning("not yet fully implemented")

---

STEP 3 — SimBot strategy profiles
Pure data changes:
  strategy_balanced_default.tres: difficulty_target = 0.5
  strategy_greedy_econ.tres: difficulty_target = 0.3
  strategy_heavy_fire.tres: difficulty_target = 0.7

---

STEP 4 — Tests
Create tests/test_shop_rotation.gd (GdUnit4, ~8 methods):
  test_get_daily_items_count_in_range — 4-6 items
  test_get_daily_items_deterministic — same day → same items
  test_get_daily_items_different_days_differ
  test_get_daily_items_always_has_consumable
  test_get_daily_items_always_has_equipment
  test_get_daily_items_excludes_capped_consumables
  test_get_daily_items_returns_empty_when_no_consumable
  test_simbot_difficulty_targets — load 3 profiles, verify values

Build test catalog in-code using ShopItemData.new() — no .tres needed for tests.

---

VERIFICATION:
- ./tools/run_gdunit_quick.sh passes
- All ~8 new tests pass
```

---
---

## GROUP 11: Final Reconciliation (1 chat)

---

### CHAT 11A — Full Project Reconciliation

```
@AGENTS.md @.cursor/skills/signal-bus/SKILL.md @.cursor/skills/testing/SKILL.md @docs/PERPLEXITY_RECONCILIATION_TRACKER.md

You are performing the final reconciliation pass for the 10-session Perplexity implementation.

This is the LAST session. Verify everything is consistent.

---

STEP 1 — Signal count verification
Count all ^signal lines in autoloads/signal_bus.gd. Expected: 77-78.
The exact count depends on whether florence_damaged and combat_dialogue_requested were added in Group 9.
Record the actual number.

---

STEP 2 — Autoload order verification
Read project.godot autoload section. Verify order matches:
  1-13: unchanged (SignalBus through SaveManager)
  14: SybilPassiveManager
  15: ChronicleManager
  16: DialogueManager
  17: AutoTestDriver
  18: GDAIMCPRuntime
  19: EnchantmentManager

---

STEP 3 — C# build
Run: dotnet build FoulWard.csproj
Verify FoulWardTypes.cs mirrors ALL new GDScript enums:
  GraphicsQuality, DifficultyTier, ChronicleRewardType, ChroniclePerkEffectType
  GameState has PASSIVE_SELECT=11, RING_ROTATE=12

---

STEP 4 — Full test suite
Run: ./tools/run_gdunit.sh (sequential baseline)
Record total test count. Expected: ~700+.
Fix any failures.

---

STEP 5 — Doc sync
Update ALL signal count locations to actual number:
  AGENTS.md, docs/FOUL_WARD_MASTER_DOC.md, docs/CONVENTIONS.md, docs/ARCHITECTURE.md,
  docs/INDEX_SHORT.md, docs/INDEX_FULL.md,
  .cursor/skills/signal-bus/SKILL.md, .cursor/skills/signal-bus/references/signal-table.md

Update test count in AGENTS.md and FOUL_WARD_MASTER_DOC.md.
Update AGENTS.md: "24 slots across 3 rings" → "42 slots across 3 rings"
Update autoload count: 17 → 19
Verify all new files appear in INDEX_SHORT.md and INDEX_FULL.md.

---

STEP 6 — Update reconciliation tracker
File: docs/PERPLEXITY_RECONCILIATION_TRACKER.md
Fill in all "Actual" columns with real values.
Mark all spec corrections as applied.
Mark all FoulWardTypes.cs mirrors as done.

---

STEP 7 — Implementation log
Create docs/PROMPT_[N]_IMPLEMENTATION.md (use next unused N).
Document: what was implemented, test count before/after, signal count before/after, any deviations from spec.

---

VERIFICATION:
- dotnet build passes
- ./tools/run_gdunit.sh passes with 0 failures
- All doc counts match actual counts
- PERPLEXITY_RECONCILIATION_TRACKER.md fully filled
```
