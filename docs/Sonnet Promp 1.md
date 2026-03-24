FOUL WARD — Implement Sell UX and Complete Phase 6 Verification Checks
=======================================================================

Role

You are a Godot 4 GDScript developer working on FOUL WARD, a medieval fantasy tower defense game. The MVP codebase is already implemented with 289 passing GdUnit4 tests. Your job is to close two specific gaps: (1) wire the existing HexGrid.sell_building() method to player-facing UI/input so buildings can actually be sold during gameplay, and (2) extend test coverage and fix any issues needed to fully verify the Phase 6 manual playtest checklist items that remain incomplete.

You must not break any existing behavior. You must not add new autoloads. You must not change existing public API signatures unless absolutely necessary (and if you do, mark it with # DEVIATION: [reason]). All code must follow CONVENTIONS.md as law.

Do not invent method signatures. If you need to add a new method, read the existing code first and derive the signature style from what is already there. Do not assume a specific signature until you have read the relevant file.

Context — Files to Load

Load all of these files before doing anything. They are your source of truth.

Architecture and Convention Documents (load in full):

    CONVENTIONS.md — all naming, signal, test, and coding conventions. Treat every rule as LAW.

    ARCHITECTURE.md — scene tree, autoload order, signal flow diagrams, class responsibilities, data flow.

    PREGENERATIONVERIFICATION.md — signal integrity table, node path verification, project config checklist. Complete this checklist mentally before writing any file.

    INDEXSHORT.md — compact index of every file, class, scene, resource, and known open issue.

When referencing any project file by name, use exactly the filename as it appears in INDEXSHORT.md. Do not invent or abbreviate filenames.

Game Code Files (open and read before coding):

Autoloads:

    res://autoloads/signalbus.gd — all cross-system signals. You will reference building_sold, building_placed, build_mode_entered, build_mode_exited.

    res://autoloads/gamemanager.gd — state machine, enter_build_mode() / exit_build_mode(), game_state enum usage.

    res://autoloads/economymanager.gd — add_gold(), add_building_material(), can_afford(), resource tracking.

Core systems you will modify or inspect:

    res://scripts/inputmanager.gd — translates mouse/keyboard input to public method calls. Currently handles hex slot click detection via raycast in BUILDMODE, routes to BuildMenu for placement. You will extend this to handle clicks on occupied slots.

    res://scenes/hexgrid/hexgrid.gd — owns 24 slots, place_building(), sell_building(), upgrade_building(), get_slot_data(). The sell_building() method is fully implemented and tested but NOT wired to any UI or input path.

    res://scenes/hexgrid/hexgrid.tscn — 24 HexSlot Area3D children on layer 7.

    res://ui/buildmenu.gd — radial menu overlay shown in BUILDMODE. Currently only handles building placement selection. You will add a sell option when the menu is opened for an occupied slot.

    res://ui/buildmenu.tscn — the scene for the radial build menu.

    res://ui/uimanager.gd — lightweight signal to panel router. Shows and hides panels on game_state_changed.

    res://ui/betweenmissionscreen.gd — post-mission hub with Shop, Research, and Buildings tabs.

    res://ui/betweenmissionscreen.tscn

Systems for Phase 6 verification:

    res://scripts/spellmanager.gd — mana pool, cooldowns, cast_spell("shockwave"), mana regen in _physics_process.

    res://scenes/arnulf/arnulf.gd — AI melee companion state machine (IDLE/PATROL/CHASE/ATTACK/DOWNED/RECOVERING).

    res://scenes/tower/tower.gd — Tower HP, fire_crossbow(), fire_rapid_missile(), repair_to_full(), take_damage().

    res://scenes/enemies/enemybase.gd — enemy nav, attack, death, gold reward.

    res://scenes/buildings/buildingbase.gd — auto-targeting, firing, upgrade.

Existing test files to extend:

    res://tests/testhexgrid.gd

    res://tests/testbuildingbase.gd

    res://tests/testshopmanager.gd

    res://tests/testgamemanager.gd

    res://tests/testsimulationapi.gd

    res://tests/testspellmanager.gd

    res://tests/testarnulfstatemachine.gd

    res://tests/testenemypathfinding.gd

Phase 1 — Research (Do This Before Writing Any Code)

Before writing a single line of code, complete the following research steps using the loaded files as your primary source. Do NOT guess about existing behavior — read the actual code.

1.1 Understand the Current Build Mode Flow

Read inputmanager.gd, gamemanager.gd, hexgrid.gd, and buildmenu.gd to answer these questions. Write a short summary of your findings before proceeding:

    How does the player enter build mode? Trace the path from the toggle_build_mode input action through InputManager to GameManager.enter_build_mode() to SignalBus.build_mode_entered to HexGrid._on_build_mode_entered() (slots become visible) and Engine.time_scale = 0.1.

    How does the player click a hex slot? Trace the raycast in InputManager: mouse click, raycast on layer 7, identifies which HexSlot_XX Area3D was hit, gets slot index. Does InputManager check if the slot is occupied or empty? Does it always open BuildMenu?

    How does BuildMenu currently work? Does it receive the slot index? Does it know whether the slot is occupied? Does it have any sell-related code or buttons already? What method does it call when the player picks a building to place?

    How does HexGrid.sell_building() work according to the tests? Read testhexgrid.gd to confirm: full refund of base costs, full refund of upgrade costs if upgraded, slot becomes unoccupied, SignalBus.building_sold emitted with (slot_index, building_type).

    Is there any sell-related code in betweenmissionscreen.gd? Check the Buildings tab — does it display placed buildings? Can it call sell from there?

1.2 Understand the Phase 6 Gaps

From INDEXSHORT.md known open issues and the test files, identify:

    Shockwave verification: Read testspellmanager.gd. Are there tests that verify shockwave actually damages enemies in a simulated mission context (not just unit-level mana deduction)? Is there an integration test where SpellManager.cast_spell("shockwave") is called while enemies are in the "enemies" group and their HP decreases?

    Arnulf verification: Read testarnulfstatemachine.gd. Are there tests that verify Arnulf transitions through IDLE to CHASE to ATTACK to (target dies) to IDLE in a scenario with actual EnemyBase instances? Is DOWNED to RECOVERING to IDLE tested with real timer progression?

    Between-mission loop: Read testgamemanager.gd and testsimulationapi.gd. Is there a test that goes: COMBAT, all waves cleared, MISSION_WON, BETWEEN_MISSIONS, shop purchase, start_next_mission, MISSION_BRIEFING, COMBAT? Does it verify that buildings persist, resources carry over, and tower HP resets?

    Full mission win/lose paths: Is there a test that verifies tower destroyed leads to MISSION_FAILED with correct game state? And all waves cleared leads to MISSION_WON with correct state transitions?

Write a brief gap analysis before coding. For each gap, note whether it needs: (a) a new GdUnit test, (b) an extension to an existing test, (c) a small code fix, or (d) manual-only verification.

1.3 Search for Patterns (Only If Needed)

If the existing code does not make the implementation path obvious, search for:

    Godot 4 patterns for context-sensitive menus showing different options based on slot state.

    Godot 4 GdUnit4 patterns for testing signal emissions and multi-step game state transitions.

Primary source of truth is always the repo itself. External research is supplementary.

Phase 2 — Implementation

TASK A: Wire Sell UX to Player Input

A.1 Design Summary

The sell UX works as follows. All of this happens during BUILDMODE only:

    Player clicks an OCCUPIED hex slot (a slot where get_slot_data(slot_index).is_occupied == true).

    BuildMenu opens in sell mode for that slot. Instead of showing 8 building placement options, it shows:

        The name of the building currently in that slot (from BuildingData.display_name).

        Whether it is upgraded.

        A SELL button showing the refund amount (gold and material, including upgrade costs if upgraded).

        A CANCEL button that closes the menu.

        Optionally, an UPGRADE button if the building is not yet upgraded and the player can afford it. This is a nice-to-have for MVP — implement it if it is straightforward, skip if it adds significant complexity. Mark with # POST-MVP if skipped.

    Player clicks SELL — HexGrid.sell_building(slot_index) is called, menu closes, slot becomes empty and visible (still in build mode).

    Player clicks CANCEL or presses Escape — menu closes, no action taken.

A.2 Files to Modify

res://scripts/inputmanager.gd:

    In the BUILDMODE click handler, after identifying the clicked slot via raycast:

        Call HexGrid.get_slot_data(slot_index) to check is_occupied.

        If empty: open BuildMenu in placement mode (existing behavior, unchanged).

        If occupied: open BuildMenu in sell mode, passing the slot index and the slot data dictionary.

    Do NOT add game logic here. InputManager only translates input to method calls.

res://ui/buildmenu.gd and res://ui/buildmenu.tscn:

    Read the existing buildmenu.gd first to understand its current structure before deciding how to extend it.

    Add a new public method for opening the menu in sell mode for an occupied slot. Derive the method name and signature style from the existing open method already in buildmenu.gd.

    The method shows the sell and upgrade UI instead of the radial placement UI.

    It stores the slot_index internally so the Sell button knows which slot to sell.

    Add a Sell button (Button node) to the scene. Hidden by default, shown only in sell mode.

    Sell button pressed signal connects to a handler that calls HexGrid.sell_building(_current_slot_index) and then closes the menu.

    Add a Cancel button or reuse the existing close/cancel mechanism.

    The existing placement mode open method must remain unchanged.

    IMPORTANT: BuildMenu must NOT contain game logic. It calls HexGrid.sell_building() and that is it. HexGrid handles refunds, signals, and slot state.

res://scenes/hexgrid/hexgrid.gd:

    No changes to sell_building() itself — it already works.

    Only add a new convenience method if BuildMenu genuinely needs something that get_slot_data() does not already provide. Read get_slot_data() first before deciding.

res://ui/betweenmissionscreen.gd (OPTIONAL — only in MVP if trivial):

    The Buildings tab currently displays placed buildings read-only.

    Adding a sell button here would be nice but is NOT required for MVP.

    If you implement it, it should call the same HexGrid.sell_building(slot_index) path.

    If you skip it, add a comment: # POST-MVP: Add sell button to Buildings tab in betweenmissionscreen.

A.3 Tests to Add or Extend

Read testhexgrid.gd first. Most sell tests may already exist. Only add what is genuinely missing.

Add these tests to testhexgrid.gd (or a new file testselux.gd if it makes the test organization cleaner — your call):

test_sell_building_via_sell_flow_empties_slot
Arrange: Place a building on slot 0.
Act: Call HexGrid.sell_building(0).
Assert: Slot 0 is unoccupied. EconomyManager gold and material match expected refund.

test_sell_upgraded_building_refunds_base_and_upgrade_costs
Arrange: Place building, upgrade it.
Act: Call HexGrid.sell_building(slot_index).
Assert: Gold refunded equals gold_cost plus upgrade_gold_cost. Material refunded equals material_cost plus upgrade_material_cost.

test_sell_building_emits_building_sold_signal
Arrange: Place a building. Monitor SignalBus.
Act: Call HexGrid.sell_building(slot_index).
Assert: SignalBus.building_sold emitted with correct (slot_index, building_type).

test_sell_on_empty_slot_returns_false
Arrange: Ensure slot 5 is empty.
Act: Call HexGrid.sell_building(5).
Assert: Returns false. No signals emitted. No resource changes.

NOTE: The key NEW behavioral tests are about the InputManager/BuildMenu routing. If you can write a test that simulates the input to BuildMenu to sell flow without requiring a full scene tree, do so. If it requires too much scene scaffolding, document it as manual-only and add a comment in the test file:
MANUAL TEST: In BUILDMODE, click an occupied slot. Verify BuildMenu shows
sell option with correct building name and refund amount. Click Sell. Verify
slot is now empty and resources are refunded.

A.4 Behavioral Edge Cases to Handle

    Double-sell prevention: After sell_building() succeeds, the slot is empty. If the player clicks the same slot again, it should now open in placement mode (empty slot). Ensure no race condition.

    Sell during wave countdown vs active wave: Both are valid BUILDMODE sub-states. Selling should work in both. Verify Engine.time_scale = 0.1 does not interfere with the sell transaction (it should not — sell is a single-frame operation, not time-dependent).

    Sell the only building: Should work fine. No special case needed.

    BuildMenu already open: If BuildMenu is open for placement and the player clicks a different occupied slot, the menu should close and reopen in sell mode for the new slot. Handle this gracefully.

TASK B: Complete Phase 6 Verification Checks

B.1 — Sybil Shockwave Full Verification (Phase 6 Row 6)

What needs verification: Shockwave spell cast during combat actually damages all ground enemies, deducts mana, starts cooldown, and the HUD updates correctly.

Action — Add integration test to testspellmanager.gd:

test_shockwave_damages_all_ground_enemies_in_group
Arrange:
Reset SpellManager (mana = 100 or set to full).
Create 3 EnemyBase instances with HealthComponents, add to group "enemies".
Set their armor_type to UNARMORED.
Ensure SpellData for shockwave is loaded (damage = 30.0, damage_type = MAGICAL).
Act:
Call SpellManager.cast_spell("shockwave").
Assert:
Each enemy HealthComponent.current_hp decreased by DamageCalculator.calculate_damage(30.0, MAGICAL, UNARMORED).
SpellManager.get_current_mana() equals max_mana minus 50 (shockwave mana_cost).
SignalBus.spell_cast emitted with "shockwave".
SignalBus.mana_changed emitted.
Teardown:
Remove enemies from group, queue_free.

test_shockwave_does_not_hit_flying_enemies
Arrange:
Same as above but set one enemy's is_flying = true via EnemyData.
Shockwave hits_flying = false.
Act:
Cast shockwave.
Assert:
Flying enemy HP unchanged.
Ground enemies damaged.

Code inspection: Read spellmanager.gd shockwave implementation. Verify it iterates get_tree().get_nodes_in_group("enemies") and checks hits_flying against each enemy is_flying. If the flying check is missing, add it. Mark with # DEVIATION: Added flying check to shockwave — spec says hits_flying=false but code was missing the filter.

B.2 — Arnulf Full Verification (Phase 6 Row 7)

What needs verification: Arnulf full state machine cycle under real conditions: detects enemy, chases, attacks, enemy dies, returns to idle. Also: takes enough damage to go DOWNED, waits 3 seconds, RECOVERING (heals to 50%), IDLE.

Action — Add or extend tests in testarnulfstatemachine.gd:

test_arnulf_chase_attack_kill_return_to_idle
Arrange:
Create Arnulf instance with NavigationAgent3D (may need minimal scene tree).
Create one EnemyBase instance at a position within Arnulf detection range but outside attack range.
Add enemy to group "enemies".
Act:
Simulate enough _physics_process frames for Arnulf to detect, chase, reach, and kill the enemy.
Assert:
Arnulf transitions: IDLE to CHASE to ATTACK.
Enemy health reaches 0 or enemy is freed.
Arnulf transitions back to IDLE.

test_arnulf_downed_recovery_cycle_restores_half_hp
Arrange:
Create Arnulf. Note max_hp from healthcomponent.
Act:
Call arnulf.healthcomponent.take_damage(max_hp) to deplete HP.
Wait 3.0 seconds (recovery_time).
Assert:
Arnulf state transitions: current to DOWNED to RECOVERING to IDLE.
After recovery: arnulf.healthcomponent.current_hp equals 50% of max_hp.
SignalBus.arnulf_incapacitated and arnulf_recovered both emitted.

Note: If full scene instantiation is too complex for unit tests, document as manual-only:
MANUAL TEST: Start a mission. Observe Arnulf moving to engage enemies.
Verify he attacks, kills, and returns to idle. Damage him to 0 HP via
debug command or overwhelming enemies. Verify he goes DOWNED for ~3s,
then recovers to 50% HP and resumes fighting.

B.3 — Between-Mission Full Loop (Phase 6 Row 10)

What needs verification: Complete flow: COMBAT, all waves cleared, MISSION_WON, BETWEEN_MISSIONS, player uses shop/research, start_next_mission, MISSION_BRIEFING, COMBAT. Buildings persist. Resources carry over. Tower HP resets.

Action — Add integration test to testgamemanager.gd or testsimulationapi.gd:

test_full_mission_to_between_mission_loop
Arrange:
GameManager.start_new_game() — state = MISSION_BRIEFING (mission 1).
Start wave countdown, force-spawn wave 1 (or set WAVES_PER_MISSION = 1 for test).
Place a building on slot 0 via HexGrid.
Record gold and building_material amounts.
Act:
Kill all enemies (force via healthcomponent.take_damage on each).
WaveManager detects 0 enemies, emits wave_cleared, all_waves_cleared.
GameManager transitions to MISSION_WON then BETWEEN_MISSIONS.
Call ShopManager.purchase_item("tower_repair") if affordable.
Call GameManager.start_next_mission().
Assert:
GameManager.current_mission == 2.
GameManager.game_state == MISSION_BRIEFING.
HexGrid.get_slot_data(0).is_occupied == true (building persisted).
Tower HP == max (reset).
EconomyManager.gold equals previous gold minus shop cost plus any post-mission bonus.

test_mission_failed_on_tower_destroyed
Arrange:
Start mission, spawn enemies.
Act:
Call Tower.take_damage(tower_max_hp) to destroy tower.
Assert:
SignalBus.tower_destroyed emitted.
GameManager.game_state == MISSION_FAILED.

Code inspection: Read gamemanager.gd to verify:

    _on_all_waves_cleared() awards post-mission resources and transitions to BETWEEN_MISSIONS.

    start_next_mission() increments current_mission, resets tower HP, resets wave counter, transitions to MISSION_BRIEFING.

    Buildings and resources are NOT reset between missions (only on start_new_game()).

If any of these behaviors are missing or buggy, fix them. Mark fixes with # DEVIATION if they change documented behavior.

B.4 — No Script Errors in Full Mission Run

Action: This is primarily a manual verification item, but strengthen it by extending testsimulationapi.gd:

test_simbot_can_drive_full_mission_loop_without_errors
Arrange:
GameManager.start_new_game().
Act:
Force-spawn wave 1 via WaveManager.
Kill all enemies.
Repeat for waves 2 and 3 (WAVES_PER_MISSION = 3).
After all_waves_cleared: call start_next_mission().
Assert:
No assertions failed.
GameManager.current_mission == 2.
No null pointer exceptions or orphaned nodes.

Files to Modify or Add

Likely modified:

    res://scripts/inputmanager.gd — add occupied-slot detection branch in BUILDMODE click handler.

    res://ui/buildmenu.gd — add open method for occupied slots, sell button handler, cancel handler.

    res://ui/buildmenu.tscn — add Sell button, Cancel button, info labels for sell mode.

    res://scripts/spellmanager.gd — possibly add is_flying filter to shockwave if missing.

Likely extended (existing test files):

    res://tests/testhexgrid.gd — verify sell tests exist; add any missing edge cases.

    res://tests/testspellmanager.gd — add shockwave integration tests (damages enemies, flying filter).

    res://tests/testarnulfstatemachine.gd — add full chase to attack to idle and downed to recovery tests.

    res://tests/testgamemanager.gd — add full mission loop test, mission failed test.

    res://tests/testsimulationapi.gd — add full loop simulation test.

New files (only if needed):

    res://tests/testsellux.gd — only if sell UX tests do not fit naturally in testhexgrid.gd.

Optional or only if needed:

    res://ui/betweenmissionscreen.gd — add sell from Buildings tab (POST-MVP, skip if non-trivial).

    res://autoloads/autotestdriver.gd — extend headless smoke test if straightforward.

    res://scenes/hexgrid/hexgrid.gd — only if a new convenience method is genuinely needed for BuildMenu.

## Final Verification Checklist (to be done by Cursor, please create instructions to do it to CURSOR_INSTRUCTIONS_1.md file)

Before declaring your work complete, verify all of the following:

    All existing 289 GdUnit4 tests still pass. Run the full suite. Zero failures.

    Sell UX behavioral verification:

        In BUILDMODE, clicking an empty slot opens BuildMenu in placement mode (unchanged).

        In BUILDMODE, clicking an occupied slot opens BuildMenu in sell mode showing building name and refund.

        Clicking Sell calls HexGrid.sell_building(), slot becomes empty, resources refunded.

        Clicking Cancel or pressing Escape closes the menu with no side effects.

        Selling an upgraded building refunds base plus upgrade costs.

        SignalBus.building_sold emitted with correct payload.

        Double-clicking a just-sold slot opens placement mode (slot is now empty).

    Phase 6 checks now covered:

        Shockwave damages ground enemies, skips flying, deducts mana, starts cooldown — tested.

        Arnulf state machine transitions tested with real enemy interaction, or documented as manual-only with clear instructions.

        Between-mission loop tested: combat to win to between missions to next mission. Buildings persist, tower resets.

        Mission failure on tower destruction tested.

        Full simulation loop runs without errors for at least 1 mission.

    Code quality:

        All new code follows CONVENTIONS.md (naming, types, signals, comments).

        All # ASSUMPTION comments present where your code depends on another module's behavior.

        All # DEVIATION comments present where you changed anything from the spec.

        All # POST-MVP comments present for anything you deliberately skipped.

        No magic numbers — all values come from resources or named constants.

        No game logic in UI scripts or InputManager.

    INDEXSHORT.md updated if you added any new files, public methods, or signals. If you only modified existing files without adding new public API surface, no update needed.
