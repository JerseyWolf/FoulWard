// CREDIT: C# child node pattern for _PhysicsProcess performance
// Technique: A C# Node child takes over _PhysicsProcess from the GDScript parent.
//            Parent data is accessed via GodotObject.Get() / .Call() across the language boundary.
//            This avoids GDScript Variant boxing overhead on every float operation per frame.
// Reference: "Mixing GDScript + C# in One Godot Project" — Mina Pecheux, Feb 2025
//   https://www.youtube.com/watch?v=s3126UnPtpE
// Reference: GDScript Dictionary/Variant allocation overhead — reddit.com/r/godot
//   https://www.reddit.com/r/godot/comments/haa76f/
// Used in: ProjectilePhysics._PhysicsProcess(), position integration, range check, collision dispatch

using Godot;

/// <summary>
/// Per-frame projectile motion and lifetime for <see cref="ProjectileBase"/> (GDScript parent).
/// Parent keeps initialization, collision layers, damage, and SignalBus hooks.
/// </summary>
[GlobalClass]
public partial class ProjectilePhysics : Node
{
	private const float MaxLifetimeSeconds = 5.0f;

	/// <summary>Cached parent from <see cref="_Ready"/>.</summary>
	public Node? Parent { get; private set; }

	public override void _Ready()
	{
		Parent = GetParent();
	}

	public override void _PhysicsProcess(double delta)
	{
		if (Engine.IsEditorHint())
		{
			return;
		}

		Node? parent = GetParent();
		if (parent == null)
		{
			return;
		}

		if (parent.Get("_hit_processed").AsBool())
		{
			return;
		}

		float dt = (float)delta;
		float lifetime = parent.Get("_lifetime").AsSingle() + dt;
		parent.Set("_lifetime", lifetime);
		if (lifetime >= MaxLifetimeSeconds)
		{
			parent.Call("queue_free");
			return;
		}

		Variant posVar = parent.Get("global_position");
		var pos = posVar.AsVector3();
		Variant velVar = parent.Get("velocity");
		var velocity = velVar.AsVector3();
		Vector3 movement = velocity * dt;
		pos += movement;
		parent.Set("global_position", pos);
		parent.Call("force_update_transform");

		float traveledDistance = parent.Get("traveled_distance").AsSingle() + movement.Length();
		parent.Set("traveled_distance", traveledDistance);

		bool hit = parent.Call("_on_hit", parent).AsBool();
		if (hit)
		{
			return;
		}

		float maxRange = parent.Get("max_range").AsSingle();
		if (traveledDistance >= maxRange)
		{
			parent.Call("_on_range_exceeded");
		}
	}
}
