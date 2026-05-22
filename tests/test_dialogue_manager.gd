# Unit tests for DialogueManager.gd — dialogue flow, flags, choices, jumps

var helpers = null

func _init(h) -> void:
	helpers = h

func run_all() -> void:
	test_load_script()
	test_script_duplication()
	test_flag_set_and_get()
	test_flag_default_value()
	test_jump_to_label()
	test_jump_to_missing_label()
	test_stop_dialogue()
	test_auto_advance_settings()
	test_entry_types_supported()
	test_script_index_starts_at_zero()

func test_load_script() -> void:
	var test_script = [
		{"type": "label", "label": "start"},
		{"type": "say", "char": "elena", "text": "Hello", "say_index": 0},
		{"type": "say", "char": "maya", "text": "Hi", "say_index": 1}
	]
	DialogueManager.load_script(test_script)
	helpers.assert_eq(DialogueManager._script.size(), 3, "Script loaded with correct size")

func test_script_duplication() -> void:
	var original = [
		{"type": "say", "char": "elena", "text": "Test", "say_index": 0}
	]
	DialogueManager.load_script(original)
	# Modify original
	original[0]["text"] = "Modified"
	# Script should be unchanged
	helpers.assert_eq(DialogueManager._script[0]["text"], "Test", "Script is deep-copied, not referenced")

func test_flag_set_and_get() -> void:
	DialogueManager.set_flag("test_flag", "test_value")
	helpers.assert_eq(DialogueManager.get_flag("test_flag"), "test_value", "Flag set and retrieved correctly")

	DialogueManager.set_flag("num_flag", 42)
	helpers.assert_eq(DialogueManager.get_flag("num_flag"), 42, "Numeric flag works")

	DialogueManager.set_flag("bool_flag", true)
	helpers.assert_eq(DialogueManager.get_flag("bool_flag"), true, "Boolean flag works")

func test_flag_default_value() -> void:
	helpers.assert_eq(DialogueManager.get_flag("nonexistent"), null, "Unknown flag returns null")
	helpers.assert_eq(DialogueManager.get_flag("nonexistent", "default"), "default", "Unknown flag returns provided default")

func test_jump_to_label() -> void:
	var test_script = [
		{"type": "label", "label": "start"},
		{"type": "say", "char": "", "text": "before", "say_index": 0},
		{"type": "label", "label": "target"},
		{"type": "say", "char": "", "text": "after", "say_index": 1}
	]
	DialogueManager.load_script(test_script)
	DialogueManager._jump_to_label("target")
	helpers.assert_eq(DialogueManager._index, 3, "Jump to label sets index after label entry")

func test_jump_to_missing_label() -> void:
	var test_script = [
		{"type": "label", "label": "start"},
		{"type": "say", "char": "", "text": "test", "say_index": 0}
	]
	DialogueManager.load_script(test_script)
	var old_index = DialogueManager._index
	DialogueManager._jump_to_label("nonexistent")
	helpers.assert_eq(DialogueManager._index, old_index + 1, "Missing label increments index by 1")

func test_stop_dialogue() -> void:
	DialogueManager._running = true
	DialogueManager.stop()
	helpers.assert_false(DialogueManager._running, "Stop sets _running to false")

func test_auto_advance_settings() -> void:
	helpers.assert_false(DialogueManager.auto_advance, "Auto-advance starts disabled")
	helpers.assert_eq(DialogueManager.auto_advance_delay, 1.0, "Auto-advance delay defaults to 1.0")

	DialogueManager.auto_advance = true
	DialogueManager.auto_advance_delay = 0.5
	helpers.assert_true(DialogueManager.auto_advance, "Auto-advance can be enabled")
	helpers.assert_eq(DialogueManager.auto_advance_delay, 0.5, "Auto-advance delay can be changed")

	# Reset
	DialogueManager.auto_advance = false
	DialogueManager.auto_advance_delay = 1.0

func test_entry_types_supported() -> void:
	var test_script = [
		{"type": "label", "label": "start"},
		{"type": "say", "char": "elena", "text": "Hello", "say_index": 0},
		{"type": "bg", "id": "living_room"},
		{"type": "show", "char": "elena", "expr": "happy"},
		{"type": "hide", "char": "elena"},
		{"type": "flag", "set": "test_flag", "value": true},
		{"type": "jump", "label": "start"},
		{"type": "wait", "duration": 0.1},
		{"type": "change_attraction", "char": "maya", "value": 2}
	]
	DialogueManager.load_script(test_script)
	helpers.assert_eq(DialogueManager._script.size(), 9, "All entry types load correctly")

func test_script_index_starts_at_zero() -> void:
	DialogueManager.load_script([{"type": "say", "char": "", "text": "test", "say_index": 0}])
	helpers.assert_eq(DialogueManager._index, 0, "Index resets to 0 on load")
