# Context Brief — Session 4: Chronicle

## Meta-Progression: The Chronicle of Foul Ward (§14)

DOES NOT EXIST IN CODE. CONFIRMED ADDED TO DESIGN. Must be implemented.

See implementation spec: ChronicleData, ChroniclePerkData, achievement triggers via SignalBus.

## Signal Bus Reference — Game State + Campaign Signals (§24)

### Game State
| Signal | Parameters |
|--------|-----------|
| game_state_changed | old_state: Types.GameState, new_state: Types.GameState |
| mission_started | mission_number: int |
| mission_won | mission_number: int |
| mission_failed | mission_number: int |
| florence_state_changed | (none) |

### Campaign
| Signal | Parameters |
|--------|-----------|
| campaign_started | campaign_id: String |
| day_started | day_index: int |
| day_won | day_index: int |
| day_failed | day_index: int |
| campaign_completed | campaign_id: String |

### Combat (relevant for kill-count achievements)
| Signal | Parameters |
|--------|-----------|
| enemy_killed | enemy_type: Types.EnemyType, position: Vector3, gold_reward: int |
| boss_killed | boss_id: String |

### Buildings (relevant for building-count achievements)
| Signal | Parameters |
|--------|-----------|
| building_placed | slot_index: int, building_type: Types.BuildingType |

### Economy
| Signal | Parameters |
|--------|-----------|
| resource_changed | resource_type: Types.ResourceType, new_amount: int |

## How to Add a New Signal (§28.2)

1. Declare in autoloads/signal_bus.gd with typed parameters.
2. Add @warning_ignore("unused_signal") above the declaration.
3. Use past tense for events (achievement_completed), present for requests.
4. Emit from the relevant system using SignalBus.signal_name.emit(...).
5. Connect in listeners using is_connected guard pattern.
6. Update FoulWardTypes.cs if a new enum is involved.

## Open TBD — Chronicle (§33)
| Item | Question | Who Decides |
|------|----------|-------------|
| Chronicle perk strength | Cosmetic micro-buffs vs meaningful advantage? | Designer/playtester |

Decision for this session: Cosmetic micro-buffs only.

## SaveManager Structure (§3.13)

Save payload is a Dictionary with top-level keys:
- "version", "attempt_id", "campaign", "game", "relationship", "research", "shop", "enchantments"

Chronicle saves separately to user://chronicle.json (cross-run persistence).

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus
- is_instance_valid() before accessing enemies, projectiles, or allies
- push_warning() not assert() in production
- AllyRole enum: MELEE_FRONTLINE=0, RANGED_SUPPORT=1, ANTI_AIR=2, SPELL_SUPPORT=3 (TANK was removed)
