# WOLF Framework — Master Workplan
## Chunk 4b Part 5 of 5: Phase 2 Sessions S34–S35
### Demo Games Part 6: Narrative RPG MVP · Roguelite Dungeon MVP

**Document version:** 1.0 | **Continues from:** Chunk 4b Part 4 (S32–S33)
**Covers:** The next two Phase 2 game sessions.
**Prerequisites:** S20 complete for S34; S25 and S29 complete before S35.

---

## Phase 2 Positioning

This pair covers the two remaining genre families before the finishing sessions (S36 showcase, S37 balance, S38 assets). S34 is the framework's first narrative-primary game — there is no tactical combat; choices, dialogue, and relationship tracking are the gameplay. S35 is the framework's most cross-cutting hybrid: a roguelite dungeon-crawl that chains procedurally generated rooms (Gaea), autobattler combat resolution (S29 pattern), and card-based rewards (S25 pattern) into a single run structure. Both sessions stress-test corners of the framework that no prior demo has exercised as the primary mechanic. [file:1]

---

## Session S34 — WOLF-NARRATIVE: Narrative RPG MVP

**Goal:** Build a choice-driven narrative RPG with branching dialogue, tracked NPC relationships, a quest log, and meaningful consequence text — proving that WOLF's `DialogueBridge`, `Quest System`, `RelationshipManager`, and `Localisation` systems can support a game where the entire experience is conversation and consequence rather than unit combat. [file:1]

**The game in one sentence:** As a plague doctor newly arrived in the Ash Ward, navigate three encounters with key NPCs across a single story day, track evolving loyalties, and reach one of four endings determined entirely by your choices. [file:1]

### Why this session matters

