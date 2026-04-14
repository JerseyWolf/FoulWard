// CREDIT: Typed save payload as C# RefCounted, callable from GDScript
// Technique: partial class : RefCounted for GDScript-accessible typed data containers.
//            System.Text.Json with JsonPropertyName attributes for format-compatible serialization.
// Reference: Godot 4.4 FileAccess C# docs
//   https://docs.godotengine.org/en/4.4/classes/class_fileaccess.html
// Reference: System.Text.Json overview (Microsoft)
//   https://learn.microsoft.com/en-us/dotnet/standard/serialization/system-text-json/overview
// Used in: SavePayload.FromGodotDict(), ToGodotDict(), Serialize(), Deserialize()

using System;
using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;
using Godot;

/// <summary>
/// Typed mirror of SaveManager JSON payload keys (<c>_build_save_payload</c> / <c>_apply_save_payload</c>).
/// Optional bridge for GDScript dictionaries and System.Text.Json without changing the GDScript save pipeline.
/// </summary>
public partial class SavePayload : RefCounted
{
	private static readonly JsonSerializerOptions JsonOptions = CreateJsonOptions();

	[System.Text.Json.Serialization.JsonPropertyName("version")]
	[JsonConverter(typeof(VersionStringConverter))]
	public string Version { get; set; } = "";

	[System.Text.Json.Serialization.JsonPropertyName("attempt_id")]
	public string AttemptId { get; set; } = "";

	[System.Text.Json.Serialization.JsonPropertyName("campaign")]
	[JsonConverter(typeof(GodotDictionaryConverter))]
	public Godot.Collections.Dictionary Campaign { get; set; } = new();

	[System.Text.Json.Serialization.JsonPropertyName("game")]
	[JsonConverter(typeof(GodotDictionaryConverter))]
	public Godot.Collections.Dictionary Game { get; set; } = new();

	[System.Text.Json.Serialization.JsonPropertyName("relationship")]
	[JsonConverter(typeof(GodotDictionaryConverter))]
	public Godot.Collections.Dictionary Relationship { get; set; } = new();

	[System.Text.Json.Serialization.JsonPropertyName("research")]
	[JsonConverter(typeof(GodotDictionaryConverter))]
	public Godot.Collections.Dictionary Research { get; set; } = new();

	[System.Text.Json.Serialization.JsonPropertyName("shop")]
	[JsonConverter(typeof(GodotDictionaryConverter))]
	public Godot.Collections.Dictionary Shop { get; set; } = new();

	[System.Text.Json.Serialization.JsonPropertyName("enchantments")]
	[JsonConverter(typeof(GodotDictionaryConverter))]
	public Godot.Collections.Dictionary Enchantments { get; set; } = new();

	/// <summary>Builds a <see cref="SavePayload"/> from a Godot dictionary (e.g. SaveManager payload).</summary>
	public static SavePayload FromGodotDict(Godot.Collections.Dictionary d)
	{
		var p = new SavePayload();
		if (d.TryGetValue("version", out Variant ver))
		{
			p.Version = VariantToVersionString(ver);
		}
		if (d.TryGetValue("attempt_id", out Variant aid))
		{
			p.AttemptId = aid.AsString();
		}
		p.Campaign = GetNestedDict(d, "campaign");
		p.Game = GetNestedDict(d, "game");
		p.Relationship = GetNestedDict(d, "relationship");
		p.Research = GetNestedDict(d, "research");
		p.Shop = GetNestedDict(d, "shop");
		p.Enchantments = GetNestedDict(d, "enchantments");
		return p;
	}

	/// <summary>Returns a Godot dictionary with the same keys as <c>_build_save_payload()</c>.</summary>
	public Godot.Collections.Dictionary ToGodotDict()
	{
		var d = new Godot.Collections.Dictionary();
		d["version"] = VersionStringToVariantForPayload(Version);
		d["attempt_id"] = AttemptId;
		d["campaign"] = Campaign;
		d["game"] = Game;
		d["relationship"] = Relationship;
		d["research"] = Research;
		d["shop"] = Shop;
		d["enchantments"] = Enchantments;
		return d;
	}

	/// <summary>Serializes using System.Text.Json (snake_case property names; <c>version</c> as JSON number when parseable).</summary>
	public static string Serialize(SavePayload p)
	{
		return JsonSerializer.Serialize(p, JsonOptions);
	}

	/// <summary>Deserializes JSON; returns <c>null</c> if input is invalid or malformed.</summary>
	public static SavePayload? Deserialize(string json)
	{
		if (string.IsNullOrWhiteSpace(json))
		{
			return null;
		}
		try
		{
			return JsonSerializer.Deserialize<SavePayload>(json, JsonOptions);
		}
		catch (JsonException)
		{
			return null;
		}
	}

	private static JsonSerializerOptions CreateJsonOptions()
	{
		var o = new JsonSerializerOptions
		{
			WriteIndented = false,
			PropertyNamingPolicy = null,
		};
		return o;
	}

