// CREDIT: Parallel C# enum mirror pattern for cross-language type safety
// Technique: Matching integer values between GDScript and C# enums allows
//            safe int casting across the language boundary.
// Reference: Godot 4.4 C# differences documentation
//   https://docs.godotengine.org/en/4.4/tutorials/scripting/c_sharp/c_sharp_differences.html
// Reference: GDScript global enum limitations — godot-proposals issue #240
//   https://github.com/godotengine/godot-proposals/issues/240
// Rule: types.gd is the single source of truth. FoulWardTypes.cs must be kept in sync manually.
// Used in: All future .cs files that need typed enum parameters.

/// <summary>
/// C# mirrors of <c>Types</c> enums from <c>res://scripts/types.gd</c>. For use in .cs files only.
/// </summary>
public static class FoulWardTypes
{
	/// <summary>C# mirror of Types.GameState from res://scripts/types.gd. Integer values are identical.</summary>
	public enum GameState
	{
		MainMenu = 0,
		MissionBriefing = 1,
		Combat = 2,
		BuildMode = 3,
		WaveCountdown = 4,
		BetweenMissions = 5,
		MissionWon = 6,
		MissionFailed = 7,
		GameWon = 8,
		GameOver = 9,
		Endless = 10,
		PassiveSelect = 11,
		/// <summary>Ring rotation pre-combat screen.</summary>
		RingRotate = 12,
	}

	/// <summary>C# mirror of Types.DamageType from res://scripts/types.gd. Integer values are identical.</summary>
	public enum DamageType
	{
		Physical = 0,
		Fire = 1,
		Magical = 2,
		Poison = 3,
		True = 4,
	}

	/// <summary>C# mirror of Types.ArmorType from res://scripts/types.gd. Integer values are identical.</summary>
	public enum ArmorType
	{
		Unarmored = 0,
		HeavyArmor = 1,
		Undead = 2,
		Flying = 3,
	}

	/// <summary>C# mirror of Types.BuildingType from res://scripts/types.gd. Integer values are identical.</summary>
	public enum BuildingType
	{
		ArrowTower = 0,
		FireBrazier = 1,
		MagicObelisk = 2,
		PoisonVat = 3,
		Ballista = 4,
		ArcherBarracks = 5,
		AntiAirBolt = 6,
		ShieldGenerator = 7,
		SpikeSpitter = 8,
		EmberVent = 9,
		FrostPinger = 10,
		Netgun = 11,
		AcidDripper = 12,
		Wolfden = 13,
		CrowRoost = 14,
		AlarmTotems = 15,
		CrossfireNest = 16,
		BoltShrine = 17,
		Thornwall = 18,
		FieldMedic = 19,
		GreatbowTurret = 20,
		MoltenCaster = 21,
		ArcaneLens = 22,
		PlagueMortar = 23,
		BearDen = 24,
		GustCannon = 25,
		WardenShrine = 26,
		IronCleric = 27,
		SiegeBallista = 28,
		ChainLightning = 29,
		FortressCannon = 30,
		DragonForge = 31,
		VoidObelisk = 32,
		PlagueCauldron = 33,
		BarracksFortress = 34,
		CitadelAura = 35,
	}

	/// <summary>C# mirror of Types.BuildingBaseMesh from res://scripts/types.gd. Integer values are identical.</summary>
	public enum BuildingBaseMesh
	{
		StoneRound = 0,
		StoneSquare = 1,
		WoodRound = 2,
		RuinsBase = 3,
	}

	/// <summary>C# mirror of Types.BuildingTopMesh from res://scripts/types.gd. Integer values are identical.</summary>
	public enum BuildingTopMesh
	{
		RoofCone = 0,
		RoofFlat = 1,
		GlassDome = 2,
		FireBowl = 3,
		PoisonTank = 4,
		BallistaFrame = 5,
		Embrasure = 6,
	}

	/// <summary>C# mirror of Types.ArnulfState from res://scripts/types.gd. Integer values are identical.</summary>
	public enum ArnulfState
	{
		Idle = 0,
		Patrol = 1,
		Chase = 2,
		Attack = 3,
		Downed = 4,
		Recovering = 5,
	}

