extends Control

# Gallery menu — shows unlocked character portraits and backgrounds.
# Locked images display a placeholder with a lock icon.
# Click unlocked images to view them full-screen with prev/next navigation.

const SLOT_SIZE = 150
const SLOT_GAP = 12
const PANEL_PADDING = 20
const VIEWPORT_WIDTH = 1280
const MIN_COLS = 3
const MAX_COLS = 8

var current_tab: String = "elena"
var tab_buttons: Array[Button] = []
var grid_container: GridContainer = null
var content_panel: Panel = null
var viewer_overlay: Control = null
var viewer_image: TextureRect = null
var viewer_label: Label = null
var viewer_prev_btn: Button = null
var viewer_next_btn: Button = null
var current_items: Array = []
var current_viewer_index: int = 0

func _ready() -> void:
	_build_ui()
	_build_viewer()
	_select_tab("elena")
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)

func _calc_columns() -> int:
	var available: float = float(VIEWPORT_WIDTH - 40 - (PANEL_PADDING * 2))
	var cols = floor(available / float(SLOT_SIZE + SLOT_GAP))
	return clamp(cols, MIN_COLS, MAX_COLS)

func _build_ui() -> void:
	# Title
	var title = Label.new()
	title.text = "Gallery"
	title.position = Vector2(20, 10)
	title.size = Vector2(1240, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.85, 0.7, 0.95, 1))
	add_child(title)

	# Tab bar
	var tab_bar = HBoxContainer.new()
	tab_bar.position = Vector2(20, 45)
	tab_bar.size = Vector2(1240, 45)
	tab_bar.add_theme_constant_override("separation", 8)
	add_child(tab_bar)

	var char_ids = Characters.get_character_ids()
	char_ids.append("backgrounds")

	for char_id in char_ids:
		var btn = Button.new()
		var display_name = "Backgrounds" if char_id == "backgrounds" else Characters.get_display_name(char_id)
		btn.text = display_name
		btn.custom_minimum_size = Vector2(150, 40)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_tab_pressed.bind(char_id))
		_apply_tab_style(btn, false)
		tab_bar.add_child(btn)
		tab_buttons.append(btn)

	# Progress label
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.position = Vector2(20, 92)
	progress_label.size = Vector2(1240, 20)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.6, 1))
	add_child(progress_label)

	# Content panel
	content_panel = Panel.new()
	content_panel.position = Vector2(20, 115)
	content_panel.size = Vector2(1240, 520)
	content_panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(content_panel)

	# Grid for image slots
	var cols = _calc_columns()
	grid_container = GridContainer.new()
	grid_container.position = Vector2(PANEL_PADDING, PANEL_PADDING)
	var grid_width = VIEWPORT_WIDTH - 40 - (PANEL_PADDING * 2)
	grid_container.size = Vector2(grid_width, 480)
	grid_container.columns = cols
	grid_container.add_theme_constant_override("h_separation", SLOT_GAP)
	grid_container.add_theme_constant_override("v_separation", SLOT_GAP)
	content_panel.add_child(grid_container)

	# Back button
	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.position = Vector2(540, 650)
	back_btn.size = Vector2(200, 45)
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.pressed.connect(_on_back_pressed)
	_apply_menu_button_style(back_btn)
	add_child(back_btn)

func _build_viewer() -> void:
	viewer_overlay = Control.new()
	viewer_overlay.visible = false
	viewer_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewer_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(viewer_overlay)

	# Dark background (click to close)
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.92)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(_on_viewer_bg_input)
	viewer_overlay.add_child(bg)

	# Image - fill the center area
	var img_margin = 100
	viewer_image = TextureRect.new()
	viewer_image.position = Vector2(img_margin, 30)
	viewer_image.size = Vector2(VIEWPORT_WIDTH - img_margin * 2, 560)
	viewer_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	viewer_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	viewer_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewer_overlay.add_child(viewer_image)

	# Label
	viewer_label = Label.new()
	viewer_label.position = Vector2(0, 600)
	viewer_label.size = Vector2(1280, 35)
	viewer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	viewer_label.add_theme_font_size_override("font_size", 20)
	viewer_label.add_theme_color_override("font_color", Color(0.85, 0.7, 0.95, 1))
	viewer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewer_overlay.add_child(viewer_label)

	# Prev button
	viewer_prev_btn = Button.new()
	viewer_prev_btn.text = "<"
	viewer_prev_btn.position = Vector2(10, 250)
	viewer_prev_btn.size = Vector2(60, 80)
	viewer_prev_btn.add_theme_font_size_override("font_size", 32)
	viewer_prev_btn.pressed.connect(_on_viewer_prev)
	_apply_viewer_button_style(viewer_prev_btn)
	viewer_overlay.add_child(viewer_prev_btn)

	# Next button
	viewer_next_btn = Button.new()
	viewer_next_btn.text = ">"
	viewer_next_btn.position = Vector2(1210, 250)
	viewer_next_btn.size = Vector2(60, 80)
	viewer_next_btn.add_theme_font_size_override("font_size", 32)
	viewer_next_btn.pressed.connect(_on_viewer_next)
	_apply_viewer_button_style(viewer_next_btn)
	viewer_overlay.add_child(viewer_next_btn)

	# Close hint
	var hint = Label.new()
	hint.position = Vector2(0, 640)
	hint.size = Vector2(1280, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.35, 0.3, 0.45, 1))
	hint.text = "Click background to close  ·  Use arrows to navigate"
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewer_overlay.add_child(hint)

