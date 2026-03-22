# FOUL WARD — Complete Game Design Document
Working Title: Foul Ward | Genre: Tower Defense (2.5D) | Engine: Godot 4 GDScript
Platforms: PC, Mac, Android | Monetization: Free base + paid DLC campaigns
License: GPL v3 (code) + Proprietary (art/story assets)

---

CORE CONCEPT

Medieval fantasy tower defense inspired by Taur, fixing its core problems while adding
dark humor tone (Overlord / Evil Genius / Dungeon Keeper / Pratchett-style).
You are monster hunters defending a mobile tower against omnidirectional enemy invasions.
Characters are based on real people (developer + two friends).

---

THE THREE HEROES

FLORENCE (The Gunner) — male, flower-themed name
- Role: Primary weapon platform, stationary on tower top
- Control: Player aims and fires manually — free crosshair, visible projectiles,
  more forgiving than Taur but still requires skill to lead moving targets
- Weapons: Multiple unlockable types, some cooldown-based, some fire-rate-based
- Personality: The boss. Practical, slightly worried about his plants
- Death condition: Tower falls = Florence falls = mission fail
- Progression: Weapon tree via research + shop
- Flying enemies: Florence CANNOT target flying enemies — anti-air buildings handle them

ARNULF FALKENSTEIN IV (The Warrior)
- Role: Secondary weapon platform, mobile melee, AI-controlled
- Starting weapon: A shovel (melee only — later weapons increasingly absurd)
- Control: AI with pre-set behavioral roles configured between missions
- Always attacks closest enemy to the tower center
- Patrol radius: Upgradeable, roughly halfway to edge of play area
- When no enemies: returns to stand adjacent to the tower
- Kill counter: Charges a frenzy mode (rapid attacks for several seconds)
- Drunken mechanic: Gets progressively drunk per wave — slower movement, hits harder
  Between-wave action available to sober him up (costs resources)
- Incapacitation: When HP hits 0 — collapses, takes a drink, rage buff activates,
  recovers automatically after ~3 seconds at 50% HP. CANNOT BE PERMANENTLY STOPPED.
  Cycle repeats unlimited times per mission.
- Visual: Drunkenness shows on character model/animations. Between-mission screen
  shows him slouched in Emperor of Mankind (Warhammer 40K) style throne, passed out,
  bottle nearby. Other characters active around him.
- Drunkenness HUD indicator: Small, unobtrusive icon — not the main focus
- Personality: Simple man. Drinks. Fights. Very angry. No tragic backstory.
  Loyal henchman to Florence.
- Progression: Own weapon tree separate from Florence. Weapons get increasingly absurd.

SYBIL THE WITCH (written exactly as: Sybil the Witch)
- Role: Battlefield-wide spell support, stationary on tower
- Magic: Geomancy (rock/earth) + time manipulation
  Character is based on a geology major — rocks/earth aesthetic is CANONICAL
- Mana: Own regenerating pool + per-spell cooldowns
- Spell Kit (4 hotbar slots max, unlocked via research):
  1. Shockwave — Battlefield-wide AoE, rocks erupt from ground (earthy/grounded visual)
  2. Tower Shield — Tower invincible ~10 seconds (emergency defensive)
  3. Time Stop — Freezes all enemies. JoJo Dio "Za Warudo" inspired: distinct "wob wob"
     sound effect, expanding crystalline sphere covers battlefield, vanishes like shockwave.
     STRETCH GOAL — complex implementation, not day-one feature.
  4. TBD — fourth slot open for future design
- Passive: Player selects ONE passive ability before each mission from unlocked options
- Buff mechanic: Some of Arnulf's "activated abilities" are secretly Sybil casting on him
- Friendly fire: Her spells hit Arnulf. Played for comedy — he reacts with dialogue
- Visual style: Most spells earthy/grounded (stone, dust, tremors).
  Time magic crystalline/elegant (distinct visual language)
- Personality: Cryptic and unsettling... but it doesn't always land. That's the joke.
  Outside contractor. Cooperates professionally with Florence and Arnulf.
