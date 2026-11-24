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
