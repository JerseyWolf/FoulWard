PART 1 — VISION, SCOPE & CAMPAIGN STRUCTURE

This document is a briefing for the game FOUL WARD, a Godot 4 tower defense game inspired by TAUR (a Unity tower defense game by Echo Entertainment, released 2020). Its purpose is to give a working AI assistant enough context to help develop any part of this game. Read this entire document before answering anything.

WHAT THE GAME IS

FOUL WARD is an active fantasy tower defense game. The player does not control a moving character. They control a stationary Tower at the center of the map by aiming and shooting with the mouse. Around the Tower, defensive structures are placed on a hex grid. An AI-controlled melee companion fights automatically. Additional AI-controlled allies can join as the campaign progresses. The player also casts spells using hotkeys. The core loop is: direct aiming and shooting, strategic building placement, passive ally combat, and spellcasting all happening simultaneously in real time. This structure is taken directly from TAUR and translated into a fantasy setting with a narrative layer added on top.

THE REFERENCE GAME: TAUR

In TAUR, the player manually controls a central cannon called the Prime Cannon. Enemies attack from all directions with no lanes. The player has a primary and secondary weapon fired with mouse buttons. A hex grid of approximately 60 slots surrounds the cannon and accepts various automated defensive structures. Between battles the player accesses a Forge, a Research tree, and a territory world map. FOUL WARD mirrors this overall structure. Key differences from TAUR that FOUL WARD deliberately improves upon: weapon upgrades are always positive and deterministic rather than using a random-outcome system that frustrated TAUR players; aiming has a forgiving auto-aim system so shooting feels satisfying rather than punishing; and a full narrative layer is added on top of the mechanical structure.

OVERALL SCOPE

The game ships in two tiers. The free version includes one complete campaign and one endless mode. The endless mode lets the player select any unlocked map and fight indefinitely with scaling difficulty and no narrative. Paid content adds further campaigns. Each paid campaign introduces a new enemy faction, a new plot, and campaign-specific characters. The core ally cast and all game mechanics are reused across campaigns. Campaigns are not connected narratively but may contain small references to one another.

THE 50-DAY CAMPAIGN STRUCTURE

Each campaign lasts up to 50 days. Each day equals one battle. On Day 50 the campaign boss appears. If the player defeats the boss, the campaign ends in victory. If the player fails, the boss conquers one of the player's held territories. On each subsequent day the boss appears again alongside stronger forces, making the fight harder but also rewarding more gold. This loop continues until the player wins or loses all territories. The mechanic ensures that failure is never a dead end — every failed boss attempt funds further upgrades — but repeated failure has genuine consequences on the world map.

TERRITORY SYSTEM

The campaign world is divided into named territories each with a distinct terrain type. The Tower teleports to whichever territory is being contested each day. Holding a territory provides a passive resource bonus. Losing one reduces that income. The player can see all territories on a world map screen between battles. When the boss begins conquering on Day 50 and beyond, their advance is shown visually on the map. If multiple territories are simultaneously under threat, the player chooses which to defend. The number of territories per campaign is a per-campaign design decision.

FACTION STRUCTURE

Enemy factions are campaign-specific. Each faction has a full roster of unit types covering a range of combat roles: basic melee infantry, ranged units, heavy armored units, fast light units, flying units, units with area-effect attacks, units with special on-death effects, and units with status-inflicting attacks. Each faction also has several named mini-boss characters who appear on milestone days before the final boss. Each mini-boss has a unique ability set. After a mini-boss is defeated, some of their troops may defect and the mini-boss themselves may become an ally NPC. The final boss is a multi-phase encounter with elite escort troops. Friendly forces come from mercenaries, retinue, and soldiers available for hire or recruited after mini-boss defeats. Enemy factions are entirely replaced per campaign; ally characters are reused across campaigns with new dialogue.

PART 2 — BATTLE LOOP & COMBAT SYSTEMS

