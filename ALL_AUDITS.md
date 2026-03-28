AUDIT 1
no findings

AUDIT 2
Here is a single, copy‑pasteable checklist covering all naming fixes from this audit.
1. Fix constant naming in campaign_manager.gd

In res://autoloads/campaign_manager.gd:

    Find the constant declaration:

        const _MercenaryOfferDataGd: GDScript = preload("res://scripts/resources/mercenary_offer_data.gd") (exact type annotation may vary).

    Change it to UPPER_SNAKE_CASE while keeping the leading underscore (private):

        const _MERCENARY_OFFER_DATA_GD: GDScript = preload("res://scripts/resources/mercenary_offer_data.gd")

Then, in the same file, replace every usage:

    _MercenaryOfferDataGd → _MERCENARY_OFFER_DATA_GD.

No other constants in the scanned autoloads appear to violate the 4a constant rule.
2. Rename SignalBus signals to snake_case

Work in two steps for each name:

    Change the signal declaration in res://autoloads/signal_bus.gd.

    Globally update all usages (emit, .connect, .disconnect, tests, etc.) to match the new name.

2.1. Edit autoloads/signal_bus.gd declarations

In res://autoloads/signal_bus.gd, rename each signal line as follows.

Combat / tower / projectiles

    signal enemykilled(enemytype: Types.EnemyType, position: Vector3, goldreward: int)
    → signal enemy_killed(enemy_type: Types.EnemyType, position: Vector3, gold_reward: int) (you may also optionally normalize argument names to snake_case, but the key is the signal name).

    signal enemyreachedtower(enemytype: Types.EnemyType, damage: int)
    → signal enemy_reached_tower(enemy_type: Types.EnemyType, damage: int)

    signal towerdamaged(currenthp: int, maxhp: int)
    → signal tower_damaged(current_hp: int, max_hp: int)

    signal towerdestroyed
    → signal tower_destroyed

    signal projectilefired(weaponslot: Types.WeaponSlot, origin: Vector3, target: Vector3)
    → signal projectile_fired(weapon_slot: Types.WeaponSlot, origin: Vector3, target: Vector3)

Arnulf / allies

    signal arnulfstatechanged(newstate: Types.ArnulfState)
    → signal arnulf_state_changed(new_state: Types.ArnulfState)

    signal arnulfincapacitated
    → signal arnulf_incapacitated

    signal arnulfrecovered
    → signal arnulf_recovered

    signal allyspawned(allyid: String)
    → signal ally_spawned(ally_id: String)

    signal allydowned(allyid: String)
    → signal ally_downed(ally_id: String)

    signal allyrecovered(allyid: String)
    → signal ally_recovered(ally_id: String)

    signal allykilled(allyid: String)
    → signal ally_killed(ally_id: String)

    signal allystatechanged(allyid: String, newstate: String)
    → signal ally_state_changed(ally_id: String, new_state: String)

Bosses / campaign boss

    signal bossspawned(bossid: String)
    → signal boss_spawned(boss_id: String)

    signal bosskilled(bossid: String)
    → signal boss_killed(boss_id: String)

    signal campaignbossattempted(dayindex: int, success: bool)
    → signal campaign_boss_attempted(day_index: int, success: bool)

Wave lifecycle

    signal wavecountdownstarted(wavenumber: int, secondsremaining: float)
    → signal wave_countdown_started(wave_number: int, seconds_remaining: float)

    signal wavestarted(wavenumber: int, enemycount: int)
    → signal wave_started(wave_number: int, enemy_count: int)

    signal wavecleared(wavenumber: int)
    → signal wave_cleared(wave_number: int)

    signal allwavescleared
    → signal all_waves_cleared

Economy / resources / mana

    signal resourcechanged(resourcetype: Types.ResourceType, newamount: int)
    → signal resource_changed(resource_type: Types.ResourceType, new_amount: int)

    signal manachanged(currentmana: int, maxmana: int)
    → signal mana_changed(current_mana: int, max_mana: int)

Territories / world map

    signal territorystatechanged(territoryid: String)
    → signal territory_state_changed(territory_id: String)

    signal worldmapupdated
    → signal world_map_updated

Buildings / build mode

    signal buildingplaced(slotindex: int, buildingtype: Types.BuildingType)
    → signal building_placed(slot_index: int, building_type: Types.BuildingType)

    signal buildingsold(slotindex: int, buildingtype: Types.BuildingType)
    → signal building_sold(slot_index: int, building_type: Types.BuildingType)

    signal buildingupgraded(slotindex: int, buildingtype: Types.BuildingType)
    → signal building_upgraded(slot_index: int, building_type: Types.BuildingType)

    signal buildingdestroyed(slotindex: int)
    → signal building_destroyed(slot_index: int)

    signal buildmodeentered
    → signal build_mode_entered

    signal buildmodeexited
    → signal build_mode_exited

Spells / mana / spell readiness

    signal spellcast(spellid: String)
    → signal spell_cast(spell_id: String)

    signal spellready(spellid: String)
    → signal spell_ready(spell_id: String)

Game state / mission lifecycle

    signal gamestatechanged(oldstate: Types.GameState, newstate: Types.GameState)
    → signal game_state_changed(old_state: Types.GameState, new_state: Types.GameState)

    signal missionstarted(missionnumber: int)
    → signal mission_started(mission_number: int)

    signal missionwon(missionnumber: int)
    → signal mission_won(mission_number: int)

    signal missionfailed(missionnumber: int)
    → signal mission_failed(mission_number: int)

Florence / campaign days

    signal florencestatechanged
    → signal florence_state_changed

    signal campaignstarted(campaignid: String)
    → signal campaign_started(campaign_id: String)

    signal daystarted(dayindex: int)
    → signal day_started(day_index: int)

    signal daywon(dayindex: int)
    → signal day_won(day_index: int)

    signal dayfailed(dayindex: int)
    → signal day_failed(day_index: int)

    signal campaigncompleted(campaignid: String)
    → signal campaign_completed(campaign_id: String)

Research / shop

    signal researchunlocked(nodeid: String)
    → signal research_unlocked(node_id: String)

    signal shopitempurchased(itemid: String)
    → signal shop_item_purchased(item_id: String)

    signal manadraughtconsumed
    → signal mana_draught_consumed

Weapons / enchantments

    signal weaponupgraded(weaponslot: Types.WeaponSlot, newlevel: int)
    → signal weapon_upgraded(weapon_slot: Types.WeaponSlot, new_level: int)

    signal enchantmentapplied(weaponslot: Types.WeaponSlot, slottype: String, enchantmentid: String)
    → signal enchantment_applied(weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String)

    signal enchantmentremoved(weaponslot: Types.WeaponSlot, slottype: String)
    → signal enchantment_removed(weapon_slot: Types.WeaponSlot, slot_type: String)

Mercenaries / ally roster

    signal mercenaryoffergenerated(allyid: String)
    → signal mercenary_offer_generated(ally_id: String)

    signal mercenaryrecruited(allyid: String)
    → signal mercenary_recruited(ally_id: String)

    signal allyrosterchanged
    → signal ally_roster_changed

(Argument name tweaks are optional; they keep everything consistent with snake_case but are not strictly required for the naming audit.)
2.2. Global search/replace usages

