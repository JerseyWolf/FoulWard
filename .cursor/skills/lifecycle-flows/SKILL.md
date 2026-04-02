---
name: lifecycle-flows
description: >-
  Activate when implementing or debugging mission flow, game loop, startup
  sequence, wave sequence, or tower destruction in Foul Ward. Use when:
  lifecycle, flow, mission cycle, game loop, startup, new game, mission start,
  mission end, wave sequence, between missions, tower destroyed, mission failed,
  mission won, build phase start, enemy spawn flow, all_waves_cleared.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Lifecycle Flows — Foul Ward

---

## Flow 1: Full Mission Cycle (§27.1)

GameManager.start_new_game()
└─ CampaignManager.start_new_campaign() # resets day to 1
└─ EconomyManager.reset_to_defaults()
└─ emit game_state_changed → MISSION_BRIEFING

Player confirms briefing:
└─ GameManager.start_wave_countdown()
└─ BuildPhaseManager.set_build_phase_active(true) → SignalBus.build_phase_started
└─ emit build_mode_entered

Player exits build mode / wave countdown begins:
└─ BuildPhaseManager.set_build_phase_active(false) → SignalBus.combat_phase_started
└─ WaveManager.start_wave_sequence()
└─ emit game_state_changed → COMBAT

COMBAT LOOP (per wave):
└─ WaveManager emits wave_started(wave_number, enemy_count)
└─ Enemies spawn at SpawnPoints
└─ [enemies path toward Tower]
└─ WaveManager emits wave_cleared(wave_number) when all enemies dead
└─ EconomyManager.grant_wave_clear_reward(wave, day_config.economy)
└─ Repeat until wave == WAVES_PER_MISSION

All waves cleared:
└─ WaveManager emits all_waves_cleared
└─ SaveManager.save_current_state() # automatic — do not add extra save calls
└─ emit mission_won(mission_number)
└─ game_state_changed → MISSION_WON → BETWEEN_MISSIONS

Between missions:
└─ CampaignManager.start_next_day()
└─ GameManager.advance_to_next_day()
└─ game_state_changed → MISSION_BRIEFING # loop for next day

Campaign complete (day 50):
└─ game_state_changed → GAME_WON

Tower destroyed alternative path:
└─ SignalBus.tower_destroyed emitted
└─ SaveManager.save_current_state() # automatic
└─ emit mission_failed(mission_number)
└─ game_state_changed → MISSION_FAILED → BETWEEN_MISSIONS


---

## Flow 2: Building Placement (§27.2)

Player clicks hex slot (HexGrid Area3D, Layer 7)
└─ BuildPhaseManager.assert_build_phase("placement") → must be true
└─ EconomyManager.can_afford_building(building_data) → must be true
└─ building: BuildingBase = BuildingScene.instantiate()
└─ building.initialize(building_data, slot_index) # BEFORE add_child
└─ HexGrid.add_child(building)
└─ EconomyManager.register_purchase(building_data)
└─ If aura: AuraManager.register_aura(building)
└─ If summoner: AllyManager.spawn_squad(building)
└─ SignalBus.building_placed.emit(slot_index, building_type)

Sell flow:
└─ refund = EconomyManager.get_refund(building_data, paid_gold, paid_material)
└─ EconomyManager.add_gold(refund.gold)
└─ EconomyManager.add_building_material(refund.material)
└─ If aura: AuraManager.deregister_aura(building.placed_instance_id)
└─ If summoner: AllyManager.despawn_squad(building.placed_instance_id)
└─ building.queue_free()
└─ SignalBus.building_sold.emit(slot_index, building_type)


---

## Flow 3: Enemy Reaching Tower (§27.3)

Enemy NavigationAgent3D reaches tower proximity (or target distance)
└─ enemy.on_reached_tower()
└─ SignalBus.tower_damaged.emit(tower.current_hp - enemy.damage, tower.max_hp)
└─ tower.current_hp -= enemy.damage
└─ enemy.queue_free() # deferred

If tower.current_hp <= 0:
└─ SignalBus.tower_destroyed.emit()
└─ [triggers mission failed path above]

Any system holding enemy reference:
└─ MUST call is_instance_valid(enemy_ref) before accessing
└─ enemy.queue_free() is deferred — reference may be valid one frame after


---

## Build Mode Mid-Combat

GameManager.enter_build_mode()
└─ Engine.time_scale = 0.1 # slow-mo during build
└─ BuildPhaseManager.set_build_phase_active(true) → SignalBus.build_phase_started
└─ game_state_changed → BUILD_MODE

GameManager.exit_build_mode()
└─ Engine.time_scale = 1.0
└─ BuildPhaseManager.set_build_phase_active(false) → SignalBus.combat_phase_started
└─ game_state_changed → COMBAT
