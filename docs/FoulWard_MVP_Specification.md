# FOUL WARD — MVP Technical Specification
Version: 0.1 Prototype | Engine: Godot 4 (GDScript) | Platform: PC only
Art: Primitive shapes (cubes/rectangles), colored and labeled

---

MVP SUCCESS CRITERION
One goal only: the game must be functional. Player can complete 5 missions, earn
resources, spend them, and die or win. Nothing more required for this build.

---

CORE GAMEPLAY LOOP

Main Menu → Mission 1 → [Waves 1-10] → Between-Mission Screen → Mission 2
→ ... → Mission 5 → End Screen

Each mission: survive 10 waves. Each wave adds one more enemy of each type.
No saving — single session only. Session resets on quit.

---

THE TOWER

- Central object: Large colored cube (labeled "TOWER") at map center
- HP bar visible at all times above the tower
- Lose condition: Tower HP reaches 0 → mission fail screen → restart from Mission 1
- Win condition: Survive all 10 waves → mission complete → between-mission screen

---

FLORENCE — Primary Weapon System

Florence has no visible model. Florence IS the tower. Player controls weapon from
the tower's perspective (top-down aim).

Aiming:
- Free crosshair — mouse cursor on PC
- No auto-tracking, no aim assist
- Player must manually lead moving targets
- More forgiving than Taur — projectiles visible, enemies can dodge them

Weapon 1 — Crossbow (left mouse button):
- Single shot per click, visible projectile with travel time
- High damage, slow cooldown (~2-3 second reload)
- Requires skill to lead targets — misses are possible and satisfying
- Ammo display: "1/1 — RELOADING 2.4s"
- Hold left mouse = fires immediately when reload completes (auto-fires if held)
- Florence CANNOT target flying enemies with either weapon

Weapon 2 — Rapid Missile (right mouse button):
- Burst of 10 rapid projectiles — lower damage per shot, fast travel speed
- Higher total DPS than crossbow if all shots hit
- Different visual projectile (smaller, faster)
- Ammo display: "10/10" counting down, then reload bar
- Hold right mouse = fires burst, reloads, fires again

Both Weapons:
- Available simultaneously, independent cooldowns
- Both have visible projectile travel time (not hitscan)

Camera:
- Fully locked — fixed isometric angle, no panning, no zoom in MVP

---

ARNULF — Secondary Melee Unit

Character: Medium-sized cube (distinct color, labeled "ARNULF")

Behavior (AI-controlled, no player input):
- Always attacks closest enemy to the tower center
- Patrol radius: approximately halfway to edge of play area
- When no enemies in range: returns to position adjacent to the tower
- When enemy detected: moves to intercept, attacks at melee range

Incapacitation & Resurrection (IMPORTANT):
- When HP reaches 0: Arnulf falls (cube tips over / changes to "downed" color)
- After 3 seconds: automatically gets back up at 50% HP
- NO PERMANENT DEATH — this cycle repeats unlimited times per mission

Stats (placeholder — tune during testing):
- HP: moderate (survives 3-4 hits from basic enemies)
- Attack: physical damage only, moderate speed
- Movement: medium speed

---

SYBIL — Spell System (No Visual Character)

Sybil has no model or position. Represented only by the spell UI.

Shockwave (only spell in MVP):
- Trigger: Dedicated key (Space or Q) or UI button
- Effect: AoE damage to ALL enemies on battlefield simultaneously
- Mana cost: 50 mana per cast
- Cooldown: 60 seconds (regardless of mana)
- Mana: Regenerates over time (e.g., 5 mana/sec, max 100)
- Visual: Simple expanding circle from tower center, vanishes (placeholder VFX)
- UI: Mana bar + cooldown timer on HUD

---

HEX GRID & BUILD SYSTEM

Grid:
- 24 hex slots fixed around tower (no upgrades in MVP)
- Grid invisible during normal gameplay
- Grid visible only in build mode

Build Mode:
- Trigger: B key or Tab
- Time scale: Engine.time_scale = 0.1 on enter (near-pause, not full pause)
- Time returns to 1.0 on exit
- Exit: same key, click outside grid, or Escape