	/// <summary>C# mirror of Types.ResourceType from res://scripts/types.gd. Integer values are identical.</summary>
	public enum ResourceType
	{
		Gold = 0,
		BuildingMaterial = 1,
		ResearchMaterial = 2,
	}

	/// <summary>C# mirror of Types.EnemyType from res://scripts/types.gd. Integer values are identical.</summary>
	public enum EnemyType
	{
		OrcGrunt = 0,
		OrcBrute = 1,
		GoblinFirebug = 2,
		PlagueZombie = 3,
		OrcArcher = 4,
		BatSwarm = 5,
		OrcSkirmisher = 6,
		OrcRatling = 7,
		GoblinRunts = 8,
		Hound = 9,
		OrcRaider = 10,
		OrcMarksman = 11,
		WarShaman = 12,
		PlagueShaman = 13,
		TotemCarrier = 14,
		HarpyScout = 15,
		OrcShieldbearer = 16,
		OrcBerserker = 17,
		OrcSaboteur = 18,
		Hexbreaker = 19,
		WyvernRider = 20,
		BroodCarrier = 21,
		Troll = 22,
		IroncladCrusher = 23,
		OrcOgre = 24,
		WarBoar = 25,
		OrcSkythrower = 26,
		WarlordsGuard = 27,
		OrcishSpirit = 28,
		PlagueHerald = 29,
	}

	/// <summary>C# mirror of Types.AllyClass from res://scripts/types.gd. Integer values are identical.</summary>
	public enum AllyClass
	{
		Melee = 0,
		Ranged = 1,
		Support = 2,
	}

	/// <summary>C# mirror of Types.WeaponSlot from res://scripts/types.gd. Integer values are identical.</summary>
	public enum WeaponSlot
	{
		Crossbow = 0,
		RapidMissile = 1,
	}

	/// <summary>C# mirror of Types.TargetPriority from res://scripts/types.gd. Integer values are identical.</summary>
	public enum TargetPriority
	{
		Closest = 0,
		HighestHp = 1,
		FlyingFirst = 2,
		LowestHp = 3,
	}

	/// <summary>C# mirror of Types.AllyRole from res://scripts/types.gd. Integer values are identical.</summary>
	public enum AllyRole
	{
		MeleeFrontline = 0,
		RangedSupport = 1,
		AntiAir = 2,
		SpellSupport = 3,
	}

	/// <summary>C# mirror of Types.AllyCombatRole from res://scripts/types.gd. Integer values are identical.</summary>
	public enum AllyCombatRole
	{
		Melee = 0,
		Ranged = 1,
		Healer = 2,
		Bomber = 3,
		Aura = 4,
	}

	/// <summary>C# mirror of Types.StrategyProfile from res://scripts/types.gd. Integer values are identical.</summary>
	public enum StrategyProfile
	{
		Balanced = 0,
		AllyHeavyPhysical = 1,
		AntiAirFocus = 2,
		SpellFocus = 3,
		BuildingFocus = 4,
	}

	/// <summary>C# mirror of Types.TerrainType from res://scripts/types.gd. Integer values are identical.</summary>
	public enum TerrainType
	{
		Grassland = 0,
		Forest = 1,
		Swamp = 2,
		Ruins = 3,
		Tundra = 4,
	}

	/// <summary>C# mirror of Types.TerrainEffect from res://scripts/types.gd. Integer values are identical.</summary>
	public enum TerrainEffect
	{
		None = 0,
		Slow = 1,
		Impassable = 2,
	}

	/// <summary>C# mirror of Types.HubRole from res://scripts/types.gd. Integer values are identical.</summary>
	public enum HubRole
	{
		Shop = 0,
		Research = 1,
		Enchant = 2,
		Mercenary = 3,
		Ally = 4,
		FlavorOnly = 5,
	}

	/// <summary>C# mirror of Types.DayAdvanceReason from res://scripts/types.gd. Integer values are identical.</summary>
	public enum DayAdvanceReason
	{
		MissionCompleted = 0,
		AchievementEarned = 1,
		MajorStoryEvent = 2,
	}

