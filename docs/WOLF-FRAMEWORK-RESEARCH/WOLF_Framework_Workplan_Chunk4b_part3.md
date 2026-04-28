# WOLF Framework — Master Workplan
## Chunk 4b Part 3 of 5: Phase 2 Sessions S30–S31
### Demo Games Part 4: Autobattler Extended · Dungeon Keeper MVP

**Document version:** 1.0 | **Continues from:** Chunk 4b Part 2 (S28–S29)
**Covers:** The next two Phase 2 game sessions.
**Prerequisites:** All Phase 1 sessions complete; S20 integration test passed; S29 complete before S30 begins.

---

## Phase 2 Positioning

This pair completes the autobattler genre family and opens the underground/keeper genre family. S30 extends S29's foundation with the synergy layer that distinguishes a flat autobattler from a meaningful draft game, while S31 introduces the framework's third major AI model (Fluid HTN creature planning) in a genre with genuinely novel structural demands: the player builds down rather than outward, and the threats are heroes invading rather than waves from the edge. [file:1]

---

## Session S30 — WOLF-SYNERGY: Autobattler Extended MVP

**Goal:** Extend `wolf-auto`'s architecture with unit trait synergies, a persistent campaign of six rounds across two difficulties, a reroll shop economy, and a 2-star/3-star upgrade ladder — proving that the autobattler foundation can support the depth layer that makes the genre commercially viable, without requiring a rewrite of the core round and board systems. [file:1]

**The game in one sentence:** Draft a warband across a 6-round campaign with full synergy bonuses, 3-star upgrades, and a reroll economy that rewards risk and composure in equal measure. [file:1]

### Systems exercised

- `BoardManager.gd` and `AutobattlerUnit.gd` from S29 — extended, not replaced [file:1]
- `GAS` AttributeSet for synergy bonuses as transient gameplay effects [file:1]
- `EconomyManager` for gold interest mechanic (earn 1 gold interest per 10 banked) [file:1]
- `Beehave` for one special unit type whose combat behaviour branches on synergy state [file:1]
- `SoundBridge` for synergy activation, 3-star pop, and interest-earned feedback [file:1]
- `Localisation` for synergy names, tier labels, and trait tooltips [file:1]
- `SavePayload.cs` — round-to-round campaign persistence with gold and HP carried over [file:1]

### Key architectural difference from S29

S29 proves the loop. S30 proves that the loop can support a meaningful decision graph. The session is successful only if the synergy system is data-driven — each trait is a `TraitData.tres` resource that specifies unit tags, threshold counts, and GAS effects — so that adding new synergies later requires zero code changes. [file:1]

### Perplexity context to load

- Chunk 4b Part 2 S29 deliverables in full: `BoardManager.gd`, `AutobattlerUnit.gd`, `ShopManager.gd`, all eight unit resources, `AutoRoundController.gd` [file:1]
- `framework/scripts/components/GAS/` from S10 — Gameplay Effects API [file:1]
- `framework/templates/resources/` pattern from S09 to design `TraitData.tres` consistently [file:1]

### Key questions for this session

1. How should synergy bonuses activate? Recommendation: `SynergyManager.gd` scans deployed units' tags each time a unit is placed or removed from board, checks all `TraitData.tres` thresholds, and applies/removes GAS Effects on all tagged units accordingly. [file:1]
2. How does the 3-star upgrade ladder interact with the merge rule from S29? Recommendation: 3-of-a-kind 1-star → 1 copy of 2-star; 3-of-a-kind 2-star → 1 copy of 3-star; 3-star units apply their synergy tag at double weight. [file:1]
3. Gold interest mechanic: does interest apply at the start of every prep phase? Recommendation: yes, capped at 5 gold interest max (requires 50 gold banked), adds tension between spending and saving. [file:1]
4. Should the six-round campaign be an extension of S29's authored formations, or do we author a new difficulty-2 formation set? Recommendation: new formation set with synergy-aware compositions so the enemy can demonstrate what synergies look like in practice. [file:1]

