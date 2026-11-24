extends GutTest


func test_full_safe_area_is_full_canvas() -> void:
	var r := KitMobile.safe_rect(Vector2i(1080, 2400), Rect2i(0, 0, 1080, 2400), Vector2(720, 1600))
	assert_eq(r, Rect2(0, 0, 720, 1600))


func test_notch_and_gesture_bar() -> void:
	var r := KitMobile.safe_rect(
		Vector2i(1080, 2400), Rect2i(0, 120, 1080, 2100), Vector2(720, 1600)
	)
	assert_eq(r, Rect2(0, 80, 720, 1400))


func test_safe_area_outside_the_window_is_clipped() -> void:
	var r := KitMobile.safe_rect(
		Vector2i(1080, 2400), Rect2i(-10, 60, 1200, 2400), Vector2(720, 1600)
	)
	assert_eq(r, Rect2(0, 40, 720, 1560))


func test_zero_window() -> void:
	var r := KitMobile.safe_rect(Vector2i.ZERO, Rect2i(0, 0, 0, 0), Vector2(720, 1280))
	assert_eq(r, Rect2(0, 0, 720, 1280))


func test_not_mobile_is_full_rect() -> void:
	var r := KitMobile.current_safe_rect(get_viewport())
	assert_eq(r, get_viewport().get_visible_rect())


func test_is_back() -> void:
	assert_true(KitMobile.is_back(Node.NOTIFICATION_WM_GO_BACK_REQUEST))
	assert_false(KitMobile.is_back(Node.NOTIFICATION_WM_CLOSE_REQUEST))
