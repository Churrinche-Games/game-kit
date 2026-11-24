extends GutTest

var _opened: Array[String] = []
var _old_opener: Callable


func before_each() -> void:
	_opened.clear()
	_old_opener = KitLinks.opener
	KitLinks.opener = func(url: String) -> void: _opened.append(url)


func after_each() -> void:
	KitLinks.opener = _old_opener


func _sheet() -> KitSheet:
	var host := Control.new()
	host.size = Vector2(720, 1280)
	add_child_autofree(host)
	var sheet := KitSheet.new()
	host.add_child(sheet)
	return sheet


func test_sheet_button_closes_and_calls() -> void:
	var sheet := _sheet()
	var calls := [0]
	var b := sheet.add_button("Go", func() -> void: calls[0] += 1)
	b.pressed.emit()
	assert_eq(calls[0], 1)
	assert_false(sheet.is_inside_tree())


func test_action_and_link_stay_open() -> void:
	var sheet := _sheet()
	var calls := [0]
	sheet.add_action("Do", func() -> void: calls[0] += 1).pressed.emit()
	sheet.add_link("Site", "https://example.org").pressed.emit()
	assert_eq(calls[0], 1)
	assert_eq(_opened, ["https://example.org"] as Array[String])
	assert_true(sheet.is_inside_tree())


func test_choice_presses_one() -> void:
	var sheet := _sheet()
	var picked := []
	var opts: Array[Dictionary] = [{"text": "A", "value": "a"}, {"text": "B", "value": "b"}]
	var row := sheet.add_choice(opts, "a", func(v: Variant) -> void: picked.append(v))
	var a: Button = row.get_child(0)
	var b: Button = row.get_child(1)
	assert_true(a.button_pressed)
	b.button_pressed = true  # what a tap does
	assert_eq(picked, ["b"])
	assert_false(a.button_pressed)
	assert_true(b.button_pressed)


func test_buttons_are_tall_and_never_take_focus() -> void:
	var sheet := _sheet()
	var b := sheet.add_button("Go")
	assert_gte(b.custom_minimum_size.y, 96.0)
	assert_eq(b.focus_mode, Control.FOCUS_NONE)


func test_long_text_scrolls() -> void:
	var sheet := _sheet()
	for i in 100:
		sheet.add_text("Line %d" % i)
	await wait_process_frames(3)
	assert_lte(sheet.panel().size.y, 1280 * 0.9 + 1)
	assert_gte(sheet.panel().position.y, 0.0)


func test_closed_emitted_once() -> void:
	var sheet := _sheet()
	watch_signals(sheet)
	sheet.close()
	sheet.close()
	assert_signal_emit_count(sheet, "closed", 1)
