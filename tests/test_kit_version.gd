extends GutTest


func test_version_is_semver() -> void:
	var semver := RegEx.create_from_string("^\\d+\\.\\d+\\.\\d+$")
	assert_not_null(
		semver.search(ChurrincheKit.VERSION), "VERSION is not semver: %s" % ChurrincheKit.VERSION
	)
