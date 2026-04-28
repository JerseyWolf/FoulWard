# WOLF Framework — Master Workplan
## Chunk 4b Part 4 of 5: Phase 2 Sessions S32–S33
### Demo Games Part 5: Dungeon Keeper Variant · Hybrid TD + Province

**Document version:** 1.0 | **Continues from:** Chunk 4b Part 3 (S30–S31)
**Covers:** The next two Phase 2 game sessions.
**Prerequisites:** S31 complete before S32; S22 and S27 complete before S33.

---

## Phase 2 Positioning

This pair closes the "variant and hybrid" tier of Phase 2. S32 proves that a second meaningfully different game can be built from the same dungeon foundation without forking it — instead layering a new mechanic (Contagion as room corruption) and a new faction skin on top of stable S31 code. S33 is the framework's most demanding MVP architecturally: it deliberately combines two proven sub-systems (province strategy from S27 + grid tower defense from S22) into one coherent game loop, which is the hardest genre-combination test the framework will face before the showcase. [file:1]

---

## Session S32 — WOLF-NECRO: Dungeon Keeper Variant

**Goal:** Demonstrate that a second Dungeon Keeper–style game can be produced from the S31 foundation in a single focused session by changing the faction skin, replacing the standard creature upkeep model with `ContagionManager` as a room-corruption spread mechanic, and introducing an undead-resurrection loop where fallen heroes can be raised as skeleton creatures. The session proves the framework's re-skinning and mechanic-swap capability rather than its ability to build from scratch. [file:1]

**The game in one sentence:** Run a Necromancer's bone catacombs where plague corruption spreads between rooms like a living organism, fallen heroes can be resurrected as skeleton servants, and three increasingly devout Paladin crusades must be repelled before they cleanse the Corruption Altar. [file:1]

### What changes from S31

| Component | S31 WOLF-DUNGEON | S32 WOLF-NECRO |
|-----------|-----------------|----------------|
| Faction name | Plague Dungeon | Bone Catacombs |
| Creature types | Ghoul, PlagueKnight, SkeletonArcher | Skeleton, WraithKnight, BoneGolem |
| Upkeep model | FlowEconomy gold drain | ContagionManager corruption spread |
| Core new mechanic | Fluid HTN construction | Hero resurrection loop |
| Room set | 5 generic dungeon rooms | 5 necromancy-themed rooms |
| Loss condition | Heart HP = 0 | Altar corruption = 0 (cleansed) |
| Win condition | Survive 3 waves | Corrupt all 4 shrine tiles before wave 3 |

The underlying scene structure, `DungeonTileManager`, HTN compound task engine, `InvasionManager`, hero pathfinding, and SignalBus signal set are all **reused without modification**. [file:1]

### Systems exercised (new or shifted usage)

- `ContagionManager.gd` repurposed: corruption is a SIR-like spread on the dungeon tile graph instead of a district graph; rooms at high corruption generate bonus creatures but also degrade faster [file:1]
- `UnitBase.tscn` resurrection pattern: on hero death emit `hero_killed(hero_id, cell_position)`, `NecromancyManager.gd` listens and after a 3s delay spawns a Skeleton unit at that cell [file:1]
- `FactionManager` for three factions: NECROMANCER (player), CRUSADERS (invaders), RESTLESS (neutral undead that occasionally fight both sides) [file:1]
- `GAS` — new room-aura effect: Bone Forge room applies `bone_hardened` status (+30 armour) to adjacent Skeleton and BoneGolem units [file:1]
- `DialogueBridge` for Necromancer advisor voice on corruption spread, resurrection events, and wave arrival [file:1]

### Perplexity context to load

- Chunk 4b Part 3 S31 deliverables in full: all dungeon scripts, tile manager, HTN domain, invasion manager, hero A* pathfinding [file:1]
- Chunk 2 S13 `ContagionManager.gd` — specifically its tile-graph adjacency mode [file:1]
- `framework/scripts/factions/FactionManager.gd` three-faction setup pattern from S23 [file:1]