Building Placement:
- Click empty hex slot → radial menu with all 8 buildings
- Shows: name, cost (gold + material), brief description
- Locked buildings shown greyed out (requires research unlock)
- Click option → placed, resources deducted
- Click occupied slot → sell (full refund) or upgrade (if available)

Buildings (8 total, 4 locked behind research):

#  | Name              | Type    | Damage   | Locked? | Notes
1  | Arrow Tower       | Ranged  | Physical | No      | Baseline, always available
2  | Fire Brazier      | Ranged  | Fire     | No      | Auto-targets, applies burn DoT
3  | Magic Obelisk     | Ranged  | Magical  | No      | Bypasses armor
4  | Poison Vat        | AoE     | Poison   | No      | Ground AoE, slows + damages
5  | Ballista          | Ranged  | Physical | Yes     | High damage, slow fire, long range
6  | Archer Barracks   | Spawner | Physical | Yes     | Spawns 2 archer units near tower
7  | Anti-Air Bolt     | Ranged  | Physical | Yes     | Targets flying enemies ONLY
8  | Shield Generator  | Support | None     | Yes     | Adds HP to adjacent buildings

Building Upgrades:
- One upgrade tier per building (Basic → Upgraded)
- Upgrade costs: gold + building material
- Accessible via occupied slot click

Selling:
- Full gold refund — no penalty
- Full building material refund

---

ENEMIES

All enemies: colored cubes/rectangles with text label.

6 Enemy Types:

#  | Name           | Color      | Armor        | Vulnerability  | Behavior
1  | Orc Grunt      | Green      | Unarmored    | Physical       | Runs straight at tower
2  | Orc Brute      | Dark Green | Heavy Armor  | Magical        | Slow, high HP, melee
3  | Goblin Firebug | Orange     | Unarmored    | Physical+Magic | Fast melee, fire immune
4  | Plague Zombie  | Brown      | Unarmored    | Fire           | Slow tank, poison immune
5  | Orc Archer     | Yellow     | Unarmored    | Physical       | Stops at range, fires
6  | Bat Swarm      | Purple     | Flying       | Physical only  | Flies, anti-air only

Wave Scaling:
- Wave N = N of each enemy type (total = N x 6)
- Wave 1: 6 enemies | Wave 5: 30 enemies | Wave 10: 60 enemies
- Max waves: 10. After wave 10: mission win.

Spawning:
- 10 fixed spawn points around map edge, evenly distributed
- Enemies assigned randomly to spawn points each wave
- All spawn simultaneously at wave start

Wave Warning:
- 30s before wave: flashing "WAVE X INCOMING" text on HUD
- Wave counter always visible: "Wave 3 / 10"

Gold on Kill:
- Floating yellow "+[amount]" text above corpse for 1 second
- Gold added to total immediately — no pickup required

---

RESOURCES & ECONOMY

Three Resources:

Resource          | Color  | Earned By              | Used For
Gold              | Yellow | Enemy kills (instant)  | Buildings, upgrades, shop
Building Material | Grey   | Post-mission reward    | Building placement, upgrades
Research Material | Blue   | Post-mission reward    | Research tree ONLY

Post-Mission Rewards:
After wave 10 → brief overlay text (no dedicated screen):
  "+[X] Gold  |  +[Y] Building Material  |  +[Z] Research Material"
Resources carry over to between-mission screen automatically.

HUD Resource Display:
Permanent: Gold | Material | Research — three counters, always visible

---

RESEARCH TREE (MVP — One Tree Only)

Tree: Base Structures
6 nodes, each costs Research Material.
Accessible from between-mission screen.

Nodes (Claude Opus to finalize values):
1. Unlock Ballista         — cost: 2 research
2. Unlock Anti-Air Bolt    — cost: 2 research
3. Arrow Tower +Damage     — cost: 1 research
4. Unlock Shield Generator — cost: 3 research
5. Fire Brazier +Range     — cost: 1 research
6. Unlock Archer Barracks  — cost: 3 research

---

SHOP (Between Missions)

No shopkeeper model in MVP. Functional store UI only.

Item                  | Cost             | Effect
Tower Repair Kit      | 50 Gold          | Restore tower to full HP
Building Repair Kit   | 30 Gold          | Restore one building to full HP
Arrow Tower (placed)  | 40 Gold + 2 Mat  | Skip build mode, auto-place next mission
Mana Draught          | 20 Gold          | Sybil starts next mission at full mana

