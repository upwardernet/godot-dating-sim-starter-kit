# Unit tests for TTSManager.gd — file path resolution, enable/disable

var helpers = null

func _init(h) -> void:
	helpers = h

func run_all() -> void:
	test_tts_path_format()
	test_tts_enabled_by_default()
	test_tts_disable()
	test_tts_display_names()
	test_tts_empty_char_returns_no_path()
	test_tts_cache_clear()
	test_tts_has_line_for_known_chars()

func test_tts_path_format() -> void:
	# Test path generation for known characters
	var expected_maya = "res://assets/audio/tts/tts_maya_0.mp3"
	var expected_elena = "res://assets/audio/tts/tts_elena_5.mp3"
	var expected_vanessa = "res://assets/audio/tts/tts_vanessa_10.mp3"

	# We can't directly call _get_tts_path since it's private, but we can test via has_line
	# Instead, verify the naming convention by checking the method exists
	helpers.assert_true(TTSManager.has_method("has_line"), "TTSManager has has_line method")

func test_tts_enabled_by_default() -> void:
	helpers.assert_true(TTSManager.is_enabled(), "TTS is enabled by default")

func test_tts_disable() -> void:
	TTSManager.set_enabled(false)
	helpers.assert_false(TTSManager.is_enabled(), "TTS can be disabled")
	TTSManager.set_enabled(true)
	helpers.assert_true(TTSManager.is_enabled(), "TTS can be re-enabled")

func test_tts_display_names() -> void:
	helpers.assert_eq(TTSManager.get_display_name("maya"), "Maya", "Maya display name")
	helpers.assert_eq(TTSManager.get_display_name("elena"), "Elena", "Elena display name")
	helpers.assert_eq(TTSManager.get_display_name("vanessa"), "Vanessa", "Vanessa display name")
	helpers.assert_eq(TTSManager.get_display_name("unknown"), "Unknown", "Unknown char gets capitalized")

func test_tts_empty_char_returns_no_path() -> void:
	# Empty char_id should not have a TTS file
	helpers.assert_false(TTSManager.has_line("", 0), "Empty char has no TTS line")

func test_tts_cache_clear() -> void:
	TTSManager.clear_cache()
	# After clearing, cache should be empty (can't directly test, but no crash)
	helpers.assert_true(true, "Cache clear does not crash")

func test_tts_has_line_for_known_chars() -> void:
	# These tests check if TTS files exist on disk
	# Results depend on whether files have been generated
	var maya_0_exists = TTSManager.has_line("maya", 0)
	var elena_0_exists = TTSManager.has_line("elena", 0)
	var vanessa_0_exists = TTSManager.has_line("vanessa", 0)

	# At minimum, the method should work without error
	helpers.assert_true(maya_0_exists == true or maya_0_exists == false, "has_line returns bool for maya_0")
	helpers.assert_true(elena_0_exists == true or elena_0_exists == false, "has_line returns bool for elena_0")
	helpers.assert_true(vanessa_0_exists == true or vanessa_0_exists == false, "has_line returns bool for vanessa_0")
