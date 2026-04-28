# WOLF Framework — Master Workplan
## Chunk 4b Part 1 of 5: Phase 2 Sessions S26–S27
### Demo Games Part 2: Card Campaign MVP · Grand Strategy MVP

**Document version:** 1.0 | **Continues from:** Chunk 4a (S21–S25)
**Covers:** The next two Phase 2 game sessions.
**Prerequisites:** All Phase 1 sessions complete; S20 integration test passed; Chunk 4a accepted.

---

## Phase 2 Positioning

This sub-chunk continues the playable game rollout after the first five MVPs. These two sessions matter because they push the framework beyond skirmish-scale combat into two higher-level structures: **persistent campaign progression** and **turn/tick-based map strategy**. [file:1]

S26 tests whether the framework can carry state across multiple combats in a long-lived run with meta-progression, while S27 tests whether province control, diplomacy, and research can coexist in a legible turn-processing loop. [file:1]

---

## Session S26 — WOLF-DECKBUILDER: Card Campaign MVP

**Goal:** Build a campaign-scale card game that extends the S25 roguelite combat foundation into a persistent progression layer with unlockable cards, saved collection state, persistent relics, node-map travel, and run-to-run advancement. The game should prove that WOLF can support both short-run deckbuilders and longer-form collectible/campaign structures without rewriting the underlying combat scene. [file:1]

**The game in one sentence:** Travel across a five-node plague province map, fight card battles, recruit cards into a permanent collection, and build a campaign deck over multiple runs until the Corruption Heart is defeated. [file:1]

### Systems exercised

- `Card Framework` combat layer from S25, reused rather than rewritten [file:1]
- `SavePayload.cs` for persistent campaign state rather than disposable run state [file:1]
- `Quest System` for optional campaign objectives and milestone unlocks [file:1]
- `DialogueBridge` for chapter intros, encounter flavour, and boss victory scenes [file:1]
- `FactionManager` in a light form for encounter ownership (`PLAYER`, `PLAGUE`, `SURVIVORS`) [file:1]
- `Localisation` for card names, relic names, map nodes, encounter labels, and chapter text [file:1]
- `SoundBridge` for card play, reward reveal, node unlock, and boss kill feedback [file:1]
- `MASTER_DOC` automation flow from S19, because this game introduces more persistent data tables than S25 [file:1]

### Relationship to S25

S26 must **not** fork the entire card combat stack. It should directly reuse the `CombatRoom.tscn`, `CombatManager.gd`, enemy intent pattern, card resources, and status-effect setup built in S25, while layering campaign progression on top. The session is successful only if the delta from S25 is mostly in map logic, persistence, unlock rules, and deck management UX. [file:1]

### Perplexity context to load

- Chunk 4a, especially S25 deliverables and assumptions [file:1]
- `autoloads/RunState.gd` from S25 to decide what upgrades into campaign persistence [file:1]
- `framework/templates/SavePayload.cs` from S09 [file:1]
- `framework/addons/godot-quest-system/` from S11 [file:1]
- Session Summary §6 card-roguelite scope and the broader WOLF "one map, one faction, one win condition" MVP framing [file:1]

### Key questions for this session

1. Where should the line sit between temporary run state and permanent account/campaign state? Recommendation: `RunState.gd` still handles in-combat and in-run transitions, but `CampaignSavePayload` owns unlocked cards, unlocked relics, completed nodes, and current chapter progress. [file:1]
2. How should the permanent collection work without turning the MVP into a full CCG? Recommendation: every cleared combat grants a pack-like reward of 1 chosen card from 3, but unlocked cards go into the permanent collection and future deckbuilding screens pull only from collection-owned cards. [file:1]
3. How many campaign chapters are enough for MVP scope? Recommendation: one chapter map with five nodes plus final boss; the persistence proves the architecture without requiring content bloat. [file:1]
4. How should deck editing work between battles? Recommendation: a lightweight camp screen with a current deck panel, collection panel, max deck size rule, and drag-click add/remove interaction — not a full custom deckbuilder UX suite. [file:1]

### Cursor prompts to generate (6 prompts)

