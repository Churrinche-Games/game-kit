extends GutTest

const FULL := "res://tests/info/game_info_full.cfg"
const MIN := "res://tests/info/game_info_min.cfg"

var _opened: Array[String] = []
var _old_opener: Callable


func before_each() -> void:
	_opened.clear()
	_old_opener = KitLinks.opener
	KitLinks.opener = func(url: String) -> void: _opened.append(url)
	TranslationServer.set_locale("en")


func after_each() -> void:
	KitLinks.opener = _old_opener


func _sheet() -> KitSheet:
	var host := Control.new()
	host.size = Vector2(720, 1280)
	add_child_autofree(host)
	var sheet := KitSheet.new()
	host.add_child(sheet)
	return sheet


func _texts(node: Node) -> Array[String]:
	var out: Array[String] = []
	for child in node.find_children("*", "", true, false):
		if child is Label or child is Button:
			out.append(child.text)
	return out


func _button(sheet: KitSheet, text: String) -> Button:
	for child in sheet.find_children("*", "Button", true, false):
		if (child as Button).text == text:
			return child
	return null


func test_about_has_version_and_source() -> void:
	var sheet := _sheet()
	var calls := [0]
	KitPages.about(sheet, KitGameInfo.from_file(FULL, "1.2.3"), func() -> void: calls[0] += 1)
	var texts := _texts(sheet)
	assert_has(texts, "Juego")
	assert_has(texts, "Version 1.2.3")
	assert_has(texts, "Made with Godot Engine")
	_button(sheet, "Source code on GitHub").pressed.emit()
	assert_eq(_opened, ["https://github.com/example/juego"] as Array[String])
	_button(sheet, "Third-party licenses").pressed.emit()
	assert_eq(calls[0], 1)


func test_about_without_repo_has_no_source_link() -> void:
	var sheet := _sheet()
	KitPages.about(sheet, KitGameInfo.from_file(MIN, "1.0.0"), func() -> void: pass)
	assert_null(_button(sheet, "Source code on GitHub"))


func test_feedback_with_everything() -> void:
	var sheet := _sheet()
	KitPages.feedback(sheet, KitGameInfo.from_file(FULL, "1.2.3"))
	_button(sheet, "Send an email").pressed.emit()
	_button(sheet, "Open an issue on GitHub").pressed.emit()
	assert_eq(_opened.size(), 2)
	assert_string_starts_with(_opened[0], "mailto:a@b.c?subject=Feedback%20on%20Juego")
	assert_eq(_opened[1], "https://github.com/example/juego/issues")


func test_feedback_hides_missing_parts() -> void:
	var no_email := KitGameInfo.from_file(FULL, "1.2.3")
	no_email.feedback_email = ""
	var sheet := _sheet()
	KitPages.feedback(sheet, no_email)
	assert_null(_button(sheet, "Send an email"))
	assert_not_null(_button(sheet, "Open an issue on GitHub"))
	assert_true(KitPages.has_feedback(no_email))
	assert_false(KitPages.has_feedback(KitGameInfo.from_file(MIN, "1.0.0")))


func test_no_support_on_play() -> void:
	var full := KitGameInfo.from_file(FULL, "1.2.3")
	assert_false(KitPages.has_support(full, &"play"))
	assert_true(KitPages.has_support(full, &"itch"))
	assert_false(KitPages.has_support(KitGameInfo.from_file(MIN, "1.0.0"), &"itch"))


func test_support_lists_each_link() -> void:
	var sheet := _sheet()
	KitPages.support(sheet, KitGameInfo.from_file(FULL, "1.2.3"), &"itch")
	assert_string_contains(" ".join(_texts(sheet)), "Juego is free and open source")
	_button(sheet, "Cafecito").pressed.emit()
	assert_eq(_opened, ["https://cafecito.app/example"] as Array[String])


func test_support_on_play_shows_nothing_to_donate() -> void:
	var sheet := _sheet()
	KitPages.support(sheet, KitGameInfo.from_file(FULL, "1.2.3"), &"play")
	assert_null(_button(sheet, "Ko-fi"))


func test_licenses_mention_godot() -> void:
	var sheet := _sheet()
	KitPages.licenses(sheet)
	var all := " ".join(_texts(sheet))
	assert_string_contains(all, "Godot Engine")
	assert_string_contains(all, "FreeType")
