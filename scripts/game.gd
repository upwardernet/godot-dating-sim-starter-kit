extends Control

# Main game controller
# Manages background, characters, and dialogue integration

@onready var background: TextureRect = $Background
@onready var character_container: HBoxContainer = $CharacterContainer
@onready var dialogue_box: Control = $CanvasLayer/DialogueBox
@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var auto_skip_button: Button = $AutoSkipButton
@onready var tts_button: Button = $TTSButton
@onready var save_load_button: Button = $SaveLoadButton
@onready var save_load_menu: Control = $SaveLoadMenu
@onready var settings_button: Button = $SettingsButton
@onready var settings_overlay: Control = $CanvasLayer/SettingsOverlay
@onready var game_over_overlay: Control = $GameOverOverlay

var auto_skip: bool = false
var tts_enabled: bool = true
var settings_open: bool = false
var attraction_scores: Dictionary = {"maya": 5, "elena": 5, "vanessa": 5}
var play_time: float = 0.0
var game_over: bool = false
var notification_queue: Array = []
var notification_active: bool = false

func _ready() -> void:
	print("[Game] _ready() called")
	# Mark all base portraits, bodies, and backgrounds as notified to prevent spam
	_mark_starting_unlocks()
	print("[Game] background node:", "Background" if $Background else "MISSING")
	print("[Game] character_container:", "CharacterContainer" if $CharacterContainer else "MISSING")
	print("[Game] dialogue_box:", "CanvasLayer/DialogueBox" if $CanvasLayer and $CanvasLayer/DialogueBox else "MISSING")
	set_background("living_room")
	print("[Game] background set to living_room")
	
	if dialogue_box:
		dialogue_box.line_confirmed.connect(func(): 
			print("[Game] line_confirmed signal received")
			DialogueManager.advance())
		dialogue_box.line_finished.connect(func():
			DialogueManager.line_finished.emit())
		print("[Game] line_confirmed connected")
	else:
		print("[Game] WARNING: dialogue_box is null!")
	
	# Fade in dark overlay
	dark_overlay.modulate = Color(1, 1, 1, 0)
	var overlay_tween = create_tween()
	overlay_tween.tween_property(dark_overlay, "modulate", Color(1, 1, 1, 1), 0.5)
	
	DialogueManager.load_script(Story.get_script_data())
	print("[Game] script loaded, calling _start_dialogue")
	
	# Play game BGM
	AudioManager.play_bgm("light")
	
	# Auto-skip button
	auto_skip_button.pressed.connect(_toggle_auto_skip)
	
	# TTS button
	tts_button.pressed.connect(_toggle_tts)
	tts_button.text = "TTS: ON"
	
	# Save/Load button
	save_load_button.pressed.connect(_open_save_load_menu)
	save_load_menu.save_requested.connect(_on_save_requested)
	save_load_menu.load_requested.connect(_on_load_requested)
	save_load_menu.menu_closed.connect(_on_save_load_menu_closed)
	
	# Settings button
	settings_button.pressed.connect(_open_settings)
	$CanvasLayer/SettingsOverlay/SettingsPanel/VBoxContainer/CloseButton.pressed.connect(_close_settings)
	$CanvasLayer/SettingsOverlay/SettingsPanel/VBoxContainer/ResetProgressButton.pressed.connect(_on_reset_progress_pressed)
	$CanvasLayer/SettingsOverlay/SettingsPanel/VBoxContainer/MainMenuButton.pressed.connect(_on_main_menu_btn_pressed)
	$CanvasLayer/SettingsOverlay/SettingsPanel/VBoxContainer/BGMContainer/BGMSlider.value_changed.connect(_on_bgm_volume_changed)
	$CanvasLayer/SettingsOverlay/SettingsPanel/VBoxContainer/SFXContainer/SFXSlider.value_changed.connect(_on_sfx_volume_changed)
	$CanvasLayer/SettingsOverlay/SettingsPanel/VBoxContainer/TTSContainer/TTSSlider.value_changed.connect(_on_tts_volume_changed)
	
	# Game over button
	$GameOverOverlay/VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$GameOverOverlay/VBoxContainer/MainMenuButton.pressed.connect(_on_main_menu_pressed)
	
	# Pass initial scores to dialogue box
	dialogue_box.set_attraction_scores(attraction_scores.duplicate())
	
	# Track affection flags
	DialogueManager.flag_changed.connect(_on_flag_changed)
	
	# Track attraction changes
	DialogueManager.attraction_changed.connect(_on_attraction_changed)
	
	# Track gallery unlocks
	GalleryManager.gallery_changed.connect(_on_gallery_changed)
	
	# Auto-skip disabled (enable for testing only)
	# auto_skip = true
	# auto_skip_button.text = "Auto Skip: ON"
	# DialogueManager.auto_advance = true
	# DialogueManager.auto_advance_delay = 0.0
	
	# Check if loading from save
	if Story.load_slot >= 0:
		if load_from_slot(Story.load_slot):
			print("[Game] Loaded from slot %d" % Story.load_slot)
			Story.load_slot = -1
			return
	
	_start_dialogue()