1. Scaffold `wolf-deckbuilder` — run `wolf new wolf-deckbuilder --genre card-roguelite`; update `docs/MASTER_DOC.md` with game name, campaign premise, persistent collection description, target session length = 15 minutes per chapter; replace S25's `RunState`-only framing with dual-state design: `RunState.gd` for active battle/run context and `CampaignSavePayload.cs` for persistent meta state; run `wolf doc generate` and commit scaffold [file:1]

2. Write `autoloads/CampaignState.gd` and `scripts/save/CampaignSavePayload.cs` — fields: `owned_card_ids`, `owned_relic_ids`, `current_deck_card_ids`, `chapter_index`, `completed_node_ids`, `gold`, `campaign_flags`, `last_boss_defeated`; save path: `user://wolf_deckbuilder_campaign.save`; methods: `new_campaign()`, `save_campaign()`, `load_campaign()`, `unlock_card(card_id)`, `unlock_relic(relic_id)`, `mark_node_complete(node_id)`; include version field and migration stub following the SavePayload pattern [file:1]

3. Write `scenes/CampaignMap.tscn` — one chapter map with 5 connected nodes: Start Encounter, Elite Combat, Camp, Choice Event, Boss; `scripts/CampaignMapController.gd` unlocks next node on clear, stores completion in CampaignState, and opens the correct scene by node type; include `MapNodeData.tres` resources in `resources/map_nodes/` with node id, type, label, rewards, and target combat profile [file:1]

4. Write `scenes/CampScreen.tscn` and `scripts/DeckEditor.gd` — current deck on left, collection pool on right, max deck size 15, min deck size 10; clicking a collection card adds it to deck if size limit allows; clicking a deck card removes it if minimum size preserved; include relic inventory strip and heal-for-gold action; all card/relic names sourced through Localisation keys [file:1]

5. Extend S25 combat content into campaign format — add `resources/encounters/` profiles (`encounter_start`, `encounter_elite`, `encounter_boss`) that specify enemy groups, gold reward, reward-rarity weights, and quest triggers; write `scripts/CampaignCombatBridge.gd` that consumes encounter profile, launches `CombatRoom.tscn`, and on victory applies rewards to CampaignState; include 5 new card rewards and 3 new relics intended for campaign-only unlocks [file:1]

6. Write 6 GdUnit4 tests: new campaign creates starter collection and deck, unlocking a card adds it to owned collection, completed node persists after save/load, DeckEditor enforces min/max deck size correctly, elite encounter grants higher-rarity reward odds than standard encounter, boss victory sets `last_boss_defeated = true`; run `wolf test --game wolf-deckbuilder` and confirm all pass [file:1]

### Deliverables

- [ ] `wolf-games/wolf-deckbuilder/` scaffolded via `wolf new` [file:1]
- [ ] `autoloads/CampaignState.gd` [file:1]
- [ ] `scripts/save/CampaignSavePayload.cs` with versioning and migration stub [file:1]
- [ ] `scenes/CampaignMap.tscn` + `scripts/CampaignMapController.gd` [file:1]
- [ ] `resources/map_nodes/` node data resources [file:1]
- [ ] `scenes/CampScreen.tscn` + `scripts/DeckEditor.gd` [file:1]
- [ ] `resources/encounters/` encounter profiles [file:1]
- [ ] `scripts/CampaignCombatBridge.gd` [file:1]
- [ ] 5 new card rewards and 3 new relics [file:1]
- [ ] 6 GdUnit4 tests passing [file:1]
- [ ] Campaign loop playable: Start → Elite → Camp → Event → Boss [file:1]
- [ ] Save/load verified across app restart [file:1]
- [ ] `wolf simbot run baseline --game wolf-deckbuilder` completes without crash, even if balance output is mostly sanity-check rather than true optimisation [file:1]

### Unlocks

S35 can later borrow the campaign/deck persistence patterns if the hybrid roguelite needs them, and S39 docs work will reference this as the canonical example of WOLF's persistent card-game architecture. [file:1]

---

## Session S27 — WOLF-GRAND: Grand Strategy MVP

**Goal:** Build a map-based strategy game where the player controls provinces, manages resources on a time tick, negotiates or fights neighbouring factions, and researches a small technology tree. The MVP should prove that WOLF supports "slow strategy" just as well as real-time combat-heavy genres. [file:1]

