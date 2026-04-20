# Foul Ward — Interview Cheat Sheet

One-page talking-points companion to [`HOW_IT_WORKS.md`](HOW_IT_WORKS.md).
Read this in the five minutes before the call.

---

## The 30-second pitch

Foul Ward is a Godot 4.6 tower-defence game where almost all the gameplay
code was written by an AI coding agent. The game itself isn't the point —
the point is the **engineering scaffolding** I built around the agent so
that it could write code without the codebase collapsing:

- a **standing-orders file** the agent reads every session (`AGENTS.md`);
- **14 domain-scoped skills** it loads on-demand (`.cursor/skills/`);
- a **bespoke RAG MCP server** I wrote in Python that indexes the whole
  project (docs + code + `.tres` resources + simulation logs) into
  ChromaDB and answers questions over hybrid BM25 + semantic retrieval;
- a **four-tier GdUnit4 test pipeline** with explicit exit-code semantics;
- a **headless simulation harness** (SimBot) that runs missions without a
  UI and writes CSV telemetry that a Python aggregator turns into
  balance classifications;
- a **strict architecture** — 19 autoloads in a fixed init order, 77 typed
  signals on a single bus, 262 `.tres` resource files (zero magic numbers
  in code) — so AI-introduced drift shows up on diff.

**Result:** 665 passing tests, 77 signals, 90 prompt log files (10 newest in `docs/`, rest in `docs/archived/prompts/`) — all solo,
all grounded in retrieval instead of the model's priors.

---

## Numbers to remember

| What | How many |
|---|---|
| Core autoloads (strict init order) | **19** |
| Typed `SignalBus` signals | **77** |
| GdUnit4 test cases (parallel aggregate) | **665** |
| Test files | **88** (72 root + 16 unit) |
| `.tres` resource files | **262** |
| Building types / enemy types | **36 / 30** |
| Cursor "skills" (domain-scoped) | **14** |
| MCP servers wired into Cursor | **6** |
| ChromaDB collections in the RAG | **4** |
| GdUnit4 runner tiers | **4** (quick / unit / parallel / sequential baseline) |
| Session logs | **88** (`PROMPT_0…87_IMPLEMENTATION.md`) |
| Parallel runner wall-clock | **~2 min 45 s** |
| Quick runner wall-clock | **~30–45 s** |

---

## One-liners per subsystem

Use these when the interviewer drills into one area.

### AGENTS.md (the standing-orders file)
"It's a ~250-line, human-readable contract at the repo root — symlinked
as `.cursorrules` — that the agent reads at every session start.
Sixteen non-negotiable rules, the full autoload init order with reasons,
and a 'wrong → correct' table of the field names the agent most often
hallucinates. It's the checked-in system prompt for the project."

### `.cursor/skills/` (14 domain skills)
"Each skill is a Markdown file with front-matter trigger keywords.
When the agent detects it's working on signals, it loads
`.cursor/skills/signal-bus/SKILL.md` — rule, how-to, WRONG/RIGHT code,
and the maintenance checklist. That keeps the working context small
and relevant — I pay the context cost only when the skill is needed."

### `foulward-rag` MCP (the RAG server)
"Python, ~760 lines. ChromaDB + LangChain + LangGraph + Ollama.
Four collections — docs, code, `.tres` resources, SimBot logs — each
with a domain-specific chunker (markdown-heading-aware, Python-language,
`.tres` section-boundary, JSON-record). Hybrid retrieval: BM25 and
semantic weighted 50/50, deduplicated by file+chunk-index. LangGraph
chain with a SQLite checkpointer for cross-session memory.
Incremental indexing via SHA-256 hash cache — unchanged files skipped.
Exposes two tools to Cursor: `query_project_knowledge(question, domain)`
and `get_recent_simbot_summary(n_runs)`. Zero cost — all local."

### Test pipeline (the staircase)
"Four tiers with increasing coverage and wall-clock. `quick` is a
50-suite allowlist for the inner loop, ~45 seconds. `unit` is 48
pure-unit suites for focused coverage. `parallel` shards all 88 test
files across 8 headless Godot processes round-robin, ~2 minutes 45
seconds, 665 cases. `sequential` is the baseline before declaring done.
All four share the same exit-code normalisation — including remapping
`139` / `134` (known Godot .NET teardown segfaults) to `101` (warning-
level pass), because those were producing spurious red runs."