	/// <summary>C# mirror of Types.BuildingSizeClass from res://scripts/types.gd. Integer values are identical.</summary>
	public enum BuildingSizeClass
	{
		SingleSlot = 0,
		DoubleWide = 1,
		TripleCluster = 2,
		Small = 3,
		Medium = 4,
		Large = 5,
	}

	/// <summary>C# mirror of Types.UnitSize from res://scripts/types.gd. Integer values are identical.</summary>
	public enum UnitSize
	{
		Small = 0,
		Medium = 1,
		Large = 2,
		Huge = 3,
	}

	/// <summary>C# mirror of Types.AllyAiMode from res://scripts/types.gd. Integer values are identical.</summary>
	public enum AllyAiMode
	{
		Default = 0,
		HoldPosition = 1,
		Aggressive = 2,
		Escort = 3,
		FollowLeader = 4,
	}

	/// <summary>C# mirror of Types.SummonLifetimeType from res://scripts/types.gd. Integer values are identical.</summary>
	public enum SummonLifetimeType
	{
		None = 0,
		Mortal = 1,
		Recurring = 2,
		Immortal = 3,
	}

	/// <summary>C# mirror of Types.AuraModifierKind from res://scripts/types.gd. Integer values are identical.</summary>
	public enum AuraModifierKind
	{
		AddFlat = 0,
		AddPercent = 1,
		Multiply = 2,
	}

	/// <summary>C# mirror of Types.AuraModifierOp from res://scripts/types.gd. Integer values are identical.</summary>
	public enum AuraModifierOp
	{
		Add = 0,
		Multiply = 1,
	}

	/// <summary>C# mirror of Types.AuraCategory from res://scripts/types.gd. Integer values are identical.</summary>
	public enum AuraCategory
	{
		Offense = 0,
		Defense = 1,
		Utility = 2,
		Control = 3,
	}

	/// <summary>C# mirror of Types.AuraStat from res://scripts/types.gd. Integer values are identical.</summary>
	public enum AuraStat
	{
		Damage = 0,
		FireRate = 1,
		Range = 2,
		Armor = 3,
		MagicResist = 4,
		MoveSpeed = 5,
	}

	/// <summary>C# mirror of Types.EnemyBodyType from res://scripts/types.gd. Integer values are identical.</summary>
	public enum EnemyBodyType
	{
		Ground = 0,
		Flying = 1,
		Hover = 2,
		Boss = 3,
		Structure = 4,
		LargeGround = 5,
		Siege = 6,
		Ethereal = 7,
	}

	/// <summary>C# mirror of Types.MissionBalanceStatus from res://scripts/types.gd. Integer values are identical.</summary>
	public enum MissionBalanceStatus
	{
		Unset = 0,
		Draft = 1,
		Review = 2,
		Shipped = 3,
	}

	/// <summary>C# mirror of Types.GraphicsQuality from res://scripts/types.gd. Integer values are identical.</summary>
	public enum GraphicsQuality
	{
		Low = 0,
		Medium = 1,
		High = 2,
		Custom = 3,
	}

	/// <summary>C# mirror of Types.ChronicleRewardType from res://scripts/types.gd.</summary>
	public enum ChronicleRewardType
	{
		Perk = 0,
		Cosmetic = 1,
		Title = 2,
	}

	/// <summary>C# mirror of Types.ChroniclePerkEffectType from res://scripts/types.gd.</summary>
	public enum ChroniclePerkEffectType
	{
		StartingGold = 0,
		StartingMana = 1,
		SellRefundPct = 2,
		ResearchCostPct = 3,
		GoldPerKillPct = 4,
		BuildingMaterialStart = 5,
		EnchantingCostPct = 6,
		WaveRewardGold = 7,
		XpGainPct = 8,
		CosmeticSkin = 9,
	}

	/// <summary>C# mirror of Types.DifficultyTier from res://scripts/types.gd.</summary>
	public enum DifficultyTier
	{
		Normal = 0,
		Veteran = 1,
		Nightmare = 2,
	}
}