This document is a briefing for the game FOUL WARD. Read it fully before helping with any task. It describes how a single battle works from start to finish.

THE BATTLE SCENE

Every battle takes place on a map tied to the territory being contested that day. The Tower is fixed at the center. Enemies spawn from multiple directions simultaneously with no fixed lanes. Enemies pathfind toward the Tower and attack it. The battle ends when all waves for that day are cleared (player victory) or the Tower's health reaches zero (player defeat). The number of waves per day and their composition scale with the current day number and campaign progression.

THE TOWER

The Tower is the player's avatar. It is stationary. The player aims it by moving the mouse and fires using mouse buttons: left button for primary weapon, right button for secondary weapon. Both can be fired simultaneously. The Tower has a health pool. Reaching zero health ends the battle in defeat.

AIMING AND AUTO-AIM SYSTEM

Aiming is designed to be satisfying rather than punishing. When the player fires in the direction of an enemy, the system applies a soft auto-aim assist: if the cursor is within a threshold angle or distance of a valid target at the time of firing, the projectile tracks toward that target. The degree of auto-aim assistance varies by weapon type — precision weapons have a tighter assist cone and faster projectiles, area weapons have wider cones but may still miss. Each weapon has a per-shot miss chance expressed as a percentage. When a miss triggers, the projectile deviates from the assisted path by a random angle. The miss chance should be low enough that the game feels responsive but high enough to remain present as a differentiator between weapon types and upgrade levels. Projectile speed is set high enough per weapon type that fast-moving enemies cannot trivially walk out of a shot that was visually on target when fired.

WEAPON UPGRADE SYSTEM

Weapons are upgraded in levels. Each weapon level has a fixed damage range — a minimum and maximum value. When a projectile hits an enemy, the damage dealt is a random value within that range. The range is identical every time a weapon of that level is used; there is no run-to-run variance in the range itself. Upgrading a weapon to the next level always increases both the minimum and the maximum of the range. Upgrading a weapon never makes it worse. The exact damage values per level per weapon type are to be defined in a data resource per weapon and balanced in a later design phase. Weapon upgrades are purchased through the between-battle progression systems. Separate from numeric level upgrades, weapons can also receive structural upgrades via the Research Tree — these change weapon behavior rather than raw damage, for example increasing clip size, adding a piercing property, changing projectile speed, or adding a secondary effect on hit. These structural upgrades are also always improvements and are one-directional.

WEAPON ENCHANTMENT SYSTEM

Enchantments change the damage affinity of a weapon rather than its raw damage numbers. An unenchanted weapon deals its base damage type with no affinity modifiers. Applying an enchantment assigns an affinity to the weapon: fire affinity, magic affinity, poison affinity, holy affinity, blunt affinity, and so on. Each affinity gives the weapon a bonus damage multiplier against enemy types that are weak to that damage type and a penalty against enemy types that resist it. For example, a fire-affinity weapon deals significantly more damage to enemies with a frost or organic armor type but less damage to enemies with fire resistance. A blunt-affinity weapon may deal bonus damage to heavily armored enemies but reduced damage to fast light enemies. Physical upgrades that do not assign a typed affinity give a flat damage increase with no trade-off — they are strictly additive and do not affect type matchups. Enchantments are mutually exclusive per slot: a weapon can have one active affinity enchantment. The number of enchantment slots per weapon and the exact affinity types and their matchups against specific enemy armor types are to be defined in later design and balance phases. The enchantment system is data-driven and must support adding new affinity types by creating new resource files without code changes.

COLLISION AND PHYSICS

All entities in the game use solid collision. Enemies cannot walk through each other, through Tower structures, through hex grid buildings, or through terrain objects. Ground enemies are blocked by physical terrain. Flying enemies use a separate navigation layer and are not blocked by ground obstacles but are still blocked by other flying entities. Projectiles collide with the first valid target they hit unless they have a piercing property. Buildings and the Tower are physically present objects in the scene — enemies must navigate around them, not through them. This creates emergent tactical behavior: clusters of enemies can be funneled, buildings can be used as barriers, and dense groups of enemies are easier to hit with area weapons.