### Cursor prompts to generate (6 prompts)

1. Scaffold `wolf-synergy` — run `wolf new wolf-synergy --genre autobattler`; write `docs/MASTER_DOC.md` with premise (same plague-warband setting as S29, extended run), campaign structure (6 rounds with carry-over HP and gold), synergy system overview, interest economy rule; wire autoloads extending S29's set with `SynergyManager`; copy S29's unit resources into this project's `resources/units/auto/` as a baseline, then flag the three units that will get synergy tags in this session [file:1]

2. Write `resources/traits/` four `TraitData.tres` synergy resources and `autoloads/SynergyManager.gd` — traits: `Undead` (3-unit threshold: all Undead gain +15% HP; 5-unit threshold: also regenerate 2 HP/s), `Plague Bearer` (2-unit: enemies start combat with 1 poison stack; 4-unit: 3 stacks), `Armoured` (2-unit: +20 flat armour for all Armoured; 4-unit: also reflect 10% damage), `Zealot` (2-unit: ChantPriest heals +50%; if Zealot count ≥ 3, ChantPriest gains shield equal to 30% max HP); `SynergyManager` scans board state on every deploy/remove event, applies GAS Effects to tagged units, and exposes `get_active_synergies() -> Array[SynergyState]` for the UI [file:1]

3. Write `scenes/SynergyBar.tscn` and `scripts/auto/SynergyBarController.gd` — HUD strip showing all four traits with current unit count vs. threshold count, icon colour for inactive/partial/active state, tooltip on hover showing threshold breakdown; updates on every `board_state_changed` signal; write `scenes/TraitTooltip.tscn` with trait name, tier thresholds, and bonus descriptions sourced from `TraitData.tres` Localisation keys [file:1]

4. Extend `ShopManager.gd` from S29 into `wolf-synergy` — add gold interest: at prep-phase start compute `floor(banked_gold / 10)` capped at 5, add to gold, emit `interest_earned(amount)` to SoundBridge; add reroll cost starting at 2 gold then +1 per reroll per round (resets each round); update eight unit pool with trait tags: `PlagueGuard` → Undead + Armoured, `BoneArcher` → Undead, `CarrionKnight` → Undead + Armoured, `ChantPriest` → Zealot, `PoxOracle` → Plague Bearer, `LeechHound` → Plague Bearer, `Ratling` → (no trait), `MortarAdept` → (no trait); update shop pool weighting so higher-cost units are rarer in early rounds [file:1]

5. Write `resources/enemy_rounds/synergy/` six synergy-aware enemy formation resources — formations composed with clear synergy combos so the player can read what the enemy is doing and learn by observation; round 6 boss board uses a 3-star `CarrionKnight` as the anchor; write `scripts/auto/CampaignRoundManager.gd` extending `AutoRoundController` with carry-over: HP and gold persist between rounds, each round starts with 3 base gold + last round's interest; save round state via `SavePayload` pattern [file:1]

6. Write 6 GdUnit4 tests: SynergyManager activates Undead 3-threshold effect when three Undead units are on board, removing one Undead unit below threshold removes GAS effect, 3-star merge requires 9 copies of 1-star, interest formula gives correct output at 10/20/50 gold, reroll cost increments per use per round, clearing round 6 with active synergy emits `game_won`; run `wolf test --game wolf-synergy` and confirm all pass [file:1]

### Deliverables

