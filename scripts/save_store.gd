class_name SaveStore
extends RefCounted
const PATH := "user://deep_core.json"
static func write(data: Dictionary) -> bool:
	data["version"] = 1
	var file := FileAccess.open(PATH+".tmp",FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if FileAccess.file_exists(PATH):
		DirAccess.copy_absolute(PATH,PATH+".bak")
	return DirAccess.rename_absolute(PATH+".tmp",PATH)==OK
static func read_save() -> Dictionary:
	for path in [PATH,PATH+".bak"]:
		if not FileAccess.file_exists(path): continue
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary and data.get("version",0)==1: return data
	return {}