MELEE COMPANION

One named AI-controlled melee companion fights automatically every battle. He patrols the hex grid perimeter, prioritizes the nearest living enemy to the Tower, moves to engage, attacks, and recovers. He cannot be directly commanded. He is present from the start of every battle and scales with upgrades made between battles.

ADDITIONAL ALLIES

Additional AI-controlled allies can be fielded each battle from resources accumulated between battles. Allies of different types use appropriate behavioral AI: ranged allies hold position and shoot, melee allies charge and fight, support allies stay near the Tower. The ally system is generic — new ally types are added via data resources without code changes.

HEX GRID BUILDINGS

A ring of hex slots surrounds the Tower. During battle the player can enter Build Mode using a hotkey to place or sell buildings using gold earned during the current battle. Buildings operate automatically once placed. They cannot be walked through by enemies. Specific building types are to be defined in a later design phase. The hex grid system must support any building type loaded from data resources.

DAMAGE AND ENEMY INTERACTION

The game uses a damage type and armor type system with defined multipliers. Damage types include at minimum physical, fire, magic, and poison. Each enemy type has an armor type with predefined multipliers for all incoming damage types. Status effects (burning, poisoned, slowed, infected, etc.) are a separate layer applied on top of raw damage with duration-based behavior. The system is data-driven — new damage types, armor types, and multiplier tables are added via resource files.

SPELLS

The player has a small number of hotkey-bound spells with immediate battlefield effects. Spells are governed by either a shared mana pool or individual cooldowns depending on the spell type. New spells are unlocked through Research. The spell system is data-driven and supports adding new spells via resource files.

MINI-BOSSES AND CAMPAIGN BOSS

Named mini-bosses appear on milestone days with elevated stats and at least one unique ability. Defeating them may result in troops switching sides. On Day 50 the campaign boss appears as a multi-phase encounter. Boss mechanics are campaign-specific and defined in a later phase.

ENVIRONMENT

Battle maps have destructible terrain props (trees, rocks, walls). Destruction is physics-driven. The environment changes tactically as the battle progresses. Terrain type affects pathfinding and may impose movement speed modifiers on ground enemies.

PART 3 — BETWEEN-BATTLE SYSTEMS

This document is a briefing for the game FOUL WARD. Read it fully before helping with any task. It describes all systems the player interacts with between battles.

OVERVIEW

After each battle the player enters a between-battle hub screen where all progression happens. Each system is associated with a named character who manages it. The hub should feel populated — characters are visually present and accessible. The current MVP is a simplified text-only screen. The final version presents characters visually with dialogue triggering on interaction.

THE SHOP

One named character runs a Shop using gold earned from battles. The Shop sells new buildings for the hex grid, alternative weapons for the Tower, one-use battle consumables, and gear for named allies. Inventory partially rotates between days. The system is data-driven: the shop catalog is loaded from resource files and new items require no code changes to add.

WEAPON UPGRADE STATION

One named character (or the same as the Shop; to be decided in a later design phase) handles weapon level upgrades. The player pays gold or resources to increase a weapon's level. The outcome is always an improvement — the damage range minimum and maximum both increase by defined amounts specific to that weapon and level. There is no random outcome. The cost per level and the damage values per level are defined in the weapon's data resource. This is the primary way raw weapon damage grows over the course of a campaign.

RESEARCH TREE

One named character manages a Research Tree funded by the secondary resource currency. Unlocks are permanent within a campaign. The tree has branches covering Tower improvements, building improvements, ally improvements, spell improvements, and army improvements. Research may unlock new content or improve existing systems. Structural weapon upgrades (clip size, piercing, projectile speed, secondary on-hit effects) are a sub-branch of the Research Tree. The system is data-driven: the tree structure, node costs, and unlock effects are all defined in resource files.

