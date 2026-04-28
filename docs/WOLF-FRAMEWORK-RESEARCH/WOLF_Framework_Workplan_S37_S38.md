# WOLF Framework — Master Workplan
## Phase 2 Sessions S37–S38
### Balance Pass · Asset Pass

**Document version:** 1.0 | **Continues from:** Chunk 4c (S36)
**Covers:** S37 and S38 — the two finishing sessions that close Phase 2.
**Prerequisites:** All S21–S36 complete and passing their own GdUnit4 suites.
After S38 is accepted, Phase 2 is closed and Phase 3 begins.

---

## Positioning

S37 and S38 are not new games. They are systematic quality passes across the entire
Phase 2 game catalogue. S37 uses the SimBot balance optimiser to bring all six core
MVPs within the ±5% win-rate target. S38 uses the art and audio pipelines to replace
every placeholder asset with a generated one. Both sessions produce changes spread
across multiple game folders rather than a single new deliverable, which requires a
different session structure: a triage order, a per-game checklist, and explicit
acceptance criteria at the end. [file:1]

---

## Session S37 — Balance Pass

**Goal:** Run the SimBot balance optimiser across all six core MVPs, apply the
recommended stat changes, re-run to verify win-rate convergence, and produce a
final `BALANCE_REPORT.md` that documents the tuned values for every game — so
that any future contributor adding content knows the calibration baseline they
must maintain. [file:1]

### What "balanced" means for each genre

The optimiser's objective is the same for all games: minimise variance in win-rate
across the three standard SimBot loadout presets (baseline, rush, turtle) with a
target of all three presets within ±5% of each other. Genre-specific secondary
targets are listed below. [file:1]

| Game | Primary target | Secondary target |
|------|---------------|-----------------|
| WOLF-TD | Wave 5 reachable by baseline; not trivially won by turtle | Wave 3 reachable by rush without cheese build |
| WOLF-TD-GRID | All 10 waves clearable; wave 10 requires active play | Tower upgrade sequence is meaningful (tier 1 viable through wave 5) |
| WOLF-RTS | Match length 8–14 minutes; no instant wins from early rush | Both factions win roughly 50/50 in mirror matches |
| WOLF-FLOW-RTS | Nanostall occurs at least once per match in baseline | Commander kill is decisive, not a formality |
| WOLF-CARD | 3-room run clearable in 30–50% of baseline attempts | Boss not trivial on first attempt; retries feel different |
| WOLF-AUTO | Round 6 clear rate 40–60% across presets | Merge opportunity available in most runs |
| WOLF-SYNERGY | Active synergy at least once per winning run | No single synergy dominates win rate by >15% |
| WOLF-DUNGEON | All three waves repelled in 50–70% of full-army runs | Creature morale panic occurs at least once per strained run |
| WOLF-CRISIS | Week 12 survival in 40–60% of optimal-play runs | All four decrees used at least once in winning runs |
| WOLF-GRAND | Both contested provinces contested in 80%+ of runs | Tech tree branch 2 unlocked before turn 8 in optimal play |

[file:1]

### Triage order

The optimiser runs in this order, most impactful to least: [file:1]

1. WOLF-FLOW-RTS — nanostall timing is the hardest value to tune by hand [file:1]
2. WOLF-SYNERGY — synergy GAS effects stack in ways hand-tuning cannot predict [file:1]
3. WOLF-SURVIVAL — night-wave difficulty interacts with province resource gating [file:1]
4. WOLF-CARD — boss HP and deck-size interact in non-obvious ways [file:1]
5. WOLF-RTS — faction mirror balance [file:1]
6. WOLF-AUTO — round escalation curve [file:1]
7. WOLF-TD — wave 5 boss HP [file:1]
8. WOLF-TD-GRID — tower upgrade value [file:1]
9. WOLF-DUNGEON — creature morale threshold [file:1]
10. WOLF-CRISIS — infection spread coefficient [file:1]
11. WOLF-GRAND — province yield rates [file:1]
12. WOLF-NECRO, WOLF-ROGUE, WOLF-NARRATIVE, WOLF-DECKBUILDER — sanity check only;
    no full optimiser pass (these games are not SimBot-primary) [file:1]

### Perplexity context to load

- Chunk 3 S15 deliverables: `balance_optimiser.py`, `simbot_swarm.py`,
  `simbot_config.yaml`, `BalanceGuardrails.tres` pattern, `rag_indexer_hook.py` [file:1]