### AutoTestDriver + SimBot (headless integration)
"AutoTestDriver is an autoload that's dormant unless you pass
`--autotest`, `--simbot_profile=`, or `--simbot_balance_sweep` on the
command line. It drives scripted integration sequences — place towers,
wait for `wave_started`, assert first kill within 60 s, assert
`wave_cleared`. SimBot plays full missions against strategy profiles
(greedy-builder, economy-first, etc.) and dumps per-wave and per-building
CSVs. A Python aggregator (`simbot_balance_report.py`) computes
`damage_per_gold` and classifies each building as OVERTUNED, BASELINE,
UNDERTUNED, or UNTESTED against the median. That's how balance changes
are grounded in evidence, not vibes."

### Architecture-as-policy
"Every architectural rule is a machine-readable invariant. 19 autoloads
in a strict init order — documented in `AGENTS.md` with the reason for
each non-trivial dependency (e.g. CampaignManager MUST load before
GameManager). 77 typed signals on SignalBus, all past-tense for events
and present-tense for requests, with an `is_connected` guard pattern.
262 `.tres` resources, zero magic numbers in code. A C#/GDScript enum
mirror (`FoulWardTypes.cs`) with identical integer values, so casts
across the boundary are type-safe. The whole shape is uniform on purpose
— so AI-introduced drift shows up immediately on diff."

### `PROMPT_[N]_IMPLEMENTATION.md` (audit trail)
"Every session writes a file with what was asked, what was implemented,
what tests were added or passed, and any `# DEVIATION:` from the spec
with a reason. 88 logs from `PROMPT_0` to `PROMPT_87`. That series is
the single most useful artefact for answering 'what did the agent
actually do vs what was I asking for' — which is the hardest question
in AI-assisted engineering."

### Gen3d pipeline (the asset story)
"Five-stage local pipeline: ComfyUI + FLUX.1-dev + three LoRAs
generate a turnaround sheet; TRELLIS.2 converts image to mesh (five
variants, pick best); Open3D + scipy cKDTree decimate while preserving
PBR textures; Blender rigs humanoids via Mixamo automation;
animations merged from Blender FBX library; output dropped as `.glb`
under `res://art/generated/`. Orchestrated by `launch.sh` (tmux
session) and `foulward_gen.py`. Entirely local — no paid APIs."

---

## STAR answers to likely questions

### Q: "Walk me through this project."
- **Situation:** I wanted to study AI-assisted coding at scale on a real
  codebase, and I wanted the study to produce something I could show.
- **Task:** Build a tower-defence game where an AI agent writes most of
  the code, without the codebase becoming unmaintainable.
- **Action:** I built four layers of guardrails — policy (AGENTS.md + 14
  domain skills), grounding (a bespoke RAG MCP server over the project),
  verification (four-tier GdUnit4 pipeline + SimBot), and audit
  (per-session PROMPT logs + machine-readable indexes). Then let the
  agent write most of the gameplay while I reviewed, steered, and
  extended the scaffolding when I saw new failure modes.
- **Result:** 665 passing tests, 77 typed cross-system signals, 262
  data-driven resources, full prompt audit trail — solo, and still auditable.

### Q: "What's the hardest problem you solved?"
- **Situation:** The agent was producing plausible-looking code that
  silently referenced fields or signals that didn't exist — the
  classic hallucination failure.
- **Task:** Stop the hallucinations from shipping, without making
  every session require me to manually check each suggestion.
- **Action:** I built `foulward-rag` — a stdio MCP server that
  indexes the whole project (docs, `.gd`, `.tres`, and SimBot logs)
  into four ChromaDB collections with per-domain chunkers, wraps
  them in a hybrid BM25 + semantic retriever (50/50 weighted,
  per-collection BM25 warmed at startup), and exposes it through a
  LangGraph chain with SQLite-backed cross-session memory. The
  agent now queries ground truth (`query_project_knowledge`) before
  writing, and its responses cite the actual source files.
- **Result:** Hallucinations on existing symbols dropped to
  near-zero. The one drift incident I did see (stale signal count
  in docs) was caught by a skill-enforced maintenance rule, not by
  a test — which is itself a lesson: grounding catches *runtime*
  errors, conventions catch *documentation* drift. You need both.

### Q: "How do you know the tests are actually useful?"
- **Situation:** Fast tests are only valuable if they catch real
  regressions — otherwise they're theatre.
- **Task:** Make sure the four-tier GdUnit4 staircase is giving me
  real signal, not just warm fuzzy feelings.
- **Action:** I kept the tiers asymmetric on purpose — the `quick`
  allowlist excludes scene-heavy suites, so it can't catch
  integration regressions. Anything that touches signal wiring,
  autoload init, or scene tree structure has to pass the `parallel`
  runner (all 88 files). The exit-code taxonomy is explicit —
  `139` and `134` (known .NET teardown crashes) are remapped to
  `101` so they don't mask real failures, but any *other* non-zero
  is a real red. Plus I added `AutoTestDriver` as a headless
  integration layer — the same game start-to-wave-cleared sequence
  runs in CI-style every time, and a failure there means a
  real-user-visible regression.