- [ ] `wolf-games/wolf-synergy/` scaffolded via `wolf new` [file:1]
- [ ] `resources/traits/` four `TraitData.tres` synergy resources [file:1]
- [ ] `autoloads/SynergyManager.gd` [file:1]
- [ ] `scenes/SynergyBar.tscn` + `scripts/auto/SynergyBarController.gd` [file:1]
- [ ] `scenes/TraitTooltip.tscn` [file:1]
- [ ] Extended `ShopManager.gd` with interest and reroll cost [file:1]
- [ ] All eight units updated with trait tags [file:1]
- [ ] `resources/enemy_rounds/synergy/` six synergy-aware enemy formations [file:1]
- [ ] `scripts/auto/CampaignRoundManager.gd` with carry-over persistence [file:1]
- [ ] 6 GdUnit4 tests passing [file:1]
- [ ] Synergy activations visually legible at a glance during board phase [file:1]
- [ ] 3-star unit demonstrably stronger and visually distinct from 2-star [file:1]
- [ ] `wolf simbot run baseline --game wolf-synergy` completes and reports synergy frequency stats [file:1]

### Unlocks

S37 balance pass is most valuable for this game because synergy GAS effects are the hardest values to tune by hand; the optimiser's win-rate equalisation objective is directly applicable here. [file:1]

---

## Session S31 — WOLF-DUNGEON: Dungeon Keeper MVP

**Goal:** Build a Dungeon Keeper–style underground management game where the player excavates a cave network, places rooms and traps, assigns creature workers, and defends against hero invasion waves. The MVP should prove that WOLF can host a genre with inverted agency: the player is the defender building into a fixed map, and the enemies (heroes) follow predetermined patrol routes inward rather than spawning from edges. [file:1]

**The game in one sentence:** Dig out a plague catacombs, place creature lairs and trap rooms, assign ghoul workers using HTN planning, and repel three hero invasion squads before they reach your Corruption Heart. [file:1]

### Systems exercised

- `Fluid HTN` for creature worker AI: goal-directed digging, hauling, room construction, and creature feeding [file:1]
- `Beehave` for creature combat AI once invaders are detected (patrol → intercept → attack) [file:1]
- `GAS` for creature HP, attack, and room buff effects (e.g., Torture Chamber gives nearby creatures +10% attack) [file:1]
- `FlowEconomyManager` for gold vein income and creature upkeep drain [file:1]
- `ContagionManager` optionally for plague-aura room effects that weaken heroes over time [file:1]
- `UnitBase.tscn` + `UnitData.tres` for both creatures and hero invaders [file:1]
- `HexGrid.gd` for the underground tile map in hex-offset layout [file:1]
- `FogOfWarGPU` for cave darkness as a literal FOW layer (unseen = black) [file:1]
- `SoundBridge` for digging, room completion, creature combat, and heart-under-attack alerts [file:1]
- `SavePayload.cs` for scenario persistence between sessions [file:1]

### Design target

This is not a full Dungeon Keeper 2 re-implementation. It is a **tile-excavation + creature-management MVP** on a 16×16 hex map with three creature types, five room types, two trap types, and three hero invasion waves. The architecture goals are: prove that Fluid HTN creature AI can plan multi-step construction tasks without per-task hand-scripting, and prove that an "inverted agency" game (player defends, enemies advance inward) fits naturally into WOLF's SignalBus and FactionManager structures. [file:1]

### Perplexity context to load

- Chunk 2 S11 deliverables: `fluid-htn` addon installation and `ExampleHTNDomain.gd` [file:1]
- Chunk 2 S12 deliverables: `HexGrid.gd` autoload, `FogOfWarGPU.gd` [file:1]
- Chunk 2 S13 deliverables: `FlowEconomyManager.gd`, `ContagionManager.gd` [file:1]
- Chunk 4a S21 deliverables: `WaveSpawner.gd`, `UnitBase.tscn`, enemy `UnitData.tres` pattern [file:1]
- Session Summary §6 dungeon-keeper genre: procedural voxel, HTN AI, flow economy [file:1]

### Key questions for this session

