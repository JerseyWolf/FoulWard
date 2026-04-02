Summary 1:

Here is a thorough, end-to-end description of everything Foul Ward is, based entirely on your project files and design documents.
Foul Ward — Complete Game Description
What the Game Is

Foul Ward is a real-time active fantasy tower defense game built in Godot 4 (GDScript), inspired by TAUR (Echo Entertainment, 2020) but deliberately improving on its frustrations. The player does not control a moving character. Instead, they operate a stationary Tower at the center of the map — aiming and firing weapons with the mouse — while an AI melee companion and additional allies fight autonomously around the Tower's perimeter. A hex grid of building slots rings the Tower. The player places and sells defensive structures in real time during combat. Spells are cast via hotkeys. All four of these activities — shooting, building, ally combat, spellcasting — happen simultaneously.

The core philosophy is: story-first, Pratchett-dark-humor tone, deterministic upgrades with no bad-outcome RNG, and a satisfying aiming system that rewards skill without punishing misses.
The Three Heroes
Florence — The Gunner (Player Character)

Florence is the player's avatar and narrative center. He is male, with a flower-themed name, described as practical and slightly worried about his plants. Florence does not move — he operates from the top of the Tower, aiming freely with the mouse cursor. Left-click fires the primary weapon (Crossbow at MVP), right-click fires the secondary weapon (Rapid Missile). Both can be fired simultaneously.

A soft auto-aim assist applies when the cursor is within a threshold angle or distance of a valid enemy at the moment of firing — the projectile tracks toward that target. Each weapon has a configurable per-shot miss chance; when a miss triggers, the projectile deviates by a random angle. Precision weapons have a tighter assist cone; area weapons have wider ones.

Florence cannot target flying enemies — that role belongs to anti-air buildings. If the Tower's HP reaches zero, the campaign battle ends in defeat.
Arnulf Falkenstein IV — The Warrior (Melee AI Companion)

Arnulf is present in every single battle from the start, requires no configuration, and cannot be permanently stopped. His state machine cycles: IDLE → CHASE → ATTACK → DOWNED → RECOVERING → IDLE. He always chases the enemy closest to the Tower center (not to himself), with a patrol radius of ~55 world units in the current implementation.

His defining mechanical quirk: when his HP hits zero, he collapses, takes a drink, a rage buff activates, and he automatically recovers to 50% HP after 3 seconds. This cycle repeats unlimited times per mission. He has a kill counter that charges a frenzy mode (rapid attacks for several seconds) — currently tracked but not yet activated in MVP.

He also gets progressively drunk per wave: slower movement, hits harder. A between-wave action sobers him up at resource cost. His drunkenness is visible on the character model and animations. The between-mission hub shows him slouched in an Emperor of Mankind-style throne, passed out, bottle nearby, while other characters are active around him.

Arnulf's weapons start with a shovel and become increasingly absurd as the campaign progresses. He has his own separate research tree branch. Some of his activated abilities are secretly Sybil casting on him — played for comedy. She can friendly-fire him, and he reacts with dialogue.
Sybil the Witch — The Spell Support

Sybil is a stationary spell-caster on the Tower, an outside contractor who cooperates professionally with Florence and Arnulf. Her personality is cryptic and unsettling — "but it doesn't always land. That's the joke." Her character is canonically based on a geology major; her entire magical aesthetic is rocks, earth, time manipulation.

She has her own regenerating mana pool and up to 4 hotbar spell slots:

    Shockwave — Battlefield-wide AoE, rocks erupt from the ground (earthy, grounded visual)

    Tower Shield — Tower is invincible for 10 seconds (emergency defensive)

    Time Stop — Freezes all enemies. JoJo "Za Warudo" inspired — distinct wob-wob sound effect, expanding crystalline sphere covers the battlefield, vanishes like a shockwave. Marked as a stretch goal due to complex implementation

    TBD — Fourth slot open for future design

Before each mission, the player selects one passive ability from Sybil's unlocked passives. She is soul-linked to the Tower — if it falls, she falls. Narratively, she is responsible for teleporting the Tower between territories between missions, and she provides pre-mission enemy intel via a divination ball.
The Tower

The Tower is a destructible structure at the scene center. Florence and Sybil both operate from it. It has:

    Visible damage states — cracks, fire, leaning before collapse

    An HP bar displayed at all times on the HUD

    Visual upgrades — grows taller and gains decorations per campaign progression

    A 24-slot hex grid in MVP (spec calls for 60 in the final version) surrounding it

Combat — What a Battle Looks Like

Every battle takes place on a map tied to the territory being contested that day. The Tower is fixed at center. Enemies spawn from all directions simultaneously with no fixed lanes and pathfind toward the Tower.
Waves

Each day has a configured number of waves (basewavecount). In MVP there are 3 waves per mission, 5 missions total, ramping up across the campaign. In the full 50-day campaign the wave count ramps from 5 (Day 1) to 10 (Day 25+), and each wave's enemy count, HP, and damage scale with per-day multipliers defined in DayConfig resources:

    Enemy HP multiplier scales roughly +2% per day from 1.0 at Day 1 to ~1.98 at Day 50

    Enemy damage multiplier scales ~+1.5% per day

    Gold reward multiplier scales ~+1% per day

A 30-second wave warning horn plays before each wave, with a UI indicator. Gold is awarded immediately on each enemy kill — floating gold text appears.
Build Mode

During combat, the player can press a hotkey to enter Build Mode. Time slows to 10% while in Build Mode (configurable in accessibility settings). The player clicks a hex slot to open a radial menu and place or sell a building. Buildings cost gold earned during the current battle. Selling returns most or all of the gold (low friction to encourage experimentation). Buildings cannot be walked through by enemies — they are solid physics objects enemies must navigate around, creating emergent funneling behavior.

Buildings operate automatically once placed. Each building can be configured with a targeting priority (closest, highest HP, flying, etc.). Some maps have special terrain hex slots with unique mechanics (hilltop range bonus, map-specific barracks, forge damage aura).
Damage System

The game uses a full damage type × armor type matrix:
Damage Type	Visual	Strong Against	Weak Against
Physical	Grey sparks	Light armor	Heavy armor, shields
Fire	Orange flames	Structures, undead	Wet/stone enemies
Magical	Purple/blue	Bypasses armor	Magically shielded
Poison	Green cloud DoT	Spreads in masses	Undead (immune, dark humor)

Armor types include: Unarmored (full damage), Heavy Armor (resists Physical, weak to Magical), Undead (immune to Poison, extra damage from Fire), and Flying (immune to ground AoE, requires anti-air buildings).

Status effects — burning, poisoned, slowed, infected — are a separate DoT layer applied on top of raw damage with duration-based tick behavior. Burn refreshes and retains the highest total damage when reapplied. Poison stacks up to a cap, with stacking increasing damage per tick.
Collision and Physics

All entities use solid collision — enemies cannot walk through each other, through Tower structures, through buildings, or through terrain objects. Ground enemies are blocked by physical terrain; flying enemies use a separate navigation layer and ignore ground obstacles but are still blocked by other flying entities. Projectiles collide with the first valid target unless they have a piercing property.
Enemy Factions
Free Campaign: Orc Raiders

Dark humor tone — bumbling but dangerous, tribal and escalating:

    Orc Grunt — Basic melee infantry

    Orc Brute — Heavy armored melee

    Orc Archer — Ranged unit

    Orc Berserker — Fast, light unit

    Goblin Firebug — Fire-based, likely area effect or status

    Goblin Swarm — 20 fodder units spawned at once

    Goblin Saboteur — Stealth, sets fires

    Orc Shaman (Boar Rider) — Status-inflicting

    Orc Siege Troll — Ranged boulder thrower (AoE)

    Orc Wolf Rider — Fast mounted unit

    Orc Warboss — Mini-boss; when killed, orcs scatter

    Orc Warchief — Campaign final boss; monologues too long

Plague Cult (also present in default mixed faction)

    Plague Zombie — Immune to Poison; infects buildings

    Bat Swarm — Flying unit

Infinite Mode / Future Campaign: Undead

    Skeleton Warrior — Reassembles unless destroyed by fire/holy damage

    Shambling Zombie — Infects buildings

    Ghoul — Fast, ignores Arnulf unless attacked

    Banshee — Silences Florence's weapon

    Bone Archer — Ranged

    Necromancer — Resurrects fallen enemies mid-wave

    Death Knight — Blocks frontal projectiles

    Wight — Drains Arnulf's rage meter

    Lich Apprentice — Mini-boss, counters Sybil's time magic

    Bone Colossus — Late-game boss, assembles from fallen enemies and grows larger

Faction Structure in Code

Each faction is a FactionData.tres resource with a weighted roster of FactionRosterEntry sub-resources defining: enemy type, spawn weight, min/max wave index eligibility, and tier. Higher-tier enemies gain weight as the wave index grows. Three built-in faction paths are registered: defaultmixed, orcraiders, plaguecult.
Mini-Bosses and Campaign Boss

Named mini-bosses appear on milestone days (Days 10, 20, 30, 40 in the 50-day campaign) with elevated stats and at least one unique ability. The current MVP has resources for:

    Plague Cult Mini-Boss (plaguecultminiboss.tres)

    Orc Warlord Mini-Boss (orcwarlordminiboss.tres)

    Final Boss (finalboss.tres)

After a mini-boss is defeated, the CampaignManager is notified via notifyMiniBossDefeated(bossId). If canDefectToAlly is true on their MiniBossData resource, a defection offer is injected into the mercenary pool — the player can recruit the defeated mini-boss as a hero ally.

The Day 50 campaign boss is a multi-phase encounter. If the player defeats it, the campaign ends in victory. If they fail, the boss marks itself as an active threat (finalbossActive = true) and conquers a random held territory on the next day. On Day 51+, the boss appears again alongside stronger forces (synthetic DayConfig is generated dynamically). Each subsequent failed attempt increases gold rewards — failure is never a dead end but has genuine world-map consequences.
Between-Mission Screen (The Hub)

After every battle the player enters a between-battle hub screen. The current MVP is a text-based screen with tabs. The final version presents all characters visually with Hades-style dialogue triggering on interaction.

The hub has the following stations, each managed by a named character:
The Shop (The Wagon)

A different local merchant per campaign — they have reactive commentary between missions. The shop sells:

    New buildings for the hex grid

    Alternative weapons for Florence

    One-use battle consumables (e.g., Mana Draught, Arrow Tower voucher)

    Gear for named allies

MVP shop has four items: tower repair, building repair, mana draught, and arrow tower voucher. Inventory partially rotates every 2–3 missions. There is a carry limit on consumables (e.g., max 3 flasks) and an emergency section for expensive gold sinks. The shop catalog is entirely data-driven via shopdata.tres.
Weapon Upgrade Station

Managed by the Weapons Engineer character. The player pays gold and/or resources to increase a weapon's level. The outcome is always an improvement — both minimum and maximum of the damage range increase by defined amounts. No random outcomes exist. Cost and damage values per level per weapon are defined in WeaponData.tres resources.
Research Tree

Managed by the Spell and Research Specialist. Funded by the secondary resource (Research Material — blue). MVP has 6 research nodes. The full design has 6 separate tree branches:

    Florence's Weapons

    Arnulf's Weapons

    Sybil's Spells & Passives

    Base Structures

    Mercenaries

    Special Units

Structural weapon upgrades (clip size, piercing, projectile speed, secondary on-hit effects) live in the Research Tree as a sub-branch. Research unlocks are permanent within a campaign. The respec system provides 3 free respecs per campaign; additional respecs cost gold from the emergency shop section.
Enchanting

Managed by the Weapon Enchanter character. Enchantments add affinity properties to weapons. Affinity types: fire, magic, poison, holy, blunt, and others. Each affinity gives a damage multiplier bonus against weak enemy types and a penalty against resistant ones. Each weapon has one active enchantment slot per slot type (e.g., one elemental slot, one power slot). Enchantments are mutually exclusive per slot. Removing and replacing enchantments happens here, costing gold and optionally crafting materials dropped by enemies. The system is fully data-driven via EnchantmentData.tres resources. Enchantment state resets on new game.
Mercenary Recruitment

Managed by the Military Commander character. Three categories:

    Named mercenaries — individual characters with personalities and upgrade paths

    Mob units — palette-swapped squads, randomly named (player can rename)

    Campaign hero mercs — 1–2 per campaign with unique upgrade paths

A morale system affects effectiveness (attack speed, accuracy, melee speed) but not desertion. Named mercs are incapacitated for multiple missions if killed. Mob units cannot permanently die — they're incapacitated for several missions and always return. Up to 2 allies can be active per day (maxActiveAlliesPerDay = 2 in code).

The CampaignManager generates daily mercenary offers from a MercenaryCatalog.tres, filtered by day range, ownership exclusion, and a cap of 3 offers per day. The AutoSelectBestAllies function scores offers using a weighted formula combining role alignment (per strategy profile), cost efficiency, and roster diversity.
World Map

A hand-drawn illustrated fantasy map (old map aesthetic — mountains, forests) showing all territories. Color coding:

    Green — player-controlled (easy)

    Yellow — contested (medium)

    Red — enemy-controlled (hard)

The 50-day main campaign has 6 named territories defined in maincampaignterritories.tres:

    heartlandplains (Days 1–10)

    blackwoodforest (Days 11–20)

    ashenswamp (Days 21–30)

    ironridge (Days 31–40)

    outercity (Days 41–50)

Each territory has a terrain type (PLAINS, FOREST, SWAMP, MOUNTAIN, CITY, OTHER) and passive bonuses (flat gold per day, percent gold bonus, research material, reduced enchanting costs, etc.). Terrain type determines the battle map's visual appearance and may impose movement speed modifiers on ground enemies.

When the final boss starts conquering after Day 50, their advance is shown visually on the map. If multiple territories are threatened simultaneously, the player chooses which to defend.
Mission Briefing

Before each battle a briefing screen presents: territory terrain, incoming wave summary, special day conditions, and a short narrative framing from Florence. It acknowledges stakes — boss appearance, lost territories, mini-boss expectations.
Currencies
Currency	Color	Earned By	Spent On
Gold	Yellow	Enemy kills (immediate)	Shop, weapon upgrades, enchanting, building
Building Material	Grey	Post-mission reward (+3 per win)	Building placement and upgrades
Research Material	Blue	Post-mission reward (+2 per win), territory bonuses	Research Tree only

Base gold reward after a mission win is 50 × mission_number, plus flat/percent territory bonuses. Starting gold at game start is 1,000.
The Florence Meta-State System

FlorenceData is a persistent object tracking cross-campaign statistics:

    totalDaysPlayed, totalMissionsPlayed, missionFailures, bossAttempts

    hasUnlockedResearch, hasRecruitedAnyMercenary

    runCount (increments per run for repeated dialogue variation)

These values are readable by the DialogueManager via DialogueManager.resolveStateValue("florence.missionFailures") — feeding directly into dialogue condition filtering.
Dialogue System (Hades Model)

Each character has a pool of DialogueEntry resources. Each entry contains: unique string ID, character ID, text body, priority integer, conditions dictionary, played boolean, and optional chain-next-entry ID.

DialogueManager filters each character's pool by current game state conditions (day number range, last battle outcome, specific enemy first-seen, item purchased, gold level, research unlocked, relationship threshold, chain completion, etc.). It selects the highest-priority unplayed entry, marks it played, and resets played flags when all entries are exhausted.

Story beat entries override the priority system entirely. Multi-part arcs are chained — completing one entry sets a state flag unlocking the next. Dialogue can also trigger mid-battle for events like an enemy type appearing for the first time, Tower HP going critically low, Arnulf hitting a high kill count, a building being destroyed, or a spell being cast for the first time.
Campaign Structure in Full

    50 days = 50 battles

    The campaign is non-linear for territory selection

    Mini-boss milestone days: 10, 20, 30, 40

    Final boss: Day 50

    After campaign completion: star difficulty system unlocks — Normal (1★), Veteran (2★, harder composition), Nightmare (3★, remixed enemies + modified bosses + unique cosmetic rewards)

    Chronicle of Foul Ward — persistent illustrated tome tracking deeds across all campaigns. Milestones unlock Chronicle Perks. Players choose 3 perks before starting any new campaign. Example perks: Arnulf's Flask (extra rage charge), Sybil's Foresight (one free respec), Florence's Aim (first weapon starts at rank 2), Veteran Mercs (mob units start at higher morale)

SimBot — Automated AI Playtester

SimBot is a built-in automated playtesting system accessible headlessly. It follows a strategy profile resource (e.g., ALLYHEAVYPHYSICAL, ANTIAIRFOCUS, SPELLFOCUS, BUILDINGFOCUS, BALANCED). Each profile has a small randomization factor so repeated runs aren't identical. SimBot logs every battle outcome to structured JSON/CSV: gold earned/spent, enemies killed by type, Tower HP remaining, buildings destroyed, spells cast, damage by weapon type, wave clear times.

