extends Control

# Save/Load menu UI
# Displays save slots with metadata and allows saving/loading

signal save_requested(slot: int)
signal load_requested(slot: int)
signal menu_closed

@onready var slot_container: VBoxContainer = $MarginContainer/VBoxContainer/SlotContainer
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

var slot_buttons: Array = []

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	_populate_slots()

func _populate_slots() -> void:
	# Clear existing buttons
	for child in slot_container.get_children():
		child.queue_free()
	slot_buttons.clear()
	
	# Create buttons for each slot
	for i in range(SaveManager.MAX_SLOTS):
		var metadata = SaveManager.get_save_metadata(i)
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 5)
		
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 60)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		if metadata.get("exists", false):
			button.text = "Slot %d - %s\n%s" % [i + 1, metadata.get("progress", "Unknown"), metadata.get("timestamp", "Unknown")]
		else:
			button.text = "Slot %d - Empty" % (i + 1)
		
		button.pressed.connect(_on_slot_pressed.bind(i))
		row.add_child(button)
		
		# Delete button for existing saves
		if metadata.get("exists", false):
			var delete_btn = Button.new()
			delete_btn.text = "X"
			delete_btn.custom_minimum_size = Vector2(40, 60)
			delete_btn.pressed.connect(_on_delete_pressed.bind(i))
			row.add_child(delete_btn)
		
		slot_container.add_child(row)
		slot_buttons.append(button)

func _on_slot_pressed(slot: int) -> void:
	if SaveManager.has_save(slot):
		load_requested.emit(slot)
	else:
		save_requested.emit(slot)

func _on_delete_pressed(slot: int) -> void:
	if SaveManager.delete_save(slot):
		print("[SaveLoadMenu] Deleted slot %d" % slot)
		refresh_slots()
	AudioManager.play_sfx("click")

func _on_close_pressed() -> void:
	menu_closed.emit()
	visible = false

func refresh_slots() -> void:
	_populate_slots()
