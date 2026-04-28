# WOLF Framework — Master Workplan
## Chunk 4b Part 2 of 5: Phase 2 Sessions S28–S29
### Demo Games Part 3: Crisis Management MVP · Autobattler MVP

**Document version:** 1.0 | **Continues from:** Chunk 4b Part 1 (S26–S27)
**Covers:** The next two Phase 2 game sessions.
**Prerequisites:** All Phase 1 sessions complete; S20 integration test passed; previous Chunk 4 sub-documents accepted.

---

## Phase 2 Positioning

This pair pushes the framework into two more distinct shapes: **systemic crisis simulation** and **round-based automated combat**. Together they test whether WOLF can support games where the player's main verbs are not direct aiming or unit micro, but rather allocation, positioning, and timing. [file:1]

S28 leans into strategic pressure, event cadence, and cascading failure management, while S29 validates the board/bench/shop loop needed for all later autobattler-style and hybrid draft-combat games. [file:1]

---

## Session S28 — WOLF-CRISIS: Survival Management MVP

**Goal:** Build a crisis management strategy game where the player governs a plague-stricken settlement through a fixed timeline of escalating emergencies — food shortages, contagion spikes, unrest, and faction pressure — and must survive to the final tick. The MVP should prove that WOLF's Flow Economy, Contagion simulation, TimeTick, FactionManager, and event/dialogue systems can drive a high-pressure management loop without requiring direct tactical combat. [file:1]

**The game in one sentence:** Keep the Ash Ward alive for 12 weekly ticks by rationing food, quarantining districts, funding medicine, and suppressing unrest before plague and panic collapse the city. [file:1]

### Systems exercised

- `FlowEconomyManager` in settlement-management mode for food, medicine, labour, and authority budgets [file:1]
- `ContagionManager.gd` from S13 as the core spread simulation across districts [file:1]
- `TimeTick` addon from S11 to drive weekly crisis turns and seasonal pressure [file:1]
- `FactionManager.gd` to model three internal blocs: Citizens, Wardens, and Clergy [file:1]
- `DialogueBridge` for advisor reports, crisis prompts, decrees, and consequence text [file:1]
- `Quest System` for optional survival objectives such as "End three ticks in a row with infection below threshold" [file:1]
- `TechTreeUI.gd` repurposed as a decree/policy tree with temporary and permanent policy unlocks [file:1]
- `Localisation` for district names, policy names, event text, and crisis labels [file:1]
- `SavePayload.cs` for scenario persistence because the game spans many discrete ticks [file:1]

### Design target

This is not a city builder with full freeform placement. It is a **panel-driven survival strategy game**: four districts, four resources, weekly decisions, event cards, and visible simulation outcomes. The purpose is to prove WOLF's systemic management capability with high readability and low content burden. [file:1]

### Perplexity context to load

- Chunk 2 S13 deliverables: `FlowEconomyManager.gd`, `ContagionManager.gd`, `FactionManager.gd`, `TechTreeUI.gd` [file:1]
- Chunk 4b Part 1 S27 deliverables because the tick-processing and crisis-event cadence partially reuse grand-strategy patterns [file:1]
- Session Summary notes around contagion, economy, and simulation-oriented reuse from Foul Ward [file:1]
- Any existing WOLF decree/policy or event-pattern notes [file:1]

### Key questions for this session

1. District model: should districts be full province-style data nodes like S27, or a lighter district panel collection? Recommendation: district data resources plus panel UI, no map interaction required beyond selecting a district card. [file:1]
2. How should contagion spread work in a management game? Recommendation: `ContagionManager` runs on a small district graph, with infection pressure flowing through adjacency and modified by quarantine, medicine spending, and unrest. [file:1]
3. How many resources are enough for MVP? Recommendation: four visible tracks — food, medicine, labour, authority — each with one core pressure relationship so trade-offs stay legible. [file:1]
4. How should policy unlocks differ from research? Recommendation: treat them as decrees on a short policy tree; some are permanent unlocks, some are active stances with upkeep costs. [file:1]