Every prior game used `DialogueBridge` as decoration — wave-start flavour text, tutorial prompts, crisis advisors. This session puts it front and centre as the game. It also exercises `RelationshipManager` (extracted from Foul Ward's `RelationshipManager.gd`) as a meaningful gameplay layer for the first time in Phase 2. If WOLF can support a pure narrative game with the same architecture as its most combat-heavy games, it dramatically broadens the claim on the landing page. [file:1]

### Systems exercised

- `DialogueBridge` + Dialogue Manager addon from S11 — branching multi-node dialogue trees for three NPCs [file:1]
- `RelationshipManager.gd` from Foul Ward extraction (S09) — track trust, suspicion, gratitude, fear per NPC [file:1]
- `Quest System` addon from S11 — three optional side objectives that can be discovered or missed depending on choices [file:1]
- `Localisation` — all dialogue text, NPC names, location names, ending text through `en.po` (and optionally `pl.po`) [file:1]
- `SoundBridge` — ambient room sounds, NPC voice accent stings, consequence resolution music [file:1]
- `SavePayload.cs` — choice state, relationship scores, and quest completion flags persist for a potential second playthrough [file:1]
- `FactionManager` light usage — three factions (WARDENS, CLERGY, CITIZENS) with overall approval ratings that shift based on choices and feed into ending resolution [file:1]
- `TimeTick` — three time slots (Morning, Afternoon, Evening) serve as soft pacing gates [file:1]

### Design target

One location (the Ash Ward Inn as hub), three NPC characters with full dialogue trees (Warden Captain Aldric, Herbalist Sister Maren, innkeeper Tomas), three time slots, four possible endings, one day. No combat. No resource economy. The architecture matters more than the content volume — the session succeeds if a second writer could add a fourth NPC entirely through new dialogue files and a new quest resource, with zero code changes. [file:1]

### Perplexity context to load

- Chunk 2 S09 deliverables: `RelationshipManager.gd` extraction notes [file:1]
- Chunk 2 S11 deliverables: Dialogue Manager addon, Quest System addon [file:1]
- Chunk 2 S14 deliverables: `Localisation.gd`, `en.po` setup [file:1]
- MASTER_DOC §19 `RelationshipManager` (Foul Ward implementation for reference) [file:1]
- Session Summary §6 narrative RPG mention [file:1]

### Key questions for this session

1. How does `RelationshipManager` store per-NPC relationship dimensions? Recommendation: a `RelationshipData.tres` resource per NPC with float fields for each tracked dimension (trust, suspicion, gratitude, fear), updated by `RelationshipManager.modify_relationship(npc_id, dimension, delta)` calls from dialogue choice callbacks. [file:1]
2. How do dialogue choices call back into the game state? Recommendation: Dialogue Manager's `signal_fired` mechanism — each choice node fires a named signal that `NarrativeController.gd` listens to and maps to relationship and faction changes. [file:1]
3. How should endings be evaluated? Recommendation: `EndingResolver.gd` runs after the Evening time slot ends; reads all relationship scores and faction approval ratings; matches against four `EndingData.tres` condition resources; the first condition set that passes is the chosen ending. [file:1]
4. Should the quest system require manual check-in or auto-complete on condition? Recommendation: auto-complete on `quest_condition_met` signal so quest progress is invisible to the player until resolution — fits the embedded narrative tone. [file:1]

### Cursor prompts to generate (6 prompts)

1. Scaffold `wolf-narrative` — run `wolf new wolf-narrative --genre narrative`; write `docs/MASTER_DOC.md` with premise, three-NPC roster (Aldric, Maren, Tomas), time-slot pacing model, four ending conditions overview, no-combat design note; wire autoloads: SignalBus, RelationshipManager, FactionManager, Localisation, DialogueBridge, SoundBridge, TimeTickBridge, QuestManager; run `wolf doc generate` [file:1]

2. Write `resources/npcs/` three `NPCData.tres` resources and `autoloads/RelationshipManager.gd` — `NPCData` fields: npc_id, display_name_key, faction_tag, portrait_path, starting_relationship (Dictionary), available_time_slots; `RelationshipManager` holds a Dictionary of `{npc_id: RelationshipData}`, exposes `modify(npc_id, dimension, delta)`, `get_score(npc_id, dimension)`, and `get_dominant_dimension(npc_id)`; write `resources/relationships/aldric.tres`, `maren.tres`, `tomas.tres` with starting values [file:1]

3. Write dialogue trees for all three NPCs using Dialogue Manager's `.dialogue` format — Aldric tree: 4 nodes, 2 branch points, tracks trust and suspicion; choices that reveal plague spread information increase trust but decrease suspicion if Aldric is already hostile; Maren tree: 5 nodes, 3 branch points, tracks gratitude and fear; sharing medicine resources increases gratitude; Tomas tree: 3 nodes, 1 branch point, unlocks a hidden quest if both trust(Aldric) > 0.6 AND gratitude(Maren) > 0.4; write `scripts/narrative/NarrativeController.gd` to handle all `signal_fired` callbacks [file:1]

4. Write three `QuestData.tres` resources and `scenes/QuestLogPanel.tscn` — quests: `HiddenLetter` (discover Tomas' secret, requires Aldric trust > 0.6 AND talking to Tomas in Afternoon; reward: special ending unlock flag), `MedicineShortage` (help Maren source medicine, requires two consecutive dialogue choices supporting her; auto-completes silently, adds gratitude delta), `WatcherInShadows` (optional — if suspicion(Aldric) > 0.7 the player is followed; revealed in Evening encounter); Quest Log Panel shows active/completed quests; quests that were missed are never shown [file:1]

5. Write `scripts/narrative/EndingResolver.gd` and `resources/endings/` four `EndingData.tres` resources — ending conditions: `TRUSTED HEALER` (trust(Aldric) > 0.7 AND gratitude(Maren) > 0.6 AND HiddenLetter complete), `WARDEN'S TOOL` (suspicion(Aldric) < 0.3 AND fear(Maren) > 0.5 AND CITIZENS approval < 40), `PEOPLE'S DOCTOR` (CITIZENS approval > 60 AND trust(Aldric) < 0.5 AND HiddenLetter NOT complete), `EXILED OUTSIDER` (default fallback); each ending has a `title_key`, `body_text_key`, `ending_music_key`; `EndingResolver.evaluate()` called on Evening time slot end [file:1]

6. Write 5 GdUnit4 tests: `RelationshipManager.modify` correctly clamps values between -1.0 and 1.0, `NarrativeController` correctly maps Aldric dialogue signal to trust delta, `HiddenLetter` quest auto-completes when conditions are met, `EndingResolver` selects `TRUSTED HEALER` given correct relationship scores, choosing to withhold medicine from Maren increases fear and decreases gratitude; run `wolf test --game wolf-narrative` and confirm all pass [file:1]

### Deliverables

- [ ] `wolf-games/wolf-narrative/` scaffolded via `wolf new` [file:1]
- [ ] `autoloads/RelationshipManager.gd` [file:1]
- [ ] `resources/npcs/` three NPC resources with starting relationship values [file:1]
- [ ] Dialogue trees for Aldric, Maren, and Tomas [file:1]
- [ ] `scripts/narrative/NarrativeController.gd` [file:1]
- [ ] Three `QuestData.tres` resources + `scenes/QuestLogPanel.tscn` [file:1]
- [ ] `scripts/narrative/EndingResolver.gd` + four `EndingData.tres` resources [file:1]
- [ ] 5 GdUnit4 tests passing [file:1]
- [ ] All four endings reachable via distinct choice paths (verified manually) [file:1]
- [ ] Dialogue trees complete without dead-end nodes [file:1]
- [ ] All text runs through Localisation (no hardcoded strings in scripts) [file:1]

### Unlocks

S39 docs work can reference WOLF-NARRATIVE as the canonical example of `RelationshipManager` and `DialogueBridge` working together. The `EndingResolver` pattern (condition resources + fallback) is reusable in any WOLF game that needs a non-combat win/loss evaluation. [file:1]

---

## Session S35 — WOLF-ROGUE: Roguelite Dungeon MVP

**Goal:** Build a roguelite dungeon-crawl that chains three framework sub-systems into a single run structure: procedurally generated rooms from Gaea, autobattler combat resolution borrowed from S29, and card-based rewards borrowed from S25. The session proves that WOLF's modular architecture allows meaningful system combination in a new genre without requiring any of the sub-systems to be rewritten, only bridged. [file:1]

**The game in one sentence:** Descend through five procedurally generated dungeon floors, fight each room's occupants in a simplified autobattle, and collect card rewards that permanently enhance your warband's stats for the rest of the run. [file:1]

### Architecture goal

This session is explicitly about proving **composability** — the hardest claim for any game framework to make. The three borrowed systems must be connected by bridge scripts only, with no modifications to the source systems: [file:1]

- Gaea generates room layouts and stores them in `RoomLayoutData.tres` resources [file:1]
- `RoomEncounterBridge.gd` reads a room layout, spawns enemy units matching the room's encounter profile, and launches the S29 autobattle loop [file:1]
- `CardRewardBridge.gd` reads the autobattle result, selects reward cards from the S25 card pool, and applies stat-boosting card effects to warband units via GAS [file:1]

No module touches another's internals. [file:1]

### Systems exercised

- `Gaea` procedural generation addon from S11 — 5-floor dungeon with varied room types [file:1]
- `BoardManager.gd` + `AutobattlerUnit.gd` from S14/S29 — combat resolution [file:1]
- `Card Framework` from S10/S25 — reward cards as stat modifiers [file:1]
- `GAS` AttributeSet — card effects applied as persistent (not timed) gameplay attribute modifiers on warband units [file:1]
- `RunState.gd` from S25 — run persistence: warband, cards collected, floor index [file:1]
- `SoundBridge` for room entry, combat start, card choice, floor descent [file:1]
- `DialogueBridge` for dungeon intro, floor transition flavour, and boss room preamble [file:1]
- `Localisation` for room names, card names, floor labels [file:1]

### Perplexity context to load

- Chunk 4a S25 deliverables: `RunState.gd`, card resources, `CombatManager.gd` pattern [file:1]
- Chunk 4b Part 2 S29 deliverables: `BoardManager.gd`, `AutobattlerUnit.gd`, `ShopManager.gd`, `AutoRoundController.gd` [file:1]
- Chunk 2 S11 `Gaea` addon installation and procedural generation API [file:1]
- Chunk 2 S10 Card Framework API — specifically how card resources apply effects [file:1]

### Key questions for this session

1. How does Gaea output room layouts in a format WOLF can consume? Recommendation: configure Gaea to output tile maps and write a `GaeaRoomParser.gd` that converts a generated tile map into a `RoomLayoutData.tres` — grid dimensions, open cell list, enemy spawn cells, reward chest cell — so the rest of the system never touches Gaea directly. [file:1]
2. How does autobattle work without the full shop/bench/round UI from S29? Recommendation: for roguelite rooms, skip the shop phase — the player's warband is already configured from prior floors; the room just launches the combat phase directly. The player watches the battle resolve and clicks "continue" when done. [file:1]
3. Card rewards as stat modifiers: how does a card become a GAS attribute change on a specific unit? Recommendation: `CardRewardBridge.gd` reads the card's `effect_payload` field and calls `UnitAttributesBridge.apply_permanent_modifier(unit_id, attribute, delta)` — a new method added to `UnitAttributesBridge.gd` specifically for run-persistent modifiers. [file:1]
4. What is the run structure? Recommendation: 5 floors, 3 rooms per floor, one room type per floor randomly: Combat Room, Elite Room (harder enemies + better reward), Rest Room (heal warband 20% HP), Merchant Room (spend run gold for a guaranteed card choice), Boss Room (last room of floor 5). [file:1]

### Cursor prompts to generate (7 prompts)

1. Scaffold `wolf-rogue` — run `wolf new wolf-rogue --genre card-roguelite`; write `docs/MASTER_DOC.md` with run structure (5 floors × 3 rooms), three core modules and their bridge scripts, warband composition (3 starting units: one from each of Frontline/Ranged/Support roles), no shop phase explanation, win condition = defeat Floor 5 Boss, loss = entire warband wiped; wire autoloads: SignalBus, RunState, Localisation, DialogueBridge, SoundBridge, BoardManager; run `wolf doc generate` [file:1]

2. Write `scripts/generation/GaeaRoomParser.gd` and the Gaea configuration — configure Gaea with a dungeon tileset (wall/floor/door cells), 5-floor generation seed passed from `RunState.run_seed`; after generation `GaeaRoomParser.parse_floor(floor_index) -> Array[RoomLayoutData]` returns 3 `RoomLayoutData.tres` instances per floor with: room_type (COMBAT/ELITE/REST/MERCHANT/BOSS), open_cells, enemy_spawn_cells (count varies by room type and floor index), reward_chest_cell; write `resources/room_layouts/` with one static hand-authored layout per room type as a fallback for testing without Gaea active [file:1]

3. Write `scripts/rogue/RoomEncounterBridge.gd` — on room entry: reads `RoomLayoutData.room_type` and `floor_index`; selects enemy units from `resources/units/auto/` using floor-scaled difficulty profile (floor 1: only Ratling/SkeletonGuard, floor 5: full pool with 2-star units); spawns enemies into BoardManager's top half via `BoardManager.place_unit(unit, slot)`; places player warband into bottom half from RunState; calls `AutoRoundController.start_combat()`; listens for `combat_resolved(outcome)` signal; on victory: emits `room_cleared(room_type)`, triggers appropriate reward flow [file:1]

4. Write `scripts/rogue/CardRewardBridge.gd` — on `room_cleared(COMBAT or ELITE)`: draws 3 cards from the run reward pool weighted by floor index (higher floors weight rarer cards heavier); displays `RewardScreen.tscn` from S25 (reused directly); on card selected: reads card's `effect_payload` Dictionary (`{attribute: String, delta: float, target: String}`); calls `UnitAttributesBridge.apply_permanent_modifier(unit_id, attribute, delta)` for the specified target unit (FRONTLINE, RANGED, SUPPORT, or ALL); adds card to RunState for bookkeeping; write `UnitAttributesBridge.apply_permanent_modifier()` method if not already present [file:1]

5. Write `scenes/RogueHUD.tscn` and `scripts/rogue/RogueRunController.gd` — HUD shows: floor index, room index, warband HP bars (live during and between rooms), cards collected count, run gold; `RogueRunController` owns the floor/room progression loop: on `room_cleared` advance room index, on floor complete advance floor index and trigger `DialogueBridge` floor-transition line, on all floors complete trigger Boss Room; on `warband_wiped` emit `run_lost`; write `scenes/FloorMap.tscn` — simple 3-node linear room map per floor, unlocking left to right as rooms clear [file:1]

6. Write Boss Room content — `resources/bosses/floor5_boss.tres` extending `AutobattlerUnit` with 3-star stats, two passive abilities: `PlagueSurge` (gains +10% attack speed each time a warband unit dies) and `BoneWall` (spawns one Skeleton minion at 50% HP); write `scripts/rogue/BossEncounterBridge.gd` extending `RoomEncounterBridge` with boss-specific spawning and phase-2 trigger at 50% HP; on boss death: emit `run_won`, display run summary (floors cleared, cards collected, warband survivors) [file:1]

7. Write 6 GdUnit4 tests: `GaeaRoomParser` returns correct number of rooms per floor, enemy count scales with floor index in `RoomEncounterBridge`, `CardRewardBridge.apply_permanent_modifier` correctly increases a unit's HP attribute, Rest Room heals warband 20% without triggering combat, `RogueRunController` advances floor index on third room clear, warband wipe emits `run_lost`; run `wolf test --game wolf-rogue` and confirm all pass [file:1]

### Deliverables

- [ ] `wolf-games/wolf-rogue/` scaffolded via `wolf new` [file:1]
- [ ] `scripts/generation/GaeaRoomParser.gd` + Gaea configuration [file:1]
- [ ] `resources/room_layouts/` static fallback layouts for all room types [file:1]
- [ ] `scripts/rogue/RoomEncounterBridge.gd` [file:1]
- [ ] `scripts/rogue/CardRewardBridge.gd` [file:1]
- [ ] `UnitAttributesBridge.apply_permanent_modifier()` method added to framework [file:1]
- [ ] `scenes/RogueHUD.tscn` + `scripts/rogue/RogueRunController.gd` [file:1]
- [ ] `scenes/FloorMap.tscn` — 3-node room progression per floor [file:1]
- [ ] `resources/bosses/floor5_boss.tres` + `scripts/rogue/BossEncounterBridge.gd` [file:1]
- [ ] 6 GdUnit4 tests passing [file:1]
- [ ] Full 5-floor run completable end-to-end [file:1]
- [ ] No modifications made to Gaea, Card Framework, or BoardManager internals (verified) [file:1]
- [ ] `wolf simbot run baseline --game wolf-rogue` completes [file:1]

### Unlocks

`apply_permanent_modifier()` added to `UnitAttributesBridge` is a framework-level addition that benefits any future WOLF game needing permanent unit upgrades. S36 showcase can feature WOLF-ROGUE as the "composability proof" demo. S39 docs site can publish this session's bridge pattern as the canonical tutorial for combining WOLF sub-systems. [file:1]

---

## Phase 2, S34–S35 — Session Status Tracker

| Session | Game | Genre | Depends on | Status |
|---------|------|-------|-----------|--------|
| S34 | WOLF-NARRATIVE | Narrative RPG | S20 | ⏳ |
| S35 | WOLF-ROGUE | Roguelite Dungeon | S25, S29 | ⏳ |

S34 depends only on Phase 1 and can run in parallel with any other Phase 2 session. S35 requires both S25 (card system) and S29 (autobattler base) and should be scheduled after both are confirmed stable. [file:1]

---

## Complete Phase 2 Session Status — Running Total

| # | Session | Status |
|---|---------|--------|
| S21 | WOLF-TD | ⏳ |
| S22 | WOLF-TD-GRID | ⏳ |
| S23 | WOLF-RTS | ⏳ |
| S24 | WOLF-FLOW-RTS | ⏳ |
| S25 | WOLF-CARD | ⏳ |
| S26 | WOLF-DECKBUILDER | ⏳ |
| S27 | WOLF-GRAND | ⏳ |
| S28 | WOLF-CRISIS | ⏳ |
| S29 | WOLF-AUTO | ⏳ |
| S30 | WOLF-SYNERGY | ⏳ |
| S31 | WOLF-DUNGEON | ⏳ |
| S32 | WOLF-NECRO | ⏳ |
| S33 | WOLF-SURVIVAL | ⏳ |
| S34 | WOLF-NARRATIVE | ⏳ |
| S35 | WOLF-ROGUE | ⏳ |
| S36 | WOLF-SHOWCASE | — (Chunk 4c) |
| S37 | Balance Pass | — (Chunk 4c) |
| S38 | Asset Pass | — (Chunk 4c) |

*End of Chunk 4b. All 15 playable game sessions are now fully documented.
The next and final Phase 2 document (Chunk 4c) covers S36 WOLF-SHOWCASE,
S37 Balance Pass, and S38 Asset Pass — the three finishing sessions before
Phase 3 (docs, launch, community) begins.* [file:1]
