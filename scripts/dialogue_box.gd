extends Control

# Dialogue box UI - displays portrait, speaker name, and dialogue text
# Emits 'line_confirmed' when user clicks to advance

signal line_confirmed
signal line_finished

@onready var portrait: TextureRect = $HBoxContainer/PortraitContainer/Portrait
@onready var portrait_container: VBoxContainer = $HBoxContainer/PortraitContainer
@onready var speaker_name: RichTextLabel = $HBoxContainer/TextContainer/NamePanel/SpeakerName
@onready var dialogue_text: RichTextLabel = $HBoxContainer/TextContainer/DialogueTextMargin/DialogueText
@onready var choices_container: VBoxContainer = $HBoxContainer/TextContainer/DialogueTextMargin/ChoicesContainer
@onready var continue_indicator: Label = $HBoxContainer/TextContainer/ContinueIndicator
@onready var attraction_label: Label = $HBoxContainer/PortraitContainer/MarginContainer/AttractionLabel

var choices_visible: bool = false
var typing: bool = false
var full_text: String = ""
var type_timer: float = 0.0
var type_interval: float = 0.03
var pulse_timer: float = 0.0
var custom_names: Dictionary = {}
var current_char_id: String = ""
var name_edit: LineEdit
var attraction_scores: Dictionary = {"maya": 5, "elena": 5, "vanessa": 5}


func _ready() -> void:
	print("[DialogueBox] _ready() called")
	print("[DialogueBox] portrait node:", "Portrait" if $HBoxContainer/PortraitContainer/Portrait else "MISSING")
	print("[DialogueBox] speaker_name:", "SpeakerName" if $HBoxContainer/TextContainer/NamePanel/SpeakerName else "MISSING")
	print("[DialogueBox] dialogue_text:", "DialogueText" if $HBoxContainer/TextContainer/DialogueTextMargin/DialogueText else "MISSING")
	print("[DialogueBox] choices_container:", "ChoicesContainer" if $HBoxContainer/TextContainer/DialogueTextMargin/ChoicesContainer else "MISSING")
	visible = false
	DialogueManager.line_started.connect(_on_line_started)
	print("[DialogueBox] connected line_started")
	DialogueManager.choices_presented.connect(_on_choices_presented)
	print("[DialogueBox] connected choices_presented")
	DialogueManager.script_ended.connect(_on_script_ended)
	print("[DialogueBox] connected script_ended")
	
	speaker_name.gui_input.connect(_on_name_clicked)
	
	name_edit = LineEdit.new()
	name_edit.visible = false
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_edit.add_theme_font_size_override("font_size", 22)
	name_edit.text_submitted.connect(_on_name_submitted)
	name_edit.focus_exited.connect(_on_name_edit_done)
	speaker_name.get_parent().add_child(name_edit)
	
	# Connect to TTSManager for playback signals
	TTSManager.tts_finished.connect(_on_tts_finished)

func _process(delta: float) -> void:
	if typing:
		type_timer += delta
		while type_timer >= type_interval:
			type_timer -= type_interval
			var chars_to_show = min(dialogue_text.visible_characters + 1, full_text.length())
			dialogue_text.visible_characters = chars_to_show
			if chars_to_show >= full_text.length():
				typing = false
				continue_indicator.visible = true
				line_finished.emit()
				break
	if continue_indicator.visible:
		pulse_timer += delta
		var alpha = 0.5 + 0.5 * sin(pulse_timer * 4.0)
		continue_indicator.modulate = Color(1, 1, 1, alpha)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[DialogueBox] mouse click detected, choices_visible=", choices_visible)
		if choices_visible:
			return
		if typing:
			dialogue_text.visible_characters = -1
			typing = false
			continue_indicator.visible = true
			line_finished.emit()
		else:
			print("[DialogueBox] emitting line_confirmed")
			AudioManager.play_sfx("click")
			line_confirmed.emit()
			accept_event()

