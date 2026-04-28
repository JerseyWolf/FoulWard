# WOLF Framework — Master Workplan
## Chunk 3 of 5: Phase 1 Sessions S15–S20
### SimBot · CI/CD · wolf CLI · Cursor Skills · Doc Automation · Integration Test

**Document version:** 1.0 | **Continues from:** Chunk 2 (S08–S14)
**Covers:** Sessions S15–S20 — the final six sessions of Phase 1.
After S20, the framework is feature-complete, all systems are proven working
together, and the repo is ready to receive Phase 2 demo games.

---

## Session S15 — SimBot: Extraction, Generalisation & Balance Optimiser

**Goal:** The SimBot headless-Godot automated tester is extracted from Foul Ward,
generalised to work with any WOLF game's loadout configs, wired to the RAG
`fw-balance` corpus so every run auto-indexes its output, and extended with a
balance optimiser that uses `BalanceGuardrails.tres` to close the stat-tuning loop.

**Background:**
Foul Ward's SimBot runs headless Godot with three preset loadouts, a swarm runner
for parallel seeds, and produces a markdown balance report. The generalised version
needs to work against any game's `waves/` and `units/` resources — not just
Foul Ward's specific paths — and the optimiser must respect the guardrail bounds
from S13 so it cannot produce mathematically valid but gameplay-absurd results.

**Perplexity context to load:**
- Chunk 2 (S13 deliverables: `FlowEconomyManager`, `BalanceGuardrails.tres`)
- Session Summary §3.2 (SimBot spec: headless Godot, loadout presets, swarm runner)
- Session Summary §3.3 (RAG spec: `fw-balance` corpus = SimBot logs source)
- MASTER_DOC §20 (CombatStatsTracker), §21 (existing SimBot scripts)
- `framework/templates/resources/BalanceGuardrails.gd` (from S13)

**Key questions for this session:**
1. SimBot currently hard-codes Foul Ward scene paths. What is the minimum
   config file that lets SimBot point to any game's wave and unit resources?
2. How should the balance optimiser work — gradient descent over a parameter
   space bounded by BalanceGuardrails, or a simpler hill-climbing pass?
   What are the optimisable parameters for a generic strategy game?
3. When SimBot finishes a run, what exact files should it write so that the RAG
   `fw-balance` corpus can index them on the next `wolf rag index` call?
4. What is the minimum "quick" SimBot profile (for CI/CD in S16) that completes
   in under 90 seconds on the dev machine?

**Cursor prompts to generate (7 prompts):**

1. Extract and generalise `tools/simbot/simbot_runner.gd` from Foul Ward —
   replace hard-coded Foul Ward scene/resource paths with a config-driven loader;
   add `tools/simbot/simbot_config.yaml` schema: `game_path`, `wave_resources_dir`,
   `unit_resources_dir`, `loadout_presets` (array of preset names), `seed_count`,
   `output_dir`; add a `config/simbot/games/foul-ward.yaml` as the first real config

2. Generalise `tools/simbot/simbot_swarm.py` — update to read `simbot_config.yaml`;
   remove Foul Ward-specific 8-way runner assumption; runner count derived from
   `os.cpu_count() - 1`; output files: `simbot_balance_report.md`,
   `simbot_raw_{timestamp}.csv`, `simbot_summary_{timestamp}.json`;
   all output to `tools/simbot/output/{game_name}/`

3. Write `tools/simbot/simbot_loadouts.gd` template — generalised version of
   Foul Ward's three presets; template presets: `baseline` (standard mid-game
   economy, mixed unit composition), `rush` (fast economy, swarm units),
   `turtle` (slow economy, heavily armoured units); each preset is a `.tres`
   file at `config/simbot/loadouts/{preset_name}.tres`; document how to add
   custom presets per-game

4. Write `tools/simbot/balance_optimiser.py` — hill-climbing optimiser over
   a parameter set read from `BalanceGuardrails.tres` bounds; optimisable
   parameters: unit HP values, attack damage values, gold costs; objective:
   minimise variance in win-rate across all three preset loadouts (target:
   all presets within ±5% win rate of each other); max iterations per run: 50;
   step size: 5% of parameter range; writes recommended stat changes to
   `simbot_optimiser_recommendations.md`; includes a hard guardrail check
   (refuse to recommend any value outside BalanceGuardrails bounds)

