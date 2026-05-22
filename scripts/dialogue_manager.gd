extends Node

# Dialogue system - plays through script lines
# Connect to signals: line_started, line_ended, choices_presented, choice_selected, script_ended, attraction_changed

signal line_started(line_data: Dictionary)
signal line_finished
signal flag_changed(flag_name: String, value: Variant)
signal attraction_changed(char_id: String, delta: int)
signal choices_presented(choices: Array)
signal choice_selected(index: int)
signal script_ended

var _script: Array = []
var _index: int = 0
var _running: bool = false
var _loop_active: bool = false

# Auto-advance for automated testing
var auto_advance: bool = false
var auto_advance_delay: float = 1.0

# Story flags for branching
var flags: Dictionary = {}

func load_script(script_data: Array) -> void:
	print("[DialogueManager] load_script: ", script_data.size(), " entries")
	_script = script_data.duplicate(true)
	_index = 0
	_running = false
	_loop_active = false

func _start_dialogue() -> void:
	if auto_advance:
		print("[DialogueManager] auto-advance enabled, delay=", auto_advance_delay)
	print("[DialogueManager] start() called, script size=", _script.size(), " current index=", _index)
	_running = true
	_play_loop()

func stop() -> void:
	_running = false

func advance() -> void:
	print("[DialogueManager] advance() called, _index was ", _index)
	if not _running:
		return
	# Increment first so the awaiting loop sees the change
	_index += 1
	# Stop any playing TTS
	var db = get_tree().root.get_node_or_null("Game/CanvasLayer/DialogueBox")
	if db and db.has_method("stop_tts"):
		db.stop_tts()
	_play_loop()

func select_choice(index: int) -> void:
	print("[DialogueManager] select_choice(", index, ")")
	choice_selected.emit(index)
	if _index < _script.size():
		var entry = _script[_index]
		if entry.get("type") == "choice":
			var options = entry.get("options", [])
			if index < options.size():
				var jump = options[index].get("jump", "")
				print("[DialogueManager] jumping to label: ", jump)
				if jump != "":
					_jump_to_label(jump)
					_play_loop()
					return
	_index += 1
	_play_loop()

func set_flag(flag_name: String, value: Variant) -> void:
	flags[flag_name] = value

func get_flag(flag_name: String, default: Variant = null) -> Variant:
	return flags.get(flag_name, default)

func _play_loop() -> void:
	if _loop_active:
		return
	_loop_active = true
	while _index < _script.size() and _running:
		var entry = _script[_index]
		var entry_type = entry.get("type", "say")
		var my_index = _index
		print("[DialogueManager] processing entry[", _index, "] type=", entry_type)

		match entry_type:
			"label":
				_index += 1
			"say":
				line_started.emit(entry)
				if auto_advance:
					await line_finished
					# If advance() was called while awaiting, skip
					if _index != my_index:
						continue
					await get_tree().create_timer(auto_advance_delay).timeout
					if _index != my_index:
						continue
					_index += 1
				else:
					break
			"bg":
				line_started.emit(entry)
				_index += 1
			"show":
				line_started.emit(entry)
				_index += 1
			"hide":
				line_started.emit(entry)
				_index += 1
			"choice":
				choices_presented.emit(entry.get("options", []))
				if auto_advance:
					await get_tree().create_timer(auto_advance_delay).timeout
					if entry.has("options") and entry["options"].size() > 0:
						choice_selected.emit(0)
						var jump = entry["options"][0].get("jump", "")
						if jump != "":
							_jump_to_label(jump)
						else:
							_index += 1
				else:
					break
			"flag":
				if entry.has("set"):
					flags[entry["set"]] = entry.get("value", true)
					flag_changed.emit(entry["set"], flags[entry["set"]])
				_index += 1
			"change_attraction":
				var char_id = entry.get("char", "")
				var delta = entry.get("value", 0)
				if char_id != "":
					attraction_changed.emit(char_id, delta)
				_index += 1
			"jump":
				_jump_to_label(entry.get("label", ""))
			"wait":
				await get_tree().create_timer(entry.get("duration", 1.0)).timeout
				_index += 1
			_:
				line_started.emit(entry)
				break
	_loop_active = false
	if _running and _index >= _script.size():
		print("[DialogueManager] reached end, emitting script_ended")
		_running = false
		script_ended.emit()

func _jump_to_label(label: String) -> void:
	for i in range(_script.size()):
		var entry = _script[i]
		if entry.get("type") == "label" and entry.get("label") == label:
			_index = i + 1
			return
	push_error("DialogueManager: Label '%s' not found" % label)
	_index += 1