1. Excavation model: should the player click tiles to queue dig orders and creatures auto-assign, or is there explicit creature-to-tile assignment? Recommendation: click-to-queue, HTN auto-assigns nearest idle creature — this is the DK feel and the HTN's natural domain. [file:1]
2. How should room placement work? Recommendation: a 2×2 or 3×3 hex cluster is claimed by clicking a placed Room Blueprint tile; the creature HTN task `ConstructRoom` picks up the blueprint and builds it over several seconds. [file:1]
3. How does hero invasion work mechanically? Recommendation: heroes enter at a fixed surface entrance tile, pathfind through revealed corridors using A* on the HexGrid, fight any creatures they encounter, and aim for the Corruption Heart tile. Three waves, each tougher and from a different entrance. [file:1]
4. Creature upkeep: do creatures consume gold continuously? Recommendation: yes, each creature type has a `upkeep_per_tick` value drawn from FlowEconomy's gold flow. If gold flow hits zero, creature morale drops and they become idle, simulating classic DK starvation. [file:1]

### Cursor prompts to generate (7 prompts)

1. Scaffold `wolf-dungeon` — run `wolf new wolf-dungeon --genre dungeon-keeper`; write `docs/MASTER_DOC.md` with premise, 16×16 hex tile map, five room types, three creature types, three hero wave schedule, win condition = survive all three waves with Corruption Heart intact, loss = Heart HP reaches 0; wire autoloads: SignalBus, FlowEconomyManager, ContagionManager, FactionManager, HexGrid, FogOfWarGPU, Localisation, DialogueBridge, SoundBridge; run `wolf doc generate` [file:1]

2. Write `scenes/DungeonMap.tscn` and `scripts/dungeon/DungeonTileManager.gd` — 16×16 HexGrid where every tile starts as `SOLID_ROCK` with FOW fully dark; tile states: SOLID_ROCK, QUEUED_DIG, BEING_DUG, OPEN_CORRIDOR, ROOM_CLAIMED, ROOM_BUILT; `DungeonTileManager` exposes `queue_dig(cell)`, `get_tile_state(cell)`, and `get_open_adjacency(cell)`; surface entrance tiles are pre-defined and visible from the start; the Corruption Heart tile is placed at map centre and always open; FogOfWarGPU reveals tiles as they are dug open [file:1]

3. Write `resources/rooms/` five room resources and `scripts/dungeon/RoomManager.gd` — rooms: `GhoulLair` (spawns Ghoul worker creature over time, costs 60 gold), `TortureCell` (nearby creatures +10% attack via GAS effect, costs 80 gold), `AlchemyPit` (produces medicine resource, costs 100 gold), `TrapCorridor` (installs spike trap, damages heroes passing through), `GoldVein` (passive +3 gold/s to FlowEconomy, must be dug adjacent to a gold-vein tile); rooms are placed by clicking a valid 2×2 hex cluster; creatures auto-construct over ~5 seconds when a blueprint is detected by HTN [file:1]

4. Write `scripts/ai/CreatureHTN.gd` — Fluid HTN domain for creature workers; world state properties: `nearest_dig_target`, `nearest_blueprint`, `nearest_food_source`, `gold_flow_positive`, `creature_morale`; primitive tasks: `DIG_TILE` (move to queued tile, execute dig action, update tile state), `CONSTRUCT_ROOM` (move to blueprint tile, build for N seconds, emit room_built), `HAUL_GOLD` (move to gold pile, deliver to heart), `FEED_SELF` (move to lair, consume food); compound task `IdleWork` selects highest-priority unmet need; if `gold_flow_positive = false` creature executes `PanicIdle` (wander randomly, no work) [file:1]

5. Write `resources/creatures/` three `UnitData.tres` creature resources and scenes: `Ghoul` (cheap, fast digger, weak fighter, upkeep 1/s), `PlagueKnight` (slow, strong fighter, cannot dig, upkeep 3/s), `SkeletonArcher` (ranged, moderate digger, upkeep 2/s); creature combat uses Beehave: `PatrolNearHeart` → detect hero in range → `InterceptAndAttack`; write `resources/heroes/` three `UnitData.tres` hero invader types: `Paladin` (high HP, slow, strong), `Rogue` (fast, low HP, bypasses traps), `Arcanist` (ranged, disables one room temporarily); heroes pathfind using HexGrid A* through open corridors [file:1]

