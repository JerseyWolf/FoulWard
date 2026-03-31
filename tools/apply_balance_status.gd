@tool
extends EditorScript
class_name BalanceStatusApplier
## Applies [code]tools/output/simbot_balance_status.csv[/code] to [code]BuildingData.balance_status[/code]
## on all [code]res://resources/building_data/*.tres[/code]. Run from **Project → Tools** or attach to EditorPlugin.
##
## Requires CSV from [code]tools/simbot_balance_report.py[/code] ([code]--out-csv[/code]).

const DEFAULT_CSV: String = "res://tools/output/simbot_balance_status.csv"


func _run() -> void:
	apply_from_csv(DEFAULT_CSV)


func apply_from_csv(csv_path: String) -> void:
	var file: FileAccess = FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		push_error("BalanceStatusApplier: cannot open %s" % csv_path)
		return
	var _header: String = file.get_line()
	var mapping: Dictionary = {}
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts: PackedStringArray = line.split(",")
		if parts.size() < 2:
			continue
		var bid: String = parts[0].strip_edges()
		var status: String = parts[1].strip_edges()
		if not bid.is_empty():
			mapping[bid] = status
	file.close()

	var dir: DirAccess = DirAccess.open("res://resources/building_data/")
	if dir == null:
		push_error("BalanceStatusApplier: cannot open res://resources/building_data/")
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	var n: int = 0
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".tres"):
			var res_path: String = "res://resources/building_data/%s" % fname
			var bd: BuildingData = load(res_path) as BuildingData
			if bd != null and mapping.has(bd.building_id):
				bd.balance_status = str(mapping[bd.building_id])
				var err: Error = ResourceSaver.save(bd, res_path)
				if err == OK:
					n += 1
				else:
					push_warning("BalanceStatusApplier: save failed %s err=%d" % [res_path, err])
		fname = dir.get_next()
	dir.list_dir_end()
	print("BalanceStatusApplier: updated %d resources from %s" % [n, csv_path])
