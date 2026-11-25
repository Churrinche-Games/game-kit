extends GutTest

const PALETTE := {
	"paper": Color("#f1e6d6"),
	"line": Color("#4a3b2e"),
	"accent": Color("#b5532a"),
	"error": Color("#b3261e")
}


func test_theme_uses_palette_slots() -> void:
	var t := KitTheme.make(PALETTE)
	var normal: StyleBoxFlat = t.get_stylebox("normal", "Button")
	assert_eq(normal.bg_color, PALETTE.paper)
	assert_eq(normal.border_color, PALETTE.line)
	assert_eq(t.get_color("font_color", "Label"), PALETTE.line)
	var pressed: StyleBoxFlat = t.get_stylebox("pressed", "Button")
	assert_eq(pressed.bg_color, PALETTE.line)
	assert_eq(t.get_color("font_pressed_color", "Button"), PALETTE.paper)


func test_theme_missing_slot_errors() -> void:
	var t := KitTheme.make({"paper": Color.WHITE})
	assert_push_error_count(3)
	assert_not_null(t)


func test_switches_stay_readable_when_on() -> void:
	var t := KitTheme.make(PALETTE)
	for style in ["normal", "pressed", "hover", "hover_pressed"]:
		var box: StyleBoxFlat = t.get_stylebox(style, "CheckButton")
		assert_eq(box.bg_color, PALETTE.paper, style)
	for c in ["font_color", "font_pressed_color", "font_hover_pressed_color"]:
		assert_eq(t.get_color(c, "CheckButton"), PALETTE.line, c)


func test_button_text_keeps_off_the_border() -> void:
	var t := KitTheme.make(PALETTE)
	for type in ["Button", "CheckButton"]:
		for style in ["normal", "pressed"]:
			var box: StyleBoxFlat = t.get_stylebox(style, type)
			assert_gte(box.content_margin_left, 12.0, "%s %s" % [type, style])
			assert_gte(box.content_margin_right, 12.0, "%s %s" % [type, style])


func test_switch_icons_fit_the_text_size() -> void:
	var t := KitTheme.make(PALETTE)
	var on := t.get_icon("checked", "CheckButton")
	var off := t.get_icon("unchecked", "CheckButton")
	assert_not_null(on)
	assert_not_null(off)
	# Sized for the 30 px text, a pill wider than it is tall.
	assert_gte(on.get_height(), 30)
	assert_gt(on.get_width(), on.get_height())
	assert_eq(on.get_size(), off.get_size())
	# On is filled with the line colour at the knob's opposite end; off is paper there.
	var on_image := on.get_image()
	var off_image := off.get_image()
	var y := on_image.get_height() / 2
	var w := on_image.get_width()
	assert_true(on_image.get_pixel(w / 4, y).is_equal_approx(PALETTE.line))
	assert_true(off_image.get_pixel(w * 3 / 4, y).is_equal_approx(PALETTE.paper))
	for name in ["checked_disabled", "unchecked_disabled"]:
		assert_not_null(t.get_icon(name, "CheckButton"), name)


func test_switch_icons_stay_sharp_when_scaled_up() -> void:
	# Phones show the 720-wide canvas 1.5x larger and more; the icon is drawn at twice its size.
	var on := KitTheme.make(PALETTE).get_icon("checked", "CheckButton")
	assert_eq(on.get_image().get_width(), on.get_width() * 2)


func test_long_labels_keep_off_the_switch() -> void:
	assert_gte(KitTheme.make(PALETTE).get_constant("h_separation", "CheckButton"), 16)
