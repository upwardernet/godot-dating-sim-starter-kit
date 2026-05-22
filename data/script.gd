extends Node

# Story script loader - loads dialogue from JSON
# JSON format supports: label, say, bg, show, hide, choice, flag, jump, wait
# Each "say" entry: {"type": "say", "char": "id", "expr": "expression", "text": "dialogue"}
# Empty char/expr for narrator text

const STORY_PATH = "res://data/story.json"

var _script_data: Array = []
var load_slot: int = -1

func _ready() -> void:
	_load_story()

func _load_story() -> void:
	var file = FileAccess.open(STORY_PATH, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			_script_data = json.data.get("script", [])
			print("[Story] Loaded ", _script_data.size(), " entries from story.json")
		else:
			push_error("[Story] JSON parse error: ", json.get_error_message())
			_script_data = []
	else:
		push_error("[Story] Could not open story file: ", STORY_PATH)
		_script_data = []

func get_script_data() -> Array:
	return _script_data
