# Foul Ward — `docs/` layout

Quick map of **active** documentation. New session logs go to **`docs/PROMPT_[N]_IMPLEMENTATION.md`** (next unused **N**); only the **10** newest `PROMPT_*` files stay here — older logs move to **`docs/archived/prompts/`** (see repo-root **`AGENTS.md`** rule 15).

**GitHub landing:** repo-root **`README.md`** links **`HOW_IT_WORKS.md`**, **`INTERVIEW_CHEATSHEET.md`**, and **`AGENTS.md`**.

## Primary indexes (read these first)

| File | Role |
|------|------|
| **`README.md`** (repo root) | Project one-liner, quick build/test, links to engineering narrative docs. |
| **`INDEX_SHORT.md`** | Compact map: autoloads, managers, scenes, resources, tests. |
| **`INDEX_FULL.md`** | Expanded API-style reference (signals, methods, resource fields). |

## Architecture and rules

| File | Role |
|------|------|
| **`ARCHITECTURE.md`** | Scene tree, autoload order, system boundaries. |
| **`CONVENTIONS.md`** | Naming, signals, typing, project habits. |
| **`SYSTEMS_part1.md` … `part3.md`** | Deeper system notes (split for size). |

## Design and product

| File | Role |
|------|------|
| **`FoulWard_MVP_Specification.md`** | MVP scope and gameplay spec. |
| **`Game_Design_Document.md`** | Broader design reference. |
| **`Foul Ward - end product estimate.md`** | Planning / scope estimate. |

## Operations and tooling

| File | Role |
|------|------|
| **`UBUNTU_REPLAY_SETUP.md`** | Ubuntu-specific replay or tooling notes. |

## Living reference

| File | Role |
|------|------|
| **`FOUL_WARD_MASTER_DOC.md`** | Comprehensive LLM/human reference (APIs, flows, anti-patterns). |
| **`SUMMARY_VERIFICATION.md`** | Read-only audit aggregate (three-part verification). |
| **`FUTURE_3D_MODELS_PLAN.md`** | Production 3D art roadmap (placeholders → shipping assets). |

## Session logs and archive

| Path | Role |
|------|------|
| **`PROMPT_80_IMPLEMENTATION.md` … `PROMPT_89_IMPLEMENTATION.md`** (current range) | The **10** session logs kept under `docs/` (rolling window). |
| **`archived/prompts/`** | All older `PROMPT_*_IMPLEMENTATION.md` files + `README.md` policy. |
| **`archived/README.md`** | What the archive folder contains after the 2026-04-20 doc cleanup. |

Large one-off exports (`REPO_DUMP_*`, scratch Perplexity trees, compliance batches) were **removed** from the tree in that cleanup; use **`git log`** / **`git show`** if you need the old text.