### Key questions for this session

1. How should corruption spread on the dungeon tile graph differ from district-level spread in S28? Recommendation: corruption flows only through OPEN_CORRIDOR and ROOM_BUILT tiles, not through SOLID_ROCK, so the player shapes the spread pattern through excavation choices. [file:1]
2. Resurrection timing: should heroes always resurrect, or only when a specific room is built? Recommendation: `NecropolisShrine` room enables resurrection within its adjacency radius — gives the player a reason to build it near invasion paths. [file:1]
3. Restless undead faction: neutral enemies that fight both sides add chaos. How does FactionManager handle a three-way neutral? Recommendation: RESTLESS is hostile to both NECROMANCER and CRUSADERS but has no base — spawns from specific `RestlessSpawner` tiles if corruption in that cell exceeds threshold. [file:1]
4. Win condition inversion: the player wins by corrupting all shrine tiles, not by surviving. How does this interact with InvasionManager's wave timing? Recommendation: Crusaders accelerate if shrines are being corrupted — their patrol speed increases — creating natural tension. [file:1]

### Cursor prompts to generate (6 prompts)

1. Scaffold `wolf-necro` — run `wolf new wolf-necro --genre dungeon-keeper`; write `docs/MASTER_DOC.md` with Necromancer premise, corruption-spread model explanation, resurrection mechanic, three-faction roster, win condition (corrupt all 4 shrines before wave 3 ends), loss condition (Altar corruption reaches 0); copy S31 dungeon scene structure and scripts as the base; update `project.godot` autoloads to add `ContagionManager` and `NecromancyManager`; run `wolf doc generate` [file:1]

2. Wire `ContagionManager` as corruption spread — adapt tile graph: each OPEN or ROOM_BUILT tile has a `corruption_level` float 0.0–1.0; corruption spreads at 0.05/s to adjacent open tiles; Altar tile starts at corruption 1.0 (source), shrines start at 0.0 (targets); write `scripts/dungeon/CorruptionVisualizer.gd` — tile colour shifts from grey (low) to sickly green-purple (high) via shader parameter; Bone Forge and NecropolisShrine rooms boost local spread rate when built; crusader heroes slow corruption in cells they occupy; emit `shrine_corrupted(shrine_id)` when tile reaches 1.0 [file:1]

3. Write `scripts/dungeon/NecromancyManager.gd` — listens to `unit_died(unit_id)` filtered for CRUSADERS faction; checks if cell is within a `NecropolisShrine`'s adjacency radius; if yes: after 3s delay, spawn a `Skeleton.tscn` at that cell with 60% of the dead hero's max HP; also raises `RestlessUndead.tscn` outside shrine radius with 30% HP and RESTLESS faction tag; NecromancyManager tracks total resurrections for optional quest objective [file:1]

4. Write `resources/rooms/necro/` five necromancy room resources: `BoneForge` (adjacent Skeleton and BoneGolem gain `bone_hardened` GAS effect, costs 70 gold), `NecropolisShrine` (enables resurrection within 2-tile radius, costs 90 gold), `BlightVat` (increases corruption spread rate in adjacent tiles by 2×, costs 60 gold), `SoulCage` (stores up to 3 soul charges from killed heroes, releases as spectral bolts on next hero entering adjacency), `RestlessGrave` (spawns 1 RestlessUndead per 3 ticks if corruption ≥ 0.5, costs 40 gold); write updated `RoomManager.gd` for necro room set [file:1]

5. Write three new creature resources reusing `UnitBase.tscn`: `Skeleton.tres` (fast, weak, free upkeep because they are undead — no gold drain), `WraithKnight.tres` (phasing movement: can move through SOLID_ROCK tiles at half speed, high upkeep 4/s), `BoneGolem.tres` (slow, very high HP, splash attack, upkeep 5/s, cannot be resurrected — too large); write `resources/heroes/crusaders/` three new Crusader hero types: `Cleric` (suppresses corruption spread in adjacent tiles, priority target for NecromancyManager), `Knight` (same as Paladin but +20% speed when a shrine is being corrupted), `Exorcist` (destroys any raised Skeleton unit on contact, then becomes exhausted for 5s) [file:1]

