extends GutTest

const DIR := "user://test_saves"
const PATH := DIR + "/save.json"


func before_each() -> void:
	_remove_dir(DIR)
	DirAccess.make_dir_recursive_absolute(DIR)


func after_all() -> void:
	_remove_dir(DIR)


func _remove_dir(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + "/" + file)
	DirAccess.remove_absolute(dir)


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func test_missing_file_returns_defaults() -> void:
	var store := SaveStore.new(PATH, 1)
	assert_eq(store.load_data({"level": 1}), {"level": 1})


func test_round_trip() -> void:
	assert_eq(SaveStore.new(PATH, 1).save_data({"level": 4, "name": "Ñandú"}), OK)
	var loaded := SaveStore.new(PATH, 1).load_data({"level": 1, "name": ""})
	assert_eq(loaded, {"level": 4, "name": "Ñandú"})


func test_int_defaults_come_back_as_int() -> void:
	SaveStore.new(PATH, 1).save_data({"level": 4})
	var loaded := SaveStore.new(PATH, 1).load_data({"level": 1})
	assert_eq(typeof(loaded.level), TYPE_INT)


func test_new_default_keys_are_filled() -> void:
	SaveStore.new(PATH, 1).save_data({"level": 2})
	var loaded := SaveStore.new(PATH, 1).load_data({"level": 1, "sound": true})
	assert_eq(loaded, {"level": 2, "sound": true})


func test_unknown_keys_are_kept() -> void:
	SaveStore.new(PATH, 1).save_data({"level": 2, "extra": "x"})
	assert_eq(SaveStore.new(PATH, 1).load_data({"level": 1}), {"level": 2, "extra": "x"})


func test_defaults_are_not_shared() -> void:
	var defaults := {"stars": [0, 0]}
	var loaded := SaveStore.new(PATH, 1).load_data(defaults)
	loaded.stars.append(3)
	assert_eq(defaults, {"stars": [0, 0]})


func test_garbage_is_backed_up() -> void:
	_write(PATH, "not json{")
	assert_eq(SaveStore.new(PATH, 1).load_data({"level": 1}), {"level": 1})
	assert_eq(_read(PATH + ".broken"), "not json{")
	assert_false(FileAccess.file_exists(PATH))


func test_wrong_shape_is_backed_up() -> void:
	for text in [
		"[1,2]", '{"version": 1, "data": [1]}', '{"version": "1", "data": {}}', '{"data": {}}'
	]:
		_write(PATH, text)
		assert_eq(SaveStore.new(PATH, 1).load_data({"level": 1}), {"level": 1}, text)
		assert_eq(_read(PATH + ".broken"), text, text)


func test_newer_version_is_backed_up() -> void:
	_write(PATH, '{"version": 3, "data": {"level": 9}}')
	assert_eq(SaveStore.new(PATH, 2).load_data({"level": 1}), {"level": 1})
	assert_true(FileAccess.file_exists(PATH + ".broken"))


func test_migrations_run_in_order() -> void:
	_write(PATH, '{"version": 1, "data": {"lvl": 5}}')
	var migrations := {
		1: func(d: Dictionary) -> Dictionary: return {"level": d.lvl},
		2:
		func(d: Dictionary) -> Dictionary:
			d.stars = 0
			return d,
	}
	var loaded := SaveStore.new(PATH, 3, migrations).load_data({"level": 1, "stars": 9})
	assert_eq(loaded, {"level": 5, "stars": 0})


func test_missing_migration_is_backed_up() -> void:
	_write(PATH, '{"version": 1, "data": {"lvl": 5}}')
	var migrations := {2: func(d: Dictionary) -> Dictionary: return d}
	assert_eq(SaveStore.new(PATH, 3, migrations).load_data({"level": 1}), {"level": 1})
	assert_true(FileAccess.file_exists(PATH + ".broken"))


func test_leftover_tmp_is_ignored() -> void:
	SaveStore.new(PATH, 1).save_data({"level": 7})
	_write(PATH + ".tmp", "half a fi")
	assert_eq(SaveStore.new(PATH, 1).load_data({"level": 1}), {"level": 7})


func test_save_replaces_atomically() -> void:
	var store := SaveStore.new(PATH, 1)
	assert_eq(store.save_data({"level": 1}), OK)
	assert_eq(store.save_data({"level": 2}), OK)
	assert_false(FileAccess.file_exists(PATH + ".tmp"))
	assert_eq(store.load_data({"level": 0}), {"level": 2})


func test_save_creates_the_directory() -> void:
	var path := DIR + "/nested/save.json"
	assert_eq(SaveStore.new(path, 1).save_data({"level": 3}), OK)
	assert_eq(SaveStore.new(path, 1).load_data({"level": 0}), {"level": 3})
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(DIR + "/nested")
