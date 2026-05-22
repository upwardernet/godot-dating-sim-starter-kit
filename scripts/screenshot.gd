extends Node

# Screenshot utility for automated testing
# Captures viewport frames and saves to user://screenshots/

const SCREENSHOT_DIR = "user://screenshots/"
var _counter: int = 0
var _enabled: bool = false
var _interval: float = 2.0
var _timer: float = 0.0

func _ready() -> void:
	DirAccess.make_dir_absolute(SCREENSHOT_DIR)
	_enabled = false  # Enable for testing only

func _process(delta: float) -> void:
	if not _enabled:
		return
	_timer += delta
	if _timer >= _interval:
		_timer = 0.0
		_take_screenshot()

func _take_screenshot() -> void:
	var viewport = get_viewport()
	var img = viewport.get_texture().get_image()
	# Downscale to reduce file size for opencode reading
	var target_width = 640
	var scale = float(target_width) / img.get_width()
	img.resize(target_width, int(img.get_height() * scale), Image.INTERPOLATE_LANCZOS)
	var filename = "screenshot_%04d.png" % _counter
	var path = SCREENSHOT_DIR + filename
	img.save_png(path)
	print("[Screenshot] Saved: ", path)
	_counter += 1

func capture_now(label: String = "") -> String:
	var viewport = get_viewport()
	var img = viewport.get_texture().get_image()
	# Downscale to reduce file size for opencode reading
	var target_width = 640
	var scale = float(target_width) / img.get_width()
	img.resize(target_width, int(img.get_height() * scale), Image.INTERPOLATE_LANCZOS)
	var suffix = "_%s" % label if label else ""
	var filename = "screenshot_%04d%s.png" % [_counter, suffix]
	var path = SCREENSHOT_DIR + filename
	img.save_png(path)
	print("[Screenshot] Saved: ", path)
	_counter += 1
	return path