For each old signal name, run a project‑wide textual replacement:

    SignalBus.enemykilled → SignalBus.enemy_killed

    SignalBus.enemyreachedtower → SignalBus.enemy_reached_tower

    SignalBus.towerdamaged → SignalBus.tower_damaged

    SignalBus.towerdestroyed → SignalBus.tower_destroyed

    SignalBus.projectilefired → SignalBus.projectile_fired

    SignalBus.arnulfstatechanged → SignalBus.arnulf_state_changed

    SignalBus.arnulfincapacitated → SignalBus.arnulf_incapacitated

    SignalBus.arnulfrecovered → SignalBus.arnulf_recovered

    SignalBus.allyspawned → SignalBus.ally_spawned

    SignalBus.allydowned → SignalBus.ally_downed

    SignalBus.allyrecovered → SignalBus.ally_recovered

    SignalBus.allykilled → SignalBus.ally_killed

    SignalBus.allystatechanged → SignalBus.ally_state_changed

    SignalBus.bossspawned → SignalBus.boss_spawned

    SignalBus.bosskilled → SignalBus.boss_killed

    SignalBus.campaignbossattempted → SignalBus.campaign_boss_attempted

    SignalBus.wavecountdownstarted → SignalBus.wave_countdown_started

    SignalBus.wavestarted → SignalBus.wave_started

    SignalBus.wavecleared → SignalBus.wave_cleared

    SignalBus.allwavescleared → SignalBus.all_waves_cleared

    SignalBus.resourcechanged → SignalBus.resource_changed

    SignalBus.manachanged → SignalBus.mana_changed

    SignalBus.territorystatechanged → SignalBus.territory_state_changed

    SignalBus.worldmapupdated → SignalBus.world_map_updated

    SignalBus.buildingplaced → SignalBus.building_placed

    SignalBus.buildingsold → SignalBus.building_sold

    SignalBus.buildingupgraded → SignalBus.building_upgraded

    SignalBus.buildingdestroyed → SignalBus.building_destroyed

    SignalBus.buildmodeentered → SignalBus.build_mode_entered

    SignalBus.buildmodeexited → SignalBus.build_mode_exited

    SignalBus.spellcast → SignalBus.spell_cast

    SignalBus.spellready → SignalBus.spell_ready

    SignalBus.gamestatechanged → SignalBus.game_state_changed

    SignalBus.missionstarted → SignalBus.mission_started

    SignalBus.missionwon → SignalBus.mission_won

    SignalBus.missionfailed → SignalBus.mission_failed

    SignalBus.florencestatechanged → SignalBus.florence_state_changed

    SignalBus.campaignstarted → SignalBus.campaign_started

    SignalBus.daystarted → SignalBus.day_started

    SignalBus.daywon → SignalBus.day_won

    SignalBus.dayfailed → SignalBus.day_failed

    SignalBus.campaigncompleted → SignalBus.campaign_completed

    SignalBus.researchunlocked → SignalBus.research_unlocked

    SignalBus.shopitempurchased → SignalBus.shop_item_purchased

    SignalBus.manadraughtconsumed → SignalBus.mana_draught_consumed

    SignalBus.weaponupgraded → SignalBus.weapon_upgraded

    SignalBus.enchantmentapplied → SignalBus.enchantment_applied

    SignalBus.enchantmentremoved → SignalBus.enchantment_removed

    SignalBus.mercenaryoffergenerated → SignalBus.mercenary_offer_generated

    SignalBus.mercenaryrecruited → SignalBus.mercenary_recruited

    SignalBus.allyrosterchanged → SignalBus.ally_roster_changed

This should cover emissions, connections, and any tests that refer to these signals by name.
3. Post‑change verification

After all the above:

    Rebuild the Godot project (or re‑open in the editor) so class_name and signal caches refresh.

    Run your GdUnit test suite (both quick and full, if available):

        ./tools/run_gdunit_quick.sh

        ./tools/run_gdunit.sh
        This will confirm that all signal name references and the one constant rename are consistent across autoloads, scenes, resources, and tests.

If you’d like, next prompt I can help you generate a quick Godot‑side grep command list (e.g. rg "enemykilled") you can paste into a shell to double‑check there are no lingering old names.

AUDIT 3
Here’s a complete, copy‑pasteable implementation checklist for all node‑path issues and contract gaps uncovered in Audit 3.
1. Fix autoload access via scene path (High)
1.1 GameManager: stop using /root/ShopManager for autoload

File: res://autoloads/game_manager.gd
Function: _ready()

    Find the _ready() function and locate this block:

text
func _ready() -> void:
    print("GameManager ready initial state:", Types.GameState.keys()[game_state])
    SignalBus.all_waves_cleared.connect(_on_all_waves_cleared)
    SignalBus.tower_destroyed.connect(_on_tower_destroyed)

    # Autoload order: CampaignManager before GameManager; connect second so day increments first on mission_won.
    _connect_mission_won_transition_to_hub()

    var shop: Node = get_node_or_null("/root/ShopManager")
    var tower: Node = get_node_or_null("/root/Main/Tower")
    if shop != null and tower != null and shop.has_method("initialize_tower"):
        shop.initialize_tower(tower)
        print("GameManager: ready, ShopManager wired to Tower")

    _reload_territory_map_from_active_campaign()
    SignalBus.boss_killed.connect(_on_boss_killed)
    _sync_held_territories_from_map()

    Replace only the shop line with autoload access:

text
    var shop: Node = ShopManager

    Final _ready() should look like:

text
func _ready() -> void:
    print("GameManager ready initial state:", Types.GameState.keys()[game_state])
    SignalBus.all_waves_cleared.connect(_on_all_waves_cleared)
    SignalBus.tower_destroyed.connect(_on_tower_destroyed)

    _connect_mission_won_transition_to_hub()

    var shop: Node = ShopManager
    var tower: Node = get_node_or_null("/root/Main/Tower")
    if shop != null and tower != null and shop.has_method("initialize_tower"):
        shop.initialize_tower(tower)
        print("GameManager: ready, ShopManager wired to Tower")

    _reload_territory_map_from_active_campaign()
    SignalBus.boss_killed.connect(_on_boss_killed)
    _sync_held_territories_from_map()

    Ensure ShopManager is actually registered as an autoload in project.godot (it should already be; if not, add it there, but that’s outside node‑path scope).

2. Lock in manager node‑path contracts (Medium)

These are documentation/contract tasks; no code changes required, but they prevent future breakage.
2.1 Update AUDIT_CONTEXT_SUMMARY Section 4c table

File: AUDIT_CONTEXT_SUMMARY.md
Section: ### 4c — Scene Tree and Node Path Contracts

    Locate the existing hard‑coded node path contracts table. It currently includes entries like:

text
| Path String | Used By | What Breaks If Wrong |
|-------------|---------|---------------------|
| `/root/Main` | GameManager (`_begin_mission_wave_sequence`) | Wave sequence silently skipped (push_warning) |
| `/root/Main/Managers/WaveManager` | GameManager | Wave sequence silently skipped |
| `/root/Main/Managers/WeaponUpgradeManager` | Tower | Falls back to raw WeaponData stats |
| `/root/Main/Managers/ResearchManager` | DialogueManager | Research conditions evaluate false |
| `/root/Main/EnemyContainer` | WaveManager | Enemies not spawned |
| `/root/Main/SpawnPoints` | WaveManager | Enemies not spawned |
| `/root/Main/AllyContainer` | GameManager | Allies not spawned |
| `/root/Main/AllySpawnPoints` | GameManager | Ally positions wrong |
| `/root/Main/ProjectileContainer` | Tower, BuildingBase | Projectiles orphaned |

    Append these rows at the end of that table:

text
| `/root/Main/Managers/ShopManager` | GameManager (`start_new_game()`, `start_mission_for_day()`) | Mission-start consumables not applied; shop-driven mission modifiers silently disabled. |
| `/root/Main/Managers/SpellManager` | InputManager (spell hotkeys / casting) | Spells cannot be cast or configured; hotkeys may appear to do nothing. |

This documents two paths that scripts already rely on: /root/Main/Managers/ShopManager and /root/Main/Managers/SpellManager.
3. Update ARCHITECTURE.md to reflect manager contracts (Medium)

File: ARCHITECTURE.md
Location: Right after the description of the Main/Managers subtree in the main scene tree section.

    Insert this subsection (or merge it with existing wording):

