extends SceneTree
## The studio banner (profile headers such as Cafecito's): the churrinche, the studio's name and
## its line, on paper, everything kept to the middle so a crop on narrow screens still reads.
## Needs a window (the text is drawn with Godot's font), so no --headless:
##   godot --path . -s tools/art/studio-banner.gd -- [out.png] [width] [height]
## Default: docs/brand/banner-1500x500.png. Draws from docs/brand/churrinche.svg (studio-logo.mjs).

const PAPER := Color("#f1e6d6")
const LINE := Color("#4a3b2e")
const INK := Color("#b3302a")
const NAME := "Churrinche Games"
const TAGLINE := ["Juegos chicos, gratis y de código abierto,", "con animales argentinos."]

var _out := "docs/brand/banner-1500x500.png"
var _view: SubViewport
var _frames := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	if not _out.is_absolute_path():
		_out = ProjectSettings.globalize_path("res://").path_join(_out)
	var size := Vector2i(1500, 500)
	if args.size() > 2:
		size = Vector2i(args[1].to_int(), args[2].to_int())
	_view = _banner(size)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 4:
		return false
	var image := _view.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	DirAccess.make_dir_recursive_absolute(_out.get_base_dir())
	image.save_png(_out)
	print("wrote ", _out, " ", image.get_size())
	quit(0)
	return true


func _banner(size: Vector2i) -> SubViewport:
	var view := SubViewport.new()
	view.size = size
	view.transparent_bg = false
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var paper := ColorRect.new()
	paper.color = PAPER
	paper.size = size
	view.add_child(paper)

	# The bird fills most of the height; the logo's square has paper around the bird.
	var bird_side := int(size.y * 1.0)
	var svg := FileAccess.get_file_as_string("res://docs/brand/churrinche.svg")
	var bird := Image.new()
	bird.load_svg_from_string(svg, float(bird_side) / 240.0)

	var bold := FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 0.9
	var regular := ThemeDB.fallback_font
	var name_px := int(size.y * 0.18)
	var line_px := int(size.y * 0.072)
	var name_w := bold.get_string_size(NAME, HORIZONTAL_ALIGNMENT_LEFT, -1, name_px).x
	var text_w := name_w
	for line: String in TAGLINE:
		text_w = maxf(text_w, regular.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, line_px).x)

	# The bird's square has paper on its right too, but the twig reaches into it: tuck in only a little.
	var tuck := bird_side * 0.05
	var group_w := bird_side - tuck + text_w
	# The bird's square starts with paper (about 15%): shift left so the ink, not the square, is centred.
	var left := (size.x - group_w) / 2.0 - bird_side * 0.07
	var art := TextureRect.new()
	art.texture = ImageTexture.create_from_image(bird)
	art.position = Vector2(left, (size.y - bird_side) / 2.0)
	view.add_child(art)

	var x := left + bird_side - tuck
	var name_h := name_px * 1.25
	var block_h := name_h + 16 + line_px * 1.4 * TAGLINE.size()
	var y := (size.y - block_h) / 2.0
	view.add_child(_label(NAME, bold, name_px, LINE, Vector2(x, y)))
	var rule := ColorRect.new()
	rule.color = INK
	rule.size = Vector2(name_w * 0.18, maxf(3.0, size.y * 0.008))
	rule.position = Vector2(x + 4, y + name_h + 2)
	view.add_child(rule)
	y += name_h + 16
	for line: String in TAGLINE:
		view.add_child(_label(line, regular, line_px, LINE, Vector2(x + 2, y)))
		y += line_px * 1.4
	return view


func _label(text: String, font: Font, px: int, color: Color, at: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", px)
	label.add_theme_color_override("font_color", color)
	label.position = at
	return label
