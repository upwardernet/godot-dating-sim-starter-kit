extends Node

# TTSManager - Centralized text-to-speech playback system
#
# Architecture:
#   - TTS files named: tts_{char_id}_{say_index}.mp3
#   - say_index = 0-based count of ALL "say" entries in story.json (including narrator)
#   - Only character lines (non-empty char) have TTS files; narrator uses typing fallback
#
# API:
#   TTSManager.play_line(char_id, say_index)  - Play TTS for a dialogue line
#   TTSManager.stop()                         - Stop current TTS playback
#   TTSManager.set_enabled(enabled)           - Enable/disable TTS
#   TTSManager.is_playing() -> bool           - Check if TTS is currently playing
#   TTSManager.has_line(char_id, say_index) -> bool - Check if TTS file exists
#
# Adding new characters:
#   1. Generate TTS files as tts_{char_id}_{say_index}.mp3 in assets/audio/tts/
#   2. Add character display name to _display_names dict below
#
# Regenerating TTS:
#   1. Delete old files from assets/audio/tts/
#   2. Count "say" entries in story.json to get correct say_index for each line
#   3. Generate new files with correct naming
#   4. Clear .godot/imported/ and reimport in Godot editor

signal tts_started
signal tts_finished

var _enabled: bool = true
var _player: AudioStreamPlayer
var _cache: Dictionary = {}
var _display_names: Dictionary = {
	"maya": "Maya",
	"elena": "Elena",
	"vanessa": "Vanessa",
}

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)

func play_line(char_id: String, say_index: int) -> void:
	"""Play TTS audio for a character dialogue line.
	
	Args:
		char_id: Character identifier (e.g. "maya", "elena")
		say_index: Global index of this "say" entry in story.json (0-based)
	"""
	if not _enabled or char_id == "":
		return
	
	var file_path = _get_tts_path(char_id, say_index)
	
	if not ResourceLoader.exists(file_path):
		print("[TTSManager] File not found: ", file_path)
		tts_finished.emit()
		return
	
	# Load and cache
	if not _cache.has(file_path):
		var resource = load(file_path)
		if resource == null:
			print("[TTSManager] Failed to load: ", file_path)
			return
		_cache[file_path] = resource
	
	# Stop any playing audio
	if _player.playing:
		_player.stop()
	
	# Play
	_player.stream = _cache[file_path]
	_player.play()
	tts_started.emit()
	
	# Connect to finished signal
	if not _player.finished.is_connected(_on_tts_finished):
		_player.finished.connect(_on_tts_finished)

func stop() -> void:
	"""Stop current TTS playback and emit finished signal."""
	if _player.playing:
		_player.stop()
		tts_finished.emit()

func is_playing() -> bool:
	return _player.playing

func has_line(char_id: String, say_index: int) -> bool:
	var file_path = _get_tts_path(char_id, say_index)
	return ResourceLoader.exists(file_path)

func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if not enabled and _player.playing:
		stop()
	print("[TTSManager] TTS ", "enabled" if enabled else "disabled")

func set_volume(linear_value: float) -> void:
	_player.volume_db = linear_to_db(linear_value)

func is_enabled() -> bool:
	return _enabled

func get_display_name(char_id: String) -> String:
	return _display_names.get(char_id, char_id.capitalize())

func clear_cache() -> void:
	_cache.clear()

func _get_tts_path(char_id: String, say_index: int) -> String:
	return "res://assets/audio/tts/tts_%s_%d.mp3" % [char_id, say_index]

func _on_tts_finished() -> void:
	tts_finished.emit()