- All `config/simbot/games/{game-name}.yaml` files created during S21–S35 [file:1]
- All `BalanceGuardrails.tres` resources created per game [file:1]
- `tools/simbot/output/` for any prior SimBot runs from Phase 2 sessions [file:1]

### Key questions for this session

1. When the optimiser recommends a stat change, where exactly does the change
   land? Recommendation: always in the unit or building `*.tres` resource file,
   never in a script. The change is a `tres` field edit, committed to the game's
   repo with the message format `[balance] wolf-rts: HeavyTank HP 400→380 (optimiser pass 1)`. [file:1]
2. How many optimiser iterations are enough per game? Recommendation: run until
   win-rate variance is below 5% OR after 3 full passes — whichever comes first.
   If 3 passes do not converge, document the game as "intentionally uneven" in
   `BALANCE_REPORT.md` with rationale. [file:1]
3. Should all games share one `BalanceGuardrails.tres` or have per-game files?
   Recommendation: per-game files already set up during Phase 2; S37 reviews and
   tightens the bounds based on what the optimiser actually tried. [file:1]
4. What happens to games where SimBot cannot meaningfully run (WOLF-NARRATIVE,
   WOLF-ROGUE in narrative room)? Recommendation: mark as `simbot_mode: sanity_only`
   in their config; run one seed, confirm no crash, no balance output expected. [file:1]

### Cursor prompts to generate (6 prompts)

1. Write `tools/simbot/run_balance_pass.sh` — orchestration script for the full
   S37 pass; iterates through the triage order list; for each game: runs
   `wolf simbot run baseline --game {game}`, then `wolf simbot optimise --game {game}`,
   then applies recommended changes to `*.tres` files automatically if the
   confidence score is above 0.8, otherwise writes them to a manual review queue;
   re-runs SimBot to verify convergence; writes per-game status to
   `tools/simbot/output/s37_pass_log.md` [file:1]

2. Write `tools/simbot/apply_recommendations.py` — reads
   `simbot_optimiser_recommendations.md` for a given game; parses recommended
   stat changes; opens the correct `.tres` file using `gdresource_parser.py`;
   applies changes; writes a git-commit-message template file
   `tools/simbot/output/{game}/balance_commit_msg.txt` for the developer to review
   before committing; includes a dry-run mode that prints changes without writing [file:1]

3. Run the full balance pass for WOLF-FLOW-RTS (priority 1) — document the exact
   command sequence, SimBot output before tuning, recommended changes, applied
   changes, and SimBot output after; record: initial win-rate variance, final
   win-rate variance, number of passes required, nanostall frequency before and
   after; paste results into session result report [file:1]

4. Run the full balance pass for WOLF-SYNERGY (priority 2) and WOLF-CARD
   (priority 4) — same documentation format; for WOLF-SYNERGY specifically:
   report which synergy had the highest individual win-rate delta and what stat
   change brought it into line; confirm no single synergy provides >15% win-rate
   advantage after tuning [file:1]

5. Run balance passes for WOLF-TD, WOLF-TD-GRID, WOLF-RTS, WOLF-AUTO,
   WOLF-DUNGEON, WOLF-CRISIS, WOLF-GRAND (priorities 5–11); for each: one
   paragraph in session result report, final win-rate table (baseline/rush/turtle),
   list of changed `.tres` values; commit all changes with correct message format [file:1]

