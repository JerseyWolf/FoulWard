# SPDX-License-Identifier: MIT
"""Stage 2: TRELLIS.2 image → GLB (in-process; run with ``FOULWARD_PYTHON`` = trellis2 env).

Bypass TRELLIS::

    export FOULWARD_GEN3D_STAGE2_MODE=input_file
    export FOULWARD_GEN3D_STAGE2_INPUT_GLB=/path/to/existing.glb

Placeholder box (stages 3–5 smoke test)::

    export FOULWARD_GEN3D_STAGE2_MODE=placeholder

**Public rembg:** default ``FOULWARD_TRELLIS_PUBLIC_REMBG=1`` rewrites cached ``pipeline.json`` to
``ZhengPeng7/BiRefNet`` instead of gated ``briaai/RMBG-2.0`` (see module body).
"""

from __future__ import annotations

import json
import os
import struct
import sys
from pathlib import Path
from typing import Any

import shutil
import trimesh


def remove_background(image_path: str, out_path: str) -> str:
    """
    Remove the background from a character image using rembg, producing
    an RGBA PNG with a transparent background. TRELLIS performs significantly
    better on transparent-background RGBA images than white-background RGB —
    it cannot misinterpret the white background as geometry.

    Uses ``rembg`` from the **current** Python interpreter (run foulward_gen
    with ``conda run -n trellis2`` or ``$FOULWARD_PYTHON`` pointing at trellis2).
    Nested ``conda run`` subprocesses are avoided because they fail when the
    pipeline itself is already launched via ``conda run``.

    Args:
        image_path: Path to the input image (white background PNG).
        out_path:   Where to save the output RGBA PNG.

    Returns:
        out_path after saving.
    """
    from rembg import remove

    with open(image_path, "rb") as f:
        data: bytes = f.read()
    out_bytes: bytes = remove(data)
    with open(out_path, "wb") as f:
        f.write(out_bytes)
    return out_path


def clean_mesh_before_decimation(mesh: trimesh.Trimesh) -> trimesh.Trimesh:
    """
    Apply trimesh cleaning operations to remove degenerate geometry
    before decimation. This reduces the chance that the decimator collapses
    legitimate faces into degenerate ones, which can produce razor-shard
    artifacts on noisy TRELLIS output.

    Operations applied in order:
    1. merge_vertices — weld duplicate/near-duplicate vertices
    2. remove degenerate faces (zero-area)
    3. remove duplicate faces (overlapping copies)
    4. fix_winding / fix_normals — consistent winding order
    5. remove_unreferenced_vertices
    """
    from trimesh import repair

    original_faces: int = int(len(mesh.faces))

    mesh.merge_vertices(merge_tex=False, merge_norm=False)

    mesh.update_faces(mesh.nondegenerate_faces())
    mesh.update_faces(mesh.unique_faces())

    repair.fix_winding(mesh)
    repair.fix_normals(mesh)

    mesh.remove_unreferenced_vertices()

    cleaned_faces: int = int(len(mesh.faces))
    removed: int = original_faces - cleaned_faces
    print(
        f"[clean] Removed {removed} degenerate/duplicate faces "
        f"({original_faces} → {cleaned_faces})"
    )

    if original_faces > 0 and removed > original_faces * 0.3:
        print("[clean] WARNING: >30% faces removed — input mesh was very noisy")

    return mesh


def _load_combined_mesh(input_path: str) -> trimesh.Trimesh:
    """Load a GLB and return a single combined Trimesh, preserving visual data."""
    scene: Any = trimesh.load(input_path, process=False, force="scene")
    if isinstance(scene, trimesh.Scene):
        meshes: list[trimesh.Trimesh] = [
            g for g in scene.geometry.values() if isinstance(g, trimesh.Trimesh)
        ]
        if not meshes:
            raise ValueError(f"No triangle meshes found in {input_path}")
        if len(meshes) == 1:
            return meshes[0]
        return trimesh.util.concatenate(meshes)
    return scene  # type: ignore[return-value]


