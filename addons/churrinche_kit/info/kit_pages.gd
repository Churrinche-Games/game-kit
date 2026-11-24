class_name KitPages
extends RefCounted
## The shared pages, each filling an open KitSheet: About, third-party licenses, Feedback, Support.


static func about(sheet: KitSheet, info: KitGameInfo, on_licenses: Callable) -> void:
	sheet.add_title(info.name)
	sheet.add_text(_t("KIT_VERSION") % info.version)
	sheet.add_text(_t("KIT_BY"))
	if info.repo_url:
		sheet.add_link(_t("KIT_SOURCE"), info.repo_url)
	sheet.add_text(_t("KIT_LICENSE_TEXT"))
	sheet.add_text(_t("KIT_MADE_WITH"))
	sheet.add_action(_t("KIT_LICENSES"), on_licenses)
	sheet.add_button(_t("KIT_CLOSE"))


## Godot's license, then every engine component with its copyright lines and license.
static func licenses(sheet: KitSheet) -> void:
	sheet.add_title(_t("KIT_LICENSES"))
	sheet.add_text("Godot Engine\n" + Engine.get_license_text())
	for component: Dictionary in Engine.get_copyright_info():
		var lines: PackedStringArray = [component.name]
		for part: Dictionary in component.parts:
			for line: String in part.copyright:
				lines.append("© " + line)
			lines.append(part.license)
		sheet.add_text("\n".join(lines))
	sheet.add_button(_t("KIT_CLOSE"))


static func has_feedback(info: KitGameInfo) -> bool:
	return not info.feedback_email.is_empty() or not info.repo_url.is_empty()


static func feedback(sheet: KitSheet, info: KitGameInfo) -> void:
	sheet.add_title(_t("KIT_FEEDBACK"))
	sheet.add_text(_t("KIT_FEEDBACK_TEXT"))
	var mailto := info.feedback_mailto(TranslationServer.get_locale())
	if mailto:
		sheet.add_link(_t("KIT_FEEDBACK_EMAIL"), mailto)
	if info.issues_url():
		sheet.add_link(_t("KIT_FEEDBACK_ISSUES"), info.issues_url())
	sheet.add_button(_t("KIT_CLOSE"))


static func has_support(info: KitGameInfo, build_store: StringName) -> bool:
	return not info.support_links_for(build_store).is_empty()


## Donation links; on a Play build (or without links) the sheet only gets its Close button.
static func support(sheet: KitSheet, info: KitGameInfo, build_store: StringName) -> void:
	var links := info.support_links_for(build_store)
	if not links.is_empty():
		sheet.add_title(_t("KIT_SUPPORT"))
		sheet.add_text(_t("KIT_SUPPORT_TEXT") % info.name)
		for link in links:
			sheet.add_link(link.name, link.url)
	sheet.add_button(_t("KIT_CLOSE"))


static func _t(key: String) -> String:
	return String(TranslationServer.translate(key))