	private static Godot.Collections.Dictionary GetNestedDict(Godot.Collections.Dictionary d, string key)
	{
		if (!d.TryGetValue(key, out Variant v))
		{
			return new Godot.Collections.Dictionary();
		}
		if (v.VariantType != Variant.Type.Dictionary)
		{
			return new Godot.Collections.Dictionary();
		}
		return v.AsGodotDictionary();
	}

	private static string VariantToVersionString(Variant v)
	{
		return v.VariantType switch
		{
			Variant.Type.Int => v.AsInt32().ToString(CultureInfo.InvariantCulture),
			Variant.Type.Float => ((int)v.AsDouble()).ToString(CultureInfo.InvariantCulture),
			Variant.Type.String => v.AsString(),
			_ => "",
		};
	}

	/// <summary>Matches <c>build_save_payload</c>: numeric <c>version</c> when possible.</summary>
	private static Variant VersionStringToVariantForPayload(string version)
	{
		if (string.IsNullOrEmpty(version))
		{
			return 1;
		}
		if (int.TryParse(version, NumberStyles.Integer, CultureInfo.InvariantCulture, out int i))
		{
			return i;
		}
		return version;
	}

	private sealed class VersionStringConverter : JsonConverter<string>
	{
		public override string Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
		{
			return reader.TokenType switch
			{
				JsonTokenType.String => reader.GetString() ?? "",
				JsonTokenType.Number => reader.TryGetInt32(out int i)
					? i.ToString(CultureInfo.InvariantCulture)
					: reader.GetDouble().ToString(CultureInfo.InvariantCulture),
				_ => "",
			};
		}

		public override void Write(Utf8JsonWriter writer, string value, JsonSerializerOptions options)
		{
			if (string.IsNullOrEmpty(value))
			{
				writer.WriteNumberValue(1);
				return;
			}
			if (int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out int i))
			{
				writer.WriteNumberValue(i);
				return;
			}
			if (double.TryParse(value, NumberStyles.Float, CultureInfo.InvariantCulture, out double d))
			{
				writer.WriteNumberValue(d);
				return;
			}
			writer.WriteStringValue(value);
		}
	}

	private sealed class GodotDictionaryConverter : JsonConverter<Godot.Collections.Dictionary>
	{
		public override Godot.Collections.Dictionary Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
		{
			using JsonDocument doc = JsonDocument.ParseValue(ref reader);
			return JsonElementToGodotDictionary(doc.RootElement);
		}

		public override void Write(Utf8JsonWriter writer, Godot.Collections.Dictionary value, JsonSerializerOptions options)
		{
			writer.WriteStartObject();
			foreach (Variant key in value.Keys)
			{
				writer.WritePropertyName(key.AsString());
				WriteVariant(writer, value[key]);
			}
			writer.WriteEndObject();
		}
	}

	private static Godot.Collections.Dictionary JsonElementToGodotDictionary(JsonElement el)
	{
		var d = new Godot.Collections.Dictionary();
		foreach (JsonProperty prop in el.EnumerateObject())
		{
			d[prop.Name] = JsonElementToVariant(prop.Value);
		}
		return d;
	}

	private static Variant JsonElementToVariant(JsonElement el)
	{
		switch (el.ValueKind)
		{
			case JsonValueKind.Object:
				return JsonElementToGodotDictionary(el);
			case JsonValueKind.Array:
			{
				var arr = new Godot.Collections.Array();
				foreach (JsonElement item in el.EnumerateArray())
				{
					arr.Add(JsonElementToVariant(item));
				}
				return arr;
			}
			case JsonValueKind.String:
				return el.GetString() ?? "";
			case JsonValueKind.Number:
				if (el.TryGetInt32(out int i))
				{
					return i;
				}
				return el.GetDouble();
			case JsonValueKind.True:
				return true;
			case JsonValueKind.False:
				return false;
			case JsonValueKind.Null:
			case JsonValueKind.Undefined:
				return default;
			default:
				return "";
		}
	}

	private static void WriteVariant(Utf8JsonWriter writer, Variant v)
	{
		switch (v.VariantType)
		{
			case Variant.Type.Nil:
				writer.WriteNullValue();
				break;
			case Variant.Type.Bool:
				writer.WriteBooleanValue(v.AsBool());
				break;
			case Variant.Type.Int:
				writer.WriteNumberValue(v.AsInt32());
				break;
			case Variant.Type.Float:
				writer.WriteNumberValue(v.AsDouble());
				break;
			case Variant.Type.String:
				writer.WriteStringValue(v.AsString());
				break;
			case Variant.Type.Array:
				writer.WriteStartArray();
				foreach (Variant item in v.AsGodotArray())
				{
					WriteVariant(writer, item);
				}
				writer.WriteEndArray();
				break;
			case Variant.Type.Dictionary:
				WriteGodotDictionary(writer, v.AsGodotDictionary());
				break;
			default:
				writer.WriteStringValue(v.AsString());
				break;
		}
	}

	private static void WriteGodotDictionary(Utf8JsonWriter writer, Godot.Collections.Dictionary dict)
	{
		writer.WriteStartObject();
		foreach (Variant key in dict.Keys)
		{
			writer.WritePropertyName(key.AsString());
			WriteVariant(writer, dict[key]);
		}
		writer.WriteEndObject();
	}
}