def _decimate_o3d(
    vertices: Any,
    faces: Any,
    target_faces: int,
) -> tuple[Any, Any, Any]:
    """
    Decimate geometry with Open3D quadric decimation.

    Returns (verts_out, faces_out, normals_out) as numpy arrays.
    Open3D correctly reaches the target face count even on non-manifold TRELLIS
    meshes. Visual data is intentionally NOT passed in; callers preserve it via
    nearest-vertex re-projection after this call.
    """
    import numpy as np
    import open3d as o3d

    o3d_mesh: o3d.geometry.TriangleMesh = o3d.geometry.TriangleMesh()
    o3d_mesh.vertices = o3d.utility.Vector3dVector(
        np.asarray(vertices, dtype=np.float64).copy()
    )
    o3d_mesh.triangles = o3d.utility.Vector3iVector(
        np.asarray(faces, dtype=np.int32).copy()
    )
    decimated: o3d.geometry.TriangleMesh = o3d_mesh.simplify_quadric_decimation(
        target_number_of_triangles=int(target_faces)
    )
    decimated.compute_vertex_normals()
    verts_out: Any = np.asarray(decimated.vertices, dtype=np.float64)
    faces_out: Any = np.asarray(decimated.triangles, dtype=np.int64)
    normals_out: Any = np.asarray(decimated.vertex_normals, dtype=np.float64)
    return verts_out, faces_out, normals_out


def decimate_glb(input_path: str, out_path: str, target_faces: int = 10000) -> str:
    """
    Decimate a GLB mesh to approximately target_faces triangles while
    preserving UV maps, vertex colors, and PBR materials.

    Strategy:
      1. Load with trimesh (preserves full visual/material data).
      2. Decimate geometry with Open3D's simplify_quadric_decimation.
         Open3D reliably reaches the target face count even on the
         non-manifold TRELLIS meshes (fast_simplification plateaus at
         ~38k faces due to seam-vertex topology on these meshes).
      3. Re-project visual data from the original high-res mesh onto
         decimated vertices via scipy cKDTree nearest-vertex lookup.
         For TextureVisuals: re-project UV + reattach PBRMaterial.
         For ColorVisuals: re-project per-vertex RGBA colors.
         For geometry-only meshes: export normals only (no change).
      4. Export as GLB with textures/materials fully embedded.

    Args:
        input_path:   Path to raw GLB from TRELLIS.
        out_path:     Where to save the decimated GLB.
        target_faces: Target triangle count. Default 10000 for standard units.

    Returns:
        out_path after saving.
    """
    import numpy as np
    from scipy.spatial import cKDTree

    combined: trimesh.Trimesh = _load_combined_mesh(input_path)
    print(
        f"[decimate] Input: {len(combined.vertices)} verts, {len(combined.faces)} faces"
        f"  visual={type(combined.visual).__name__}"
    )

    combined = clean_mesh_before_decimation(combined)

    has_uv: bool = (
        isinstance(combined.visual, trimesh.visual.TextureVisuals)
        and combined.visual.uv is not None
        and len(combined.visual.uv) > 0
    )
    has_vc: bool = isinstance(combined.visual, trimesh.visual.ColorVisuals)
    print(f"[decimate] has_uv={has_uv}, has_vertex_colors={has_vc}")

    # Capture original visual data before geometry decimation
    original_uvs: Any = combined.visual.uv.copy() if has_uv else None
    original_material: Any = combined.visual.material if has_uv else None
    original_vc: Any = None
    if has_vc:
        try:
            original_vc = combined.visual.vertex_colors.copy()
        except Exception:
            original_vc = None

    # Geometry decimation via Open3D
    verts_out, faces_out, normals_out = _decimate_o3d(
        combined.vertices, combined.faces, target_faces
    )
    print(f"[decimate] Output: {len(verts_out)} verts, {len(faces_out)} faces")

    # Nearest-vertex UV/color re-projection from original high-res mesh
    tree: cKDTree = cKDTree(combined.vertices)
    _, idx = tree.query(verts_out, k=1)

    if has_uv and original_uvs is not None and original_material is not None:
        new_uvs: Any = original_uvs[idx]
        print(f"[decimate] UV reprojected: {new_uvs.shape}  material={type(original_material).__name__}")
        decimated_mesh: trimesh.Trimesh = trimesh.Trimesh(
            vertices=verts_out,
            faces=faces_out,
            vertex_normals=normals_out,
            process=False,
        )
        decimated_mesh.visual = trimesh.visual.TextureVisuals(
            uv=new_uvs,
            material=original_material,
        )
    elif has_vc and original_vc is not None:
        new_vc: Any = original_vc[idx]
        unique_colors: int = len(np.unique(new_vc, axis=0))
        print(f"[decimate] Vertex colors reprojected: {unique_colors} unique")
        decimated_mesh = trimesh.Trimesh(
            vertices=verts_out,
            faces=faces_out,
            vertex_normals=normals_out,
            vertex_colors=new_vc,
            process=False,
        )
    else:
        print("[decimate] No UV/color data — geometry-only output")
        decimated_mesh = trimesh.Trimesh(
            vertices=verts_out,
            faces=faces_out,
            vertex_normals=normals_out,
            process=False,
        )

    export_scene: trimesh.Scene = trimesh.scene.scene.Scene(
        geometry={"geometry_0": decimated_mesh}
    )
    export_scene.export(out_path, file_type="glb")
    return out_path