SimBot is invoked via CLI: godot --headless -- --simbotprofile=balanced --simbotruns=5 --simbotseed=42.
Cursor MCP Tools — What Cursor Uses Automatically

The project ships a .cursormcp.json with five active MCP servers:
MCP Server	What Cursor Uses It For
godot-mcp-pro	Read the scene tree, validate scripts without errors, run the project, capture debug output, take screenshots, inject input events
gdai-mcp-godot (GDAI)	Read Godot's error console in real time, inspect node state at runtime, drive the game loop by calling public methods
sequential-thinking	Multi-step reasoning for architecture planning and complex debugging chains
filesystem-workspace	Read/write project files directly — GDScript, .tres resources, Markdown docs, JSON/CSV logs
GitHub MCP	Commit, branch, PR creation, issue tracking directly from Cursor sessions

When Cursor implements a new feature, the workflow is: write the code → use godot-mcp-pro to validate the scene tree matches expectations → use GDAI to check the error console → run headless tests via GdUnitCmdTool.gd → confirm the main scene smoke test passes → only then mark the task complete. The mcp-godot-workflow.mdc Cursor rule enforces this order automatically.
Technical Stack and Testing

    Engine: Godot 4.6, GDScript throughout, Forward renderer

    Test framework: GdUnit4 — 289 test cases, 0 failures at last full run

    Headless test command: godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests/

    Main scene smoke test: tools/smokemainscene.sh

    All content in .tres resource files — no hardcoded gameplay values in scripts

    Two maintained index files: INDEXSHORT.md (compact, fits one LLM context window) and INDEXFULL.md (full method/signal documentation for every autoload and resource)

The autoload architecture uses a SignalBus as the single registry for all cross-system communication — over 40 typed signals covering combat, economy, game state, waves, shop, research, build mode, enchantments, territories, bosses, and the Florence meta-state. No game logic is tangled with UI code or input handling — SimBot can drive the entire game loop by connecting to signals and calling public methods with zero UI interaction.

Summary 2:
Here is a comprehensive, detailed description of everything Foul Ward is and has, pulled from all documents.
FOUL WARD — Complete Game Description
What It Is

Foul Ward is an active fantasy tower defense game built in Godot 4, inspired directly by TAUR (Echo Entertainment, 2020). The player does not control a moving character. Instead, they sit at the center of a battlefield controlling a stationary Tower, aim and shoot with the mouse, manage a surrounding hex grid of defensive buildings, cast spells with hotkeys, and watch AI-controlled allies fight automatically — all simultaneously in real time. The core loop is direct-aim shooting + strategic building placement + passive ally combat + spellcasting all firing at once.
The Campaign Structure
50-Day Main Campaign

The game's primary campaign runs 50 days, each day being one battle. The difficulty escalates linearly — by Day 50, enemy HP is ~98% higher and enemy damage is ~73% higher than Day 1, while gold rewards are ~49% richer. Mini-boss milestone days occur at Days 10, 20, 30, and 40. Day 50 is the final boss encounter.
The Boss Loop — Failure is Never a Dead End

If the player loses on Day 50, the campaign boss conquers one of the player's held territories. The boss then appears every subsequent day alongside stronger forces — harder fights, but richer rewards. This continues until the player either wins or loses all territories. Failure always funds further upgrades; it never ends the game outright.
Short Campaign

A 5-day short campaign also exists for testing and onboarding. Its day names include "Rotting Fields", "Blighted Road", "Cursed Bridge", "Siege at Dawngate", and "Foul Ward — Last Stand".
Endless Mode

A third mode — Endless — lets the player select any unlocked map and fight indefinitely with scaling difficulty, no narrative, and no campaign constraints. It is the primary environment for SimBot automated balance testing.
The Map & Territories
Five Named Territories

The main campaign world contains five named territories, each with distinct terrain, passive bonuses, and visual appearance:
Territory	Terrain	Passive Bonus	Starting Ownership
Heartland Plains	Plains	+5 flat gold/day	Player-held
Blackwood Forest	Forest	+3 flat gold + 5% gold bonus	Contested
Ashen Swamp	Swamp	+12% gold bonus	Contested
Iron Ridge	Mountain/Mine	+15 flat gold/day	Contested
Outer City	City/Walled	+12 flat gold/day	Contested

The Tower teleports to whichever territory is being contested each day. Holding territories provides passive income; losing them cuts it. When the boss begins advancing after Day 50, the map shows their conquest visually. If multiple territories are threatened, the player chooses which to defend.
Terrain Types

Each territory's terrain type affects the battle map's visual appearance and enemy pathfinding — terrain is implemented as a swappable geometry + navmesh layer over the same base battle scene, so all scripts work identically across all terrains. Ground enemies can be funneled by terrain and buildings; flying enemies use a separate navigation layer not blocked by ground obstacles.
The Battle Scene — What Gameplay Looks Like
The Tower (Player Avatar)

The Tower is fixed at the center of the map. The player aims by moving the mouse and fires with:

    Left mouse button — Primary weapon (crossbow)

    Right mouse button — Secondary weapon (rapid missile)

Both can be fired simultaneously. The Tower has a health pool; reaching zero ends the battle in defeat.
Auto-Aim System

Aiming is designed to feel satisfying rather than punishing. When the cursor is within a threshold angle or distance of a valid target at the time of firing, the projectile tracks toward that target — a soft auto-aim assist. Precision weapons have a tighter assist cone; area weapons have wider cones. Each weapon also has a miss chance percentage — when a miss triggers, the projectile deviates by a random angle. Upgrading a weapon always reduces miss chance and increases the damage range minimum and maximum, never making the weapon worse.
Waves and Enemies

Enemies spawn from multiple directions simultaneously with no fixed lanes. They pathfind toward the Tower and attack it. Enemies use solid collision — they cannot walk through each other, through buildings, or through terrain. This creates emergent funneling behavior. Wave count per day ramps from 5 waves on Day 1 to 10 waves from Day 15 onward.
The Hex Grid (24 Slots)

A ring of 24 hex slots surrounds the Tower. During battle the player presses B or Tab to enter Build Mode, then clicks slots to open the Build Menu and place or sell buildings using gold earned during the current battle. Buildings operate automatically once placed and cannot be walked through by enemies.
The Eight Buildings
Building	Cost	Damage Type	Notes
Arrow Tower	50g / 2 mat	Physical	Ground only, upgradeable
Fire Brazier	60g / 3 mat	Fire + DoT burn	3s burn DoT on hit, upgradeable
Magic Obelisk	80g / 4 mat	Magic	Ground only, upgradeable
Poison Vat	55g / 2 mat	Poison + DoT	5s poison DoT, upgradeable
Ballista	100g / 5 mat	Physical	High single-hit, research-locked
Archer Barracks	90g / 4 mat	Physical	Research-locked, deploys archer allies
Anti-Air Bolt	70g / 3 mat	Physical	Air targets only, research-locked
Shield Generator	120g / 6 mat	—	Defensive utility, research-locked

The Enemies & Factions
Three Factions (Campaign One)

The first campaign features three enemy factions:

    DEFAULTMIXED — Equal-weight mix of all six enemy types, used for early days

    ORC RAIDERS (factionid: ORCRAIDERS) — Orc-heavy roster, with the Gorefang Warlord as mini-boss

    PLAGUE CULT (factionid: PLAGUECULT) — Undead/fire/flyer mix, with the Herald of Worms as mini-boss; the final boss Archrot Incarnate belongs to this faction

Six Enemy Types
Enemy	Armor	Notes
Orc Grunt	Unarmored	Basic melee runner
Orc Brute	Heavy Armor	Slow, high HP melee
Goblin Firebug	Unarmored	Fast melee, fire immune
+ 3 additional types	Various	Flying and ranged variants

The Damage Matrix

The game uses a full 4×4 damage type × armor type matrix. Damage types: Physical, Fire, Magic, Poison. Each enemy's armor type multiplies incoming damage accordingly. Status effects (burning, poisoned, slowed, infected) are a separate layer applied on top with duration-based ticking behavior.
Mini-Bosses and the Final Boss

    Gorefang Warlord (Orc Raiders): 400 HP, 32 damage, 110 gold reward

    Herald of Worms (Plague Cult): 450 HP, 35 damage, 3-phase, 120 gold reward

    Archrot Incarnate (Final Boss, Day 50): 5,000 HP, 80 damage, 3-phase encounter, 2,000 gold reward

Defeating a mini-boss can result in their troops defecting and the mini-boss themselves potentially joining as an ally — the Defected Orc Captain is one such ally data resource.
The Allies
Arnulf — Permanent Melee Companion

Arnulf is always present from campaign start. He is a unique melee companion with 200 HP, 5.0 movement speed, 25 attack damage, and a 55-unit patrol radius. His state machine runs: IDLE → PATROL → CHASE → ATTACK → DOWNED → RECOVERING — after being knocked down, he recovers for 3 seconds and returns to full health. He fights automatically, cannot be commanded, and scales with between-battle upgrades.
Additional Allies

The generic ally roster includes:

    Mercenary Melee (90 HP, 12 dmg, melee) — hirable

    Mercenary Ranged (70 HP, 14 dmg, range 10) — hirable

    Mercenary Support (80 HP, 8 dmg) — optional

    Anti-Air Scout (65 HP, 11 dmg, range 9, targets flying only, FLYINGFIRST priority)

    Hired Archer (70 HP, 14 dmg, range 10)

    Defected Orc Captain (140 HP, 18 dmg, unique, from mini-boss defection)

Allies have targeting priorities: CLOSEST, LOWEST_HP, HIGHEST_HP, FLYING_FIRST.
Spells

Spells are hotkey-bound with immediate battlefield effects, governed by a shared mana pool or individual cooldowns. Implemented spells include:

    Shockwave — AoE damage (Space bar), hits flying enemies

    Slow Field — Zero direct damage, control spell; slows enemies in area

    Arcane Beam — Directed magic damage

    Tower Shield — Defensive buff on the Tower

New spells are unlocked through the Research Tree and are entirely data-driven.
Between-Mission Hub — The Hub Screen

After each battle the player enters the between-mission hub where all progression happens. Each system is managed by a named character who is visually present in the hub and triggers dialogue when interacted with.
The Six Hub Characters
Character ID	Role	Manages
COMPANIONMELEE (Arnulf)	Melee companion	Fights every battle; hub dialogue
SPELLRESEARCHER (Sybil)	Spell/Research specialist	Spell Research Tree branch
WEAPONSENGINEER	Weapons craftsperson	Weapon level upgrades, building research
ENCHANTER (Enchantress)	Weapon enchanter	Enchanting system
MERCHANT	Shop trader	Item shop
MERCENARYCOMMANDER (Mercenary Captain)	Military commander	Troop recruitment, defected ally assignment

The central protagonist is Florence — not a hub character but the player's voice. All dialogue and narrative is filtered through her perspective. She has a FlorenceData resource tracking meta-state counters like total days played, battles won/lost, and mission milestones, which gate her dialogue entries.
The Between-Mission Screen Tabs

The BetweenMissionScreen has six tabs:

    World Map — Territory status, passive bonuses, boss advance visualization

    Shop — Rotating item inventory, consumables, alternate weapons, building blueprints, ally gear

    Research — Research Tree with branches: Tower, Buildings, Allies, Spells, Army

    Buildings — Building-specific upgrades

    Weapons — Weapon level upgrades (always deterministic improvements, never random)

    Mercenaries — Hire from daily rotating offers; manage defected allies

The Dialogue System (Hades Model)

Dialogue is modeled on Hades by Supergiant Games. Each character has a pool of DialogueEntry resources. The DialogueManager filters that pool by current game state conditions at every interaction — day range, last battle outcome, first enemy type seen, items purchased, research unlocked, gold level, relationship tier, and more. The highest-priority unplayed entry that passes all conditions is displayed. Essential story beat entries override priority entirely. Multi-part story arcs chain via a chain_next_id pointer.

Relationship values per character are tracked from −100 to +100, divided into named tiers. Relationship only ever increases. Higher relationship unlocks deeper arc dialogue entries. The RelationshipManager autoload applies affinity deltas when tracked SignalBus events fire (e.g., a specific spell cast, a mini-boss killed, gold spent with the merchant).
Mission Briefing

Before each battle a briefing screen presents the territory terrain, incoming wave summary, special day conditions (mini-boss expected, boss returning), and a short narrative framing by Florence.
Weapon Progression
Level Upgrades

Weapon levels are purchased at the Weapons Engineer station. Each level upgrade always increases both the minimum and maximum of the weapon's damage range. The outcome is entirely deterministic — no random upgrade results, no chance of a bad outcome. This was a deliberate improvement over TAUR's frustrating random forge system.
Weapon Enchantments

Enchantments add damage affinity to a weapon — fire, magic, poison, holy, blunt, etc.. An enchanted weapon gets bonus damage multipliers against weaknesses and penalties against resistances. Enchantments are mutually exclusive per weapon slot and are applied, removed, or swapped at the Enchanter hub character. The system is fully data-driven.
Structural Upgrades via Research

The Research Tree includes structural weapon upgrades that change behavior, not just raw numbers: increased clip size, piercing property, projectile speed changes, secondary on-hit effects.
SimBot — Automated AI Playtester

SimBot is a built-in headless AI that plays the game autonomously for balance testing, driven entirely through manager autoloads without the full game UI. It follows StrategyProfile data resources — three profiles exist:

    BALANCED_DEFAULT — Mixed buildings, moderate spells, inner ring preference

    GREEDY_ECON — Cheap early towers, minimal upgrades and spells, saves gold aggressively

    HEAVY_FIRE — Fire Brazier/Ballista/Magic Obelisk bias, aggressive Shockwave usage

Each profile has a small randomization factor so repeated runs are not identical but remain strategically consistent. SimBot logs every battle to structured CSV files: gold earned/spent, enemies killed by type, Tower HP remaining, buildings destroyed, spells cast, damage by weapon type, wave clear times. The logs can be parsed externally for balance analysis, and SimBot can run batches of days or entire full campaigns.
MCP Tools — What Cursor Uses Automatically

Cursor is integrated with two MCP servers that give it direct Godot access without the developer copy-pasting anything:
Tool	Server	Status	What It Does
get_scene_tree	gdai-mcp-godot	✅ Working	Returns full scene hierarchy
get_godot_errors	gdai-mcp-godot	✅ Working	Returns error log output
get_scene_file_content	gdai-mcp-godot	✅ Working	Returns raw .tscn content
get_project_info	gdai-mcp-godot	✅ Working	Project metadata
view_script	gdai-mcp-godot	✅ Working	Script content viewer
sequential_thinking	sequential-thinking	✅ Available	Single structured reasoning tool
163 editor tools	godot-mcp-pro	✅ Available	Full editor integration suite
query_project_knowledge	foulward-rag	⚠️ Not configured	Hybrid BM25+semantic RAG search over codebase
get_recent_simbot_summary	foulward-rag	⚠️ Not configured	Balance log analysis

The RAG pipeline (foulward-rag) was built in Prompt 18 and is architecturally ready but not yet wired into .cursormcp.json — that is a pending task.
Art Pipeline

Placeholder art is generated programmatically. The PlaceholderIconGenerator creates 64×64 PNG icons from character/building/enemy names via an EditorPlugin. A Blender headless script (generate_placeholder_glbs_blender.py) batch-exports rigged blockout GLB models for all enemies, allies, buildings, bosses, and misc entities under res://art/generated/. The ArtPlaceholderHelper autoload resolves placeholder meshes, materials, and icons at runtime with fallback and caching, and generated assets take priority over primitives when present. A FUTURE_3D_MODELS_PLAN.md document outlines the production 3D roadmap with PhysicalBone3D and AnimationPlayer wiring notes.
Current Code Health

As of the most recent audit (Prompt 26, 2026-03-28), the test suite runs 525 test cases, 0 failures, 17 orphan nodes. The 78-item improvement backlog has 3 critical issues, 18 high, 32 medium, and 25 low priority items — all flagged resource placeholders are either intentional stubs or acceptable PLACEHOLDER_ACCEPTABLE fields awaiting narrative/tuning passes. The project has 58 test suites covering every major system from economy transactions to SimBot determinism to dialogue condition evaluation.

Summary 3:
Based on everything discussed across this entire conversation, here is my most thorough reconstruction of FOUL WARD as a product.
FOUL WARD — Complete Game Description
Core Concept & Genre

FOUL WARD is a tower defense RPG built in Godot 4. It sits at the intersection of tactical tower defense (like Into the Breach or Dungeon Warfare) and narrative RPG (like Darkest Dungeon or Wildermyth) — a game where the tactical combat layer is deeply entangled with a persistent campaign layer, character relationships, and faction politics. The tone is dark fantasy, leaning into a besieged-fortress aesthetic. You are defending something precious — a ward, a keep, a sanctified place — against waves of enemies that grow in intelligence and aggression across a campaign.

