class_name SaveStore
extends RefCounted
## A small versioned save file, stored as JSON: {"version": <int>, "data": {...}}.
##
## Tolerant by design:
## - old saves are upgraded with `migrations` (from_version -> Callable(data) -> data for from_version + 1);
## - broken saves, and saves from a newer version of the game, are moved to `<path>.broken`, never deleted;
## - a crash while saving leaves the previous save intact (it writes `<path>.tmp`, then renames).
## Numbers come back as float from JSON; a value whose default is an int is returned as an int.

var _path: String
var _version: int
var _migrations: Dictionary


func _init(path: String, version: int, migrations: Dictionary = {}) -> void:
	_path = path
	_version = version
	_migrations = migrations


## Returns the saved data laid over a copy of `defaults`. Keys missing from the save come from
## `defaults`; keys not in `defaults` are kept.
func load_data(defaults: Dictionary) -> Dictionary:
	var result := defaults.duplicate(true)
	if not FileAccess.file_exists(_path):
		return result
	var data: Variant = _read_current_data()
	if data == null:
		_back_up()
		return result
	for key: Variant in data:
		var value: Variant = data[key]
		if typeof(value) == TYPE_FLOAT and typeof(defaults.get(key)) == TYPE_INT:
			value = int(value)
		result[key] = value
	return result


func save_data(data: Dictionary) -> Error:
	var dir := _path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		var made := DirAccess.make_dir_recursive_absolute(dir)
		if made != OK:
			return made
	var tmp := _path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var written := file.store_string(JSON.stringify({"version": _version, "data": data}))
	file.close()
	if not written:
		return ERR_FILE_CANT_WRITE
	return DirAccess.rename_absolute(tmp, _path)


## The save's data upgraded to the current version, or null if the file can't be used.
func _read_current_data() -> Variant:
	var parsed: Variant = _parse_file()
	if parsed == null:
		return null
	var version := int(parsed.version)
	if version != parsed.version or version > _version:
		return null
	return _migrate(parsed.data, version)


## {"version": number, "data": Dictionary} from the file, or null if it isn't that shape.
func _parse_file() -> Variant:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(_path)) != OK:
		return null
	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	if typeof(parsed.get("version")) not in [TYPE_INT, TYPE_FLOAT]:
		return null
	if typeof(parsed.get("data")) != TYPE_DICTIONARY:
		return null
	return parsed


func _migrate(data: Variant, from_version: int) -> Variant:
	var version := from_version
	while version < _version:
		if not _migrations.has(version):
			return null
		data = (_migrations[version] as Callable).call(data)
		if typeof(data) != TYPE_DICTIONARY:
			return null
		version += 1
	return data


func _back_up() -> void:
	var broken := _path + ".broken"
	if FileAccess.file_exists(broken):
		DirAccess.remove_absolute(broken)
	DirAccess.rename_absolute(_path, broken)