func _start_dialogue() -> void:
	print("[Game] _start_dialogue() executing")
	await get_tree().create_timer(0.1).timeout
	print("[Game] timer done, calling DialogueManager._start_dialogue()")
	DialogueManager._start_dialogue()

func _mark_starting_unlocks() -> void:
	for char_id in Characters.get_character_ids():
		for expr in Characters.get_expressions(char_id):
			_mark_notified("portrait_%s_%s" % [char_id, expr])
		for pose in ["pose1", "pose2"]:
			_mark_notified("body_%s_%s" % [char_id, pose])
	for bg_id in Characters.get_background_ids():
		_mark_notified("bg_%s" % bg_id)

func set_background(bg_id: String) -> void:
	GalleryManager.unlock_background(bg_id)
	var path = Characters.get_background(bg_id)
	if path and ResourceLoader.exists(path):
		var new_texture = load(path)
		background.modulate = Color(1, 1, 1, 0)
		background.texture = new_texture
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		AudioManager.play_sfx("transition")
		var tween = create_tween()
		tween.tween_property(background, "modulate", Color(1, 1, 1, 1), 0.5)

func show_character(char_id: String, expression: String = "neutral", _position: String = "center") -> void:
	GalleryManager.unlock_portrait(char_id, expression)
	GalleryManager.unlock_body(char_id, "pose1")
	GalleryManager.unlock_body(char_id, "pose2")
	var path = Characters.get_portrait(char_id, expression)
	if path and ResourceLoader.exists(path):
		var portrait_node: TextureRect = _get_or_create_portrait(char_id)
		portrait_node.texture = load(path)
		portrait_node.visible = true
		portrait_node.modulate = Color(1, 1, 1, 0)
		var tween = create_tween()
		tween.tween_property(portrait_node, "modulate", Color(1, 1, 1, 1), 0.4)

func hide_character(char_id: String) -> void:
	var portrait_node: TextureRect = character_container.get_node_or_null(char_id.to_pascal_case())
	if portrait_node:
		var tween = create_tween()
		tween.tween_property(portrait_node, "modulate", Color(1, 1, 1, 0), 0.3)
		tween.tween_callback(func(): portrait_node.visible = false)

func _get_or_create_portrait(char_id: String) -> TextureRect:
	var node_name = char_id.to_pascal_case()
	var existing: TextureRect = character_container.get_node_or_null(node_name)
	if existing:
		return existing
	
	var tex_rect = TextureRect.new()
	tex_rect.name = node_name
	tex_rect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	character_container.add_child(tex_rect)
	return tex_rect

func update_attraction(char_id: String, delta: int) -> void:
	if attraction_scores.has(char_id):
		attraction_scores[char_id] = clamp(attraction_scores[char_id] + delta, 0, 10)
		var new_score = attraction_scores[char_id]
		dialogue_box.update_attraction(char_id, new_score)
		
		# Check for game over (all three at 0)
		if attraction_scores["maya"] == 0 and attraction_scores["elena"] == 0 and attraction_scores["vanessa"] == 0:
			_trigger_game_over()

func _trigger_game_over() -> void:
	if game_over:
		return
	game_over = true
	print("[Game] GAME OVER! All attraction scores hit 0!")
	AudioManager.play_sfx("transition")
	
	# Show game over overlay
	game_over_overlay.visible = true
	game_over_overlay.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(game_over_overlay, "modulate", Color(1, 1, 1, 1), 0.5)
	
	# Stop dialogue
	DialogueManager.stop()

