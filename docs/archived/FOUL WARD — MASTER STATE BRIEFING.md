FOUL WARD — MASTER STATE BRIEFING FOR DOCUMENTATION GENERATION

Purpose: This document is the source-of-truth briefing to be used by an Opus model to generate a master FOUL_WARD_MASTER_DOC.md file. That file should serve as a living manual — updated every time any system is added, changed, or cut — readable by both human developers and LLM agents (Cursor, Perplexity, or otherwise). Every section below describes current verified code state AND confirmed future planned state. Nothing here is speculative unless explicitly marked TBD.

Source material verified against: Workplan-executed-checklist.txt (Prompt 51 codebase snapshot), SUMMARY_VERIFICATION.md, Summaries.md, OPUS_ALL_ACTIONS.md, and direct resource/script dumps.
SECTION 1 — PROJECT IDENTITY

Game title: Foul Ward
Engine: Godot 4 (GDScript)
Genre: Real-time tower defense, stationary perspective (player controls the tower itself, aiming manually with a mouse), inspired by TAUR
Campaign structure: 50-day main campaign. Each day = one mission. Missions have a build phase then wave combat.
Test count: 525 passing GdUnit4 tests as of Prompt 51
Primary files of record:

    docs/INDEX_SHORT.md — compact one-liner per file index

    docs/OPUS_ALL_ACTIONS.md — consolidated snapshot, improvement backlog, standing orders

    REPO_DUMP_SCRIPTS.md, REPO_DUMP_SCENES.md, REPO_DUMP_RESOURCES.md — full code/scene/resource dumps

SECTION 2 — CORE ARCHITECTURE
Player Character: Florence

    Male plague doctor. The player IS Florence — a stationary tower that the player aims manually with the mouse.

    Script: res://scripts/florence_data.gd — class FlorenceData extends Resource (NOT an autoload)

    Tracked fields: florence_id, display_name, total_days_played, run_count, total_missions_played, boss_attempts, boss_victories, mission_failures, has_unlocked_research, has_unlocked_enchantments, has_recruited_any_mercenary, has_seen_any_mini_boss, has_defeated_any_mini_boss, has_reached_day_25, has_reached_day_50, has_seen_first_boss

    Florence takes damage directly from enemies reaching the tower (SignalBus.florence_damaged)

    Two weapon slots: CROSSBOW (damage 50.0, no flying) and RAPID_MISSILE (damage 8.0, no flying) — defined in res://resources/weapon_data/crossbow.tres and rapid_missile.tres

AI Companions

Three named companions exist. All are permanent characters in the world.

Arnulf

    Role: Melee frontline ally, autonomous fighter

    ally_id: arnulf, max_hp: 200, basic_attack: 25.0, is_unique: true, is_starter_ally: true

    Has a full state machine in arnulf.gd with Types.ArnulfState

    Drunkenness system: DOES NOT EXIST IN CODE. Formally cut from design. No enum, no state, no reference anywhere.

    Signals: arnulf_state_changed, arnulf_incapacitated, arnulf_recovered

Sybil

    Role: Spell researcher / spell support

    Manages the spell system via SpellManager

    Passive selection system: NOT YET IN CODE. Confirmed added to design.

        Before each mission, Sybil's unlocked passives should be available

        Whether player picks one passive OR all are active simultaneously is TBD (recommended: all active simultaneously as Option B)

        Implementation: new SybilPassiveData resource class, SpellManager reads active passives at mission start, applies to mana_regen_rate/max_mana/cooldowns

        If single-pick is chosen: add PASSIVE_SELECT GameState between MISSION_BRIEFING and BUILD_MODE

Florence

    Male plague doctor (see above)

    Hub keeper for the main screen

Weapons

    WeaponData fields: weapon_slot (enum Types.WeaponSlot), display_name, damage (single float — NOT base_damage_min/base_damage_max)

    Two weapon .tres files: crossbow.tres (slot 0), rapid_missile.tres (slot 1)

    Weapon upgrades tracked via SignalBus.weapon_upgraded(weapon_slot, new_level)