5. Write `tools/simbot/rag_indexer_hook.py` — post-run hook called by
   `simbot_swarm.py` on completion; copies latest output files to the game's
   `docs/balance/` folder (RAG-indexed path per game config); writes a
   `docs/balance/LATEST_RUN.md` summary with timestamp, seed count, win rates
   per loadout, top three optimiser recommendations; this file becomes the
   `fw-balance` corpus's most-queried document

6. Write `config/simbot/loadouts/baseline.tres`,
   `config/simbot/loadouts/rush.tres`,
   `config/simbot/loadouts/turtle.tres` — Godot Resource files using the
   generalised LoadoutPreset schema from prompt 3; values calibrated for
   a generic 10-wave mid-difficulty strategy game

7. Write `tools/simbot/quick_profile.yaml` — minimal CI/CD SimBot profile:
   3 seeds only, baseline loadout only, waves 1–5 only, no optimiser pass;
   target runtime: under 90 seconds on RTX 4090 dev machine; document in
   `SETUP.md` that this is what CI runs and full optimiser runs are manual

**Deliverables:**
- [ ] `tools/simbot/simbot_runner.gd` — generalised, config-driven
- [ ] `tools/simbot/simbot_swarm.py` — generalised, cpu_count-aware
- [ ] `tools/simbot/simbot_loadouts.gd` — template with 3 presets
- [ ] `tools/simbot/balance_optimiser.py` — hill-climbing, guardrail-bounded
- [ ] `tools/simbot/rag_indexer_hook.py` — auto-indexes output to fw-balance
- [ ] `tools/simbot/quick_profile.yaml` — CI-safe <90s profile
- [ ] `config/simbot/simbot_config.yaml` — schema definition
- [ ] `config/simbot/games/foul-ward.yaml` — Foul Ward config
- [ ] `config/simbot/loadouts/baseline.tres`, `rush.tres`, `turtle.tres`
- [ ] `docs/balance/LATEST_RUN.md` populated after a test run (verified)
- [ ] `wolf rag index --corpus fw-balance` picks up balance output (verified)
- [ ] Quick profile completes in under 90 seconds (verified, time recorded in
      session result report)

**Unlocks:** S16 (CI/CD needs quick_profile.yaml), S08 already needs `run_simbot`
tool (can run before S15 with stub, replaces stub after S15)

---

## Session S16 — CI/CD: GitHub Actions Across All Four Repos

**Goal:** Every push to any of the four repositories triggers the appropriate
automated checks; every version tag on `wolf-framework` or `wolf-mcp` triggers
a publish; no broken commit can merge to `main` without tests passing.

**Perplexity context to load:**
- Chunk 1 (repo structure, four repos)
- Chunk 3, S15 deliverables (quick_profile.yaml)
- GitHub Actions documentation reference (paste relevant YAML syntax)
- Current GdUnit4 parallel test runner command (from MASTER_DOC or S15 result)

