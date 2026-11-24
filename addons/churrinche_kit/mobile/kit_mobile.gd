class_name KitMobile
extends RefCounted
## Phone basics: the safe area (notches, camera holes, gesture bar) in canvas units, and the
## Android back button. Games set application/config/quit_on_go_back=false and handle back.


## The safe area, given in window pixels, converted to canvas units and clipped to the canvas.
static func safe_rect(window: Vector2i, safe: Rect2i, canvas: Vector2) -> Rect2:
	var full := Rect2(Vector2.ZERO, canvas)
	if window.x <= 0 or window.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
		return full
	var scale := canvas / Vector2(window)
	var r := Rect2(Vector2(safe.position) * scale, Vector2(safe.size) * scale)
	return r.intersection(full)


## The safe area of this device in the viewport's canvas units; the whole visible rect on
## desktops and the web, where the "safe area" is the screen's, not the window's.
static func current_safe_rect(viewport: Viewport) -> Rect2:
	var visible := viewport.get_visible_rect()
	if not OS.has_feature("mobile"):
		return visible
	var r := safe_rect(
		DisplayServer.window_get_size(), DisplayServer.get_display_safe_area(), visible.size
	)
	return Rect2(r.position + visible.position, r.size)


static func is_back(what: int) -> bool:
	return what == Node.NOTIFICATION_WM_GO_BACK_REQUEST
