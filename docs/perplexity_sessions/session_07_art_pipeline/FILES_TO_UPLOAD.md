# Files to Upload for Session 7: Art Pipeline

**Errata (single-file bundle):** The standalone file `FILES_TO_UPLOAD.md` is **not** attached for Perplexity. This manifest exists for repo maintainers; for Perplexity, its entire contents (this list and the full text of every path below) are merged into `SESSION_07_FULL_PROMPT.md` in this folder.

Listed repository paths:

1. `scripts/art/art_placeholder_helper.gd` — Runtime mesh/material resolver; full file (~444 lines)
2. `scripts/art/rigged_visual_wiring.gd` — GLB mount + animation mapping; full file (~117 lines)
3. `FUTURE_3D_MODELS_PLAN.md` — Production 3D art roadmap; full file (~321 lines)
4. `docs/FOUL WARD 3D ART PIPELINE.txt` — Full 5-stage art pipeline strategy (~358 lines)
5. `scenes/enemies/enemy_base.gd` — EnemyBase; lines 1-50 covering visual slot setup (~50 lines)
6. `scenes/arnulf/arnulf.gd` — Arnulf; lines 130-140 covering ArnulfVisual (~10 lines)
7. `scenes/bosses/boss_base.gd` — BossBase; lines 40-50 covering BossVisual (~10 lines)

Total estimated token load: ~1,310 lines across 7 files

Note: art_placeholder_helper.gd (444 lines) is the largest file. If Perplexity context is tight, upload lines 1-200 only (mesh resolution logic; the rest is material lookup tables).