- Motivation: Simply into the work. Monster hunting is the job.
- Death condition: Soul-linked to tower. Tower falls = she falls = mission fail
- Teleportation: Moves the tower between missions (narrative wrapper for mission select)
- Divination: Provides pre-mission enemy intel via divination ball (no separate scouting)
- First-time interactions have special dialogue lines for special events

---

THE TOWER & BASE STRUCTURE

- Central Tower: Destructible. Florence and Sybil operate from it.
- Visible damage states: Cracks, fire, leaning structure before collapse
- HP bar displayed at all times
- Visually upgradeable: Grows taller, adds decorations per campaign
- Hex Grid: ~60+ slots (upgradeable), build mode reveals grid, slows time to 10%
- Build Mode: Click slot → radial menu → place building
  Time scale drops to 10% on enter. Configurable in accessibility settings.
- Sell: Same-price or near-same refund (low friction, encourages experimentation)
- In-place upgrades: Gold to upgrade existing buildings (Level 1 to 2), separate from research
- Special terrain slots: Some maps have unique hex locations (hilltop = +range, etc.)
  Also special map-specific slots (barracks summons warriors, forge = +damage aura)
- Building destruction: Down mid-mission. Repaired between missions.
- Targeting priority: Player configures per building (focus flying, closest, highest HP, etc.)

Building Categories:
- Regular turrets (physical damage)
- Elemental towers (fire / magical / poison)
- Artillery (AoE bombardment)
- Anti-air / Missile defense
- Cryo/slow towers
- Fighter / Bomber / Gunship hangars
- Shield generators
- Mercenary barracks
- Undead/demon summoning structure (NOT a Sybil spell — it is a building)

---

COMBAT SYSTEMS

Damage Types (4):
Physical  | Grey sparks    | Strong: light armor        | Weak: heavy armor, shields
Fire      | Orange flames  | Strong: structures, undead | Weak: wet/stone enemies
Magical   | Purple/blue    | Bypasses armor             | Weak: magically shielded
Poison    | Green cloud    | DoT spreads in masses      | Undead IMMUNE (dark humor line)

Armor/Resistance Types:
Unarmored   — full damage from everything
Heavy armor — resists Physical, weak to Magical
Undead      — immune to Poison, extra damage from Fire
Flying      — immune to ground AoE, requires anti-air buildings

Wave Mechanics:
- Omnidirectional spawning — enemies from all sides, no fixed lanes
- Wave warning — horn + UI indicator ~30 seconds before wave
- Gold per kill — awarded immediately on death (floating +gold text)

---

MERCENARIES

Types:
- Named mercenaries: Individual characters, own personality, own upgrade paths
- Mob units: Palette-swapped squads, randomly named, player can rename
- Campaign hero mercs: 1-2 per campaign, unique upgrade paths

Morale System:
Affects effectiveness (NOT desertion).
Influenced by: consecutive wins, health state.
Low morale = lower attack speed, accuracy, melee speed.

Death/Incapacitation:
Named mercs: Incapacitated for multiple missions if "killed"
Mob units: Cannot die permanently — incapacitated several missions, always return

Upgrades:
No individual gear for mob mercs. Research tree per mercenary type.
Campaign hero mercs have specific upgrade paths.

Enemy Recruitment:
Some enemy types recruitable after defeating them.
Potentially recruit enemy boss as hero (campaign-dependent).

---

ECONOMY & RESOURCES

Three Resources:
Gold              | Yellow | Enemy kills (immediate) | Buildings, upgrades, shop, respecs
Building Material | Grey   | Post-mission reward     | Building placement, upgrades
Research Material | Blue   | Post-mission reward     | Tech tree unlocks ONLY

The Wagon (Shop):
- Shopkeeper: Different local merchant per campaign
  Reactive comments between missions (not full dialogue trees)
- Permanent catalog always available (gold-only consumables)
- Rotating stock refreshes every 2-3 missions
- Emergency section for expensive gold sinks
- Carry limits on consumables (e.g., max 3 flasks)
- Inventory expands as campaign progresses

Research Tree (6 Separate Trees):
1. Florence's Weapons
2. Arnulf's Weapons
3. Sybil's Spells & Passives
4. Base Structures
5. Mercenaries
6. Special Units