func _on_line_started(line_data: Dictionary) -> void:
	var entry_type = line_data.get("type", "say")
	print("[DialogueBox] _on_line_started type=", entry_type, " data=", line_data)
	
	# Always reset choices state on any new entry
	choices_container.visible = false
	choices_visible = false
	
	if entry_type == "say":
		visible = true
		continue_indicator.visible = false
		var char_id = line_data.get("char", "")
		current_char_id = char_id
		var expression = line_data.get("expr", "neutral")
		var text = line_data.get("text", "")
		var say_idx = line_data.get("say_index", -1)
		print("[DialogueBox] speaking:", char_id, "|", text, "|say_index=", say_idx)
		
		# Narrator mode: hide portrait and speaker name, expand text area
		if char_id == "":
			portrait_container.visible = false
			speaker_name.visible = false
		else:
			portrait_container.visible = true
			speaker_name.visible = true
			# Update portrait
			var portrait_path = Characters.get_portrait(char_id, expression)
			print("[DialogueBox] portrait_path for '", char_id, "', '", expression, "': ", portrait_path)
			if portrait_path and ResourceLoader.exists(portrait_path):
				print("[DialogueBox] loading portrait texture")
				portrait.texture = load(portrait_path)
				portrait.modulate = Color(1, 1, 1, 0)
				var tween = create_tween()
				tween.tween_property(portrait, "modulate", Color(1, 1, 1, 1), 0.3)
			else:
				print("[DialogueBox] portrait path missing or file doesn't exist")
			
			# Update speaker name with accent color
			var display_name = custom_names.get(char_id, Characters.get_display_name(char_id))
			speaker_name.text = display_name
			speaker_name.add_theme_color_override("font_color", Characters.get_accent_color(char_id))
			
			# Show attraction score
			if attraction_scores.has(char_id):
				var score = attraction_scores[char_id]
				attraction_label.text = "Attraction: %d/10" % score
				attraction_label.add_theme_color_override("font_color", _get_attraction_color(score))
				attraction_label.visible = true
			else:
				attraction_label.visible = false
		
		# Update dialogue text
		full_text = text
		dialogue_text.text = text
		
		var tts_available = TTSManager.is_enabled() and char_id != "" and TTSManager.has_line(char_id, say_idx)
		
		if tts_available:
			dialogue_text.visible_characters = -1
			dialogue_text.visible = true
			typing = false
			continue_indicator.visible = true
			# Wait for TTS to finish before emitting line_finished
			# Signal connected in _ready: TTSManager.tts_finished -> _on_tts_finished
		else:
			dialogue_text.visible_characters = 0
			dialogue_text.visible = true
			if DialogueManager.auto_advance:
				# Instant text for fast testing
				dialogue_text.visible_characters = -1
				typing = false
				continue_indicator.visible = true
				call_deferred("emit_signal", "line_finished")
			else:
				typing = true
				type_timer = 0.0
		
		# Play TTS if enabled and character is speaking (after setting up display mode)
		if TTSManager.is_enabled() and char_id != "" and say_idx >= 0:
			TTSManager.play_line(char_id, say_idx)
		
	elif entry_type == "bg":
		# Background change handled by game.gd
		var bg_id = line_data.get("id", "")
		print("[DialogueBox] bg change to:", bg_id)
		if bg_id:
			var game_node = get_tree().root.get_node_or_null("Game")
			if game_node:
				game_node.set_background(bg_id)
	
	elif entry_type == "show":
		var char_id = line_data.get("char", "")
		var expression = line_data.get("expr", "neutral")
		if char_id != "":
			var game_node = get_tree().root.get_node_or_null("Game")
			if game_node:
				game_node.show_character(char_id, expression)
	
	elif entry_type == "hide":
		var char_id = line_data.get("char", "")
		if char_id != "":
			var game_node = get_tree().root.get_node_or_null("Game")
			if game_node:
				game_node.hide_character(char_id)

