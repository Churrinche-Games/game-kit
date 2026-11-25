extends SceneTree
## Rasterizes an SVG to an opaque square PNG of the given size (no window needed):
##   godot --headless --path . -s tools/art/render_svg.gd -- <in.svg> <out.png> <size>


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		printerr("usage: render_svg.gd -- <in.svg> <out.png> <size>")
		quit(2)
		return
	var root_dir := ProjectSettings.globalize_path("res://")
	var src: String = args[0] if args[0].is_absolute_path() else root_dir.path_join(args[0])
	var dst: String = args[1] if args[1].is_absolute_path() else root_dir.path_join(args[1])
	var text := FileAccess.get_file_as_string(src)
	var probe := Image.new()
	probe.load_svg_from_string(text, 1.0)
	var image := Image.new()
	var err := image.load_svg_from_string(text, float(args[2].to_int()) / probe.get_width())
	if err != OK:
		printerr("could not read ", src)
		quit(1)
		return
	image.convert(Image.FORMAT_RGB8)
	DirAccess.make_dir_recursive_absolute(dst.get_base_dir())
	image.save_png(dst)
	print("wrote ", dst, " ", image.get_size())
	quit(0)