### Cursor prompts to generate (6 prompts)

1. Scaffold `wolf-crisis` — run `wolf new wolf-crisis --genre grand-strategy`; write `docs/MASTER_DOC.md` with premise (Ash Ward under plague lockdown), 12-week scenario length, victory = survive until Week 12 with central district intact, loss = authority reaches 0 OR infection exceeds collapse threshold in 3 districts; wire autoloads: SignalBus, FlowEconomyManager, ContagionManager, FactionManager, Localisation, DialogueBridge, SoundBridge, TimeTickBridge; run `wolf doc generate` [file:1]

2. Write `resources/districts/` four `DistrictData.tres` resources: `OldGate` (food stores), `RiverWard` (medicine access), `BellQuarter` (labour hub), `CathedralHill` (authority centre/capital); fields: district_id, display_name_key, adjacency_ids, population, infection_level, unrest_level, base_yields, collapse_threshold, strategic_tags; write `scenes/CrisisDashboard.tscn` — four district panels, top resource bars, weekly event feed, decree panel button, end-week button [file:1]

3. Write `scripts/crisis/CrisisController.gd` — weekly loop: collect yields into FlowEconomy pools, apply upkeep, process contagion spread through district adjacency graph, process faction mood changes, draw one crisis event, apply any active decree effects, evaluate loss/win conditions, increment week counter; expose summary data to UI: infection trend, unrest trend, net resource delta per week [file:1]

4. Write `resources/events/` eight `CrisisEventData.tres` resources and `scripts/crisis/EventResolver.gd` — examples: Grain Spoilage, Apothecary Strike, Funeral Riot, Clerical Procession, Border Refugees, Sewer Breach, Blackout, Secret Cure Rumour; each event gives 2–3 choices with resource/faction/infection consequences and optional DialogueBridge flavour; choices can modify Contagion spread modifiers for one or more districts [file:1]

5. Write `resources/decrees/` six `ResearchNodeData.tres` policy/decree nodes and `scenes/DecreePanel.tscn` using `TechTreeUI.gd`: Quarantine Ward (reduces spread, increases unrest), Forced Rationing (preserves food, lowers citizen mood), Street Patrols (stabilises unrest, costs authority), Emergency Clinics (medicine upkeep, lowers infection), Holy Processions (raises clergy support, may worsen infection), Labour Draft (raises labour, raises unrest); decrees can be passive unlocks or toggleable stances with weekly upkeep [file:1]

6. Write 6 GdUnit4 tests: contagion spreads only to adjacent districts absent modifiers, Quarantine Ward lowers spread coefficient but raises unrest next tick, Grain Spoilage event reduces food correctly, authority loss to 0 triggers `game_lost`, surviving through Week 12 with valid state triggers `game_won`, active decree upkeep is charged each week; run `wolf test --game wolf-crisis` and confirm all pass [file:1]

### Deliverables

- [ ] `wolf-games/wolf-crisis/` scaffolded via `wolf new` [file:1]
- [ ] `resources/districts/` four `DistrictData.tres` resources [file:1]
- [ ] `scenes/CrisisDashboard.tscn` [file:1]
- [ ] `scripts/crisis/CrisisController.gd` [file:1]
- [ ] `resources/events/` eight crisis event resources [file:1]
- [ ] `scripts/crisis/EventResolver.gd` [file:1]
- [ ] `resources/decrees/` six decree/policy resources [file:1]
- [ ] `scenes/DecreePanel.tscn` using `TechTreeUI.gd` [file:1]
- [ ] 6 GdUnit4 tests passing [file:1]
- [ ] Scenario playable from Week 1 to Week 12 with visible failure cascades and recoveries [file:1]
- [ ] Save/load across weekly ticks verified [file:1]
- [ ] `wolf simbot run baseline --game wolf-crisis` completes in strategic mode without crash [file:1]

### Unlocks

S33 can later combine this pressure-management pattern with tactical defense nights, and S39 docs work can point to WOLF-CRISIS as the canonical example of using ContagionManager outside a combat game. [file:1]

