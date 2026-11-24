class_name KitGameInfo
extends RefCounted
## What the shared pages need to know about a game, read from its res://game_info.cfg:
##
##   [game]     name="…"  repo_url="https://github.com/…"
##   [feedback] email="…"            (empty until the game has a feedback address)
##   [support]  links=[["Ko-fi", "https://…"], …]   (shown only in itch.io builds)
##
## The file is not a resource: export presets must list it in include_filter.

const PATH := "res://game_info.cfg"

var name := ""
var version := ""
var repo_url := ""
var feedback_email := ""
var support_links: Array[Dictionary] = []


## Missing keys are empty; a missing file is a warning. version defaults to the project's.
static func from_file(path: String = PATH, version_override: String = "") -> KitGameInfo:
	var info := KitGameInfo.new()
	info.version = (
		version_override
		if version_override
		else str(ProjectSettings.get_setting("application/config/version", ""))
	)
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		push_warning("KitGameInfo: could not read %s" % path)
		return info
	info.name = str(cfg.get_value("game", "name", ""))
	info.repo_url = str(cfg.get_value("game", "repo_url", "")).trim_suffix("/")
	info.feedback_email = str(cfg.get_value("feedback", "email", ""))
	var links: Variant = cfg.get_value("support", "links", [])
	if links is Array:
		for link: Variant in links:
			if link is Array and link.size() == 2 and str(link[1]).begins_with("https://"):
				info.support_links.append({"name": str(link[0]), "url": str(link[1])})
	return info


## &"itch" in builds exported with the itch custom feature; every other build is &"play", which
## never shows donations.
static func store() -> StringName:
	return &"itch" if OS.has_feature("itch") else &"play"


func issues_url() -> String:
	return repo_url + "/issues" if repo_url else ""


## A mailto link with the game and version in the subject, in that language; "" without an email.
func feedback_mailto(locale: String) -> String:
	if feedback_email.is_empty():
		return ""
	var subject := "Feedback on %s v%s"
	var t := TranslationServer.get_translation_object(locale)
	if t != null and t.get_message("KIT_FEEDBACK_SUBJECT") != &"":
		subject = String(t.get_message("KIT_FEEDBACK_SUBJECT"))
	return "mailto:%s?subject=%s" % [feedback_email, (subject % [name, version]).uri_encode()]


func support_links_for(build_store: StringName) -> Array[Dictionary]:
	if build_store != &"itch":
		return []
	return support_links