6. Write 6 GdUnit4 tests: corruption spreads from Altar to adjacent open tiles each second, BlightVat doubles spread rate in adjacent tiles, hero death within NecropolisShrine radius triggers resurrection after 3s, Skeleton spawned via resurrection has 60% of hero max HP, Exorcist destroys Skeleton on contact and enters exhausted state, corrupting all four shrines before wave 3 ends emits `game_won`; run `wolf test --game wolf-necro` and confirm all pass [file:1]

### Deliverables

- [ ] `wolf-games/wolf-necro/` scaffolded via `wolf new` using S31 as structural base [file:1]
- [ ] `ContagionManager` wired as tile-graph corruption spread [file:1]
- [ ] `scripts/dungeon/CorruptionVisualizer.gd` with shader-driven colour gradient [file:1]
- [ ] `scripts/dungeon/NecromancyManager.gd` — resurrection + restless undead [file:1]
- [ ] `resources/rooms/necro/` five necromancy room resources [file:1]
- [ ] Three new creature resources (Skeleton, WraithKnight, BoneGolem) [file:1]
- [ ] Three new Crusader hero types (Cleric, Knight, Exorcist) [file:1]
- [ ] 6 GdUnit4 tests passing [file:1]
- [ ] Corruption spread visible on tiles during playtest [file:1]
- [ ] Resurrection loop observable: hero dies near shrine → Skeleton spawns 3s later [file:1]
- [ ] `wolf simbot run baseline --game wolf-necro` completes without crash [file:1]

### Unlocks

S36 showcase can use WOLF-NECRO's visual corruption shader as one of the more atmospheric demo thumbnails. S38 asset pass should prioritise the WraithKnight model since it is the most visually distinctive new unit. [file:1]

---

## Session S33 — WOLF-SURVIVAL: Hybrid Province + Night Defense

**Goal:** Build the framework's most architecturally ambitious MVP: a single game that runs two distinct loops on alternating phases — a daytime province-management turn where the player taxes, builds, and recruits, and a nighttime grid tower defense where the player must hold their last stronghold against a plague wave. The session's primary purpose is to prove that two previously separate sub-systems (S27 grand strategy and S22 grid TD) can be combined under one SignalBus event graph without hacks or hard-coded cross-system calls. [file:1]

**The game in one sentence:** Govern three plague-era provinces by day, then defend your capital's walls at night — survive four seasons of escalating winter waves to drive back the Pale Swarm. [file:1]

### Why this is architecturally significant

Every prior game session reuses individual systems. S33 is the first game that combines two **scene-level loops** — the strategy map and the combat arena — as alternating game states. This tests: [file:1]

- Whether `SignalBus` can cleanly mediate the handoff between `GrandCampaignController` (S27 pattern) and `GridArenaManager` (S22 pattern) without either knowing about the other [file:1]
- Whether province resource yields (from FlowEconomy strategic mode) can gate the availability of tower types in the night defense without coupling the two managers directly [file:1]
- Whether save/load correctly captures the interleaved state: province ownership, resource levels, AND current wave progress [file:1]

### Systems exercised

- `ProvinceMapManager.gd` from S12 and the province resource pattern from S27 for the day phase [file:1]
- `FlowEconomyManager` in dual mode: strategic yield accumulation in the day phase, upkeep drain during the night phase [file:1]
- `TimeTick` — day/night cycle as the primary game clock: one day tick = 60 seconds real time [file:1]
- `GridArena` + `TowerPlacementManager` + `WaveSpawner` from S22 for the night phase [file:1]
- `FactionManager` for three factions: PLAYER, PALE SWARM (night invaders), BORDER LORDS (rival province holders) [file:1]
- `TechTreeUI` for province-level upgrades that unlock tower types in the night defense [file:1]
- `ContagionManager` for a light spread mechanic: unchecked waves in a province increase its infection level, reducing yields next day [file:1]
- `SavePayload.cs` for cross-phase state persistence [file:1]
- `DialogueBridge` for season transition narrative and advisor alerts [file:1]