ENCHANTING

One named character handles Enchanting. Enchantments add affinity properties to weapons (see Part 2 for the full mechanic description). Applying, removing, and replacing enchantments happens here. Cost is gold and optionally crafting materials dropped by enemies. The system is data-driven.

MERCENARY RECRUITMENT

One named character manages the mercenary pool for hiring temporary battle troops and the management of any defected mini-boss allies. Available types scale with campaign progression. The system is data-driven.

WORLD MAP

A world map screen shows all territories. The player sees which are held, neutral, or enemy-controlled with their terrain types and passive bonuses. Boss advances after Day 50 are shown here. Multi-threat situations require the player to choose which territory to defend.

MISSION BRIEFING

Before each battle a briefing screen presents the territory terrain, incoming wave summary, special day conditions, and a short narrative framing from Florence. It acknowledges narrative stakes: boss appearance, lost territories, mini-boss expectations.

CURRENCIES

Gold is earned during battle by killing enemies and is spent at the Shop, on weapon upgrades, and on Enchanting. The secondary resource currency is earned by holding territories, completing optional battle bonus objectives, and defeating mini-bosses, and is spent only at the Research Tree.

PART 4 — CHARACTERS & NARRATIVE SYSTEM

This document is a briefing for the game FOUL WARD. Read it fully before helping with any task. It describes the character framework and how dialogue should work mechanically. Specific character names, personalities, and backstories are to be decided in a dedicated writing phase and are not specified here.

CHARACTER ROLES

The game has a cast of named characters populating the between-battle hub. The following roles must exist in every campaign as mechanical fixtures. Specific character identities are placeholders until the writing phase fills them in.

ROLE: MELEE COMBAT COMPANION. Fights in every battle automatically. Comments on combat events in dialogue. First ally present from campaign start.

ROLE: SPELL AND RESEARCH SPECIALIST. Manages the spell Research Tree branch. Provides narrative context for magical events. Unlocks new spells through their tree.

ROLE: WEAPONS ENGINEER OR CRAFTSPERSON. Manages weapon level upgrades, building Research Tree branch, and structural weapon upgrade Research branch. Comments on mechanical and structural events.

ROLE: WEAPON ENCHANTER. Manages the Enchanting system. Provides narrative flavor around weapon affinity choices and battle performance.

ROLE: SHOP MERCHANT OR TRADER. Manages the Shop. Provides lighter tonal dialogue about commerce and the war situation.

ROLE: MERCENARY OR MILITARY COMMANDER. Manages troop recruitment and defected ally assignment. Comments on ally performance and losses.

ROLE: FLORENCE — THE PLAYER CHARACTER. The central protagonist through whom all narrative is experienced. She speaks for the player; there are no dialogue choices. Her voice and arc are defined per campaign in the writing phase. She interacts with every other character and is the emotional center of the story.

ROLE: CAMPAIGN-SPECIFIC CHARACTERS. One or more characters unique to a single campaign such as a defected mini-boss, a quest giver, or a faction-specific ally. They use the same dialogue framework. Their pools are smaller than core characters. A template for creating new campaign-specific characters must be built in from the start so adding one requires only a new resource file.

THE HADES DIALOGUE MODEL

FOUL WARD's dialogue system is modeled on the system used in Hades by Supergiant Games (2020). The core principles are as follows.

Each character has a pool of conversation entries stored as data. When the player interacts with a character, the system filters their pool by current game state conditions. Conditions that can gate an entry include: current day number range, outcome of the last battle, whether a specific enemy type was first seen, whether a specific item was purchased, current gold or resource level, whether a research node is unlocked, whether a relationship value threshold has been reached, whether a previous entry in a chain has been completed, and any other trackable game state variable.