Respec System:
3 free respecs per campaign. Additional respecs cost gold (shop emergency section).

---

CAMPAIGN STRUCTURE — THE 50-DAY WAR

Territory Map:
Hand-drawn illustrated fantasy map style (old maps with mountains/forests).
Green territories: we control (easy).
Yellow territories: contested (medium).
Red territories: enemy-controlled (hard).
Difficulty based on territorial ownership + location.
Non-linear — player chooses which territory to attack or defend each day.

Per Campaign:
~25+ missions. Long campaigns.
After 50 days: Campaign boss arrives (mandatory, scales to player power).
Lose to boss: Lose one territory, fall back, keep all upgrades/gold, try again.
Lose all territories: Campaign over, start fresh (Chronicle Perks persist).
Win boss fight: Campaign ends, story resolves.
Post-boss: Hardcore difficulty + challenge missions unlock.

Post-Campaign Star System:
Normal (1 star): Cleared during campaign.
Veteran (2 stars): Harder composition, higher rewards.
Nightmare (3 stars): Remixed enemies, modified bosses, unique cosmetic rewards.

Story Progression:
Driven by days survived (not territory control meter).
Some missions are story-locked (mandatory). Player chooses others.
Plot is the MAIN SELLING POINT — story progression is primary appeal.

---

ENEMY FACTIONS

FREE CAMPAIGN: ORCS
Dark humor potential — bumbling but dangerous, tribal and escalating.
Units: Orc Grunt, Orc Berserker, Orc Brute, Orc Archer, Orc Shaman (boar rider),
Orc Siege Troll (ranged boulder thrower), Orc Wolf Rider, Orc Warboss
(mini-boss, orcs scatter if killed), Goblin Swarm (20 fodder at once),
Goblin Saboteur (stealth, sets fires), Orc Warchief (campaign boss, monologues too long).

