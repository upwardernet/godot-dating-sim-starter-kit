extends Node

# Save/Load system for game state persistence
# Handles multiple save slots, metadata, and game state serialization

const SAVE_DIR = "user://saves/"
const MAX_SLOTS = 3
const SAVE_EXTENSION = ".save"

signal save_loaded(slot: int)
signal save_created(slot: int)

func _ready() -> void:
	DirAccess.make_dir_absolute(SAVE_DIR)

func get_save_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d%s" % [slot, SAVE_EXTENSION]

func save_game(slot: int, game_state: Dictionary) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		push_error("SaveManager: Invalid slot %d" % slot)
		return false
	
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"dialogue_index": game_state.get("dialogue_index", 0),
		"flags": game_state.get("flags", {}),
		"attraction_scores": game_state.get("attraction_scores", {}),
		"metadata": {
			"progress": _generate_progress_description(game_state.get("dialogue_index", 0)),
			"play_time": game_state.get("play_time", 0)
		}
	}
	
	var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if not file:
		push_error("SaveManager: Failed to open save file for slot %d" % slot)
		return false
	
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	
	save_created.emit(slot)
	print("[SaveManager] Game saved to slot %d" % slot)
	return true

func load_game(slot: int) -> Dictionary:
	var path = get_save_path(slot)
	if not FileAccess.file_exists(path):
		push_error("SaveManager: No save file in slot %d" % slot)
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("SaveManager: Failed to open save file for slot %d" % slot)
		return {}
	
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()
	
	if parse_result != OK:
		push_error("SaveManager: Failed to parse save file for slot %d" % slot)
		return {}
	
	var data = json.get_data()
	if data.get("version") != "1.0":
		push_warning("SaveManager: Save version mismatch (expected 1.0, got %s)" % data.get("version"))
	
	save_loaded.emit(slot)
	print("[SaveManager] Game loaded from slot %d" % slot)
	return data

func get_save_metadata(slot: int) -> Dictionary:
	var path = get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {"exists": false}
	
	var data = load_game(slot)
	if data.is_empty():
		return {"exists": false}
	
	return {
		"exists": true,
		"timestamp": data.get("timestamp", "Unknown"),
		"progress": data.get("metadata", {}).get("progress", "Unknown"),
		"dialogue_index": data.get("dialogue_index", 0)
	}

func delete_save(slot: int) -> bool:
	var path = get_save_path(slot)
	if not FileAccess.file_exists(path):
		return false
	
	var dir = DirAccess.open(SAVE_DIR)
	if not dir:
		push_error("SaveManager: Failed to open save directory")
		return false
	
	var error = dir.remove(path)
	if error != OK:
		push_error("SaveManager: Failed to delete save file for slot %d" % slot)
		return false
	
	print("[SaveManager] Save deleted from slot %d" % slot)
	return true

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func delete_all_saves() -> void:
	for i in range(MAX_SLOTS):
		delete_save(i)
	print("[SaveManager] All saves deleted")

func _generate_progress_description(dialogue_index: int) -> String:
	# Map dialogue indices to progress descriptions
	if dialogue_index < 10:
		return "Episode 1: Arrival - Beginning"
	elif dialogue_index < 30:
		return "Episode 1: Arrival - Meeting the Family"
	elif dialogue_index < 50:
		return "Episode 1: Arrival - Making Choices"
	elif dialogue_index < 70:
		return "Episode 1: Arrival - Route Selected"
	else:
		return "Episode 1: Arrival - Near End"