SECTION 3 — AUTOLOADS (init order matters)

All registered in project.godot in this order:

    SignalBus — res://autoloads/signal_bus.gd — Central typed signal hub. 58 signals. No logic, no state. Never add logic here.

    NavMeshManager — res://scripts/nav_mesh_manager.gd — Registers NavigationRegion3D, queues bake on nav_mesh_rebake_requested

    DamageCalculator — res://autoloads/damage_calculator.gd — Stateless 4×4 damage-type × armor-type matrix. Pure function singleton.

    AuraManager — res://autoloads/aura_manager.gd — Registers aura towers and enemy aura emitters. get_damage_pct_bonus, get_enemy_speed_modifier, get_enemy_damage_bonus, get_enemy_heal_per_sec

    EconomyManager — res://autoloads/economy_manager.gd — Owns gold, building_material, research_material. Duplicate cost scaling via building_id. register_purchase, get_refund → Dictionary, reset_for_mission, apply_mission_economy, grant_wave_clear_reward, passive gold per wave

    CampaignManager — res://autoloads/campaign_manager.gd — Day/campaign progress, faction registry, owned_allies, active_allies_for_next_day, mercenary catalog, auto_select_best_allies. MUST load before GameManager.

    RelationshipManager — res://autoloads/relationship_manager.gd — Affinity −100..100 per character_id, tiers from relationship_tier_config.tres, loads character_relationship/*.tres + relationship_events/*.tres

    SettingsManager — res://autoloads/settings_manager.gd — user://settings.cfg, master/music/SFX volumes, graphics quality, keybind mirror

    GameManager — res://autoloads/game_manager.gd — Owns game state (Types.GameState), mission index, wave index, territory map runtime, mission rewards, final boss state, held_territory_ids, advance_to_next_day, _spawn_allies_for_current_mission

    BuildPhaseManager — res://autoloads/build_phase_manager.gd — is_build_phase, build_phase_started / combat_phase_started, set_build_phase_active. Also handles ring rotation: rotate_ring() exists in code with NO UI YET.

    AllyManager — res://autoloads/ally_manager.gd — Summoner building squads, spawn_squad / despawn_squad, _squads by placed_instance_id

    CombatStatsTracker — res://autoloads/combat_stats_tracker.gd — begin_mission/begin_run/register_building/flush_to_disk/end_run → user://simbot/runs/{mission_id}_{timestamp}/ CSVs

    SaveManager — res://autoloads/save_manager.gd — Rolling autosaves user://saves/attempt_*/slot_*.json

    DialogueManager — res://autoloads/dialogue_manager.gd — Loads DialogueEntry .tres from res://resources/dialogue/**. Priority, AND conditions, once-only, chain_next_id. Emits dialogue_line_started / dialogue_line_finished

    AutoTestDriver — res://autoloads/auto_test_driver.gd — Headless smoke-test driver, active on --autotest or --simbot_profile or --simbot_balance_sweep

    GDAIMCPRuntime — GdAI MCP GDExtension bridge (editor only)

    EnchantmentManager — res://autoloads/enchantment_manager.gd — Per-weapon enchantment slots (elemental, power). 4 enchantment .tres files. Remove enchantment costs no gold (current implementation).

SECTION 4 — GAME STATES

Defined in res://scripts/types.gd as Types.GameState:

text
MAIN_MENU
MISSION_BRIEFING
COMBAT
BUILD_MODE
WAVE_COUNTDOWN
BETWEEN_MISSIONS
MISSION_WON
MISSION_FAILED
GAME_WON
GAME_OVER
ENDLESS

Planned additions (not yet in code):

    RING_ROTATE — pre-battle ring rotation screen (between MISSION_BRIEFING and BUILD_MODE)

    PASSIVE_SELECT — Sybil passive selection screen (TBD, only if single-pick option is chosen)

