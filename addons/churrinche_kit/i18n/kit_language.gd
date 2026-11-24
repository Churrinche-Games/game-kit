class_name KitLanguage
extends RefCounted
## Spanish when the device is in Spanish, English otherwise; a saved choice overrides that.

const SUPPORTED := ["es", "en"]
const NAMES := {"es": "Español", "en": "English"}


static func device_default(os_locale: String) -> String:
	return "es" if os_locale.to_lower().begins_with("es") else "en"


## The language to use: the saved one if it is supported ("" means follow the device).
static func resolve(saved: String, os_locale: String) -> String:
	return saved if saved in SUPPORTED else device_default(os_locale)


## Resolves against the device locale, switches the game to it and returns it.
static func apply(saved: String) -> String:
	var code := resolve(saved, OS.get_locale())
	TranslationServer.set_locale(code)
	return code


static func display_name(code: String) -> String:
	return NAMES.get(code, code)
