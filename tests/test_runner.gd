# Main test runner — executes all test suites and reports results

extends Node

var helpers
var all_passed: bool = true
var total_passed: int = 0
var total_failed: int = 0
var all_failures: Array = []

func _ready() -> void:
	print("\n")
	print("SIGMA DATE - TEST SUITE")
	print("\n")

	helpers = load("res://tests/test_helpers.gd").new()

	# Run all test suites
	var suites = [
		["Characters", "res://tests/test_characters.gd"],
		["SaveManager", "res://tests/test_save_manager.gd"],
		["GalleryManager", "res://tests/test_gallery_manager.gd"],
		["DialogueManager", "res://tests/test_dialogue_manager.gd"],
		["Full Dialogue", "res://tests/test_dialogue_full.gd"],
		["TTSManager", "res://tests/test_tts_manager.gd"],
	]

	for suite_info in suites:
		var suite_name = suite_info[0]
		var path = suite_info[1]
		print("\n--- Running: %s ---" % suite_name)
		helpers.reset()
		var test_script = load(path)
		var test_instance = test_script.new(helpers)
		test_instance.run_all()
		total_passed += helpers._passed
		total_failed += helpers._failed
		if not helpers.all_passed():
			all_passed = false
			# Collect failures
			for r in helpers._results:
				if r.begins_with("FAIL"):
					all_failures.append("[%s] %s" % [suite_name, r])
		# Print per-suite summary
		print("  %s: %d passed, %d failed" % [suite_name, helpers._passed, helpers._failed])

	# Print failures
	if all_failures.size() > 0:
		print("\n========== FAILURES ==========")
		for f in all_failures:
			print(f)
		print("============================\n")

	# Print final summary
	print("\n========== FINAL RESULTS ==========")
	print("Total: %d | Passed: %d | Failed: %d" % [total_passed + total_failed, total_passed, total_failed])
	print("================================\n")

	if all_passed:
		print("ALL TESTS PASSED!")
	else:
		print("SOME TESTS FAILED!")

	# Auto-quit after tests complete
	await get_tree().create_timer(2.0).timeout
	get_tree().quit(0 if all_passed else 1)