SECTION 5 — SPELLS

Manager: SpellManager — max_mana: 100, mana_regen_rate: 5.0 per second

Four registered spells (wired in main.tscn):

    shockwave.tres — "Shockwave"

    slow_field.tres — "Slow Field"

    arcane_beam.tres — "Arcane Beam"

    tower_shield.tres — "Aegis Pulse"

Hotkeys:

    Space → cast selected spell

    Tab / Shift+Tab → cycle spells

    Keys 1–4 → select spell slot 0–3 directly

Time Stop spell: FORMALLY CUT. Too complex. Do not implement. Do not reference in design docs.

Sybil Passives: See Section 2.
SECTION 6 — BUILDINGS

36 BuildingData .tres files under res://resources/building_data/. Key field names:

    gold_cost (NOT build_gold_cost)

    target_priority using Types.TargetPriority (NOT targeting_priority)

    damage_type as int matching Types.DamageType: 0=PHYSICAL, 1=FIRE, 2=MAGICAL, 3=POISON (4=TRUE)

    building_id for duplicate scaling in EconomyManager

Full building list (display_name / gold_cost):
Acid Dripper 40, Alarm Totems 40, Anti-Air Bolt 70, Arcane Lens 130, Archer Barracks 90, Arrow Tower 50, Ballista 100, Barracks Fortress 320, Bear Den 130, Bolt Shrine 45, Chain Lightning 130, Citadel Aura 350, Crossfire Nest 50, Crow Roost 45, Dragon Forge 350, Ember Vent 45, Field Medic 50, Fire Brazier 60, Fortress Cannon 280, Frost Pinger 50, Greatbow Turret 100, Gust Cannon 110, Iron Cleric 120, Magic Obelisk 80, Molten Caster 120, Net Gun 35, Plague Cauldron 280, Plague Mortar 110, Poison Vat 55, Shield Generator 120, Siege Ballista 140, Spike Spitter 40, Thornwall 30, Void Obelisk 300, Warden Shrine 120, Wolf Den 55

Ring Rotation:

    rotate_ring() EXISTS in BuildPhaseManager/HexGrid

    Pre-battle ring rotation UI DOES NOT EXIST YET. Confirmed on roadmap. Must be implemented.

    Spec: new screen or modal shown after mission briefing. Left/right buttons (or A/D) call rotate_ring(). Confirm button transitions to BUILD_MODE. Wire into GameManager._transition_to.

SECTION 7 — RESEARCH