# TRELLIS input square edge after pad (see tools/gen3d/scripts/trellis2_input_ab_variant.py A/B 2026-04-20).
# Community often uses ~770; front-only + 768 beat 770 and full-sheet configs on decimated NM proxy.
TRELLIS_INPUT_SIZE: int = int(os.environ.get("FOULWARD_TRELLIS_INPUT_EDGE", "768"))
# Texture bake resolution: 2048 for production quality
TEXTURE_RESOLUTION: int = 2048
# TRELLIS sparse / slat sampler steps — lower reduces internal-structure hallucination.
TRELLIS_SAMPLER_STEPS: int = int(os.environ.get("FOULWARD_TRELLIS_SAMPLER_STEPS", "8"))
TRELLIS_SPARSE_GUIDANCE: float = float(os.environ.get("FOULWARD_TRELLIS_SPARSE_GUIDANCE", "5.0"))
TRELLIS_SLAT_GUIDANCE: float = float(os.environ.get("FOULWARD_TRELLIS_SLAT_GUIDANCE", "2.0"))
def _trellis_repo_root() -> str:
    raw: str = os.environ.get("FOULWARD_TRELLIS_REPO", str(Path.home() / "TRELLIS.2"))
    return str(Path(raw).expanduser().resolve())


def _ensure_repo_on_path() -> None:
    root: str = _trellis_repo_root()
    if root not in sys.path:
        sys.path.insert(0, root)


def _stage2_mode() -> str:
    raw: str = os.environ.get("FOULWARD_GEN3D_STAGE2_MODE", "trellis").strip().lower()
    return raw if raw != "" else "trellis"


def _image_to_glb_from_input_file(out_p: Path) -> str:
    src: str = os.environ.get("FOULWARD_GEN3D_STAGE2_INPUT_GLB", "").strip()
    if src == "":
        raise ValueError(
            "FOULWARD_GEN3D_STAGE2_MODE=input_file requires FOULWARD_GEN3D_STAGE2_INPUT_GLB "
            "pointing to an existing .glb (e.g. a previous placeholder or manual mesh)."
        )
    src_p: Path = Path(src).expanduser().resolve()
    if not src_p.is_file():
        raise FileNotFoundError(f"FOULWARD_GEN3D_STAGE2_INPUT_GLB not found: {src_p}")
    shutil.copy2(src_p, out_p)
    return str(out_p)


def _image_to_glb_placeholder(out_p: Path) -> str:
    mesh: trimesh.Trimesh = trimesh.creation.box(extents=[0.6, 1.8, 0.4])
    mesh.export(str(out_p))
    return str(out_p)


def _trellis_public_rembg_enabled() -> bool:
    raw: str = os.environ.get("FOULWARD_TRELLIS_PUBLIC_REMBG", "1").strip().lower()
    return raw not in ("0", "false", "no", "off")