func _apply_viewer_button_style(btn: Button) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.15, 0.1, 0.25, 0.7)
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
	hover.bg_color = Color(0.3, 0.2, 0.5, 0.9)
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

func _apply_tab_style(btn: Button, active: bool) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.15, 0.1, 0.25, 0.8) if not active else Color(0.3, 0.2, 0.5, 0.9)
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.7, 0.6, 0.9, 0.8) if active else Color(0.5, 0.4, 0.7, 0.5)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", normal)
	btn.add_theme_stylebox_override("pressed", normal)

func _apply_menu_button_style(btn: Button) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.15, 0.1, 0.25, 0.8)
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
	hover.bg_color = Color(0.25, 0.18, 0.4, 0.9)
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

func _make_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.03, 0.1, 0.95)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.4, 0.7, 0.6)
	return style

func _make_slot_style(unlocked: bool) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.09, 0.18, 1) if unlocked else Color(0.05, 0.03, 0.08, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	if unlocked:
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.5, 0.4, 0.7, 0.4)
	return style

func _make_slot_hover_style(unlocked: bool) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.14, 0.28, 1) if unlocked else Color(0.07, 0.05, 0.12, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	if unlocked:
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.7, 0.6, 0.9, 0.7)
	return style

func _select_tab(tab_id: String) -> void:
	current_tab = tab_id
	for btn in tab_buttons:
		var btn_id = _get_tab_id_for_button(btn)
		_apply_tab_style(btn, btn_id == tab_id)
	_populate_grid()
	_update_progress()

func _update_progress() -> void:
	var progress_label = get_node_or_null("ProgressLabel")
	if not progress_label:
		return

	var unlocked = 0
	var total = 0

	if current_tab == "backgrounds":
		var bg_ids = Characters.get_background_ids()
		total = bg_ids.size()
		for bg_id in bg_ids:
			if GalleryManager.is_background_unlocked(bg_id):
				unlocked += 1
	else:
		var expressions = Characters.get_expressions(current_tab)
		total += expressions.size()
		for expr in expressions:
			if GalleryManager.is_portrait_unlocked(current_tab, expr):
				unlocked += 1
		total += 2
		if GalleryManager.is_body_unlocked(current_tab, "pose1"):
			unlocked += 1
		if GalleryManager.is_body_unlocked(current_tab, "pose2"):
			unlocked += 1

	var display_name = "Backgrounds" if current_tab == "backgrounds" else Characters.get_display_name(current_tab)
	progress_label.text = "%s: %d / %d unlocked" % [display_name, unlocked, total]

func _get_tab_id_for_button(btn: Button) -> String:
	if btn.text == "Backgrounds":
		return "backgrounds"
	for char_id in Characters.get_character_ids():
		if btn.text == Characters.get_display_name(char_id):
			return char_id
	return ""

func _populate_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()

	current_items.clear()

	if current_tab == "backgrounds":
		_populate_backgrounds()
	else:
		_populate_portraits(current_tab)
		_add_section_label("Body Poses")
		_populate_bodies(current_tab)

func _add_section_label(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.size = Vector2(VIEWPORT_WIDTH - 40 - (PANEL_PADDING * 2), 30)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.85, 0.7, 0.95, 1))
	grid_container.add_child(label)

func _populate_portraits(char_id: String) -> void:
	var expressions = Characters.get_expressions(char_id)
	for expr in expressions:
		var unlocked = GalleryManager.is_portrait_unlocked(char_id, expr)
		var path = Characters.get_portrait(char_id, expr)
		current_items.append({"unlocked": unlocked, "label": expr.capitalize(), "path": path})
		var slot = _make_slot(unlocked, expr.capitalize(), path)
		grid_container.add_child(slot)

func _populate_bodies(char_id: String) -> void:
	var body_ids = ["pose1", "pose2"]
	for body_id in body_ids:
		var unlocked = GalleryManager.is_body_unlocked(char_id, body_id)
		var path = Characters.get_body(char_id, body_id)
		current_items.append({"unlocked": unlocked, "label": body_id.capitalize(), "path": path})
		var slot = _make_slot(unlocked, body_id.capitalize(), path)
		grid_container.add_child(slot)