**The game in one sentence:** Rule a five-province plague kingdom, tax and fortify your lands, choose diplomacy or war with two rival factions, and achieve dominance by controlling three capitals before winter ends. [file:1]

### Systems exercised

- `ProvinceMapManager.gd` from S12 for province ownership, adjacency, and province events [file:1]
- `FactionManager.gd` from S13 for relations, hostility, alliance flags, and war-state queries [file:1]
- `TechTreeUI.gd` from S13 for three-branch research progression [file:1]
- `TimeTick` addon from S11 for monthly/seasonal progression and event timing [file:1]
- `FlowEconomyManager` in strategic mode for tax, food, and unrest pressures [file:1]
- `DialogueBridge` for advisor events, diplomacy offers, and crisis prompts [file:1]
- `Quest System` for optional strategic objectives such as "hold border provinces for 3 ticks" [file:1]
- `Localisation` for province names, tech names, policy labels, and event text [file:1]
- `SavePayload.cs` for campaign persistence because turns/ticks must survive quit/resume [file:1]

### Design target

This is not a full Europa Universalis clone. It is a **small-map, high-legibility** grand strategy MVP: one map, three factions, five provinces, three resources, one tech tree, and one winter deadline. The point is not breadth. The point is to prove that WOLF can host province ownership, diplomacy matrices, ticking resources, and event-driven narrative choices inside one coherent architecture. [file:1]

### Perplexity context to load

- Chunk 2 S12 and S13 deliverables (`ProvinceMapManager.gd`, `FactionManager.gd`, `TechTreeUI.gd`, `FlowEconomyManager.gd`) [file:1]
- Chunk 3 S19 doc-automation decisions because the game will need large auto-generated enum/resource tables [file:1]
- Session Summary's grand-strategy MVP notes [file:1]
- Any province-map recipe notes already extracted into WOLF [file:1]

### Key questions for this session

1. Province map representation: image-mask provinces, polygonal clickable regions, or a data-driven graph with a visual overlay? Recommendation: data-driven adjacency graph plus clickable polygon overlays, because it is simplest for AI and save-state logic. [file:1]
2. Time model: full turns or continuous ticks? Recommendation: monthly ticks driven by TimeTick, grouped into four seasons, with winter-end as hard scenario deadline. [file:1]
3. Resource model: should every province produce all resources in tiny amounts, or should provinces specialise? Recommendation: province specialisation gives meaningful territorial decisions — e.g., Grainvale produces food, Ironreach produces metal, Black Abbey produces faith/research. [file:1]
4. Diplomacy: how deep for MVP? Recommendation: relation score, non-aggression pact, alliance, war, tribute demand, and one crisis event chain. Enough to prove FactionManager patterns without bloating the UI. [file:1]

### Cursor prompts to generate (7 prompts)

1. Scaffold `wolf-grand` — run `wolf new wolf-grand --genre grand-strategy`; fill `docs/MASTER_DOC.md` with scenario pitch, five-province map, three factions (`PLAYER`, `ASHEN COURT`, `RIVER LEAGUE`), victory condition = control 3 capitals by end of Winter Turn 12, loss = capital lost for two consecutive ticks; wire autoloads: SignalBus, FlowEconomyManager, FactionManager, ProvinceMapManager, Localisation, DialogueBridge, SoundBridge, TimeTickBridge; run `wolf doc generate` [file:1]

2. Write `resources/provinces/` five `ProvinceData.tres` resources: `BlackAbbey` (capital, research focus), `Grainvale` (food focus), `Ironreach` (metal focus), `Mireford` (border fort province), `HollowMarch` (unrest-prone frontier); fields: province_id, display_name_key, owner_faction, adjacent_ids, resource_yields, unrest_base, is_capital, strategic_value; write `scenes/GrandMap.tscn` with clickable polygon regions matching these provinces and a right-side province inspector panel [file:1]

3. Write `scripts/strategic/GrandCampaignController.gd` — drives the monthly tick loop using TimeTick; each month: collect province yields into FlowEconomy strategic buffers, process unrest growth/decay, resolve wars/battles abstractly on contested borders, check research progress, fire event queue, then evaluate victory/loss conditions; seasons every 3 ticks; at Winter end (tick 12) evaluate final victory state [file:1]

