# FOUL WARD — Full project summary (handoff)

**Purpose:** Single document describing what this repository is, how it is organized, what each major part does, and where development stands. Intended for a new contributor or AI session (e.g. after cloning on Ubuntu) to regain context quickly.

**Engine:** Godot **4.6** (see `project.godot` → `config/features`). Main scene: `res://scenes/main.tscn`.

**Repository:** Remote is typically `https://github.com/JerseyWolf/FoulWard.git` (verify with `git remote -v`). Default branch: **`main`**.

---

## What the game is

**FOUL WARD** is a **PC tower-defense / action** prototype in Godot 4: **Florence** (tower weapons) + **Sybil** (Spells / Shockwave) + **Arnulf** (melee AI ally) + **hex-grid buildings** + **waves of six enemy types** across **5 missions × 10 waves**. The **MVP goal** is a playable loop: menu → missions → between-mission shop/research → win/lose, with **simulation-friendly APIs** (bots/tests can drive managers without UI).

Authoritative gameplay design: `docs/FoulWard_MVP_Specification.md`. Architecture and conventions (read-only reference for agents): `docs/ARCHITECTURE.md`, `docs/CONVENTIONS.md`, `docs/SYSTEMS_part*.md`.

---

## Top-level layout

| Path | Role |
|------|------|
| `autoloads/` | Singletons: `SignalBus`, `DamageCalculator`, `EconomyManager`, `GameManager`, `AutoTestDriver` |
| `scenes/` | Runtime scenes: `main.tscn`, `tower`, `Arnulf`, `hex_grid`, `enemies`, `buildings`, `projectiles`, UI scenes |
| `scripts/` | Managers attached under `Main/Managers` (Wave, Spell, Shop, Research, Input), `sim_bot.gd`, resource scripts |
| `resources/` | `enemy_data/`, `building_data/`, `weapon_data/`, `spell_data/`, `shop_data/`, `research_data/` (`.tres` + script classes) |
| `ui/` | HUD, main menu, between-mission, build menu, mission briefing, end screen, `ui_manager.gd` |
| `tests/` | GdUnit4 suites (`test_*.gd`) — **289** cases at last full run |
| `addons/` | **gdUnit4**, **godot_mcp** (editor integration), **gdai-mcp-plugin-godot** (GDAI MCP bridge) |
| `tools/` | MCP helpers (`mcp-support`), autotest scripts, etc. |
| `MCPs/` | Optional copy of Godot MCP Pro vendor tree; `server/node_modules` is gitignored |

---

## Autoloads (global)

- **`SignalBus`** — Central typed signals (combat, economy, game state, waves, shop, research, build mode).
- **`DamageCalculator`** — Damage type × armor × vulnerability matrix.
- **`EconomyManager`** — Gold, building material, research material; spend/add/reset.
- **`GameManager`** — Mission index, wave index (via `WaveManager` sync where applicable), `Types.GameState` (menu, combat, build mode, briefing, between missions, etc.), mission win/fail, **shop mission-start consumables** (mana draught, prepaid Arrow Tower).
- **`AutoTestDriver`** — Headless smoke driver (optional; autoload for scripted checks).

MCP-related autoloads from `addons/godot_mcp/` (`MCPScreenshot`, `MCPInputService`, `MCPGameInspector`) support editor MCP tooling when the plugin is enabled.

---

## Main scene (`scenes/main.tscn`) — mental model

Under **`Main`** (Node3D):

- **Tower** — Player weapons (crossbow + rapid missile), HP, aim; can integrate shop tower repair.
- **Arnulf** — Melee AI ally (state machine).
- **HexGrid** — 24 slots, **BuildingData** registry, place/sell/upgrade, **research-gated** buildings, **shop free placement** for Arrow Tower voucher.
- **SpawnPoints** — `Marker3D` for wave spawns.
- **EnemyContainer**, **BuildingContainer**, **ProjectileContainer**.
- **Managers** — `WaveManager`, `SpellManager`, `ResearchManager`, `ShopManager`, `InputManager`.
- **UI** — `UIManager`, HUD, build menu, between-mission screen, main menu, mission briefing, end screen.

---

## Core systems (where logic lives)

| System | Primary locations |
|--------|-------------------|
| Waves & enemies | `scripts/wave_manager.gd`, `scenes/enemies/enemy_base.gd`, `resources/enemy_data/*.tres` |
| Tower weapons | `scenes/tower/tower.gd`, `resources/weapon_data/*.tres` |
| Projectiles | `scenes/projectiles/projectile_base.gd` |
| Buildings | `scenes/buildings/building_base.gd`, `resources/building_data/*.tres`, HexGrid placement |
| Research | `scripts/research_manager.gd`, `resources/research_data/*.tres`, `BuildingData` unlock + boost fields |
| Shop | `scripts/shop_manager.gd`, `resources/shop_data/*.tres` — four MVP items (tower repair, building repair, mana draught, arrow tower voucher) |
| Spells / mana | `scripts/spell_manager.gd`, `resources/spell_data/shockwave.tres` |
| UI / flow | `ui/ui_manager.gd`, `ui/mission_briefing.gd`, `game_manager.gd` state machine |
| Simulation / bot | `scripts/sim_bot.gd`, `tests/test_simulation_api.gd` |

---

## Game flow (simplified)

1. **Main menu** → `GameManager.start_new_game()` → mission 1, **COMBAT**, economy defaults, **`apply_mission_start_consumables()`** (shop vouchers), wave sequence starts.
2. **Between missions** → `BETWEEN_MISSIONS` — shop / research / buildings tabs; **Next mission** → briefing → **`start_wave_countdown()`** → COMBAT + consumables + waves.
3. **Mission briefing** (`MISSION_BRIEFING`) — mission UI only; **Begin** starts waves (see `game_manager.gd` + `mission_briefing.gd`).
4. **Win** — all waves cleared → rewards → `BETWEEN_MISSIONS` or **GAME_WON** after mission 5.
5. **Lose** — tower destroyed → **MISSION_FAILED**.

---

## Data-driven content

- **No hardcoded combat stats in random scripts** — prefer `.tres` under `resources/` loaded by registries on managers / scenes (per project rules in Cursor).
- **Enemy / building / weapon / spell / shop / research** each have resource scripts under `scripts/resources/`.

---

## Tests

- **Framework:** GdUnit4 (`addons/gdUnit4`).
- **Last known full run:** **289** test cases, **0** failures (headless `GdUnitCmdTool.gd`; see `CURRENT_STATUS.md` for command).
- **Note:** On some Windows setups Godot may **SIGSEGV after** the test run; use the **Overall Summary** line as the pass/fail truth.

---

## What is implemented vs open (MVP tracking)

Detailed checklist: **`AUTONOMOUS_SESSION_2.md`**.

**Largely in place:** wave scaling, damage matrix, economy, shop (four items), research tree (six nodes), mission briefing path, simulation API tests, SimBot activate/deactivate hygiene, git LF/binary attributes for Linux clones.

**Still open / manual:** Phase **6** twelve playtest checks; optional enemy stat tuning; HUD polish. **Phase 2** headless main-scene smoke is automated on Linux (`tools/smoke_main_scene.sh`, exit 0); on **Windows**, headless main may still be unreliable — prefer **editor F5** for full loop validation there.

---

## Related handoff files

- **`CURRENT_STATUS.md`** — How to recreate this workspace (Godot, Cursor, MCP, npm, tests) on a new machine.
- **`AUTONOMOUS_SESSION_2.md`** — Phase checklist and session notes.

---

*Generated for repository handoff; update when major systems or counts change.*