---

## Session S29 — WOLF-AUTO: Autobattler MVP

**Goal:** Build the first full autobattler loop in WOLF: shop phase, bench, board placement, automatic combat round, reward/shop refresh, and a short multi-round run. The MVP should prove that the framework's `BoardManager`, GAS combat stack, and drag-place interaction can support an auto-resolving strategy game without any direct attack input from the player. [file:1]

**The game in one sentence:** Draft a small plague warband from a rotating shop, place units onto a 4×4 board, and survive six rounds of automatic combat against escalating enemy formations. [file:1]

### Systems exercised

- `BoardManager.gd` from S14 for board/bench state, slot occupancy, and deployment rules [file:1]
- `AutobattlerUnit.gd` from S14 as the core combat unit base [file:1]
- `GAS` AttributeSet for HP, attack speed, armour, and status interactions [file:1]
- `TargetSelector.gd` for auto-targeting nearest or lowest-HP enemies during combat [file:1]
- `EconomyManager` for shop gold, round rewards, and refresh costs [file:1]
- `DialogueBridge` for short announcer text on key rounds and win/lose states [file:1]
- `SoundBridge` for buy, deploy, merge, round-start, and unit-death feedback [file:1]
- `Localisation` for unit names, traits, shop text, and round labels [file:1]
- Optional light `Quest System` objective layer such as "Win a round with exactly 3 deployed units" [file:1]

### Design target

This is not a full Teamfight Tactics clone. It is a **small-board, six-round autobattler** with 8–10 unit types, a simple shop, one merge rule, and a clean combat resolution loop. The architecture goal is more important than content volume: drag from shop/bench to board, lock formation, watch combat resolve, collect reward, repeat. [file:1]

### Perplexity context to load

- Chunk 2 S14 deliverables: `BoardManager.gd`, `AutobattlerUnit.gd`, `TargetSelector.gd` [file:1]
- Chunk 4a and 4b prior demos for GAS patterns, reward structures, and state persistence decisions [file:1]
- Any `guladam` autobattler-base extraction notes mentioned in the session summary [file:1]
- Session Summary autobattler MVP notes [file:1]

### Key questions for this session

1. Board representation: should board and bench both use the same slot-resource model? Recommendation: yes — unified `BoardSlotData` with tags (`bench`, `frontline`, `backline`) to keep drag-drop logic simple. [file:1]
2. Combat simulation cadence: fully continuous real-time or stepped ticks? Recommendation: lightweight continuous time with attack cooldown timers is enough for MVP and aligns with GAS unit combat. [file:1]
3. Merge/upgrade rule: when do units combine? Recommendation: classic 3-of-a-kind merge into a 2-star version with multiplicative stat gain, because it is intuitive and content-light. [file:1]
4. Enemy rounds: authored formations or procedural generation? Recommendation: authored round formations for six rounds, because that gives reliable difficulty pacing and easier SimBot balancing. [file:1]

### Cursor prompts to generate (6 prompts)

1. Scaffold `wolf-auto` — run `wolf new wolf-auto --genre autobattler`; write `docs/MASTER_DOC.md` with premise, six-round structure, board size (4×4 battle board + 5-slot bench), gold rules (start 5, +3 per round, refresh cost 2), win condition = clear round 6 boss board, loss = health reaches 0 from round defeats; wire autoloads: SignalBus, EconomyManager, Localisation, DialogueBridge, SoundBridge, BoardManager; run `wolf doc generate` [file:1]

2. Write `scenes/AutoBoard.tscn` and `scripts/auto/AutoRoundController.gd` — board contains 16 battle slots in two halves (player bottom, enemy top) plus 5 bench slots and 5 shop slots; phases: PREP (shop open, drag/drop enabled, refresh allowed) → LOCK (player clicks ready) → COMBAT (shop disabled, units auto-fight) → REWARD (gold payout, optional unit reward, next round setup); AutoRoundController owns round index, player HP, reward payout, enemy formation loading, and phase transitions [file:1]

