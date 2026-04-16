# Files to Upload for Session 2: Sybil Passives

**Errata (single-file bundle):** The standalone file `FILES_TO_UPLOAD.md` is **not** attached for Perplexity. This manifest exists for repo maintainers; for Perplexity, its entire contents (this list and the full text of every path below) are merged into `SESSION_02_FULL_PROMPT.md` in this folder.

Listed repository paths:

1. `scripts/types.gd` — Enum definitions; lines 1-100 covering GameState, DamageType, and existing enum patterns (~100 lines)
2. `scripts/spell_manager.gd` — Scene-bound spell manager; full file (~320 lines)
3. `autoloads/game_manager.gd` — Autoload game state machine; lines 55-120 covering _ready, state transitions, mission start (~65 lines)
4. `autoloads/signal_bus.gd` — Central signal hub; lines 1-50 showing signal declaration patterns (~50 lines)
5. `scripts/resources/spell_data.gd` — SpellData resource class definition (~34 lines)

Total estimated token load: ~569 lines across 5 files
