extends Control

# Main menu controller

var settings_open: bool = false
var continue_button: Button

@onready var hbox: HBoxContainer = $HBoxContainer
@onready var left_character_image: TextureRect = $HBoxContainer/LeftCharacterImage
@onready var right_character_image: TextureRect = $HBoxContainer/RightCharacterImage
@onready var center_container: CenterContainer = $HBoxContainer/CenterContainer
@onready var vbox: VBoxContainer = $HBoxContainer/CenterContainer/VBoxContainer

func _ready() -> void:
	print("[MainMenu] _ready() called")
	var start_btn = $HBoxContainer/CenterContainer/VBoxContainer/StartButton
	print("[MainMenu] StartButton:", "found" if start_btn else "MISSING")
	start_btn.pressed.connect(_on_start_pressed)
	
	# Add Continue button if save exists
	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(300, 50)
	continue_button.add_theme_font_size_override("font_size", 24)
	continue_button.visible = _has_any_save()
	continue_button.pressed.connect(_on_continue_pressed)
	vbox.add_child(continue_button)
	vbox.move_child(continue_button, 0)
	
	var settings_btn = $HBoxContainer/CenterContainer/VBoxContainer/SettingsButton
	print("[MainMenu] SettingsButton:", "found" if settings_btn else "MISSING")
	settings_btn.pressed.connect(_on_settings_pressed)
	var quit_btn = $HBoxContainer/CenterContainer/VBoxContainer/QuitButton
	print("[MainMenu] QuitButton:", "found" if quit_btn else "MISSING")
	quit_btn.pressed.connect(_on_quit_pressed)
	
	var close_btn = $SettingsOverlay/SettingsPanel/VBoxContainer/CloseButton
	close_btn.pressed.connect(_on_close_settings)
	
	var reset_btn = $SettingsOverlay/SettingsPanel/VBoxContainer/ResetProgressButton
	reset_btn.pressed.connect(_on_reset_progress_pressed)
	
	var main_menu_btn = $SettingsOverlay/SettingsPanel/VBoxContainer/MainMenuButton
	main_menu_btn.pressed.connect(_on_close_settings)
	
	var bgm_slider = $SettingsOverlay/SettingsPanel/VBoxContainer/BGMContainer/BGMSlider
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	
	var sfx_slider = $SettingsOverlay/SettingsPanel/VBoxContainer/SFXContainer/SFXSlider
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	var tts_slider = $SettingsOverlay/SettingsPanel/VBoxContainer/TTSContainer/TTSSlider
	tts_slider.value_changed.connect(_on_tts_volume_changed)
	
	var gallery_btn = $HBoxContainer/CenterContainer/VBoxContainer/GalleryButton
	gallery_btn.pressed.connect(_on_gallery_pressed)
	
	print("[MainMenu] all buttons connected")
	
	# Play menu BGM
	AudioManager.play_bgm("menu")
	
	# Fade in menu
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)
	
	# Load latest unlocked character portraits
	_load_latest_portraits()

func _load_latest_portraits() -> void:
	var char_ids = Characters.get_character_ids()
	if char_ids.size() >= 1:
		_load_menu_portrait(left_character_image, char_ids[0])
	if char_ids.size() >= 2:
		_load_menu_portrait(right_character_image, char_ids[1])

func _load_menu_portrait(texture_rect: TextureRect, char_id: String) -> void:
	var portrait_path = Characters.get_portrait(char_id, "happy")
	print("[MainMenu] Loading default portrait for %s: %s" % [char_id, portrait_path])
	_load_portrait(texture_rect, char_id, "happy")

func _has_any_progress() -> bool:
	if _has_any_save():
		return true
	return FileAccess.file_exists(GalleryManager.GALLERY_PATH)

func _load_portrait(texture_rect: TextureRect, char_id: String, expression: String) -> void:
	var path = Characters.get_portrait(char_id, expression)
	if path and ResourceLoader.exists(path):
		texture_rect.texture = load(path)
	else:
		texture_rect.visible = false

func _has_any_save() -> bool:
	for i in range(SaveManager.MAX_SLOTS):
		if SaveManager.has_save(i):
			return true
	return false

func _on_start_pressed() -> void:
	print("[MainMenu] Start pressed, changing to game.tscn")
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_continue_pressed() -> void:
	print("[MainMenu] Continue pressed, loading latest save")
	AudioManager.play_sfx("click")
	# Find the most recent save
	var latest_slot = -1
	var latest_time = ""
	for i in range(SaveManager.MAX_SLOTS):
		var meta = SaveManager.get_save_metadata(i)
		if meta.get("exists", false):
			var ts = meta.get("timestamp", "")
			if ts > latest_time:
				latest_time = ts
				latest_slot = i
	
	if latest_slot >= 0:
		# Store the slot to load in a global that game.gd can read
		Story.load_slot = latest_slot
		get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("click")
	settings_open = true
	hbox.visible = false
	$SettingsOverlay.visible = true
	$SettingsOverlay.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property($SettingsOverlay, "modulate", Color(1, 1, 1, 1), 0.3)

func _on_close_settings() -> void:
	AudioManager.play_sfx("click")
	settings_open = false
	var tween = create_tween()
	tween.tween_property($SettingsOverlay, "modulate", Color(1, 1, 1, 0), 0.2)
	await tween.finished
	$SettingsOverlay.visible = false
	hbox.visible = true

func _on_bgm_volume_changed(value: float) -> void:
	AudioManager.set_volume(linear_to_db(value))

func _on_sfx_volume_changed(value: float) -> void:
	AudioManager.set_sfx_volume(linear_to_db(value))

func _on_tts_volume_changed(value: float) -> void:
	TTSManager.set_volume(value)

func _on_quit_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().quit()

func _on_reset_progress_pressed() -> void:
	AudioManager.play_sfx("click")
	SaveManager.delete_all_saves()
	GalleryManager.reset_all()
	continue_button.visible = false
	print("[MainMenu] Progress reset")

func _on_gallery_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/gallery_menu.tscn")