3. Write `resources/units/auto/` 8 autobattler unit resources and scenes: `Ratling`, `PlagueGuard`, `BoneArcher`, `MortarAdept`, `ChantPriest`, `LeechHound`, `CarrionKnight`, `PoxOracle`; define role tags (frontline, ranged, support), cost tier (1–3 gold), and one passive each; implement simple passives directly in `AutobattlerUnit.gd` hooks — e.g., BoneArcher prioritises lowest-HP enemy, ChantPriest heals nearest ally every 4s, LeechHound lifesteals 25% damage dealt [file:1]

4. Write `scripts/auto/ShopManager.gd` and `scenes/ShopPanel.tscn` — fills 5 shop slots each prep phase from weighted pool by round number, handles buy, refresh, and freeze-shop actions; purchased units go to first empty bench slot; if player buys third copy of same unit star level, auto-merge into upgraded unit instance with stat multiplier (HP ×1.8, attack ×1.5); write merge VFX/SFX hook via SoundBridge [file:1]

5. Write `resources/enemy_rounds/` six authored enemy formation resources and `scripts/auto/EnemyFormationLoader.gd` — each round defines enemy units, slot positions, and reward gold; round 6 boss board includes one `PoxOracle` 2-star plus escorts; combat resolution ends when one side has no living units; player loses HP equal to surviving enemy star-sum; add one optional quest objective via Quest System: "Win Round 3 without losing a unit" [file:1]

6. Write 6 GdUnit4 tests: buying a unit deducts correct gold and places on bench, drag from bench to board updates BoardManager occupancy, three copies merge into 2-star unit, BoneArcher targets lowest-HP enemy correctly, round loss subtracts player HP by surviving enemy value, clearing round 6 emits `game_won`; run `wolf test --game wolf-auto` and confirm all pass [file:1]

### Deliverables

- [ ] `wolf-games/wolf-auto/` scaffolded via `wolf new` [file:1]
- [ ] `scenes/AutoBoard.tscn` + `scripts/auto/AutoRoundController.gd` [file:1]
- [ ] `resources/units/auto/` eight unit resources and scenes [file:1]
- [ ] `scripts/auto/ShopManager.gd` + `scenes/ShopPanel.tscn` [file:1]
- [ ] Merge rule implemented with 2-star upgrade path [file:1]
- [ ] `resources/enemy_rounds/` six enemy formation resources [file:1]
- [ ] `scripts/auto/EnemyFormationLoader.gd` [file:1]
- [ ] 6 GdUnit4 tests passing [file:1]
- [ ] Six-round run playable end-to-end [file:1]
- [ ] Board/bench/shop loop feels stable and readable [file:1]
- [ ] `wolf simbot run baseline --game wolf-auto` completes and reports round-clear rates [file:1]

### Unlocks

S30 directly extends this architecture into the more expressive synergy-driven autobattler, and S35 may later borrow the board-phase combat structure if the hybrid roguelite uses auto-combat rooms. [file:1]

---

## Phase 2, S28–S29 — Session Status Tracker

| Session | Game | Genre | Depends on | Status |
|---------|------|-------|-----------|--------|
| S28 | WOLF-CRISIS | Survival Management | S27 recommended, S20 minimum | ⏳ |
| S29 | WOLF-AUTO | Autobattler MVP | S20 | ⏳ |

S28 benefits from S27 because both share strategic tick-processing patterns, but it can still run after S20 if needed. S29 depends only on the Phase 1 framework gate and can be developed in parallel with S28. [file:1]

---

## Position in Remaining Chunk 4

After this sub-chunk, the remaining Phase 2 sessions still to document are: S30 `WOLF-SYNERGY`, S31 `WOLF-DUNGEON`, S32 `WOLF-NECRO`, then S33–S38. [file:1]

*End of Chunk 4b Part 2. The next continuation should cover S30–S31 unless you want to reorder around dependency priority.* [file:1]
