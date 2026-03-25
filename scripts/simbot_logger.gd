## simbot_logger.gd
## PRE_GENERATION_VERIFICATION: Mentally ran the required checklist for this file
## (CSV IO helper only, no scene access, no game logic coupling).
##
## Writes SimBot balance logs to CSV under user://.
## SOURCE: CSV header/append pattern adapted from Godot 4 FileAccess/DirAccess docs.
##         https://docs.godotengine.org
extends Node
class_name SimBotLogger

const LOG_DIR: String = "user://simbot_logs"
const DEFAULT_FILENAME: String = "simbot_balance_log.csv"

static func get_default_path() -> String:
	return LOG_DIR + "/" + DEFAULT_FILENAME

static func _ensure_dir_exists() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	if not dir.dir_exists("simbot_logs"):
		dir.make_dir_recursive("simbot_logs")

static func write_header_if_needed(file_path: String, columns: Array[String]) -> void:
	_ensure_dir_exists()
	if FileAccess.file_exists(file_path):
		return

	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return

	file.store_line(",".join(columns))
	file.flush()
	file.close()

static func append_row(file_path: String, columns: Array[String], row: Dictionary) -> void:
	_ensure_dir_exists()

	# Godot 4.x: FileAccess.APPEND is not available in this build.
	# Implement append by opening READ_WRITE and seeking to end.
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ_WRITE)
	if file == null:
		return
	file.seek_end(0)

	var values: Array[String] = []
	values.resize(columns.size())

	for i: int in range(columns.size()):
		var col: String = columns[i]
		if row.has(col):
			values[i] = str(row[col])
		else:
			values[i] = "0"

	file.store_line(",".join(values))
	file.flush()
	file.close()