6. Write `scripts/dungeon/InvasionManager.gd` and `resources/waves/` three hero invasion wave resources — Wave 1: 2 Paladins + 1 Rogue, enter Turn 5 (2 minutes in), entrance North; Wave 2: 2 Rogues + 1 Arcanist, enter Turn 8, entrance East; Wave 3: 2 Paladins + 2 Arcanists + 1 Rogue (boss wave), enter Turn 11, entrance South; each wave spawns heroes at the entrance tile and triggers `invasion_started(wave_index)` on SignalBus; `InvasionManager` tracks hero HP, checks Heart HP on hero arrival, emits `game_lost` or `wave_repelled(wave_index)` [file:1]

7. Write 7 GdUnit4 tests: queuing a dig assigns correct tile state, HTN selects DIG task over CONSTRUCT when dig queue is non-empty, GhoulLair spawns creature after construction completes, TortureCell GAS effect applies to adjacent creature, gold flow hitting zero sets all creature morale to panic, hero A* path resolves through open corridors only (not through SOLID_ROCK), all three waves clear with full creature army results in `game_won`; run `wolf test --game wolf-dungeon` and confirm all pass [file:1]

### Deliverables

- [ ] `wolf-games/wolf-dungeon/` scaffolded via `wolf new` [file:1]
- [ ] `scenes/DungeonMap.tscn` + `scripts/dungeon/DungeonTileManager.gd` [file:1]
- [ ] `resources/rooms/` five room resources + `scripts/dungeon/RoomManager.gd` [file:1]
- [ ] `scripts/ai/CreatureHTN.gd` — Fluid HTN domain with four primitive tasks [file:1]
- [ ] `resources/creatures/` three creature unit resources and scenes [file:1]
- [ ] `resources/heroes/` three hero invader unit resources [file:1]
- [ ] `scripts/dungeon/InvasionManager.gd` + `resources/waves/` three wave resources [file:1]
- [ ] 7 GdUnit4 tests passing [file:1]
- [ ] Dig queue → creature auto-assigns → corridor opens — verified working [file:1]
- [ ] Hero pathfinding through open corridors confirmed via test and visual playtest [file:1]
- [ ] Creature panic on gold-flow-zero visually noticeable [file:1]
- [ ] All three invasion waves fire at correct times and from correct entrances [file:1]
- [ ] `wolf simbot run baseline --game wolf-dungeon` completes without crash [file:1]

### Unlocks

S32 (WOLF-NECRO) directly extends this dungeon architecture with the Contagion-as-corruption mechanic and an undead faction skin, so S31 must be fully stable before S32 begins. [file:1]

---

## Phase 2, S30–S31 — Session Status Tracker

| Session | Game | Genre | Depends on | Status |
|---------|------|-------|-----------|--------|
| S30 | WOLF-SYNERGY | Autobattler Extended | S29 | ⏳ |
| S31 | WOLF-DUNGEON | Dungeon Keeper MVP | S20 | ⏳ |

S30 requires S29 to be complete. S31 depends only on Phase 1 and can run in parallel with S30 if two sessions are available. [file:1]

---

## Position in Remaining Chunk 4

After this sub-chunk, the remaining Phase 2 sessions still to document are: S32 `WOLF-NECRO`, S33 `WOLF-SURVIVAL`, S34 `WOLF-NARRATIVE`, S35 `WOLF-ROGUE`, S36 `WOLF-SHOWCASE`, S37 Balance Pass, and S38 Asset Pass. [file:1]

*End of Chunk 4b Part 3. The next continuation should cover S32–S33.* [file:1]
