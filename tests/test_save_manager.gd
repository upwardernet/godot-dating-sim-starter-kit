# Unit tests for SaveManager.gd — save/load/delete operations

var helpers = null

func _init(h) -> void:
	helpers = h

func run_all() -> void:
	test_invalid_slot_rejects_save()
	test_invalid_slot_rejects_load()
	test_save_and_load_roundtrip()
	test_save_metadata()
	test_delete_save()
	test_has_save()
	test_save_version()
	test_empty_load_returns_empty_dict()
	test_max_slots_constant()
	test_save_dir_creation()

func test_invalid_slot_rejects_save() -> void:
	var result = SaveManager.save_game(-1, {})
	helpers.assert_false(result, "Save to slot -1 fails")

	result = SaveManager.save_game(99, {})
	helpers.assert_false(result, "Save to slot 99 fails")

	result = SaveManager.save_game(SaveManager.MAX_SLOTS, {})
	helpers.assert_false(result, "Save to slot MAX_SLOTS fails")

func test_invalid_slot_rejects_load() -> void:
	var result = SaveManager.load_game(-1)
	helpers.assert_true(result.is_empty(), "Load from slot -1 returns empty")

	result = SaveManager.load_game(99)
	helpers.assert_true(result.is_empty(), "Load from slot 99 returns empty")

func test_save_and_load_roundtrip() -> void:
	var test_slot = 0
	# Clean up first
	SaveManager.delete_save(test_slot)

	var game_state = {
		"dialogue_index": 42,
		"flags": {"test_flag": true, "another_flag": "value"},
		"attraction_scores": {"maya": 7, "elena": 3, "vanessa": 5},
		"play_time": 123.45
	}

	var save_result = SaveManager.save_game(test_slot, game_state)
	helpers.assert_true(save_result, "Save succeeds for valid slot")

	var loaded = SaveManager.load_game(test_slot)
	helpers.assert_false(loaded.is_empty(), "Load returns non-empty dict")
	helpers.assert_eq(loaded.get("dialogue_index"), 42, "Dialogue index preserved")
	helpers.assert_eq(loaded.get("flags").get("test_flag"), true, "Flag preserved")
	helpers.assert_eq(loaded.get("flags").get("another_flag"), "value", "String flag preserved")
	helpers.assert_eq(loaded.get("attraction_scores").get("maya"), 7, "Maya attraction preserved")
	helpers.assert_eq(loaded.get("attraction_scores").get("elena"), 3, "Elena attraction preserved")
	helpers.assert_eq(loaded.get("attraction_scores").get("vanessa"), 5, "Vanessa attraction preserved")
	helpers.assert_eq(loaded.get("metadata", {}).get("play_time"), 123.45, "Play time preserved in metadata")

	# Cleanup
	SaveManager.delete_save(test_slot)

func test_save_metadata() -> void:
	var test_slot = 1
	SaveManager.delete_save(test_slot)

	var game_state = {
		"dialogue_index": 25,
		"flags": {},
		"attraction_scores": {},
		"play_time": 60.0
	}
	SaveManager.save_game(test_slot, game_state)

	var meta = SaveManager.get_save_metadata(test_slot)
	helpers.assert_true(meta.get("exists", false), "Metadata shows save exists")
	helpers.assert_not_empty(meta.get("timestamp", ""), "Timestamp is present")
	helpers.assert_not_empty(meta.get("progress", ""), "Progress description is present")
	helpers.assert_eq(meta.get("dialogue_index"), 25, "Dialogue index in metadata")

	SaveManager.delete_save(test_slot)

func test_delete_save() -> void:
	var test_slot = 2
	SaveManager.delete_save(test_slot)

	var game_state = {"dialogue_index": 0, "flags": {}, "attraction_scores": {}, "play_time": 0}
	SaveManager.save_game(test_slot, game_state)
	helpers.assert_true(SaveManager.has_save(test_slot), "Save exists before delete")

	var delete_result = SaveManager.delete_save(test_slot)
	helpers.assert_true(delete_result, "Delete succeeds")
	helpers.assert_false(SaveManager.has_save(test_slot), "Save does not exist after delete")

func test_has_save() -> void:
	var test_slot = 0
	SaveManager.delete_save(test_slot)
	helpers.assert_false(SaveManager.has_save(test_slot), "has_save false for empty slot")

	var game_state = {"dialogue_index": 0, "flags": {}, "attraction_scores": {}, "play_time": 0}
	SaveManager.save_game(test_slot, game_state)
	helpers.assert_true(SaveManager.has_save(test_slot), "has_save true after save")

	SaveManager.delete_save(test_slot)

func test_save_version() -> void:
	var test_slot = 1
	SaveManager.delete_save(test_slot)

	var game_state = {"dialogue_index": 0, "flags": {}, "attraction_scores": {}, "play_time": 0}
	SaveManager.save_game(test_slot, game_state)

	var loaded = SaveManager.load_game(test_slot)
	helpers.assert_eq(loaded.get("version"), "1.0", "Save version is 1.0")

	SaveManager.delete_save(test_slot)

func test_empty_load_returns_empty_dict() -> void:
	SaveManager.delete_save(0)
	SaveManager.delete_save(1)
	SaveManager.delete_save(2)

	for i in range(SaveManager.MAX_SLOTS):
		var result = SaveManager.load_game(i)
		helpers.assert_true(result.is_empty(), "Load empty slot %d returns empty dict" % i)

func test_max_slots_constant() -> void:
	helpers.assert_eq(SaveManager.MAX_SLOTS, 3, "MAX_SLOTS is 3")

func test_save_dir_creation() -> void:
	helpers.assert_eq(SaveManager.SAVE_DIR, "user://saves/", "SAVE_DIR is correct")
	helpers.assert_eq(SaveManager.SAVE_EXTENSION, ".save", "SAVE_EXTENSION is correct")