6. Write `framework/docs/BALANCE_REPORT.md` — the master balance reference
   document; sections: balance philosophy, SimBot methodology, per-game tuned
   value tables (unit HP, attack, cost for all MVPs), per-game win-rate table
   (before/after), games marked `sanity_only`, BalanceGuardrails bounds summary,
   guidance for future contributors ("if you add a new unit, run SimBot before
   submitting a PR"); commit to `wolf-framework` main [file:1]

### Deliverables

- [ ] `tools/simbot/run_balance_pass.sh` [file:1]
- [ ] `tools/simbot/apply_recommendations.py` [file:1]
- [ ] All 11 primary games SimBot-run to convergence (verified) [file:1]
- [ ] Per-game win-rate variance ≤ 5% for all 11 primary games OR documented
      exception in `BALANCE_REPORT.md` (verified) [file:1]
- [ ] All stat changes committed to correct `*.tres` files with correct message format [file:1]
- [ ] `BalanceGuardrails.tres` bounds reviewed and tightened per game [file:1]
- [ ] `framework/docs/BALANCE_REPORT.md` complete and committed [file:1]
- [ ] `wolf rag index --corpus fw-balance` run after all balance commits;
      `wolf rag query "what is the tuned HP of WOLF-RTS HeavyTank?"` returns
      correct value from the report (verified) [file:1]

### Unlocks

S39 docs site can publish `BALANCE_REPORT.md` as a dedicated "Balance & Tuning"
reference page. Future contributors can run `wolf simbot run baseline --game {game}`
before submitting a PR and compare against this baseline to catch accidental
regressions. [file:1]

---

## Session S38 — Asset Pass

**Goal:** Run the full art and audio pipelines across all fifteen demo games,
replacing every placeholder asset with a generated one, so that the showcase
launcher and all games look and sound like intentional works rather than
prototypes with debug visuals. [file:1]

### Pipeline recap

The art pipeline is five stages (from S03): [file:1]

1. **FLUX** — generate character concept sheet from faction + archetype + style prompt [file:1]
2. **TRELLIS.2** — convert concept to 3D mesh [file:1]
3. **UniRig / Mixamo** — rig the mesh [file:1]
4. **Blender animation** — bake idle, walk, attack, death animations [file:1]
5. **Godot import** — drop GLB into correct asset folder, verify import settings [file:1]

The audio pipeline is three stages (from S05): [file:1]

1. **AudioCraft SFX** — generate per-event sound effects from text prompts [file:1]
2. **MusicGen stems** — generate 2–4 looping music stems per game [file:1]
3. **Godot audio import** — convert to OGG, assign via SoundBridge [file:1]

### Art generation priority and strategy

Not every game needs unique character models. Games that share a faction skin
(e.g., WOLF-TD and WOLF-NECRO both use plague/undead themes) should share base
meshes and use material swaps for variation. The priority tiers are: [file:1]

**Tier 1 — Full pipeline (all 5 stages, unique models):**
WOLF-TD (Florence player model + Grimsby + 4 enemies), WOLF-RTS (4 unit types per
faction = 8 models), WOLF-DUNGEON (3 creature types + 3 hero invaders), WOLF-AUTO
(8 autobattler units) [file:1]

**Tier 2 — Mesh reuse with material swap:**
WOLF-NECRO reuses WOLF-DUNGEON creature meshes with bone/corruption material
variants; WOLF-SYNERGY reuses WOLF-AUTO unit meshes with 2-star/3-star material
upgrades; WOLF-FLOW-RTS reuses WOLF-RTS meshes with different faction colour sets [file:1]

**Tier 3 — 2D sprites (no 3D pipeline):**
WOLF-CARD, WOLF-DECKBUILDER (card art only — 2D painted style via FLUX);
WOLF-NARRATIVE (NPC portrait art — 2D); WOLF-GRAND, WOLF-CRISIS (province map
icons, adviser portraits — 2D) [file:1]

**Tier 4 — Preview images and showcase assets:**
All 15 games need a `preview.png` (1280×720, 16:9) for the showcase launcher;
WOLF-SURVIVAL, WOLF-ROGUE get a `.webm` preview clip (15 seconds, 720p) for the
hero panel video autoplay [file:1]

### Audio generation priority

Every game gets at minimum: one ambient loop, three combat SFX, one UI confirm SFX,
one win jingle (3s), one lose sting (2s). Tier 1 games additionally get a full
music stem set (intro, loop A, loop B, boss). [file:1]

| Game | Music tier | Key SFX to generate |
|------|-----------|-------------------|
| WOLF-TD | Full stems | Arrow fire, grunt hit, wave horn, build place |
| WOLF-RTS | Full stems | Unit select, attack, building complete, enemy alert |
| WOLF-DUNGEON | Full stems | Dig, room complete, creature growl, invasion horn |
| WOLF-AUTO | Full stems | Card buy, deploy, merge pop, round start |
| WOLF-SURVIVAL | Full stems | Day bell, night horn, province lost, tower place |
| WOLF-CARD | Full stems | Card draw, card play, energy spend, run clear |
| All others | Ambient + UI | Ambient loop, confirm, cancel, win, lose |

[file:1]

### Perplexity context to load

- Chunk 1 S03 deliverables: `studio.py`, Gen3D pipeline stages, known bugs [file:1]
- Chunk 1 S05 deliverables: `audio_pipeline.py`, AudioCraft SFX and MusicGen
  commands, output format (OGG, 22kHz) [file:1]
- All `assets/generated/` manifest files from Phase 2 sessions [file:1]
- `framework/skills/wolf-pipelines.md` from S18 — pipeline command reference [file:1]

### Key questions for this session

1. The Gen3D pipeline has two known bugs from S03. What are they and have they
   been fixed? Recommendation: address both before starting the Tier 1 batch to
   avoid cascading failures. Document the fixes in `SETUP.md`. [file:1]
2. How should material swaps work in Godot for Tier 2 mesh reuse? Recommendation:
   use Godot's `surface_material_override` on `MeshInstance3D` nodes in the
   reusing game's scene, referencing the base game's GLB but with a new
   `StandardMaterial3D` resource. No GLB forking. [file:1]
3. Card art generation for WOLF-CARD and WOLF-DECKBUILDER: should every card have
   unique art? Recommendation: the 20 starter cards get unique FLUX generations;
   reward pool cards share a 6-illustration set by card category to stay within
   the session's time budget. [file:1]
4. Preview image for the showcase: should it be a hand-composed Godot screenshot
   or a FLUX generation? Recommendation: Godot screenshot for accuracy, then
   FLUX-generated atmospheric overlay for visual appeal. Final composite saved
   as `preview.png`. [file:1]

### Cursor prompts to generate (7 prompts)

1. Audit the two known Gen3D pipeline bugs from S03 and fix them — write the
   bug diagnosis and fix in `SETUP.md` under "Known Pipeline Issues"; confirm
   `wolf art generate test_unit PLAYER humanoid` completes all 5 stages without
   error; if the TRELLIS.2 → UniRig handoff bug is still present, write a manual
   rigging fallback step using Mixamo web API instead [file:1]

2. Run Tier 1 art generation batch — WOLF-TD characters: `wolf art generate
   florence_tower PLAGUE humanoid`, `wolf art generate grimsby_fighter SURVIVOR
   humanoid`, `wolf art generate skeleton_basic PLAGUE humanoid`, `wolf art generate
   armoured_ghoul PLAGUE humanoid`, `wolf art generate plague_carrier PLAGUE
   humanoid`, `wolf art generate plague_lord PLAGUE boss`; verify all 6 GLBs
   import correctly into WOLF-TD `assets/characters/`; update manifest.json;
   document any stage failures and workarounds [file:1]

3. Run Tier 1 art generation for WOLF-RTS (8 unit models: 4 per faction),
   WOLF-DUNGEON (6 models: 3 creatures + 3 hero invaders), WOLF-AUTO (8
   autobattler unit models); document total generation time, any failed stages,
   and GLB quality checks (poly count within budget, rig weight painting acceptable,
   animations bake cleanly); commit all GLBs to respective game `assets/characters/` [file:1]

4. Run Tier 2 material-swap pass — for WOLF-NECRO: open each WOLF-DUNGEON creature
   scene, override materials with bone/corruption variants (grey-white base, green
   glow on corruption emission channel); for WOLF-SYNERGY: create 2-star and 3-star
   material variants for all 8 WOLF-AUTO units (metallic increase and emissive glow
   at higher stars); for WOLF-FLOW-RTS: create faction colour sets for WOLF-RTS
   base meshes; commit all `StandardMaterial3D` resources to the respective games [file:1]

5. Run Tier 3 and Tier 4 — FLUX card art for all 20 WOLF-CARD starter cards
   (512×512 PNG per card, painterly plague-medieval style, cards update their
   `CardData.tres` texture path); NPC portrait art for WOLF-NARRATIVE (three
   character portraits 512×512 PNG); province map icons for WOLF-GRAND and
   WOLF-CRISIS; generate all 15 `preview.png` showcase images (1280×720 Godot
   screenshot + FLUX atmospheric overlay); generate WOLF-SURVIVAL and WOLF-ROGUE
   `.webm` preview clips (15s, 720p, captured via Godot's built-in movie maker) [file:1]

6. Run full audio generation pass — for each Tier 1 game: `wolf audio music
   "{game_style} ambient loop" --stems`, `wolf audio sfx "{event_description}"
   --category combat --duration 1.5` for each listed SFX; for all other games:
   ambient loop + UI set only; total target: at minimum 1 music loop and 3 SFX
   per game; verify all OGG files import into Godot without warnings; assign to
   SoundBridge audio buses in each game's `AudioConfig.tres` [file:1]

7. Write `framework/docs/ASSET_MANIFEST.md` — master record of every generated
   asset across all games: art assets (GLB path, unit name, stage that produced it,
   generation date, poly count), audio assets (OGG path, game, event type, duration,
   generation model used), card art (PNG path, card name), preview images (PNG/WEBM
   path, game); this document feeds the HuggingFace dataset card in Phase 3;
   run `wolf rag index --corpus fw-art` after committing to verify the art pipeline
   RAG corpus picks up new manifest entries [file:1]

### Deliverables

**Art:**
- [ ] Tier 1 GLBs: all 28 character models (WOLF-TD ×6, WOLF-RTS ×8, WOLF-DUNGEON ×6, WOLF-AUTO ×8) [file:1]
- [ ] All Tier 1 GLBs import correctly in their respective game projects [file:1]
- [ ] Tier 2 material variants committed for WOLF-NECRO, WOLF-SYNERGY, WOLF-FLOW-RTS [file:1]
- [ ] 20 WOLF-CARD card art PNGs [file:1]
- [ ] 3 WOLF-NARRATIVE NPC portrait PNGs [file:1]
- [ ] Province map icons for WOLF-GRAND and WOLF-CRISIS [file:1]
- [ ] 15 `preview.png` showcase images (1280×720) [file:1]
- [ ] WOLF-SURVIVAL `preview.webm` and WOLF-ROGUE `preview.webm` [file:1]

**Audio:**
- [ ] Tier 1 music stems (4 games × ~4 stems = ~16 OGG files) [file:1]
- [ ] Ambient loops for all 15 games [file:1]
- [ ] Per-event SFX for all games (minimum 3 per game = 45+ OGG files) [file:1]
- [ ] All OGG files assigned in `AudioConfig.tres` per game [file:1]

**Documentation:**
- [ ] Gen3D pipeline bug fixes documented in `SETUP.md` [file:1]
- [ ] `framework/docs/ASSET_MANIFEST.md` complete and committed [file:1]
- [ ] `wolf rag index --corpus fw-art` returns entries from new manifest (verified) [file:1]

**Acceptance check:**
- [ ] Launch WOLF-SHOWCASE; all 15 game cards display a preview image (no
      missing texture fallbacks) [file:1]
- [ ] Launch WOLF-TD; Florence model renders with correct animations in Godot [file:1]
- [ ] Launch WOLF-CARD; all 20 cards display unique art [file:1]
- [ ] All SFX audible in their correct trigger contexts (verified per game) [file:1]

### Unlocks

After S38 is accepted, Phase 2 is formally closed. The `PHASE2_ACCEPTANCE_REPORT.md`
is committed to `wolf-framework` main alongside `PHASE1_ACCEPTANCE_REPORT.md`.
Phase 3 begins: docs site (S39), HuggingFace asset publishing (S40), community
infrastructure (S41), and launch announcement (S42). [file:1]

---

## Phase 2 Final Status Table

| Session | Game/Task | Required for Phase 3 | Status after S38 |
|---------|-----------|---------------------|-----------------|
| S21–S35 | All 15 playable demos | Yes | ✅ |
| S36 | WOLF-SHOWCASE launcher | Yes | ✅ |
| S37 | Balance Pass | Yes — BALANCE_REPORT needed for docs | ✅ |
| S38 | Asset Pass | Yes — preview images needed for launcher | ✅ |

---

## PHASE2_ACCEPTANCE_REPORT.md — Required Sections

This document is committed at the end of S38 and formally closes Phase 2. [file:1]

- **Games Checklist** — all 15 games ticked against their core deliverables [file:1]
- **Launcher Status** — WOLF-SHOWCASE screenshots at two resolutions [file:1]
- **Balance Summary** — link to `BALANCE_REPORT.md`, summary of convergence results [file:1]
- **Asset Summary** — GLB count, OGG count, card art count, total pipeline runtime [file:1]
- **Test Suite Status** — GdUnit4 total across all Phase 2 projects (target: >120 passing tests) [file:1]
- **Known Issues** — any games with documented balance exceptions or missing
  Tier 1 models due to pipeline failures [file:1]
- **Phase 3 Readiness** — confirm docs site can start: WOLF logo ready, preview
  images ready, BALANCE_REPORT ready, SYSTEMS_REFERENCE ready [file:1]

*End of S37–S38 document. Phase 2 is complete when
PHASE2_ACCEPTANCE_REPORT.md is committed to main.* [file:1]
