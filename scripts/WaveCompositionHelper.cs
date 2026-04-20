// CREDIT: RefCounted C# helper callable from GDScript via Godot's marshaller
// Technique: partial class : RefCounted with Godot.Collections public API and
//            System.Collections.Generic for internal processing.
//            Godot marshaller maps PascalCase C# method names to snake_case GDScript calls.
// Reference: Godot 4.4 C# collections interop docs
//   https://docs.godotengine.org/en/4.4/tutorials/scripting/c_sharp/c_sharp_collections.html
// Reference: Godot 4 cross-language scripting
//   https://docs.godotengine.org/en/stable/tutorials/scripting/cross_language_scripting.html
// Extracted roster loop from wave composition (historical refactor; see git blame).
// Used in: WaveCompositionHelper.BuildRoster(), called from wave_manager.gd spawn_wave()

using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

/// <summary>
/// Builds a per-type enemy count roster from <see cref="FactionData"/> roster weights (Prompt 9 allocation).
/// Regular waves use <c>WaveComposer</c>; this helper preserves the historical weighted allocation for tooling and parity.
/// </summary>
[GlobalClass]
public partial class WaveCompositionHelper : RefCounted
{
	/// <summary>
	/// Builds roster entries: each dictionary has <c>enemy_type</c> (int) and <c>count</c> (int).
	/// Matches legacy <c>wave_manager.gd</c> <c>_allocate_counts_for_roster</c> + faction entry filtering.
	/// </summary>
	/// <param name="factionData">FactionData resource (GDScript); must expose <c>get_entries_for_wave</c> and <c>get_effective_weight_for_wave</c>.</param>
	public Godot.Collections.Array<Godot.Collections.Dictionary> BuildRoster(
		Resource factionData,
		int waveNumber,
		int totalEnemyCount)
	{
		var result = new Godot.Collections.Array<Godot.Collections.Dictionary>();
		if (factionData == null || totalEnemyCount <= 0)
		{
			return result;
		}

		var entriesVar = factionData.Call("get_entries_for_wave", waveNumber);
		var entries = entriesVar.AsGodotArray();
		if (entries.Count == 0)
		{
			return result;
		}

		var weights = new List<float>(entries.Count);
		var enemyTypeInts = new List<int>(entries.Count);

		foreach (Variant v in entries)
		{
			var entry = v.As<Resource>();
			int enemyTypeInt = entry.Get("enemy_type").AsInt32();
			enemyTypeInts.Add(enemyTypeInt);
			float w = factionData.Call("get_effective_weight_for_wave", entry, waveNumber).AsSingle();
			weights.Add(w);
		}

		int[] counts = AllocateCountsForRoster(weights, totalEnemyCount);
		var merged = new Dictionary<int, int>();
		for (int i = 0; i < counts.Length; i++)
		{
			int c = counts[i];
			if (c <= 0)
			{
				continue;
			}

			var typed = (FoulWardTypes.EnemyType)enemyTypeInts[i];
			int et = (int)typed;
			merged.TryGetValue(et, out int prev);
			merged[et] = prev + c;
		}

		foreach (KeyValuePair<int, int> kv in merged)
		{
			var row = new Godot.Collections.Dictionary
			{
				["enemy_type"] = kv.Key,
				["count"] = kv.Value,
			};
			result.Add(row);
		}

		return result;
	}

	/// <summary>GDScript-visible name for <see cref="BuildRoster"/> (explicit snake_case; marshaller unreliable via <c>Object.call</c>).</summary>
	public Godot.Collections.Array<Godot.Collections.Dictionary> build_roster(
		Resource factionData,
		int waveNumber,
		int totalEnemyCount)
		=> BuildRoster(factionData, waveNumber, totalEnemyCount);

	/// <summary>Largest-remainder proportional allocation — mirrors legacy GDScript <c>_allocate_counts_for_roster</c>.</summary>
	private static int[] AllocateCountsForRoster(IReadOnlyList<float> weights, int totalEnemies)
	{
		int n = weights.Count;
		if (n == 0)
		{
			return Array.Empty<int>();
		}

		double totalWeight = 0.0;
		for (int i = 0; i < n; i++)
		{
			totalWeight += weights[i];
		}

		if (totalWeight <= 0.0)
		{
			int equal = totalEnemies / n;
			int remainder = totalEnemies % n;
			var countsEq = new int[n];
			for (int i = 0; i < n; i++)
			{
				countsEq[i] = equal + (i < remainder ? 1 : 0);
			}

			return countsEq;
		}

		var floatCounts = new double[n];
		var countsInt = new int[n];
		int runningTotal = 0;

		for (int i = 0; i < n; i++)
		{
			double share = weights[i] / totalWeight;
			double ideal = totalEnemies * share;
			floatCounts[i] = ideal;
			int cInt = (int)Math.Floor(ideal);
			countsInt[i] = cInt;
			runningTotal += cInt;
		}

		int remaining = totalEnemies - runningTotal;
		if (remaining > 0)
		{
			var indices = Enumerable.Range(0, n).ToList();
			indices.Sort((a, b) =>
			{
				double fracA = floatCounts[a] - countsInt[a];
				double fracB = floatCounts[b] - countsInt[b];
				return fracB.CompareTo(fracA);
			});

			int give = Math.Min(remaining, indices.Count);
			for (int k = 0; k < give; k++)
			{
				countsInt[indices[k]] += 1;
			}
		}

		return countsInt;
	}
}
