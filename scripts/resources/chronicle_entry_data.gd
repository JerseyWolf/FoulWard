## ChronicleEntryData — one achievement / chronicle entry definition.
class_name ChronicleEntryData
extends Resource

@export var entry_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_id: String = ""
## SignalBus signal name to listen for (e.g. [code]enemy_killed[/code]).
@export var tracking_signal: String = ""
## Filter token for ChronicleManager (not a JSON key from signal payloads): [code]flying_only[/code], [code]unique_bosses[/code], or empty.
@export var tracking_field: String = ""
@export var target_count: int = 1
@export var reward_type: Types.ChronicleRewardType = Types.ChronicleRewardType.PERK
@export var reward_id: String = ""