24 research_data/*.tres files. Field names: node_id, display_name, research_cost (NOT rp_cost), prerequisite_ids.

Sample tree (simplified):

    Tier 1 unlocks: Arrow Tower +Damage (cost 1), Spike Spitter (1), Frost Pinger (2), Crow Roost (1), Wolf Den (2), Ballista (2), Shield Generator (3), Archer Barracks (3)

    Tier 2 unlocks: Greatbow Turret (2, req: Spike Spitter), Gust Cannon (2, req: Crow Roost), Bear Den (3, req: Wolf Den), Warden Shrine (2, req: Wolf Den), Molten Caster (2, req: Frost Pinger), Arcane Lens (3, req: Frost Pinger), Chain Lightning (3, req: Crow Roost)

    Tier 3 unlocks: Siege Ballista (3, req: Ballista), Barracks Fortress (5, req: Bear Den), Citadel Aura (6, req: Warden Shrine), Dragon Forge (5, req: Molten Caster), Fortress Cannon (4, req: Siege Ballista), Void Obelisk (5, req: Arcane Lens), Plague Cauldron (4, req: Arcane Lens)

SECTION 8 — ENCHANTMENTS

    Two slot types per weapon: "elemental" and "power"

    Four enchantment .tres files: arcane_focus.tres, scorching_bolts.tres, sharpened_mechanism.tres, toxic_payload.tres

    Remove enchantment: FREE (no gold cost in current implementation)

    Apply enchantment: uses try_apply_enchantment(..., gold_cost: int), may spend gold via EconomyManager

    No crafting material in current API

    _affinity_xp / _affinity_level stubs exist in manager — POST-MVP, not active

SECTION 9 — ALLIES & MERCENARIES

12 ally .tres files under res://resources/ally_data/:
ally_id	max_hp	attack_damage	is_unique	is_starter
arnulf	200	25.0	true	true
anti_air_scout	65	11.0	false	false
ally_melee_generic	90	12.0	false	false
ally_ranged_generic	70	14.0	false	false
ally_support_generic	80	8.0	false	false
bear_alpha	200	22.0	false	—
defected_orc_captain	140	18.0	true	false
hired_archer	70	14.0	false	false
knight_captain	180	28.0	false	—
militia_archer	90	14.0	false	—
wolf_alpha	80	12.0	false	—
wolf_pup	50	7.0	false	—

AllyData.identity, max_lifetime_sec, damage, target_flags defined (Prompt 39+42).
AllyManager handles squad spawning from summoner buildings by placed_instance_id.
SECTION 10 — ENEMIES & BOSSES

30 total EnemyData .tres files (6 original + 24 added in Prompt 50). Types.EnemyType values 0–29.

Three boss resources at top-level res://resources/:

    bossdata_final_boss.tres

    bossdata_orc_warlord_miniboss.tres

    bossdata_plague_cult_miniboss.tres

    bossdata_audit5_territory_miniboss.tres

Enemy special tags (runtime): ShieldComponent, AuraManager enemy aura emitters, charge/enrage/dash, regen, saboteur set_disabled, Brood Carrier spawn_enemy_at_position.
SECTION 11 — CAMPAIGN & PROGRESSION
Day/Wave Structure

    50 days in main campaign (campaign_main_50days.tres)

    5 days in short campaign (campaign_short_5days.tres — for testing)

    Each mission = 5 waves (WAVES_PER_MISSION)

    After Day 50 final boss: if boss not defeated, advance_to_next_day() increments day, _assign_boss_attack_to_day() picks a random held territory and marks it as final boss threat — loop continues until player wins or tower is destroyed

Star Difficulty System — CONFIRMED ON ROADMAP, NOT YET IN CODE

    Normal (1★), Veteran (2★), Nightmare (3★)

    Unlocked per-map AFTER the player completes the final boss

    Players can replay any cleared map at higher difficulty

    Implementation: add Types.DifficultyTier enum (NORMAL, VETERAN, NIGHTMARE). Each TerritoryData or DayConfig stores unlocked_difficulty_tiers: Array[Types.DifficultyTier]. Veteran/Nightmare apply multipliers on existing enemy_hp_multiplier / enemy_damage_multiplier fields in DayConfig. World Map shows star indicators per territory. Difficulty selector appears in BetweenMissionScreen once final boss is cleared.

Endless Mode

    CampaignManager.is_endless_mode and Types.GameState.ENDLESS EXIST in code (Prompt 23)

    start_endless_run() and synthetic day scaling implemented

    Leaderboards: NOT a core feature. Optional "upload score" button planned if easy to implement.

        At run end: show local score summary (waves survived, enemies killed, day reached)

        Optional submit button → lightweight HTTPS POST to external leaderboard service (LootLocker or Supabase)

        Entirely opt-in, no account required, button hidden if backend not ready

SECTION 12 — META-PROGRESSION: THE CHRONICLE OF FOUL WARD

STATUS: DOES NOT EXIST IN CODE. CONFIRMED ADDED TO DESIGN. Must be implemented.
Design

A persistent cross-campaign tome tracking every achievement across all playthroughs. Achievements unlock small optional upgrades ("Chronicle Perks"). Players toggle perks on/off before each run — completely optional.
Implementation Spec

    New resource class ChronicleData — saved to user://chronicle.json (or a dedicated SaveManager slot)

        Fields: achievements: Dictionary (achievement_id → bool unlocked), perks: Dictionary (perk_id → bool enabled)

    New resource class ChroniclePerkData (.tres)

        Fields: perk_id, display_name, description, required_achievement_id, effect fields (e.g. starting_gold_bonus: int, max_hp_bonus: int, mana_regen_bonus: float)

    GameManager / EconomyManager read enabled perks at start_new_game() and apply flat bonuses

    Achievement triggers hook into existing SignalBus events — mapping to existing FlorenceData fields:

        campaign_completed → "Completed a campaign"

        boss_killed → "Defeated a boss"

        has_reached_day_25 / has_reached_day_50 → milestone achievements

        run_count thresholds → "Played N runs"

        etc.

    New Chronicle Screen accessible from main menu and hub. Shows tome UI: list of achievements (locked/unlocked) and associated perks with toggle checkboxes.

    SignalBus will need new signals: chronicle_achievement_unlocked(achievement_id: String), chronicle_perk_toggled(perk_id: String, enabled: bool)

SECTION 13 — HUB SCREENS
Current State

    hub.tscn — 2D hub with CharacterCatalog and instances of character_base_2d.tscn in HBoxContainer. Placeholder ColorRect "Body" blocks — no portrait art yet. All marked # TODO(ART).

    between_mission_screen.tscn — TabContainer with tabs: World Map, Shop, Research, Buildings, Weapons, Mercenaries

    dialogue_panel.tscn — full click-to-continue dialogue overlay (for between-mission conversations)

Confirmed Final Design (NOT Hades-style)

    Each hub screen has a styled background image and a "keeper" NPC character visible (the relevant character for that screen — Merchant for Shop, Sybil for Research/Spells, Arnulf for Mercenaries, etc.)

    Style reference: TAUR — functional screens with character presence, not a navigable 3D space

    Each keeper has a dialogue line shown if they have something new to say

        Driven by existing DialogueManager priority + once_only flag

        Whether this auto-triggers or requires a "Talk" button: TBD

    HubRole enum already defined in types.gd: SHOP, RESEARCH, ENCHANT, MERCENARY, ALLY, FLAVOR_ONLY

Mid-Battle Dialogue (NOT full Hades-style)

    Lightweight: audio file plays + non-invasive subtitle strip at bottom of HUD

    NOT the full DialoguePanel overlay

    Triggers hook into existing SignalBus events: wave_started, enemy_enraged, ally_downed, boss_spawned, etc.

    Implementation: AudioStreamPlayer on character scene or global one-shot bus + slim Label/Panel anchored bottom of HUD, auto-dismissed after a few seconds

SECTION 14 — WORLD MAP
Current State

    ui/world_map.tscn — territory list + labels tab with TerritoryData backing

    SignalBus.world_map_updated and territory_state_changed(territory_id) exist

    5 terrain types: GRASSLAND, FOREST, SWAMP, RUINS, TUNDRA

Confirmed Final Design

    Hand-drawn illustrated fantasy map — a single large texture covering the scene

    Map is split into regions — each region = one level/territory

    Each TerritoryData.territory_id maps to a Polygon2D or TextureButton hotspot overlaid on the map texture

    Territory state (secured / threatened / locked) drives visual overlays (tint, icon badge) on each hotspot

    SignalBus.territory_state_changed hooks into refreshing hotspot visuals

    Star difficulty indicators per territory (once difficulty system is implemented — see Section 11)

SECTION 15 — DIALOGUE SYSTEM

    Manager: DialogueManager autoload

    Resources: 15 DialogueEntry .tres files under res://resources/dialogue/** — currently all placeholder (TODO:) text

    Fields: entry_id, character_id, text, plus conditions, once_only, chain_next_id, relationship tier gating

    Characters in dialogue resources: FLORENCE, COMPANION_MELEE (Arnulf), SPELL_RESEARCHER (Sybil)

    All dialogue content is placeholder. Content population is a future task.

SECTION 16 — SIGNALS REFERENCE (all 58)

text
enemy_killed(enemy_type, position, gold_reward)
enemy_reached_tower(enemy_type, damage)
tower_damaged(current_hp, max_hp)
tower_destroyed()
projectile_fired(weapon_slot, origin, target)
arnulf_state_changed(new_state)
arnulf_incapacitated()
arnulf_recovered()
ally_spawned(ally_id, building_instance_id)
ally_died(ally_id, building_instance_id)
ally_squad_wiped(building_instance_id)
ally_downed(ally_id)
ally_recovered(ally_id)
ally_killed(ally_id)
ally_state_changed(ally_id, new_state)
boss_spawned(boss_id)
boss_killed(boss_id)
campaign_boss_attempted(day_index, success)
wave_countdown_started(wave_number, seconds_remaining)
wave_started(wave_number, enemy_count)
enemy_spawned(enemy_type, position)
enemy_enraged(enemy_instance_id)
wave_cleared(wave_number)
all_waves_cleared()
resource_changed(resource_type, new_amount)
territory_state_changed(territory_id)
world_map_updated()
enemy_entered_terrain_zone(enemy, speed_multiplier)
enemy_exited_terrain_zone(enemy, speed_multiplier)
terrain_prop_destroyed(prop, world_position)
nav_mesh_rebake_requested()
building_placed(slot_index, building_type)
building_sold(slot_index, building_type)
building_upgraded(slot_index, building_type)
building_dealt_damage(instance_id, damage, enemy_id)
florence_damaged(amount, source_enemy_id)
building_destroyed(slot_index)
spell_cast(spell_id)
spell_ready(spell_id)
mana_changed(current_mana, max_mana)
game_state_changed(old_state, new_state)
mission_started(mission_number)
mission_won(mission_number)
mission_failed(mission_number)
florence_state_changed()
campaign_started(campaign_id)
day_started(day_index)
day_won(day_index)
day_failed(day_index)
campaign_completed(campaign_id)
build_mode_entered()
build_mode_exited()
research_unlocked(node_id)
research_node_unlocked(node_id)
research_points_changed(points)
shop_item_purchased(item_id)
mana_draught_consumed()
weapon_upgraded(weapon_slot, new_level)
enchantment_applied(weapon_slot, slot_type, enchantment_id)
enchantment_removed(weapon_slot, slot_type)
mercenary_offer_generated(ally_id)
mercenary_recruited(ally_id)
ally_roster_changed()

Signals to be added (planned features):

    chronicle_achievement_unlocked(achievement_id: String) — Chronicle system

    chronicle_perk_toggled(perk_id: String, enabled: bool) — Chronicle system

    Any signals needed for ring rotation UI confirmation

    Any signals needed for Sybil passive selection (if Option A single-pick is chosen)

SECTION 17 — SHOP

    Manager: ShopManager

    Current items: 4 shop items in catalog (exact ids TBD from shop_catalog.tres)

    Shop inventory rotation: PLANNED but unspecified, pending final item list. When item list is locked: add daily_offer_count to ShopItemData or ShopManager, draw random subset each day, mirror pattern of MercenaryCatalog.get_daily_offers().

SECTION 18 — SIMBOT / TESTING

    SimBot — headless simulation API. SimBot.run_balance_sweep, SimBot.run_batch, SimBot.debug_batch

    AutoTestDriver — active on --autotest, --simbot_profile, --simbot_balance_sweep

    CombatStatsTracker — writes wave/building CSVs to user://simbot/runs/

    Tools: tools/simbot_balance_report.py, tools/apply_balance_status.gd (BalanceStatusApplier)

    Tests: 525 passing GdUnit4 tests as of Prompt 51

    Quick iteration: ./tools/run_gdunit_quick.sh

SECTION 19 — THINGS THAT DO NOT EXIST AND MUST NOT BE ASSUMED TO EXIST

The following were discussed in design documents or early specs but are confirmed absent from code and some are formally cut:
Feature	Status
Arnulf drunkenness system	FORMALLY CUT — never implement
Time Stop spell	FORMALLY CUT — never implement
Hades-style 3D navigable hub	FORMALLY CUT — replaced by TAUR-style screens
build_gold_cost field on BuildingData	DOES NOT EXIST — correct field is gold_cost
targeting_priority field on BuildingData	DOES NOT EXIST — correct field is target_priority
rp_cost on ResearchData	DOES NOT EXIST — correct field is research_cost
weapon_id on WeaponData	DOES NOT EXIST — correct field is weapon_slot
base_damage_min / base_damage_max on WeaponData	DOES NOT EXIST — correct field is damage (single float)
Types.SpellType / Types.SpellID enums	DO NOT EXIST in types.gd
Chronicle / meta-progression system	DOES NOT EXIST YET — planned, see Section 12
Ring rotation UI	DOES NOT EXIST YET — planned, see Section 6
Sybil passive selection	DOES NOT EXIST YET — planned, see Section 2
Star difficulty system	DOES NOT EXIST YET — planned, see Section 11
Leaderboards	DOES NOT EXIST YET — optional future addition
Shop inventory rotation	DOES NOT EXIST YET — deferred pending item list
Hand-drawn world map art	DOES NOT EXIST YET — art direction confirmed
Hub keeper portrait art	DOES NOT EXIST YET — all TODO(ART) placeholders
Any dialogue content	DOES NOT EXIST — all 15 entries are TODO placeholders
SECTION 20 — CONVENTIONS & RULES FOR LLM AGENTS

These rules apply to every future Cursor session, Perplexity analysis, or any LLM touching this codebase:

    Never add logic to SignalBus. It is a pure signal hub with no state.

    CampaignManager must be registered before GameManager in project.godot init order.

    Field name discipline: Always use gold_cost, target_priority, research_cost, weapon_slot, damage. Never use the wrong names listed in Section 19.

    Types.gd is the single source of truth for all enums. If an enum does not exist in types.gd, it does not exist. Do not assume it exists elsewhere.

    All new signals go in signal_bus.gd with full typed parameters.

    All new persistent data resources go under res://resources/ in an appropriate subdirectory.

    All new GdUnit4 tests go under res://tests/unit/ following the pattern test_{system_name}.gd.

    FlorenceData is not an autoload — it is a Resource loaded by SaveManager/GameManager as needed.

    SimBot must remain headless-safe — no UI node dependencies in any code path SimBot exercises.

    push_warning not push_error for missing optional nodes in GameManager (GdUnit compatibility).

    Never use localStorage or sessionStorage — not applicable in Godot but noted for any web tooling.

    This document must be updated every time a system is added, changed, or formally cut. The update should happen in the same Cursor session as the implementation. The update checklist: (a) move feature from "planned" to "exists", (b) add correct field names to Section 19 if relevant, (c) add new signals to Section 16, (d) update the "does not exist" table in Section 19.

SECTION 21 — OPEN TBD ITEMS (decisions pending)
Item	Question	Who decides
Sybil passive selection	Single pick before mission OR all passives always active?	Designer
Hub keeper dialogue trigger	Auto-triggers when entering screen OR requires "Talk" button click?	Designer
Chronicle perk strength	How impactful are perks? (cosmetic-level micro-buffs vs meaningful advantage)	Designer/playtester
Shop rotation count	How many items shown per day when rotation is implemented?	Designer (after item list is locked)
Leaderboard backend	Which service if implemented? (LootLocker, Supabase, custom)	Developer
Star difficulty multipliers	Exact HP/damage/gold multipliers for Veteran and Nightmare