INFINITE MODE: UNDEAD
Attrition threat. Reassembling skeleton mechanic forces specialized builds.
Pyre building (infinite-only) permanently destroys fallen undead.
Units: Skeleton Warrior (reassembles unless fire/holy), Shambling Zombie (infects buildings),
Ghoul (fast, ignores Arnulf unless attacked), Banshee (silences Florence's weapon),
Bone Archer, Necromancer (resurrects fallen mid-wave), Death Knight (blocks frontal
projectiles), Wight (drains Arnulf's rage meter), Lich Apprentice (mini-boss, counters
Sybil's time magic), Bone Colossus (late boss, assembles from fallen, grows larger).

Note: Infinite Mode — players can fight ORCS or UNDEAD.
Undead have Infinite mode only; no campaign yet.

---

INFINITE MODE

Play one map until death with escalating waves.
Multiple maps selectable.
Own meta-progression: permanent upgrades making each run start stronger.
Own progression track separate from campaigns.

---

GLOBAL META-PROGRESSION — THE CHRONICLE OF FOUL WARD

Persistent illustrated tome tracking deeds across all campaigns.
Milestones unlock Chronicle Perks.
Before any new campaign: choose 3 perks from unlocked Chronicle.
Perks are mild advantages, not game-breaking.

Example Perks:
- Arnulf's Flask: Start with extra rage charge
- Sybil's Foresight: One free respec per campaign
- Florence's Aim: First weapon starts rank 2
- Veteran Mercs: Mob units start higher morale

---

ART & VISUAL STYLE

Target: Low-poly 3D with exaggerated grotesque character designs + hand-illustrated
2D portraits for heroes/bosses. Darkest Dungeon meets stylized low-poly.

Camera: 2.5D — full 3D scene, orthographic Camera3D, isometric angle.
Android: Portrait and landscape both supported, camera free or lockable, zoom available.

Asset Pipeline:
- Blender → .glb → Godot 4
- Free CC0 assets: KayKit Medieval Hexagon Pack, Quaternius, Kenney.nl
- AI-generated 3D: Tripo AI (characters), Meshy (environment props)

Environment: Weather effects randomized per playthrough (visual-only initially).
Same map can have rain, fog, or snow on different runs.

---

AUDIO & TONE

Tone: Pratchett-style dark humor. World played earnest, absurdity emerges naturally.
Rare fourth-wall breaks. Orcs brutal, heroes darkly funny about it.

Dialogue: Hades-style banter during missions and between boss encounters.
Florence: Practical boss, worried about plants.
Arnulf: Simple, angry, trash-talks enemies, reacts when Sybil's spells hit him.
Sybil: Cryptic, unsettling, often doesn't land — that's the joke.
First-time interaction lines for special events.

Narrator: Full voiceover in free campaign (demonstrates paid DLC quality). Skippable.
Music: Hybrid orchestral/folk medieval with dramatic swells during bosses.

---

TECHNICAL STACK

Engine: Godot 4 (GDScript — preferred over C# for LLM compatibility)
Testing: GdUnit4 framework
MCP: GDAI MCP Server (AI reads Godot output, runs scenes, debugs in real-time)

Workflow:
1. Claude Opus — architecture, ARCHITECTURE.md, CONVENTIONS.md, SYSTEMS.md
2. Perplexity Pro — GDScript generation from Opus specs (parallel workstreams)
3. GDAI MCP + Claude — inner dev loop (write, run, read errors, fix, iterate)
4. Cursor Pro — multi-file refactors, codebase-wide edits, test suite runs
5. Perplexity Deep Research — validation, existing solutions, debugging research

---

SIMULATION TESTING DESIGN

All game systems must be fully decoupled from player input handling.
The goal: a headless GDScript bot can drive the entire game loop by connecting to
signals and calling public methods, with zero UI interaction required.

This enables automated playtesting strategies such as:
- "Buy only arrow towers" bot
- "Buy only fire buildings" bot
- "Max Arnulf upgrades only" bot

Each bot runs headlessly, plays through all 50 days, and reports findings.
This catches balance issues before human playtesters ever touch the game.

ARCHITECTURAL CONSTRAINT: No game logic may be tangled with UI code or input handling.
Flag any system design that violates this in ARCHITECTURE.md.

---

MONETIZATION & OPEN SOURCE

Base game: 100% free and open source.
  - One full story campaign (Orcs) with full narrator/artwork/voiceover
  - Infinite mode (Orcs + Undead)
  - All core mechanics

Paid DLC: Campaign packs (~$1 per campaign OR bundle — TBD)
  - New factions, storylines, full voiceover, hand-illustrated art
  - Standalone campaigns (independent difficulty, similar balance across all)
  - Loose shared lore across campaigns (Easter eggs, passing references)

License: GPL v3 (engine/game code) + Proprietary (art, voice, story, campaign data)

Modding:
  - Full GDScript mod support
  - Config files exposed (all monster/hero/unit stats editable)
  - In-game mod editor (stretch goal)

Bestiary/Codex: Fills in as players encounter enemies. Lore, stats, Sybil's sarcastic
annotations. Nice-to-have, not MVP scope.

---

DESIGN PHILOSOPHY — FIXES FROM TAUR

1. No vicious cycle: Buildings have Damaged state (50%) before Destroyed. Repair cheaper.
2. No RNG forge: Deterministic temper system — visible pick-3 modifier choices.
3. No resource bloat: Only 3 resources. Clear purposes, no stalling.
4. Clear difficulty signaling: Skull ratings, enemy preview, adaptive boss scaling.
5. Weapon balance: Weapons designed around enemy archetypes, not raw DPS.
6. Better aiming: Free crosshair with visible projectiles — forgiving but skillful.
7. Boss scaling: Boss always scales to player power. Lose to boss = lose territory, not game over.

---

DEFERRED DECISIONS (Post-MVP / Needs Author)

Story: All campaign plots, enemy commander names, shopkeeper personalities per campaign.
Sybil's 4th spell, full passive ability list.
Arnulf's weapon progression beyond the shovel.
Florence's complete weapon roster.
All paid campaign settings and factions.
Exact numerical values (radius, mana pools, gold scaling, respec costs).
Special terrain hex slot mechanics per map.
Arnulf's shovel name (if weapon names implemented).
Exactly how between-mission screen looks beyond basic tabs.