def _ensure_trellis_pipeline_json_and_public_rembg(model_id: str) -> None:
    """Prefetch ``pipeline.json`` and optionally swap gated RMBG for public BiRefNet."""
    if model_id != "microsoft/TRELLIS.2-4B":
        return
    try:
        from huggingface_hub import hf_hub_download

        hf_hub_download(repo_id=model_id, filename="pipeline.json")
    except Exception:
        pass

    if not _trellis_public_rembg_enabled():
        return

    hub_dir: Path = Path.home() / ".cache/huggingface/hub"
    pattern: str = "models--microsoft--TRELLIS.2-4B/snapshots/*/pipeline.json"
    for p in hub_dir.glob(pattern):
        try:
            text: str = p.read_text(encoding="utf-8")
            data: dict[str, Any] = json.loads(text)
            args: dict[str, Any] = data.get("args") or {}
            rembg_model: dict[str, Any] = args.get("rembg_model") or {}
            rargs: dict[str, Any] = rembg_model.get("args") or {}
            if rargs.get("model_name") != "briaai/RMBG-2.0":
                continue
            rargs["model_name"] = "ZhengPeng7/BiRefNet"
            p.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")
        except (OSError, json.JSONDecodeError, TypeError, KeyError):
            continue


def _write_placeholder_glb(out_path: str) -> str:
    json_chunk: bytes = b'{"asset":{"version":"2.0"}}'
    pad: int = (4 - len(json_chunk) % 4) % 4
    json_chunk += b" " * pad
    total_len: int = 12 + 8 + len(json_chunk)
    with open(out_path, "wb") as f:
        f.write(struct.pack("<4sII", b"glTF", 2, total_len))
        f.write(struct.pack("<II", len(json_chunk), 0x4E4F534A))
        f.write(json_chunk)
    print(f"[stage2] Placeholder GLB written: {out_path}")
    return out_path