After filtering, the system selects the highest-priority available entry that has not yet been played. It marks it as played after display. When all entries are played, the played flags reset so entries can repeat. Essential story beat entries override the priority system entirely and play when their trigger conditions are met regardless of other pending entries. Multi-part story arcs are chained: completing one entry sets a state flag that unlocks the next in the chain. Characters reference events from other characters' storylines using shared state flags.

Dialogue can also trigger mid-battle for specific in-battle events: an enemy type appearing for the first time, Tower health dropping critically low, the companion achieving a large kill count in one battle, a building being destroyed, a spell being cast for the first time.

IMPLEMENTATION REQUIREMENTS

Each dialogue entry is a data resource containing: a unique string ID, the character's ID, the text body, a priority integer, a conditions dictionary, a played boolean, and an optional chain-next-entry ID. The DialogueManager autoload processes any character's pool using identical logic. Adding a new character requires only a new pool resource file — no changes to the manager code. The UI accepts any entry and displays it with the correct character portrait and name. Relationship values per character are tracked in game state and increase as conversations are completed. Relationship never decreases. Higher relationship unlocks deeper arc entries.

PART 5 - GRAPHICS, ANIMATIONS

The characters should have placeholders for characters, buildings, etc., so it would be optimal if there was a way that Cursor would be able to generate those placeholders as graphics automatically. I need all the tools setup for this to happen. Final product would probably use blender and some local tool that I can run on 4090 GTX, if automatically generating good looking models at this stage is possible to create via vibecoding that would be great too, but that is not a priority at the moment, so please figure out a way to do this full auto based on character names in a way that would use the character, building, and monster names to be able to know how they should look like. Adding animations for each action is even better, but just planning out the architecture, movement, and physic of characters and objects would be even better.

PART 6 — WORLD, TERRAIN, TESTING, MCP TOOLS & CODE ARCHITECTURE

This document is a briefing for the game FOUL WARD. Read it fully before helping with any task. It describes the world structure, terrain system, the automated playtesting system, MCP tool integration, testing strategy, and code architecture principles.

WORLD MAP AND TERRAIN

Each campaign has a data-driven world map with named territories. The map screen is a UI menu, not a real-time environment. Territory count, layout, names, terrain types, and passive bonuses are all defined in a campaign data resource. The map screen reads from that resource so different campaigns with different territory counts require no code changes. Each territory has a terrain type that changes the battle map's visual appearance and may impose gameplay modifiers on enemy movement and available pathfinding routes. Terrain type is implemented as a variation layer on the base battle scene — swappable geometry and navmesh variants — so the same battle scripts work across all terrains. Destructible environment props are generic components: any prop placed in a scene with the destructible component becomes destructible automatically.

SIMBOT — AUTOMATED AI PLAYTESTER

SimBot is a built-in automated playtesting system that allows Cursor or any other AI tool to play through the game without human input. Its purpose is balance testing, regression testing, and log gathering. SimBot operates by following a defined strategy profile that specifies which upgrade paths to prioritize, which buildings to place, which spells to use, and which mercenaries to hire. Strategy profiles are data resources — multiple profiles can be created representing different playstyles (physical damage focus, spell focus, building focus, ally-heavy, etc.). Each profile has a small randomization factor so repeated runs with the same profile are not identical but remain broadly consistent with the intended strategy. SimBot can play through a specified number of days, a full campaign, or the endless mode. It logs the outcome of every battle including: gold earned and spent, enemies killed by type, Tower health remaining, buildings destroyed, spells cast, damage dealt by weapon type, and wave clear times. Logs are written to a structured file (JSON or CSV) that can be parsed by an external tool for balance analysis. SimBot is accessible as a headless mode: it can run without launching the full game UI, driven entirely through the existing manager autoloads. The endless mode is the primary environment for SimBot balance runs because it allows running many days without narrative or campaign state constraints.

TESTING STRATEGY