func _populate_backgrounds() -> void:
	var bg_ids = Characters.get_background_ids()
	for bg_id in bg_ids:
		var unlocked = GalleryManager.is_background_unlocked(bg_id)
		var path = Characters.get_background(bg_id)
		current_items.append({"unlocked": unlocked, "label": bg_id.replace("_", " ").capitalize(), "path": path})
		var slot = _make_slot(unlocked, bg_id.replace("_", " ").capitalize(), path)
		grid_container.add_child(slot)

func _make_slot(unlocked: bool, label: String, path: String) -> Control:
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	if unlocked:
		slot.gui_input.connect(_on_slot_clicked.bind(path, label))

	# Background
	var slot_bg = ColorRect.new()
	slot_bg.name = "SlotBg"
	slot_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot_bg.color = Color(0.12, 0.09, 0.18, 1) if unlocked else Color(0.05, 0.03, 0.08, 1)
	slot_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(slot_bg)

	if unlocked:
		var tex_rect = TextureRect.new()
		tex_rect.name = "Image"
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if path and ResourceLoader.exists(path):
			tex_rect.texture = load(path)
		slot.add_child(tex_rect)

		# Hover overlay
		var hover_overlay = ColorRect.new()
		hover_overlay.name = "HoverOverlay"
		hover_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		hover_overlay.color = Color(0.3, 0.25, 0.45, 0)
		hover_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(hover_overlay)

		slot.mouse_entered.connect(_on_slot_hover.bind(slot, true))
		slot.mouse_exited.connect(_on_slot_hover.bind(slot, false))
	else:
		var lock_label = Label.new()
		lock_label.text = "🔒"
		lock_label.set_anchors_preset(Control.PRESET_CENTER)
		lock_label.offset_left = -16
		lock_label.offset_top = -16
		lock_label.offset_right = 16
		lock_label.offset_bottom = 16
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_label.add_theme_font_size_override("font_size", 28)
		lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(lock_label)

	# Label at bottom
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = label
	name_label.position = Vector2(0, SLOT_SIZE - 26)
	name_label.size = Vector2(SLOT_SIZE, 26)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.65, 0.55, 0.8, 1) if unlocked else Color(0.3, 0.25, 0.4, 1))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(name_label)

	return slot

func _on_slot_hover(slot: Control, entered: bool) -> void:
	var bg = slot.get_node_or_null("SlotBg") as ColorRect
	var overlay = slot.get_node_or_null("HoverOverlay") as ColorRect
	if entered:
		if bg:
			bg.color = Color(0.18, 0.14, 0.28, 1)
		if overlay:
			var tween = create_tween()
			tween.tween_property(overlay, "color", Color(0.3, 0.25, 0.45, 0.25), 0.15)
	else:
		if bg:
			bg.color = Color(0.12, 0.09, 0.18, 1)
		if overlay:
			var tween = create_tween()
			tween.tween_property(overlay, "color", Color(0.3, 0.25, 0.45, 0), 0.15)

func _on_slot_clicked(event: InputEvent, path: String, _label: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		AudioManager.play_sfx("click")
		var idx = -1
		for i in range(current_items.size()):
			if current_items[i]["path"] == path:
				idx = i
				break
		if idx >= 0:
			_open_viewer(idx)

func _open_viewer(index: int) -> void:
	current_viewer_index = index
	var item = current_items[index]
	if item["path"] and ResourceLoader.exists(item["path"]):
		viewer_image.texture = load(item["path"])
		viewer_label.text = item["label"]
		_update_viewer_buttons()
		viewer_overlay.visible = true
		viewer_overlay.modulate = Color(1, 1, 1, 0)
		var tween = create_tween()
		tween.tween_property(viewer_overlay, "modulate", Color(1, 1, 1, 1), 0.2)

func _update_viewer_buttons() -> void:
	viewer_prev_btn.visible = current_viewer_index > 0
	viewer_next_btn.visible = current_viewer_index < current_items.size() - 1

func _on_viewer_prev() -> void:
	AudioManager.play_sfx("click")
	if current_viewer_index > 0:
		_open_viewer(current_viewer_index - 1)

func _on_viewer_next() -> void:
	AudioManager.play_sfx("click")
	if current_viewer_index < current_items.size() - 1:
		_open_viewer(current_viewer_index + 1)

func _close_viewer() -> void:
	AudioManager.play_sfx("click")
	var tween = create_tween()
	tween.tween_property(viewer_overlay, "modulate", Color(1, 1, 1, 0), 0.15)
	await tween.finished
	viewer_overlay.visible = false
	viewer_image.texture = null

func _on_viewer_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_viewer()

func _on_tab_pressed(tab_id: String) -> void:
	AudioManager.play_sfx("click")
	_select_tab(tab_id)

func _on_back_pressed() -> void:
	AudioManager.play_sfx("click")
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
