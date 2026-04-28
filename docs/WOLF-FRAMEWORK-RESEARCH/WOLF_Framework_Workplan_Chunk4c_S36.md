# WOLF Framework — Master Workplan
## Chunk 4c: Phase 2 Session S36
### WOLF-SHOWCASE: Demo Launcher

**Document version:** 1.0 | **Continues from:** Chunk 4b Part 5 (S34–S35)
**Covers:** S36 only.
**Prerequisites:** All S21–S35 complete and passing their own GdUnit4 suites.

---

## Session S36 — WOLF-SHOWCASE: Demo Launcher

**Goal:** Build a polished, standalone launcher application that presents all
fifteen Phase 2 demo games under a unified WOLF brand identity — giving first-time
visitors, potential contributors, and press a single entry point that communicates
the full breadth of what the framework can produce. The launcher is not a game;
it is the framework's public face. [file:1]

**The launcher in one sentence:** A visually cohesive menu application that lets
any visitor browse all fifteen WOLF demo games by genre, read a one-paragraph
description, watch a short animated preview, and launch the selected game directly
from the Godot editor or from a compiled export. [file:1]

### Why this session matters

Every prior session produced a game. This session produces the thing that makes
all the games matter to someone who has never heard of WOLF. The showcase is the
first thing a prospective user or contributor will run. If it looks hand-assembled
or generic, the framework's credibility suffers regardless of the quality of the
games themselves. The bar here is: a human designer at an indie studio would be
comfortable shipping this as a product page. [file:1]

### What the launcher must do

- Display all 15 demo games with title, genre tag, one-line hook, and a static
  or animated preview image [file:1]
- Filter by genre (Tower Defense, RTS, Card, Strategy, Autobattler, Dungeon,
  Hybrid, Narrative) [file:1]
- Highlight 3–4 featured demos on a hero panel (recommended: WOLF-TD, WOLF-RTS,
  WOLF-SURVIVAL, WOLF-ROGUE as the most system-diverse) [file:1]
- Launch the selected game scene directly in the same Godot project or open the
  correct game folder if running in editor mode [file:1]
- Display a brief WOLF framework description and link to the docs site [file:1]
- Run at 1920×1080 and 1280×720 without layout breaks [file:1]
- Support both light and dark mode via the same theme-toggle pattern used across
  the framework [file:1]
- Look good enough to be the thumbnail on the GitHub repository [file:1]

### Systems exercised (launcher-level)

- `Localisation` — all game titles, descriptions, and genre tags through `en.po` [file:1]
- `SoundBridge` — ambient background music loop, hover SFX, selection SFX [file:1]
- `SavePayload` light usage — remembers last-selected genre filter and last-launched
  game across sessions [file:1]
- `wolf art generate` pipeline from S03/S38 — preview images for each game
  generated via the art pipeline and dropped into `assets/previews/` [file:1]
- `SignalBus` for a handful of launcher-specific signals:
  `game_selected(game_id)`, `genre_filter_changed(genre)`, `launcher_launched(game_id)` [file:1]

### Design direction

The visual language must feel like a game framework made by a developer who cares
about aesthetics — not a Unity asset store template. Reference points: the Godot
Asset Library's clean catalogue layout, Itch.io's game card grid, and the tone
of a well-made indie portfolio site. [file:1]

Specific requirements: [file:1]
- Dark-first design (dark mode as the default, light available via toggle) [file:1]
- A custom WOLF logo mark used consistently — wordmark in the header, favicon as
  the project icon [file:1]
- Game cards use a subtle surface elevation (shadow + border) rather than
  coloured side borders or gradient fills [file:1]
- Genre filter tabs, not a dropdown [file:1]
- The hero panel uses a large preview image with overlay text — not a text block
  beside a thumbnail [file:1]
- No emoji, no icon-in-circle decoration, no "Empowering your game development
  journey" copy [file:1]

### Perplexity context to load