The game uses multiple layers of testing. Unit tests (GdUnit4) cover individual functions in all manager autoloads and core systems: damage calculations, economy transactions, research unlock logic, dialogue filtering, wave composition generation, and collision responses. Integration tests cover interactions between systems: a wave spawning enemies that are then damaged by a building and killed for gold, a research unlock enabling a new building type that can then be placed on the hex grid, an enchantment applied to a weapon correctly modifying its damage output against an armored enemy. Simulation tests use SimBot to play through a set number of days and assert that outcomes are within expected ranges: gold earned per day should fall within a defined band for each strategy profile, the campaign should be completable with at least one strategy profile, and no unhandled errors or null pointer exceptions should appear in the logs. All tests should be runnable headlessly so Cursor can execute them via MCP tools without human interaction. The goal is not to maximize test count but to ensure that every major code path and every interaction between systems has at least one test that would catch a regression.

MCP TOOL INTEGRATION

We have both Godot MCP Pro and GDAI MCP. Both are MCP-compatible with Cursor. Cursor can directly read the scene tree, read the error console, validate scripts, run the project, and capture debug output without requiring the human developer to copy-paste. When Cursor is implementing new features, it should use the MCP to validate that the scene tree matches expectations, that scripts parse without errors, and that the project runs before marking a task complete. I need as many of the capabilities of the two being used to make the end product better and to be able to do all kinds of tests by itself. Cursor being able to do things autonomously is way more important to me than it doing it fast, so I want it to be thorough with the testing procedures and such.

CODE ARCHITECTURE PRINCIPLES

The single most important architectural constraint is that all game content is data-driven. Every entity type — enemies, buildings, weapons, spells, research nodes, shop items, dialogue entries, territories, terrain types, mercenaries, affinities, armor types — is defined in a data resource file (.tres). Manager scripts load from these resources. No content values are hardcoded in scripts. Adding a new enemy type, building, spell, or campaign requires creating new resource files only.

The second architectural constraint is moddability and readability. Code should be written to be understood by a person who is new to the project. Functions should be short and do one thing. Variable and function names should be explicit and self-documenting. Magic numbers should not exist in scripts — all numeric constants that affect gameplay should live in data resources or named constants in a constants file. Redundant code should be refactored into shared utilities. Duplicated logic across files should be consolidated.

PROJECT INDEX FILES

The project must maintain two index files in the root of the repository at all times. These files are updated by Cursor every time a new feature, system, or file is added. There are currently four INDEX_* files, but they have been autogenerated by Cursor on automode, so that would probably be need to looked at.

INDEX_SHORT.md is a compact reference. It lists every script file with its path, its class name, and a single sentence describing what it does. It lists every resource type with its path and a single sentence. It lists every autoload with its name, path, and what signals it emits. It lists every scene with its path and what node it represents. It is designed to fit in a single LLM context window as a fast orientation tool.

INDEX_FULL.md is the extended reference. For every script it includes: the path, class name, purpose, all public methods with their parameters and return types described in plain English, all exported variables with their types and what they connect to, all signals emitted and under what conditions, and any known dependencies on other scripts or autoloads. For every resource type it includes the full list of fields and their purpose. For every autoload it includes the full signal list with payload descriptions. This document is the primary reference for modders and for LLM assistants working on the codebase in a new context window. Cursor must update the relevant section of INDEX_FULL.md every time it adds a new public method, signal, exported variable, or resource field. Both files should be written in plain language, not technical jargon, so that a non-programmer reading them understands what each part of the game is responsible for.

TECHNICAL STACK

Engine: Godot 4, GDScript throughout, Forward+ renderer. All content in .tres resource files. Testing: GdUnit4 for unit and integration tests, SimBot for simulation tests. MCP: Godot MCP Pro (primary) or GDAI MCP (alternative) for Cursor-to-Godot integration. Version control: Git. Development workflow: Perplexity for architecture planning and briefing generation, Cursor with MCP for code generation, repair, and automated validation, Godot editor for scene wiring and runtime observation. Art pipeline tool and export format to be decided in a dedicated art phase.