---

CAMPAIGN STRUCTURE (MVP)

- 5 missions, fixed linear sequence — no territory map
- Missions named "Mission 1" through "Mission 5"
- Placeholder briefing screen: grey + "MISSION [X]" + "PRESS ANY KEY TO START"
- After Mission 5: End screen — "YOU SURVIVED — Foul Ward v0.1" + Quit button

Between-Mission Screen (3 tabs):
1. Shop — buy consumables
2. Research — spend Research Material
3. Buildings — view placed buildings (view only, buildings carry over)
Single "NEXT MISSION" button to proceed.

---

MAIN MENU

- Start → Mission 1 (all resources reset to starting values)
- Settings → empty screen + "Back" button (placeholder only)
- Quit → closes game

---

HUD ELEMENTS

Always visible during missions:
- Top left: Gold | Material | Research
- Top center: Wave X / 10 + countdown timer ("Next wave: 18s")
- Top right: Tower HP bar
- Bottom center: Shockwave button + mana bar + cooldown timer
- Bottom right: Weapon 1 ammo/cooldown + Weapon 2 ammo/cooldown
- Reminder label: "[B] Build Mode"

---

SIMULATION TESTING DESIGN (Architectural Constraint)

All game systems must be fully decoupled from player input handling.
A headless GDScript bot must be able to drive the entire game loop
by connecting to signals and calling public methods — zero UI interaction.

This enables future automated playtesting:
- "Buy only arrow towers" strategy bot
- "Buy only fire buildings" strategy bot
Each bot plays through all waves/missions, then reports findings to a log file.

EVERY MANAGER MUST expose its core actions as callable public methods.
NO game logic may live inside UI scripts or input handlers.

---

TECHNICAL NOTES FOR CLAUDE OPUS

Scene Structure:
- Main.tscn            — root scene, game manager node
- Tower.tscn           — central tower with HP component
- HexGrid.tscn         — 24-slot hex grid manager
- Building.tscn        — base building class, 8 subtypes
- Enemy.tscn           — base enemy class, 6 subtypes
- Arnulf.tscn          — AI character, state machine
- Projectile.tscn      — base projectile, 2 subtypes (crossbow bolt, rapid missile)
- WaveManager.gd       — wave spawning, scaling, countdown
- EconomyManager.gd    — gold, material, research tracking + transactions
- SpellManager.gd      — Sybil's spells, mana, cooldowns
- UIManager.gd         — HUD, build menu, between-mission screen
- GameManager.gd       — mission state, session progression (1 to 5)
- DamageCalculator.gd  — damage type x vulnerability matrix
- SimBot.gd            — headless strategy bot (stub only in MVP, no logic yet)

Key Systems to Architect:
1. Projectile system (travel time, collision, miss detection, 2 projectile types)
2. Hex grid slot management (placement, sell, upgrade, radial menu)
3. Enemy pathfinding (NavigationAgent3D or simple Vector3 steering for MVP)
4. Wave scaling formula (N enemies per type on wave N, max 10)
5. Build mode time scaling (Engine.time_scale = 0.1)
6. Damage type + vulnerability matrix (4 types x 4 armor types)
7. Between-mission persistence (resources + buildings carry over; tower HP does NOT
   reset between waves but DOES reset between missions)
8. Arnulf state machine (patrol, chase, attack, downed, recover — loops infinitely)
9. Mana regeneration + spell cooldown system
10. Simulation decoupling (all managers expose public API callable without UI/input)

Damage Matrix:
              Physical  Fire  Magical  Poison
Unarmored:    1.0       1.0   1.0      1.0
Heavy Armor:  0.5       1.0   2.0      1.0
Undead:       1.0       2.0   1.0      0.0
Flying:       1.0       1.0   1.0      1.0

GdUnit4 Test Targets:
- Wave scaling: wave N = N per type, total = N x 6
- Damage calculation: type x vulnerability matrix
- Economy: add/subtract gold, material costs, research unlock gates
- Arnulf state machine: all transitions
- Mana: rate over time, cap at max, deduct on cast, block during cooldown
- Building sell: full resource refund verified
- Mission progression: state advances correctly 1 to 5 to end
- Simulation API: all manager public methods callable without UI nodes present
