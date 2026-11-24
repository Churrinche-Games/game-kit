class_name KitSheet
extends Control
## A modal panel over its parent: a dimmed background and a centred, scrolling column of text,
## switches and buttons (help, settings, About, confirmations).

signal closed

const WIDTH := 560.0
const MARGIN := 32
const BUTTON_H := 96.0
## The panel is at most this share of the parent's height; longer content scrolls.
const MAX_HEIGHT := 0.9

## Where the panel may sit, in the sheet's coordinates (the device safe area); empty = the whole
## sheet.
var area_rect := Rect2():
	set(value):
		area_rect = value
		_queue_place()

var _panel: PanelContainer
var _scroll: ScrollContainer
var _box: VBoxContainer
var _closed := false
var _place_queued := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = PanelContainer.new()
	add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, MARGIN)
	_panel.add_child(margin)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(_scroll)
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_theme_constant_override("separation", 20)
	_box.minimum_size_changed.connect(_queue_place)
	_scroll.add_child(_box)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_ENTER_TREE:
		_queue_place()


func panel() -> PanelContainer:
	return _panel


func add_title(text: String) -> Label:
	var label := add_text(text)
	label.add_theme_font_size_override("font_size", 40)
	return label


func add_text(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_child(label)
	return label


func add_check(text: String, value: bool, on_toggle: Callable) -> CheckButton:
	var check := CheckButton.new()
	check.text = text
	check.button_pressed = value
	check.focus_mode = Control.FOCUS_NONE
	check.custom_minimum_size = Vector2(0, BUTTON_H)
	check.toggled.connect(on_toggle)
	_box.add_child(check)
	return check


## A button that closes the sheet, then runs on_press.
func add_button(text: String, on_press: Callable = Callable()) -> Button:
	return _add(text, _close_then.bind(on_press))


## A button that runs on_press and leaves the sheet open.
func add_action(text: String, on_press: Callable) -> Button:
	return _add(text, on_press)


## A button that opens url and leaves the sheet open.
func add_link(text: String, url: String) -> Button:
	return _add(text, KitLinks.open.bind(url))


## A row of toggle buttons, one per option ({"text", "value"}); exactly one is pressed.
func add_choice(options: Array[Dictionary], current: Variant, on_pick: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var group := ButtonGroup.new()
	for option in options:
		var b := _new_button(option.text)
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = option.value == current
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.toggled.connect(_on_choice.bind(option.value, on_pick))
		row.add_child(b)
	_box.add_child(row)
	return row


func close() -> void:
	if _closed:
		return
	_closed = true
	if is_inside_tree():
		get_parent().remove_child(self)
	closed.emit()
	queue_free()


func _on_choice(on: bool, value: Variant, on_pick: Callable) -> void:
	if on:
		on_pick.call(value)


func _close_then(on_press: Callable) -> void:
	close()
	if on_press.is_valid():
		on_press.call()


func _add(text: String, on_press: Callable) -> Button:
	var b := _new_button(text)
	b.pressed.connect(on_press)
	_box.add_child(b)
	return b


func _new_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, BUTTON_H)
	return b


## Placement runs once per frame at most, after the content has changed: placing it from inside a
## resize (as wrapped text re-measures) can feed back into itself forever.
func _queue_place() -> void:
	if _place_queued:
		return
	_place_queued = true
	_place.call_deferred()


func _place() -> void:
	_place_queued = false
	var area := area_rect if area_rect.has_area() else Rect2(Vector2.ZERO, size)
	var width := minf(WIDTH, area.size.x - 32)
	# The scroll container keeps room for its bar; the text column gets exactly what is left.
	var reserve := _scroll.get_v_scroll_bar().get_combined_minimum_size().x
	var inner := width - MARGIN * 2 - reserve
	if _box.custom_minimum_size.x != inner:
		_box.custom_minimum_size.x = inner
	var content := _box.get_combined_minimum_size().y + MARGIN * 2
	var height := minf(content, area.size.y * MAX_HEIGHT)
	var rect := Rect2(
		(area.position + (area.size - Vector2(width, height)) / 2).floor(), Vector2(width, height)
	)
	if _panel.get_rect() != rect:
		_panel.position = rect.position
		_panel.size = rect.size
