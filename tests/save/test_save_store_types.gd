extends GutTest
## JSON loses types; SaveStore restores them from the shape of the defaults.

const DIR := "user://test_saves_types"
const PATH := DIR + "/save.json"


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	DirAccess.remove_absolute(PATH)


func after_all() -> void:
	DirAccess.remove_absolute(PATH)
	DirAccess.remove_absolute(DIR)


func _round_trip(data: Dictionary, defaults: Dictionary) -> Dictionary:
	SaveStore.new(PATH, 1).save_data(data)
	return SaveStore.new(PATH, 1).load_data(defaults)


func test_ints_in_arrays_come_back_as_int() -> void:
	var loaded := _round_trip({"stars": [1, 2, 3]}, {"stars": [0]})
	assert_eq(loaded.stars, [1, 2, 3])
	for star: Variant in loaded.stars:
		assert_eq(typeof(star), TYPE_INT)


func test_typed_array_default_is_honored() -> void:
	var stars: Array[int] = []
	var loaded := _round_trip({"stars": [1, 2]}, {"stars": stars})
	assert_true(loaded.stars.is_typed())
	assert_eq(loaded.stars.get_typed_builtin(), TYPE_INT)
	var back: Array[int] = loaded.stars
	assert_eq(back, [1, 2])


func test_int_keys_come_back_as_int() -> void:
	var loaded := _round_trip({"best": {1: 30, 2: 40}}, {"best": {1: 0}})
	assert_eq(loaded.best, {1: 30, 2: 40})
	for key: Variant in loaded.best:
		assert_eq(typeof(key), TYPE_INT)
		assert_eq(typeof(loaded.best[key]), TYPE_INT)


func test_nested_records_are_coerced_and_filled() -> void:
	var loaded := _round_trip(
		{"settings": {"volume": 7}}, {"settings": {"volume": 5, "lang": "es"}}
	)
	assert_eq(loaded.settings, {"volume": 7, "lang": "es"})
	assert_eq(typeof(loaded.settings.volume), TYPE_INT)


func test_fractional_value_with_int_default_stays_float() -> void:
	assert_eq(_round_trip({"speed": 2.5}, {"speed": 1}).speed, 2.5)
