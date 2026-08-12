class_name FileUtils
extends RefCounted

static func read_json(path: String, default = null):
	if not FileAccess.file_exists(path):
		return default
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return default
	return json.data


static func write_json(path: String, data) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


static func list_files_in_dir(path: String, extension: String = "") -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir():
			if extension.is_empty() or file_name.ends_with(extension):
				result.append(path + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return result
