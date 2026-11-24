class_name KitLinks
extends RefCounted
## Opens web and mailto links. Tests replace `opener`.

static var opener: Callable = OS.shell_open


static func open(url: String) -> void:
	if url.is_empty():
		return
	opener.call(url)
