class_name KitTheme
extends RefCounted
## The shared look: a Godot Theme built from the game's palette slots.

const SLOTS := ["paper", "line", "accent", "error"]
const DEFAULTS := {
	"paper": Color("#f1e6d6"),
	"line": Color("#4a3b2e"),
	"accent": Color("#b5532a"),
	"error": Color("#b3261e")
}


## palette: one Color per slot in SLOTS. A missing slot is an error and gets a default color.
static func make(palette: Dictionary) -> Theme:
	var p := {}
	for slot: String in SLOTS:
		if palette.has(slot):
			p[slot] = palette[slot]
		else:
			push_error("KitTheme: the palette has no '%s' color" % slot)
			p[slot] = DEFAULTS[slot]
	var paper: Color = p.paper
	var line: Color = p.line
	var t := Theme.new()
	t.default_font_size = 30
	var normal := StyleBoxFlat.new()
	normal.bg_color = paper
	normal.border_color = line
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(16)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = line
	for style in ["normal", "hover", "focus", "disabled"]:
		t.set_stylebox(style, "Button", normal)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("hover_pressed", "Button", pressed)
	t.set_color("font_color", "Button", line)
	t.set_color("font_hover_color", "Button", line)
	t.set_color("font_focus_color", "Button", line)
	t.set_color("font_pressed_color", "Button", paper)
	t.set_color("font_hover_pressed_color", "Button", paper)
	t.set_color("font_disabled_color", "Button", Color(line, 0.4))
	t.set_color("font_color", "Label", line)
	# A switch shows its state with its toggle icon; its box never fills, so the label stays readable.
	for style in ["normal", "pressed", "hover", "hover_pressed", "focus", "disabled"]:
		t.set_stylebox(style, "CheckButton", normal)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(c, "CheckButton", line)
	# Godot's own toggle icons are drawn for 16 px text; these fit the theme's 30 px.
	t.set_icon("checked", "CheckButton", switch_icon(true, paper, line))
	t.set_icon("unchecked", "CheckButton", switch_icon(false, paper, line))
	t.set_icon("checked_disabled", "CheckButton", switch_icon(true, paper, Color(line, 0.4)))
	t.set_icon("unchecked_disabled", "CheckButton", switch_icon(false, paper, Color(line, 0.4)))
	var panel := StyleBoxFlat.new()
	panel.bg_color = paper
	panel.set_corner_radius_all(24)
	t.set_stylebox("panel", "PanelContainer", panel)
	return t


## A switch: a pill, filled with the line colour and the knob on the right when on; paper with a
## border and the knob on the left when off. Antialiased, drawn at runtime (no image files).
static func switch_icon(on: bool, paper: Color, line: Color) -> ImageTexture:
	const W := 68
	const H := 38
	var r := H / 2.0
	var knob := Vector2(W - r if on else r, r)
	var image := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var p := Vector2(x + 0.5, y + 0.5)
			# Distance to the pill's spine, minus its radius: < 0 inside.
			var d := Vector2(clampf(p.x, r, W - r), r).distance_to(p) - r
			var c := Color(0, 0, 0, 0)
			c = _over(c, line, clampf(0.5 - d, 0, 1))
			if not on:
				c = _over(c, paper, clampf(0.5 - (d + 3), 0, 1))
			c = _over(
				c, line if not on else paper, clampf(0.5 - (p.distance_to(knob) - (r - 7)), 0, 1)
			)
			image.set_pixel(x, y, c)
	return ImageTexture.create_from_image(image)


static func _over(dst: Color, src: Color, coverage: float) -> Color:
	var top := Color(src, src.a * coverage)
	return dst.blend(top)