### Perplexity context to load

- Chunk 4a S22 deliverables: `GridArena.tscn`, `TowerPlacementManager.gd`, all three tower types, `WaveSpawner.gd` [file:1]
- Chunk 4b Part 1 S27 deliverables: `GrandCampaignController.gd`, `ProvinceData.tres` pattern, `DiplomacyPanel.gd` [file:1]
- Chunk 2 S13 `FlowEconomyManager.gd` dual-mode pattern notes [file:1]
- Chunk 2 S12 `ProvinceMapManager.gd` [file:1]

### Key questions for this session

1. Phase handoff: what is the exact SignalBus signal sequence for transitioning from day to night and back? Recommendation: `day_phase_ended(day_index)` → game state switches, GridArena loads → `wave_cleared` or `wave_failed` → `night_phase_ended(day_index, outcome)` → GrandCampaignController resumes, province consequences applied. [file:1]
2. How do province resources gate tower availability? Recommendation: each tower type has a `required_province_upgrade` field on `BuildingData.tres`; `TowerPlacementManager` checks FactionManager's current province tech level before allowing placement — no direct coupling between the two managers. [file:1]
3. How many provinces for MVP? Recommendation: three provinces (Capital, Farmlands, Iron Ridge) — one controlled by player, two contested. Keeping it smaller than S27 lets the session focus on the phase-handoff mechanic rather than map content. [file:1]
4. Seasons: four seasons of four days each = 16-day run. Wave difficulty scales with season. After Season 4 night, win condition evaluates. This gives a concrete endpoint without needing a special boss fight. [file:1]

### Cursor prompts to generate (7 prompts)

1. Scaffold `wolf-survival` — run `wolf new wolf-survival --genre grand-strategy`; write `docs/MASTER_DOC.md` with dual-loop architecture explanation, three-province map, four-season run structure, night wave schedule, win condition (survive Season 4 night with Capital intact), loss conditions (Capital HP = 0 during night OR Capital province lost during day); wire ALL relevant autoloads from both S22 and S27 patterns; run `wolf doc generate` [file:1]

2. Write `autoloads/PhaseManager.gd` — the central phase state machine: states `DAY_PHASE` and `NIGHT_PHASE`; on `day_phase_ended(day_index)` signal: saves province state via SavePayload, transitions to NIGHT_PHASE, loads `GridArena.tscn` with the correct wave resource for this day; on `night_phase_ended(day_index, outcome)` signal: saves night outcome, applies infection consequences to provinces via ContagionManager, transitions to DAY_PHASE, reloads province map; expose `current_day()` and `current_season()` getters [file:1]

3. Write `resources/provinces/survival/` three `ProvinceData.tres` resources: `Capital` (player-owned, food + authority yields, the arena that defends at night), `Farmlands` (contested, food focus, can be taken by Border Lords if left undefended two consecutive days), `IronRidge` (contested, metal focus, unlocks Cannon Tower type if player controls it); write day-phase UI: compact province overview panel with tax/invest actions, a tech tree button opening `TechTreeUI.gd`, and a prominent "Sound the Horn" button that ends the day phase [file:1]

4. Adapt `GridArena.tscn` from S22 for the survival night defense — key differences: wall tiles replace the simple path (player builds barricades in pre-wave 30s prep, then combat starts), wave enemy types imported from a `NightWaveData.tres` resource rather than the S22 generic WaveData; `NightWaveData` fields: `day_index`, `enemy_groups: Array[SpawnGroupData]`, `gold_reward`, `infection_penalty_on_fail`; write four-season wave escalation: Season 1 = small swarms, Season 2 = armoured units added, Season 3 = fast flankers added, Season 4 = boss horde [file:1]