The game is not a pure wave-spam tower defense. Waves have composition, timing, and special conditions. The spaces between waves matter as much as the waves themselves.
Campaign Structure
The Overworld Map

The campaign is played across a hex-grid territory map. Each territory is a node that can be:

    Contested — enemies are actively pushing into it

    Held — under your control, generating economy bonuses

    Lost — fallen to enemy control, unlocking harder enemy compositions

    Special — contains a named location (a ruined chapel, a crossroads inn, a mine)

Territory control is not binary — there is a pressure system where enemy influence creeps across territories over time if you don't actively defend or push back. Losing a territory doesn't end the game but cascades: you lose economy, unlock harder enemy types, and may trigger narrative events.

The map has a fog of war component — you don't always know what's moving where until scouts report or enemies arrive. The campaign has a meta-turn structure: after each mission, time advances, territories shift, and you make strategic decisions about where to deploy your limited allies.
Campaign Modes

    Story Campaign — a structured arc with named characters, scripted events, and a definitive ending

    Endless Mode — a survival escalation on a single map, tracked on leaderboards, no narrative

Attempt Structure

The campaign uses a rolling save slot system — 5 save slots that rotate. Each new attempt is stored independently (attempt_1 through attempt_N). This is intentional: the game has roguelike elements and a failed campaign is a documented run you can review. The SaveManager orchestrates all of this, including slot rotation when the max is exceeded.
Between-Mission Screens
The Hub / Ward Screen

Between missions you are in the Ward — a persistent home base that visually reflects the health of your campaign. Buildings upgrade, allies move around, and NPCs have dialogue that responds to recent events.

Key interactive elements:

    The Shop (ShopManager) — buy consumables, upgrade materials, hire mercenaries

    The Research Tree (ResearchManager) — unlock passive bonuses, new building types, advanced spells. Nodes on the tree have prerequisites; unlocking one emits a signal that the DialogueManager listens to, potentially triggering character commentary

    The Roster — view your deployed allies, their stats, relationships, and current status

    The Map — zoom out to the territory hex map to make strategic decisions

    SimBot / Adviser Panel — the AI adviser (see below) gives contextual summaries of the strategic situation

Economy Screen

Gold flows from territory holdings and is spent at the shop, on research, and on mercenary contracts. EconomyManager handles all transactions with strict validation — every spend_gold call checks balance, every earn_gold call is logged. Economy bonuses flow from territories you control (implemented in TerritoryEconomyBonuses).
Dialogue Events

Some between-mission moments trigger dialogue sequences — voiced or text-based conversations between named characters. These are driven by DialogueManager, which evaluates condition keys like:

    gold_amount — triggers commentary if you're broke or flush

    research_unlocked_<id> — character reacts to a new research unlock

    arnulf_is_downed — specific dialogue if your tank ally is injured

    last_spell_cast — mages comment on recent combat magic use

Dialogue uses a .tres resource system for content, with placeholder text currently in many nodes awaiting a narrative pass.
Mission Structure / Combat
The Hex Grid

Combat takes place on a hex grid (HexGrid). The grid supports:

    Pathfinding for enemies — enemies navigate around obstacles and buildings

    Building placement — towers, walls, and support structures snap to hex cells

    Territory adjacency — the hex structure mirrors the overworld map logic

The grid is persistent in memory and has strict validity checks — attempting to place on an occupied or invalid cell is rejected gracefully (now with push_warning after the P27 assert cleanup).
Wave Structure