def prepare_trellis_input(image_path: str, out_path: str) -> str:
    from PIL import Image, ImageOps

    img = Image.open(image_path).convert("RGBA")
    # Pad to square using white background, keep subject centered
    w, h = img.size
    size = max(w, h)
    padded = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    padded.paste(img, ((size - w) // 2, (size - h) // 2))
    edge: int = int(TRELLIS_INPUT_SIZE)
    padded = padded.resize((edge, edge), Image.LANCZOS)
    padded.convert("RGB").save(out_path)
    return out_path


def image_to_glb(
    image_path: str,
    out_path: str,
    model_id: str = "microsoft/TRELLIS.2-4B",
    tri_budget: int = 12000,
    seed: int | None = None,
) -> str:
    """
    Mesh from image, or bypass TRELLIS when ``FOULWARD_GEN3D_STAGE2_MODE`` is set.

    Args:
        image_path: Path to the front-view RGBA PNG (background-removed).
        out_path:   Where to save the raw textured GLB.
        model_id:   HuggingFace model ID for TRELLIS.2.
        tri_budget: Reserved for future use (TRELLIS pre-decimation handled via
                    ``FOULWARD_TRELLIS_PREDECIMATE`` env var; see below).
        seed:       Random seed for TRELLIS generation. ``None`` → random 32-bit seed.
                    Different seeds produce shape variants from the same image.

    Returns:
        out_path after saving.

    Environment variables:
        FOULWARD_TRELLIS_PREDECIMATE: Pre-decimation target inside TRELLIS's
            ``o_voxel.postprocess.to_glb``. Default 100000. Reduces raw GLB from
            ~38 MB to ~4 MB. Our ``decimate_glb`` step further reduces to target_faces.
            Set to a higher value (e.g. 1000000) for maximum source detail.
    """
    import random as _random

    _ = tri_budget  # reserved
    out_p: Path = Path(out_path).resolve()
    out_p.parent.mkdir(parents=True, exist_ok=True)

    if seed is None:
        seed = _random.randint(0, 2**32 - 1)
    print(f"[stage2] seed={seed}")

    mode: str = _stage2_mode()
    if mode == "input_file":
        return _image_to_glb_from_input_file(out_p)
    if mode == "placeholder":
        return _image_to_glb_placeholder(out_p)
    if mode != "trellis":
        raise ValueError(
            f"Unknown FOULWARD_GEN3D_STAGE2_MODE={mode!r}. Use trellis, input_file, or placeholder."
        )

    _ensure_trellis_pipeline_json_and_public_rembg(model_id)
    _ensure_repo_on_path()

    try:
        import o_voxel
        import torch
        from PIL import Image
        from trellis2.pipelines import Trellis2ImageTo3DPipeline
    except ImportError as e:
        print(f"[stage2] TRELLIS import failed: {e}")
        print("[stage2] Run: cd ~/TRELLIS.2 && pip install -e .")
        return _write_placeholder_glb(str(out_p))

    print(f"[stage2] Loading TRELLIS.2 ({model_id})...")
    pipeline = Trellis2ImageTo3DPipeline.from_pretrained(model_id)
    pipeline.cuda()

    if pipeline.rembg_model is not None and hasattr(pipeline.rembg_model, "model"):
        try:
            pipeline.rembg_model.model.float()
        except Exception:
            pass

    # Set seeds before generation for reproducibility
    import torch as _torch
    _torch.manual_seed(seed)
    if _torch.cuda.is_available():
        _torch.cuda.manual_seed_all(seed)

    trellis_input_path: str = prepare_trellis_input(
        image_path, image_path.replace(".png", "_trellis_input.png")
    )
    front_resized = Image.open(trellis_input_path).convert("RGB")
    print(f"[stage2] TRELLIS input: {trellis_input_path}")

    # TRELLIS pre-decimation target: default 100000 (from ~38MB raw → ~4MB).
    # Our decimate_glb step further reduces to the game-ready target (8k–20k).
    predecimate: int = int(os.environ.get("FOULWARD_TRELLIS_PREDECIMATE", "100000"))

    print(
        f"[stage2] Generating mesh"
        f" (sampler_steps={TRELLIS_SAMPLER_STEPS}, sparse_guidance={TRELLIS_SPARSE_GUIDANCE},"
        f" slat_guidance={TRELLIS_SLAT_GUIDANCE}, texture_size={TEXTURE_RESOLUTION},"
        f" predecimate={predecimate})..."
    )
    with _torch.no_grad():
        result = pipeline.run(
            front_resized,
            seed=seed,
            sparse_structure_sampler_params={
                "steps": TRELLIS_SAMPLER_STEPS,
                "guidance_strength": TRELLIS_SPARSE_GUIDANCE,
            },
            shape_slat_sampler_params={
                "steps": TRELLIS_SAMPLER_STEPS,
                "guidance_strength": TRELLIS_SLAT_GUIDANCE,
            },
            tex_slat_sampler_params={
                "steps": TRELLIS_SAMPLER_STEPS,
                "guidance_strength": TRELLIS_SLAT_GUIDANCE,
            },
        )

    mesh = result[0]
    mesh.simplify(16777216)
    glb_obj = o_voxel.postprocess.to_glb(
        vertices=mesh.vertices,
        faces=mesh.faces,
        attr_volume=mesh.attrs,
        coords=mesh.coords,
        attr_layout=mesh.layout,
        voxel_size=mesh.voxel_size,
        aabb=[[-0.5, -0.5, -0.5], [0.5, 0.5, 0.5]],
        decimation_target=predecimate,
        texture_size=TEXTURE_RESOLUTION,
        remesh=True,
        remesh_band=1,
        remesh_project=0,
        verbose=False,
    )
    glb_obj.export(str(out_p), extension_webp=True)

    size_mb: float = os.path.getsize(out_p) / 1e6
    print(f"[stage2] GLB exported: {out_p} ({size_mb:.1f}MB)")
    return str(out_p)


def _check_glb_has_texture(path: str) -> bool:
    """
    Return True if the GLB at *path* contains UV map or multi-color vertex data.
    Used as a post-generation diagnostic: a white mesh (all-white vertex colors,
    no UV) indicates TRELLIS did not produce texture for this seed.
    """
    import numpy as np

    try:
        scene: Any = trimesh.load(path, process=False)
        meshes: list[trimesh.Trimesh] = (
            list(scene.geometry.values())
            if isinstance(scene, trimesh.Scene)
            else [scene]
        )
        for m in meshes:
            if (
                isinstance(m.visual, trimesh.visual.TextureVisuals)
                and m.visual.uv is not None
                and len(m.visual.uv) > 0
            ):
                return True
            if isinstance(m.visual, trimesh.visual.ColorVisuals):
                try:
                    vc: Any = m.visual.vertex_colors
                    if vc is not None and len(np.unique(vc, axis=0)) > 1:
                        return True
                except Exception:
                    pass
    except Exception:
        pass
    return False


def generate_mesh_variants(
    image_path: str,
    out_dir: str,
    model_id: str = "microsoft/TRELLIS.2-4B",
    tri_budget: int = 10000,
    n_variants: int = 5,
    slug: str = "unit",
    project_root: str = "",
) -> list[str]:
    """
    Run TRELLIS N times on the same input image with different random seeds,
    producing N candidate GLBs. Each variant is immediately decimated and
    copied to two locations:

      - ``out_dir/candidate_{i}_decimated.glb``   (ephemeral working dir in /tmp)
      - ``{project_root}/art/gen3d_candidates/{slug}/candidate_{i}_decimated.glb``
        (permanent project storage — kept across reboots for post-run review)

    Raw per-variant GLBs are deleted after decimation to save disk space.

    Args:
        image_path:    Path to the front-view RGBA PNG (background removed).
        out_dir:       Working directory for raw + decimated candidates (e.g. /tmp/fw_slug_candidates).
        model_id:      HuggingFace model ID for TRELLIS.2.
        tri_budget:    Target triangle count for each decimated candidate.
        n_variants:    Number of mesh variants to generate. Default 5.
        slug:          Asset slug (e.g. "orc_grunt") used for the permanent storage path.
        project_root:  Godot project root path. If empty, permanent copy is skipped.

    Returns:
        List of ``n_variants`` paths to decimated candidate GLBs in *out_dir*.
    """
    import os
    import random
    import shutil

    os.makedirs(out_dir, exist_ok=True)

    # Set up permanent storage dir alongside ephemeral /tmp working dir
    permanent_dir: str = ""
    if project_root:
        permanent_dir = os.path.join(project_root, "art", "gen3d_candidates", slug)
        os.makedirs(permanent_dir, exist_ok=True)

    candidates: list[str] = []
    for i in range(1, n_variants + 1):
        print(f"\n[Stage 2] ── Variant {i}/{n_variants} ──")
        seed: int = random.randint(0, 2**32 - 1)
        raw: str = os.path.join(out_dir, f"candidate_{i}_raw.glb")
        decimated: str = os.path.join(out_dir, f"candidate_{i}_decimated.glb")

        print(f"[Stage 2] Generating mesh (seed={seed})...")
        image_to_glb(image_path, raw, model_id=model_id, tri_budget=None, seed=seed)

        if not _check_glb_has_texture(raw):
            print(
                f"[Stage 2] WARNING: candidate {i} raw GLB has no UV/color data"
                f" (seed={seed}) — output will be white mesh."
            )
        else:
            print(f"[Stage 2] Texture confirmed in candidate {i} raw GLB ✓")

        print(f"[Stage 2] Decimating candidate {i} → {tri_budget} faces...")
        decimate_glb(raw, decimated, target_faces=tri_budget)

        try:
            os.remove(raw)
        except OSError:
            pass

        # Permanent project copy — write immediately so it survives a /tmp wipe
        if permanent_dir:
            perm_path: str = os.path.join(permanent_dir, f"candidate_{i}_decimated.glb")
            shutil.copy2(decimated, perm_path)
            print(f"[Stage 2] Candidate {i} saved: {decimated}")
            print(f"[Stage 2]   permanent copy:   {perm_path}")
        else:
            print(f"[Stage 2] Candidate {i} ready: {decimated}")

        candidates.append(decimated)

    return candidates