func _on_choices_presented(options: Array) -> void:
	print("[DialogueBox] _on_choices_presented with", options.size(), " options")
	visible = true
	continue_indicator.visible = false
	dialogue_text.visible = false
	choices_container.visible = true
	choices_visible = true
	typing = false
	
	# Clear old buttons
	for child in choices_container.get_children():
		child.queue_free()
	
	# Create choice buttons
	for i in range(options.size()):
		var btn = Button.new()
		btn.text = options[i].get("text", "Option %d" % (i + 1))
		print("[DialogueBox] adding choice button:", btn.text)
		btn.pressed.connect(func(opt_index=i): 
			print("[DialogueBox] choice", opt_index, "selected")
			AudioManager.play_sfx("choice")
			DialogueManager.select_choice(opt_index))
		btn.custom_minimum_size = Vector2(300, 50)
		btn.add_theme_font_size_override("font_size", 20)
		
		var normal = StyleBoxFlat.new()
		normal.bg_color = Color(0.1, 0.08, 0.2, 0.85)
		normal.corner_radius_top_left = 8
		normal.corner_radius_top_right = 8
		normal.corner_radius_bottom_left = 8
		normal.corner_radius_bottom_right = 8
		normal.border_width_left = 2
		normal.border_width_top = 2
		normal.border_width_right = 2
		normal.border_width_bottom = 2
		normal.border_color = Color(0.5, 0.4, 0.7, 0.5)
		
		var hover = StyleBoxFlat.new()
		hover.bg_color = Color(0.2, 0.15, 0.35, 0.95)
		hover.corner_radius_top_left = 8
		hover.corner_radius_top_right = 8
		hover.corner_radius_bottom_left = 8
		hover.corner_radius_bottom_right = 8
		hover.border_width_left = 2
		hover.border_width_top = 2
		hover.border_width_right = 2
		hover.border_width_bottom = 2
		hover.border_color = Color(0.7, 0.6, 0.9, 0.8)
		
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", hover)
		btn.add_theme_stylebox_override("focus", hover)
		
		choices_container.add_child(btn)

func _on_name_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if current_char_id == "":
			return
		speaker_name.visible = false
		name_edit.visible = true
		name_edit.text = custom_names.get(current_char_id, Characters.get_display_name(current_char_id))
		name_edit.grab_focus()
		name_edit.select_all()

func _on_name_submitted(_new_text: String) -> void:
	_on_name_edit_done()

func _on_name_edit_done() -> void:
	if current_char_id != "" and name_edit.text.strip_edges() != "":
		custom_names[current_char_id] = name_edit.text.strip_edges()
		speaker_name.text = custom_names[current_char_id]
	name_edit.visible = false
	speaker_name.visible = true

func _on_script_ended() -> void:
	visible = false
	if DialogueManager.auto_advance:
		print("[DialogueBox] script ended, auto-advance mode, quitting")
		await get_tree().create_timer(0.5).timeout
		get_tree().quit()

func _on_tts_finished() -> void:
	# TTS finished playing, emit line_finished so dialogue can advance
	call_deferred("emit_signal", "line_finished")

func stop_tts() -> void:
	TTSManager.stop()

func set_tts_enabled(enabled: bool) -> void:
	TTSManager.set_enabled(enabled)

func set_attraction_scores(scores: Dictionary) -> void:
	attraction_scores = scores

func update_attraction(char_id: String, value: int) -> void:
	attraction_scores[char_id] = value
	if current_char_id == char_id and attraction_label.visible:
		attraction_label.text = "Attraction: %d/10" % value
		attraction_label.add_theme_color_override("font_color", _get_attraction_color(value))

func _get_attraction_color(score: int) -> Color:
	# 0 = Red, 5 = Yellow, 10 = Green
	if score <= 5:
		return Color(1.0, score / 5.0, 0.0)
	else:
		return Color(1.0 - (score - 5.0) / 5.0, 1.0, 0.0)
