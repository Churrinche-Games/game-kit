class_name SaveStore
extends RefCounted
## A small versioned save file, stored as JSON: {"version": <int>, "data": {...}}.
##
## Tolerant by design:
## - old saves are upgraded with `migrations` (from_version -> Callable(data) -> data for from_version + 1);
## - broken saves, and saves from a newer version of the game, are moved to `<path>.broken`, never deleted;
## - a crash while saving leaves the previous save intact (it writes `<path>.tmp`, then renames).
##
## JSON loses types, so loaded values are converted back to the shape of `defaults`, recursively:
## floats become ints where the default is an int (also inside arrays, using the first element or the
## typed-array type as the template), typed-array defaults come back typed, and string keys become int
## keys where the default dictionary has int keys. Store only JSON types (numbers, strings, bools,
## arrays, dictionaries); Vector2, Color and other engine types come back as strings.

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
	if not FileAccess.file_exists(_path):
		return defaults.duplicate(true)
	var data: Variant = _read_current_data()
	if data == null:
		_back_up()
		return defaults.duplicate(true)
	return _coerce_dictionary(data, defaults)


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


static func _coerce(value: Variant, template: Variant) -> Variant:
	match typeof(template):
		TYPE_INT:
			if typeof(value) == TYPE_FLOAT and value == floorf(value):
				return int(value)
		TYPE_ARRAY:
			if typeof(value) == TYPE_ARRAY:
				return _coerce_array(value, template)
		TYPE_DICTIONARY:
			if typeof(value) == TYPE_DICTIONARY:
				return _coerce_dictionary(value, template)
	return value


static func _coerce_array(value: Array, template: Array) -> Array:
	var element: Variant = null
	if not template.is_empty():
		element = template[0]
	elif template.is_typed() and template.get_typed_builtin() == TYPE_INT:
		element = 0
	var out := value.map(func(item: Variant) -> Variant: return _coerce(item, element))
	if not template.is_typed() or template.get_typed_builtin() == TYPE_OBJECT:
		return out
	var builtin := template.get_typed_builtin()
	if not out.all(func(item: Variant) -> bool: return typeof(item) == builtin):
		return out
	return Array(out, builtin, template.get_typed_class_name(), template.get_typed_script())


## A dictionary whose keys are all ints is a map (e.g. best score per level): every entry uses its
## first value as the template. Otherwise it is a record: missing keys are filled from the template.
static func _coerce_dictionary(value: Dictionary, template: Dictionary) -> Dictionary:
	var is_map := (
		not template.is_empty()
		and template.keys().all(func(k: Variant) -> bool: return typeof(k) == TYPE_INT)
	)
	var out: Dictionary = {} if is_map else template.duplicate(true)
	for key: Variant in value:
		var out_key: Variant = key
		if is_map and typeof(key) == TYPE_STRING and (key as String).is_valid_int():
			out_key = (key as String).to_int()
		var entry_template: Variant = template.values()[0] if is_map else template.get(out_key)
		out[out_key] = _coerce(value[key], entry_template)
	return out


func _back_up() -> void:
	var broken := _path + ".broken"
	if FileAccess.file_exists(broken):
		DirAccess.remove_absolute(broken)
	DirAccess.rename_absolute(_path, broken)