- **Result:** When the parallel runner is green, I can actually
  ship. When it's red, it's always real — I don't have to
  investigate flakes.

### Q: "What would you do differently?"
- Add GitHub Actions CI. The tooling is ready (clean exit codes,
  log files) — it just isn't wired up.
- Generate `INDEX_SHORT.md` / `INDEX_FULL.md` from the `.gd` AST
  instead of asking the agent to keep them in sync.
- Collapse the four test runner scripts into one Python entry
  point with `--tier` (they share 80% of logic).
- Promote a few of the "Known Gotchas" (autoload order,
  scene-manager paths) to runtime invariant tests, so they can't
  silently drift.
- Move the "re-read AGENTS.md" habit from convention to a Cursor
  pre-turn hook — forgetting it is the biggest source of agent
  drift I've seen.

### Q: "How much of this is your work vs the agent's?"
- The *scaffolding* is mine — `AGENTS.md`, all 14 skills, the RAG
  server and indexer, the four runner scripts and their exit-code
  normalisation, `AutoTestDriver`, the SimBot aggregator, the
  `launch.sh` orchestrator, and all the architectural decisions
  (autoload count and order, SignalBus-only comms, `.tres`-only
  tuning).
- Most of the *gameplay code* was drafted by the agent, reviewed and
  steered by me, and every change is logged in a
  `PROMPT_[N]_IMPLEMENTATION.md`. The agent succeeds because the
  scaffolding makes it hard for it to fail — not because it's smart.

### Q: "Why a tower defence game specifically?"
- Because the domain has a lot of small, orthogonal systems (buildings,
  enemies, economy, waves, research, spells, dialogue, save/load) that
  are independently testable. That's the ideal shape for studying
  whether an agent can maintain separation of concerns at scale. A
  more monolithic game (e.g. a narrative RPG) would hide drift
  behind tight coupling.

---

## Three honest trade-offs

Use these to demonstrate self-awareness.

1. **Local-only RAG.** Free and private, but embeddings run on my
   machine and synthesis is a 3B-parameter model. A team would want
   hosted models for better recall. The MCP surface stays the same.
2. **Count-in-9-places maintenance** for signals. A skill rule catches
   drift, but a generator reading `signal_bus.gd` and writing the count
   into every doc would be correct by construction. I didn't build it
   because the drift rate was already ~0, but it's the obvious next
   step.
3. **No CI.** Everything runs locally. The first thing I'd add for a
   collaborator is a GitHub Actions workflow running
   `run_gdunit_parallel.sh` on every push.

---

## Words to use

**Do use:** *grounding, retrieval-augmented, hybrid retrieval, structural
drift, policy layer, machine-readable architecture, exit-code taxonomy,
test staircase, headless integration, data-driven tuning, governance
layer, audit trail, invariants, idempotent orchestration.*

**Avoid:** "vibe-coded" (the CV frames this deliberately — "AI-augmented
engineering" / "methodology for governing LLM-generated code" is the
register I picked). "I just told Cursor to build it" (*factually* true
but it undersells the scaffolding, which is what the interview is
actually about).

---

## If the interviewer opens the repo

Hand them this tour in order. Each step is ~30 seconds.

1. **`AGENTS.md`** — "This is what the agent reads first every session."
2. **`.cursor/mcp.json`** — "Six MCP servers. The interesting one is
   `foulward-rag` — I wrote that."
3. **`new_rag_mpc/rag_mcp_server.py`** — "~760 lines of Python.
   Hybrid retrieval + LangGraph with SQLite memory."
4. **`tools/run_gdunit_parallel.sh`** — "Sharded across 8 processes.
   Note the `139`/`134` → `101` exit-code remapping."
5. **`autoloads/auto_test_driver.gd`** — "Dormant unless `--autotest`.
   Drives a scripted integration sequence. Writes to stderr — stdout is
   reserved for MCP JSON-RPC."
6. **`docs/archived/prompts/PROMPT_76_IMPLEMENTATION.md`** — "Example session log (parallel-runner
   metrics). Every change has a record with pass/fail status and any deviations."
7. **`autoloads/signal_bus.gd`** — "77 typed signals. `grep -c '^signal '`
   the file and you get 77 — the skill enforces that count propagates
   to 9 documented locations."
8. **`.cursor/skills/signal-bus/SKILL.md`** — "A domain-scoped skill.
   Trigger keywords, rule, how-to, maintenance checklist."

End of cheat sheet.