text
#### Manager node path contracts (FOUL WARD)

Several managers are resolved by absolute node path under `Main/Managers`:

- `WaveManager` is expected at `/root/Main/Managers/WaveManager` (wave spawning, countdown, boss registry).
- `ResearchManager` is expected at `/root/Main/Managers/ResearchManager` (DialogueManager research conditions; day-start resets).
- `WeaponUpgradeManager` is expected at `/root/Main/Managers/WeaponUpgradeManager` (Tower stat lookup and upgrade resets).
- `ShopManager` is expected at `/root/Main/Managers/ShopManager` (mission-start consumables, shop-driven mission modifiers).
- `SpellManager` is expected at `/root/Main/Managers/SpellManager` (spell hotkeys and casting from InputManager).

These paths are authoritative: any change to the `Main/Managers` subtree must keep these exact node names and relative positions, or the dependent systems will silently degrade.

This aligns architecture docs with the contracts now recorded in Section 4c.
4. Verify manager placement in main.tscn (sanity, no code change)

File: res://scenes/main.tscn

    Confirm that under Main/Managers you have:

    WaveManager (script wave_manager.gd)

    SpellManager (script spell_manager.gd)

    ResearchManager (script research_manager.gd)

    ShopManager (script shop_manager.gd)

    WeaponUpgradeManager (script weapon_upgrade_manager.gd)

    InputManager (script input_manager.gd)

REPO_DUMP_SCENES.md already shows this structure, but double‑checking in the editor ensures no rename or reparent happened since the dump.

No edits are needed if the tree matches; this is just to ensure the newly formalized contracts are actually satisfied.
5. Confirm no additional fragile or autoload‑via‑path usages

After the above, do a quick grep pass in your repo (in editor or CLI) for:

    "/root/ShopManager" (should no longer exist after step 1)

    any other "/root/" usages that refer to autoloads rather than nodes under Main

    patterns like ../ in paths or long chains such as "/root/Main/UI/.../Sub/.../Deep" (there were none in the dump; this is just a safety net)

You should not need to change anything else if the code still matches the audited dump.

If you paste this whole checklist into your cursor prompt and apply it step‑by‑step, you’ll implement all fixes and documentation updates required by the node‑path integrity audit.

AUDIT 4
Here is a concrete, copy‑pasteable checklist of everything to implement, grouped by area, with no code, just precise actions and behavioral requirements.
1. Align SimBot public API with contract