func _toggle_auto_skip() -> void:
	auto_skip = !auto_skip
	if auto_skip:
		auto_skip_button.text = "Auto Skip: ON"
		DialogueManager.auto_advance = true
		DialogueManager.auto_advance_delay = 0.8
		# Instantly skip current line when turning auto-skip on
		DialogueManager.advance()
		AudioManager.play_sfx("click")
	else:
		auto_skip_button.text = "Auto Skip: OFF"
		DialogueManager.auto_advance = false
		AudioManager.play_sfx("click")

func _toggle_tts() -> void:
	tts_enabled = !tts_enabled
	if tts_enabled:
		tts_button.text = "TTS: ON"
		TTSManager.set_enabled(true)
		AudioManager.play_sfx("click")
	else:
		tts_button.text = "TTS: OFF"
		TTSManager.set_enabled(false)
		AudioManager.play_sfx("click")

func _on_flag_changed(flag_name: String, value: Variant) -> void:
	if flag_name == "maya_affection" and value is int:
		update_attraction("maya", value)
	elif flag_name == "elena_affection" and value is int:
		update_attraction("elena", value)
	elif flag_name == "vanessa_affection" and value is int:
		update_attraction("vanessa", value)

func _on_attraction_changed(char_id: String, delta: int) -> void:
	update_attraction(char_id, delta)

func _process(delta: float) -> void:
	play_time += delta

func save_to_slot(slot: int) -> bool:
	var game_state = {
		"dialogue_index": DialogueManager._index,
		"flags": DialogueManager.flags.duplicate(),
		"attraction_scores": attraction_scores.duplicate(),
		"play_time": play_time
	}
	return SaveManager.save_game(slot, game_state)

func load_from_slot(slot: int) -> bool:
	var data = SaveManager.load_game(slot)
	if data.is_empty():
		return false
	
	# Restore game state
	DialogueManager._index = data.get("dialogue_index", 0)
	DialogueManager.flags = data.get("flags", {})
	attraction_scores = data.get("attraction_scores", {"maya": 5, "elena": 5, "vanessa": 5})
	play_time = data.get("play_time", 0.0)
	
	# Update UI
	dialogue_box.set_attraction_scores(attraction_scores.duplicate())
	
	# Restart dialogue from saved position
	DialogueManager._start_dialogue()
	
	return true

func _open_save_load_menu() -> void:
	save_load_menu.visible = true
	save_load_menu.refresh_slots()
	AudioManager.play_sfx("click")

func _on_save_requested(slot: int) -> void:
	if save_to_slot(slot):
		print("[Game] Saved to slot %d" % slot)
		save_load_menu.refresh_slots()
	AudioManager.play_sfx("click")

func _on_load_requested(slot: int) -> void:
	if load_from_slot(slot):
		print("[Game] Loaded from slot %d" % slot)
		save_load_menu.visible = false
	AudioManager.play_sfx("click")

func _on_save_load_menu_closed() -> void:
	save_load_menu.visible = false
	AudioManager.play_sfx("click")

func _open_settings() -> void:
	AudioManager.play_sfx("click")
	settings_open = true
	settings_overlay.visible = true
	settings_overlay.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(settings_overlay, "modulate", Color(1, 1, 1, 1), 0.3)

func _close_settings() -> void:
	AudioManager.play_sfx("click")
	settings_open = false
	var tween = create_tween()
	tween.tween_property(settings_overlay, "modulate", Color(1, 1, 1, 0), 0.2)
	await tween.finished
	settings_overlay.visible = false

func _on_bgm_volume_changed(value: float) -> void:
	AudioManager.set_volume(linear_to_db(value))

func _on_sfx_volume_changed(value: float) -> void:
	AudioManager.set_sfx_volume(linear_to_db(value))

func _on_tts_volume_changed(value: float) -> void:
	TTSManager.set_volume(value)

func _on_main_menu_btn_pressed() -> void:
	AudioManager.play_sfx("click")
	_autosave_and_return_to_menu()

