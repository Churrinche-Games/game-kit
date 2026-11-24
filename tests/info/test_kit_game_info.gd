extends GutTest

const FULL := "res://tests/info/game_info_full.cfg"
const MIN := "res://tests/info/game_info_min.cfg"


func test_reads_full_file() -> void:
	var info := KitGameInfo.from_file(FULL, "1.2.3")
	assert_eq(info.name, "Juego")
	assert_eq(info.version, "1.2.3")
	assert_eq(info.repo_url, "https://github.com/example/juego")
	assert_eq(info.issues_url(), "https://github.com/example/juego/issues")
	assert_eq(info.feedback_email, "a@b.c")
	assert_eq(info.support_links.size(), 2)
	assert_eq(info.support_links[1], {"name": "Cafecito", "url": "https://cafecito.app/example"})


func test_missing_parts_are_empty() -> void:
	var info := KitGameInfo.from_file(MIN, "1.0.0")
	assert_eq(info.name, "Juego")
	assert_eq(info.repo_url, "")
	assert_eq(info.issues_url(), "")
	assert_eq(info.feedback_email, "")
	assert_eq(info.support_links.size(), 0)


func test_missing_file_is_empty() -> void:
	var info := KitGameInfo.from_file("res://tests/info/nope.cfg", "1.0.0")
	assert_push_warning("nope.cfg")
	assert_eq(info.name, "")
	assert_eq(info.support_links.size(), 0)


func test_version_defaults_to_the_project_setting() -> void:
	var old: Variant = ProjectSettings.get_setting("application/config/version", "")
	ProjectSettings.set_setting("application/config/version", "4.5.6")
	assert_eq(KitGameInfo.from_file(MIN).version, "4.5.6")
	ProjectSettings.set_setting("application/config/version", old)


func test_mailto_subject_es_and_en() -> void:
	var info := KitGameInfo.from_file(FULL, "1.2.3")
	assert_eq(
		info.feedback_mailto("es"), "mailto:a@b.c?subject=Comentarios%20sobre%20Juego%20v1.2.3"
	)
	assert_eq(info.feedback_mailto("en"), "mailto:a@b.c?subject=Feedback%20on%20Juego%20v1.2.3")


func test_no_email_no_mailto() -> void:
	assert_eq(KitGameInfo.from_file(MIN, "1.0.0").feedback_mailto("es"), "")


func test_store_is_play_here() -> void:
	assert_eq(KitGameInfo.store(), &"play")


func test_support_links_only_for_itch() -> void:
	var info := KitGameInfo.from_file(FULL, "1.2.3")
	assert_eq(info.support_links_for(&"play").size(), 0)
	assert_eq(info.support_links_for(&"itch").size(), 2)
