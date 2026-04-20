# Historical session logs (`PROMPT_N_IMPLEMENTATION.md`)

This folder holds **archived** Cursor/agent session write-ups. The **10 most recent** sessions live at repo root under `docs/` (after Prompt 88: `PROMPT_79` … `PROMPT_88`); older logs are moved here when a new session is logged.

## Policy (rolling window)

1. New work is logged to `docs/PROMPT_[N]_IMPLEMENTATION.md` where **N** is the next unused integer (see latest file in `docs/`).
2. When more than **10** files match `docs/PROMPT_*_IMPLEMENTATION.md`, move the **oldest** by number into this folder (preserve filename).

## Special case

- **`PROMPT_1_IMPLEMENTATION_v2.md`** — second session that reused number 1 (2026-03-31 skills audit). **`PROMPT_1_IMPLEMENTATION.md`** — original session (2026-03-24).

## Index

Summaries and cross-references: **`docs/INDEX_SHORT.md`**.

## Count

Full history is split between this folder and `docs/`; use:

```bash
find docs docs/archived/prompts -maxdepth 1 -name 'PROMPT_*_IMPLEMENTATION.md' | wc -l
```

Optional: directory `new_rag_mpc/` is a historical typo for “MCP”; renaming would touch `launch.sh` and MCP config — deferred.