5. Write `scripts/survival/ProvinceConsequenceResolver.gd` — processes night outcome: if `wave_cleared`: apply `gold_reward` to EconomyManager, reduce Capital infection by 0.1; if `wave_failed`: apply `infection_penalty_on_fail` to Capital via ContagionManager, reduce Capital's next-day yields by 20%; also resolves Border Lord aggression each day: if Farmlands or IronRidge has been uncontested for 2 consecutive days, Border Lords claim that province (remove from player control, cancel province yields); emit `province_lost(province_id)` on SignalBus [file:1]

6. Write `scripts/survival/TowerGatekeeper.gd` — sits between `TowerPlacementManager` and the province tech state; `can_place_tower(tower_type) -> bool` returns false if the required province upgrade is not unlocked; exposes a `get_locked_towers() -> Array[TowerType]` for the placement UI to grey-out locked options with a tooltip showing which province and upgrade unlocks them; write the three tech upgrades: `Logistics Reform` (unlocks Freeze Tower, requires any province upgrade tier 1), `Iron Smelting` (unlocks Cannon Tower, requires IronRidge controlled), `Watchtowers` (adds +1 pre-wave prep time, requires Capital upgrade tier 2) [file:1]

7. Write 7 GdUnit4 tests: `PhaseManager` transitions from DAY to NIGHT on signal, `PhaseManager` correctly restores province state after NIGHT phase, wave_cleared reduces Capital infection level, wave_failed applies infection penalty to next-day yields, `TowerGatekeeper` blocks Cannon Tower placement if IronRidge not controlled, Border Lords claim Farmlands after 2 uncontested days, surviving Season 4 night with Capital intact emits `game_won`; run `wolf test --game wolf-survival` and confirm all pass [file:1]

### Deliverables

- [ ] `wolf-games/wolf-survival/` scaffolded via `wolf new` [file:1]
- [ ] `autoloads/PhaseManager.gd` — day/night state machine [file:1]
- [ ] `resources/provinces/survival/` three province resources [file:1]
- [ ] Day-phase province overview UI panel [file:1]
- [ ] Adapted `GridArena.tscn` for survival night defense [file:1]
- [ ] `resources/waves/night/` `NightWaveData.tres` resources for all 16 days [file:1]
- [ ] `scripts/survival/ProvinceConsequenceResolver.gd` [file:1]
- [ ] `scripts/survival/TowerGatekeeper.gd` [file:1]
- [ ] 7 GdUnit4 tests passing [file:1]
- [ ] Day-to-night and night-to-day transitions work cleanly without scene leak [file:1]
- [ ] Province resource gating on tower types confirmed working [file:1]
- [ ] Save/load across phase transitions verified [file:1]
- [ ] `wolf simbot run baseline --game wolf-survival` completes [file:1]

### Unlocks

S36 showcase can present this as the flagship "what WOLF can do" demo because the dual-loop structure is the most visually impressive feature combination. S37 balance pass should run this game's SimBot profile first because the night-wave difficulty is the hardest to tune by hand. [file:1]

---

## Phase 2, S32–S33 — Session Status Tracker

| Session | Game | Genre | Depends on | Status |
|---------|------|-------|-----------|--------|
| S32 | WOLF-NECRO | Dungeon Keeper Variant | S31 | ⏳ |
| S33 | WOLF-SURVIVAL | Hybrid TD + Province | S22, S27 | ⏳ |

S32 requires S31 to be fully stable. S33 requires both S22 (grid TD) and S27 (province/grand strategy) and is the most dependency-heavy session in Phase 2 — schedule it only after both are accepted. [file:1]

---

## Position in Remaining Chunk 4

After this sub-chunk, the remaining Phase 2 sessions to document are: S34 `WOLF-NARRATIVE`, S35 `WOLF-ROGUE`, S36 `WOLF-SHOWCASE`, S37 Balance Pass, and S38 Asset Pass. [file:1]

*End of Chunk 4b Part 4. The next continuation should cover S34–S35.* [file:1]