**Key questions for this session:**
1. What is the correct GitHub Actions setup for running Godot 4.4 headless in CI
   without a display server? (`xvfb-run` or Godot's own `--headless` flag?)
2. How do we cache Godot's import cache between runs to avoid re-importing all
   assets on every CI job?
3. PyPI publishing via GitHub Actions — OIDC trusted publisher or API token?
   (Recommendation: OIDC — no secrets to rotate.)
4. GHCR Docker image publishing — when should images rebuild? On every push
   (too slow) or only when `docker/` changes (correct)?

**Cursor prompts to generate (6 prompts):**

1. Write `.github/workflows/test.yml` for `wolf-framework` — triggers on push to
   `main` and all PRs; jobs: (a) `gdscript-lint` using `scony/godot-gdscript-toolkit`
   Docker action; (b) `unit-tests` using Godot 4.4 headless + GdUnit4 parallel
   runner (quick suite only, ~665 tests, target <3 min); (c) `simbot-quick`
   using `tools/simbot/quick_profile.yaml` (target <90s); all three jobs run in
   parallel; PR blocked if any job fails

2. Write `.github/workflows/publish-docker.yml` for `wolf-framework` — triggers
   on push to `main` only when files under `docker/` change (path filter);
   builds `wolf-dev` and `wolf-art` images; pushes to GHCR with tags:
   `latest` and `sha-{short_commit}`; wolf-art build uses `--platform linux/amd64`
   (no cross-compile); requires `GITHUB_TOKEN` (auto-provided, no secrets needed)

3. Write `.github/workflows/publish-pypi.yml` for `wolf-mcp` — triggers on
   version tag push (`v*.*.*`); uses OIDC trusted publisher (no API token secret);
   runs: `python -m build`, then `twine upload`; also runs `mypy wolf_mcp/` and
   `black --check wolf_mcp/` as pre-publish gates; tag format: matches semantic
   versioning `v0.1.0`, `v1.0.0` etc.

4. Write `.github/workflows/test.yml` for `wolf-mcp` — triggers on push to `main`
   and PRs; jobs: (a) `lint` running `black --check` + `mypy` + `ruff`;
   (b) `unit-tests` running `pytest tests/` with coverage report; target: >80%
   coverage gate; Python 3.11 and 3.12 matrix

5. Write `.github/workflows/test.yml` for `wolf-games` — triggers on push to
   `main` and PRs; runs `gdscript-lint` across all game folders; runs each game's
   GdUnit4 suite if present (detected by `tests/` folder existence); skips
   `foul-ward/` (frozen, no CI runs on frozen games)

6. Write `tools/ci/` helper scripts referenced by the workflows:
   `tools/ci/run_gdunit.sh` — wraps GdUnit4 parallel runner with the correct
   Godot headless command, xvfb-run wrapping, and exit-code passthrough;
   `tools/ci/check_import_cache.sh` — validates that no new `.import` files were
   added without corresponding `.tres` resource files (catches common "forgot to
   commit import" mistakes); `tools/ci/lint_signals.sh` — standalone signal
   validation script (calls `wolf validate-signals` without full MCP) for use
   in CI without spinning up the MCP server

**Deliverables:**
- [ ] `wolf-framework/.github/workflows/test.yml`
- [ ] `wolf-framework/.github/workflows/publish-docker.yml`
- [ ] `wolf-mcp/.github/workflows/publish-pypi.yml`
- [ ] `wolf-mcp/.github/workflows/test.yml`
- [ ] `wolf-games/.github/workflows/test.yml`
- [ ] `tools/ci/run_gdunit.sh`
- [ ] `tools/ci/check_import_cache.sh`
- [ ] `tools/ci/lint_signals.sh`
- [ ] All workflows pass on first run against current main branch (verified)
- [ ] A test PR is opened and auto-checked (verified)
- [ ] PyPI OIDC trusted publisher configured in PyPI dashboard for `wolf-framework`

**Unlocks:** S20 (integration test PR is the first real CI gate test), Phase 3
(GHCR images needed for SETUP.md to reference pre-built images)

---

## Session S17 — The wolf CLI Tool

**Goal:** `pip install wolf-framework` gives any developer a working `wolf`
command that handles every workflow — project scaffolding, art, audio, testing,
SimBot, RAG, and framework updates — all with a `--help` flag and a friendly
error message when a prerequisite is missing.

**Perplexity context to load:**
- Chunk 1 (CLI design decisions: `--path` flag, default `~/wolf-framework`)
- Chunk 3, S16 deliverables (CI scripts the CLI can reuse)
- `wolf-mcp/pyproject.toml` (entry points already defined)
- Session Summary §3.1 (existing python orchestration scripts)

**Key questions for this session:**
1. Should `wolf new` place the new game inside `wolf-games/` in the framework
   install path, or in an arbitrary user-specified location? (Recommendation:
   default to `wolf-games/<name>` relative to install path, overridable with
   `--output-path`.)
2. What scaffolding files does `wolf new` create beyond copying the templates?
   What does it auto-fill in `MASTER_DOC_TEMPLATE.md` (game name, date, paths)?
3. `wolf update` — should it update the framework submodules as well, or only
   the framework itself? Risk: submodule updates can break addon APIs.
4. How should the CLI handle the case where `wolf-dev` Docker container is not
   running when a command like `wolf test` is invoked?

**Cursor prompts to generate (7 prompts):**

1. Write `wolf_mcp/cli/__init__.py` and `wolf_mcp/cli/main.py` — Click-based
   CLI entry point; top-level group `wolf` with subcommand groups: `new`, `install`,
   `update`, `art`, `audio`, `test`, `simbot`, `rag`, `doc`; global options:
   `--wolf-path PATH` (defaults to `WOLF_PATH` env var or `~/wolf-framework`);
   `--verbose` flag; version command `wolf --version`; friendly error handler that
   detects "Docker not running" and prints the exact fix command

2. Write `wolf_mcp/cli/commands/scaffold.py` — `wolf new <game-name>` command;
   `--output-path` option (default: `{wolf_path}/wolf-games/{game-name}`);
   steps: (a) create directory structure mirroring wolf-framework's `framework/`
   layout; (b) copy all templates from `framework/templates/`; (c) copy
   `framework/templates/MASTER_DOC_TEMPLATE.md` to `docs/MASTER_DOC.md` and
   auto-fill: game_name, creation_date, author placeholder, framework_version;
   (d) copy `framework/templates/AGENTS.md`; (e) create `config/rag/games/
   {game-name}.yaml` from `config/rag/default.yaml`; (f) create `project.godot`
   stub with `config/name` set; (g) print "Done! Open {output_path} in Godot 4.4"

3. Write `wolf_mcp/cli/commands/install.py` — `wolf install` command; `--path`
   option; steps: (a) check prerequisites (Docker, Git, Python 3.11+) with
   version checks; (b) clone all four repos into correct locations; (c) run
   `git submodule update --init --recursive` in wolf-framework; (d) copy
   `.env.template` to `.env` and prompt user to fill in required values;
   (e) call `docker compose pull` to pull pre-built GHCR images;
   (f) ask "Download AI models now? (~80 GB) [y/N]" and conditionally run
   `tools/bootstrap.sh`; total install without models: ~2 minutes

4. Write `wolf_mcp/cli/commands/art.py` — `wolf art generate <name> <faction>
   <asset-type>` calls `pipelines/art/studio.py` via subprocess with the
   wolf-art container; `wolf art status` shows last generated assets from
   manifest.json; `wolf art list-archetypes` prints available prompt templates;
   `wolf art reimport <name>` re-runs only stage 5 (Godot drop) for an existing
   GLB

5. Write `wolf_mcp/cli/commands/audio.py` — `wolf audio sfx "<prompt>"
   --duration 2.0 --category <category>` and `wolf audio music "<prompt>"
   --stems --category <category>`; `wolf audio list` shows assets in
   `assets/generated/audio/`; all commands proxy to the audio pipeline inside
   wolf-art container

6. Write `wolf_mcp/cli/commands/testing.py` — `wolf test` runs full GdUnit4
   suite via `tools/ci/run_gdunit.sh`; `wolf test --quick` runs subset (smoke
   tests only); `wolf simbot run <profile>` calls `simbot_swarm.py` with the
   named config; `wolf simbot optimise` runs the balance optimiser; `wolf simbot
   report` prints latest `LATEST_RUN.md` to stdout

7. Write `wolf_mcp/cli/commands/update.py` — `wolf update` command; checks
   current framework version tag; fetches latest; shows changelog diff; asks
   "Update framework? Addon updates are opt-in. [y/N]"; on yes: `git pull` on
   wolf-framework; on `--addons` flag additionally: `git submodule update
   --remote framework/addons/` with a per-addon confirmation prompt (to avoid
   surprise API breaks); `wolf update --check` is non-destructive: just reports
   whether updates are available

**Deliverables:**
- [ ] `wolf_mcp/cli/__init__.py`
- [ ] `wolf_mcp/cli/main.py` — Click entry point with all subcommand groups
- [ ] `wolf_mcp/cli/commands/scaffold.py` — `wolf new`
- [ ] `wolf_mcp/cli/commands/install.py` — `wolf install`
- [ ] `wolf_mcp/cli/commands/art.py` — `wolf art` subcommands
- [ ] `wolf_mcp/cli/commands/audio.py` — `wolf audio` subcommands
- [ ] `wolf_mcp/cli/commands/testing.py` — `wolf test` + `wolf simbot`
- [ ] `wolf_mcp/cli/commands/update.py` — `wolf update`
- [ ] `wolf new integration-test` runs without error (verified)
- [ ] `wolf test --quick` passes (verified)
- [ ] `wolf --help` and all subcommand `--help` outputs are clean (verified)
- [ ] `wolf install --help` documents the --path flag clearly (verified)

**Unlocks:** S20 (integration test uses `wolf new` + `wolf test`), Phase 2
(all demo games scaffolded via `wolf new`), S39 (docs reference CLI commands)

---

## Session S18 — Cursor Skills Pack

**Goal:** A complete set of `.cursor/skills/` domain skill files is extracted
from Foul Ward's working configuration, generalised for any WOLF game, and
packaged so that `wolf new` automatically drops the correct skill files into
every new game's `.cursor/skills/` folder.

**Background:**
Foul Ward uses a `.cursor/skills/` system where each `.md` file is a standing
briefing that Cursor reads before working on a specific domain (e.g.,
`godot-signals.md` tells Cursor the exact rules for signal wiring in this project).
These are not prompts — they are persistent, loaded context. The generalised WOLF
skills pack is arguably the most LLM-productivity-enhancing part of the framework,
because it means Cursor already knows the WOLF conventions when it opens any new game.

**Perplexity context to load:**
- Chunk 2, S09 deliverables (`AGENTS.md` template, `SignalBus.gd` template)
- MASTER_DOC §29 (LLM agent conventions), §30 (anti-patterns catalogue)
- Session Summary §4.1 (skills extraction in scope list)
- Any existing `.cursor/skills/` files from Foul Ward (paste contents)

**Key questions for this session:**
1. What is the correct `.cursor/skills/` file format — plain Markdown, or does
   it require a specific YAML front-matter header for Cursor to load it?
2. Which domain skill files does Foul Ward have, and which need to be created
   new for the framework (e.g., there was no Card game skill in Foul Ward)?
3. How granular should skills be? One big `wolf-all.md` vs. many small files?
   (Recommendation: one file per domain, 200–400 words each — small enough to
   always be in context, large enough to be useful.)
4. Should skills reference each other (e.g., `wolf-signals.md` links to
   `wolf-resources.md`)? How does Cursor handle cross-skill references?

**Cursor prompts to generate (6 prompts):**

1. Write `framework/skills/wolf-architecture.md` — the master architecture skill:
   autoload init order, the 20 canonical SignalBus signals and their parameter
   signatures, the rule that SignalBus has no logic, the Types.gd → GameTypes.cs
   sync requirement, the C# interop boundary (math-only), the Resource-driven
   data rule (no hardcoded stats); this is the file Cursor reads before any
   architectural change

2. Write `framework/skills/wolf-signals.md` — signal wiring skill: the four
   signal rules (declare in SignalBus.gd, connect in _ready, emit with full
   parameter names, never connect in _process); the forbidden patterns
   (logic in signal handlers, signals that return values, direct node references
   across scenes); a quick-reference table of all 20 canonical signals with
   their parameters

3. Write `framework/skills/wolf-resources.md` — resource-driven data skill:
   why stats live in .tres files, the template resource list (UnitData,
   BuildingData, WaveData, FactionData, ResearchNodeData, BalanceGuardrails),
   the rule that .tres files are never edited by code (read-only at runtime),
   the upgrade pattern (nested resource arrays, never mutable fields),
   the SavePayload versioning rule

4. Write `framework/skills/wolf-testing.md` — testing skill: GdUnit4 test file
   naming convention (`test_{system_name}.gd`), the three test categories
   (unit/integration/simbot), the parallel runner command, the rule that every
   new autoload needs at least 4 tests, the GdUnit4 assertion API quick reference,
   the forbidden pattern (tests that depend on scene tree being loaded)

5. Write domain-specific skills for each of the six game genres the demos cover:
   `framework/skills/genre-tower-defense.md` — TAUR pattern, wave spawning,
   build-phase/combat-phase loop, targeting modes;
   `framework/skills/genre-rts.md` — unit production, steering AI integration,
   formation manager, RTS camera conventions;
   `framework/skills/genre-card-roguelite.md` — Card Framework patterns, run
   state vs. persistent state, deck serialization;
   `framework/skills/genre-grand-strategy.md` — province map, faction relations,
   tech tree, TimeTick for turn processing;
   `framework/skills/genre-autobattler.md` — board/bench split, drag-place
   pattern, round resolution loop, GAS attribute mapping;
   `framework/skills/genre-dungeon-keeper.md` — voxel dig pattern, HTN planner
   for creature AI, flow economy for dungeon maintenance

6. Write `framework/skills/wolf-pipelines.md` — the AI pipeline skill: the five
   art stages and which to re-run when (stage 1 only for style changes; stage
   3+ for rig fixes); the three audio stages; the three RAG corpora and which
   questions each answers; the `wolf art generate` and `wolf audio sfx` command
   syntax; the manifest.json structure for tracking generated assets

**Deliverables:**
- [ ] `framework/skills/wolf-architecture.md`
- [ ] `framework/skills/wolf-signals.md`
- [ ] `framework/skills/wolf-resources.md`
- [ ] `framework/skills/wolf-testing.md`
- [ ] `framework/skills/wolf-pipelines.md`
- [ ] `framework/skills/genre-tower-defense.md`
- [ ] `framework/skills/genre-rts.md`
- [ ] `framework/skills/genre-card-roguelite.md`
- [ ] `framework/skills/genre-grand-strategy.md`
- [ ] `framework/skills/genre-autobattler.md`
- [ ] `framework/skills/genre-dungeon-keeper.md`
- [ ] `wolf new` updated to copy correct genre skill(s) into `.cursor/skills/`
      based on `--genre` flag (e.g., `wolf new my-rts --genre rts`)
- [ ] `framework/skills/README.md` — index of all skill files, when each is
      auto-copied by `wolf new`, and how to manually add skills

**Unlocks:** All Phase 2 demo game sessions (every `wolf new` call uses these
skills), S39 (docs site has a Skills page)

---

## Session S19 — MASTER_DOC Automation & doc Commands

**Goal:** The `wolf doc` CLI subcommand can auto-generate and auto-update key
sections of a game's `docs/MASTER_DOC.md` by reading the live codebase —
so the document stays accurate without manual maintenance and remains a reliable
RAG source.

**Background:**
The MASTER_DOC is the RAG system's primary source of truth for the `fw-framework`
corpus. If it drifts from the codebase (autoloads added but not listed, signals
renamed but not updated), the RAG gives wrong answers. Automation closes this gap.
The human-authored narrative sections (design rationale, cut features, open TBD)
are never touched by automation — only the machine-readable tables.

**Perplexity context to load:**
- Chunk 2, S09 deliverables (`MASTER_DOC_TEMPLATE.md`)
- Chunk 3, S17 deliverables (`wolf_mcp/cli/commands/`)
- MASTER_DOC §1 (autoloads init order table), §2.1 (SignalBus signal table),
  §5 (Types enum table) — these are the sections we automate
- Session Summary §3.3 (RAG indexing — MASTER_DOC is the primary fw-framework doc)

**Key questions for this session:**
1. `wolf doc generate` — should it overwrite the whole MASTER_DOC or only the
   sections wrapped in special markers? (Recommendation: special markers, e.g.
   `<!-- WOLF:AUTO-START:autoloads -->` ... `<!-- WOLF:AUTO-END:autoloads -->`
   so human-written sections are never touched.)
2. How do we parse `project.godot` to extract the autoload list and init order?
3. How do we parse `autoloads/signal_bus.gd` to extract all signal declarations
   with their parameters?
4. Should `wolf doc validate` be a separate CI job or part of the existing
   `wolf test` flow? (Recommendation: separate, non-blocking warn in CI.)

**Cursor prompts to generate (5 prompts):**

1. Write `wolf_mcp/cli/commands/docs.py` — `wolf doc generate` command;
   reads `project.godot` to extract autoload list and init order;
   reads `autoloads/signal_bus.gd` to extract all `signal` declarations with
   parameters using regex; reads `autoloads/types.gd` to extract all `enum`
   declarations; writes extracted data into the MASTER_DOC's `<!-- WOLF:AUTO -->` 
   marked sections without touching any other content; dry-run mode:
   `wolf doc generate --dry-run` prints what would change without writing

2. Write `wolf_mcp/cli/commands/docs.py` addition — `wolf doc validate` command;
   checks that every autoload in `project.godot` is listed in MASTER_DOC's
   autoloads table; checks that every signal in `signal_bus.gd` is listed in
   MASTER_DOC's signals table; checks that every enum in `types.gd` is listed;
   reports PASS / WARN per section; exit code 0 = all pass, 1 = warnings,
   2 = missing entries (CI-friendly)

3. Update `framework/templates/MASTER_DOC_TEMPLATE.md` from S09 — add
   `<!-- WOLF:AUTO-START:autoloads -->` / `<!-- WOLF:AUTO-END:autoloads -->`
   markers around the autoloads table; same markers around signals table and
   enums table; add a header banner:
   "⚠ Sections marked AUTO are maintained by `wolf doc generate`.
   Do not edit them manually — your changes will be overwritten."

4. Write `wolf_mcp/parsers/` module — `wolf_mcp/parsers/gdscript_parser.py`
   (regex-based, not full AST): `parse_signals(filepath) -> List[SignalInfo]`,
   `parse_enums(filepath) -> List[EnumInfo]`,
   `parse_class_name(filepath) -> str`; `wolf_mcp/parsers/project_parser.py`:
   `parse_autoloads(project_godot_path) -> List[AutoloadInfo]` (reads INI-format
   project.godot); all parsers covered by 6 pytest unit tests using fixture files

5. Write `.github/workflows/doc-validate.yml` for `wolf-games` — triggers on PR;
   runs `wolf doc validate` in the wolf-dev container for the changed game;
   posts validation results as a PR comment using `actions/github-script`;
   non-blocking (warn only, does not block merge) with a clear message:
   "MASTER_DOC is out of sync. Run `wolf doc generate` to fix."

**Deliverables:**
- [ ] `wolf_mcp/cli/commands/docs.py` — `wolf doc generate` + `wolf doc validate`
- [ ] `wolf_mcp/parsers/gdscript_parser.py`
- [ ] `wolf_mcp/parsers/project_parser.py`
- [ ] Updated `framework/templates/MASTER_DOC_TEMPLATE.md` with AUTO markers
- [ ] `wolf-games/.github/workflows/doc-validate.yml`
- [ ] 6 pytest tests for parsers (all passing)
- [ ] `wolf doc generate` run on Foul Ward produces correct autoloads + signals
      tables without touching narrative sections (verified)
- [ ] `wolf doc validate` on Foul Ward returns all-pass (verified)

**Unlocks:** S20 (integration test runs `wolf doc generate` as part of setup),
S39 (docs site can display SYSTEMS_REFERENCE.md + auto-generated tables)

---

## Session S20 — Framework Integration Test

**Goal:** A brand-new game called `wolf-integration-test` is scaffolded using
`wolf new`, every major framework system is instantiated and run together in one
Godot project, all tests pass, and the result constitutes the definitive proof
that the complete framework works as a coherent whole — not just as isolated parts.

**This session is the Phase 1 acceptance gate.** If S20 passes, Phase 1 is done.

**Perplexity context to load:**
- The complete Chunk 1 + 2 + 3 workplan (all prior session deliverables)
- The `framework/docs/SYSTEMS_REFERENCE.md` produced in S14
- The `framework/scenes/demos/README.md` produced in S10
- The cumulative framework inventory at the end of Chunk 2

**Key questions for this session:**
1. What is the minimal integration test scene that exercises the maximum number
   of systems? (A micro-RTS match: spawn units via add_unit MCP tool, units use
   Steering AI + Beehave, economy via EconomyManager, one wave via WaveData, FOW
   active, dialogue after wave, save/load round-trip — covers ~14 systems.)
2. How do we structure the integration test as a GdUnit4 test suite rather than
   a manual playthrough, so it runs in CI?
3. What should the session result report document — just pass/fail, or a full
   system-by-system evidence log?

**Cursor prompts to generate (7 prompts):**

1. Scaffold the integration test game — run `wolf new wolf-integration-test
   --genre rts` from the CLI; verify all template files are created; verify
   MASTER_DOC.md is populated with game name and date; verify `.cursor/skills/`
   contains `wolf-architecture.md`, `wolf-signals.md`, `wolf-resources.md`,
   `wolf-testing.md`, `genre-rts.md`; verify `config/rag/games/
   wolf-integration-test.yaml` was created

2. Wire all framework autoloads into the integration test game's `project.godot`
   in the correct init order: SignalBus → FlowEconomyManager → FactionManager →
   HexGrid → ContagionManager → Localisation → DialogueBridge → SoundBridge →
   MinimapManager; verify Godot loads without errors; run `wolf doc generate`
   to auto-fill MASTER_DOC autoloads table

3. Write `wolf-integration-test/scenes/IntegrationTestArena.tscn` — the
   main integration scene: 12×12 hex grid, two factions (PLAYER vs. ENEMY),
   RTSCamera3D, FogOfWar2D, Minimap overlay, three UnitBase units per side
   spawned from UnitData.tres resources, EconomyManager panel, one WaveData
   resource defining an enemy wave, DialogueBridge triggered after wave completes

4. Write `wolf-integration-test/tests/test_integration_arena.gd` — GdUnit4
   integration test suite covering: unit spawning from UnitData resource,
   Steering AI pathfinding (unit moves from A to B), GAS HP depletion on attack,
   Beehave chase-and-attack tree transition, EconomyManager gold spend and refund,
   FactionManager war declaration + is_enemy check, FlowEconomyManager nanostall
   trigger, SignalBus signal receipt count for `unit_died`, FOW visibility update
   after unit death, dialogue triggered after wave, save/load round-trip via
   SavePayload; minimum 12 test cases, all passing

5. Run `wolf test` on the integration test game — confirm all tests pass in the
   parallel runner; confirm GdUnit4 exit code is 0; paste exact command and output
   into session result report; if any tests fail, fix the root cause (could be
   in the framework, not the test) before marking S20 done

6. Run `wolf simbot run baseline --game wolf-integration-test` — confirm SimBot
   runs the integration test arena headlessly for 10 seeds; confirm output is
   written to `tools/simbot/output/wolf-integration-test/`; run
   `wolf rag index --corpus fw-balance` and confirm SimBot output is indexed;
   run `wolf rag query "what was the average win rate in the last simbot run?"` 
   and confirm RAG returns correct answer from the indexed balance report

7. Write `framework/docs/PHASE1_ACCEPTANCE_REPORT.md` — the formal sign-off
   document for Phase 1; sections: Framework Systems Checklist (tick every
   system from the Chunk 2 cumulative inventory), Test Results (GdUnit4 count
   + pass rate), SimBot Results (win rates, any optimiser recommendations),
   CI Status (all workflows green), Known Limitations (document any systems
   that have known issues or are stubs), Signed Off By (you), Date;
   this document is committed to `wolf-framework` main branch as the v1.0 pre-tag marker

**Deliverables:**
- [ ] `wolf-games/wolf-integration-test/` — fully scaffolded via `wolf new`
- [ ] All framework autoloads wired + Godot loads cleanly (verified)
- [ ] `scenes/IntegrationTestArena.tscn` — all major systems in one scene
- [ ] `tests/test_integration_arena.gd` — 12+ test cases, all passing
- [ ] `wolf test` exit code 0 (verified, screenshot in session result report)
- [ ] SimBot baseline run completes for integration test game (verified)
- [ ] `wolf rag query` returns correct balance answer (verified)
- [ ] `framework/docs/PHASE1_ACCEPTANCE_REPORT.md` committed to main
- [ ] All CI workflows green on main branch after this session's commits (verified)

**Unlocks:** ALL Phase 2 sessions (framework is now proven; game work begins)

---

## Phase 1, S15–S20 — Session Status Tracker

| Session | Title | Depends on | Status |
|---------|-------|-----------|--------|
| S15 | SimBot extraction + balance optimiser | S13, S06 | ⏳ |
| S16 | CI/CD across all four repos | S15, S07 | ⏳ |
| S17 | wolf CLI tool | S01, S06, S08 | ⏳ |
| S18 | Cursor skills pack | S09, S14 | ⏳ |
| S19 | MASTER_DOC automation + wolf doc | S09, S17 | ⏳ |
| S20 | Framework integration test (Phase 1 gate) | ALL S01–S19 | ⏳ |

---

## Phase 1 Complete: Full Session Map & Dependency Graph

```
Phase 0 (manual)
    │
    ├──► S01 Repos ──────────────────────────────────┐
    │       │                                        │
    │       ▼                                        ▼
    │    S02 Docker ─────┬──────────────────────► S17 CLI
    │       │            │
    │       ▼            ▼
    │    S03 Art       S05 Audio
    │    S04 studio.py    │
    │       │             │
    │       └─────┬───────┘
    │             │
    │             ▼
    │          S06 RAG ──────────────────────────► S07 MCP v0
    │             │                                      │
    │             │                                   S08 MCP complete
    │             │
    │          S09 Core extraction
    │             │
    │       ┌─────┴──────┐
    │       ▼            ▼
    │    S10 Addons1   S11 Addons2
    │       │            │
    │       └─────┬──────┘
    │             │
    │       ┌─────┼──────┐
    │       ▼    ▼        ▼
    │    S12 Maps  S13 Economy  S18 Skills
    │       │         │
    │       └────┬────┘
    │            ▼
    │         S14 Targeting/Replay
    │            │
    │       ┌────┼────┐
    │       ▼   ▼      ▼
    │    S15 SimBot  S19 Docs
    │       │
    │    S16 CI/CD
    │
    └──────────────────────────────────────────► S20 Integration Test (gate)
```

*After S20 passes, open Phase 2.*

---

## Phase 1 Deliverable Count Summary

| Category | Count |
|---|---|
| Framework GDScript files | ~42 scripts |
| Framework Godot scenes + resources | ~28 .tscn / .tres |
| Godot addons (git submodules) | 18 |
| AI pipeline scripts | 11 (art 5 + audio 3 + RAG 3) |
| wolf-mcp Python tools | 11+ |
| wolf CLI subcommands | ~20 |
| GdUnit4 tests added | ~60 new |
| Documentation files | ~12 .md |
| GitHub Actions workflows | 5 |
| Cursor skill files | 11 |
| Docker images | 2 |

*End of Chunk 3. Chunk 4 covers Phase 2 sessions S21–S38: all 16 demo games,
each a self-contained playable scene built on the completed framework.*
