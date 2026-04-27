# PROMPT 96 — UniRig skin checkpoint load (PyTorch 2.6 / Box)

## Step 0 error (reproduced)

`torch.load(ckpt, map_location='cpu')` → **`UnpicklingError` / WeightsUnpickler** (PyTorch 2.6 defaults `weights_only=True`). Same checkpoint loads with **`weights_only=False`**.

## Fix (Case B + C)

**File:** `~/UniRig-repo/run.py` only.

When `resume_from_checkpoint` is set (train resume, predict, or validate with a `.ckpt`):

1. **`torch.serialization.add_safe_globals([Box])`** when available (belt-and-suspenders for safe unpickle paths).
2. Temporarily replace **`torch.load`** with a wrapper that forces **`kwargs["weights_only"] = False`** (Lightning may pass `weights_only=True` explicitly, so `setdefault` is insufficient).
3. **`finally`**: restore original **`torch.load`**.

## Verification

- Direct `torch.load(..., weights_only=False)` + `add_safe_globals([Box])`: loads dict with expected top-level keys (`state_dict`, `hyper_parameters`, …).
- `run.py` → `trainer.predict(...)` with skin task: proceeds past checkpoint connector; subsequent failure without a full Gen3D tree was only missing `predict_skeleton.npz` in a minimal manual invocation (expected without full skeleton extract layout).

## Stage 3 isolation

Not re-validated end-to-end in this workspace: `art/gen3d_candidates/orc_grunt/**/*.glb` absent here (ignored / empty clone). On a machine with the Prompt 94 GLB tree, re-run the Step 4 snippet from the user prompt.
