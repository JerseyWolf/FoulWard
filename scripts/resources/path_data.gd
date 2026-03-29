## path_data.gd
## Spatial path binding for a lane (Curve3D asset + routing rules).
##
## Design/spec documents refer to this as **PathData**. The registered `class_name` is
## `RoutePathData` because Godot already defines a built-in `PathData` type; use
## `RoutePathData` everywhere in GDScript to avoid parser/shadowing issues.

## Named `RoutePathData` to avoid clashing with Godot's built-in `PathData` type name.
class_name RoutePathData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var lane_id: String = ""

## Path to a Curve3D resource or scene sub-path (often `res://.../*.tres`; loader interprets).
@export var curve3d_path: NodePath = NodePath("")

# Bitmask: flag index matches `Types.EnemyBodyType` ordinal (0..7).
@export_flags(
		"ground",
		"flying",
		"hover",
		"boss",
		"structure",
		"large_ground",
		"siege",
		"ethereal"
) var body_types_allowed: int = 0

## Cached path length for AI lookahead / wave timing (0 = compute at runtime).
@export var total_length_hint: float = 0.0

## When true, blocker allies can affect this path segment.
@export var blocker_sensitive: bool = true

## Tag emitted when enemies leak through this path (mission analytics).
@export var leak_entry_point_tag: String = ""

@export var tags: PackedStringArray = PackedStringArray()


func collect_validation_warnings() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if id.is_empty():
		out.append("path id is empty")
	if lane_id.is_empty():
		out.append("lane_id is empty")
	if curve3d_path.is_empty():
		out.append("curve3d_path is empty")
	return out
