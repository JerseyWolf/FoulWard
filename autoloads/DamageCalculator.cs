// CREDIT: static readonly 2D array lookup table pattern
// Technique: C# static readonly multidimensional array for O(1) indexed damage lookup
// Replaces: GDScript Dictionary-based matrix in damage_calculator.gd
// Reference: "The 'in'-modifier and the readonly structs in C#"
//   https://devblogs.microsoft.com/premier-developer/the-in-modifier-and-the-readonly-structs-in-c/
// Used in: DamageCalculator.CalculateDamage(), _matrix initialization

using Godot;

/// <summary>
/// Stateless utility that applies armor-type multipliers to incoming base damage.
/// Simulation API: all public methods callable without UI nodes present.
/// </summary>
public partial class DamageCalculator : Node
{
	private const int DamageTypeCount = 5;
	private const int ArmorTypeCount = 4;
	private const int DamageTypeTrue = 4;

	// Indexed as _matrix[(int)damageType, (int)armorType] — matches Types.DamageType × Types.ArmorType in types.gd
	private static readonly float[,] _matrix = new float[,]
	{
		// PHYSICAL — UNARMORED, HEAVY_ARMOR, UNDEAD, FLYING
		{ 1.0f, 0.5f, 1.0f, 1.0f },
		// FIRE
		{ 1.0f, 1.0f, 2.0f, 1.0f },
		// MAGICAL
		{ 1.0f, 2.0f, 1.0f, 1.0f },
		// POISON
		{ 1.0f, 1.0f, 0.0f, 1.0f },
		// TRUE (matrix unused; CalculateDamage returns base early)
		{ 1.0f, 1.0f, 1.0f, 1.0f },
	};

	/// <summary>Returns base_damage multiplied by the matrix multiplier for the given armor and damage type.</summary>
	public float CalculateDamage(float baseDamage, int damageType, int armorType)
	{
		if (damageType == DamageTypeTrue)
		{
			return baseDamage;
		}
		if (damageType < 0 || damageType >= DamageTypeCount || armorType < 0 || armorType >= ArmorTypeCount)
		{
			return baseDamage;
		}
		return baseDamage * _matrix[damageType, armorType];
	}

	/// <summary>GDScript-visible name for <see cref="CalculateDamage"/> (existing callers use snake_case).</summary>
	public float calculate_damage(float baseDamage, int damageType, int armorType) =>
		CalculateDamage(baseDamage, damageType, armorType);

	/// <summary>Returns per-tick damage for a DoT effect (matrix-adjusted).</summary>
	public float CalculateDotTick(
		float dotTotalDamage,
		float tickInterval,
		float duration,
		int damageType,
		int armorType
	)
	{
		if (duration <= 0.0f || tickInterval <= 0.0f)
		{
			return 0.0f;
		}
		float ticks = duration / tickInterval;
		if (ticks <= 0.0f)
		{
			return 0.0f;
		}
		float perTickBase = dotTotalDamage / ticks;
		return CalculateDamage(perTickBase, damageType, armorType);
	}

	/// <summary>GDScript-visible name for <see cref="CalculateDotTick"/>.</summary>
	public float calculate_dot_tick(
		float dotTotalDamage,
		float tickInterval,
		float duration,
		int damageType,
		int armorType
	) =>
		CalculateDotTick(dotTotalDamage, tickInterval, duration, damageType, armorType);
}
