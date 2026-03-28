Godot Engine v4.6.1.stable.official.14d19694e - https://godotengine.org

[GameManager] _ready: initial state=MAIN_MENU
[91mERR[39m [23:51:11] [GDAIRuntimeServer] Runtime server failed to start: Port 3572 is already in use.[0m
[2J[H[38;2;233;150;122m
--------------------------------------------------------------------------------------------------
GdUnit4 Comandline Tool
--------------------------------------------------------------------------------------------------[0m
[38;2;218;165;32m
Headless mode is ignored by option '--ignoreHeadlessMode'"

Please note that tests that use UI interaction do not work correctly in headless mode.
Godot 'InputEvents' are not transported by the Godot engine in headless mode and therefore
have no effect in the test!
[0m
Scanning for test suites in: res://tests
[38;2;0;206;209mRun Test Suite: [0m[38;2;250;235;215mres://tests/test_ally_base.gd[0m
  [38;2;250;235;215mres://tests/test_ally_base.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_melee_ally_find_target_returns_nearest_enemy[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
[Tower] _ready: hp=500 auto_fire=false crossbow_reload=2.5s
[Arnulf] _ready: hp=200 move_speed=5.0 patrol_radius=55
[Arnulf] state → IDLE  (target=none)
[HexGrid] _ready: building_data_registry size=8
[HexGrid] _ready: ResearchManager found=true
[HexGrid] _ready: 24 slots initialized
[WaveManager] _ready: enemy_data_registry size=6
[InputManager] _ready
[BuildMenu] _ready
[Enemy] initialized:   hp=200 speed=0.0 flying=false pos=(0,0,0)
  [38;2;250;235;215mres://tests/test_ally_base.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_melee_ally_find_target_returns_nearest_enemy[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 88ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_ally_base.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_melee_ally_attacks_enemy_in_range[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
[Tower] _ready: hp=500 auto_fire=false crossbow_reload=2.5s
[Arnulf] _ready: hp=200 move_speed=5.0 patrol_radius=55
[Arnulf] state → IDLE  (target=none)
[HexGrid] _ready: building_data_registry size=8
[HexGrid] _ready: ResearchManager found=true
[HexGrid] _ready: 24 slots initialized
[WaveManager] _ready: enemy_data_registry size=6
[InputManager] _ready
[BuildMenu] _ready
[Enemy] initialized:   hp=200 speed=0.0 flying=false pos=(0,0,0)
[Arnulf] state → CHASE  (target=)
  [38;2;250;235;215mres://tests/test_ally_base.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_melee_ally_attacks_enemy_in_range[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 2s 579ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_ally_base.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_ally_hp_decreases_and_uses_health_component[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_ally_base.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_ally_hp_decreases_and_uses_health_component[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 106ms[0m
[38;2;250;235;215m[0m
[38;2;30;144;255mStatistics:[0m[38;2;250;235;215m 3 tests cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans |[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 3s 522ms[0m
[38;2;250;235;215m[0m
[38;2;250;235;215m[0m
[38;2;0;206;209mRun Test Suite: [0m[38;2;250;235;215mres://tests/test_territory_economy_bonuses.gd[0m
  [38;2;250;235;215mres://tests/test_territory_economy_bonuses.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_controlled_territory_increases_end_of_day_gold[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_territory_economy_bonuses.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_controlled_territory_increases_end_of_day_gold[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 42ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_territory_economy_bonuses.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_lost_territory_bonus_does_not_apply[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_territory_economy_bonuses.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_lost_territory_bonus_does_not_apply[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 18ms[0m
[38;2;250;235;215m[0m
[38;2;30;144;255mStatistics:[0m[38;2;250;235;215m 2 tests cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans |[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 85ms[0m
[38;2;250;235;215m[0m
[38;2;250;235;215m[0m
[38;2;0;206;209mRun Test Suite: [0m[38;2;250;235;215mres://tests/test_health_component.gd[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_initial_hp_equals_max_hp[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_initial_hp_equals_max_hp[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 39ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_is_alive_true_on_init[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_is_alive_true_on_init[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 6ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_reduces_current_hp[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_reduces_current_hp[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 19ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_clamps_to_zero_not_negative[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_clamps_to_zero_not_negative[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 12ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_emits_health_changed[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_emits_health_changed[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 25ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_to_zero_emits_health_depleted[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_to_zero_emits_health_depleted[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 28ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_to_zero_sets_is_alive_false[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_to_zero_sets_is_alive_false[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 1ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_health_depleted_emitted_exactly_once_not_twice[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_health_depleted_emitted_exactly_once_not_twice[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 18ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_when_dead_does_not_emit_health_changed[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_when_dead_does_not_emit_health_changed[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 10ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_when_dead_hp_stays_at_zero[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_when_dead_hp_stays_at_zero[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 0ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_partial_does_not_emit_health_depleted[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_partial_does_not_emit_health_depleted[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 25ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_float_fractional_part_truncated[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_float_fractional_part_truncated[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 7ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_exactly_one_hp_remaining_is_still_alive[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_exactly_one_hp_remaining_is_still_alive[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 21ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_sequential_calls_accumulate_correctly[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_sequential_calls_accumulate_correctly[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 15ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_heal_increases_current_hp[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_heal_increases_current_hp[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 6ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_heal_clamps_to_max_hp[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_heal_clamps_to_max_hp[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 6ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_heal_at_full_hp_stays_at_max[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_heal_at_full_hp_stays_at_max[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 1ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_heal_emits_health_changed[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_heal_emits_health_changed[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 25ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_heal_does_not_revive_dead_entity[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_heal_does_not_revive_dead_entity[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 1ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_heal_on_dead_entity_hp_still_clamps_to_max[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_heal_on_dead_entity_hp_still_clamps_to_max[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 15ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_reset_to_max_restores_full_hp[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_reset_to_max_restores_full_hp[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 15ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_reset_to_max_sets_is_alive_true_after_death[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_reset_to_max_sets_is_alive_true_after_death[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 45ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_reset_to_max_emits_health_changed[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_reset_to_max_emits_health_changed[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 30ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_reset_to_max_allows_health_depleted_to_fire_again[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_reset_to_max_allows_health_depleted_to_fire_again[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 38ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_reset_to_max_on_full_hp_still_emits_health_changed[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_reset_to_max_on_full_hp_still_emits_health_changed[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 33ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_reset_to_max_full_cycle_damage_reset_damage[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_reset_to_max_full_cycle_damage_reset_damage[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 1ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_is_alive_true_when_hp_above_zero[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_is_alive_true_when_hp_above_zero[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 9ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_is_alive_false_after_lethal_damage[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_is_alive_false_after_lethal_damage[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 27ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_is_alive_true_after_reset_to_max[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_is_alive_true_after_reset_to_max[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 40ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_health_changed_payload_current_hp_correct_after_damage[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_health_changed_payload_current_hp_correct_after_damage[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 46ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_health_changed_payload_max_hp_correct[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_health_changed_payload_max_hp_correct[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 27ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_health_changed_payload_after_heal_correct[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_health_changed_payload_after_heal_correct[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 28ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_different_max_hp_export_uses_correct_starting_hp[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_different_max_hp_export_uses_correct_starting_hp[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 12ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_on_custom_max_hp_clamps_correctly[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_health_component.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_take_damage_on_custom_max_hp_clamps_correctly[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 19ms[0m
[38;2;250;235;215m[0m
[38;2;30;144;255mStatistics:[0m[38;2;250;235;215m 34 tests cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans |[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 1s 313ms[0m
[38;2;250;235;215m[0m
[38;2;250;235;215m[0m
[38;2;0;206;209mRun Test Suite: [0m[38;2;250;235;215mres://tests/test_enemy_pathfinding.gd[0m
  [38;2;250;235;215mres://tests/test_enemy_pathfinding.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_ground_enemy_paths_around_buildings_reaches_tower[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
[Tower] _ready: hp=500 auto_fire=false crossbow_reload=2.5s
[Arnulf] _ready: hp=200 move_speed=5.0 patrol_radius=55
[Arnulf] state → IDLE  (target=none)
[HexGrid] _ready: building_data_registry size=8
[HexGrid] _ready: ResearchManager found=true
[HexGrid] _ready: 24 slots initialized
[WaveManager] _ready: enemy_data_registry size=6
[InputManager] _ready
[BuildMenu] _ready
[GameManager] start_new_game: mission=1  gold=1000 mat=50
[GameManager] state: MAIN_MENU → COMBAT
[GameManager] _begin_mission_wave_sequence: mission=1
[WaveManager] start_wave_sequence
[WaveManager] countdown started: wave=1 duration=3.0s
[HexGrid] place_building: slot=0 type=0 charge=true  gold=21000 mat=2050
[Building] initialized: Arrow Tower  dmg=20 range=15.0 fire_rate=1.00  air=false gnd=true
[HexGrid] place_building SUCCESS: slot=0 type=0 at pos=(6.0,0.0,0.0)  remaining gold=20950 mat=2048
[HexGrid] place_building: slot=1 type=0 charge=true  gold=20950 mat=2048
[Building] initialized: Arrow Tower  dmg=20 range=15.0 fire_rate=1.00  air=false gnd=true
[HexGrid] place_building SUCCESS: slot=1 type=0 at pos=(3.0,0.0,5.2)  remaining gold=20900 mat=2046
[HexGrid] place_building: slot=2 type=0 charge=true  gold=20900 mat=2046
[Building] initialized: Arrow Tower  dmg=20 range=15.0 fire_rate=1.00  air=false gnd=true
[HexGrid] place_building SUCCESS: slot=2 type=0 at pos=(-3.0,0.0,5.2)  remaining gold=20850 mat=2044
[HexGrid] place_building: slot=3 type=0 charge=true  gold=20850 mat=2044
[Building] initialized: Arrow Tower  dmg=20 range=15.0 fire_rate=1.00  air=false gnd=true
[HexGrid] place_building SUCCESS: slot=3 type=0 at pos=(-6.0,0.0,0.0)  remaining gold=20800 mat=2042
[HexGrid] place_building: slot=4 type=0 charge=true  gold=20800 mat=2042
[Building] initialized: Arrow Tower  dmg=20 range=15.0 fire_rate=1.00  air=false gnd=true
[HexGrid] place_building SUCCESS: slot=4 type=0 at pos=(-3.0,0.0,-5.2)  remaining gold=20750 mat=2040
[HexGrid] place_building: slot=5 type=0 charge=true  gold=20750 mat=2040
[Building] initialized: Arrow Tower  dmg=20 range=15.0 fire_rate=1.00  air=false gnd=true
[HexGrid] place_building SUCCESS: slot=5 type=0 at pos=(3.0,0.0,-5.2)  remaining gold=20700 mat=2038
[Enemy] initialized: Orc Grunt  hp=80 speed=3.0 flying=false pos=(0,0,0)
[Enemy] initialized: Orc Brute  hp=200 speed=2.0 flying=false pos=(0,0,0)
[Enemy] initialized: Goblin Firebug  hp=60 speed=4.0 flying=false pos=(0,0,0)
[Enemy] initialized: Plague Zombie  hp=120 speed=1.5 flying=false pos=(0,0,0)
[Enemy] initialized: Orc Archer  hp=70 speed=2.5 flying=false pos=(0,0,0)
[Enemy] initialized: Bat Swarm  hp=40 speed=5.0 flying=true pos=(0,0,0)
[WaveManager] wave 1 spawned: 6 enemies total
[Arnulf] state → CHASE  (target=Plague Zombie)
[Arnulf] state → ATTACK  (target=Plague Zombie)
[Arnulf] state → CHASE  (target=Plague Zombie)
[Arnulf] state → ATTACK  (target=Plague Zombie)
[Tower] take_damage: 8  hp=500→492
[Tower] take_damage: 8  hp=492→484
[Tower] take_damage: 8  hp=484→476
[Tower] take_damage: 8  hp=476→468
[Tower] take_damage: 8  hp=468→460
[Enemy] DIED: Plague Zombie  rewarding 12 gold
[Arnulf] state → CHASE  (target=Plague Zombie)
[Tower] take_damage: 8  hp=460→452
[Tower] take_damage: 8  hp=452→444
[Tower] take_damage: 8  hp=444→436
[Tower] take_damage: 8  hp=436→428
[Tower] take_damage: 8  hp=428→420
[Tower] take_damage: 8  hp=420→412
[Tower] take_damage: 8  hp=412→404
[Tower] take_damage: 8  hp=404→396
[Tower] take_damage: 8  hp=396→388
[Tower] take_damage: 8  hp=388→380
[Tower] take_damage: 8  hp=380→372
[Tower] take_damage: 8  hp=372→364
[Tower] take_damage: 8  hp=364→356
[Tower] take_damage: 8  hp=356→348
[Tower] take_damage: 8  hp=348→340
[Tower] take_damage: 8  hp=340→332
[Arnulf] state → ATTACK  (target=Goblin Firebug)
[Tower] take_damage: 8  hp=332→324
[Tower] take_damage: 8  hp=324→316
[Tower] take_damage: 8  hp=316→308
[Tower] take_damage: 8  hp=308→300
[Enemy] DIED: Goblin Firebug  rewarding 15 gold
[Arnulf] state → CHASE  (target=Goblin Firebug)
[Tower] take_damage: 8  hp=300→292
[Tower] take_damage: 8  hp=292→284
[Tower] take_damage: 8  hp=284→276
[Tower] take_damage: 8  hp=276→268
[Tower] take_damage: 8  hp=268→260
[Tower] take_damage: 8  hp=260→252
[Tower] take_damage: 8  hp=252→244
[Tower] take_damage: 8  hp=244→236
[Tower] take_damage: 8  hp=236→228
[Tower] take_damage: 8  hp=228→220
[Arnulf] state → ATTACK  (target=Orc Brute)
[Tower] take_damage: 8  hp=220→212
[Tower] take_damage: 8  hp=212→204
[Tower] take_damage: 8  hp=204→196
[Tower] take_damage: 8  hp=196→188
[Tower] take_damage: 8  hp=188→180
[Tower] take_damage: 8  hp=180→172
[Tower] take_damage: 8  hp=172→164
[Arnulf] state → CHASE  (target=Orc Brute)
  [38;2;250;235;215mres://tests/test_enemy_pathfinding.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_ground_enemy_paths_around_buildings_reaches_tower[0m[38;2;34;139;34m PASSED[0m[38;2;100;149;237m 56s 710ms[0m
[38;2;250;235;215m[0m
  [38;2;250;235;215mres://tests/test_enemy_pathfinding.gd[0m[38;2;250;235;215m > [0m[38;2;250;235;215mtest_ground_enemy_paths_to_tower_without_buildings_unchanged[0m[38;2;34;139;34m STARTED[0m[38;2;250;235;215m[0m
[Tower] _ready: hp=500 auto_fire=false crossbow_reload=2.5s
[Arnulf] _ready: hp=200 move_speed=5.0 patrol_radius=55
[Arnulf] state → IDLE  (target=none)
[HexGrid] _ready: building_data_registry size=8
[HexGrid] _ready: ResearchManager found=true
[HexGrid] _ready: 24 slots initialized
[WaveManager] _ready: enemy_data_registry size=6
[InputManager] _ready
[BuildMenu] _ready
[GameManager] start_new_game: mission=1  gold=20727 mat=2038
[GameManager] state: COMBAT → COMBAT
[GameManager] _begin_mission_wave_sequence: mission=1
[WaveManager] start_wave_sequence
[WaveManager] countdown started: wave=1 duration=3.0s
[Enemy] initialized: Orc Grunt  hp=80 speed=3.0 flying=false pos=(0,0,0)
[Enemy] initialized: Orc Brute  hp=200 speed=2.0 flying=false pos=(0,0,0)
[Enemy] initialized: Goblin Firebug  hp=60 speed=4.0 flying=false pos=(0,0,0)
[Enemy] initialized: Plague Zombie  hp=120 speed=1.5 flying=false pos=(0,0,0)
[Enemy] initialized: Orc Archer  hp=70 speed=2.5 flying=false pos=(0,0,0)
[Enemy] initialized: Bat Swarm  hp=40 speed=5.0 flying=true pos=(0,0,0)
[WaveManager] wave 1 spawned: 6 enemies total
[Arnulf] state → CHASE  (target=Orc Archer)
[Arnulf] state → ATTACK  (target=Orc Archer)
[Arnulf] state → CHASE  (target=Orc Archer)
[Arnulf] state → ATTACK  (target=Orc Archer)
[Tower] take_damage: 8  hp=500→492
[Enemy] DIED: Orc Archer  rewarding 20 gold
[Arnulf] state → CHASE  (target=Orc Archer)
[Tower] take_damage: 8  hp=492→484
[Tower] take_damage: 8  hp=484→476
[Tower] take_damage: 8  hp=476→468
[Tower] take_damage: 8  hp=468→460
[Tower] take_damage: 8  hp=460→452
[Tower] take_damage: 8  hp=452→444
[Tower] take_damage: 8  hp=444→436
[Tower] take_damage: 8  hp=436→428
[Tower] take_damage: 8  hp=428→420
[Tower] take_damage: 8  hp=420→412
[Tower] take_damage: 8  hp=412→404
[Tower] take_damage: 8  hp=404→396
[Tower] take_damage: 8  hp=396→388
[Tower] take_damage: 8  hp=388→380
[Tower] take_damage: 8  hp=380→372
[Tower] take_damage: 8  hp=372→364
[Tower] take_damage: 8  hp=364→356
[Arnulf] state → ATTACK  (target=Goblin Firebug)
[Tower] take_damage: 8  hp=356→348
[Tower] take_damage: 8  hp=348→340
[Tower] take_damage: 8  hp=340→332
[Tower] take_damage: 8  hp=332→324
[Enemy] DIED: Goblin Firebug  rewarding 15 gold
[Arnulf] state → CHASE  (target=Goblin Firebug)
[Tower] take_damage: 8  hp=324→316
[Tower] take_damage: 8  hp=316→308
[Tower] take_damage: 8  hp=308→300
[Tower] take_damage: 8  hp=300→292
[Tower] take_damage: 8  hp=292→284
[Tower] take_damage: 8  hp=284→276
[Tower] take_damage: 8  hp=276→268
[Tower] take_damage: 8  hp=268→260
[Tower] take_damage: 8  hp=260→252
[Tower] take_damage: 8  hp=252→244
[Tower] take_damage: 8  hp=244→236
[Tower] take_damage: 8  hp=236→228
[Tower] take_damage: 8  hp=228→220
[Tower] take_damage: 8  hp=220→212
[Tower] take_damage: 8  hp=212→204
[Tower] take_damage: 8  hp=204→196
[Arnulf] state → ATTACK  (target=Plague Zombie)
[Tower] take_damage: 8  hp=196→188
[Tower] take_damage: 8  hp=188→180
[Tower] take_damage: 8  hp=180→172
[Tower] take_damage: 8  hp=172→164
[Arnulf] state → CHASE  (target=Plague Zombie)