- Chunks 4a–4b full game list with titles, genres, one-line hooks (extract from
  each session's "game in one sentence") [file:1]
- `framework/skills/wolf-architecture.md` for SignalBus signal-naming conventions [file:1]
- `framework/docs/SYSTEMS_REFERENCE.md` from S14 for the framework description copy [file:1]
- Any art pipeline preview images already generated in S38 (if S38 runs first)
  or placeholder paths if S38 runs after [file:1]

### Key questions for this session

1. Game launching mechanism: when the player clicks "Launch" in the editor, should
   the launcher change scene to the selected game's main scene (`get_tree().change_scene_to_file()`),
   or open a separate Godot window? Recommendation: change scene for the compiled
   export, show a "Open in editor: navigate to `wolf-games/{game-name}/`" tooltip
   for editor-mode users. A `LaunchMode` enum in `ShowcaseConfig.tres` controls this. [file:1]
2. Preview images: should they be static generated PNGs or animated `.webm` clips?
   Recommendation: static PNGs for the card grid (fast load), one short looping
   `.webm` for the hero panel of the currently hovered or selected game. [file:1]
3. Should all 15 games be selectable on day one of the launcher release, or should
   unreleased games show as "Coming Soon" cards? Recommendation: all 15 visible,
   with a `is_available: bool` field on `ShowcaseGameData.tres` — "Coming Soon"
   cards are greyed out and not launchable but show the genre and hook. [file:1]
4. WOLF logo: wordmark only, or icon mark + wordmark? Recommendation: a minimal
   geometric icon mark (wolf-head abstracted into 3–4 triangular facets, SVG)
   plus the wordmark "WOLF" in a bold geometric sans-serif. The icon mark should
   work at 32×32 as a favicon. [file:1]

### Cursor prompts to generate (7 prompts)

1. Design the WOLF visual identity — write `assets/brand/wolf_logo.svg`: geometric
   wolf-head mark built from 4–5 triangular facets, monochrome, works at 32px and
   512px; `assets/brand/wolf_wordmark.svg`: "WOLF" in a bold geometric sans-serif
   with letter-spacing 0.15em; `assets/brand/wolf_favicon.png`: 32×32 simplified
   mark; define the launcher's colour tokens in `ShowcaseTheme.tres`:
   dark-mode surface `#111210`, accent `#4f98a3` (Hydra Teal from Nexus palette),
   text `#cdccca`, card surface `#1c1b19`, hero overlay gradient from transparent
   to `#111210` from right to left; confirm the identity reads as "serious indie
   framework" not "game jam project" [file:1]

2. Write `resources/showcase/` fifteen `ShowcaseGameData.tres` resources — one per
   game; fields: `game_id`, `display_title`, `genre_tag`, `genre_enum`,
   `hook_text_key` (Localisation key for one-line description), `systems_highlights`
   (Array of 3 system names), `preview_image_path`, `preview_video_path`,
   `main_scene_path`, `is_available: bool`; populate all 15 from the Phase 2
   session documents; set `is_available = true` for all since all games are built
   before this session [file:1]

3. Write `scenes/ShowcaseLauncher.tscn` and `scripts/showcase/LauncherController.gd`
   — layout: header bar (WOLF wordmark + dark/light toggle + docs link),
   hero panel (full-width, 40% viewport height, animated preview of featured game,
   overlay with title + hook + "Launch" button), genre filter tab row (8 genre tabs
   + "All"), game card grid (3-column at 1920px, 2-column at 1280px, 1-column at
   720px); `LauncherController` loads all `ShowcaseGameData.tres` resources on
   `_ready`, populates card grid, handles genre filter changes via
   `genre_filter_changed` signal, handles card selection updating the hero panel [file:1]

4. Write `scenes/showcase/GameCard.tscn` and `scripts/showcase/GameCardController.gd`
   — card layout: preview image (16:9, lazy-loaded), genre tag pill, title, hook
   text (max 2 lines, ellipsis overflow), 3 system highlight chips;
   hover state: subtle `shadow-md` lift + accent border (`1px solid --color-primary`
   at 40% opacity); selected state: accent border at full opacity + "Launch" button
   appears at card bottom; `is_available = false` state: greyed card, overlay
   "Coming Soon" pill, Launch button hidden; all text through Localisation;
   hover and select emit `game_selected(game_id)` to SignalBus [file:1]

5. Write `scenes/showcase/HeroPanel.tscn` and `scripts/showcase/HeroPanelController.gd`
   — on `game_selected(game_id)`: crossfade preview image, update title + hook +
   system highlights + genre tag; autoplay `.webm` preview clip if available,
   fall back to static image; "Launch" button calls `LauncherController.launch_game(game_id)`:
   in export mode calls `get_tree().change_scene_to_file(main_scene_path)`,
   in editor mode shows a `ShowcaseEditorNote.tscn` popup with folder path and
   copy-path button; hero panel features four fixed highlighted games in rotation
   on startup before the user makes a selection [file:1]

6. Write `scripts/showcase/ShowcaseSaveState.gd` — lightweight save using
   `SavePayload` pattern: stores `last_genre_filter`, `last_selected_game_id`;
   saves on every filter change and game launch; loads on `_ready` to restore
   last state; also writes a `launcher_analytics.json` locally (no network calls)
   tracking which games were launched and how many times — this data feeds the
   WOLF community page eventually [file:1]

7. Write `scenes/showcase/AboutPanel.tscn` — accessible from header "About WOLF"
   button; panels: Framework description (3 sentences from `SYSTEMS_REFERENCE.md`),
   system count, game count, GitHub link, docs site link, licence statement;
   includes a collapsible "Built with" section listing all 18 addons with their
   licences; write 4 GdUnit4 tests: `ShowcaseGameData` resources all load without
   error, genre filter correctly hides non-matching cards, `LauncherController`
   updates hero panel on game selection signal, `ShowcaseSaveState` restores last
   genre filter on reload; run `wolf test --game wolf-showcase` and confirm all pass [file:1]

### Deliverables

- [ ] `wolf-games/wolf-showcase/` scaffolded via `wolf new` [file:1]
- [ ] `assets/brand/wolf_logo.svg` — geometric wolf mark [file:1]
- [ ] `assets/brand/wolf_wordmark.svg` [file:1]
- [ ] `assets/brand/wolf_favicon.png` [file:1]
- [ ] `ShowcaseTheme.tres` — launcher colour tokens [file:1]
- [ ] `resources/showcase/` fifteen `ShowcaseGameData.tres` resources [file:1]
- [ ] `scenes/ShowcaseLauncher.tscn` + `scripts/showcase/LauncherController.gd` [file:1]
- [ ] `scenes/showcase/GameCard.tscn` + `scripts/showcase/GameCardController.gd` [file:1]
- [ ] `scenes/showcase/HeroPanel.tscn` + `scripts/showcase/HeroPanelController.gd` [file:1]
- [ ] `scripts/showcase/ShowcaseSaveState.gd` [file:1]
- [ ] `scenes/showcase/AboutPanel.tscn` [file:1]
- [ ] 4 GdUnit4 tests passing [file:1]
- [ ] Launcher renders correctly at 1920×1080 and 1280×720 (verified, screenshots
      in session result report) [file:1]
- [ ] Dark mode is default; light mode toggle works without layout break (verified) [file:1]
- [ ] All 15 game cards display with correct title, genre tag, and hook text [file:1]
- [ ] Genre filter correctly shows/hides cards for all 8 genre categories [file:1]
- [ ] Hero panel crossfade and video autoplay work without stutter [file:1]
- [ ] "Launch" button successfully changes scene to WOLF-TD as a smoke test [file:1]
- [ ] WOLF logo committed to `wolf-framework/assets/brand/` and referenced in
      the docs site config for Phase 3 [file:1]

### Session result report requirements

This session has a higher documentation bar than most because the visual output is
the framework's public identity. The session result report must include: [file:1]

- Screenshots of the launcher at 1920×1080 (dark mode) and 1280×720 (light mode) [file:1]
- A screenshot of the hero panel with WOLF-SURVIVAL selected (the most visually
  impressive preview) [file:1]
- A screenshot of the genre filter with "Card" active showing the three card games [file:1]
- The SVG wolf logo rendered at 512px and 32px side by side [file:1]
- One sentence confirming no hardcoded strings — all text goes through Localisation [file:1]

### Unlocks

The WOLF logo and brand assets created here are used by: S39 docs site header,
GitHub repository social preview, HuggingFace space thumbnail, and the framework's
`README.md` banner. The launcher itself becomes the primary public demo link shared
in the launch announcement. [file:1]

---

## Phase 2 Completion State After S36

| Session | Game | Status after S36 |
|---------|------|-----------------|
| S21–S35 | All 15 playable demos | ✅ Built |
| S36 | WOLF-SHOWCASE launcher | ✅ Built |
| S37 | Balance Pass | ⏳ Next |
| S38 | Asset Pass | ⏳ Next |

After S36 is accepted, Phase 2 has all playable content and its public face.
S37 and S38 are polish passes that improve quality without adding new games or scenes. [file:1]

*End of Chunk 4c. S37 and S38 will be documented separately as agreed.* [file:1]
