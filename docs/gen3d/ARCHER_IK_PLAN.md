# Orc Archer — Bow IK Architecture Plan

**Status:** Deferred — full implementation requires `weapon_bone_recurve_bow.glb` to exist first.  
**Last updated:** 2026-04-22

---

## Overview

The orc_archer uses a bow held in the left hand with the right hand drawing the string.
Procedural `SkeletonIK3D` drives the right arm toward a nock point on the bow mesh
while the animation clip plays on the left arm. The bow string pull is driven by a morph
target on the bow mesh, keyed by `AnimationPlayer`.

---

## Node Tree (ASCII)

```
CharacterRoot (Node3D)
└── Skeleton3D
    ├── BoneAttachment3D  [bone_name = "LeftHand"]  ← bow arm
    │   └── bow.glb (Node3D instance)
    │       └── MeshInstance3D  [morph target: "string_pull"]
    └── SkeletonIK3D  [name = "DrawArmIK"]
        ├── root_bone  = "Spine"
        └── tip_bone   = "RightHand"
```

---

## Bones Involved

| Role | Bone Name | Notes |
|------|-----------|-------|
| Bow arm (hold) | `LeftHand` | BoneAttachment3D parent; bow GLB is a child |
| Draw arm (pull) | `RightHand` | SkeletonIK3D tip — IK drives this toward nock point |
| IK chain root | `Spine` | Anchors the IK solve to the torso |
| Nock marker | marker node on bow mesh | Empty Node3D child of bow GLB at string nock position |

---

## SkeletonIK3D Configuration

```gdscript
var ik: SkeletonIK3D = SkeletonIK3D.new()
ik.root_bone = "Spine"
ik.tip_bone = "RightHand"
# Magnet offset pulls the elbow outward for a natural draw pose
ik.magnet = Vector3(0.3, 0.0, -0.2)
# Target is set each frame to the nock marker's global_position
# ik.target_node = bow_nock_path  (set at runtime after bow GLB instantiation)
ik.min_distance = 0.0
ik.max_distance = 0.8   # max draw length in metres
ik.interpolation = 1.0  # fully IK-driven when drawing; lerp to 0 during idle
```

The `interpolation` property is animated by `AnimationPlayer` to blend between
the clip-driven pose (idle/walk) and the IK-solved draw pose (attack_melee).

---

## String Pull — Morph Target

The bow mesh (`weapon_bone_recurve_bow.glb`) must be exported from Blender with
a shape key named `"string_pull"` (value 0.0 = rest, 1.0 = full draw).

In Godot the morph target is driven by an `AnimationPlayer` track:

```
AnimationPlayer  →  track: "MeshInstance3D:blend_shapes/string_pull"
  Key 0.0s  →  0.0   (arrow nocked, string at rest)
  Key 0.3s  →  1.0   (full draw, release point)
  Key 0.35s →  0.0   (string snaps back)
```

The same `AnimationPlayer` that drives the `attack_melee` clip controls this track
so the draw and release are frame-accurate with the arm animation.

---

## Runtime Setup (deferred GDScript — do not implement yet)

```gdscript
# Called after orc_archer GLB is instantiated and bow is attached via WeaponAttachment:
func _setup_draw_arm_ik(skeleton: Skeleton3D, bow_root: Node3D) -> void:
    var nock_marker: Node3D = bow_root.find_child("NockMarker", true, false) as Node3D
    if nock_marker == null:
        push_warning("orc_archer: NockMarker not found in bow GLB — IK skipped")
        return
    var ik: SkeletonIK3D = SkeletonIK3D.new()
    ik.name = "DrawArmIK"
    ik.root_bone = "Spine"
    ik.tip_bone = "RightHand"
    ik.magnet = Vector3(0.3, 0.0, -0.2)
    ik.interpolation = 0.0
    skeleton.add_child(ik)
    ik.target_node = ik.get_path_to(nock_marker)
    ik.start()
```

---

## Deferred Implementation Checklist

- [ ] `weapon_bone_recurve_bow.glb` authored in Blender with `NockMarker` empty and `"string_pull"` shape key
- [ ] Bow placed into `art/generated/weapons/weapon_bone_recurve_bow.glb`
- [ ] `WeaponAttachment.attach()` called for `orc_archer` → `LeftHand` (already wired in `WEAPON_ASSIGNMENTS`)
- [ ] `_setup_draw_arm_ik()` called after bow instantiation in orc_archer scene script
- [ ] `AnimationPlayer` `attack_melee` clip extended with `blend_shapes/string_pull` track
- [ ] `SkeletonIK3D.interpolation` animated: 0 during idle/walk, 1 during draw, 0 after release
