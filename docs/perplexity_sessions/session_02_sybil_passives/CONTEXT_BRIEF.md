# Context Brief — Session 2: Sybil Passives

## AI Companions — Sybil (§2.2)

STATUS: EXISTS IN CODE (spell management); PASSIVE SYSTEM PLANNED

- Role: Spell researcher / spell support.
- Manages the spell system via SpellManager.
- PLANNED — Sybil Passive Selection System (not yet in code).

## Game States (§6)

Defined in res://scripts/types.gd as Types.GameState.

Transition graph: MAIN_MENU -> MISSION_BRIEFING -> COMBAT <-> BUILD_MODE -> WAVE_COUNTDOWN -> (COMBAT loop) -> MISSION_WON/MISSION_FAILED -> BETWEEN_MISSIONS -> MISSION_BRIEFING...

PLANNED states: RING_ROTATE (pre-battle ring rotation), PASSIVE_SELECT (Sybil passives).

### GameState Enum (current values)
| Name | Value |
|------|-------|
| MAIN_MENU | 0 |
| MISSION_BRIEFING | 1 |
| COMBAT | 2 |
| BUILD_MODE | 3 |
| WAVE_COUNTDOWN | 4 |
| BETWEEN_MISSIONS | 5 |
| MISSION_WON | 6 |
| MISSION_FAILED | 7 |
| GAME_WON | 8 |
| GAME_OVER | 9 |
| ENDLESS | 10 |

## Spells (§7)

Manager: SpellManager (scene node under /root/Main/Managers/) — max_mana: 100, mana_regen_rate: 5.0/sec.

Four registered spells:
| .tres File | Display Name | Mana | Cooldown |
|-----------|-------------|------|----------|
| shockwave.tres | Shockwave | 50 | 60s |
| slow_field.tres | Slow Field | — | — |
| arcane_beam.tres | Arcane Beam | — | — |
| tower_shield.tres | Aegis Pulse | — | — |

slow_field.tres has damage = 0.0 intentionally (control spell).

## SpellManager API (§4.2)

| Signature | Returns | Usage |
|-----------|---------|-------|
| cast_spell(spell_id: String) -> bool | bool | Casts if mana/cooldown OK |
| get_available_spells() -> Array[SpellData] | Array | All registered spells |
| get_current_mana() -> int | int | Current mana |
| get_max_mana() -> int | int | Max mana |
| get_mana_regen_rate() -> float | float | Mana per second |
| is_spell_ready(spell_id: String) -> bool | bool | Cooldown + mana check |

## Full Mission Cycle — Mission Start Flow (§27.1, steps 1-2)

1. MAIN_MENU -> User clicks "Start"
2. GameManager.start_new_game()
   -> EconomyManager.reset_to_defaults()
   -> EnchantmentManager.reset_to_defaults()
   -> ResearchManager.reset_to_defaults()
   -> WeaponUpgradeManager.reset_to_defaults()
   -> FlorenceData.reset_for_new_run()
   -> CampaignManager.start_new_campaign()
     -> _bootstrap_starter_allies()
     -> _start_current_day_internal()
       -> SignalBus.day_started.emit(1)
       -> CampaignManager._load_terrain(territory)
       -> GameManager.start_mission_for_day(1, day_config)
         -> _transition_to(COMBAT)
         -> BuildPhaseManager.set_build_phase_active(false)
         -> SignalBus.mission_started.emit(1)

## Formally Cut Features (§31)
| Feature | Status |
|---------|--------|
| Arnulf drunkenness system | FORMALLY CUT |
| Time Stop spell | FORMALLY CUT |
| Hades-style 3D navigable hub | FORMALLY CUT |

Note: Sybil passive selection is PLANNED, not cut.

## Open TBD — Sybil (§33)
| Item | Question | Who Decides |
|------|----------|-------------|
| Sybil passive selection | Single pick before mission OR all passives always active? | Designer |

Decision for this session: Single pick before mission.

## Signal Declaration Patterns

Signals are declared in autoloads/signal_bus.gd with typed parameters:
```
signal sybil_passive_selected(passive_id: String)
```
Past tense for events, present for requests. All signals carry @warning_ignore("unused_signal").

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus
- _physics_process for game logic — _process for visual/UI only
- Scene instantiation: call initialize() before or immediately after add_child()
- get_node_or_null() for runtime lookups with null guard
- AllyRole enum: MELEE_FRONTLINE=0, RANGED_SUPPORT=1, ANTI_AIR=2, SPELL_SUPPORT=3 (TANK was removed)
- dialogue_line_started and dialogue_line_finished are now on SignalBus (not locally in DialogueManager)
