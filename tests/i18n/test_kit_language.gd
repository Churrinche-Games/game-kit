extends GutTest

const CSV := "res://addons/churrinche_kit/i18n/kit_strings.csv"


func after_each() -> void:
	TranslationServer.set_locale("en")


func test_device_default() -> void:
	for locale in ["es", "es_AR", "es-419", "es_ES"]:
		assert_eq(KitLanguage.device_default(locale), "es", locale)
	for locale in ["en_US", "pt_BR", "", "fr"]:
		assert_eq(KitLanguage.device_default(locale), "en", locale)


func test_saved_overrides() -> void:
	assert_eq(KitLanguage.resolve("en", "es_AR"), "en")
	assert_eq(KitLanguage.resolve("es", "en_US"), "es")
	assert_eq(KitLanguage.resolve("", "es_AR"), "es")
	assert_eq(KitLanguage.resolve("fr", "es_AR"), "es")


func test_apply_sets_locale() -> void:
	assert_eq(KitLanguage.apply("es"), "es")
	assert_eq(TranslationServer.get_locale(), "es")
	assert_eq(tr("KIT_ABOUT"), "Acerca de")


func test_display_names() -> void:
	assert_eq(KitLanguage.display_name("es"), "Español")
	assert_eq(KitLanguage.display_name("en"), "English")


func test_every_key_has_both_languages() -> void:
	var f := FileAccess.open(CSV, FileAccess.READ)
	assert_eq(f.get_csv_line(), PackedStringArray(["keys", "es", "en"]))
	var rows := {}
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() == 1 and row[0] == "":
			continue
		assert_eq(row.size(), 3, str(row))
		assert_true(row[0].begins_with("KIT_"), row[0])
		assert_ne(row[1], "", row[0])
		assert_ne(row[2], "", row[0])
		rows[row[0]] = row
	assert_string_contains(rows.KIT_FEEDBACK_TEXT[1], "Contanos")
	assert_string_contains(rows.KIT_FEEDBACK_SUBJECT[1], "Comentarios sobre %s v%s")


func test_translations_load() -> void:
	var es: Translation = load("res://addons/churrinche_kit/i18n/kit_strings.es.translation")
	assert_eq(es.get_message("KIT_ABOUT"), "Acerca de")