func _on_reset_progress_pressed() -> void:
	AudioManager.play_sfx("click")
	SaveManager.delete_all_saves()
	GalleryManager.reset_all()
	print("[Game] Progress reset")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _autosave_and_return_to_menu() -> void:
	# Autosave to slot 0 before returning to menu
	if save_to_slot(0):
		print("[Game] Autosaved to slot 0 before returning to main menu")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_restart_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_main_menu_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_gallery_changed() -> void:
	for char_id in Characters.get_character_ids():
		for expr in Characters.get_expressions(char_id):
			if GalleryManager.is_portrait_unlocked(char_id, expr):
				var key = "portrait_%s_%s" % [char_id, expr]
				if not _was_notified(key):
					var path = Characters.get_portrait(char_id, expr)
					var display_name = Characters.get_display_name(char_id)
					_queue_notification(path, "%s — %s" % [display_name, expr.capitalize()])
					_mark_notified(key)
		for pose in ["pose1", "pose2"]:
			if GalleryManager.is_body_unlocked(char_id, pose):
				var key = "body_%s_%s" % [char_id, pose]
				if not _was_notified(key):
					var path = Characters.get_body(char_id, pose)
					var display_name = Characters.get_display_name(char_id)
					_queue_notification(path, "%s — %s" % [display_name, pose.capitalize()])
					_mark_notified(key)
	for bg_id in Characters.get_background_ids():
		if GalleryManager.is_background_unlocked(bg_id):
			var key = "bg_%s" % bg_id
			if not _was_notified(key):
				var path = Characters.get_background(bg_id)
				_queue_notification(path, bg_id.replace("_", " ").capitalize())
				_mark_notified(key)
	
	# Process next notification if not already showing
	if not notification_active and notification_queue.size() > 0:
		_show_next_notification()

var _notified_keys: Dictionary = {}

func _was_notified(key: String) -> bool:
	return _notified_keys.has(key)

func _mark_notified(key: String) -> void:
	_notified_keys[key] = true

func _queue_notification(path: String, label: String) -> void:
	if path and ResourceLoader.exists(path):
		notification_queue.append({"path": path, "label": label})

func _show_next_notification() -> void:
	if notification_queue.is_empty():
		notification_active = false
		return
	
	notification_active = true
	var item = notification_queue.pop_front()
	AudioManager.play_sfx("choice")
	
	# Create notification overlay
	var overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	
	# Background panel
	var panel = Panel.new()
	panel.position = Vector2(390, 200)
	panel.size = Vector2(500, 320)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.03, 0.12, 0.95)
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.85, 0.7, 0.95, 0.8)
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)
	
	# Glow effect
	var glow = ColorRect.new()
	glow.position = Vector2(385, 195)
	glow.size = Vector2(510, 330)
	glow.color = Color(0.5, 0.3, 0.8, 0.15)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(glow)
	
	# Title
	var title = Label.new()
	title.text = "✨ New Image Unlocked!"
	title.position = Vector2(410, 210)
	title.size = Vector2(460, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.95, 0.8, 1.0, 1))
	overlay.add_child(title)
	
	# Image preview
	var img_rect = TextureRect.new()
	img_rect.position = Vector2(410, 245)
	img_rect.size = Vector2(200, 200)
	img_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_rect.texture = load(item["path"])
	img_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(img_rect)
	
	# Label
	var label = Label.new()
	label.text = item["label"]
	label.position = Vector2(620, 245)
	label.size = Vector2(250, 200)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.75, 0.65, 0.9, 1))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(label)
	
	# Animate in
	overlay.modulate = Color(1, 1, 1, 0)
	panel.modulate = Color(1, 1, 1, 0)
	var in_tween = create_tween()
	in_tween.set_parallel(true)
	in_tween.tween_property(overlay, "modulate", Color(1, 1, 1, 1), 0.3)
	in_tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3)
	
	await get_tree().create_timer(2.5).timeout
	
	# Animate out
	var out_tween = create_tween()
	out_tween.set_parallel(true)
	out_tween.tween_property(overlay, "modulate", Color(1, 1, 1, 0), 0.4)
	await out_tween.finished
	
	overlay.queue_free()
	
	# Show next
	_show_next_notification()
