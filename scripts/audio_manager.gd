extends Node

# AudioManager - centralized BGM with crossfade and SFX playback support
# Uses AudioStreamPlayer with MP3 streams

var _bgm_player: AudioStreamPlayer
var _current_bgm: String = ""
var _volume_db: float = -10.0
var _is_fading: bool = false
var _sfx_volume: float = 0.0

const BGM_PATH = "res://assets/audio/bgm/"
const SFX_PATH = "res://assets/audio/sfx/"

var _sfx_cache: Dictionary = {}

func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	add_child(_bgm_player)
	
	# Preload SFX files
	_load_sfx("click")
	_load_sfx("type")
	_load_sfx("choice")
	_load_sfx("transition")

func _load_sfx(sfx_id: String) -> void:
	var path = SFX_PATH + "sfx_" + sfx_id + ".mp3"
	if ResourceLoader.exists(path):
		_sfx_cache[sfx_id] = load(path)
	else:
		print("[AudioManager] SFX file not found: ", path)

func _on_fade_finished() -> void:
	_is_fading = false
	if _bgm_player.playing:
		_bgm_player.stop()
		_play_current_bgm()

func play_bgm(bg_id: String, fade_duration: float = 1.0) -> void:
	if bg_id == _current_bgm and _bgm_player.playing:
		return
	var path = BGM_PATH + "bgm_" + bg_id + ".mp3"
	if not ResourceLoader.exists(path):
		print("[AudioManager] file not found: ", path)
		return
	_current_bgm = bg_id
	if _is_fading or _bgm_player.playing:
		_is_fading = true
		var tween = create_tween()
		tween.tween_property(_bgm_player, "volume_db", -80.0, fade_duration * 0.5)
		tween.tween_callback(_on_fade_finished)
	else:
		_play_current_bgm()

func _play_current_bgm() -> void:
	var path = BGM_PATH + "bgm_" + _current_bgm + ".mp3"
	if ResourceLoader.exists(path):
		var stream = load(path)
		_bgm_player.stream = stream
		_bgm_player.volume_db = _volume_db
		_bgm_player.play()

func stop_bgm(fade_duration: float = 1.0) -> void:
	if _is_fading:
		_is_fading = true
		var tween = create_tween()
		tween.tween_property(_bgm_player, "volume_db", -80.0, fade_duration)
		tween.tween_callback(_on_stop_finished)
	elif _bgm_player.playing:
		_bgm_player.stop()
		_current_bgm = ""

func _on_stop_finished() -> void:
	_is_fading = false
	_bgm_player.stop()
	_current_bgm = ""

func set_volume(volume: float) -> void:
	_volume_db = volume
	if _bgm_player.playing:
		_bgm_player.volume_db = _volume_db

func play_sfx(sfx_id: String) -> void:
	if not _sfx_cache.has(sfx_id):
		return
	if _sfx_volume <= -80.0:
		return
	var player = AudioStreamPlayer.new()
	player.bus = "Master"
	player.stream = _sfx_cache[sfx_id]
	player.volume_db = _sfx_volume
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func set_sfx_volume(volume_db: float) -> void:
	_sfx_volume = volume_db