Waves are managed by WaveManager. Each wave has:

    A composition — specific enemy types, counts, and entry timing

    A countdown — a real-time timer before the next wave begins

    State awareness — the countdown pauses when you enter BUILD_MODE and resumes in COMBAT (implemented in P28's _on_game_state_changed stub)

    Special conditions — some waves have a "commander" unit, timed objectives, or environmental hazards

Waves do not just repeat with bigger numbers. Enemy compositions shift based on campaign state — if you've been holding certain territories, specific elite enemy types appear earlier.
Game States

GameManager maintains the authoritative game state enum:

    BUILD_MODE — you place buildings, spend gold, position allies

    COMBAT — waves are active, towers fire, enemies move

    PAUSED — game frozen, menus open

    GAME_OVER — tower fallen

    VICTORY — wave cleared

State transitions emit signals on SignalBus that all systems listen to.
Towers / Buildings

Buildings are the primary defense layer. BuildingBase is the parent class. Building types include:

    Damage towers — ranged attackers with varied projectile types (fire, frost, arcane)

    Slow/debuff structures — reduce enemy movement or apply status effects

    Economy buildings — generate gold passively

    Support buildings — buff adjacent towers or provide ally healing

    Walls / barriers — redirect enemy pathfinding

Buildings have:

    Upgrade paths — spend gold to advance through tiers

    Special abilities — unlocked at specific upgrade levels, defined in BuildingSpecials test coverage

    Health — buildings can be destroyed by enemies that reach them

The BuildMenu (ui/build_menu.gd) presents available buildings filtered by what's been unlocked via Research.
Projectile System

ProjectileBase handles all projectile behavior. Projectiles:

    Track a target or travel ballistically

    Apply damage on hit via DamageCalculator

    Can have elemental types — FIRE, FROST, ARCANE, PHYSICAL, and others

    Apply status effects (burn, slow, stun) based on type

DamageCalculator computes the final damage figure accounting for:

    Base damage

    Elemental multipliers — FIRE against UNDEAD has a specific multiplier (one of the RAG query test cases)

    Armor reduction

    Status effect modifiers

Enemies
EnemyBase

All enemies inherit from EnemyBase. Core properties:

    Health, armor, movement speed

    Element affinity/resistance

    Reward (gold on death)

    Pathfinding target (the ward itself)

Enemy Types

The game has a faction system — enemies belong to factions with distinct visual themes and mechanical identities:

    Undead — slow, high HP, weak to FIRE, sometimes resurrect

    Beasts — fast, low HP, ignore slow effects

    Cultists — ranged attackers, summon minions

    Constructs — high armor, immune to poison

Enemy data is defined in .tres resource files (EnemyData).
Enemy Pathfinding

EnemyPathfinding system handles navigation on the hex grid. Enemies dynamically reroute if their path is blocked by newly placed buildings or destroyed paths. The test suite has dedicated integration tests (test_enemy_pathfinding.gd) that validate rerouting behavior.
Mini-Bosses and Bosses

BossBase inherits from EnemyBase with additions:

    Phase transitions at HP thresholds

    Unique abilities that fire on phase change

    Named entry — bosses have names, intro animations, and sometimes dialogue

Mini-bosses are a special subcategory — test_mini_boss_defection.gd exists in the test suite, suggesting some mini-bosses can be recruited rather than killed under certain conditions, tying into the faction/relationship systems.
Ally System
AllyBase

Player-controlled or semi-autonomous characters that fight alongside towers. AllyBase defines:

    Stats (attack, defense, speed, health)

    Ability set

    Faction affiliation

    Relationship scores (see below)

Named Characters

The game has named characters including at minimum:

    Arnulf — a tank-type ally, referenced specifically in DialogueManager condition keys (arnulf_is_downed). His state directly affects available dialogue and potentially mission difficulty

    Florence — has a dedicated test file (test_florence.gd), suggesting she has unique mechanics or special interactions that required isolated test coverage

Mercenaries

The game has a mercenary system — temporary hires available between missions. The test suite covers:

    test_mercenary_offers.gd — what gets offered and under what conditions

    test_mercenary_purchase.gd — the transaction flow

    test_simbot_mercenaries.gd — how the AI adviser evaluates mercenary recommendations

Mercenaries have faction affiliations. Hiring from one faction may affect your relationship with another.
Relationship System

RelationshipManager is a persistent system tracking affinity scores between the player and each named character/faction. Key mechanics:
Affinity Tiers

Affinity is a numerical value with defined thresholds that map to named tiers (e.g., Hostile → Neutral → Friendly → Allied). The exact thresholds are stored in .tres config files. Tier transitions:

    Unlock new dialogue

    Change what mercenaries are available

    Affect mission modifiers (allied factions may send aid; hostile ones may ambush)

Affinity Events

Affinity changes in response to game events via SignalBus signals. Multiple events accumulate arithmetically — the relationship test coverage (test_relationship_manager_tiers.gd) validates exact threshold behavior and clamping at min/max values.
Save Persistence

RelationshipManager data is saved and restored through SaveManager — this was wired in Prompt 27 as a critical fix. Before that fix, all relationship progress was silently lost on save/load.
Enchantment System

EnchantmentManager handles persistent buffs that can be applied to buildings or allies. Enchantments:

    Are unlocked through Research

    Have costs paid in a secondary resource

    Can stack (with diminishing returns or hard caps)

    Persist across missions within a campaign attempt

Consumables

A consumable system allows single-use items to be deployed during combat or between missions. Test coverage in test_consumables.gd.
SimBot — The AI Adviser

SimBot is one of the most distinctive features — an in-game AI adviser that gives you strategic recommendations. It is not a passive hint system; it has profiles, logging, and safety constraints, suggesting it's a meaningful gameplay layer.
SimBot Features

    Profiles (test_simbot_profiles.gd) — different adviser personalities or specializations you can unlock/choose

    Mercenary recommendations (test_simbot_mercenaries.gd) — suggests hires based on your current roster gaps

    Strategic summaries — the RAG MCP tool get_recent_simbot_summary returns a summary of recent SimBot activity, meaning SimBot logs its own recommendations persistently

    Handlers (test_simbot_handlers.gd) — event-driven responses to game state changes

    Safety constraints (test_simbot_safety.gd) — explicit rules about what SimBot is and isn't allowed to recommend, suggesting it can be quite proactive

SimBot bridges the gap between the tactical layer and the strategic layer, helping less experienced players understand what decisions matter most.
Weapons

The game has a weapon system separate from buildings — likely for ally loadouts. test_weapon_structural.gd exists in the unit test suite, validating that weapon data structures are well-formed. Weapons likely have:

    Damage type

    Range

    Attack speed

    Special modifiers

UI Architecture
UIManager

ui/ui_manager.gd manages the overall UI state machine — which screens are visible, transitions between screens, and responding to GameManager state changes.
HUD

ui/hud.gd — the in-combat heads-up display. Shows:

    Current wave information

    Gold counter

    Tower health

    Active ally status

Build Menu

ui/build_menu.gd — presented during BUILD_MODE. Filtered by unlocked buildings, shows costs and previews.
Settings

SettingsManager handles audio, display, and gameplay preferences. Tested in test_settings_manager.gd.
MCP Tools Cursor Uses Automatically

When a Cursor session opens in this project, it has access to the following MCP (Model Context Protocol) tools without you doing anything:
Always Available (configured in .cursor/mcp.json)

    get_godot_errors — reads Godot's error log. Every prompt instructs the agent to check this before declaring done.

    run_script / bash tools — runs shell commands (test runners, grep, file operations)

    The gdai-mcp-godot server — the Godot-specific MCP integration for reading scene trees, querying node properties, and interacting with the running editor

Available When RAG Server Is Running (manually started)

    query_project_knowledge — semantic search over the indexed codebase, returning relevant code snippets and docs for any query

    get_recent_simbot_summary — returns a summary of recent SimBot adviser activity from the game's own logs

The RAG server lives at ~/LLM/rag_mcp_server.py running in a virtualenv at ~/LLM/rag_env/. It must be manually started (or configured as a launchd agent) before Cursor sessions can use it.
Test Infrastructure

The project has a mature three-tier test suite with 58 test files and ~522 test cases:
Test Tiers

    Unit tests (33 files) — pure logic, no scene instantiation, no timers. Run via run_gdunit_unit.sh (~65s due to engine startup overhead)

    Integration tests (~25 files) — instantiate scenes, use timers and await. Run via run_gdunit_quick.sh or the full suite

    Full suite — run_gdunit.sh (~4m20s sequential) or run_gdunit_parallel.sh (~2m45s, 8 parallel processes, 37% faster)

Key Test Areas

Every major system has dedicated tests. The coverage gap work from P26/P27/P28 focused on:

    RelationshipManager tier boundary behavior

    SaveManager slot rotation and round-trip save/load

    DialogueManager condition key responses

    WaveManager state-change handling

Orphan Tracking

GdUnit reports orphan nodes (leaked scene instances). Starting at 17 orphans, reduced to 6 after P27 cleanup, with P28 targeting 0.
Document Architecture

The project maintains rigorous documentation:
File	Purpose
docs/AGENTS.md	Standing orders for all AI agents — rules, tools, workflow
docs/INDEX_SHORT.md	Compact file map for fast navigation
docs/INDEX_FULL.md	Detailed file map with descriptions
IMPROVEMENTS_TO_BE_DONE.md	Living audit backlog — all known issues, prioritized
docs/ALL_AUDITS.md	Historical record of all audit sessions
docs/PROMPT_NN_IMPLEMENTATION.md	Log of every Cursor session's work

Every Cursor session must read AGENTS.md and INDEX_SHORT.md first, log its work to a new PROMPT_NN_IMPLEMENTATION.md, and update the indexes when files are created or renamed.
Current State of the Project (as of Prompts 27-28)

The project is in late pre-production / early vertical slice state. The infrastructure is production-grade — the test suite, save system, signal bus, and manager autoloads are all solid. The work in recent prompts has been hardening and filling gaps rather than building net-new systems. Key remaining gaps:

    Placeholder dialogue text in .tres files (needs a narrative/writing pass)

    Some stub functions in DialogueManager now implemented (P28)

    Research tree content may be sparse

    Territory map likely has placeholder level layouts

    SimBot profiles may have limited content beyond structural scaffolding

    Boss encounter content (phases, special abilities) extent is unclear

The architecture is ready to ship content into. The next major work phase would be content production — writing actual dialogue, designing specific wave compositions, building out the territory map with real missions, and giving the named characters meaningful arcs.

Summary 4:
This is a big one. Based on everything discussed across this entire conversation, here is the most thorough description I can assemble of Foul Ward as a complete game product.
Foul Ward — Complete Game Description
What Foul Ward Is

Foul Ward is a 3D real-time tower defense game built in Godot 4, with a dark medieval plague-fantasy aesthetic. The player defends a dying settlement called The Ward against waves of corrupted factions — orc raiders and plague cultists — across a campaign of connected territories. Between battles, the player manages resources, upgrades towers, reads faction lore, and makes strategic decisions on a world map. The game plays from a fixed isometric-style overhead camera, and the core loop is: survey the map → build towers before the wave → survive the wave → spend gold on upgrades → advance the campaign.
The Aesthetic and Setting

The world is late-medieval, dark, diseased, and crumbling. Stone towers draped in chain and crow-perch, swamp valleys choked with pale fog, ruined settlements with cracked archways and bone-scattered ground. The color palette is desaturated and earthy — rust oranges, moss greens, sickly yellows, ash greys — with glowing amber fire and sickly purple plague light as the only saturated elements. There are two enemy factions with distinct visual identities:

    Orc Raiders — rust-orange armor, crude iron weapons, loud and physical

    Plague Cult — bone-white robes, black-veined skin, eerie silence, green plague glow

The tone is grim but not grimdark. There is atmosphere, lore, and flavor text — not despair. The Ward has a cast of named defenders and a story.
Core Gameplay Loop
Pre-Wave Phase (Build Phase)

The player starts a mission with a fixed gold budget and a cleared map showing enemy spawn points, the goal crystal, the enemy path network, and available build pads. The player places towers on designated build pads before calling the first wave. Between waves they have the same opportunity.

    Towers can be placed, upgraded, or sold during the build phase

    The navmesh shows where enemies will walk

    Terrain features (bridges, gorges, swamp patches, cliff lines) are visible

    Build pads are explicitly marked — the player cannot build anywhere

Wave Phase

When the player starts a wave, enemies spawn from one or more entry points, path toward the goal crystal using Godot's NavigationAgent3D, and must be stopped before they reach it. Enemies:

    Move in real time

    Have visible health bars

    React to damage with hit-flash and stagger animations

    Slow down when moving through swamp terrain zones

    Path around obstacles, cliffs, and NavigationObstacles

    Die with ragdoll-like death effects

Multiple waves can be active simultaneously. Enemies have varied stats, movement speeds, and resistances. Killing enemies awards gold and XP.
Between-Wave Phase

A short pause between waves lets the player:

    Spend earned gold on new towers or upgrades

    View the next wave composition (a wave preview panel)

    Read enemy tooltips/lore

    Assess damage dealt and gold remaining

Towers

There are at least 8 tower types, each built from the modular kit system (base + top mesh + faction accent color via ShaderMaterial override). Every tower has:

    A TowerData resource defining stats, cost, upgrade path

    A BuildingData resource defining visual mesh IDs and accent color

    Up to 3 upgrade tiers (cost scales each tier)

    A targeting mode (nearest, first, last, strongest, farthest)

Tower Roster (Known)
Tower	Function	Notes
Arrow Tower	Single-target ranged, fast	Basic starting tower
Magic Obelisk	AoE magic damage, slow	Glass dome top, good vs groups
Fire Brazier	AoE burning DoT zone	Fire bowl top, fire VFX
Poison Vat	Poisons enemies, reducing armor	Green tint accent
Shield Generator	Buffs adjacent towers' armor	Flat roof, support role
Ballista	High damage, slow fire rate, long range	Ballista frame top
Archer Barracks	Spawns a small group of archer units	Cone roof, Orc faction counter
Lightning Rod	Chain lightning between nearby enemies	Magic Obelisk variant

Towers have level-of-detail art: placeholder kit meshes exist now, with Hyper3D Rodin-generated final art planned per FUTURE_3D_MODELS_PLAN.md §4.
Enemies

All enemies share a base EnemyBase scene with:

    CharacterBody3D + NavigationAgent3D

    HealthComponent with signals

    AnimationTree state machine (idle → walk → attack → die → stagger)

    Terrain multiplier stack (slowdown in swamp zones)

    Group membership "enemies" for collision filtering

    Death signal → gold drop → ragdoll/VFX

Enemy Roster (Planned)

Orc Raiders faction:

    Orc Grunt — standard melee humanoid, T-pose Mixamo rig

    Orc Berserker — faster, more damage, glass-cannon

    Orc Shieldbearer — tanky, blocks projectiles

    Orc Champion — mini-boss with a special attack

    Warchief Arnulf — named boss, zone-of-control aura

Plague Cult faction:

    Plague Cultist — slow humanoid, infects on hit

    Plague Zombie — shambling, large HP pool

    Bone Crawler — fast, low HP, in swarms

    Plague Abomination — large, shambling biped with AoE plague vomit

    High Cantor — caster enemy, buffs nearby cult units

All humanoid types go through the Mixamo pipeline: Rodin mesh → Mixamo browser upload → auto-rig → animation clips download → Godot FBX import → AnimationPlayer → AnimationTree.
Campaign and World Map

The campaign is structured around a territory map — a stylized overhead view of a region surrounding The Ward. Territories are nodes on a graph, connected by paths. The player conquers or defends territories day by day.
Territory Data

Each territory has a TerritoryData resource with:

    terrain_type (GRASSLAND, FOREST, SWAMP, RUINS, TUNDRA)

    faction assignment

    wave composition reference

    campaign difficulty modifier

    lore flavor text

Day/Night Cycle

The campaign uses a day counter. CampaignManager drives the loop:

    Show world map

    Player selects next territory

    _load_terrain() instantiates the correct terrain scene into TerrainContainer

    GameManager.start_mission_for_day() triggers

    Battle plays out

    Results screen → back to world map

World Map Screen

A 2D or stylized 3D overhead view showing:

    Territory nodes labeled with terrain type and faction

    Conquered territories (greyed, owned)

    Available territories (highlighted, attackable)

    The Ward node (home base, never directly attacked)

    Campaign day counter

    Gold reserve and persistent resource totals

Terrain and Levels
Terrain Types

Five biomes, each with a swappable PackedScene loaded by CampaignManager:
Terrain	Visual	Effect
GRASSLAND	Flat green ground, clear sky	None
FOREST	Dense tree props, dappled light	0.75× enemy speed
SWAMP	Pale fog, muddy ground, standing water	0.55× enemy speed via TerrainZone
RUINS	Cracked stone, broken columns, bone scatter	Destructible props rebake navmesh on death
TUNDRA	Snow-covered ground, ice patches	0.7× speed, ice = 1.2× speed

Each terrain scene contains:

    GroundMesh + StaticBody3D + ConcavePolygonShape3D

    NavigationRegion3D (registered with NavMeshManager autoload on load)

    TerrainZone Area3D nodes (where applicable)

    PropContainer (destructible + immovable props)

Level Structure

Every level scene (Level_*.tscn) contains:

text
LevelRoot
├── TerrainContainer       ← swapped per territory
├── SpawnPoints            ← 1–3 enemy entry nodes
├── GoalPoints             ← crystal/gate the enemies target
├── BuildPads              ← explicit tower placement slots
├── EncounterMarkers       ← wave trigger volumes
└── LevelDataBinder        ← connects LevelData resource

Elevation Features

Maps are mostly flat with special modular chunks for:

    Bridges — narrow crossing with cliff drop, strategic choke

    Gorge edges — impassable blocker, forces pathing through bridge

    Hill ramps — gentle elevation change, slower climb

    Ruined walls — partial blockers with destructible sections

Between-Mission Screens
Results Screen

After a battle:

    Gold earned

    Enemies killed (with icons)

    Towers built/upgraded

    Crystal HP remaining

    Stars awarded (0–3 based on performance)

    "Continue" → world map

Upgrade Screen

Between days, before selecting the next territory:

    Persistent upgrade tree (not tower-specific)

    Unlockable: new tower types, global passive buffs, defender abilities

    Costs Foul Gold (rare currency earned from bosses and territory bonuses)

Lore/Journal Screen

Accessible from world map:

    Codex entries for enemies unlocked on first encounter

    Territory descriptions

    Notes from named NPCs (the Ward's survivors)

    Art/illustration per entry

Named Characters
Defenders of The Ward

These characters appear in dialogue, lore text, and potentially as active unit abilities:

    Sister Margol — plague doctor, Ward medic, dry humor, tactical adviser

    Old Harruk — retired orc (reformed?), knows orc tactics, provides faction intel

    Warden Edith — commander of the Ward's walls, stoic, heavy armor

    The Architect — mysterious tower designer, provides upgrade unlock dialogue

    Arnulf (enemy) — orc Warchief, the narrative antagonist of Act 1

Enemy Named Units

Arnulf is the only named enemy in Act 1. Later acts may introduce a Plague Cantor named boss.
Cursor's Toolchain (What Runs Automatically)

Cursor operates with these MCP servers and tools active by default:
MCP Servers

    Godot MCP — reads and writes .tscn, .gd, .tres files, runs scripts in the Godot scene tree, reads node properties

    Blender MCP — executes Python bpy scripts inside Blender, triggers Hyper3D Rodin panel generation, exports GLB files to res://art/generated/

Automatic Behaviors Per AGENTS.md

    Reads AGENTS.md at the start of every session before touching any code

    Checks actual file paths against requested paths and adapts (as seen in every confirmation message)

    Writes TODO(ART-KIT):, TODO(TERRAIN):, TODO(ART-ANIM): comments per convention

    Updates FUTURE_3D_MODELS_PLAN.md with every new planned asset type

    Updates docs/INDEX_SHORT.md and docs/INDEX_FULL.md after every prompt

    Creates docs/PROMPT_NN_IMPLEMENTATION.md per session

    Appends to GdUnit4 allowlists in tools/run_gdunit_quick.sh and tools/run_gdunit_unit.sh

    Runs the full test suite before marking any prompt done

    0 failures required; exit 100/101 allowed per AGENTS warning/orphan rules

Test Infrastructure

    GdUnit4 — Godot-native unit/integration testing

    tests/unit/ — all unit tests

    tests/support/ — mock helpers like counting_navigation_region.gd

    tools/run_gdunit.sh, run_gdunit_quick.sh, run_gdunit_unit.sh, run_gdunit_parallel.sh

    544 test cases currently, growing with each feature

Code Architecture
Autoloads

    SignalBus — all cross-system signals (enemy events, terrain events, tower events, game state)

    CampaignManager — day loop, territory selection, terrain loading

    GameManager — mission start/end, wave management, crystal HP

    NavMeshManager — queued thread-safe navmesh rebaking

    SaveManager — persistent campaign state

Key Resource Types

    EnemyData — stats, mesh reference, faction

    TowerData — stats, cost, upgrade path

    BuildingData — base_mesh_id, top_mesh_id, accent_color

    TerritoryData — terrain_type, faction, wave config

    WaveData — enemy composition, timing, difficulty

Key Scripts

    enemy_base.gd — movement, health, terrain multiplier, animation state

    building_base.gd — tower placement, kit assembly, upgrade handling

    terrain_zone.gd — Area3D speed modifier with enemy group filter

    art_placeholder_helper.gd — get_building_kit_mesh(), GLB loading, fallback BoxMesh, accent application

Art Pipeline
Current State

All enemies and towers are placeholder geometry (capsules, BoxMesh fallbacks from kit system).
Planned Replacements

    Hyper3D Rodin — generates mesh + PBR textures from prompt inside Blender MCP

    Mixamo — browser-based humanoid auto-rig + animation clip download (manual step, ~10 min/enemy)

    Blender Geometry Nodes — terrain dressing, prop scatter, cliff variations (future)

Art Assets Tracked In

FUTURE_3D_MODELS_PLAN.md:

    §1–3: entity mesh generation prompts

    §4: modular building kit (12 pieces, Rodin prompt template)

    §5: terrain system (5 biomes, prop destruction, navmesh rebake)

    §6: enemy animations (Mixamo clip list per enemy)

What Is Fully Built and Working (As of This Conversation)
System	Status
System	Status
Types enum (all game types)	✅
SignalBus	✅
EnemyBase (movement, health, terrain speed)	✅
NavigationAgent3D pathfinding	✅
Terrain system (5 types, scene swap)	✅
TerrainZone speed modifier	✅
NavMeshManager (threaded rebake queue)	✅
Modular building kit (12 pieces, accent color)	✅
BuildingData (kit fields)	✅
ArtPlaceholderHelper (kit assembly, GLB fallback)	✅
AnimationTree state machine scaffolding (empty clips)	✅ (code wired)
Procedural limb fallback animation	✅ (code wired)
CampaignManager terrain loading	✅
TerritoryData terrain_type field	✅
Test suite (544 cases, 0 failures)	✅
FUTURE_3D_MODELS_PLAN.md §4 + §5	✅
Level authoring (LevelData, BuildPad, SpawnPoint, GoalPoint)	🔲 Next
Actual 3D enemy meshes (Rodin)	🔲 Next
Mixamo animation clips	🔲 Next
Forest / Ruins / Tundra terrain scenes	🔲 Next
Between-mission UI (results, upgrades, lore)	🔲 Future
World map screen	🔲 Future
Named character dialogue	🔲 Future
Sound/music	🔲 Future
The Three Most Important Next Steps

Based on everything above, the three highest-value things to build next are:

    Level authoring system — LevelData resource, SpawnPoint, GoalPoint, BuildPad, level validation script, and one playable test level (level_test_01.tscn)

    First real enemy mesh — one orc grunt through the full Rodin → Mixamo → Godot AnimationTree pipeline, proving the whole pipeline works end to end

    Basic results/between-wave UI — just enough to close the game loop: wave results panel, gold earned display, continue button

Once those three exist, Foul Ward is a playable, demonstrable game loop from title to end of mission.

Summary 5:Here is an exhaustive description of everything FOUL WARD contains and is designed to contain, based on all accumulated design documents and implementation work.
FOUL WARD — Full Game Description
High Concept

FOUL WARD is a 3D tower defense game built in Godot 4. You are defending Florence — a great stone tower — against a relentless Orc siege across a 50-day campaign. Each day is a self-contained battle of 10 waves. Between battles you manage a persistent economy: spending gold on research, weapon upgrades, mercenaries, and a shop. The central design tension is that you never have enough resources to do everything — every day you are making irreversible choices about what to build, what to ignore, and what to sacrifice.
The Battlefield
Florence

Florence is the object being defended — the literal ancient tower at the center of the map. She is not passive. Florence has her own weapons that auto-fire at enemies throughout combat:

    Crossbow — slow-firing, high single-target damage. The workhorse weapon. Upgradeable.

    Rapid Missile — fast-firing, lower per-hit damage, effective against swarms. Upgradeable.

Florence has an HP pool that persists across the entire campaign. Damage taken in battle carries over. If her HP reaches zero, the run ends. The final HP percentage at the end of Day 50 is the victory metric. Her weapons upgrade between missions using gold, making the weapon upgrade system one of the key between-mission decisions.
The Three-Ring Layout

Surrounding Florence are 24–36 tower slots arranged in three concentric rings. Each ring corresponds to a size class:
Ring	Size Class	Slot Count	Distance from Florence
Inner	LARGE	4–6	~6–8 units
Middle	MEDIUM	8–12	~12–16 units
Outer	SMALL	12–18	~20–26 units

Only towers of the matching size class can be placed in a given slot. Inner LARGE slots are expensive strategic anchors — each one is a major commitment. Outer SMALL slots are cheap, expendable, and plentiful. This naturally creates a layered defense geometry without the player having to think about it: big powerful centerpieces close to Florence, workhorse towers in the middle ring, cheap specialists and sacrificial units on the perimeter closest to the enemy.

Visual identity of each ring is distinct: gold/bronze hex borders for LARGE inner slots, silver for MEDIUM, copper/dull for SMALL. Slots the player can't yet afford anything for are dimmed.
Ring Rotation

Before each battle, the player can rotate the entire ring layout in 60° increments (0°, 60°, 120°, 180°, 240°, 300°). This is shown on a pre-battle setup screen that overlays the hex layout on top of the terrain. All slot world positions recompute based on the rotation offset, and navmesh obstacles update accordingly. This is the single most important pre-battle tactical decision: different terrain maps have choke points, hills, and enemy spawn positions at different angles, so rotating your formation to face the threat or protect vulnerable slots matters significantly.
Core Combat Loop
Build Phase and Combat Phase

Each of the 10 waves within a day follows the same rhythm:

    Build Phase — The wave hasn't started yet. The player can place new towers, upgrade existing towers, or sell towers for a partial gold refund. This is the tactical decision layer.

    Combat Phase — Enemies spawn from the map edges and walk toward Florence. Towers auto-fire. Florence's weapons auto-fire. The player can cast spells during combat using mana. When all enemies in the wave are dead or have reached Florence, the wave ends.

    Post-wave — Gold from kills is distributed. A brief pause before the next build phase begins.

The build phase between waves is where moment-to-moment strategy lives. Do you build a new tower now, or save for a more expensive one next wave? Do you upgrade your Arrow Tower for better DPS, or place a second one for better coverage?
Mana and Spells

Florence has a mana pool that regenerates during combat. The player can spend mana to cast spells — area damage, targeted nukes, or utility effects — aimed at enemy clusters. Spells are the player's active input during combat (towers auto-fire without player direction). Mana management is a meaningful micro-decision: spend it aggressively to clear dangerous enemies, or hold it in reserve for an emergency.
Tower System (36 Building Types)
The Three Size Classes

SMALL towers (12–20 in the game roster): Cheap, disposable specialists costing 30–60 gold and 0–1 building material. They deal 8–20 DPS and have 80–150 HP. Their purpose is to do one thing cheaply — a small anti-air cannon, a small poison applicator, a basic arrow tower. The many SMALL slots encourage experimentation. Losing one hurts less than losing a LARGE tower.

MEDIUM towers (roughly 8–12 in the roster): The workhorses at 80–150 gold and 2–4 material. 25–50 DPS, 200–400 HP. This is where most of the strategic variety lives. A MEDIUM fire tower, a MEDIUM summoner barracks, a MEDIUM magic obelisk — these define your mid-game.

LARGE towers (6–10 in the roster): Expensive strategic anchors at 200–400 gold and 5–10 material. 60–120 DPS, 500–1,000 HP. You'll have at most 4–6 LARGE slots per mission, and filling even one is a significant investment. Each LARGE tower should feel like a strategy-defining choice. A LARGE fire artillery piece, a LARGE summoner citadel, a LARGE aura broadcaster — these are the builds that define a run.
Damage Types

All towers deal one of four primary damage types (plus TRUE damage which bypasses all mitigation):

    PHYSICAL — Standard, effective against UNARMORED enemies, reduced against HEAVY armor

    MAGICAL — Effective against UNDEAD, reduced against certain resistant types

    FIRE — Bonus damage to FLYING units, strong DoT (ignite) potential

    POISON — DoT-based, weak per-hit but relentless; excellent against high-HP single targets

The damage matrix is a multiplier table (DamageType × ArmorType) that determines how much damage gets through. Players who diversify damage types can handle any enemy composition. Mono-damage strategies are efficient early but create hard counters in later waves.
Tower Roles

DPS towers — Pure offense in one damage type. Arrow Tower (physical), Fire Brazier (fire), Magic Obelisk (magic), Poison Vat (poison), Ballista (physical, high single-target), and many more.

Summoner towers — Don't deal damage themselves. Instead, they spawn squads of allied units that patrol the battlefield, intercept enemies, and physically block pathing. A summoner tower produces a leader unit (stronger) and optionally 1–3 follower units (weaker). The squad blocks enemies like terrain obstacles do — enemies have to path around or through them. This is the unique mechanic that separates FOUL WARD's spatial layer from most tower defense games.

Aura towers — Passive buffs that radiate in a radius. They don't fire at enemies. They amplify nearby towers. Aura categories include damage_pct (all damage output from nearby towers +15%), attack_speed_pct (fire rate up), armor_flat (towers in range take less damage), enemy_slow (enemies in range slowed). The stacking rule: same-category auras don't stack — only the strongest applies. Different-category auras stack freely.

Healer towers — Restore HP to nearby buildings and/or allied summons over time. Critical in long missions where towers accumulate damage from artillery-type waves. The heal_targets field specifies whether a healer restores "allies", "buildings", or "both".

Anti-air (AA) towers — Specialized to target FLYING enemies. Some towers are general-purpose with an AA mode; dedicated AA towers prioritize flying targets exclusively and deal bonus damage to the FLYING armor type.

Artillery towers — Slow-firing, high AoE (area-of-effect) damage. Effective against clusters of enemies. Usually MEDIUM or LARGE.
In-Mission Upgrades

Each tower has 2 upgrade levels (3 total states: base, level 1, level 2). Upgrades are purchased with gold during build phases. Each level improves one or more of: damage (+25% then +50% cumulative), fire rate (+20%), range (+15%). Level 1 costs 60% of the tower's build price; level 2 costs 100%. A fully upgraded MEDIUM tower that cost 100 gold to build costs 260 total.
Duplicate Cost Scaling

To prevent spamming a single tower type, each additional copy of the same tower type within a mission costs 8% more than the previous. The first Arrow Tower costs 40 gold; the sixth costs 56 gold. This is tracked per-mission and resets each day. It's gentle enough that 2–3 copies of a tower feel fine, but by copy 5+ the premium meaningfully nudges players toward diversification.
Enemy System (30 Orc Types)
Tiers

Enemies scale from T1 fodder to T5 boss-tier:
Tier	Label	HP Range	Speed	Gold Reward	Examples
T1	Fodder	40–80	4–6	5–10	Grunt, Skirmisher, Rat Swarm
T2	Standard	100–200	3–5	12–20	Raider, Orc Archer, Hound
T3	Elite	250–500	2–4	25–40	Shieldbearer, Berserker, Shaman
T4	Heavy	600–1,200	1.5–3	45–70	Troll, Ironclad Crusher, Ogre
T5	Boss-tier	1,500–5,000	1–2	100–200	Warlord's Guard, Spirit Champion
Enemy Roles

Melee core — Grunts, Raiders, Berserkers. The bulk of early waves. Shieldbearers have a physical shield that absorbs a flat amount of damage before HP is touched. The Berserker has a charge mechanic: when its HP drops below a threshold, it dashes forward at high speed, ignoring blocker summons briefly, and deals burst damage.

Swarm/rush — Skirmishers, Hounds, Rat Swarm. High speed, low HP. Designed to overwhelm anti-swarm defenses. Hounds move at speed 8–10 (extremely fast). The Rat Swarm is a cluster counted as one unit with very low individual HP. These enemies test AA-style small towers and AoE artillery.

Ranged/artillery — Orc Archers, Drummers, Siege Crew. The Siege Crew has a range that outranges MEDIUM towers — players either need LARGE towers or must rotate their ring to expose shorter-range towers to the flank. Artillery-type enemies deal direct damage to tower HP, making healer towers and building durability researches more valuable on heavy-artillery days.

Support/casters — The most tactically interesting enemies because they amplify everything around them:

    Plague Shaman — Offensive debuff; reduces tower damage output within an aura radius

    War Shaman — Offensive buff; increases nearby orc damage output

    Totem Carrier — Defensive aura; regenerates HP of nearby orcs

    Banner Seer — Passive speed and damage aura

    Hexbreaker — Dispels one active player aura or building shield on hit

Support enemies should be priority-killed but are often sheltered behind heavy melee units.

Heavy/special — Trolls have regeneration (HP ticks back up if not in combat recently). The Orc Saboteur attaches a "disabling bomb" to a building on reach, shutting it down for 3–5 seconds — countered by having blocker summons intercept it. The Orc Brood Carrier spawns 2–3 smaller units on death, forcing AoE investment. The Goblin Firebug explodes on death dealing AoE fire damage.

Flying enemies — Bat Swarms and Harpies. These units fly over ground obstacles and blocker summons entirely. Only towers with the can_target_flying flag or dedicated AA towers can hit them. Flying waves massively punish players who have ignored AA.

Anti-air ground units — The Orc Skythrower throws javelins that preferentially target air units. This counters players who rely on air summons as their primary DPS.
Armor Types

    UNARMORED — Takes full damage from all types

    HEAVY — Reduced physical damage, normal magical/fire

    UNDEAD — Weak to magical, resistant to physical and poison

    FLYING — Weak to fire, immune to ground melee

Wave Composition

Waves are generated from a point budget that scales with both day number and wave number within the day:

text
budget = 50 + (day × 8) + (wave × 5)
Day 1 Wave 1 = 63 pts → 8-12 T1 enemies
Day 50 Wave 10 = 500 pts → dangerous T1-T5 mix

Each wave has a type tag that constrains composition: RUSH (≥70% fast enemies), AIRSTRIKE (≥50% flying), ARTILLERY (≥40% ranged with long reach), HEAVY (≥50% high-HP), INVASION (mixed, no single type >30%), BOSS (fixed boss + escort). The wave generator fills the budget greedily from eligible enemies.
Allied Units
Arnulf

Arnulf is a named hero — the most powerful individual unit in the game. He starts at approximately 200 HP and 25 DPS, scaling upward with upgrades across the campaign. Arnulf fights on the battlefield independently, and his stats are the benchmark against which all summoned units are measured. Summoned units are individually weaker, but collectively valuable through their blocking role and numerical mass.
Summoned Squads

Summoner towers produce squads rather than single units. A squad consists of a leader (stronger, more HP) and 0–3 followers (weaker, die first). When the squad is wiped, the tower goes on a respawn cooldown (10–20 seconds) before summoning a fresh squad.

Three respawn behaviors exist:

    Mortal: Standard. Wipe → tower cooldown → resummon.

    Recurring: Auto-respawns after 5–10 seconds without tower input. Slightly weaker (-15% DPS) but reliable.

    Immortal: Cannot die — HP regens fully if not attacked for 3 seconds. But is_blocker = false (cannot physically block pathing) and deal only 50% damage. Mobile turrets, not walls.

The global summon cap is 20 active allied units at once. When at cap, summoner towers display "Summon Limit Reached" and go on cooldown until a unit dies.
Mercenaries

Mercenaries are hired between missions from a rotating pool of offers. They are persistent allied units (not summoned per-wave) who fight throughout the campaign. Unlike summoner-tower squads, mercs are individual named units with roles: MELEE_FRONTLINE, RANGED_SUPPORT, etc. They are recruited using gold from the between-mission shop.
Between-Mission Systems

After each day's battle ends, the player enters the between-mission screen — a strategic layer with five distinct systems.
Research Tree

The Research Tree contains 24 nodes (6 base + 18 added in Prompt 50). Nodes are unlocked using Research Material (a separate currency from gold). Every node does exactly one thing and has prerequisites. The tree gates tower access aggressively:

    Day 1: ≤8 towers available

    Day 25: ~60% of towers unlocked

    Day 40: All towers available

Node types include:

    Tower unlocks — the only way to access most towers

    Global damage bonuses — e.g., "+10% FIRE damage from all sources"

    Tower behavior upgrades — "Summoner: mortal → recurring respawn", "Aura radius +30%"

    Building durability — "+50% HP to all MEDIUM towers"

    Squad expansions — "LARGE summoner gains +1 follower"

Nodes are one-time permanent unlocks, not leveled. The tree forces strategic commitment: do you rush fire-damage nodes early and go all-in on that damage type? Or diversify into summon infrastructure?
Weapon Upgrades

Florence's crossbow and rapid missile can be permanently leveled up using gold. These upgrades persist for the entire remaining campaign. The crossbow and rapid missile have separate upgrade paths, and the player chooses which to prioritize — single-target power vs. swarm-clearing speed.
Shop

A rotating shop offering consumable and one-time-purchase items. Items include things like one-use wave-clearing bombs, temporary gold multipliers, bonus building material drops, and HP restoration for Florence. The shop's exact item pool was not fully detailed in current design documents but the category exists and SimBot tracks gold spent there separately.
Mercenary Recruitment

A rotating roster of mercenary offers — typically 2–3 candidates shown per day. Each candidate has a role type, stats, and a gold hiring cost. Once hired, mercs join the roster permanently and fight in all future missions. The roster refreshes on a schedule, so a desirable merc may not be available again if passed up.
Enchanting

The enchanting system allows the player to apply special effects to weapons or towers — effects that go beyond the standard stat upgrades. The system exists in the design and data structures but is the least-developed between-mission system currently, flagged as too complex for SimBot automated testing in its current form. It is designed as a lategame investment system where rare enchantment items (from the shop or drops) are applied to specific buildings for exotic effects.
Economy

Three currencies run in parallel:

Gold — The primary currency. Earned from killing enemies (T1: 5–10 gold, T5: 100–200 gold). Spent on tower placement, in-mission upgrades, weapon upgrades, mercenary hiring, shop items, and enchanting. Gold income scales: ~600 total on Day 1, ~1,500 on Day 25, ~3,000 on Day 50. A SMALL tower is affordable from wave 1–2 income. A LARGE tower requires saving across 6+ waves.

Building Material — A scarcer resource, rate-limited by design. Required alongside gold for placing MEDIUM and LARGE towers. SMALL towers cost 0–1 material; LARGE towers cost 5–10. Material is the real cap on how many strong towers you can deploy — not gold.

Research Material — Earned by completing waves and days. Spent exclusively on the Research Tree. Cannot be used for anything else. Its scarcity creates the real pacing of tower unlocks: even if you have 24 Research nodes available, you won't afford them all quickly.
Campaign Structure

The campaign runs for exactly 50 days. There is no branching map — the 50 days are linear. What varies per day is the wave configuration: the day determines which wave types appear, what enemies are in the pool (certain elite enemies don't appear until Day 10+, T5 boss-tier enemies not until Day 30+), and the overall budget scale. Boss days at specific milestones (design suggests milestone days at specific intervals) spawn a BOSS wave: a fixed boss unit with a defined escort composition, treating the boss fight as a scripted encounter rather than a random pool.

Florence's HP carries over between days — damage taken does not heal passively. The Research Tree and healer towers/shop items are the only HP recovery mechanisms.

A full campaign simulated at 10× speed takes approximately 2–5 minutes per run (50 days × 10 waves). Human playthroughs are intended to take significantly longer due to decision time.
Build UI — The Tower Wheel

When a player clicks on an empty tower slot, a radial build wheel appears showing only towers that fit that slot's size class — never all 36 at once. Within the wheel, towers are organized clockwise by role:

    12 o'clock: DPS towers

    2 o'clock: Summoner towers

    4 o'clock: Support/Aura towers

    6 o'clock: Healer towers

    8 o'clock: AA-specialist towers

    10 o'clock: Utility/Special towers

Visual encoding on each tower card:

    Border color = damage type (gray=physical, red=fire, blue=magic, green=poison)

    Background pattern = role (solid=DPS, striped=summoner, dotted=support)

    Opacity = 100% if affordable+unlocked, 50% if unlocked but can't afford, 25% if locked

    Small badge = ✦ for AA, ☗ for blocker summons, ◎ for aura

Hovering a tower shows name, cost, 3 role tags, and headline stats (DPS + range for DPS towers; squad size for summoners; radius for auras). Detail mechanics and lore are in a separate inspect panel.

For occupied slots, the wheel transforms into an upgrade/sell wheel: upgrade (top), inspect (right), sell (bottom) — with the sell amount showing the refund value.
What Is Not Yet Runtime-Wired

Everything in the data layer (.tres files for all 36 buildings, 30 enemies, 5 allies, 18 research nodes) exists and is populated. The following systems are data-only and need runtime implementation in upcoming prompts:

    Summoner tower squad spawning behavior

    Aura tower radius broadcasting and stat pipeline integration

    Healer tower radius ticking

    Enemy special mechanics (charge, shield, on_death_spawn, disable_building, regen, anti_air)

    BuildPhaseManager controlling the phase transition

    Ring rotation in the pre-battle setup screen

    CombatStatsTracker signal connections (partially done, pending damage_dealt emitters)

    Full wave composition using point_cost + wave_tags from EnemyData



Summary 5:

Here is an exhaustive description of everything FOUL WARD contains and is designed to contain, based on all accumulated design documents and implementation work.
FOUL WARD — Full Game Description
High Concept

FOUL WARD is a 3D tower defense game built in Godot 4. You are defending Florence — a great stone tower — against a relentless Orc siege across a 50-day campaign. Each day is a self-contained battle of 10 waves. Between battles you manage a persistent economy: spending gold on research, weapon upgrades, mercenaries, and a shop. The central design tension is that you never have enough resources to do everything — every day you are making irreversible choices about what to build, what to ignore, and what to sacrifice.
The Battlefield
Florence

Florence is the object being defended — the literal ancient tower at the center of the map. She is not passive. Florence has her own weapons that auto-fire at enemies throughout combat:

    Crossbow — slow-firing, high single-target damage. The workhorse weapon. Upgradeable.

    Rapid Missile — fast-firing, lower per-hit damage, effective against swarms. Upgradeable.

Florence has an HP pool that persists across the entire campaign. Damage taken in battle carries over. If her HP reaches zero, the run ends. The final HP percentage at the end of Day 50 is the victory metric. Her weapons upgrade between missions using gold, making the weapon upgrade system one of the key between-mission decisions.
The Three-Ring Layout

Surrounding Florence are 24–36 tower slots arranged in three concentric rings. Each ring corresponds to a size class:
Ring	Size Class	Slot Count	Distance from Florence
Inner	LARGE	4–6	~6–8 units
Middle	MEDIUM	8–12	~12–16 units
Outer	SMALL	12–18	~20–26 units

Only towers of the matching size class can be placed in a given slot. Inner LARGE slots are expensive strategic anchors — each one is a major commitment. Outer SMALL slots are cheap, expendable, and plentiful. This naturally creates a layered defense geometry without the player having to think about it: big powerful centerpieces close to Florence, workhorse towers in the middle ring, cheap specialists and sacrificial units on the perimeter closest to the enemy.

Visual identity of each ring is distinct: gold/bronze hex borders for LARGE inner slots, silver for MEDIUM, copper/dull for SMALL. Slots the player can't yet afford anything for are dimmed.
Ring Rotation

Before each battle, the player can rotate the entire ring layout in 60° increments (0°, 60°, 120°, 180°, 240°, 300°). This is shown on a pre-battle setup screen that overlays the hex layout on top of the terrain. All slot world positions recompute based on the rotation offset, and navmesh obstacles update accordingly. This is the single most important pre-battle tactical decision: different terrain maps have choke points, hills, and enemy spawn positions at different angles, so rotating your formation to face the threat or protect vulnerable slots matters significantly.
Core Combat Loop
Build Phase and Combat Phase

Each of the 10 waves within a day follows the same rhythm:

    Build Phase — The wave hasn't started yet. The player can place new towers, upgrade existing towers, or sell towers for a partial gold refund. This is the tactical decision layer.

    Combat Phase — Enemies spawn from the map edges and walk toward Florence. Towers auto-fire. Florence's weapons auto-fire. The player can cast spells during combat using mana. When all enemies in the wave are dead or have reached Florence, the wave ends.

    Post-wave — Gold from kills is distributed. A brief pause before the next build phase begins.

The build phase between waves is where moment-to-moment strategy lives. Do you build a new tower now, or save for a more expensive one next wave? Do you upgrade your Arrow Tower for better DPS, or place a second one for better coverage?
Mana and Spells

Florence has a mana pool that regenerates during combat. The player can spend mana to cast spells — area damage, targeted nukes, or utility effects — aimed at enemy clusters. Spells are the player's active input during combat (towers auto-fire without player direction). Mana management is a meaningful micro-decision: spend it aggressively to clear dangerous enemies, or hold it in reserve for an emergency.
Tower System (36 Building Types)
The Three Size Classes

SMALL towers (12–20 in the game roster): Cheap, disposable specialists costing 30–60 gold and 0–1 building material. They deal 8–20 DPS and have 80–150 HP. Their purpose is to do one thing cheaply — a small anti-air cannon, a small poison applicator, a basic arrow tower. The many SMALL slots encourage experimentation. Losing one hurts less than losing a LARGE tower.

MEDIUM towers (roughly 8–12 in the roster): The workhorses at 80–150 gold and 2–4 material. 25–50 DPS, 200–400 HP. This is where most of the strategic variety lives. A MEDIUM fire tower, a MEDIUM summoner barracks, a MEDIUM magic obelisk — these define your mid-game.

LARGE towers (6–10 in the roster): Expensive strategic anchors at 200–400 gold and 5–10 material. 60–120 DPS, 500–1,000 HP. You'll have at most 4–6 LARGE slots per mission, and filling even one is a significant investment. Each LARGE tower should feel like a strategy-defining choice. A LARGE fire artillery piece, a LARGE summoner citadel, a LARGE aura broadcaster — these are the builds that define a run.
Damage Types

All towers deal one of four primary damage types (plus TRUE damage which bypasses all mitigation):

    PHYSICAL — Standard, effective against UNARMORED enemies, reduced against HEAVY armor

    MAGICAL — Effective against UNDEAD, reduced against certain resistant types

    FIRE — Bonus damage to FLYING units, strong DoT (ignite) potential

    POISON — DoT-based, weak per-hit but relentless; excellent against high-HP single targets

The damage matrix is a multiplier table (DamageType × ArmorType) that determines how much damage gets through. Players who diversify damage types can handle any enemy composition. Mono-damage strategies are efficient early but create hard counters in later waves.
Tower Roles

DPS towers — Pure offense in one damage type. Arrow Tower (physical), Fire Brazier (fire), Magic Obelisk (magic), Poison Vat (poison), Ballista (physical, high single-target), and many more.

Summoner towers — Don't deal damage themselves. Instead, they spawn squads of allied units that patrol the battlefield, intercept enemies, and physically block pathing. A summoner tower produces a leader unit (stronger) and optionally 1–3 follower units (weaker). The squad blocks enemies like terrain obstacles do — enemies have to path around or through them. This is the unique mechanic that separates FOUL WARD's spatial layer from most tower defense games.

Aura towers — Passive buffs that radiate in a radius. They don't fire at enemies. They amplify nearby towers. Aura categories include damage_pct (all damage output from nearby towers +15%), attack_speed_pct (fire rate up), armor_flat (towers in range take less damage), enemy_slow (enemies in range slowed). The stacking rule: same-category auras don't stack — only the strongest applies. Different-category auras stack freely.

Healer towers — Restore HP to nearby buildings and/or allied summons over time. Critical in long missions where towers accumulate damage from artillery-type waves. The heal_targets field specifies whether a healer restores "allies", "buildings", or "both".

Anti-air (AA) towers — Specialized to target FLYING enemies. Some towers are general-purpose with an AA mode; dedicated AA towers prioritize flying targets exclusively and deal bonus damage to the FLYING armor type.

Artillery towers — Slow-firing, high AoE (area-of-effect) damage. Effective against clusters of enemies. Usually MEDIUM or LARGE.
In-Mission Upgrades

Each tower has 2 upgrade levels (3 total states: base, level 1, level 2). Upgrades are purchased with gold during build phases. Each level improves one or more of: damage (+25% then +50% cumulative), fire rate (+20%), range (+15%). Level 1 costs 60% of the tower's build price; level 2 costs 100%. A fully upgraded MEDIUM tower that cost 100 gold to build costs 260 total.
Duplicate Cost Scaling

To prevent spamming a single tower type, each additional copy of the same tower type within a mission costs 8% more than the previous. The first Arrow Tower costs 40 gold; the sixth costs 56 gold. This is tracked per-mission and resets each day. It's gentle enough that 2–3 copies of a tower feel fine, but by copy 5+ the premium meaningfully nudges players toward diversification.
Enemy System (30 Orc Types)
Tiers

Enemies scale from T1 fodder to T5 boss-tier:
Tier	Label	HP Range	Speed	Gold Reward	Examples
T1	Fodder	40–80	4–6	5–10	Grunt, Skirmisher, Rat Swarm
T2	Standard	100–200	3–5	12–20	Raider, Orc Archer, Hound
T3	Elite	250–500	2–4	25–40	Shieldbearer, Berserker, Shaman
T4	Heavy	600–1,200	1.5–3	45–70	Troll, Ironclad Crusher, Ogre
T5	Boss-tier	1,500–5,000	1–2	100–200	Warlord's Guard, Spirit Champion
Enemy Roles

Melee core — Grunts, Raiders, Berserkers. The bulk of early waves. Shieldbearers have a physical shield that absorbs a flat amount of damage before HP is touched. The Berserker has a charge mechanic: when its HP drops below a threshold, it dashes forward at high speed, ignoring blocker summons briefly, and deals burst damage.

Swarm/rush — Skirmishers, Hounds, Rat Swarm. High speed, low HP. Designed to overwhelm anti-swarm defenses. Hounds move at speed 8–10 (extremely fast). The Rat Swarm is a cluster counted as one unit with very low individual HP. These enemies test AA-style small towers and AoE artillery.

Ranged/artillery — Orc Archers, Drummers, Siege Crew. The Siege Crew has a range that outranges MEDIUM towers — players either need LARGE towers or must rotate their ring to expose shorter-range towers to the flank. Artillery-type enemies deal direct damage to tower HP, making healer towers and building durability researches more valuable on heavy-artillery days.

Support/casters — The most tactically interesting enemies because they amplify everything around them:

    Plague Shaman — Offensive debuff; reduces tower damage output within an aura radius

    War Shaman — Offensive buff; increases nearby orc damage output

    Totem Carrier — Defensive aura; regenerates HP of nearby orcs

    Banner Seer — Passive speed and damage aura

    Hexbreaker — Dispels one active player aura or building shield on hit

Support enemies should be priority-killed but are often sheltered behind heavy melee units.

Heavy/special — Trolls have regeneration (HP ticks back up if not in combat recently). The Orc Saboteur attaches a "disabling bomb" to a building on reach, shutting it down for 3–5 seconds — countered by having blocker summons intercept it. The Orc Brood Carrier spawns 2–3 smaller units on death, forcing AoE investment. The Goblin Firebug explodes on death dealing AoE fire damage.

Flying enemies — Bat Swarms and Harpies. These units fly over ground obstacles and blocker summons entirely. Only towers with the can_target_flying flag or dedicated AA towers can hit them. Flying waves massively punish players who have ignored AA.

Anti-air ground units — The Orc Skythrower throws javelins that preferentially target air units. This counters players who rely on air summons as their primary DPS.
Armor Types

    UNARMORED — Takes full damage from all types

    HEAVY — Reduced physical damage, normal magical/fire

    UNDEAD — Weak to magical, resistant to physical and poison

    FLYING — Weak to fire, immune to ground melee

Wave Composition

Waves are generated from a point budget that scales with both day number and wave number within the day:

text
budget = 50 + (day × 8) + (wave × 5)
Day 1 Wave 1 = 63 pts → 8-12 T1 enemies
Day 50 Wave 10 = 500 pts → dangerous T1-T5 mix

Each wave has a type tag that constrains composition: RUSH (≥70% fast enemies), AIRSTRIKE (≥50% flying), ARTILLERY (≥40% ranged with long reach), HEAVY (≥50% high-HP), INVASION (mixed, no single type >30%), BOSS (fixed boss + escort). The wave generator fills the budget greedily from eligible enemies.
Allied Units
Arnulf

Arnulf is a named hero — the most powerful individual unit in the game. He starts at approximately 200 HP and 25 DPS, scaling upward with upgrades across the campaign. Arnulf fights on the battlefield independently, and his stats are the benchmark against which all summoned units are measured. Summoned units are individually weaker, but collectively valuable through their blocking role and numerical mass.
Summoned Squads

Summoner towers produce squads rather than single units. A squad consists of a leader (stronger, more HP) and 0–3 followers (weaker, die first). When the squad is wiped, the tower goes on a respawn cooldown (10–20 seconds) before summoning a fresh squad.

Three respawn behaviors exist:

    Mortal: Standard. Wipe → tower cooldown → resummon.

    Recurring: Auto-respawns after 5–10 seconds without tower input. Slightly weaker (-15% DPS) but reliable.

    Immortal: Cannot die — HP regens fully if not attacked for 3 seconds. But is_blocker = false (cannot physically block pathing) and deal only 50% damage. Mobile turrets, not walls.

The global summon cap is 20 active allied units at once. When at cap, summoner towers display "Summon Limit Reached" and go on cooldown until a unit dies.
Mercenaries

Mercenaries are hired between missions from a rotating pool of offers. They are persistent allied units (not summoned per-wave) who fight throughout the campaign. Unlike summoner-tower squads, mercs are individual named units with roles: MELEE_FRONTLINE, RANGED_SUPPORT, etc. They are recruited using gold from the between-mission shop.
Between-Mission Systems

After each day's battle ends, the player enters the between-mission screen — a strategic layer with five distinct systems.
Research Tree

The Research Tree contains 24 nodes (6 base + 18 added in Prompt 50). Nodes are unlocked using Research Material (a separate currency from gold). Every node does exactly one thing and has prerequisites. The tree gates tower access aggressively:

    Day 1: ≤8 towers available

    Day 25: ~60% of towers unlocked

    Day 40: All towers available

Node types include:

    Tower unlocks — the only way to access most towers

    Global damage bonuses — e.g., "+10% FIRE damage from all sources"

    Tower behavior upgrades — "Summoner: mortal → recurring respawn", "Aura radius +30%"

    Building durability — "+50% HP to all MEDIUM towers"

    Squad expansions — "LARGE summoner gains +1 follower"

Nodes are one-time permanent unlocks, not leveled. The tree forces strategic commitment: do you rush fire-damage nodes early and go all-in on that damage type? Or diversify into summon infrastructure?
Weapon Upgrades

Florence's crossbow and rapid missile can be permanently leveled up using gold. These upgrades persist for the entire remaining campaign. The crossbow and rapid missile have separate upgrade paths, and the player chooses which to prioritize — single-target power vs. swarm-clearing speed.
Shop

A rotating shop offering consumable and one-time-purchase items. Items include things like one-use wave-clearing bombs, temporary gold multipliers, bonus building material drops, and HP restoration for Florence. The shop's exact item pool was not fully detailed in current design documents but the category exists and SimBot tracks gold spent there separately.
Mercenary Recruitment

A rotating roster of mercenary offers — typically 2–3 candidates shown per day. Each candidate has a role type, stats, and a gold hiring cost. Once hired, mercs join the roster permanently and fight in all future missions. The roster refreshes on a schedule, so a desirable merc may not be available again if passed up.
Enchanting

The enchanting system allows the player to apply special effects to weapons or towers — effects that go beyond the standard stat upgrades. The system exists in the design and data structures but is the least-developed between-mission system currently, flagged as too complex for SimBot automated testing in its current form. It is designed as a lategame investment system where rare enchantment items (from the shop or drops) are applied to specific buildings for exotic effects.
Economy

Three currencies run in parallel:

Gold — The primary currency. Earned from killing enemies (T1: 5–10 gold, T5: 100–200 gold). Spent on tower placement, in-mission upgrades, weapon upgrades, mercenary hiring, shop items, and enchanting. Gold income scales: ~600 total on Day 1, ~1,500 on Day 25, ~3,000 on Day 50. A SMALL tower is affordable from wave 1–2 income. A LARGE tower requires saving across 6+ waves.

Building Material — A scarcer resource, rate-limited by design. Required alongside gold for placing MEDIUM and LARGE towers. SMALL towers cost 0–1 material; LARGE towers cost 5–10. Material is the real cap on how many strong towers you can deploy — not gold.

Research Material — Earned by completing waves and days. Spent exclusively on the Research Tree. Cannot be used for anything else. Its scarcity creates the real pacing of tower unlocks: even if you have 24 Research nodes available, you won't afford them all quickly.
Campaign Structure

The campaign runs for exactly 50 days. There is no branching map — the 50 days are linear. What varies per day is the wave configuration: the day determines which wave types appear, what enemies are in the pool (certain elite enemies don't appear until Day 10+, T5 boss-tier enemies not until Day 30+), and the overall budget scale. Boss days at specific milestones (design suggests milestone days at specific intervals) spawn a BOSS wave: a fixed boss unit with a defined escort composition, treating the boss fight as a scripted encounter rather than a random pool.

Florence's HP carries over between days — damage taken does not heal passively. The Research Tree and healer towers/shop items are the only HP recovery mechanisms.

A full campaign simulated at 10× speed takes approximately 2–5 minutes per run (50 days × 10 waves). Human playthroughs are intended to take significantly longer due to decision time.
Build UI — The Tower Wheel

When a player clicks on an empty tower slot, a radial build wheel appears showing only towers that fit that slot's size class — never all 36 at once. Within the wheel, towers are organized clockwise by role:

    12 o'clock: DPS towers

    2 o'clock: Summoner towers

    4 o'clock: Support/Aura towers

    6 o'clock: Healer towers

    8 o'clock: AA-specialist towers

    10 o'clock: Utility/Special towers

Visual encoding on each tower card:

    Border color = damage type (gray=physical, red=fire, blue=magic, green=poison)

    Background pattern = role (solid=DPS, striped=summoner, dotted=support)

    Opacity = 100% if affordable+unlocked, 50% if unlocked but can't afford, 25% if locked

    Small badge = ✦ for AA, ☗ for blocker summons, ◎ for aura

Hovering a tower shows name, cost, 3 role tags, and headline stats (DPS + range for DPS towers; squad size for summoners; radius for auras). Detail mechanics and lore are in a separate inspect panel.

For occupied slots, the wheel transforms into an upgrade/sell wheel: upgrade (top), inspect (right), sell (bottom) — with the sell amount showing the refund value.
What Is Not Yet Runtime-Wired

Everything in the data layer (.tres files for all 36 buildings, 30 enemies, 5 allies, 18 research nodes) exists and is populated. The following systems are data-only and need runtime implementation in upcoming prompts:

    Summoner tower squad spawning behavior

    Aura tower radius broadcasting and stat pipeline integration

    Healer tower radius ticking

    Enemy special mechanics (charge, shield, on_death_spawn, disable_building, regen, anti_air)

    BuildPhaseManager controlling the phase transition

    Ring rotation in the pre-battle setup screen

    CombatStatsTracker signal connections (partially done, pending damage_dealt emitters)

    Full wave composition using point_cost + wave_tags from EnemyData

Summary 6:
# FOUL WARD â Project State Inventory
## Reference document for Claude Opus audit pass
### Compiled: 2026-03-31 | Based on Prompts 4, 5, 50, 10, 11, 12 + Design Analysis (paste.txt)
 
---
 
## HOW TO USE THIS DOCUMENT
 
This is a reference inventory of what the codebase **should** contain based on
conversation history. Opus should treat every entry as a hypothesis to verify, not a
fact. For each section marked **[VERIFY]**, open the relevant file and confirm whether
the item actually exists as described. Where gaps are found, note them in your manual.
 
Legend:
  â  Confirmed implemented (prompt output said [ALL TASKS COMPLETE])
  đś  Data-only stub (field/resource exists, no runtime logic wired)
  â ď¸  Assumed/inferred (mentioned but not explicitly confirmed in output)
  â  Not yet started (planned in roadmap, no prompt written yet)
  đ  [VERIFY] â Needs a file read to confirm
 
---
 
## PART 1 â AUTOLOADS
 
### combat_stats_tracker.gd â
Location: autoloads/combat_stats_tracker.gd
 
Confirmed fields:
  - _mission_id: String
  - _run_label: String
  - begin_run(mission_id: String, run_label: String) -> void
  - end_run() -> void  [flushes all CSVs]
  - _reset_internal_state() -> void
 
CSV output path pattern:
  user://simbot/runs/{mission_id}_{timestamp}/
 
Files written per run:
  - building_summary.csv
    Columns: building_id, display_name, role_tags, cost_gold_paid,
             total_damage_dealt, damage_per_gold, ally_deaths,
             mission_id, run_id, run_label
  - wave_summary.csv
    Columns: wave_number, enemies_leaked, florence_damage_taken,
             mission_id, run_id, run_label
  - event_log.csv  [debug mode only â may not be present in all builds]
 
Signals connected [VERIFY exact signal names]:
  - SignalBus.enemy_killed
  - SignalBus.building_placed
  - SignalBus.building_sold
  - SignalBus.building_upgraded
  - SignalBus.resource_changed
  - SignalBus.wave_cleared   [or wave_completed â verify exact name]
  - SignalBus.ally_spawned
  - SignalBus.ally_killed
  - SignalBus.building_dealt_damage  [added in Prompt 4]
 
Known gaps:
  - damage_dealt signal (the full per-source signal from design doc Â§7.3.4)
    is NOT yet wired â only building_dealt_damage exists.
  - Per-armor-type damage breakdown is in design doc but likely not in CSVs yet.
  - enemy_damage_dealt signal (Â§7.3.4 Appendix C) does NOT exist yet.
 
---
 
### sim_bot.gd â
Location: scripts/sim_bot.gd  [VERIFY â may be autoloads/sim_bot.gd]
 
Confirmed methods:
  - run_balance_sweep() -> void
      Runs mission_01 Ă ["balanced", "summoner_heavy", "artillery_air"]
  - _run_single_balance_run(mission_id, loadout_name) -> void
  - _place_loadout(defs: Array) -> void
      Uses HexGrid.place_building(slot, type) [VERIFY exact API]
  - _auto_run_waves_until_end(mission_id, loadout_name) -> void
  - _balance_resolve_mission() â wave acceleration logic [VERIFY name]
  - run_single() â pre-existing from before Prompt 12
  - run_batch() â pre-existing from before Prompt 12
 
Pre-existing (before Prompt 12):
  - StrategyProfile resource support
  - placement via HexGrid.place_building(slot, type)
 
Added in Prompt 12:
  - run_balance_sweep() entry point
  - begin_run / end_run calls to CombatStatsTracker
  - research unlock step before placement
 
AutoTestDriver flag:
  --simbot_balance_sweep  â  runs run_balance_sweep() headless and quits
  [VERIFY where AutoTestDriver lives â likely scripts/auto_test_driver.gd]
 
Known gaps:
  - Only tests mission_01; no multi-mission sweep configured
  - _wait_for_wave_or_mission_end() uses inner func syntax â [VERIFY this
    compiles in current Godot version; inner funcs can be tricky in GDScript]
  - place_building_async() referenced in Prompt 12 writeup but actual call
    is HexGrid.place_building(slot, type) â confirm no async wrapper needed
 
---
 
### build_phase_manager.gd â
Location: autoloads/build_phase_manager.gd
 
Confirmed methods/signals:
  - set_build_phase_active(active: bool) -> void
  - build_phase_started  [signal]
  - combat_phase_started [signal]
 
Integration points:
  - GameManager calls set_build_phase_active(false) on:
      mission start / start_wave_countdown / exit_build_mode
  - GameManager calls set_build_phase_active(true) in enter_build_mode
  - BuildMenu hides on combat_phase_started signal
 
Known gaps / [VERIFY]:
  - assert_build_phase() guard on place_building, sell_building,
    upgrade_building â confirm these guards exist in building_base.gd
    or hex_grid.gd
  - confirm_build_phase() method â exists? or is it set_build_phase_active(false)?
 
---
 
### research_manager.gd â
Location: scripts/research_manager.gd  [VERIFY path]
 
Confirmed:
  - can_unlock(node_id) -> bool
  - get_research_points() -> int
  - add_research_points(amount) -> void
  - unlock(node_id) -> void  [alias for unlock_node]
  - show_research_panel_for(node_id) -> void
  - _unlock_building_for_node() â clears BuildingData.is_locked on
    the hex_grid group's registry
  - research_nodes: Array â 24 nodes total (6 existing + 18 new)
  - dev_unlock_anti_air_only: bool  [dev flag, should be false]
 
RP currency note:
  - RP IS research material from EconomyManager, not a second currency
  - research_points_changed signal mirrors resource_changed(RESEARCH_MATERIAL)
 
Registered in scenes/main.tscn: â
 
---
 
### signal_bus.gd â
Location: autoloads/signal_bus.gd
 
Confirmed signals (accumulated across all prompts):
  Pre-existing:
    - wave_started
    - wave_completed   [VERIFY: some code uses wave_cleared â confirm canonical name]
    - mission_failed
    - enemy_killed
    - building_placed
    - building_sold
    - building_upgraded
    - resource_changed(resource_type, new_amount)
    - spell_cast
    - tower_damaged     [VERIFY exact name â florence takes damage]
    - ally_spawned
    - ally_killed
 
  Added Prompt 4:
    - building_dealt_damage  [payload: see Prompt 4 spec]
 
  Added Prompt 11:
    - research_node_unlocked
    - research_points_changed
 
  Planned but NOT yet added:
    - damage_dealt(amount, damage_type, source_category, source_id,
        target_enemy_type, target_armor_type)    â design doc Â§7.3.4
    - enemy_damage_dealt(amount, attacker_enemy_type,
        target_category, target_id)              â design doc Appendix C
    - ally_died  [referenced in Prompt 7 roadmap]  â
 
---
 
### game_manager.gd â ď¸
Location: autoloads/game_manager.gd
 
Confirmed integrations (from Prompt 11 output):
  - Calls BuildPhaseManager.set_build_phase_active(false) on mission start
  - enter_build_mode() / exit_build_mode() methods exist
  - start_wave_countdown() exists
 
Inferred (needed by SimBot, not explicitly confirmed):
  - start_mission_async(mission_id) â [VERIFY: may be
    CampaignManager.start_new_campaign() + GameManager.start_mission_for_day()
    rather than a single async method]
  - is_mission_over() -> bool â [VERIFY exact method name]
 
---
 
## PART 2 â SCRIPTS / GAMEPLAY
 
### building_base.gd â (partial)
Location: scripts/building_base.gd  [VERIFY exact path]
 
Confirmed:
  - recompute_all_stats() â triggers full stat pipeline
  - _apply_data_stats() â reads from BuildingData and applies to instance
  - Stat pipeline order: base_stats â aura â status â clamp â push
  - take_damage() â thin wrapper, still exists for backwards compat
 
Added Prompt 5:
  - receive_damage(packet) â unified damage resolution entry point
    Pipeline: targeting validation â PHYSICAL/MAGICAL/FIRE/POISON/TRUE
    mitigation â shield absorption â HP damage â on-hit status â analytics signal
  - Signal emission to building_dealt_damage
 
Known gaps:
  - assert_build_phase() guard â [VERIFY exists]
  - Aura emission from is_aura=true buildings â NOT YET WIRED đś
  - is_healer logic (heal_tick timer, heal_radius scan) â NOT YET WIRED đś
  - is_summoner spawn logic â NOT YET WIRED đś
  - Upgrade level tracking (current_upgrade_level: int) â [VERIFY exists]
 
---
 
### enemy_base.gd â (partial)
Location: scripts/enemy_base.gd  [VERIFY path]
 
Confirmed:
  - apply_stat_layer() â scaffolded for aura resolution
  - Reads special_tags / special_values from EnemyData
 
Known gaps â all special_tags are DATA ONLY, no runtime behavior:
  - "charge"         đś  no dash / enrage logic
  - "shield"         đś  ShieldComponent node does not exist yet
  - "aura_buff"      đś  not registered with AuraManager
  - "aura_heal"      đś  not registered with AuraManager
  - "on_death_spawn" đś  no spawn handler on enemy_died
  - "disable_building" đś  BuildingBase.set_disabled() may not exist
  - "regen"          đś  no HP regen tick in _process
  - "anti_air"       đś  no targeting priority override
 
---
 
### hex_grid.gd â (partial)
Location: scenes/hex_grid/hex_grid.gd  [VERIFY]
 
Confirmed:
  - add_to_group("hex_grid")  â so ResearchManager can find it
  - building_data_registry: Array[BuildingData]
    assert building_data_registry.size() == 36  [VERIFY this assert]
  - rotate_ring(delta_steps: int) â ring rotation, build phase only
  - get_buildable_hexes() -> Array  â used by SimBot [VERIFY method name]
  - place_building(slot, type) â SimBot placement API [VERIFY signature]
 
Known gaps:
  - get_tower_type_count(building_type) -> int â referenced in design doc
    Â§7.2.3 but NOT yet implemented  â
  - Duplicate cost scaling via duplicate_cost_k â BuildMenu reads it but
    HexGrid doesn't enforce it yet  [VERIFY]
  - NavMesh obstacle registration for blocker summons â not yet wired  đś
 
---
 
### wave_manager.gd â
Location: scripts/wave_manager.gd  [VERIFY]
 
Confirmed:
  - WaveComposer integration via _composer: WaveComposer
  - @export var wave_pattern: WavePatternData
  - force_spawn_wave(wave_number: int)  [1-based]
  - clear_all_enemies() â also cancels composed spawn queue + mission
    timed spawn queue; sets _is_spawning_composed=false, clears
    _spawn_composed_queue / cursor / timer
  - has_pending_composed_spawns() -> bool
  - assert enemy_data_registry.size() == 30
 
Notes:
  - force_spawn_wave_async() â [VERIFY: may be sync with await wrapper in SimBot]
 
---
 
### wave_composer.gd â
Location: scripts/wave_composer.gd
 
Confirmed methods:
  - compose_wave(wave_index: int) -> Array[EnemyData]
  - _compute_budget_for_wave(wave_index) -> int
  - _get_primary_tag(wave_index) -> String
  - _get_modifiers(wave_index) -> Array[String]
  - _build_candidate_pool(primary_tag, modifiers, wave_index) -> Array[EnemyData]
  - _enemy_matches_primary_tag(ed, primary_tag) -> bool
  - _enemy_passes_modifiers(ed, modifiers, wave_index) -> bool
  - _pick_enemy_for_wave(pool, wave_index) -> EnemyData
  - _max_tier_for_wave(wave_index) -> int
 
Budget formula: base_point_budget + budget_per_wave * (wave_index + 1)
Note: This is per-mission only. Day-based scaling from design doc Â§7.2.4
(base + day_scaling * day_number + wave_scaling * wave_number) is NOT
yet implemented.  â
 
---
 
### ally_manager.gd đś
Location: [VERIFY â may not exist yet or may be a stub]
 
Referenced in: Prompt 7 roadmap (summoner runtime)
Status: If it exists, it is almost certainly a stub with no summon
        lifecycle management (spawn/respawn/death tracking).
Needed for: is_summoner towers, global summon cap (MAX_ACTIVE_SUMMONS=20)
 
---
 
### aura_manager.gd đś
Location: [VERIFY â may not exist yet]
 
Referenced in: Prompt 8 roadmap (aura runtime)
Status: NOT YET WIRED. The aura_category resolver was scaffolded in the
        stat pipeline (building_base.gd) but AuraManager as a node/autoload
        likely does not exist yet.
Needed for:
  - is_aura=true buildings emitting aura_effect_type/value on placement
  - Stacking rule: same aura_category â only strongest applies
  - enemy_slow auras through EnemyBase.apply_stat_layer()
  - enemy aura_buff / aura_heal registrations from enemy special_tags
 
---
 
### shield_component.gd â
Not yet created. Referenced in Prompt 9 roadmap for enemy "shield" tag.
Needed: A node that attaches to EnemyBase, absorbs shield_hp before HP.
 
---
 
## PART 3 â RESOURCES
 
### scripts/resources/building_data.gd â
Location: scripts/resources/building_data.gd  [VERIFY]
 
Confirmed fields (from Prompt 50):
  Original fields (pre-Prompt 50) â [VERIFY exact names]:
    - display_name: String
    - cost_gold: int
    - cost_material: int
    - base_damage: float
    - attack_range: float
    - attack_speed: float   [or fire_rate]
    - is_locked: bool
    - building_type: Types.BuildingType
 
  Renamed in Prompt 50:
    - footprint_size_class   [was: size_class before Prompt 50 enum rename]
    - aura_category: String  [was: an enum before Prompt 50]
    - heal_target_flags      [was: heal_targets bitmask before Prompt 50]
 
  Added in Prompt 50:
    - size_class: String     ["SMALL", "MEDIUM", "LARGE"]
    - role_tags: Array[String]
    - balance_status: String ["UNTESTED","BASELINE","OVERTUNED","UNDERTUNED","CUT_CAMPAIGN_1"]
    - building_id: String    [unique string key, separate from enum]
    - is_summoner: bool
    - summon_leader_data_path: String
    - summon_follower_data_path: String
    - summon_cooldown: float
    - summon_respawn_type: String   ["mortal","recurring","immortal"]
    - summon_respawn_delay: float
    - summon_is_blocker: bool
    - is_aura: bool
    - aura_effect_type: String
    - aura_effect_value: float
    - aura_radius: float    [VERIFY â may need to be added]
    - is_healer: bool
    - heal_per_tick: float
    - heal_tick_interval: float
    - heal_radius: float    [VERIFY â may need to be added]
    - heal_targets: String  ["allies","buildings","both"]
    - max_upgrade_level: int
    - upgrade_costs: Array[Dictionary]
    - upgrade_damage_multipliers: Array[float]
    - upgrade_range_multipliers: Array[float]
    - upgrade_fire_rate_multipliers: Array[float]
    - duplicate_cost_k: float  [default 0.08]
 
  NOT yet confirmed whether these design-doc fields made it in:
    - summon_squad_size: int  [VERIFY]
    - aura_stacking_category  [may be same as aura_category â VERIFY]
 
---
 
### scripts/resources/enemy_data.gd â
Location: scripts/resources/enemy_data.gd  [VERIFY]
 
Confirmed fields (added Prompt 50):
  - point_cost: int
  - wave_tags: Array[String]
  - tier: int  [1â5]
  - special_tags: Array[String]
  - special_values: Dictionary
  - balance_status: String
 
  Pre-existing [VERIFY exact names]:
  - display_name: String
  - enemy_type: Types.EnemyType
  - max_hp: float
  - move_speed: float
  - armor_type: Types.ArmorType
  - damage: float
  - is_flying: bool
  - gold_reward: int
 
---
 
### scripts/resources/wave_pattern_data.gd â
Location: scripts/resources/wave_pattern_data.gd
 
Fields:
  - id: String
  - display_name: String
  - base_point_budget: int  [default 35 in default_campaign_pattern]
  - budget_per_wave: int    [default 9]
  - max_waves: int          [30]
  - wave_primary_tags: Array[String]
  - wave_modifiers: Array[Array[String]]
 
Resource file:
  res://resources/wave_patterns/default_campaign_pattern.tres  â
 
---
 
### scripts/simbot/simbot_loadouts.gd â
Location: scripts/simbot/simbot_loadouts.gd
 
Three loadouts defined:
  - "balanced":        arrow_tower Ă4, fire_brazier Ă2, magic_obelisk Ă2,
                       poison_vat Ă1, wolfden Ă1, warden_shrine Ă1
  - "summoner_heavy":  wolfden Ă3, bear_den Ă2, barracks_fortress Ă1,
                       citadel_aura Ă1, field_medic Ă1, iron_cleric Ă1
  - "artillery_air":   siege_ballista Ă2, fortress_cannon Ă1, dragon_forge Ă1,
                       anti_air_bolt Ă2, crow_roost Ă2, chain_lightning Ă1
 
Note: "wolfden" not "wolf_den" â matches actual .tres building_id
 
---
 
## PART 4 â CONTENT (.tres FILES)
 
### Building .tres (36 total) â
Location: res://resources/building_data/   [VERIFY path]
 
Original 8 (updated for Prompt 50 fields):
  These exist and were updated. [VERIFY names]:
    - arrow_tower.tres
    - fire_brazier.tres      [VERIFY â may be named differently]
    - magic_obelisk.tres     [VERIFY]
    - poison_vat.tres        [VERIFY]
    - [4 more original towers â VERIFY names]
 
New 28 (added Prompt 50):
  From simbot_loadouts.gd, confirmed building_ids exist:
    - wolfden.tres
    - bear_den.tres          [VERIFY]
    - barracks_fortress.tres [VERIFY]
    - citadel_aura.tres      [VERIFY]
    - field_medic.tres       [VERIFY]
    - iron_cleric.tres       [VERIFY]
    - siege_ballista.tres    [VERIFY]
    - fortress_cannon.tres   [VERIFY]
    - dragon_forge.tres      [VERIFY]
    - anti_air_bolt.tres     [VERIFY]
    - crow_roost.tres        [VERIFY]
    - chain_lightning.tres   [VERIFY]
    - warden_shrine.tres     [VERIFY]
    - [15 more â VERIFY full list via dir listing]
 
  All balance_status fields default to "UNTESTED" unless a prior
  apply_balance_status.gd run has been done.
 
Important: 28 towers in the "artillery_air" and "summoner_heavy" loadouts
  are DATA ONLY. Their is_summoner, is_aura, and is_healer flags are set
  but NO runtime logic exists yet (see Part 2 gaps).
 
---
 
### Enemy .tres (30 total) â
Location: res://resources/enemy_data/   [VERIFY path]
 
Original 6 (updated):
  [VERIFY names â likely grunt.tres, skirmisher.tres, etc.]
 
New 24 (added Prompt 50):
  [VERIFY full list via dir listing]
  All special_tags populated but NO runtime behavior wired.
  All balance_status = "UNTESTED"
 
Registry assert in wave_manager.gd:
  assert enemy_data_registry.size() == 30
 
---
 
### Ally .tres (5 stubs) đś
Location: res://resources/ally_data/   [VERIFY path]
 
Status: Pure data stubs. No AllyBase runtime behavior confirmed.
  Fields: [VERIFY â likely hp, damage, move_speed, is_blocker, ally_id]
  These are referenced by summon_leader_data_path on building .tres files
  but no spawn code reads them at runtime yet.
 
---
 
### Research .tres (18 new + 6 existing = 24 total) â
Location: res://resources/research/   [VERIFY path]
 
Confirmed: 24 research nodes registered in scenes/main.tscn on
  ResearchManager.research_nodes
 
[VERIFY what the 18 new nodes unlock â likely the 28 new towers plus
  some summoner/aura/healer upgrades]
 
---
 
## PART 5 â UI
 
### ui/build_menu.gd + build_menu.tscn â
Location: ui/build_menu.gd, ui/build_menu.tscn  [VERIFY]
 
Confirmed:
  - Rebuilds grid from HexGrid.building_data_registry
  - Sorted: size_class (SMALLâMEDIUMâLARGE) then display_name
  - Hides on SignalBus.combat_phase_started
  - Refreshes on research_unlocked / research_node_unlocked
  - BuildingScroll (ScrollContainer) around 2-column GridContainer
  - Affordability disables placement even for unlocked towers
 
Note: This is a SCROLLING LIST, not a radial "Tower Wheel". The design
  doc Â§7.5.1 describes a radial build UI per slot â NOT YET IMPLEMENTED. â
  Decision needed: keep scroll list for now, or build radial wheel.
 
---
 
### ui/build_menu_button.tscn + build_menu_button.gd â
Location: ui/build_menu_button.*  [VERIFY]
 
Confirmed:
  - Displays: title + gold/material cost line + role_tags
  - LockOverlay: shown when is_locked=true; click opens research panel
    (does NOT prevent click, which allows research routing)
  - Affordability styling: disables placement when too expensive + unlocked
 
---
 
### ui/research_panel.gd + research_panel.tscn â
Location: ui/research_panel.*  [VERIFY]
 
Confirmed:
  - Full-screen dimmer + side panel
  - RP (research points) label
  - Scrollable rows via ScrollContainer.ensure_control_visible
  - scroll_to_node(node_id) method
 
---
 
### ui/research_node_row.gd + research_node_row.tscn â
Location: ui/research_node_row.*  [VERIFY]
 
Confirmed:
  - Displays research node info + cost + unlock button
 
---
 
### ui/hud.gd + hud.tscn â
Location: ui/hud.*  [VERIFY]
 
Confirmed:
  - Research button only visible in BUILD_MODE
  - Research button â show_panel() call
 
Missing / not confirmed:
  - Ring rotation UI (drag handle or 60Â° increment buttons)  â
  - Duplicate cost display in build menu  đś
  - Summon limit indicator ("Summon Limit Reached")  â
 
---
 
## PART 6 â TOOLS
 
### tools/simbot_balance_report.py â
Location: tools/simbot_balance_report.py
 
Confirmed behavior:
  - Reads all building_summary.csv from simbot_runs/ (via --root flag or default)
  - Aggregates: total_damage, total_gold, ally_deaths, run_ids per building_id
  - Computes damage_per_gold per tower
  - Gold floor: total_gold_spent >= 200 across runs to be eligible for classification
  - Thresholds: OVERTUNED >= median * 1.35 | UNDERTUNED <= median * 0.65 | else BASELINE
  - Writes tools/output/simbot_balance_report.md  (markdown table)
  - Writes tools/output/simbot_balance_status.csv (building_id,status)
  - Creates output/ directory if not present
 
To run:
  python3 tools/simbot_balance_report.py
  python3 tools/simbot_balance_report.py --root /path/to/runs
 
Output columns in report:
  Building | role_tags | runs | dmg/gold | ally_deaths/run | status
 
Known gaps vs. design doc Â§7.3.2:
  - damage_vs_unarmored / damage_vs_heavy / damage_vs_flying breakdown: NOT implemented
  - kills_per_gold: NOT in current report
  - count_upgraded / count_lost: NOT tracked
  - Per-run win/loss correlation: NOT tracked
  - Per-enemy survival_rate analysis (Â§7.3.3): NOT implemented
  â These are all post-balance-pass enhancements
 
---
 
### tools/apply_balance_status.gd â
Location: tools/apply_balance_status.gd
 
Confirmed:
  - EditorScript (or Node tool), class_name BalanceStatusApplier
  - apply_from_csv(path: String) â reads simbot_balance_status.csv
  - Iterates res://resources/building_data/*.tres
  - Sets balance_status on each BuildingData if building_id matches
  - Saves with ResourceSaver.save()
 
Default CSV path: tools/output/simbot_balance_status.csv  [VERIFY hardcoded default]
 
To run: Open in Godot editor, run as EditorScript.
 
---
 
### tools/run_gdunit_unit.sh â
Current state: 324 test cases, 0 failures
 
---
 
### tools/run_gdunit_quick.sh â (added Prompt 12)
[VERIFY this exists â mentioned in Prompt 12 output]
 
---
 
### tools/gen_prompt50_assets.py â ď¸
Location: tools/gen_prompt50_assets.py
Status: One-off generator for .tres stubs. Optional to delete.
 
---
 
### tools/gen_prompt50_enemies_allies_research.py â ď¸
Location: tools/gen_prompt50_enemies_allies_research.py
Status: One-off generator. Optional to delete.
 
---
 
## PART 7 â TESTS
 
### tests/unit/test_wave_composer.gd â
24 test cases â all passing.
Tests: compose_wave(), budget scaling, tier gating, tag filtering, fallback pool.
 
### tests/unit/test_wave_manager.gd â
24 test cases â all passing (after clear_all_enemies() fix).
Key fixed test: test_all_waves_cleared_emitted_after_wave_10
 
### tests/unit/test_research_and_build_menu.gd â
Added Prompt 11. [VERIFY case count]
 
### tests/unit/test_simbot_balance_integration.gd â
Added Prompt 12.
Tests:
  - test_combat_stats_tracker_begin_end_run
  - test_all_buildings_have_balance_status_string
 
### tests/unit/test_content_invariants.gd â
4 test cases (added Prompt 50).
Tests: all building/enemy .tres pass invariants (cost > 0, etc.)
 
### tests/test_art_placeholders.gd â
Loads res://.../{enum_key_lower}.tres for all Types.BuildingType and
  Types.EnemyType values.
 
---
 
## PART 8 â TYPES AND ENUMS
 
### scripts/types.gd â
Location: scripts/types.gd  [VERIFY path, may be autoloads/types.gd]
 
Confirmed:
  BuildingType enum: entries 0â35 (36 total, indices 8â35 added Prompt 50)
  EnemyType enum:    entries 0â29 (30 total, indices 6â29 added Prompt 50)
 
Note: Design doc narrative mentioned "36 enemies" but actual enum is 30.
  wave_manager assert confirms: enemy_data_registry.size() == 30
 
---
 
## PART 9 â SCENES
 
### scenes/main.tscn â
Confirmed nodes added/updated:
  - ResearchManager (with 24 research_nodes assigned)
  - ResearchPanel under UI
  - dev_unlock_anti_air_only = false on ResearchManager
 
[VERIFY: BuildPhaseManager is in autoloads, not scene â confirm not duplicated]
 
---
 
## PART 10 â DOCS
 
### docs/PROMPT_50_IMPLEMENTATION.md â
### docs/PROMPT_10_IMPLEMENTATION.md â
### docs/PROMPT_11_IMPLEMENTATION.md â
### docs/PROMPT_51_IMPLEMENTATION.md â  [Note: Prompt 12 was logged as Prompt 51]
### docs/INDEX_SHORT.md â  [updated through Prompt 12]
### docs/INDEX_FULL.md â   [updated through Prompt 12]
 
Missing:
  - docs/ARCHITECTURE.md  â  No top-level architecture document exists
  - docs/SIGNAL_REFERENCE.md  â  No canonical list of all signals + payloads
  - docs/BALANCE_PROCESS.md  â  No written process guide for human operators
 
---
 
## PART 11 â WHAT IS COMPLETELY NOT STARTED (Roadmapped Only)
 
### Prompt 7 â Summoner Tower Runtime  â
Files that need to be written/extended:
  - building_base.gd: spawn squad on placement, read summon_leader_data_path /
    summon_follower_data_path, handle mortal/recurring/immortal respawn
  - ally_manager.gd: lifecycle tracking, global cap MAX_ACTIVE_SUMMONS=20
  - hex_grid.gd: register blocker summons as soft NavMesh obstacles
  - signal_bus.gd: ally_died signal
  - Dependency: needs NavigationObstacle3D rebaking when summons placed/die
 
### Prompt 8 â Aura & Healer Tower Runtime  â
Files that need to be written/extended:
  - aura_manager.gd: new autoload, emit/resolve aura_category stacking rule
  - building_base.gd: is_aura towers emit on placement, subscribe to
    aura_manager updates
  - enemy_base.gd: enemy_slow auras applied via apply_stat_layer()
  - building_base.gd: is_healer tick timer, heal_radius scan, receive_heal()
  - ally_base.gd: receive_heal() method  [VERIFY ally_base.gd exists]
 
### Prompt 9 â Enemy Special Mechanics Runtime  â
Files that need to be written/extended:
  - enemy_base.gd: read special_tags in _ready(), wire each to behavior
  - shield_component.gd: NEW FILE
  - aura_manager.gd: register enemy aura_buff / aura_heal entries
  - building_base.gd: set_disabled(true/false, duration) method
  Behaviors needed per tag:
    charge           â speed multiplier on enrage_hp_pct threshold
    shield           â ShieldComponent absorbs shield_hp first
    aura_buff        â register with AuraManager on spawn
    aura_heal        â register with AuraManager on spawn
    on_death_spawn   â spawn_type Ă spawn_count on enemy_died
    disable_building â melee reach triggers set_disabled on BuildingBase
    regen            â HP tick in _process
    anti_air         â targeting priority override to FLYING
 
### Ring rotation UI  â
  - HexGrid.rotate_ring() method exists (Prompt 5)
  - No UI to trigger it (no drag handle, no 60Â° increment buttons)
  - Pre-battle screen rotation overlay from design doc Â§7.1.2: not built
 
### Duplicate cost enforcement in placement  â
  - duplicate_cost_k field exists on BuildingData
  - get_tower_type_count() on HexGrid: NOT implemented
  - CostCalculator utility: NOT implemented
  - BuildMenu does NOT yet show scaled cost for nth duplicate
 
### Global summon cap  â
  - MAX_ACTIVE_SUMMONS = 20: constant not defined
  - SummonManager or GameManager counter: NOT implemented
  - "Summon Limit Reached" UI: NOT implemented
 
### Day-based wave budget scaling  â
  - WaveComposer only uses wave_index, not day_number
  - Design doc formula: base + day_scaling*day + wave_scaling*wave: NOT implemented
  - Multi-day campaign loop in SimBot: NOT implemented (only mission_01)
 
### Multi-mission SimBot sweep  â
  - run_balance_sweep() hardcoded to ["mission_01"]
  - No early/late game mission coverage
 
### Tower wheel radial UI  â  (design doc Â§7.5.1)
 
### Weapon enchanting system  â  (referenced in design doc, no prompt written)
 
### Shop system  â  (referenced in design doc, no prompt written)
 
### Mercenary recruitment system  â  (referenced in design doc, no prompt written)
 
---
 
## PART 12 â KNOWN DISCREPANCIES TO VERIFY
 
1. wave_cleared vs wave_completed â signal name used inconsistently across
   files. Canonical name in SignalBus needs confirming.
 
2. force_spawn_wave() is 1-based per WaveManager implementation note,
   but WaveComposer uses 0-based wave_index internally. Confirm the
   off-by-one is handled at the WaveManager/Composer boundary.
 
3. Prompt 12 SimBot code uses inner func syntax for lambda signal handlers
   (_on_wave_completed, _on_mission_failed inside _wait_for_wave_or_mission_end).
   GDScript inner functions in Godot 4.x may not compile as written.
   Likely needs to be refactored to class-level methods or callables.
 
4. place_building_async() vs HexGrid.place_building() â Prompt 12 writeup
   mentions BuildPhaseManager.place_building_async() but the pre-work
   inspection confirmed placement is via HexGrid.place_building(slot, type).
   Confirm which API is actually used in sim_bot.gd after implementation.
 
5. start_mission_async() â may not exist as a single async method;
   may be CampaignManager.start_new_campaign() + GameManager.start_mission_for_day().
   Confirm the SimBot call chain.
 
6. "wolfden" vs "wolf_den" â simbot_loadouts.gd uses "wolfden" (no underscore)
   to match the actual .tres building_id. Ensure all references are consistent.
 
7. Prompt 12 output was logged in docs as PROMPT_51_IMPLEMENTATION.md.
   The numbering gap (12 in conversation vs 51 in docs) suggests the project
   has its own internal prompt numbering separate from this conversation.
   Confirm which numbering scheme is canonical for future prompts.
 
8. Research material = RP: the design uses a single research_material currency
   that doubles as RP. Confirm EconomyManager.resource_changed(RESEARCH_MATERIAL)
   is the only currency source and there is no separate "research points" wallet.
 
---
 
## PART 13 â QUICK REFERENCE: HOW TO USE THE BALANCE PIPELINE
 
Step 1 â Run a sweep (headless):
  godot --path . --headless -- --simbot_balance_sweep
 
Step 2 â Copy runs to analysis folder:
  [mirror user:// simbot/runs/ to ./simbot_runs/]
 
Step 3 â Generate report:
  python3 tools/simbot_balance_report.py
 
Step 4 â Review report:
  open tools/output/simbot_balance_report.md
 
Step 5 â Apply status to .tres:
  [in Godot editor] run tools/apply_balance_status.gd as EditorScript
 
Step 6 â Commit updated .tres balance_status fields
 
Tuning knobs:
  Loadouts:    scripts/simbot/simbot_loadouts.gd
  Thresholds:  tools/simbot_balance_report.py  (median * 1.35 / 0.65)
  Gold floor:  tools/simbot_balance_report.py  (total_gold >= 200)
  Wave pattern: resources/wave_patterns/default_campaign_pattern.tres
 
---
 
## PART 14 â FILE TREE SUMMARY (EXPECTED)
 
autoloads/
  build_phase_manager.gd     â
  combat_stats_tracker.gd    â
  signal_bus.gd              â
  game_manager.gd            â (partial â verify async methods)
 
scripts/
  types.gd                   â
  wave_composer.gd           â
  resources/
    building_data.gd         â
    enemy_data.gd            â
    wave_pattern_data.gd     â
  simbot/
    simbot_loadouts.gd       â
  sim_bot.gd                 â
  research_manager.gd        â
  wave_manager.gd            â
  building_base.gd           â (aura/heal/summon stubs only)
  enemy_base.gd              â (special_tags stubs only)
  ally_manager.gd            đś (stub or missing)
  aura_manager.gd            â (not yet created)
  shield_component.gd        â (not yet created)
  ally_base.gd               đś (VERIFY exists)
 
scenes/
  hex_grid/hex_grid.gd       â
  main.tscn                  â
 
ui/
  build_menu.gd              â
  build_menu.tscn            â
  build_menu_button.gd       â
  build_menu_button.tscn     â
  research_panel.gd          â
  research_panel.tscn        â
  research_node_row.gd       â
  research_node_row.tscn     â
  hud.gd                     â
  hud.tscn                   â
 
resources/
  building_data/             36 Ă .tres  â (data only for new towers)
  enemy_data/                30 Ă .tres  â (data only for new enemies)
  ally_data/                  5 Ă .tres  đś (stubs)
  research/                  24 Ă .tres  â
  wave_patterns/
    default_campaign_pattern.tres        â
 
tools/
  simbot_balance_report.py   â
  apply_balance_status.gd    â
  run_gdunit_unit.sh         â
  run_gdunit_quick.sh        â
  gen_prompt50_assets.py     â ď¸ (optional, one-off)
  gen_prompt50_enemies_allies_research.py  â ď¸ (optional, one-off)
  output/                    [created on first report run]
 
tests/unit/
  test_wave_composer.gd              â
  test_wave_manager.gd               â
  test_research_and_build_menu.gd    â
  test_simbot_balance_integration.gd â
  test_content_invariants.gd         â
  test_art_placeholders.gd           â
 
docs/
  PROMPT_50_IMPLEMENTATION.md        â
  PROMPT_10_IMPLEMENTATION.md        â
  PROMPT_11_IMPLEMENTATION.md        â
  PROMPT_51_IMPLEMENTATION.md        â
  INDEX_SHORT.md                     â
  INDEX_FULL.md                      â
  ARCHITECTURE.md                    â
  SIGNAL_REFERENCE.md                â
  BALANCE_PROCESS.md                 â