1.1. Ensure required methods exist on SimBot (in res://scripts/simbot.gd) with these signatures and semantics:

    func activate(strategy: Types.StrategyProfile) -> void

        Accepts a Types.StrategyProfile enum value.

        Loads and stores the corresponding StrategyProfile resource.

        Resets any per-run internal state needed for deterministic behavior and logging.

    func deactivate() -> void

        Marks SimBot as inactive so it stops issuing gameplay commands.

        Does not clear historical logs; only affects future decisions.

    func run_single(profile_id: String, run_index: int, seed_value: int) -> Dictionary

        Resets game state to a clean mission (equivalent to starting a fresh mission in other tests).

        Activates the specified StrategyProfile based on profile_id.

        Seeds the RNG with seed_value in a way that guarantees determinism across runs.

        Drives a full mission/day to a terminal condition (win, loss, timeout, error).

        Returns a Dictionary that follows the “run_single result schema” defined in Section 3 below.

    func run_batch(profile_id: String, runs: int, base_seed: int = 0, csv_path: String = "") -> void

        For each run_index in 0 .. runs - 1:

            Derive an effective seed from base_seed and run_index.

            Call run_single(profile_id, run_index, effective_seed).

            Collect each run’s Dictionary result for later logging.

        After all runs, write a CSV file (see “CSV row schema” in Section 4).

        Update internal log state so get_log() returns this batch.

    func decide_mercenaries() -> void

        Reads available offers and budgets from CampaignManager and EconomyManager.

        Scores offers based on the active StrategyProfile and roster composition.

        Attempts to purchase a limited number of offers, respecting resource constraints.

        Relies only on autoloads and resources (no UI).

    func get_log() -> Dictionary

        Returns a structured summary of the last batch (or last single treated as a batch of one).

        Follows the schema in Section 5 below.

1.2. Confirm that any extra convenience methods that already exist (bot_enter_build_mode, bot_place_building, bot_cast_spell, bot_fire_crossbow, bot_advance_wave, etc.) remain private/internal to SimBot, do not leak into the contract, and remain headless-safe.
2. Fix the get_log return‑type mismatch

2.1. Locate getlog / get_log in res://scripts/simbot.gd.

2.2. Change its return type from Array[String] (or whatever it currently is) to Dictionary.

2.3. Ensure the returned Dictionary has at least these top‑level keys (see Section 5 for details):

    entries: Array[Dictionary] — one Dictionary per run, each following the run_single result schema.

    profile_id: String — profile used for the last batch.

    runs: int — number of runs.

    base_seed: int — base seed used in the last batch.

    csv_path: String — effective CSV path used (default or overridden).

2.4. If any code or tests currently expect get_log() to return an Array[String] of lines, update them to read from get_log()["entries"], or from a field like get_log()["entries_formatted"] if you decide to keep both raw and structured views.

2.5. Guarantee that get_log() returns a sensible value immediately after run_batch completes (and optionally after a standalone run_single, treated as one‑run batch).
3. Implement and stabilize the run_single result schema

3.1. Ensure run_single constructs and returns a Dictionary with the following fixed keys and types:

    profile_id: String

    run_index: int

    seed_value: int

    result: String — one of "WIN", "LOSS", "TIMEOUT", "ERROR".

    waves_cleared: int

    final_wave: int

    enemies_killed: int

    tower_hp_start: int

    tower_hp_end: int

    gold_earned: int

    building_material_spent: int

    spell_casts: int

    duration_seconds: float

3.2. Wire these values to real game state:

    Capture tower_hp_start before the mission begins and tower_hp_end at mission end.

    Track waves_cleared and final_wave from WaveManager / GameManager.

    Track enemies_killed using existing counters or signals.

    Compute gold_earned as current gold minus baseline starting gold.

    Accumulate building_material_spent from EconomyManager operations during the run.

    Count spell_casts whenever SimBot uses spells via SpellManager.

    Measure duration_seconds either as simulated time (ticks) or wall‑clock time, but do it consistently.

3.3. Make sure determinism tests can rely on this Dictionary:

    Repeated run_single calls with the same (profile_id, run_index, seed_value) must produce identical values for all deterministic fields.

    If you introduce any non‑deterministic fields, keep them clearly separate or omit them from determinism checks.

3.4. If you already have run‑result fields with different names, either:

    Rename them to the schema above, or

    Add backward‑compatibility keys (e.g. keep both result and outcome) and plan to clean up later.

4. Implement and stabilize the CSV row schema for run_batch

4.1. Ensure run_batch writes a CSV file with a single header row and one data row per run.

4.2. Use the following column order in the header:

    profile_id

    run_index

    seed_value

    result

    waves_cleared

    final_wave

    enemies_killed

    tower_hp_start

    tower_hp_end

    gold_earned

    building_material_spent

    spell_casts

    duration_seconds

4.3. For each run, map the Dictionary returned by run_single to the columns above and write one CSV row.

4.4. Use a consistent delimiter (comma is fine) and a stable numeric format:

    Integers with no extra formatting.

    duration_seconds with a small fixed precision (e.g. 3 decimal places).

4.5. Use user:// as the base path for CSV output:

    If csv_path argument is empty, use a default like user://simbot/logs/simbot_balance_log.csv.

    If csv_path is provided, resolve it under user:// or treat it as a full path consistently.

4.6. Ensure directory creation and file writing are robust:

    Create parent directories under user:// if they do not exist.

    Either overwrite the file for each batch or append to it in a predictable way — whichever test_simbot_logging expects; keep that behavior stable.

4.7. At the end of run_batch, update internal log state so get_log() can reflect:

    The same profile_id, runs, base_seed, csv_path.

    The same per‑run metrics as written in the CSV.

5. Finalize get_log() batch‑level schema

5.1. Inside SimBot, maintain an internal structure to store the last batch’s results:

    E.g. last_batch_entries: Array[Dictionary], last_profile_id: String, last_runs: int, last_base_seed: int, last_csv_path: String.

5.2. Make get_log() return a Dictionary with at least:

    entries: Array[Dictionary] — assign from last_batch_entries.

    profile_id: String — assign from last_profile_id.

    runs: int — assign from last_runs.

    base_seed: int — assign from last_base_seed.

    csv_path: String — assign from last_csv_path.

5.3. Optionally, compute and include a summary: Dictionary:

    wins: int — count of entries with result == "WIN".

    losses: int — count of entries with result == "LOSS".

    timeouts: int — count of entries with result == "TIMEOUT".

    errors: int — count of entries with result == "ERROR".

    avg_waves_cleared: float — mean of waves_cleared.

    avg_enemies_killed: float — mean of enemies_killed.

    avg_gold_earned: float — mean of gold_earned.

5.4. Decide how get_log() behaves after a single run_single call:

    Recommended: treat a direct run_single as an implicit batch of one:

        Set entries to [single_result_dictionary].

        Set runs to 1, profile_id to the profile used, base_seed to seed_value, and csv_path to an empty string (if no CSV was written).

5.5. Update any tests that currently assert on get_log() to match this new schema:

    They should assert on log["entries"].size(), and check fields inside those per‑run Dictionaries, rather than on a raw Array[String].

6. Reinforce headless‑safety guarantees (SimBot + AutoTestDriver)

6.1. Audit res://scripts/simbot.gd and ensure:

    There is no reference to res://ui, CanvasLayer, Control, HUD, BuildMenu, BetweenMissionScreen, UIManager, Hub, or other UI scenes.

    There are no get_node()/$/find_child() calls into UI paths.

    Any node lookups are limited to:

        Autoload singletons (e.g. GameManager, CampaignManager, etc.).

        Root scene children that are already safe in other tests (e.g. /root/Main/Tower, /root/Main/HexGrid, /root/Main/Managers/WaveManager, /root/Main/EnemyContainer).

6.2. Verify that all SimBot methods behave sensibly when Main or particular managers are missing:

    Avoid direct get_node() without null guards for scene nodes.

    When accessing /root/Main/..., prefer get_node_or_null and abort the run/update with a safe ERROR result instead of crashing.

6.3. Confirm that file I/O in run_batch and logging uses only user:// or otherwise headless‑supported paths, and that no editor‑only or OS‑specific APIs are required.
7. Improve AutoTestDriver coverage of SimBot API

7.1. Keep existing AutoTestDriver behavior for normal smoke tests unchanged:

    When --autotest is present (and no --simbot_profile), run the current integration path (Tower auto‑fire, building placements, waves, etc.).

7.2. In the SimBot CLI path (when --simbot_profile is provided), extend beyond a single run_batch call:

    After creating/finding SimBot and before quitting, add coverage for other contract methods.

7.3. Ensure AutoTestDriver covers at least once:

    run_batch(profile_id, runs, base_seed) — already covered.

    run_single(profile_id, run_index, seed_value) — add a dedicated call, e.g.:

        If simbot_runs == 1, call run_single instead of run_batch.

        Or add a separate flag that triggers a run_single path.

    get_log() — after run_batch completes:

        Call get_log() and validate that:

            runs matches the CLI simbot_runs.

            entries.size() matches runs.

            Basic fields (profile_id, run_index, result, etc.) are present.

        Print a short summary of wins/losses/timeouts to stdout (optional but useful).

    decide_mercenaries() — add an optional path (e.g. when --simbot_test_mercs is provided):

        Put the game into a campaign + between‑missions state consistent with mercenary offers.

        Call decide_mercenaries() once.

        Optionally assert or log how many offers were purchased and how the roster changed.

7.4. Keep AutoTestDriver strictly headless‑safe:

    Do not introduce any UI node references in the new SimBot‑coverage paths.

    Use only autoloads and the same Main‑scene paths that are already used in the existing integration flow.

8. Keep tests and SimBot contract in sync

8.1. Review all SimBot‑related tests (test_simbot_basic_run.gd, test_simbot_profiles.gd, test_simbot_logging.gd, test_simbot_determinism.gd, test_simbot_safety.gd, test_simbot_mercenaries.gd):

    Update them to assert against:

        The Dictionary shape returned from run_single.

        The batch‑level Dictionary from get_log().

        The CSV contents as defined in Sections 3–4.

8.2. Confirm that test_simbot_safety.gd (and any similar tests) still pass:

    They should verify there are no res://ui references and that SimBot remains usable without main UI scenes present.

8.3. After changes, run:

    The SimBot test subset.

    The full GdUnit suite if feasible, to ensure that API and headless behavior changes have not broken older tests.

This checklist is intended to be exhaustive for the SimBot + headless + AutoTestDriver scope you described; you can now work through each numbered block in order and be confident you are covering all the issues identified by the audit.

AUDIT 5
Here is a single, exhaustive implementation to‑do list you can paste into your editor prompt. It is organized by area but written as concrete actions.
General

    Create any missing GdUnit4 test suite files mentioned below under res://tests/.

    Keep all new tests headless‑safe: no editor dependencies; only load scenes/resources from res://.

    Prefer short, focused test functions with clear names describing behavior and failure condition.

1. Campaign autoload order & day progression

    New suite

        Add res://tests/test_campaign_autoload_and_day_flow.gd.

    Autoload order regression test

        In this suite, load project.godot with ConfigFile.

        Read the [autoload] section and collect autoload names in order.

        Assert that CampaignManager and GameManager entries both exist.

        Assert that the index of CampaignManager is strictly less than the index of GameManager.

        On failure, return a clear test assertion message: “CampaignManager must be registered before GameManager in project.godot”.

    Start campaign initializes day state

        Instantiate CampaignManager in a test without relying on editor autoloads.

        Assign active_campaign_config to a known short CampaignConfig (e.g. campaign_short_5_days.tres).

        Call start_new_campaign().

        Assert:

            current_day == 1.

            campaign_completed == false.

            campaign_length == active_campaign_config.get_effective_length() (or appropriate accessor).

    mission_won advances day when campaign active

        Wire CampaignManager to a test SignalBus instance (or real autoload if test uses it).

        Ensure current_day is 1 and current_day_config is valid.

        Emit SignalBus.mission_won with suitable parameters to trigger day progression.

        Await one process_frame.

        Assert: current_day == 2.

        Assert new current_day_config matches the second day’s DayConfig.

    mission_won does not progress without active campaign

        Instantiate CampaignManager without calling start_new_campaign().

        Set current_day = 5 as a sentinel.

        Emit SignalBus.mission_won.

        Await one frame.

        Assert current_day is still 5 (no auto-progression).

    Campaign completion on last day

        Use a 2‑day CampaignConfig for a small deterministic test.

        Start new campaign and progress from day 1 to day 2 by simulating mission_won.

        On day 2, emit mission_won again.

        Assert:

            campaign_completed == true.

            current_day does not exceed the campaign’s effective length.

2. Boss and Day‑50 loop

    Extend or add boss/day flow suite

        Either extend res://tests/test_boss_waves.gd / test_final_boss_day.gd or add test_boss_day_flow.gd to host day‑flow tests.

    Mini-boss day secures territory

        Create or load a DayConfig in test with:

            is_mini_boss_day = true.

            A valid boss_id matching some BossData.

        Ensure corresponding TerritoryData exists and is mapped from that day in CampaignConfig.

        Initialize CampaignManager and GameManager as in game: shared SignalBus; CampaignManager drives days; GameManager handles mission.

        Set initial territory state such that the relevant territory is threatened / not secured.

        Start a campaign and begin mission on this mini-boss day.

        Simulate boss death: emit SignalBus.boss_killed (or call the game’s boss‑defeat handler), then emit SignalBus.mission_won.

        Assert:

            Territory has is_secured == true.

            Territory has has_boss_threat == false.

            Territory ID is present in held_territory_ids in GameManager (or equivalent field).

    Mini-boss defection adds ally to roster

        Configure a MiniBossData resource used in the test with a non‑empty defected_ally_id pointing to an existing AllyData.

        Start a campaign where that mini-boss day can be reached.

        Trigger the mini-boss defection path as production code expects (e.g. through CampaignManager using boss kill signal).

        Assert:

            owned_allies now contains the defected_ally_id.

            After roster refresh, current_ally_roster_ids also contains this id.

    Final boss day sets final_boss_defeated and completes campaign

        Create or load a CampaignConfig where the last day is a final boss day with boss_id for the final boss resource.

        Start new campaign and simulate mission_won events to advance to the final boss day.

        On the final boss day, emit SignalBus.boss_killed with the final boss id, then SignalBus.mission_won.

        Assert:

            GameManager.final_boss_defeated == true (or equivalent field).

            CampaignManager.campaign_completed == true.

            No additional boss days are queued after completion.

    Synthetic boss-attack days insertion and clearing

        Set up a CampaignConfig / territory setup where the game would insert boss-attack days (using is_boss_attack_day field in DayConfig).

        Use CampaignManager to step through days, calling get_day_config_for_index() at each logical index.

        Before boss defeat, assert that some indices return DayConfigs with is_boss_attack_day == true.

        Simulate defeating the appropriate boss days.

        After that, re-check those indices and assert is_boss_attack_day == false (attack slots are cleared).

    Boss wave composition (boss + escorts)

        Configure BossData with deterministic escort composition and ensure appropriate FactionData for the day.

        Call WaveManager.set_day_context(day_config) with this context.

        Start wave spawning in a test environment and collect spawned enemies.

        Assert:

            Exactly one boss enemy of expected type spawns.

            Escort enemies match expected types and counts from BossData/FactionData.

3. SimBot robustness & headless safety

    Full short-campaign batch smoke test

        In test_simbot_basic_run.gd or new SimBot test file, select a short campaign (5 days).

        Instantiate SimBot and load a valid StrategyProfile resource.

        Set the active campaign configuration on CampaignManager to the short campaign.

        Call SimBot.run_batch(profile_id, runs=3, base_seed=1234) and await completion.

        Assert:

            Test finishes without throwing.

            GameManager’s current_day is within a sensible range (1..campaign_length+1).

            Optionally, currency and stats in SimBot or GameManager are non‑negative and within expected bounds.

    No UI access during SimBot runs

        Set up a test that does NOT instantiate main.tscn – only autoloads and SimBot exist.

        Optionally create a fake UIManager that crashes when called and ensure it is not added to the tree.

        Call SimBot.run_single(profile_id, seed=42).

        Assert:

            Run completes successfully.

            Any instrumentation you add to detect UI access (e.g. tracking calls on UIManager) remains untouched.

    CSV logging invariants and determinism

        Before running, delete or redirect user://simbot_logs/simbot_balance_log.csv to a temp location.

        Run SimBot.run_batch once with fixed profile and seed.

        Open user://simbot_logs/simbot_balance_log.csv.

        Assert:

            File exists.

            Header row contains expected columns (e.g. run_id,profile_id,seed,day,gold,kills,win, adjust to your actual schema).

            At least one data row exists.

        Run SimBot.run_batch again with the same profile and seed.

        Re-open the file, read the new rows.

        Assert:

            New rows are appended.

            Data rows for the same (run index, day, profile, seed) combination are identical across runs (deterministic).

4. Sell UX (build-mode sell flow)

    New or extended sell tests

        Extend test_hex_grid.gd or add test_sell_ux.gd.

    Selling an occupied slot refunds and frees

        In setup, instantiate HexGrid and EconomyManager, then place a known building at slot 0.

        Record gold_before and building_material_before.

        Trigger the same sell entry point used by BuildMenu/InputManager for slot 0.

        Assert:

            Sell returns true / success.

            Gold increases (or matches expected refund value).

            Materials adjust as specified by design, if applicable.

            Slot 0 is now empty (e.g., place_building(0, type) succeeds).

    Attempting to sell an empty slot is a safe no-op

        Ensure slot 5 (or another valid index) is empty.

        Attempt to sell that slot using the same API.

        Assert:

            Sell returns false or otherwise indicates no‑op.

            Gold and materials remain equal to pre‑call values.

    Invalid slot indices are safe

        Attempt to sell at index -1.

        Attempt to sell at index >= slot_count.

        Assert:

            No crash.

            Operation returns false or behaves as safe no‑op.

5. Firing assist / miss perturbation

    Assist not applied beyond max distance

        Extend test_simulation_api.gd or add test_firing_assist.gd.

        Configure a test WeaponData with small assist_max_distance (e.g. 10 units).

        Put target/enemy at a distance significantly larger (e.g. 30 units).

        Call the tower’s public or test‑exposed method that wraps _resolve_manual_aim_target().

        Assert the resolved target is equal to the original aim (no snapping or assist).

    Miss perturbation respects max miss angle

        Configure WeaponData with base_miss_chance = 1.0 and max_miss_angle_degrees = 2.0.

        Seed the RNG deterministically for repeatability.

        Fire a series of manual shots, collect actual target vectors for each.

        Compute angle between intended aim vector and adjusted vector for each shot.

        Assert all angles are ≤ 2 degrees.

    SimBot/autofire bypass assist

        Prepare two flows: manual aim and autofire/SimBot path.

        In tests, record the target vector used for projectiles:

            Under manual firing (assist enabled).

            Under auto-fire or SimBot in the same geometry.

        Assert:

            Manual path shows adjusted vectors when in assist window.

            Auto-fire/SimBot path uses unmodified targets, confirming assist logic is not applied for AI or auto modes.

6. Weapon upgrade station

    Extend test_weapon_upgrade_manager.gd

        Work in that suite; don’t create a second for the same class.

    Upgrade beyond max level fails safely

        Initialize WeaponUpgradeManager with a weapon at its documented maximum level.

        Call upgrade_weapon(slot) again.

        Assert:

            Method returns false (or documented failure pattern).

            Weapon level remains at max, no further upgrades applied.

    Upgrade with insufficient resources fails and doesn’t mutate state

        Set EconomyManager’s gold/materials just below the required cost for upgrade.

        Attempt to upgrade.

        Assert:

            Upgrade returns false.

            Gold/material values are unchanged.

            weapon_upgraded signal is not emitted.

    Cost modifiers from territories / research

        Set up a test where TerritoryData or Research apply a cost modifier to upgrades.

        Compute expected modified cost in GDScript test from raw .tres values and bonuses.

        Trigger an upgrade under these conditions.

        Assert the observed gold delta matches the computed modified cost exactly.

7. Enchantments

    Extend test_enchantment_manager.gd or test_tower_enchantments.gd

        Add mid-mission change tests there.

    Removing enchantments leaves existing projectiles unchanged

        Equip tower with Enchantment A that changes projectile damage or type.

        Fire a batch of projectiles; store references and/computed damage output.

        Remove the enchantment.

        Let first batch collide and apply damage; measure effect.

        Assert those projectiles still reflect Enchantment A’s effects.

        Fire a new batch after removal and assert these use base weapon stats (no enchantment).

    Swapping enchantments only affects future shots

        Start with Enchantment A, fire batch and record effect.

        Swap to Enchantment B mid-mission.

        Fire a second batch.

        Assert:

            First batch matches A behavior.

            Second batch matches B behavior.

            No mixed state or crash appears at the transition.

8. Building collision & pathfinding

    Extend test_enemy_pathfinding.gd

        Add new tests for dense layouts and flying enemies.

    Ground enemies recover from dense obstacle layouts

        Use HexGrid and BuildingBase to create a narrow, winding corridor pattern.

        Spawn several ground enemies near the entrance.

        Advance physics for a large number of frames (e.g. 600 frames).

        Track each enemy’s position each frame.

        Assert for each enemy:

            Position changes over time; it is not identical for more than N consecutive frames (stuck threshold).

            Ideally, enemies eventually reach either intended goal or leave starting region.

    Flying enemies ignore building obstacles

        Re‑use the dense obstacle layout.

        Spawn a flying enemy (is_flying = true) behind the obstacles.

        Run a baseline without obstacles, recording the enemy’s path / time to goal.

        Run again with obstacles active.

        Assert path and/or time to goal are effectively the same (within tolerance), confirming obstacles don’t affect flying units.

9. Faction data robustness

    Extend test_faction_data.gd / test_wave_manager.gd

    Missing FactionData resource

        Craft a DayConfig with faction_id that has no corresponding FactionData resource on disk.

        Call WaveManager.configure_for_day(day_config).

        Assert:

            Method returns false or some error indicator.

            No crash occurs.

        Attempt to start a wave; assert either:

            No enemies spawn, or

            A documented fallback composition is used safely.

    Empty faction roster safe behavior

        Create FactionData with an empty roster list.

        Configure WaveManager using this faction and call configure_for_day.

        Start a wave.

        Assert:

            No crash.

            Behavior matches the chosen design: zero enemies or explicit fallback.

10. Dialogue conditions

    Extend test_dialogue_manager.gd

    Missing research nodes for Sybil/Arnulf conditions

        Create DialogueConditions for sybil_research_unlocked_any and arnulf_research_unlocked_any referencing IDs that don’t exist in ResearchManager’s tree.

        Evaluate conditions via DialogueManager in isolation (no UI).

        Assert each returns false.

        Assert no unhandled errors or engine warnings beyond expected logs.

    Broken dialogue chains do not crash

        Create DialogueEntry chain where one next_id refers to a non-existent entry.

        Start a conversation through DialogueManager and call “get next” repeatedly.

        Assert:

            When invalid next_id is reached, DialogueManager returns null or ends conversation gracefully.

            No crash or infinite loop occurs.

11. Hub 2D robustness

    Extend test_character_hub.gd or add test_hub_resilience.gd

    Missing Hub/DialoguePanel handled gracefully

        Instantiate UIManager in a test scene without adding Hub or DialoguePanel scenes.

        Call methods like open_shop_panel, open_research_panel, or generic “open hub panel” methods.

        Assert:

            Calls complete without throwing.

            If you have logging helpers, assert that UIManager executed its safe re-fetch / warning path, but didn’t crash.

12. Florence meta-state

    Extend test_florence.gd

    Higher-priority day-advance reason wins

        Identify two DayAdvanceReason values where one has higher priority via Types.get_day_advance_priority().

        Initialize FlorenceData in GameManager (or equivalent).

        Simulate a day with two reasons fired in sequence: first the lower-priority, then higher-priority reason.

        Assert final Florence state/counters correspond to the higher-priority reason.

        Optionally repeat with reversed call order to prove priority, not order, controls result.

13. Art placeholder overrides

    Extend test_art_placeholders.gd

    Generated art overrides placeholders from /art/generated/

        In test setup, create or ensure existence of a “generated” mesh/material under res://art/generated/meshes/enemies/ matching an existing placeholder key.

        Verify ArtPlaceholderHelper lookup order prefers art/generated over base art/meshes.

        Spawn an EnemyBase instance that uses that art key via ArtPlaceholderHelper.

        Grab the MeshInstance3D or corresponding visual node and inspect its mesh/material resource.

        Assert the resolved resource originates from art/generated/... path, not the placeholder path.

If you tell me which section you’ll tackle first, I can condense that section into an even shorter, step‑by‑step coding sequence.

AUDIT 6
Below is a single, copy‑pasteable implementation backlog derived from the audit. It is organized by system and focuses on concrete, implementable work items.
1. Spells and combat systems

1.1 Implement multi‑spell system

    Add additional SpellData .tres resources for at least 2–3 new spells (e.g. slow field, beam, shield), with IDs, damage, radius, cost, and cooldown.

    Extend SpellManager to register and cast multiple spells by ID (not just shockwave).

    Update input bindings (and/or UI hotkeys) to support selecting/casting different spells.

    Add tests in tests/test_spell_manager.gd (or equivalent) for casting each new spell and verifying damage/effects.

1.2 Implement structural weapon upgrades

    Extend WeaponLevelData to support structural properties (e.g. can_pierce, projectile_count, spread_angle, splash_radius).

    Update Tower.gd fire logic to respect new properties (piercing projectiles, multi‑projectile patterns, etc.).

    Add tests for each structural behavior (pierce, multi-shot, etc.) to ensure deterministic behavior and SimBot compatibility.

1.3 Finalize Archer Barracks and Shield Generator behaviors

    Design and implement actual behaviors for Archer Barracks and Shield Generator (currently 0 fire rate and damage). Consider:

        Archer Barracks: periodically spawn ally archers or buff nearby allies.

        Shield Generator: add shield HP or damage reduction to tower/buildings.

    Update BuildingData .tres for these buildings to non-zero, meaningful stats.

    Extend BuildingBase and/or new helper scripts for these special behaviors.

    Add tests for these buildings’ behaviors and interactions (enemy attacks, buffs, etc.).

2. Allies, Arnulf, and mercenaries

2.1 Finish generic ally combat behaviors

    Implement support ally buffs in AllyBase (e.g. aura effects, healing, or damage buffs) using AllyData role/flags.

    Implement ranged ally projectiles for ranged allies, reusing or extending ProjectileBase and ally-specific projectile scenes.

    Implement ally uses_downed_recovering path using AllyData fields so generic allies can enter DOWNED/RECOVERING states similar to Arnulf.

2.2 Implement Ally targeting improvements

    Use cantargetflying and preferred_targeting in AllyData to influence AllyBase target selection (ground vs flying, priority).

    Add tests for flying-target preference and different targeting modes (CLOSEST, FARTHEST, etc.).

2.3 Implement ally leveling and scaling

    Use startinglevel and level_scaling_factor in AllyData to scale HP, damage, or other stats over the campaign.

    Decide progression sources (campaign day, research, shop, or experience) and implement in CampaignManager and/or GameManager.

    Add tests validating ally stat scaling across days/levels.

2.4 Complete mini‑boss defection timing and gating

    Implement defection_day_offset logic from MiniBossData to inject defection offers on later days (not just immediately).

    Use required_territory_ids, required_faction_ids, and required_research_ids in MercenaryOfferData to gate offers properly.

    Add tests for delayed defection and gated mercenary offers.

3. Territory, campaign, and economy

3.1 Use all TerritoryData bonuses

    Wire bonus_flat_gold_per_kill, bonus_research_per_day, bonus_research_cost_multiplier, bonus_enchanting_cost_multiplier, and bonus_weapon_upgrade_cost_multiplier into GameManager, ResearchManager, ShopManager, EnchantmentManager, and WeaponUpgradeManager (as appropriate).

    Ensure is_active_for_bonuses() in TerritoryData controls whether bonuses are applied (controlled + not permanently lost).

    Add tests that validate territory bonuses are applied when territories are controlled and not applied otherwise.

3.2 Implement default faction behavior

    Use default_faction_id in TerritoryData when DayConfig does not explicitly set a faction.

    Ensure CampaignManager and WaveManager correctly derive the faction from territory when faction_id is empty.

    Add tests verifying fallback behavior and that it remains deterministic.

3.3 Fix campaign day/mission placeholder reuse

    Replace the mission_index placeholder reuse in DayConfig (days >5 mapping to mission 5) with real mission configurations for all 50 days.

    Update relevant CampaignConfig .tres files so each day points at the correct content (enemy compositions, terrain, bosses).

    Update and/or add tests that rely on distinct day content (e.g., different enemy mixes, boss-days).

3.4 Implement Endless mode

    Design and implement an Endless mode flow in GameManager (new GameState, wave progression without a fixed day cap).

    Extend WaveManager to support endless scaling rules (HP/damage multipliers, spawn counts beyond a fixed cap).

    Add a new Endless mode entry point in the main menu UI and tests to verify simulation works headless in endless mode.

3.5 Implement save/load persistence

    Design a SaveManager (autoload) and a Profile resource format capturing: campaign progress, territories, allies/mercenaries, weapon/enchantment states, Florence meta-state.

    Implement serialization to disk (e.g., user://profile.json or similar) and loading on startup.

    Ensure that autoloads (CampaignManager, GameManager, ResearchManager, ShopManager, EnchantmentManager, DialogueManager, SimBot) can restore state cleanly.

    Add tests to serialize a mid-campaign state, reload it in a clean run, and confirm equivalence.

4. Shop, research, and consumables

4.1 Generalize consumables system

    Replace the one-off _mana_draught_pending flag with a generalized consumables model (stack counts, cooldowns, types) managed in a dedicated component or in ShopManager.

    Define consumable types in data (new resource or extended ShopItemData) with fields such as duration, cooldown, and effect tags.

    Extend GameManager and SpellManager to consume consumables generically (not just hard-coded mana draught).

    Add tests for multiple consumables, stacking rules, and correct application in battles.

4.2 Harden enchantment unlocks

    Replace the placeholder enchantment unlock logic in ShopManager (literal item_id checks) with a data-driven mechanism based on Research or ShopItemData flags.

    Update FlorenceData hooks (has_unlocked_enchantments) to be set consistently via research, shop, or progression.

    Add tests for unlocking enchantments and verifying UI/EnchantmentManager behavior.

4.3 Make full use of EnchantmentData effect hooks

    Implement handling of effect_tags and effect_data in Tower/ProjectileBase or a dedicated EnchantmentEffects helper.

    Add at least one enchantment that uses effect_tags for additional effects (e.g., applying poison DoT, slow, or armor reduction).

    Add tests verifying new effects are correctly applied and remain deterministic.

5. Dialogue, hub, Florence, and narrative

5.1 Implement character relationship/affinity system

    Define a relationship data structure in FlorenceData or a new RelationshipData resource, mapping character IDs to numeric affinity values.

    Update DialogueManager to support conditions based on relationship thresholds (e.g., florence_relationship_SYBIL >= 3).

    Introduce increments to relationship values based on events (mission success, purchases from characters, boss kills, etc.).

    Add tests verifying relationship changes and dialogue gating based on relationship thresholds.

5.2 Implement mid-battle dialogue triggers

    Add conditions and hooks in GameManager, WaveManager, SpellManager, and Tower to emit dialogue triggers (e.g., first boss spawn, tower HP < 25%, first spell cast) to DialogueManager.

    Extend DialogueCondition/DialogueEntry usage to support such triggers (new keys like tower_hp_percent, spell_cast_id).

    Ensure all dialogue invocations remain headless-safe for SimBot (no direct UI access in game scripts).

    Add tests verifying that appropriate dialogues become eligible and are selected when triggers occur.

5.3 Replace all TODO/PLACEHOLDER dialogue and descriptions

    Audit all .tres dialogue entries and AllyData/BossData/TerritoryData descriptions for TODO or PLACEHOLDER and author final text.

    Update CharacterData descriptions, portraits, and icon IDs from TODO/POST‑MVP to real values.

    Ensure string IDs (entry_id, character_id) remain stable; only text/metadata change.

5.4 Strengthen Florence meta-state usage

    Fully integrate FlorenceData flags (has_unlocked_research, has_unlocked_enchantments, has_recruited_any_mercenary, has_seen_any_miniboss, has_seen_first_boss, etc.) with events in GameManager, ResearchManager, ShopManager, CampaignManager.

    Add or refine DialogueConditions that depend on these flags for real narrative branches.

    Add tests for Florence state transitions and resulting dialogue availability.

6. SimBot and AutoTestDriver

6.1 Flesh out SimBot signal handlers

    Implement logic in SimBot’s empty handlers:

        _on_wave_cleared: log per-wave metrics, adjust build/spell priorities, or trigger early exit.

        _on_all_waves_cleared: finalize metrics and end the run.

        _on_game_state_changed: track transitions and avoid actions in non-combat states.

        _on_mission_started: reset run/misson metrics and recalc decisions.

    Ensure implementations remain headless-safe (no UI references) and do not break existing tests.

    Add new tests covering multi-wave runs and verifying handler behavior and metrics logging.

6.2 Use StrategyProfile difficulty targets

    Implement usage of difficulty_target from StrategyProfile in SimBot’s metrics evaluation, possibly calculating a “fit score” vs actual performance.

    Optionally add a simple tuning mode (e.g., CLI flag) that runs multiple profiles and reports which is closest to target.

    Add tests around difficulty scoring and profile comparison.

6.3 Cleanly document and/or adjust AutoTestDriver deviation

    Decide on desired behavior:

        Either accept that --simbot_profile should run SimBot without --autotest, and update AUDIT_CONTEXT_SUMMARY / project docs accordingly, or

        Require --autotest even for SimBot runs, and adjust _ready() in auto_test_driver.gd accordingly.

    Add tests or CI scripts reflecting the chosen contract, to avoid regressions.

7. Art, icons, and UI

7.1 Implement icon pipeline

    Populate res://art/icons/buildings, .../enemies, .../allies with initial placeholder PNGs or textures.

    Implement actual get_building_icon, get_enemy_icon, get_ally_icon, etc. in ArtPlaceholderHelper to return these textures instead of null.

    Integrate icons into UI panels (shop, research, world map, dialogue) without introducing game logic into UI scripts.

    Add tests (if feasible) or at least automated checks ensuring icon lookups return non-null for implemented entities.

7.2 Implement Settings screen

    Replace pass in ui/main_menu.gd::_on_settings_pressed() with opening a proper Settings scene/screen.

    Implement basic options (volume, graphics quality, keybinds) and ensure they persist between sessions if save/load is implemented.

    Add simple UI tests verifying settings actions do not crash and apply to the correct subsystems.

8. Destructibility and environment

8.1 Implement building destruction flows

    Use BuildingBase.disable_collision_and_obstacle() to support actual building destruction (e.g., when HP reaches 0 or a specific effect triggers it).

    Decide behavior: resource refunds? debris? impact on navigation? Implement accordingly in BuildingBase and GameManager.

    Add tests verifying destroyed buildings stop attacking, are not targetable, and react correctly with pathfinding and HexGrid bookkeeping.

8.2 Implement optional destructible props (if still desired)

    If the design spec requires scenery destructibles, create a DestructibleProp scene + script with HP, destruction visuals, and signal emission.

    Place some props in scenes and ensure they interact correctly with projectiles/spells/enemies.

    Add tests verifying destructibles behave correctly and don’t disrupt core systems.

9. Testing, consistency, and documentation

9.1 Run and stabilize full GdUnit suite

    Run ./tools/run_gdunit.sh in a clean environment and fix any failing tests or environment issues (e.g. orphan-node warnings, CLI arg problems).

    Update any tests that reference now-changed behaviors (e.g. multi-spell support, ally leveling, new SimBot logic).

9.2 Add tests for new systems

    For every new or expanded feature above (multi-spell, structural upgrades, ally levels, territory bonuses, consumables, relationships, midbattle dialogue, endless mode, SimBot handlers, icons, settings, destructibility), create focused GdUnit tests.

9.3 Reconcile PROBLEM_REPORT.md (if available)

    Open PROBLEM_REPORT.md in the repo and reconcile its entries with this backlog:

        Close or update problems that are fixed.

        Add missing items from that file to this backlog if any remain unaddressed.

9.4 Update documentation

    Update AUDIT_CONTEXT_SUMMARY.md Section 2 and any INDEX_* files to reflect new systems and resolved POST‑MVP items.

    Update architecture docs for any changed contracts (e.g. AutoTestDriver behavior, SimBot difficulty targets, save/load system, endless mode).

If you paste this list into your “cursor prompt,” you can work system by system, turning each bullet into a concrete implementation and corresponding tests. As you implement, I recommend starting with low‑risk, high‑leverage items (territory bonuses, SimBot handlers, enchantment effects) before tackling bigger features (relationship system, endless mode, full save/load).

AUDIT 7
Here is a concrete, copy‑pastable implementation TODO list based on the Prompt 16/17 audit.
1. Bring INDEX_FULL.md up to date for Prompt 16

    Add StrategyProfile script to the resources section

        Insert an entry for resscriptsresourcesstrategyprofile.gd under the resources scripts list.

        Mark it as: NEW – P16 StrategyProfile resource (SimBot profiles).

    Document the SimBot profile resources

        Under the resources .tres section, add entries for the strategy profile bundle, e.g.:

            resresourcesstrategyprofilesstrategybalanceddefault.tres

            resresourcesstrategyprofilesstrategygreedyecon.tres

            resresourcesstrategyprofilesstrategyheavyfire.tres

        Mark as: NEW – P16 Strategy profile data (default, greedy econ, heavy fire).

    Document the SimBot profile and run tests

        In the tests section, add entries for:

            resteststestsimbotprofiles.gd

            resteststestsimbotbasicrun.gd

            resteststestsimbotlogging.gd

            resteststestsimbotdeterminism.gd

            resteststestsimbotsafety.gd

        Mark all as: NEW – P16 SimBot strategy profile and safety tests.

    Update the SimBot API section in INDEX_FULL.md

        Under the SimBot API documentation, add entries for the two new public methods:

            func runsingle(profile_id: String, run_index: int, seed_value: int) -> Dictionary

            func runbatch(profile_id: String, runs: int, base_seed: int = 0, csv_path: String = "") -> void

        Briefly describe each (purpose, headless‑safe, main parameters).

        Ensure the SimBot API summary reflects CSV logging behavior (default path and how to override).

    Note the AutoTestDriver CLI extension in INDEX_FULL.md

        Under the autotestdriver.gd entry, add a Prompt 16 delta mentioning:

            New command‑line arguments: --simbotprofile, --simbotruns, --simbotseed.

            Behavior: if --simbotprofile is passed, run SimBot batch without requiring --autotest.

2. Bring INDEX_FULL.md up to date for Prompt 17 (art pipeline)

    Add ArtPlaceholderHelper script to the script map

        Under “art” or helper scripts, add:

            resscriptsartartplaceholderhelper.gd – NEW – P17 ArtPlaceholderHelper; convention-based art resolver for meshes/materials/icons.

    Document all res/art resource files

        Under resources, add entries for:

            resartmeshesenemies.tres

            resartmeshesbuildings.tres

            resartmeshesallies.tres

            resartmeshesmisc.tres

            resartmaterialsfactions.tres

            resarticonsbuildings.tres (empty POST‑MVP stub)

            resarticonsenemies.tres (empty POST‑MVP stub)

            resarticonsallies.tres (empty POST‑MVP stub)

        Mark all as: NEW – P17 Art placeholder resources.

    Document generated asset drop‑zones

        In the INDEX_FULL resources/tools or pipeline section, add notes for:

            resartgeneratedmeshes/ – “Drop zone for AI/Blender mesh outputs, overrides placeholder meshes when present.”

            resartgeneratedicons/ – “Drop zone for generated icons, overrides placeholder icons when present.”

    Reference README files for the art pipeline

        Under documentation/tools in INDEX_FULL, add entries for each READMEARTPIPELINE.md or a single grouped entry like:

            resart**/READMEARTPIPELINE.md – P17 Art pipeline documentation (naming, override rules, drop‑zone usage).

    Document scene art reference changes

        For each affected scene, update its INDEX_FULL entry to mention Prompt 17 art wiring:

            resscenesbuildingsbuildingbase.tscn – MODIFIED – P17: now references resart meshes/materials and uses art placeholders.

            resscenenemiesenemybase.tscn – MODIFIED – P17: art resources wired via resart.

            resscenestowertower.tscn – MODIFIED – P17: tower mesh/material from resart.

            resscenesarnulfarnulf.tscn – MODIFIED – P17: Arnulf mesh/material from resart.

            resscenesprojectilesprojectilebase.tscn – MODIFIED – P17: projectile mesh from resart.

            ressceneshexgridhexgrid.tscn – MODIFIED – P17: hex slot mesh/material from resart.

    Document the new art test

        Add resteststestartplaceholders.gd to the tests section, marked:

            NEW – P17 Art placeholder wiring test (preload-only, headless-safe).

3. Optional test improvements (currently [NO TEST] assets)

    Decide whether to keep or improve coverage for pure data assets

        For resartmeshes*.tres, resartmaterialsfactions.tres, and resarticons*.tres, choose explicitly:

            Either: accept that they remain untested (document in INDEX_FULL or a test coverage note as “data‑only, no dedicated tests”), or

            Add minimal GdUnit tests that load these resources and assert they exist and have expected basic properties (e.g. non‑null meshes/materials, known resource paths).

    Decide whether to add explicit tests for scene art wiring

        Option A (minimal): rely on test_art_placeholders.gd plus existing gameplay tests to catch broken resource paths.

        Option B (stricter): add tests that instantiate each modified scene (tower.tscn, enemybase.tscn, etc.) headlessly and assert that:

            The MeshInstance3D nodes can be instantiated.

            The ArtPlaceholderHelper finds either generated or placeholder resources without throwing.

        If you choose B, add new test files and index them in INDEX_FULL.

4. Process / documentation clean‑up

    Clear remaining “UNINDEXED — Prompt 16/17” flags in AUDIT_CONTEXT_SUMMARY and index files

        After updating INDEX_FULL, revise any notes in:

            AUDIT_CONTEXT_SUMMARY.md Section 3 that currently say “UNINDEXED — Prompt 16/17” for:

                strategyprofile.gd

                strategyprofiles.tres

                SimBot profile tests and API methods

                resart*.tres and scene art references

        Update them to reflect that indexing is now complete.

    Confirm that INDEX_MACHINE.md and INDEX_SHORT.md are consistent

        Update INDEX_MACHINE (or equivalent machine-readable index) to include:

            strategyprofile.gd, strategyprofiles.tres, SimBot tests.

            artplaceholderhelper.gd, resart*.tres, art test.

        Ensure INDEX_SHORT and INDEX_FULL both reference the same Prompt 16/17 entries.

    Record the test coverage decision explicitly

        In either INDEX_FULL’s test section or a separate testing doc, note:

            Which art resources and scenes are intentionally left without dedicated tests, and why (pure data, covered by higher‑level tests, etc.).

            That Prompt 16’s SimBot tests plus Prompt 17’s art test have been integrated and indexed.

If you want, I can next turn this into a step‑by‑step “editing script” (e.g. ordered edits to each specific file with suggested headings/sections) for easier implementation.
