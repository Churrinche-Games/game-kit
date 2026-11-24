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
	var panel := StyleBoxFlat.new()
	panel.bg_color = paper
	panel.set_corner_radius_all(24)
	t.set_stylebox("panel", "PanelContainer", panel)
	return t