4. Write `scripts/strategic/DiplomacyPanel.gd` and `scenes/DiplomacyPanel.tscn` — relation score per faction displayed as number and stance icon; actions: offer non-aggression pact, demand tribute, declare war, propose alliance; all actions call FactionManager methods and enqueue advisor dialogue via DialogueBridge; include one crisis event chain: if player controls both Grainvale and Ironreach by turn 6, Ashen Court demands tribute or declares war [file:1]

5. Write `resources/research/` 9 `ResearchNodeData.tres` resources in three branches: Governance (Tax Reform, Provincial Courts, Emergency Decrees), Military (Militia Drill, Siege Rations, Border Forts), Doctrine (Pestilent Theology, Ritual Census, Black Procession); `scenes/ResearchScreen.tscn` uses `TechTreeUI.gd`; research progress accumulates from BlackAbbey's research yield + doctrine modifiers; unlocking Border Forts reduces unrest growth in Mireford and HollowMarch [file:1]

6. Write `scripts/strategic/ProvinceBattleResolver.gd` — abstract conflict model for border wars: compares attacker force score, defender force score, fort bonus, unrest penalty, and seasonal modifier (winter hurts attacker); outputs province flip/no flip and casualties; integrate with FactionManager war state and GrandCampaignController tick processing; include event log entry for each battle [file:1]

7. Write 6 GdUnit4 tests: province adjacency graph loads correctly, monthly tick adds correct province yields to strategic economy, declaring war updates FactionManager state, unlocking Border Forts reduces unrest growth on next tick, winter battle applies attacker penalty, controlling three capitals before turn 12 emits `game_won`; run `wolf test --game wolf-grand` and confirm all pass [file:1]

### Deliverables

- [ ] `wolf-games/wolf-grand/` scaffolded via `wolf new` [file:1]
- [ ] `resources/provinces/` five `ProvinceData.tres` resources [file:1]
- [ ] `scenes/GrandMap.tscn` with clickable province overlays [file:1]
- [ ] `scripts/strategic/GrandCampaignController.gd` [file:1]
- [ ] `scenes/DiplomacyPanel.tscn` + `scripts/strategic/DiplomacyPanel.gd` [file:1]
- [ ] `resources/research/` nine `ResearchNodeData.tres` resources [file:1]
- [ ] `scenes/ResearchScreen.tscn` using `TechTreeUI.gd` [file:1]
- [ ] `scripts/strategic/ProvinceBattleResolver.gd` [file:1]
- [ ] One scripted diplomacy crisis event chain [file:1]
- [ ] 6 GdUnit4 tests passing [file:1]
- [ ] Scenario playable from tick 1 to tick 12 with clear win/loss resolution [file:1]
- [ ] Save/load across turns verified [file:1]
- [ ] `wolf simbot run baseline --game wolf-grand` completes in strategic-simulation mode without crash [file:1]

### Unlocks

S28 can reuse the tick/event loop and strategic FlowEconomy pattern for crisis management, while S33 can later combine province ownership with tactical defense using this as its strategic half. [file:1]

---

## Phase 2, S26–S27 — Session Status Tracker

| Session | Game | Genre | Depends on | Status |
|---------|------|-------|-----------|--------|
| S26 | WOLF-DECKBUILDER | Card Campaign | S25 | ⏳ |
| S27 | WOLF-GRAND | Grand Strategy | S20 | ⏳ |

S26 depends directly on S25 because it deliberately extends the card-combat foundation rather than reimplementing it, while S27 depends only on the Phase 1 gate and can run in parallel with S26 if a separate session is handling strategic systems. [file:1]

---

## Position in Remaining Chunk 4

After this sub-chunk, the remaining Phase 2 sessions still to document are: S28 `WOLF-CRISIS`, S29 `WOLF-AUTO`, S30 `WOLF-SYNERGY`, S31 `WOLF-DUNGEON`, S32 `WOLF-NECRO`, then later S33–S38. [file:1]

*End of Chunk 4b Part 1. The next continuation should cover S28–S29 unless you want to reprioritise the order.* [file:1]
